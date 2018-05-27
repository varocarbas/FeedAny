package IO;

#Performs all the initial I/O actions (e.g.,  deleting/creating files or folders).
sub InitialActionsIO
{
	{
		no warnings "once";
		
		my @files = ($Globals_Variables::IONames{Globals_Constants::IO_ERRORS_FILE()}, "wget-log");
	
		foreach my $file (@files)
		{
			my $path = $Globals_Variables::RootPath . $file;
		
			if (-e $path)
			{
				eval { unlink($path); };
				if ($@) { Errors::ShowError(Globals_Constants::ERROR_IO_FILE_DELETE(), $filePath); }
			}
		}		
	}
}

#Returns an array including all the lines of the target file. Only expected to be used with relatively small files.
sub FileLinesToArray
{
	my @lines;
	my $filePath = $_[0];
	
	if (!-e $filePath) { return (); }
	
	eval
	{
		open my $reader, '<', $filePath;
		chomp(@lines = <$reader>);
		close $reader;	
	};
	
	if ($@)
	{
		Errors::ShowError(Globals_Constants::ERROR_IO_FILE_READ(), $filePath);
		@lines = ();		
	}
	
	return @lines;
}

#Writes the input string to the target file. Only expected to be used with relatively small strings.
sub TextToFile
{
	my $text = $_[0];
	my $filePath = $_[1];		

	eval
	{
		open my $writer, '>', $filePath;
		print $writer $text;
		close $writer;
	};
	
	my $isOK = 1;
	
	if ($@)
	{
		Errors::ShowError(Globals_Constants::ERROR_IO_FILE_WRITE(), $filePath);
		$isOK = 0;
	}
	
	return $isOK;
}
 
1;