package HTML_Parse_Entities;

#Called by FindEntityMainDefinitionInternal to perform some of its actions.
sub FindEntityMainDefinitionInternalFirst
{
	my $html = $_[0];
	my $length = $_[1];	
	my $lastI = $_[2];
	my $tag = $_[3];
	my $lengthTag = $_[4];	
	my $backwards = $_[5];
	
	if
	(
		($backwards && $lastI < $lengthTag) ||
		(!$backwards && $lastI > $length - $lengthTag)
	)
	{ return -1; }
		
	my $outI = -1;
	my $i = ($backwards ? index(substr($html, 0, $lastI), $tag) : index($html, $tag, $lastI));
	if ($i < 0)
	{
		#The input HTML code doesn't include the target entity name.
		return -1;
	}

	if ($backwards)
	{
		#By bearing in mind that $lastI was generated after having analysed some argument names/values,
		#it should be clear the reason for the condition below these lines: tag + starting symbol (<) +
		#blank space between entity name and argument.
		if ($lastI < $lengthTag + 2) { return -1; }

		for ($i = $lastI - 1; $i >= 0; $i--)
		{
			if (substr($html, $i, 1) eq ">")
			{
				#Bear in mind that the whole point is finding the initial part of the entity tag
				#associated with the attribute from which this analysis started. That character
				#is the end part a HTML entity, what can't exist under the afor conditions.
				return -1;
			}
			if (substr($html, $i, 1) ne "<") { next; }

			$i = Accessory::IterateThroughStringWhile($html, $length, " ", $i + 1, 1);
			if (substr($html, $i, $lengthTag) eq $tag) { $outI = $i; }
			
			#The target entity name and its starting symbol "<" have been found.
			last;
		}
	}
	else
	{
		while(1)
		{
			my $tempI = Accessory::IterateThroughStringWhile($html, $length, " ", $i - 1, -1);
			if (substr($html, $tempI, 1) eq "<")
			{
				#The start "<" symbol was found and, right after it, the target entity name.

				$outI = $i;
				last;
			}
			
			$i = Accessory::IndexOfOutsideQuotes($html, $tag, $i + 1);
			if ($i < 0)
			{
				#No valid reference to the target entity name could be found.
				return -1;
			}				
		}
	}
	
	if ($outI > -1)
	{
		my @starts = ($outI - 1, $outI + $lengthTag);
		my @vars = (-1, 1);
		
		for (my $i0 = 0; $i0 < 2; $i0++)
		{
			my $i = Accessory::IterateThroughStringWhile
			(
				$html, $length, " ", $starts[$i0], $vars[$i0]
			);

			if (substr($html, $i, 1) eq "/")
			{
				#No opening entity tag includes that symbol.
				return -1;
			}			
		}
	}

	return $outI;
}

#Called by GetNextEntityCloseI2s to perform some of its internal actions.
sub GetEntityOpenCloseSymbols
{	
	my $html = $_[0];
	my $length = $_[1];	
	my @inputs = @{$_[2]};
	
	my @outArray = (-1, -1);
	my @targets = ("<", ">");
	my @factors = (-1, 1);

	for (my $i0 = 0; $i0 < 2; $i0++)
	{
		my $i = $inputs[$i0] + $factors[$i0];
		if ($i < 0) { return (); }
		
		$i = Accessory::IterateThroughStringWhile
		(
			$html, $length, " ", $i, $factors[$i0]
		);
		if
		(
			substr($html, $i, 1) ne $targets[$i0]
		)
		{ return (); }

		$outArray[$i0] = $i;
	}
	
	return @outArray;
}

