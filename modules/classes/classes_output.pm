package Output;

sub Instantiate
{
	my $type = shift;
	my %params = @_;
	my $instance = {};
	
	#String variable with the name of the given output.
	if (defined($params{"Name"})) { $instance->{"Name"} = $params{"Name"}; }

	#String variable including the main URL associated with the given output.
	if (defined($params{"URL"})) { $instance->{"URL"} = $params{"URL"}; }
	
	#Array of Output_Entry instances including all the contents extracted from the HTML code by applying the input rules.
	@{$instance->{"Entries"}} = (defined($params{"Entries"}) ? @{$params{"Entries"}} : ());
	
	bless $instance, $type; 
}

1;