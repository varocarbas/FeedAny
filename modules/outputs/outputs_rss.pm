package Outputs_RSS;
use Time::Piece;

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

sub AddHTMLSupport
{
	my $html = $_[0];
	my $id = $_[1];
	
	my $length = length($html);
	
	{
		no warnings "once";
	
		foreach my $tag (values %Globals_Variables::HTMLTags)
		{
			my $i = Accessory::IndexOfOutsideQuotes($html, $tag);
			if ($i < 0) { next; }
			
			$i = Accessory::IterateThroughStringWhile($html, $length, " ", $i - 1, 1);
			if ($i < 0 or substr($html, $i, 1) ne "<") { next; }
			
			$i = Accessory::IndexOfOutsideQuotes($html, ">", $i);
			if ($i >= 0) { return 1; }
		}			
	}
	
	return 0;
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
	
	foreach $input (keys %content)
	{
		{
			no warnings "once";
			
			my $id = $Globals_Variables::InputToRSS{$input};
			my $content = $content{$input};
			
			if
			(
				$id == Globals_Constants::RSS_ENTRY_LINK() and
				length(Accessory::Trim($content)) > 0
			)
			{ $url = $content; }
			
			$outEntry .= AddRSSEntryLine
			(
				$content, $indentLevels[1], $id, AddHTMLSupport($content, $id)
			);			
		}
	}
	
	$outEntry .= AddRSSEntryLine($url, $indentLevels[1], Globals_Constants::RSS_ENTRY_GUID(), 0);	
	
	return ($outEntry . AddRSSEntryLine("</item>", $indentLevels[0]));
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