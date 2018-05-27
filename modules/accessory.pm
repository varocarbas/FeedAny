package Accessory;

#Removes all blank spaces from the start/end of the input string.
sub Trim
{		
	my $output = $_[0];
	
	if (defined $output) { $output =~ s/^\s+|\s+$//g; }

	return $output;
}

#Returns the position in array where the target input is located or -1.
sub IndexOfArray
{
	my @array = @{$_[0]};
	my $target = $_[1];
	
	for (my $i = 0; $i < scalar(@array); $i++)
	{
		if ($array[$i] eq $target) { return $i; }
	}
	
	return -1;	
}

#Called by GetUnescapedQuote to perform some of the required actions.
sub GetUnescapedQuoteInternal
{
	my $input = $_[0];
	my $i = $_[1];
	my $maxI = $_[2];
	my $quote = $_[3];
	
	if ($i > 0)
	{
		my $bit2 = substr($input, $i - 1, 1);
				
		if (($bit2 eq $quote) or ($bit2 eq "\\")) { return undef; }
	}
	
	if ($i < $maxI)
	{
		if (substr($input, $i + 1, 1) eq $quote) { return undef; }
	}
			
	return $quote;
}

#Confirms whether the input character includes a supported and non-escaped quotes.
#Escaped quotes are those preceded by "\" or themselves.
sub GetUnescapedQuote
{
	my $input = $_[0];
	my $i = $_[1];
	if ($i < 0 or !defined($input)) { return undef; }
	
	my $maxI = length($input) - 1;
	if ($i > $maxI) { return undef; }
	
	my $bit = substr($input, $i, 1);	
	{
		no warnings "once";

		foreach my $quote (@Globals_Variables::Quotes)
		{
			if ($bit eq $quote)
			{
				return GetUnescapedQuoteInternal
				(
					$input, $i, $maxI, $quote 
				);
			}
		}		
	}
	
	return undef;
}

#Method used accessorily while performing within-quotes kind of string analyses.
sub UpdateInsideQuotes
{
	#@quotes is always a non-null array with two elements and
	#quoteNew one of the supported quotes.
	my @quotes = @{$_[0]};
	my $quoteNew = $_[1];
	
	my $i = ($quoteNew eq $Globals_Variables::Quotes[0] ? 0 : 1);	
	if (defined($quotes[$i])) { $quotes[$i] = undef; }
	else  { $quotes[$i] = $quoteNew; }

	return @quotes;
}

#Called internally by IndexOfOutsideQuotes & LastOutsideQuotes to perform their intrinsically identical actions.
sub OutsideQuotesCommon
{
	my $input = $_[0];
	my $target = $_[1];
	if (!defined($input) or !defined($target)) { return -1; }
	
	my $inputLen = length($input);
	my $targetLen = length($target);
	my $startI0 =
	(
		scalar(@_) > 2 and $_[2] > -1 and $_[2] <= $inputLen - $targetLen ? $_[2] : 0
	);
	if
	(
		$inputLen < 1 or $targetLen < 1 or
		$inputLen < $targetLen or index($input, $target, $startI0) < 0
	)
	{ return -1; }
	
	my $backwards = (scalar(@_) > 3 and $_[3] ? 1 : 0);
	my @quotes = (undef, undef);
	my $first = substr($target, 0, 1);

	my $step = 1;
	my $startI = $startI0;
	my $endI = $inputLen - $targetLen;
	if ($backwards)
	{
		$startI = $inputLen - 1;
		$endI = $startI0 + $targetLen - 1;
		$step = -1;
	}
	
	my $i = $startI - $step;
	while ($i ne $endI)
	{
		$i = $i + $step;
		
		my $bit = substr($input, $i, 1);
		if ($bit eq $first)
		{
			if (defined($quotes[0]) or defined($quotes[1])) { next; }
			
			if (substr($input, $i, $targetLen) eq $target) { return $i; }
		}
		else
		{
			my $tempVar = GetUnescapedQuote($input, $i);
			if (defined($tempVar))
			{
				@quotes = UpdateInsideQuotes(\@quotes, $tempVar);
			}
		}		
	}
	
	return -1;	
}

#This method is equivalent to the in-built index with the peculiarity that skips
#all the substrings inside valid quotes (i.e., equal, supported, non-escaped)
sub IndexOfOutsideQuotes
{
	return OutsideQuotesCommon($_[0], $_[1], (scalar(@_) > 2 ? $_[2] : -1));
}

#Similar to the aforementioned IndexOfOutsideQuotes but starting from the end of the string.
sub LastOutsideQuotes
{
	return OutsideQuotesCommon($_[0], $_[1], (scalar(@_) > 2 ? $_[2] : -1));
}

#Returns the starting/ending indices of the surrounding quotes of the given target or
#undef in case of not meeting the expected format.
sub ValueIsSurroundedByQuotes
{
	my $main = $_[0];
	my $target = $_[1];
	my $i00 = $_[2];	
	
	if (!defined($target) or !defined($main)) { return (); }
	
	my $mainLength = length($main);
	my $targetLength = length($target);	
	
	if
	(
		$mainLength < 1 or $targetLength < 1 or
		$i00 < 1 or $i00 + $targetLength > $mainLength - 1
	)
	{ return (); }

	my @outArray;
	my @starts = ($i00 - 1, $i00 + $targetLength);
	my @additions = (-1, 1);
	my $quote = undef;

	for (my $i0 = 0; $i0 < 2; $i0++)
	{
		my $i = $starts[$i0];
		while (substr($main, $i, 1) eq " ")
		{
			$i += $additions[$i0];
		}

		my $quote2 = GetUnescapedQuote($main, $i);
		
		if
		(
			!defined($quote2) or
			(
				defined($quote) and ($quote2 ne $quote)
			)
		)
		{ return (); }
	
		$outArray[$i0] = $i;		
	}

	return @outArray;
}

#Skips certain character before/after the input position. This is mostly useful while parsing
#HTML to ignore blank spaces.
sub IterateThroughStringWhile
{
	my $string = $_[0];
	my $length = $_[1];
	my $target = $_[2];
	my $i = $_[3];
	my $direction = $_[4];	
	
	my $maxI = $length - 1;
	if
	(
		!defined($string) or $length < 1 or undef($target) or
		$i < 0 or $i > $maxI or abs($direction) ne 1
	)
	{ return -1; }
	
	while (substr($string, $i, 1) eq $target)
	{
		$i += $direction;
		
		if
		(
			($direction eq -1 and $i eq 0) or
			($direction eq 1 and $i eq $maxI)
		)
		{ return $i; }
	}
	
	return $i;
}

#Returns the substring surrounded by two equal, supported, non-escaped quotes. In any other
#case, it returns undef.
sub GetElementInQuotes
{
	my $input = $_[0];
	my $length = $_[1];
	my $i0 = $_[2];
	
	$i = Accessory::IterateThroughStringWhile($input, $length, " ", $i0 - 1, -1);
	if ($i < 0) { return undef; }
		
	my $quote = Accessory::GetUnescapedQuote($input, $i);
	if (!defined($quote)) { return undef; }
		
	my $i2 = index($input, $quote, $i0);
	if ($i2 < 0 or !defined(Accessory::GetUnescapedQuote($input, $i2))) { return undef; }
	
	$i2 = Accessory::IterateThroughStringWhile($input, $length, " ", $i2 - 1, -1);	

	return substr($input, $i0, $i2 - $i0 + 1);	
}

1;