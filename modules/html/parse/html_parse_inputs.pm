package HTML_Parse_Inputs;

#Method used accessory while creating entity/atribute instances.
sub CreateEntityClassFromInputFirstActions
{
	my $input = $_[0];
	my $input2 = Accessory::Trim($input);
	
	my $length = length($input2);
	if ($length < 2) { return (); }

	if
	(
		(substr($input2, 0, 1) eq "{") and
		(substr($input2, $length - 1, 1) eq "}")
	)
	{
		$length -= 2;
		$input2 = substr($input2, 1, $length);
	}

	my @outArray;
	
	for (my $i0 = 0; $i0 < $length; $i0++)
	{
		my $i1 = Accessory::IndexOfOutsideQuotes($input2, "<", $i0);
		my $i2 = Accessory::IndexOfOutsideQuotes($input2, ">", $i1);
		if ($i1 < 0 or $i2 < 0) { return @outArray; }
	
		push @outArray, Accessory::Trim(substr($input2, $i1 + 1, $i2 - $i1 - 1));
	}
	
	return @outArray;
}

#Method used accessory while creating entity/atribute instances.
sub CreateEntityClassFromInputGetQuotes
{
	my $input = $_[0];
	my $quote = undef;
	my $found = 0;
	my @outArray = (-1, -1);
	
	for (my $i = 0; $i < length($input); $i++)
	{
		my $tempVar = Accessory::GetUnescapedQuote($input, $i);
		if (!defined($tempVar)) { next; }
		
		if (defined($quote))
		{
			if ($found)
			{
				#There is no possible valid scenario involving 3 unescaped quotes.
				return ();
			}
			
			if ($quote eq $tempVar)
			{
				$found = 1;
				$outArray[1] = $i;
			}
			else { return (); }
		}
		else
		{
			$quote = $tempVar;
			$outArray[0] = $i;
		}
	}
	
	return @outArray;
}

#Called by CreateEntityClassesFromInput to take care of the corresponding attribute.
sub CreateEntityClassFromInputGetAttribute
{
	my $class = $_[0];
	my $input = $class->{"HTML"};
	if (!defined($input) or length($input) < 1) { return $class; }
	
	my $i = Accessory::IndexOfOutsideQuotes($input, "=");
	if ($i < 1) { return $class; }

	my @beforeAfter =
	(
		Accessory::Trim(substr($input, 0, $i)),
		Accessory::Trim(substr($input, $i + 1))
	);

	$i = Accessory::IndexOfOutsideQuotes($beforeAfter[1], " ");
	if ($i < 0) { $class->{"HTML"} = undef; }
	else
	{
		$class->{"HTML"} = substr($beforeAfter[1], $i + 1);
		$beforeAfter[1] = substr($beforeAfter[1], 0, $i);
	}
	
	my @quotes = CreateEntityClassFromInputGetQuotes($beforeAfter[1]);
	if (scalar(@quotes) eq 0)
	{
		#Reaching this point means that there is something different than
		#two identical (' or ") unescaped quotes.
		return $class;
	}
	
	my %attributes = %{$class->{"Attributes"}};
	$attributes{lc(Accessory::Trim($beforeAfter[0]))} = substr
	(
		$beforeAfter[1], $quotes[0] + 1, $quotes[1] - $quotes[0] - 1
	);
	%{$class->{"Attributes"}} = %attributes;

	return $class;
}

#Called by CreateEntityClassesFromInput to take care of all the attributes.
sub CreateEntityClassFromInputGetAttributes
{
	my $input = $_[0];
	if (!defined($input) or length($input) < 1) { return (); }
	
	my $class = Html->Instantiate("HTML" => $input);	
	my $length = length($input);
	
	while (defined($class->{"HTML"}))
	{
		$class = CreateEntityClassFromInputGetAttribute($class);
	}
	
	return %{$class->{"Attributes"}};
}

#Performs the main actions to convert the HTML code (string) of the given input entry into the array of HTML_Entity instances which will be
#used during the subsequent analyses. Note that it is expected to be stored in an Html_Target instance, under "Entities". 
sub CreateEntityClassesFromInput
{
	my $input = $_[0];
	if (!defined($input) or length($input) < 1) { return (); }

	my @tempArray = CreateEntityClassFromInputFirstActions($input);
	if (scalar(@tempArray) eq 0) { return (); }	

	my @outEntities;

	foreach my $item (@tempArray)
	{
		my $i = Accessory::IndexOfOutsideQuotes($item, " ");
		my $bit = ($i < 0 ? $item : substr($item, 0, $i));

		my $id = HTML_Parse_Common::MatchEntityID($bit);
		if ($id < 0)
		{
			#Not including a supported HTML entity is an unfixable problem.
			#This part will be ignored, but there might be other worthy ones.
			next;
		}

		push @outEntities, Html_Entity->Instantiate("Type" => $id);
		if ($i > -1 and $i < length($item) - 1)
		{
			%{$outEntities[scalar(@outEntities) - 1]->{"Attributes"}} =
			CreateEntityClassFromInputGetAttributes
			(
				Accessory::Trim(substr($item, $i + 1))
			);			
		}
	}
	
	return @outEntities;
}

1;