package Output_Entry;

sub Instantiate
{
	my $type = shift;
	my %params = @_;
	my $instance = {};
	
	#Hash including all the inputed entry types (keys of %Globals_Variables::InputEntryVars) => content (string).
	%{$instance->{"Content"}} = (defined($params{"Content"}) ? %{$params{"Content"}} : ());

	#Integer variable used accessorily while parsing the main entry information, stored in the aforementioned variables.
	$instance->{"LastI"} = (defined($params{"LastI"}) ? $params{"LastI"} : 0);	
	
	#Boolean variable indicating whether the given instance is valid or not.
	$instance->{"IsOK"} = (defined($params{"IsOK"}) ? $params{"IsOK"} : 1);	
		
	bless $instance, $type;  
}


1;