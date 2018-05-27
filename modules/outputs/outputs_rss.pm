package Outputs_RSS;

#Generates the RSS code associated with the given output and writes it to the target file.
sub GenerateOutputRSS
{	
	my $output = $_[0];

	my $filePath;
	{
		no warnings "once";

		$filePath = $Globals_Variables::OutputDir . $output->{"Name"};
		$filePath .= $Globals_Variables::IONames{Globals_Constants::IO_OUTPUT_EXTENSION_RSS()}; 
	}
	
	IO::TextToFile(GetRSS($output), $filePath);
}

#Gets the RSS code associated with the given output.
sub GetRSS
{
	my $output = $_[0];
	
	my $outRSS = AddRSSStart($output);
	
	my @array = @{$output->{"Entries"}};
	my %content = %{$array[0]->{"Content"}};
	
	foreach my $entry (@{$output->{"Entries"}})
	{
		$outRSS .= AddRSSEntry($entry, $output->{"URL"});
	}
	
	return $outRSS . AddRSSEnd();
}

#Returns the starting part of the RSS code.
sub AddRSSStart
{
	my $output = $_[0];
	
	my $outRSS;
	my @firsts =
	(
		$Globals_Variables::RSSFormat{Globals_Constants::RSS_FORMAT_HEADING()},
		"<rss xmlns:atom=\"" . $Globals_Variables::RSSFormat{Globals_Constants::RSS_FORMAT_ATOM()} . "\" " .
		"version=\"" . $Globals_Variables::RSSFormat{Globals_Constants::RSS_FORMAT_VERSION()} . "\">"
	);
	foreach $first (@firsts) { $outRSS .= AddRSSEntryLine($first); }
	
	$outRSS .= AddRSSEntryLine("<channel>", 1);
	$outRSS .= AddRSSStartChannelDescription($output);
	
	return $outRSS;
}

#Returns the channel description for the given RSS code. It is always the same.
sub AddRSSStartChannelDescription
{
	my $output = $_[0];
	
	my $title = "RSS feed of " . $output->{"Name"};
	my $indentLevel = 2;

	my $outRSS = AddRSSEntryLine($title, $indentLevel, Globals_Constants::RSS_ENTRY_TITLE());
	$outRSS .= AddRSSEntryLine
	(
		"<atom:link rel=\"self\" href=\"" . $output->{"URL"} . "\" type=\"application/rss+xml\"/>", $indentLevel
	);
	
	$outRSS .= AddRSSEntryLine
	(
		$output->{"URL"}, $indentLevel, Globals_Constants::RSS_ENTRY_LINK()
	);
	$outRSS .= AddRSSEntryLine
	(
		$title, $indentLevel, Globals_Constants::RSS_ENTRY_DESCRIPTION()
	);	

	return $outRSS;
}

#Returns the last part of the RSS code. Always the same.
sub AddRSSEnd
{
	return (AddRSSEntryLine("</channel>", 1) . AddRSSEntryLine("</rss>", 0));
}

#Determines whether the given input string (i.e., one of the entries of the generated XML file) contains HTML code or not.
#Note that this analysis has to account for much more than what is considered for input webpages (i.e., $Globals_Variables::HTMLTags).
sub HasHTMLCode
{
	my $html = lc($_[0]);
	my $length = $_[1];
	
	my $i = 0;
	
	while(1)
	{
		$i = Accessory::IndexOfOutsideQuotes($html, "<", $i);
		if ($i < 0 or $i >= $length - 2) { last; }
				
		my $i2 = Accessory::IndexOfOutsideQuotes($html, ">", $i);
		if ($i2 >= $i + 1) { return 1; }
		$i++;
	}
	
	return 0;
}

