package Outputs_Main;

#Returns the instance of the Output class generated by the input values.
sub GetOutput
{	
	my $input = $_[0];
	
	my %urls = %{$input->{"URLs"}};
	my $url = $urls{Globals_Constants::INPUT_URL_MAIN()};
	
	{
		no warnings "once";
		
		my @tempArray = HTML_Main::GetDomainProtocolFromURL($url);
		$Globals_Variables::CurDomain = $tempArray[0];
		$Globals_Variables::CurProtocol = $tempArray[1];
	}
	
	my @entries = GetOutputEntries
	(
		HTML_Main::GetHTML($url), \%{$input->{"Entries"}}, \%{$input->{"Limits"}}
	);
	if (scalar(@entries) == 0) { return undef; }
	

	return Output->Instantiate
	(
		"Name" => $input->{"Name"}, "Entries" => \@entries, "URL" => $url
	);
}

#Returns collection storing all the entries for the corresponding Output instance.
sub GetOutputEntries
{	
	my $html = $_[0];
	my %inputs = %{$_[1]};
	my %limits = %{$_[2]};

	my %targets = GetOutputEntriesTargets(\%inputs);
	if (scalar(keys %targets) == 0) { return (); }

	my $htmlClass = Html->Instantiate("HTML" => $html, "Targets" => \%targets);

	my $endI = length($html) - 1;
	my @outEntries;

	while (1)
	{
		my $entry = GetOutputEntry($htmlClass);
		if
		(
			!defined($entry) or $entry->{"LastI"} < 0
			or $entry->{"LastI"} > $endI
		)
		{ last; }

		$htmlClass->{"LastI"} = $entry->{"LastI"};
		push @outEntries, $entry;
		
		if (scalar(@outEntries) == $limits{Globals_Constants::INPUT_LIMIT_ENTRIES()}) { last; }
	}
	
	return @outEntries;
}

#From the corresponding input entries, it generates the targets (group of HTML_Entity instances) to be applied to the HTML
#code. Or, in other words, this method converts the string inputs defining the HTML entities surrounding the expected values
#into the HTML_Entity instances which will be used while parsing the HTML code and generating the final outputs.
sub GetOutputEntriesTargets
{	
	my %inputs = %{$_[0]};
	my %targets;
	
	foreach my $key (keys %inputs)
	{
		my @target = HTML_Parse_Inputs::CreateEntityClassesFromInput($inputs{$key}->{"Value"});
		if (scalar(@target) == 0) { next; }

		@{$targets{$key}} = @target;	
	}

	return %targets;	
}

#Returns the Output_Entry associated with the input information.
sub GetOutputEntry
{	
	my $htmlClass = $_[0];
	my %targets0 = %{$htmlClass->{"Targets"}};
	
	my @inputs = (keys %targets0);
	my $maxInputs = scalar(@inputs) - 1;

	my %outContent;
	my $maxHtml = length($htmlClass->{"HTML"}) - 1;
	my $lastI0 = $htmlClass->{"LastI"};
	my $outI = -1;
	
	#Note that all the HTML-related actions inside the loop are done by taking the relevant HTML as
	#reference (i.e., substring from the given last index until the end). Consequently all these
	#indices (e.g., $entity->{"LastI"}) have to be corrected to refer to the frame of reference which
	#is relevant outside this method. The variable $addI is precisely meant to take care of this correction.
	my $addI = 0;
	
	for ($i0 = 0; $i0 <= $maxInputs; $i0++)
	{
		my $input = $inputs[$i0];
		my @targets = @{$targets0{$input}};
		my $maxTargets = scalar(@targets) - 1;
		
		$htmlClass->{"LastI"} = $lastI0;
		my $matched = 0;
		
		#This variable will be holding the Html_Entity instance resulting from the last
		#parsing analysis (done in HTML_Parse_Entities::MatchEntityToTarget).
		#As far as the targets are ordered from left to right, only the contents of the
		#last sucessfully matched entity are relevant/returned.
		my $entity;
		
		for (my $i1 = 0; $i1 <= $maxTargets; $i1++)
		{
			$addI = $htmlClass->{"LastI"};
			my $html = substr($htmlClass->{"HTML"}, $htmlClass->{"LastI"});
			
			$entity = HTML_Parse_Entities::MatchEntityToTarget($html, $targets[$i1], $input);
			if (!defined($entity) or !defined($entity->{"CloseI"}))
			{
				#There is no possible match for this target in the current HTML code.
				last;
			}
			
			if ($i1 == $maxTargets) { $matched = 1; }
			else
			{
				$htmlClass->{"LastI"} = $entity->{"LastI"} + $addI + 1;
				if ($htmlClass->{"LastI"} >= $maxHtml or $htmlClass->{"LastI"} < 1)
				{
					#Some targets haven't been matched, but all the HTML code has
					#already been analysed.
					last;
				}
			}				
		}

		if ($matched)
		{
			$outContent{$input} = $entity->{"Content"};
			if ($entity->{"CloseI2"} > $outI) { $outI = $entity->{"CloseI2"} + $addI; }
		}
		else { $outContent{$input} = ""; }
	}

	if (!exists $outContent{Globals_Constants::INPUT_ENTRY_URL})
	{
		$outContent
		{
			Globals_Constants::INPUT_ENTRY_URL
		}
		= $Globals_Variables::CurProtocol . $Globals_Variables::CurDomain;
	}
	
	return Output_Entry->Instantiate("LastI" => $outI, "Content" => \%outContent);
}

1;