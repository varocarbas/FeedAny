package Inputs_Checks;

#Validity check for the limit inputs. 
sub CheckInputLimit
{
	my $input = $_[0];
	
	my $limit = undef;	
	use Scalar::Util qw(looks_like_number);
	
	if (looks_like_number($_[0]))
	{
		$limit = $input;
		if ($limit < 1 or $limit > $Globals_Variables::GenericLimits{Globals_Constants::LIMITS_INPUT_MAX_ENTRIES()})
		{
			$limit = $Globals_Variables::GenericLimits{Globals_Constants::LIMITS_INPUT_MAX_ENTRIES()};
		}
	}

	return $limit;
}

#In charge of pre-analysing the input entries.
sub CheckInputEntry
{
	return (scalar(@_) < 1 or length(Accessory::Trim($_[0])) < 1 ? undef : $_[0]);
}

#Performs a preliminary validity check for the URL inputs.
sub CheckInputURL
{
	my $input = $_[0];
	my $input2 = lc($input);

	my @tempArray = CheckURLProtocol($input, $input2);

	return (!@tempArray ? undef : $tempArray[0] . $tempArray[1]);
}

#Performs a simple validity analysis on the input URL.
sub CheckURLProtocol
{
	my @output = ();
	my $urlOut = $_[0];
	my $urlIn2 = $_[1];

	my @starts = ("http://", "https://");
	my $protocol = "";
	
	foreach my $start (@starts)
	{
		$length = length($start);
		
		if (substr($urlIn2, 0, $length) eq $start)
		{
			$urlOut = substr($urlOut, $length);
			$protocol = $start;
			last;
		}
	}
	
	if ($protocol eq "") { $protocol = "http://"; }
	
	push @output, $protocol;
	push @output, $urlOut;

	return @output;
}

#Confirms that there are inputs for all the basic input entries.
sub InputsAreOKBasic
{
	my %inputs = %{$_[0]};
	
	{
		no warnings 'once';

		foreach $basic (@Globals_Variables::InputBasic)
		{
			my $found = 0;
			
			if (exists $inputs{$basic})
			{
				if (length(Accessory::Trim($inputs{$basic}->{"Value"})) > 0) { $found = 1; }
			}
			
			if ($found eq 0) { Errors::ShowError(Globals_Constants::ERROR_INPUT_BASIC()); }
		}
	}
	
	#There is no need to return any variable because of the potential error severity.
	#Any error here would immediately stop the execution of the program.
}

#Performs a basic validity check of the input information.
sub InputsAreOK
{
	my %inputs = %{$_[0]};
	
	InputsAreOKBasic(\%inputs);
	#Reaching this point means that all the basic requirements have been successfully met.

	return 1;
}

1;