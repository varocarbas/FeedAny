package Globals_Variables;

#All the global variables are included in this file. For the constant declarations, take a look at Globals_Constants.

#Main file/directory information.
our $RootPath;
our $InputDir;
our $OutputDir;	
our %IONames;
our %RSSFormat;
our %RSSTags;
our %RSSTagsOpen;
our @RSSTagsHTML;
our @RSSTagsHTMLCode;
our %InputToRSS;

#Main input information in the input files.
our %InputLabels;
our @Quotes;

#Global HTML-related variables.
our %HTMLTags;

#Variables dealing with all what refers to parsing.
our %ParseConstraints;

#Secondary input information used internally to ease the management of the main input variables/constants.
our @InputURLs;
our @InputEntries;
our @InputLimits;
our @InputBasic;
our %InputEntryVars; 

#Variables referring to information only relevant under the current conditions.
our $CurInputFile;
our $CurDomain;
our $CurProtocol;
our $ErrorDisplayed = 0;

#Main method which is called right at the start to populate all the variables in this file.
sub InitialActionsGlobals
{	
	InitialiseIO();
	InitialiseInputLabels();
	InitialiseInputSecondary();	
	InitialiseSymbols();
	InitialiseHTML();
	InitialiseParse();
	
	use Cwd qw();
	$RootPath = Cwd::cwd() . "/";

	$InputDir = $RootPath . $IONames{Globals_Constants::IO_INPUT_DIR()} . "/";
	$OutputDir = $RootPath . $IONames{Globals_Constants::IO_OUTPUT_DIR()} . "/";	
}

#Populates all the variables dealing with the I/O file and folder names.
sub InitialiseIO
{	
	$IONames{Globals_Constants::IO_INPUT_DIR()} = "inputs/";
	$IONames{Globals_Constants::IO_INPUT_EXTENSION()} = ".fa";
	$IONames{Globals_Constants::IO_ERRORS_FILE()} = "errors.txt";
	$IONames{Globals_Constants::IO_OUTPUT_DIR()} = "outputs/";
	$IONames{Globals_Constants::IO_OUTPUT_EXTENSION_RSS()} = ".xml";
	
	InitialiseRSS();
}

#Populates all the RSS-related variables.
sub InitialiseRSS
{
	InitialiseRSSFormat();
	InitialiseRSSTags();
	InitialiseRSSTagsOpen();
	InitialiseRSSTagsHTML();	
	InitialiseInputToRSS();
}

#Populates all the variables dealing with the format of the RSS output files.
sub InitialiseRSSFormat
{	
	$RSSFormat{Globals_Constants::RSS_FORMAT_HEADING()} = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>";
	$RSSFormat{Globals_Constants::RSS_FORMAT_ATOM()} = "http://www.w3.org/2005/Atom";
	$RSSFormat{Globals_Constants::RSS_FORMAT_VERSION()} = "2.0";
	$RSSFormat{Globals_Constants::RSS_FORMAT_INDENTATION()} = 3;	
}

#Populates the tags for all the relevant RSS items.
sub InitialiseRSSTags
{	
	$RSSTags{Globals_Constants::RSS_ENTRY_TITLE()} = "title";
	$RSSTags{Globals_Constants::RSS_ENTRY_LINK()} = "link";
	$RSSTags{Globals_Constants::RSS_ENTRY_GUID()} = "guid";
	$RSSTags{Globals_Constants::RSS_ENTRY_DESCRIPTION()} = "description";
	$RSSTags{Globals_Constants::RSS_ENTRY_DATE()} = "pubDate";	
}

#Populates a hash including the RSS entries whose opening parts don't follow the standard structure "<" + tag + ">".
sub InitialiseRSSTagsOpen
{
	$RSSTagsOpen{Globals_Constants::RSS_ENTRY_GUID()} = "<guid isPermaLink=\"false\">";
}

#Populates the collections dealing with the RSS which might have HTML support.
sub InitialiseRSSTagsHTML
{
	push @RSSTagsHTML, Globals_Constants::RSS_ENTRY_DESCRIPTION();
	
	push @RSSTagsHTMLCode, "<![CDATA[";
	push @RSSTagsHTMLCode, "]]>";	
}

#Populates a hash mapping all the input entries to the RSS ones.
sub InitialiseInputToRSS
{	
	$InputToRSS{Globals_Constants::INPUT_ENTRY_TITLE()} = Globals_Constants::RSS_ENTRY_TITLE();
	$InputToRSS{Globals_Constants::INPUT_ENTRY_URL()} = Globals_Constants::RSS_ENTRY_LINK();
	$InputToRSS{Globals_Constants::INPUT_ENTRY_BODY()} = Globals_Constants::RSS_ENTRY_DESCRIPTION();
}

#Populates all the variables dealing with the input labels in the input files.
sub InitialiseInputLabels
{
	$InputLabels{Globals_Constants::INPUT_URL_MAIN()} = "main url";
	$InputLabels{Globals_Constants::INPUT_ENTRY_TITLE()} = "entry title";
	$InputLabels{Globals_Constants::INPUT_ENTRY_BODY()} = "entry body";
	$InputLabels{Globals_Constants::INPUT_ENTRY_URL()} = "entry url";
	$InputLabels{Globals_Constants::INPUT_LIMIT_ENTRIES()} = "maximum number of entries";
}
 
