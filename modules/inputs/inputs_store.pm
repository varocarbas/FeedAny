package Inputs_Store;

#Instantiates the Input class variable associated with the corresponding input file and
#stores all the required information. 
sub InstatiateInput
{
	#Getting a first version of all the collections in the Input class, namely: {"URLs"},
	#{"Entries"} and {"Limits"}.
	my %tempInputs = GetTempInputs(\@{$_[1]});
	if (!%tempInputs) { return undef; }
	
	my $input = Input->Instantiate();
	my $fileName = $_[0];

	{
		no warnings 'once';
		
		$input->{"Name"} = substr
		(
			$fileName, 0, length($fileName) - length
			(
				$Globals_Variables::IONames{Globals_Constants::IO_INPUT_EXTENSION()}
			)
		);
	}

	return UpdateInputCollections($input, \%tempInputs);
}

#Returns a collection with the first version of all the inputs in the given input file, one per line.
#They are stored as instances of the Input_Entry class, even though only part of them are actually
#input entries.
sub GetTempInputs
{
	my @lines = @{$_[0]};
	my %outInputs;

	for (my $i = 0; $i < scalar(@lines); $i++)
	{
		my %tempDict = ParseFileLine($lines[$i]);
		if (%tempDict) { %outInputs = AddTempInput(\%outInputs, \%tempDict); }
	}
	
	return (Inputs_Checks::InputsAreOK(\%outInputs) ? %outInputs : undef);
}

#Called accessorily while analysing the title of the given input line in ParseFileLine.
sub GetIndexAfterInputLabel
{
	my $input2 = $_[0];
	my $label = $_[1];
	my $length = $_[2];

	my $i = index($input2, $label);
	if ($i != 0) { return -1; }
	
	$i = index($input2, ":");

	if ($length < $i)
	{
		if (length(Accessory::Trim(substr($length, $i - $length))) > 0) { $i = -2; }		
	}
	
	return $i + 1;
}

#Parses one line (= input) of the corresponding input file, stores the contents in a Input_Entry
#variable and returns it together with the given input type (e.g., Globals_Constants::INPUT_URL_MAIN).
sub ParseFileLine
{	
	my $input = $_[0];
	
	my $input2 = lc(Accessory::Trim($input));
	my %output;

	foreach my $type (keys %Globals_Variables::InputLabels) 
	{
		my $label = $Globals_Variables::InputLabels{$type};
	
		my $i = GetIndexAfterInputLabel($input2, $label);

		if ($i > -1)
		{
			my $item = Input_Entry->Instantiate
			(
				"Value" => Accessory::Trim(substr($input, $i))
			);		
			if (defined($item)) { $output{$type} = $item; }
			
			last;
		}
	}

	return %output;
}

#Adds the Input_Entry instance associated with the current line to the collection including all of them.
sub AddTempInput
{
	my %outInputs = %{$_[0]};	
	my %tempDict = %{$_[1]};

	foreach my $type (keys %tempDict) 
	{
		if (exists $outInputs{$type} and $type != Globals_Constants::INPUT_ENTRY_ADDITIONALS())
		{
			#Only additional entries might be repeated.
		}

		my $tempVar = Inputs_Analysis::AnalyseInputValue($tempDict{$type}->{"Value"}, $type);
		if (defined($tempVar))
		{
			%outInputs = AddEntryValues(\%outInputs, $type, $tempVar);
		}
		else
		{
			{
				no warnings 'once';
				
				if (Accessory::IndexOfArray(\@Globals::InputLabelsBasic, $type) > -1)
				{
					Errors::ShowError
					(
						Constants::ERROR_INPUT_VALUE_FORMAT(), $Globals_Variables::InputLabels{$type}
					);		
				}
				else { next; }					
			}
		}
	}

	return %outInputs;
}

#Method performing the last actions in all the input values and storing them in the corresponding
#collections inside the given Input class instance.
sub UpdateInputCollections
{	
	my $input = $_[0];
	my %tempInputs = %{$_[1]};
	
	{
		no warnings 'once';
		
		%{$input->{"URLs"}} = GetInputCollectionSimple
		(
			\%tempInputs, \@Globals_Variables::InputURLs
		);
		
		%{$input->{"Entries"}} = GetInputCollectionEntries(\%tempInputs);
				
		%{$input->{"Limits"}} = GetInputCollectionSimple
		(
			\%tempInputs, \@Globals_Variables::InputLimits
		);		
	}	
	
	return $input;
}

#Performs all the required corrections on the temporary inputs for the input entries.
sub GetInputCollectionEntries
{
	#%entries contains all the input types (i.e., lines of the corresponding input file).
	#%outEntries only the ones associated with the input entries (i.e., included in @Globals_Variables::InputEntries).
	my %entries = %{$_[0]};
	my %outEntries;
	
	{
		no warnings "once";

		foreach my $type (@Globals_Variables::InputEntries)
		{
			 %outEntries = AddEntryValues
			 (
				\%outEntries, $type,
				(
					$type == Globals_Constants::INPUT_ENTRY_ADDITIONALS() ?
					\@{$entries{$type}->{"Array"}} : $entries{$type}->{"Value"}
				)
			);	 
		}		
	}
	
	return %outEntries;
}

#Adapts the temporary inputs for the groups of types not requiring any special actions, namely:
#URLs and limits. Note that the adequacy of the input values with respect to the to the corresponding
#target formats has already been checked at a previous point.
sub GetInputCollectionSimple
{	
	my %tempItems = %{$_[0]};
	my @ids = @{$_[1]};	
	my %output;
	
	foreach $id (@ids)
	{
		if (exists $tempItems{$id})
		{
			$output{$id} = $tempItems{$id}->{"Value"};
		}
	}
	
	return %output;	
}

#Add the corresponding entry value by accounting for two possible scenarios: single vs. multiple.
sub AddEntryValues
{
	my %allInputs = %{$_[0]};
	my $type = $_[1];
	my $value = $_[2];	
	
	if ($type == Globals_Constants::INPUT_ENTRY_ADDITIONALS())
	{
		if (ref($value) eq 'ARRAY')
		{
			@{$allInputs{Globals_Constants::INPUT_ENTRY_ADDITIONALS()}->{"Array"}} = @{$value};
		}
		else
		{
			push @{$allInputs{Globals_Constants::INPUT_ENTRY_ADDITIONALS()}->{"Array"}}, $value;			
		}
	}
	else { $allInputs{$type}->{"Value"} = $value; }	
	
	return %allInputs;
}

#Gets the corresponding entry value by accounting for two possible scenarios: single vs. multiple.
sub GetEntryValues
{
	my $input = $_[0];
	my $type = $_[1];
	
	return
	(
		$type == Globals_Constants::INPUT_ENTRY_ADDITIONALS() ?
		@{$input->{"Array"}} : $input->{"Value"}
	);
}

1;