#Returns various indices to properly determine the closing part (in its widest sense) of the given
#HTML entity (or an error).
sub GetNextEntityCloseI2s
{	
	my $html = $_[0];
	my $length = $_[1];	
	my $i = $_[2];
	my $tag = $_[3];
	my $lengthTag = $_[4];

	my @outArray;
	
	while (1)
	{
		$i = Accessory::IndexOfOutsideQuotes($html, "/", $i);
		if ($i < 0 or $i >= $length - 2)
		{
			@outArray = ($i);
			last;
		}
		
		my $i2 = Accessory::IterateThroughStringWhile($html, $length, " ", $i + 1, 1);
		if ($i2 <= $length - $lengthTag and substr($html, $i2, $lengthTag) eq $tag)
		{
			@outArray = ($i, $i2 + $lengthTag - 1);
		}
		
		if (scalar(@outArray) == 0)
		{
			$i2 = Accessory::IterateThroughStringWhile($html, $length, " ", $i - 1, -1);
			if ($i2 >= $lengthTag and substr($html, $i2 - $lengthTag + 1 , $lengthTag) eq $tag)
			{
				@outArray = ($i2 - $lengthTag + 1, $i);
			}				
		}
		
		if (scalar(@outArray) == 2)
		{
			@outArray = GetEntityOpenCloseSymbols($html, $length, \@outArray);
			if (scalar(@outArray) == 2) { last; }
		}
		
		$i++;
	}

	return @outArray;
}

#The main deal when trying to match a HTML entity is finding its ending/starting point; what lies in between
#is quite irrelevant (= doesn't need to be filtered). The problem is that there might be various nested HTML
#entities making the determination of that ending point more difficult. This is where NestedEntitiesWithinAreOK
#comes in: it looks for other HTML entities with the same name, check their starting/ending points and confirms
#that the initial assumption regarding the closing tag of the given entity is right/wrong.
sub NestedEntitiesWithinAreOK
{
	my $html = $_[0];
	my $closeI = $_[1];	
	my $closeI2 = $_[2];
	my $tag = $_[3];
	my $lengthTag = $_[4];	
	
	my @openCloses = (0, 0);

	for (my $i = $closeI; $i < $closeI2; $i++)
	{
		my $bit = substr($html, $i, 1);
		if ($bit ne "<") { next; }

		$i = Accessory::IterateThroughStringWhile($html, $closeI2, " ", $i + 1, 1);
		if ($i < 0 or $i >= $closeI2) { last; }
					
		#Index of the last character of the current HTML entity name (if any).
		my $tempVar = HTML_Parse_Common::GetEntityAttributeNameLastI
		(
			$html, $closeI2, $i, Globals_Constants::HTML_TYPE_ENTITY()
		);
		
		if ($tempVar < 0)
		{
			#There isn't any other valid HTML entity. Why continuing then?
			last;
		}
			
		my $length2 = $tempVar + 1 - $i;		
		my $tag2 = lc(substr($html, $i, $length2));
		my $tempVar2 = HTML_Parse_Common::EntityTagIsClosing($tag2, $length2);
		my $openClose = 0;		
		if (defined($tempVar2))
		{
			$tag2 = $tempVar2;
			$openClose = 1;
		}
		$i = $tempVar + 1;
		
		if ($tag2 ne $tag)
		{
			#The whole point here is to make sure that the closing tag of the given
			#entity is properly detected. Analysing all the remaining entities would
			#provoke an unnecessary waste of time and even the parsing methodology
			#to become too inflexible. Why not tolerating imperfect HTML code when
			#that aspect doesn't matter much (entity contents)?
			next;
		}
		
		$tempVar = Accessory::IndexOfOutsideQuotes($html, ">", $i);
	
		if ($tempVar > -1)
		{
			$tempVar = Accessory::IterateThroughStringWhile
			(
				$html, $closeI2 + 1, " ", $tempVar + 1, 1
			);
		}

		if ($tempVar < 0)
		{
			#It doesn't matter whether it is an opening or closing tag, having the ending ">"
			#symbol is an absolute requirement even when dealing with imperfect HTML code.
			#Additionally, note that there has to be something after that symbol because the
			#whole poin here is analysing nested entities inside another one (whose closing tag
			#has to come after all of them).
			next;
		}

		$i = $tempVar - 1;		
		$openCloses[$openClose]++;
	}

	#Finding an even number of open/close tags for the target entity would mean that everything is
	#OK and that the initial assumption regarding the closing tag was right. On the other hand,
	#an uneven number would mean that a further analysis is required.
	return ($openCloses[0] == $openCloses[1]);
}