#Populates all the variables used internally to ease the management of the main input variables/constants.  
sub InitialiseInputSecondary
{
	push @InputURLs, Globals_Constants::INPUT_URL_MAIN();
			
	push @InputEntries, Globals_Constants::INPUT_ENTRY_TITLE();
	push @InputEntries, Globals_Constants::INPUT_ENTRY_BODY();
	push @InputEntries, Globals_Constants::INPUT_ENTRY_URL();
	
	push @InputLimits, Globals_Constants::INPUT_LIMIT_ENTRIES();
	
	push @InputBasic, Globals_Constants::INPUT_URL_MAIN();
	push @InputBasic, Globals_Constants::INPUT_ENTRY_BODY();
	
	$InputEntryVars{Globals_Constants::INPUT_ENTRY_TITLE()} = "Title";
	$InputEntryVars{Globals_Constants::INPUT_ENTRY_BODY()} = "Body";
	$InputEntryVars{Globals_Constants::INPUT_ENTRY_URL()} = "Url";	
}

#Populates the variables including other main information in the input files.
sub InitialiseSymbols()
{	
	push @Quotes, "\"";
	push @Quotes, "'";
}

#Populates all the HTML-related public variables.
sub InitialiseHTML()
{	
	$HTMLTags{Globals_Constants::HTML_ENTITY_DIV()} = "div";
	$HTMLTags{Globals_Constants::HTML_ENTITY_SPAN()} = "span";	
	$HTMLTags{Globals_Constants::HTML_ENTITY_P()} = "p";
	$HTMLTags{Globals_Constants::HTML_ENTITY_A()} = "a";
	$HTMLTags{Globals_Constants::HTML_ENTITY_B()} = "b";
	$HTMLTags{Globals_Constants::HTML_ENTITY_I()} = "i";	
	$HTMLTags{Globals_Constants::HTML_ENTITY_H()} = "h";
	$HTMLTags{Globals_Constants::HTML_ENTITY_H1()} = "h1";
	$HTMLTags{Globals_Constants::HTML_ENTITY_H2()} = "h2";
	$HTMLTags{Globals_Constants::HTML_ENTITY_H3()} = "h3";
	$HTMLTags{Globals_Constants::HTML_ENTITY_H4()} = "h4";
	$HTMLTags{Globals_Constants::HTML_ENTITY_H5()} = "h5";
	$HTMLTags{Globals_Constants::HTML_ENTITY_H6()} = "h6";	
	$HTMLTags{Globals_Constants::HTML_ENTITY_EM()} = "em";
	$HTMLTags{Globals_Constants::HTML_ENTITY_STRONG()} = "strong";	
	$HTMLTags{Globals_Constants::HTML_ENTITY_TABLE()} = "table";
	$HTMLTags{Globals_Constants::HTML_ENTITY_TR()} = "tr";
	$HTMLTags{Globals_Constants::HTML_ENTITY_TD()} = "td";
	$HTMLTags{Globals_Constants::HTML_ENTITY_TH()} = "th";
	$HTMLTags{Globals_Constants::HTML_ENTITY_THEAD()} = "thead";
	$HTMLTags{Globals_Constants::HTML_ENTITY_TBODY()} = "tbody";
	$HTMLTags{Globals_Constants::HTML_ENTITY_TFOOT()} = "tfoot";
	$HTMLTags{Globals_Constants::HTML_ENTITY_CAPTION()} = "caption";
	$HTMLTags{Globals_Constants::HTML_ENTITY_INPUT()} = "input";
	$HTMLTags{Globals_Constants::HTML_ENTITY_FORM()} = "form";
	$HTMLTags{Globals_Constants::HTML_ENTITY_UL()} = "ul";
	$HTMLTags{Globals_Constants::HTML_ENTITY_LI()} = "li";	
	$HTMLTags{Globals_Constants::HTML_ENTITY_SCRIPT()} = "script";
	$HTMLTags{Globals_Constants::HTML_ENTITY_STYLE()} = "style";
	$HTMLTags{Globals_Constants::HTML_ENTITY_LINK()} = "link";
	$HTMLTags{Globals_Constants::HTML_ENTITY_META()} = "meta";
	$HTMLTags{Globals_Constants::HTML_ENTITY_TITLE()} = "title";
}

#Populates all the parsing related variables.
sub InitialiseParse()
{
	$ParseConstraints{Globals_Constants::CONSTRAINTS_PARSE_MAX_INTERNAL()} = 25;
	$ParseConstraints{Globals_Constants::CONSTRAINTS_PARSE_MAX_GLOBAL()} = 50;
}

#Constraints used by all the parsing algorithms (e.g., the ones preventing infinite loop when parsing wrong HTML code).
use constant { CONSTRAINTS_PARSE_MAX_INTERNAL => 0, CONSTRAINTS_PARSE_MAX_GLOBAL => 1 };

1;