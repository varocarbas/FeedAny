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
	 
	#Hash including all the inputed entry types (keys of %Globals_Variables::InputEntryVars) => array of targets (Entity class instances).
	#Note that these arrays are ordered such that they match the expected HTML structure (first to last -> left to right). For example,
	#the HTML code <a title='title'><p> would be represented with two entities, a (attribute title->"title") and p (no attibute),
	#stored in the Targets array with the indices 0 and 1 respectively.	
	%{$instance->{"Targets"}} = (defined($params{"Targets"}) ? %{$params{"Targets"}} : ());
	
	#Equivalent to Targets, but for the additional input entries.
	%{$instance->{"TargetsAdditional"}} = (defined($params{"TargetsAdditional"}) ? %{$params{"TargetsAdditional"}} : ());
	 
	bless $instance, $type;  
}

1;