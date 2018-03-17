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
	
	if ($tempI == 0) { $tag = substr($tag, 1, $length); }
	elsif ($tempI == $length) { $tag = substr($tag, 0, $length); }
	else { $tag = undef; }
	
	return $tag;
}

#Returns the last index right after the HTML entity/attribute being currently analysed.
sub GetEntityAttributeNameLastI
{
	my $html = $_[0];
	my $length = $_[1];
	my $i0 = $_[2];
	my $type = $_[3];
	
	if ($length - $i0 == 1) { return 0; }
	
	my $target = ($type == Globals_Constants::HTML_TYPE_ENTITY() ? ">" : "=");
	
	for (my $i = $i0; $i < $length; $i++)
	{
		my $bit = substr($html, $i, 1);

		if ($type == Globals_Constants::HTML_TYPE_ENTITY() and $bit eq "/")
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

1;