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
	if (scalar(@entries) eq 0) { return undef; }

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

	my $htmlClass = Html->Instantiate("HTML" => HTML_Parse_Common::PreprocessHTML($html, length($html)));
	
	$htmlClass = GetOutputEntriesTargets(\%inputs, $htmlClass);
	if (scalar(keys %{$htmlClass->{"Targets"}}) eq 0) { return (); }

	my $endI = length($html) - 1;
	my @outEntries;
	
	my $count = 0;
	my $maxCount = ($limits{Globals_Constants::INPUT_ENTRY_LIMIT()});
	if ($maxCount < 1) { $maxCount = -1; }
	
	while (1)
	{
		my $entry = GetOutputEntry($htmlClass);
		if (!defined($entry) or $entry->{"LastI"} < 0 or $entry->{"LastI"} > $endI) { last; }
		
		$htmlClass->{"LastI"} = $entry->{"LastI"};
		my %content = %{$entry->{"Content"}};
		if (!$entry->{"IsOK"} or OutputEntryRepeated(\@outEntries, \%content)) { next; }

		push @outEntries, $entry;
		
		$count++;
		print("Entry " . $count . "\n");
		if ($maxCount ne -1 and $count eq $maxCount) { last; }
	}
	
	return @outEntries;
}

#Checks whether the given output entry is identical to a previous one.
sub OutputEntryRepeated
{
	my @allEntries = @{$_[0]};
	if (scalar(@allEntries) < 1) { return 0; }
	
	my %curContent = %{$_[1]};
	
	foreach my $entry (@allEntries)
	{
		my %content = %{$entry->{"Content"}};
		
		{
			no warnings "once";
			
			my $repeated = 1;
			
			foreach $item (%Globals_Variables::InputEntryVars)
			{
				if ($curContent{$item} ne $content{$item})
				{
					$repeated = 0;
					last;
				}
			}
			
			if ($repeated) { return 1; }
		}
	}
	
	return 0;
}

#From the corresponding input entries, it generates the targets (group of HTML_Entity instances) to be applied to the HTML
#code. Or, in other words, this method converts the string inputs defining the HTML entities surrounding the expected values
#into the HTML_Entity instances which will be used while parsing the HTML code and generating the final outputs.
sub GetOutputEntriesTargets
{	
	my %inputs = %{$_[0]};
	my $outClass = $_[1];
	
	my %targets;
	
	foreach my $type (keys %inputs)
	{
		my @entries;
		
		if ($type eq Globals_Constants::INPUT_ENTRY_ADDITIONALS()) { @entries = @{$inputs{$type}}; }
		else { push @entries, $inputs{$type}; }
		
		my @targets2;
		
		foreach my $entry (@entries)
		{
			my @entities = HTML_Parse_Inputs::CreateEntityClassesFromInput($entry->{"Value"});
			
			if (scalar(@entities) > 0)
			{
				push @targets2, Html_Target->Instantiate
				(
					"Entities" => \@entities, "Constraints" => \@{$entry->{"Constraints"}}
				);			
			}
		}
		if (scalar(@targets2) eq 0) { next; }
		
		if ($type eq Globals_Constants::INPUT_ENTRY_ADDITIONALS()) { @{$targets{$type}} = @targets2; }	
		else { $targets{$type} = $targets2[0]; }
	}

	%{$outClass->{"Targets"}} = %targets;

	return $outClass;	
}

