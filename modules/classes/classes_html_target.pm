package Html_Target;

sub Instantiate
{
	my $type = shift;
	my %params = @_;
	my $instance = {};
	
	#Array including all the target HTML entities (Html_Entity class instances).
	#Note that this array is ordered such that it matches the expected HTML structure (first to last -> left to right). For example,
	#the HTML code <a title='title'><p> would be represented with two entities, a (attribute title->"title") and p (no attibute),
	#stored in the Targets array with the indices 0 and 1 respectively.
	@{$instance->{"Entities"}} = (defined($params{"Entities"}) ? @{$params{"Entities"}} : ());
	
	#Array of Input_Constraint instances associated with the given input entry.
	@{$instance->{"Constraints"}} = (defined($params{"Constraints"}) ? @{$params{"Constraints"}} : ());
	
	bless $instance, $type;  
}

1;