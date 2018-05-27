package Input_Constraint;

sub Instantiate
{
	my $type = shift;
	my %params = @_;
	my $instance = {};
	
	#Constraint ID (constants with the heading "CONSTRAINTS_INPUT_).
	if (defined($params{"ID"})) { $instance->{"ID"} = $params{"ID"}; }
	
	#String variable including the constraint target value (e.g., "value" for the constraint "contains value").
	if (defined($params{"Value"})) { $instance->{"Value"} = $params{"Value"}; }
	
	#Integer variable referring to the logical operator relating the current constraint and the following one (if any).
	$instance->{"Operator"} = (defined($params{"Operator"}) ? $params{"Operator"} : Globals_Constants::OPERATORS_LOGICAL_AND());
	
	bless $instance, $type;  
}


1;