package HTML_Parse_Common;

#Determines whether the given HTML entity tag is closing (includes "/") or not.
sub EntityTagIsClosing
{
	my $tag = $_[0];
	my $length = $_[1];
	if ($length < 2) { return undef; }

	$length--;	
	my $isClosing = 0;
	my $tempI = index($tag, "/");
	
	if ($tempI eq 0) { $tag = substr($tag, 1, $length); }
	elsif ($tempI eq $length) { $tag = substr($tag, 0, $length); }
	else { $tag = undef; }
	
	return $tag;
}

#Returns the last HTML entity/attribute index (i.e., first index right after its definition).
sub GetEntityAttributeNameLastI
{
	my $html = $_[0];
	my $length = $_[1];
	my $i0 = $_[2];
	my $type = $_[3];
	
	if ($length - $i0 eq 1) { return 0; }
	
	my $target = ($type eq Globals_Constants::HTML_TYPE_ENTITY() ? ">" : "=");
	
	for (my $i = $i0; $i < $length; $i++)
	{
		my $bit = substr($html, $i, 1);

		if ($type eq Globals_Constants::HTML_TYPE_ENTITY() and $bit eq "/")
		{
			#The given entity tag being closing/opening is irrelevant here.
		}
		elsif ($bit eq " " or $bit eq $target) { return $i - 1; }
	}
	
	return -1;
}

#Confirms whether the given string matches one of the supported HTML entity names or not.
sub MatchEntityID
{
	my $input = $_[0];	
	
	if (!defined($input)) { return -1; }
	$input = lc($input);

	{
		no warnings "once";
		
		foreach my $key (keys %Globals_Variables::HTMLTags)
		{
			if ($input eq $Globals_Variables::HTMLTags{$key}) { return $key; }
		}		
	}
	
	return -1;
}

#Returns the start/end indices defining the main contents (e.g., <a href='link'> from <a href='link'>link</a>) of the next valid HTML entity.
sub GetNextHTMLEntityMainContents
{
	my $html = $_[0];
	my $length = $_[1]; 
	my $lastI = $_[2];
	
	my $i;
	my @outArray = (-1, -1, undef);
	
	foreach my $tag (values %Globals_Variables::HTMLTags)
	{	
		my $i0 = Accessory::IndexOfOutsideQuotes($html, $tag . " ", $lastI);
		if ($i0 < 0) { next; }
		$i = $i0;
		
		$i = Accessory::IterateThroughStringWhile($html, $length, " ", $i - 1, 1);
		if ($i < 0 or substr($html, $i, 1) ne "<") { next; }
		
		my $i2 = Accessory::IndexOfOutsideQuotes($html, ">", $i);
		if ($i2 > 0)
		{
			if (!defined($outArray[2]) or ($i < $outArray[0]))
			{
				$outArray[0] = Accessory::IterateThroughStringWhile($html, $length, " ", $i0 + length($tag) + 1, 1);
				$outArray[1] = $i2;
				$outArray[2] = $tag;				
			}
			
			$i = $i2;			
		}
	}
		
	return @outArray;	
}

#Determines whether the input HTML code contains a valid (at least, in appearance) version of the target entity and arguments
sub EntityAndArgsExist
{
	my $html = lc($_[0]);
	my $length = $_[1];
	my $entity = $_[2]; 
	my @args = @{$_[3]};

	my $i = 0;
	
	while ($i > -1)
	{
		$i = Accessory::IndexOfOutsideQuotes($html, $entity, $i + 1);
		if ($i < 2) { next; }

		my $i2 = Accessory::IterateThroughStringWhile($html, $length, " ", $i - 1, -1);
		if ($i2 < 0 or substr($html, $i2, 1) ne "<") { next; }

		$i2 = Accessory::IndexOfOutsideQuotes($html, ">", $i);
		if ($i2 <= $i) { next; }

		#An apparently valid main entity has been found. Now the arguments have to be analysed.
		my $argsOK = 1;
		
		foreach my $arg (@args)
		{
			my $i3 = Accessory::IndexOfOutsideQuotes($html, $arg);
			if ($i3 <= $i or $i3 >= $i2)
			{
				$argsOK = 0;
				last;
			}
			
			$i3 = Accessory::IterateThroughStringWhile($html, $length, " ", $i3 + 1, 1);
			if ($i3 < 0 or substr($html, $i3) ne "=")
			{
				$argsOK = 0;
				last;
			}			
		
			$i3 = Accessory::IterateThroughStringWhile($html, $length, " ", $i3 + 1, 1);
			if ($i3 < 0 or !defined(Accessory::GetUnescapedQuote($html, $i3)))
			{
				$argsOK = 0;
				last;
			}			
		}
		
		if ($argsOK) { return 1; }
	}

	return 0; 
}

