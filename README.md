# FeedAny

[https://customsolvers.com/feed_any/](https://customsolvers.com/feed_any/) (ES: [https://customsolvers.com/feed_any_es/](https://customsolvers.com/feed_any_es/))

## Introduction

FeedAny generates web feeds from random pages via HTML parsing. The target web pages can have any structure, but are supposed to be web feed friendly.

## Quick start guide

- Make sure that your machine supports Perl 5.
- Include as many input files (*.fa) as you wish in the root "inputs" folder. 
- Run FeedAny (e.g., type "perl FeedAny.pl" in the command line).
- Use the files generated in the root "outputs" folder as you would use any web feed.

## Input files (*.fa)

All the input files are expected to follow these rules:
- The titles (before ":") aren't supposed to be modified.
- The input values (after ":") have to verify the corresponding format as suggested by the title: URL, HTML or integer numeric.
- URLs have to be valid and to start with "http://" or "https://".
- Only [supported HTML entities](https://customsolvers.com/downloads/feed_any/supported_html_entities.txt) can be used. The attributes might be anything, but their values have to be surrounded by quotes (e.g., ```<div attribute='value'>```). Only opening tags are expected. It is possible to include various nested entities (e.g., ```<div attr="whatever"><a>```).

## Practical example

A Linux user wants to get the last codeproject.com articles via RSS. This is what he has to do:
- Make a copy of one of the sample files in the root "inputs" folder and rename it to "code_project_last.fa".
- Open that new file and write "https://www.codeproject.com/script/Articles/Latest.aspx" right after "Main URL:". Navigate to that page.
- Choose a descriptive chunk of simple, non-enhanced text from the first item description, show the page source and look for it.
- Now (20-03-2018), it is immediately preceded by ```<div id="[GIBBERISH]" class="description">```. [GIBBERISH] is unique, but ```class="description"``` is used by all the items.
- Open "code_project_last.fa" and write ```<div class="description">``` right after "Entry body:".
- The same process can also be repeated for "Entry title:" and "Entry URL:",  always by choosing descriptive HTML entities and attributes. It is possible to pick just some of the attributes or an entity not immediately preceding the given text.  
- Run FeedAny by typing "perl FeedAny.pl" in the console and see "code_project_last.xml" being created in the "outputs" folder.
- That output file might be copied to the given local server and opened with a RSS reader through HTTP.
- A cronjob might also be set up to regularly update the "code_project_last.xml" contents.


## Authorship & Copyright
I, Alvaro Carballo Garcia (varocarbas), am the sole author of each single bit of this code.

Equivalently to what happens with all my other online contributions, this code can be considered public domain. For more information about my copyright/authorship attribution ideas, visit the corresponding pages of my sites:
- https://customsolvers.com/copyright/<br/> 
ES: https://customsolvers.com/copyright_es/
- https://varocarbas.com/copyright/<br/>
ES: https://varocarbas.com/copyright_es/