package Globals_Constants;

#All the constants are declared in this file and any additional information associated with them
#(e.g., string representation of the given HTML entity) is stored in Globals_Constants.

#Main items (files and folders) defining the I/O system.
use constant { IO_INPUT_DIR => 0, IO_INPUT_EXTENSION => 1, IO_ERRORS_FILE => 2, IO_OUTPUT_DIR => 3, IO_OUTPUT_EXTENSION_RSS => 4 };

#Definition of the RSS outputs format.
use constant { RSS_FORMAT_HEADING => 0, RSS_FORMAT_VERSION => 1, RSS_FORMAT_ATOM => 2, RSS_FORMAT_INDENTATION => 3 };

#All the main RSS items whose population requires some kind of special treatment.
use constant { RSS_ENTRY_TITLE => 0, RSS_ENTRY_LINK => 1, RSS_ENTRY_GUID => 2, RSS_ENTRY_DESCRIPTION => 3, RSS_ENTRY_DATE => 4 };

#Types of fields in the input files, one per line.
use constant { INPUT_URL_MAIN => 0, INPUT_ENTRY_TITLE => 1, INPUT_ENTRY_BODY => 2, INPUT_ENTRY_URL => 3, INPUT_LIMIT_ENTRIES => 4 };

#All the different categories accounted by the HTML parsing code.
use constant { HTML_TYPE_ENTITY => 0, HTML_TYPE_ATTRIBUTE => 1 };

#All the supported HTML entities.
use constant
{
	HTML_ENTITY_DIV => 0, HTML_ENTITY_SPAN => 1, HTML_ENTITY_P => 2, HTML_ENTITY_A => 3, HTML_ENTITY_B => 4, HTML_ENTITY_I => 5, HTML_ENTITY_H => 6,
	HTML_ENTITY_H1 => 7, HTML_ENTITY_H2 => 8, HTML_ENTITY_H3 => 9, HTML_ENTITY_H4 => 10, HTML_ENTITY_H5 => 11, HTML_ENTITY_H6 => 12,
	HTML_ENTITY_EM => 13, HTML_ENTITY_STRONG => 14, HTML_ENTITY_TABLE => 15, HTML_ENTITY_TR => 16, HTML_ENTITY_TD => 17, HTML_ENTITY_TH => 18,
	HTML_ENTITY_THEAD => 19, HTML_ENTITY_TBODY => 20, HTML_ENTITY_TFOOT => 21, HTML_ENTITY_CAPTION => 22, HTML_ENTITY_INPUT => 23,
	HTML_ENTITY_FORM => 24, HTML_ENTITY_UL => 25, HTML_ENTITY_LI => 26, HTML_ENTITY_SCRIPT => 27, HTML_ENTITY_STYLE => 28, HTML_ENTITY_LINK => 29,
	HTML_ENTITY_META => 30, HTML_ENTITY_TITLE => 31
};

#Constraints used by all the parsing algorithms (e.g., the ones preventing infinite loop when parsing wrong HTML code).
use constant { CONSTRAINTS_PARSE_MAX_INTERNAL => 0, CONSTRAINTS_PARSE_MAX_GLOBAL => 1 };

#All error types.
use constant
{
	ERROR_INPUT_LABEL_REPEATED => 0, ERROR_INPUT_VALUE_FORMAT => 1, ERROR_INPUT_BASIC => 2, ERROR_HTML_GRABBING => 3,
	ERROR_IO_FILE_DELETE => 4, ERROR_IO_FILE_READ => 5, ERROR_IO_FILE_WRITE => 6
};

1;
