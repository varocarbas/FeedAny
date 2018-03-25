package Input_Entry;

sub Instantiate
{
	my $type = shift;
	my %params = @_;
	my $instance = {};
	
	#Variable containing the main value of the given item. It might be a string, numeric or Html_Entity instance.
	if (defined($params{"Value"})) { $instance->{"Value"} = $params{"Value"}; }
	
	#Array of strings used when dealing with INPUT_ENTRY_ADDITIONALS, which might contain any number of elements.
	@{$instance->{"Array"}} = (defined($params{"Array"}) ? @{$params{"Array"}} : ());
	 
	bless $instance, $type;  
}


1;