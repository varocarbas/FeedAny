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

1;