package HTML_Main;

#Navigates to the input URL and returns its HTML code.
sub GetHTML
{
	my $url = $_[0];

	my $contents = qx{wget --user-agent=\"FeedAny HTML grabber\" --quiet --output-document=- $url};

	if (length(Accessory::Trim($contents)) < 1)
	{
		Errors::ShowError(Globals_Constants::ERROR_HTML_GRABBING(), $url);
	}

	return $contents;
}

#Returns the domain and protocol for the input URL. For example, "site.com"/"http" for
#"http://site.com/page1".
sub GetDomainProtocolFromURL
{
	my $url = $_[0];

	my @outArray = (lc($url), "");

	foreach my $protocol ("https://", "http://")
	{
		if (index($outArray[0], $protocol) eq 0)
		{
			$outArray[0] = substr($outArray[0], length($protocol));
			$outArray[1] = $protocol;
			last;
		}
	}

	if (index($outArray[0], "www.") eq 0) { $outArray[0] = substr($outArray[0], 4); }

	$i = index($outArray[0], "/");
	$outArray[0] = ($i < 0 ? $outArray[0] : substr($outArray[0], 0, $i));
	
	return @outArray;
}

1;