#Returns an updated version of the input HTML code where all the occurrences of the target HTML entity have been removed. 
sub RemoveImgOccurrences
{
	my $html = $_[0];
	my $length = $_[1];

	my @startEnd = ("img", ">");
	
	return RemoveHTMLBits($html, $length, \@startEnd, 1, 1);
}

#Performs some preliminary corrections (e.g., removing comments) on the raw HTML code, in order to facilitate
#the subsequent parsing actions.
sub PreprocessHTML
{
	my $html = $_[0];
	my $length = $_[1];

	my $htmlOut = PreprocessHTMLRemoveComments($html, $length);
	
	return $htmlOut;
}

#Called by PreprocessHTML to remove comments.
sub PreprocessHTMLRemoveComments
{
	my $html = $_[0];
	my $length = $_[1];

	my @startEnd = ("<!--", "-->");
	return RemoveHTMLBits($html, $length, \@startEnd, 0, 0);	
}

#Removes all the chunks in the input HTML code defined by the given start/end substrings.
sub RemoveHTMLBits
{
	my $html = $_[0];
	my $length = $_[1];
	my @startEnd = @{$_[2]};
	my $outsideQuotes = @{$_[3]};
	my $type = @{$_[4]};
	
	my $html2 = lc($html);
	my $lengthEnd = length($startEnd[1]);
	my $htmlOut = "";
	my $i = 0;
	
	while(1)
	{
		my $tempI = RemoveHTMLBitsGetIndex($html2, $startEnd[0], $i, $outsideQuotes);
		if (!RemoveHTMLBitsStartFound($html2, $length, $tempI, $type))
		{
			$htmlOut .= substr($html, $i);
			last;
		}
		else
		{
			$htmlOut .= substr($html, $i, $tempI - $i);
			$tempI = RemoveHTMLBitsGetIndex($html2, $startEnd[1], $tempI, $outsideQuotes);
			if ($tempI < 0) { last; }
			$i = $tempI + $lengthEnd + 1;
		}
	}
	
	return $htmlOut;	
}

#Called from RemoveHTMLBits to get the given index by accounting for the given conditions (i.e., quotes being relevant or not).
sub RemoveHTMLBitsGetIndex
{
	my $html = $_[0];
	my $target = $_[1];
	my $i = $_[2];
	my $outsideQuotes = $_[3];
	
	return ($outsideQuotes ? Accessory::IndexOfOutsideQuotes($html, $target, $i) : index($html, $target, $i));
}

#Determines whether the given index represents a valid starting point, as expected by RemoveHTMLBits.
sub RemoveHTMLBitsStartFound
{
	my $html2 = $_[0];
	my $length = $_[1];
	my $tempI = $_[2];
	my $type = $_[3];
	
	my $found = 0;
	
	if ($tempI < 0) {}
	elsif ($type eq 0) { $found = 1; }
	elsif ($type eq 1)
	{
		#It is a specific case of a HTML entity where only the opening "<" matters.
		if ($tempI > 1)
		{
			$tempI = Accessory::IterateThroughStringWhile($html2, $length, " ", $tempI - 1, -1);
			if ($tempI > -1 and substr($html2, $tempI, 1) eq "<") { $found = 1; }	
		}
	}
	
	return $found;
}

1;