#Returns the content associated with the given Output_Entry instance by accounting for the difference
#normal/additional input entries.
sub GetOutputEntryContent
{	
	my $htmlClass = $_[0];
	my $isAdditional = $_[1];

	my %targets0 = GetOutputEntryContentTargets(\%{$htmlClass->{"Targets"}}, $isAdditional);

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
	my $isOK = 1;
	
	foreach my $input (sort keys %targets0)
	{
		my @targets = @{$targets0{$input}->{"Entities"}};
		my $maxTargets = scalar(@targets) - 1;
		
		my @constraints = @{$targets0{$input}->{"Constraints"}};	
		
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
			
			$entity = HTML_Parse_Entities::MatchEntityToTarget($html, $targets[$i1], ($isAdditional ? -1 : $input));
			if (!defined($entity) or !defined($entity->{"CloseI"}))
			{
				#There is no possible match for this target in the current HTML code.
				last;
			}
			
			if ($i1 eq $maxTargets) { $matched = 1; }
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
			$outContent{$input} = GetOutputEntryContentAnalyseConstraints($entity->{"Content"}, \@constraints);
			if ($entity->{"CloseI2"} > $outI) { $outI = $entity->{"CloseI2"} + $addI; }
		}
		else { $outContent{$input} = ""; }
		
		if (scalar(@constraints) > 0 and (!$matched or !defined($outContent{$input}) or length(Accessory::Trim($outContent{$input})) < 1))
		{
			#Not matching one of the targets (e.g., title) doesn't necessarily invalidate the given entry,
			#unless it includes a constraint (e.g., only titles including whatever).
			#The analysis will better continue anyway to improve the LastI value as much as possible (lower risk of previous information included in latter entries).
			$isOK = 0;
		}
	}

	if ($isOK and !OutputEntryIsOK(\%outContent)) { $isOK = 0; }
	
	return Output_Entry->Instantiate("LastI" => $outI, "Content" => \%outContent, "IsOK" => $isOK);
}

#Makes sure that the content is compatible with all the constraints.
sub GetOutputEntryContentAnalyseConstraints
{
	my $content = $_[0];
	my @constraints = @{$_[1]};
	if (scalar(@constraints) < 1) { return $content; }

	my $maxI = scalar(@constraints) - 1;
	my $operator = -1;
	my $metOnce = 0;
	
	for ($i = 0; $i <= $maxI; $i++)
	{
		my $constraint = $constraints[$i];
		if (GetOutputEntryContentConstraintIsMet($content, $constraint) eq 0)
		{
			if
			(
				($i eq $maxI) or ($operator eq Globals_Constants::OPERATORS_LOGICAL_AND()) or
				(
					$operator eq -1 and $i < $maxI and $constraints[$i]->{"Operator"} eq Globals_Constants::OPERATORS_LOGICAL_AND()
				)
			)
			{ return ""; }
		}
		else
		{
			$metOnce = 1;
			
			if (($i < $maxI) and ($constraints[$i]->{"Operator"} eq Globals_Constants::OPERATORS_LOGICAL_OR()))
			{
				#The next constraint doesn't need to be analysed.
				$i++;
			}
		}

		$operator = $constraints[$i]->{"Operator"};
	}

	return ($metOnce ? $content : "");
}

#Makes sure that the content is compatible with the given constraint.
sub GetOutputEntryContentConstraintIsMet
{
	my $content = lc($_[0]);
	my $constraint = $_[1];
	
	my $value = lc($constraint->{"Value"});
	my $i = index($content, $value);
	my $isMet = 0;
	
	if ($i < 0)
	{
		$isMet =
		(
			(
				$constraint->{"ID"} eq Globals_Constants::CONSTRAINTS_INPUT_NOT_EQUAL() or
				$constraint->{"ID"} eq Globals_Constants::CONSTRAINTS_INPUT_NOT_CONTAINS()
			)
			? 1 : 0
		);
	}
	else
	{
		if ($constraint->{"ID"} eq Globals_Constants::CONSTRAINTS_INPUT_CONTAINS()) { $isMet = 1; }
		elsif ($content eq $value)
		{
			$isMet = ($constraint->{"ID"} eq Globals_Constants::CONSTRAINTS_INPUT_EQUAL() ? 1 : 0);
		}
	}
	
	return $isMet;
}

#Returns a hash including the expected targets, either the ones associated with the additional entries or with all the other ones.
sub GetOutputEntryContentTargets
{
	my %targets = %{$_[0]};
	my $isAdditional = $_[1];

	my %targetsOut;
	
	if ($isAdditional eq 1)
	{
		#The targets hash contains a Globals_Constants::INPUT_ENTRY_ADDITIONALS() entry for sure.		
		my $i = -1;
		foreach my $target (@{$targets{Globals_Constants::INPUT_ENTRY_ADDITIONALS()}})
		{
			$i++;
			$targetsOut{$i} = $target;
		}		
	}
	else
	{
		foreach my $key (keys %targets)
		{
			if ($key ne Globals_Constants::INPUT_ENTRY_ADDITIONALS())
			{
				$targetsOut{$key} = $targets{$key};
			}
		}
	}
	
	return %targetsOut;
}

