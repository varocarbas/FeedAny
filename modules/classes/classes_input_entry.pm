package Input_Entry;

sub Instantiate
{
	my $type = shift;
	my %params = @_;
	my $instance = {};
	
	#Variable containing the main value of the given item. It might be a string, numeric or Html_Entity instance.
	if (defined($params{"Value"})) { $instance->{"Value"} = $params{"Value"}; }
	 
	bless $instance, $type;  
}


1;