#Adds the final part to the given RSS entry.
sub AddRSSEntryFinal
{
	my @indentLevels = @{$_[0]};
	my $url = $_[1];
	my @urlIDs = @{$_[2]};
	
	my $output = "";
	
	foreach my $id (@urlIDs) { $output .= AddRSSEntryLine($url, $indentLevels[1], $id, 0); }
	
	use POSIX qw(strftime);
	$output .= AddRSSEntryLine
	(
		strftime("%a, %d %b %Y %H:%M:%S %z", localtime(time())), $indentLevels[1], Globals_Constants::RSS_ENTRY_DATE(), 0
	);
	
	return ($output . AddRSSEntryLine("</item>", $indentLevels[0]));
}

#Returns a whole RSS entry, including all the information in the given Output_Entry instance Content.
sub AddRSSEntry
{
	my $entry0 = $_[0];
	my $url0 = $_[1];
	
	my $url = $url0;
	my @indentLevels = (2, 3);
	my $outEntry = AddRSSEntryLine("<item>", $indentLevels[0]);
	
	my %content = %{$entry0->{"Content"}};
	my $linkFound = 0;
	
	foreach $input (keys %content)
	{
		{
			no warnings "once";
			
			my $id = $Globals_Variables::InputToRSS{$input};
			my $content = $content{$input};
			
			if ($id == Globals_Constants::RSS_ENTRY_LINK())
			{
				$linkFound = 1;
				if (length(Accessory::Trim($content)) > 0) { $url = $content; }
				else { $content = $url; }
			}
			
			my $html = 0;
			my $length = length($content);
			if ($length > $Globals_Variables::GenericLimits{Globals_Constants::LIMITS_RSS_MAX_LENGTH()})
			{
				#A so long entry is almost certainly unintended. It was most likely provoked by a malformed HTML code.
				$html = 1;
				$content = substr($content, 0, $Globals_Variables::GenericLimits{Globals_Constants::LIMITS_RSS_MAX_LENGTH()});
			}
			else { $html = HasHTMLCode($content, $length); }
			
			$outEntry .= AddRSSEntryLine($content, $indentLevels[1], $id, $html);			
		}
	}
	
	my @urlIDs = (Globals_Constants::RSS_ENTRY_GUID());
	if (!$linkFound) { push @urlIDs, Globals_Constants::RSS_ENTRY_LINK(); }
	
	return $outEntry . AddRSSEntryFinal(\@indentLevels, $url, \@urlIDs);
}

#All the RSS closing tags follow the same rules, but some of the opening ones don't.
sub GetRSSEntryOpen
{
	my $type = $_[0];

	return
	(
		exists $Globals_Variables::RSSTagsOpen{$type} ?
		$Globals_Variables::RSSTagsOpen{$type} :
		"<" . $Globals_Variables::RSSTags{$type} . ">"
	);
}

#Adds a whole line to the RSS code by also accounting for the applicable indentation.
sub AddRSSEntryLine
{
	my $text0 = $_[0];
	my $indentLevel = (scalar(@_) > 1 ? $_[1] : 0);
	my $type = (scalar(@_) > 2 ? $_[2] : -1);
	my $supportHTML = (scalar(@_) > 3 ? $_[3] : 0);
	
	my $text = $text0;
	if ($supportHTML)
	{
		$text =
		(
			$Globals_Variables::RSSTagsHTMLCode[0] . $text .
			$Globals_Variables::RSSTagsHTMLCode[1]
		);
	}

	if ($type > -1)
	{
		{
			no warnings "once";
			
			$text =
			(
				GetRSSEntryOpen($type) . $text . "</" .
				$Globals_Variables::RSSTags{$type} . ">"
			);			
		}
	}
	
	return AddRSSIndentation($indentLevel) . $text . "\n";
}

#Returns the instructed indentation (i.e., number of spaces associated with the current indentation level within the RSS code).
sub AddRSSIndentation
{
	my $level = $_[0];
	if ($level < 1) { return ""; }
	
	my $target;
	{
		no warnings "once";
		$target = $level * $Globals_Variables::RSSFormat
		{
			Globals_Constants::RSS_FORMAT_INDENTATION()
		};
	}
	
	my $outIndent = "";
	my $count = 0;
	
	while ($count < $target)
	{
		$count++;
		$outIndent .= " ";
	}
	
	return $outIndent;	
}

1;