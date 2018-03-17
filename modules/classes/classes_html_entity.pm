package Html_Entity;

sub Instantiate
{
	my $type = shift;
	my %params = @_;
	my $instance = {};
	
	#----- Variables used while parsing the HTML code.
	
	#Integer variable refering to some index within the html string (not necessarily the variable below).
	$instance->{"LastI"} = (defined($params{"LastI"}) ? $params{"LastI"} : 0);	
		
	#String variable containing a relevant part of the HTML code defining this entity. It might only be a portion of it.	
	if (defined($params{"HTML"})) { $instance->{"HTML"} = $params{"HTML"}; }
	
	#Boolean variable indicating whether a given target (the whole entity or any other one) has been found.
	$instance->{"Found"} = (defined($params{"Found"}) ? $params{"Found"} : 0);
	
	#Integer variable refering to an index relevant at some point during the HTML parsing process.
	$instance->{"TempI"} = (defined($params{"TempI"}) ? $params{"TempI"} : -1);	
	#------------------------------------------------------
	
	
	#----- Variables containing the final information defining the given entity.
		
	#Integer variable including the type of the given HTML entity (constants with the heading "HTML_ENTITY_").
	if (defined($params{"Type"})) { $instance->{"Type"} = $params{"Type"}; }
		
	#Integer variable referring to the index of the entity name's last character.
	if (defined($params{"NameI"})) { $instance->{"NameI"} = $params{"NameI"}; }
	
	#Integer variable referring to the index of the ">" which closes the entity main definition, right before the content.
	if (defined($params{"CloseI"})) { $instance->{"CloseI"} = $params{"CloseI"}; }
	
	#Integer variable referring to the index of the "<" which starts the entity closing tag, right after the content.
	if (defined($params{"CloseI2"})) { $instance->{"CloseI2"} = $params{"CloseI2"}; }
	
	#Hash including all the attributes (constants with the heading "HTML_ATTRIBUTE_") types => contents associated
	#with the given HTML entity.
	%{$instance->{"Attributes"}} = (defined($params{"Attributes"}) ? %{$params{"Attributes"}} : ());
	
	#String variable included the content of the given HTML entity, understood as the text after the ">" indexed by CloseI.
	if (defined($params{"Content"})) { $instance->{"Content"} = $params{"Content"}; }
	
	#------------------------------------------------------
	
	bless $instance, $type;  
}

1;