package Input_Entry;

sub Instantiate
{
	my $type = shift;
	my %params = @_;
	my $instance = {};
	
	#Variable containing the main value of the given item. It might be a string, numeric or Html_Entity instance.
	if (defined($params{"Value"})) { $instance->{"Value"} = $params{"Value"}; }

	#Array of Input_Constraint instances including all the constraints associated with the given entry.
	#Note that the order in this array defines the constraint precedence (first -> last = left -> right).
	@{$instance->{"Constraints"}} = (defined($params{"Constraints"}) ? @{$params{"Constraints"}} : ());
	 
	bless $instance, $type;  
}


1;