package Input;

sub Instantiate
{
	my $type = shift;
	my %params = @_;
	my $instance = {};
	
	#String variable with the name of the given input.
	if (defined($params{"Name"})) { $instance->{"Name"} = $params{"Name"}; }

	#Hash listing all the url types (constants with the heading "INPUT_URL_") => values (string).
	%{$instance->{"URLs"}} = (defined($params{"URLs"}) ? %{$params{"URLs"}} : ());
	
	#Hash with all the input entry types (keys of %Globals_Variables::InputEntryVars) => associated Input_Entry instance(s).
	#Globals_Constants::EntriesAdditional is associated with an array and all the other types with a single instance.
	%{$instance->{"Entries"}} = (defined($params{"Entries"}) ? %{$params{"Entries"}} : ());	
	
	#Hash listing all the limit types (constants with the heading "INPUT_MAX_") => values (numeric).
	%{$instance->{"Limits"}} = (defined($params{"Limits"}) ? %{$params{"Limits"}}: ());	
	
	bless $instance, $type; 
}

1;