#Called by FindEntityMainDefinition to perform some of the internal actions.
sub FindEntityMainDefinitionInternal
{	
	my $html = $_[0];
	my $length = $_[1];	
	my $lastI = $_[2];
	my $tag = $_[3];
	my $backwards = $_[4];
	
	my $lengthTag = length($tag);	

	while(1)
	{
		#FindEntityMainDefinitionInternalFirst returning a non-negative integer means that
		#this is the tag name index and that the starting part is fine (i.e., "<" present).	
		my $i = FindEntityMainDefinitionInternalFirst
		(
			$html, $length, $lastI, $tag, $lengthTag, $backwards
		);
		if ($i < 0) { last; }

		my $lastI = $i + $lengthTag;
		my $closeI = -1;

		while(1)
		{		
			$closeI = Accessory::IndexOfOutsideQuotes($html, ">", $lastI);
			if ($closeI < 0) { last; }

			$lastI = $closeI;
			
			#The loop below these lines (2 iterations max.) accounts for the scenario of a
			#valid HTML entity whose contents are surrounded by others. Analysing them is
			#required to find the closing tag. For example, finding "<div><div>text</div></div>",
			#where the contents of the first div entity are expected to be "<div>text</div>".

			while(1)
			{
				my @tempArray = GetNextEntityCloseI2s
				(
					$html, $length, $lastI, $tag, $lengthTag
				);

				if (scalar(@tempArray) == 1)
				{
					#It was impossible to find valid CloseI2s and, consequently, this
					#isn't a valid HTML entity. No need to go further.
					$lastI = $tempArray[0];
					last;
				}

				if (NestedEntitiesWithinAreOK($html, $closeI, $tempArray[0], $tag, $lengthTag))
				{
					#A valid HTML entity has been found. The returned values are:
					#the indices of the last index of the entity name, the last ">"
					#before the contents (closeI), the first "<" after the contents
					#(closeI2) and the last ">".
					return ($i + $lengthTag, $closeI, $tempArray[0], $tempArray[1]);					
				}
				else { $lastI = $tempArray[1] + 1; }
			}
		}
	}

	#Returning the last index isn't required because of being smaller than the value
	#outputed by the attribute analysis.
	return ();
}

#Called by GetEntityContentLink to account for the scenario of link including a supported protocol.
sub GetEntityContentLinkFromURL
{
	my $html = $_[0];
	my $length = $_[1];
	
	my $outLink;
	
	foreach my $protocol ("http://", "https://")
	{
		my $i = index(lc($html), $protocol);
		if ($i < 0) { next; }

		$outlink = Accessory::GetElementInQuotes($html, $length, $i);
		if (!defined($outLink)) { next; }
		
		if (index($outlink, " ") < 0 and index($outLink, ".") > -1)
		{
			return $outLink;
		}
	}
	
	return undef;
}

#In some cases, the URLs aren't fully compatible with the expected format.
#This method performs some basic corrections to minimise the chances of problems on this front.
sub GetEntityContentLink
{
	my $html = $_[0];
	my $length = length($html);
	
	my $outLink = GetEntityContentLinkFromURL($html, $length);
	if (defined($outLink)) { return $outLink; }
	
	my $html2 = lc($html);
	my $i = Accessory::IndexOfOutsideQuotes(lc($html), "href");
	if ($i < 0) { return $outLink; }
	
	$i = Accessory::IterateThroughStringWhile($html, $length, " ", $i + 4, 1);
	if (substr($html, $i) != "=") { return $outLink; }
		
	$i = Accessory::IterateThroughStringWhile($html, $length, " ", $i + 1, 1);
	if ($i < 0) { return $outLink; }
	
	my $quote = Accessory::GetUnescapedQuote($html, $i);
	if (!defined($quote)) { next; }
	
	my $i2 = index($html, $quote, $i + 1);
	if ($i2 < 0 or $i2 < $i + 2) { return $outLink; }

	$outLink = lc(substr($html, $i + 1, $i2 - $i - 1));
	
	my $includeDomain = 1;
	my @domains = ("www." . $Globals_Variables::CurDomain, $Globals_Variables::CurDomain);

	foreach my $domain (@domains)
	{
		if (index($outLink, $domain) == 0)
		{
			$includeDomain = 0;
			last;
		}
	}

	{
		no warnings "once";

		if ($includeDomain)
		{
			#It is a relative path to which the main domain name has to be added.
			if (substr($outLink, 0, 1) ne "/") { $outLink = "/" . $outLink; }
			
			{
				no warnings "once";
				$outLink = $Globals_Variables::CurDomain . $outLink;
			}
		}
		$outLink = $Globals_Variables::CurProtocol . $outLink;
	}	

	return $outLink;
}

