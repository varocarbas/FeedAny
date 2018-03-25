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
	
	#Hash with all the input entry types (keys of %Globals_Variables::InputEntryVars) => Input_Entry instance.
	%{$instance->{"Entries"}} = (defined($params{"Entries"}) ? %{$params{"Entries"}} : ());	
	
	#Array listing all the additional input entries (if any). Their outputs will be stored together with the body ones (i.e., Globals_Constants::INPUT_ENTRY_BODY()).
	@{$instance->{"EntriesAdditional"}} = (defined($params{"EntriesAdditional"}) ? @{$params{"EntriesAdditional"}} : ());
	
	#Hash listing all the limit types (constants with the heading "INPUT_MAX_") => values (numeric).
	%{$instance->{"Limits"}} = (defined($params{"Limits"}) ? %{$params{"Limits"}}: ());	
	
	bless $instance, $type; 
}

1;