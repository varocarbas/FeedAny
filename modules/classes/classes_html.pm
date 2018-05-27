package Html;

sub Instantiate
{
	my $type = shift;
	my %params = @_;
	my $instance = {};
	
	#String variable including all the HTML text being parsed.
	if (defined($params{"HTML"})) { $instance->{"HTML"} = $params{"HTML"}; }
		
	#Integer variable referring to the location within the whole HTML text of the character under consideration.
	$instance->{"LastI"} = (defined($params{"LastI"}) ? $params{"LastI"} : 0);	
	 
	#Hash with all the input entry types (keys of %Globals_Variables::InputEntryVars) => associated target (Html_Target instance).
	#In some cases (e.g., dealing with a Globals_Constants::INPUT_ENTRY_ADDITIONALS entry), it is defined by entry type => array of targets.
	%{$instance->{"Targets"}} = (defined($params{"Targets"}) ? %{$params{"Targets"}} : ());
	 
	bless $instance, $type;  
}

1;