#After all the previous analyses, getting the literal entity content (between ">" and "<") is trivial.
#But, in some cases, additional corrections are required and that's why including this method.
sub GetEntityContent
{
	my $entity = $_[0];
	my $entryType = $_[1];
	
	my $outContent = undef;

	if ($entryType == Globals_Constants::INPUT_ENTRY_URL())
	{
		$outContent = GetEntityContentLink
		(
			substr
			(
				$entity->{"HTML"}, $entity->{"NameI"}, $entity->{"CloseI2"} - $entity->{"NameI"}
			)
		);
	}
	
	if (!defined($outContent))
	{
		$outContent = substr
		(
			$entity->{"HTML"}, $entity->{"CloseI"} + 1,
			$entity->{"CloseI2"} - $entity->{"CloseI"} - 1
		);
	}
	
	return Accessory::Trim($outContent);
}

#After all the attributes have been matched (if required), this method takes care of the
#main HTML entity.
sub FindEntityMainDefinition
{
	my $entity = $_[0];

	#This method can be called either to iterate backwards from a
	#matched attribute or to go forward from a random position.
	my $backwards = $_[1];
	my $entryType = $_[2];
	
	my $html = $entity->{"HTML"};
	my $length = length($html);
	my $lastI = $entity->{"LastI"};
	if
	(
		$lastI < 0 || ($backwards and $lastI < 1) ||
		!defined($html) || $length < 1
	)
	{ return $entity; }

	#When looking for entity names, the case doesn't matter.
	$html = lc($html);
	
	my $tag;
	{
		no warnings "once";
		$tag = $Globals_Variables::HTMLTags{$entity->{"Type"}};
	}

	my @tempArray = FindEntityMainDefinitionInternal
	(
		$html, $length, $lastI, $tag, $backwards
	);
	if (scalar(@tempArray) == 0) { return $entity; }

	$entity->{"NameI"} = $tempArray[0];
	$entity->{"CloseI"} = $tempArray[1];
	$entity->{"CloseI2"} = $tempArray[2];
	$entity->{"Content"} = GetEntityContent($entity, $entryType);
	$entity->{"LastI"} = $tempArray[3];

	return $entity;
}

#This method is part of the HTML-attribute-matching process. 
sub GetNextAttribute
{	
	my $entity = $_[0];
	my $attribute = $_[1];		
	my $value = $_[2];
	
	my $length = length($attribute);
	my $lastI = $entity->{"LastI"};

	while (1)
	{
		my $i = index($entity->{"HTML"}, $value, $lastI);
		if ($i < 0)
		{
			#The target value isn't there. No possible workaround.
			
			#Any future analysis starting before $lastI could provoke an
			#infinite loop.
			$entity->{"LastI"} = $lastI;
			return $entity;
		}
		#Target value was found.

		$entity->{"LastI"} = $i;
		$lastI = $i + length($value);
		
		my @tempArray = Accessory::ValueIsSurroundedByQuotes
		(
			$entity->{"HTML"}, $value, $entity->{"LastI"}
		);
		if (scalar(@tempArray) != 2) { next; }

		$lastI = $tempArray[1] + 1;
		#The target value fulfills the basic requirement of being surrounded by quotes.
		
		$entity->{"LastI"} = $tempArray[0] - 1;
		while (substr($entity->{"HTML"}, $entity->{"LastI"}, 1) eq " ")
		{
			$entity->{"LastI"}--;
		}
		if (substr($entity->{"HTML"}, $entity->{"LastI"}, 1) ne "=") { next; }
		#Heading equal sign present.

		$entity->{"LastI"}--;
		while (substr($entity->{"HTML"}, $entity->{"LastI"}, 1) eq " ")
		{
			$entity->{"LastI"}--;
		}

		$i = $entity->{"LastI"} - $length + 1;

		if ($i >= 0 and (lc(substr($entity->{"HTML"}, $i, $length)) eq $attribute))
		{
			#The final bit (attribute name) has been matched and, consequently, everything is OK.
			#Note that, unlikely what happens with the value, here it doesn't matter lower/upper case.
			#For example, href='http://site.com' and hRef='http://site.com' are identical, but
			#different than href='http://Site.com'.
			$entity->{"LastI"} = $i;
			$entity->{"Found"} = 1;

			#Matching one attribute doesn't necessarily mean that the target entity was found.
			#In case of failing, future analyses will start from $entity->{"TempI"}.
			$entity->{"TempI"} = $lastI;
			
			return $entity;
		}
	}

	return $entity;
}