#Returns the Output_Entry associated with the input information.
sub GetOutputEntry
{
	my $htmlClass = $_[0];

	my $outEntry = GetOutputEntryContent($htmlClass, 0);
	my %content = %{$outEntry->{"Content"}};
	my $remoteImg = 0;

	if (GetOutputEntryAdditionalToo(\%{$htmlClass->{"Targets"}}) eq 1)
	{
		#Better analysing additionals even when the main analysis was wrong to make sure that the LastI
		#value is as good as possible (i.e., no old information included in future entries).
		
		if ($outEntry->{"LastI"} > $htmlClass->{"LastI"}) { $htmlClass->{"LastI"} = $outEntry->{"LastI"}; }
		my $tempVar = GetOutputEntryContent($htmlClass, 1);
		my %additionals = %{$tempVar->{"Content"}};
		
		if ($outEntry->{"IsOK"})
		{
			if ($tempVar->{"IsOK"})
			{
				$remoteImg = 1;
				my $body = $content{Globals_Constants::INPUT_ENTRY_BODY()};
				foreach my $key (sort keys %additionals)
				{
					$body .= "<br/><br/>[ADDITIONAL " . $key . "]<br/>" . $additionals{$key};
				}
				
				$content{Globals_Constants::INPUT_ENTRY_BODY()} = $body;
			}
			else
			{
				#One of the additional fields constraints hasn't been met and the whole entry is invalid.
				$outEntry->{"IsOK"} = 0;		
			}		
		}
		
		if ($tempVar->{"LastI"} > $outEntry->{"LastI"}) { $outEntry->{"LastI"} = $tempVar->{"LastI"}; }
	}
		
	if ($outEntry->{"IsOK"} and $remoteImg)
	{
		#There are various elements in the body (i.e., main and, at least, one additional) and better removing
		#all the imgs to ensure the visibility of all of them.
		my $body = $content{Globals_Constants::INPUT_ENTRY_BODY()};
		my $length = length($body);
		
		$content{Globals_Constants::INPUT_ENTRY_BODY()} =
		(
			HTML_Parse_Common::EntityAndArgsExist($body, $length, "img", \@{("src")}) ?
			HTML_Parse_Common::RemoveImgOccurrences($body, $length) : $body
		);
	}
	
	%{$outEntry->{"Content"}} = %content;
				
	return $outEntry;
}

#Performs all the required actions to make sure that the input string meets the expected format in the entry body.
sub UpdateBody
{
	my $input = $_[0];
	my $length = $_[1];

	#img entities are relevant because of the peculiar treatment that most of HTML viewers give to it, which might affect the
	#visibility of some of the elements (e.g., additionals not seen because of displaying the img of the main one).
	my $output =
	(
		HTML_Parse_Common::EntityAndArgsExist($input, $length, "img", \@{("src")}) eq 0 ?
		$input : HTML_Parse_Common::RemoveImgOccurrences($input, $length)
	);
	
	return $output;
}

#Determines whether the given output entry is valid (= its body is OK).
sub OutputEntryIsOK
{
	my %content = %{$_[0]};
	
	return 
	(
		exists $content{Globals_Constants::INPUT_ENTRY_BODY()} or
		!defined($content{Globals_Constants::INPUT_ENTRY_BODY()}) or
		length(Accessory::Trim($content{Globals_Constants::INPUT_ENTRY_BODY()})) < 1 ? 0 : 1
	);
}

#Determines whether the current input entries include additionals (which require a special analysis) or not.
sub GetOutputEntryAdditionalToo
{
	my %targets = %{$_[0]};
	
	my $outVar = 0;
	
	if (exists $targets{Globals_Constants::INPUT_ENTRY_ADDITIONALS()})
	{
		if (scalar(@{$targets{Globals_Constants::INPUT_ENTRY_ADDITIONALS()}}) > 0) { $outVar = 1; }
	}
	
	return $outVar;
}

1;