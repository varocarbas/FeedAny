package Errors;

sub ShowError
{
	my $filePath;
	{
		no warnings "once";
		$filePath = $Globals_Variables::RootPath . $Globals_Variables::IONames{Globals_Constants::IO_ERRORS_FILE()};
	}
	
	my $message = (scalar(@_) > 1 && $_[1] ? "WARNING" : "ERROR") . " --- " . $_[0] . "\n";
	
	if (!IO::TextToFile($message, $filePath))
	{
		$message = "There was an error while writing to \"" . $filePath . "\"."
	}
	
	{
		no warnings "once";
		
		#Global flag avoiding to print multiple messages for the same error.
		$Globals_Variables::ErrorDisplayed = 1;		
	}
	
	print($message);
	
	if (scalar(@_) > 2 && $_[2]) { exit(1); }
}

#Returns the message associated with the given error ID.
sub GetErrorMessage
{
	my $id = $_[0];
	my $input = (scalar(@_) > 1 ? $_[1] : "");
	my $input2 = (scalar(@_) > 2 ? $_[2] : "");
	my $message = "";
	
	if ($id == Globals_Constants::ERROR_INPUT_LABEL_REPEATED())
	{
		$message = "The label \"" . $input . "\" is repeated."
	}
	elsif ($id == Globals_Constants::ERROR_INPUT_VALUE_FORMAT())
	{
		$message = "The input value for \"" . $input . "\" doesn't match the expected format.";
	}
	elsif ($id == Globals_Constants::ERROR_INPUT_BASIC())
	{
		{
			no warnings 'once';
		
			$message = "The input file \"" . $Globals_Variables::CurInputFile;
			$message .= "\" doesn't include one of the basic fields (";
			
			$i_max = scalar(@Globals_Variables::InputBasic) - 1;
		}
		
		for (my $i = 0; $i <= $i_max; $i++)
		{
			if ($i > 0) { $message .= ($i == $i_max ? " and" : ",") . " "; }
			
			{
				no warnings 'once';
				$message .= "\"" . $Globals_Variables::InputLabels
				{
					$Globals_Variables::InputBasic[$i]
				}
				. "\"";		
			}
		}
		
		$message .= ").";
	}
	elsif ($id == Globals_Constants::ERROR_HTML_GRABBING())
	{
		$message = "There was an error while retrieving the HTML code from " . $input . ".";		
	}
	
	return $message;
}

1;