#It is called as part of the process of matching a given HTML entity when attributes have to be accounted.
#In fact, the whole analysis starts precisely from here: firstly attributes and then main entity name.
sub MatchEntityAttribute
{	
	my $entity = $_[0];
	my $id = $_[1];
	my $value = $_[2];
	my $entryType = $_[3];
	
	$entity->{"Found"} = 0;
	$entity = GetNextAttribute($entity, $id, $value);

	if (!$entity->{"Found"})
	{
		#Not finding one of the attribute values provokes the analysis to
		#be immediately stopped as far as there is no possible way around.
		return undef;	
	}

	if (!defined($entity->{"CloseI"}))
	{
		#The entity hasn't be validated yet. In case of failing to do so this time,
		#there might be another opportunity at a different point.
		$entity = FindEntityMainDefinition($entity, 1, $entryType);
	}

	if (!defined($entity->{"CloseI"}))
	{
		#This isn't the right entity and the analysis needs to be restarted.
		#Some of the target attributes might have been found anyway and this is the reason
		#for relying on $entity->{"TempI"} (index after the last matched attribute): avoiding
		#potential infinite loops by parsing over and over valid attributes not belonging
		#to the valid entity.	
		if ($entity->{"TempI"} > -1) { $entity->{"LastI"} = $entity->{"TempI"}; }
	}

	return $entity;
}

#It tries to find a match in the HTML code for the input information.
sub MatchEntityToTarget
{
	my $html = $_[0];
	my $target = $_[1];
	my $entryType = $_[2];
	
	my $entity = Html_Entity->Instantiate("HTML" => $html, "Type" => $target->{"Type"});
	my %attributes0 = %{$target->{"Attributes"}};	
	my @ids = (keys %attributes0);
	my $maxAttribute = scalar(@ids) - 1;
	
	#The attributes are usually much more specific than the entity name; this is the
	#why the analysis is focused on them.
	#Note that MatchEntityAttribute also checks the main entity definition.

	if ($maxAttribute < 0)
	{
		#No attributes are expected to be matched, just the first
		#occurrence of the given entity.
		$entity = FindEntityMainDefinition($entity, 0, $entryType);
		if (!defined($entity->{"CloseI"})) { $entity = undef; }
	}
	else
	{
		for (my $i = 0; $i <= $maxAttribute; $i++)
		{
			$entity = MatchEntityAttribute
			(
				$entity, $ids[$i], $attributes0{$ids[$i]}, $entryType
			);
			if (!defined($entity)) { return undef; }

			if (defined($entity->{"CloseI"}))
			{
				if ($i == $maxAttribute) { last; }
				
				#As far as attributes don't follow any specific order, the safest starting
				#for upcoming analysis is the entity name index (i.e., before all the attributes).
				$entity->{"LastI"} = $entity->{"NameI"};
			}
			else
			{
				#All the attributes collected so far weren't associated with a valid
				#entity. The whole analysis needs to be restarted.
				$i = -1;			
			}
		}
		
		%{$entity->{"Attributes"}} = %attributes0;
	}

	return $entity;
}

1;