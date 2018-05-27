package Inputs_Store;

#Instantiates the Input class variable associated with the corresponding input file and stores all the required information. 
sub InstatiateInput
{
	#Getting a first version of all the collections in the Input class, namely: {"URLs"}, {"Entries"} and {"Limits"}.
	my %tempInputs = GetInputsFirst(\@{$_[1]});	
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
#They are stored as instances of the Input_Entry class, even though only part of them are actually input entries.
sub GetInputsFirst
{
	my @lines = @{$_[0]};
	my %outInputs;

	for (my $i = 0; $i < scalar(@lines); $i++)
	{
		my %tempDict = ParseFileLine($lines[$i]);
		if (%tempDict) { %outInputs = AddInputFirst(\%outInputs, \%tempDict); }
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

#Called from GetEntryFromLine to determine the point until which the line contents are relevant (i.e., where the comments start).
sub GetEntryFromLineUptoComments
{
	my $input2 = $_[0];
	
	my $outI = -1;
	my $found = 0;
	
	while (1)
	{
		my $tempVar = Accessory::IndexOfOutsideQuotes($input2, "//", $outI + 1);
		if ($tempVar < 0) { last; }
		
		$found = 1;
		$outI = $tempVar;
		
		foreach $item ("http:", "https:")
		{
			my $tempVar2 = length($item);
			if (substr($input2, $tempVar - $tempVar2, $tempVar2) eq $item)
			{
				#This isn't a comment, but a URL.
				$found = 0;
				last;
			}
		}
		
		if ($found eq 1)
		{
			#A valid comment has been found, everything after it can be safely ignored.
			last;
		}
	}

	return ($found eq 0 ? -1 : $outI);
}

#Called from  GetEntryFromLineConstraints to perform accessory actions.
sub GetEntryFromLineConstraintsInternal
{
	my $input = $_[0];
	my $input2 = lc($input);	

	my @output = (-1, -1);

	foreach $id (keys %Globals_Variables::InputConstraints)
	{
		my $constraint = $Globals_Variables::InputConstraints{$id};		

		$i = Accessory::IndexOfOutsideQuotes($input2, $constraint);
		if ($i > -1 and ($output[1] eq -1 or $id > $output[1]))
		{
			$output[0] = $i;
			$output[1] = $id;
		}
	}

	return @output;
}

#Called from GetEntryFromLine to analyse eventual input constraints.
sub GetEntryFromLineConstraints
{
	my $outEntry = $_[0];
	my $input2 = $outEntry->{"Value"};
	my $firstTime = 1;
	my @constraints;

	while (defined($input2))
	{
		my @tempArray = GetEntryFromLineConstraintsInternal($input2);
		if ($tempArray[0] < 0) { last; }

		my $constraint = Input_Constraint->Instantiate("ID" => $tempArray[1]);
		$input2 = substr($input2, $tempArray[0] + length($Globals_Variables::InputConstraints{$tempArray[1]}));

		if ($firstTime)
		{
			$firstTime = 0;
			$outEntry->{"Value"} = Accessory::Trim(substr($outEntry->{"Value"}, 0, $tempArray[0]));
		}
	
		my $length2 = length($input2);
		my @nexts = (-1, -1);
		
		{
			no warnings "once";
			
			foreach $id (keys %Globals_Variables::OperatorsLogical)
			{
				$tempVar = " " . $Globals_Variables::OperatorsLogical{$id} . " ";
				my $i = Accessory::IndexOfOutsideQuotes($input2, $tempVar);
				if ($i > -1)
				{
					$nexts[0] = $i;
					$nexts[1] = Accessory::IterateThroughStringWhile
					(
						$input2, $length2, " ", $i + length($tempVar), 1
					);
					$constraint->{"Operator"} = $id;
					last;
				}
			}				
		}

		$tempVar = $input2;
		if ($nexts[0] > -1)
		{
			$tempVar = Accessory::Trim(substr($input2, 0, $nexts[0]));
			$input2 = Accessory::Trim(substr($input2, $nexts[1]));
		}
		else
		{
			$tempVar = Accessory::Trim($tempVar);
			$input2 = undef;
		}
		$tempVar = Accessory::GetElementInQuotes($tempVar, length($tempVar), 1);
		
		if (defined($tempVar))
		{
			$constraint->{"Value"} = $tempVar;
			push @constraints, $constraint;
		}
	}

	if (scalar(@constraints) > 0) { @{$outEntry->{"Constraints"}} = @constraints; }

	return $outEntry;
}

#Method analysing the given input line and creating the corresponding Input_Entry instance.
sub GetEntryFromLine
{
	my $input = $_[0];	
	my $length = length($input);
	
	if ($length < 2) { return Input_Entry->Instantiate("Value" => $input); }
	if (substr($input, 0, 2) eq "//") { return undef; }

	#Index where the comments start in case of being present. Note that the returned value cannot be 0.
	my $i = GetEntryFromLineUptoComments(lc($input));
	my $value = Accessory::Trim($i > -1 ? substr($input, 0, $i) : $input);

	my $outEntry = Input_Entry->Instantiate();
	$outEntry->{"Value"} = $value;
	
	$i = index($value, " ");
	if ($i > -1)
	{
		#There might be some constraints which have to be analysed.
		$outEntry = GetEntryFromLineConstraints($outEntry);
	}

	return $outEntry;
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
			my $item = GetEntryFromLine(Accessory::Trim(substr($input, $i)));

			if (defined($item)) { $output{$type} = $item; }
			last;
		}
	}

	return %output;
}

#Adds the Input_Entry instance associated with the current line to the collection including all of them.
sub AddInputFirst
{
	my %outInputs = %{$_[0]};	
	my %tempDict = %{$_[1]};

	foreach my $type (keys %tempDict) 
	{
		if (exists $outInputs{$type} and $type != Globals_Constants::INPUT_ENTRY_ADDITIONALS())
		{
			#Only additional entries might be repeated.
			next;
		}

		if (defined(Inputs_Analysis::AnalyseInputValue($tempDict{$type}->{"Value"}, $type)))
		{
			%outInputs = AddEntryValues(\%outInputs, $type, $tempDict{$type});
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
		
		%{$input->{"URLs"}} = GetInputCollectionSimple(\%tempInputs, \@Globals_Variables::InputURLs);
		%{$input->{"Entries"}} = GetInputCollectionEntries(\%tempInputs);
		%{$input->{"Limits"}} = GetInputCollectionSimple(\%tempInputs, \@Globals_Variables::InputLimits);		
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
			if (!exists $entries{$type}) { next; }

			%outEntries = AddEntryValues(\%outEntries, $type, $entries{$type});
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
		if (exists $tempItems{$id}) { $output{$id} = $tempItems{$id}->{"Value"}; }
	}
	
	return %output;	
}

#Add the corresponding entry value by accounting for two possible scenarios: single vs. multiple.
sub AddEntryValues
{
	my %allInputs = %{$_[0]};
	my $type = $_[1];
	my $entry = $_[2];	

	if ($type eq Globals_Constants::INPUT_ENTRY_ADDITIONALS())
	{
		if (ref($entry) eq 'ARRAY') { @{$allInputs{$type}} = @{$entry}; }
		else { push @{$allInputs{$type}}, $entry; }
	}
	else { $allInputs{$type} = $entry; }	
	
	return %allInputs;
}

1;