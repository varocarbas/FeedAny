# FeedAny

[https://customsolvers.com/feed_any/](https://customsolvers.com/feed_any/) (ES: [https://customsolvers.com/feed_any_es/](https://customsolvers.com/feed_any_es/)) --- [Video](https://www.youtube.com/watch?v=XXZcxYmhQRg)

## Introduction

FeedAny generates web feeds from random pages via HTML parsing. The target web pages can have any structure, but are supposed to be web-feed friendly (i.e., regularly-updated sets of data on a well-structured layout).

## Quick start guide

- Make sure that both Perl and Wget are installed on your machine.
- Include as many input files (*.fa) as you wish in the root "inputs" folder ([some samples](https://customsolvers.com/downloads/feed_any/samples/)). 
- Run FeedAny (e.g., type "perl FeedAny.pl" in the command line).
- Use the files generated in the root "outputs" folder as you would use any web feed (e.g., open them with a feed reader).

## Input files (*.fa)

All the input files are expected to follow these rules:
- The titles (before ":") aren't supposed to be modified.
- The input values (after ":") have to verify the following formats: HTML ("Entry title", "Entry body" and "Entry additional"), URL ("Entry URL") or integer numeric ("Maximum number of entries").
- Only [supported HTML entities](https://customsolvers.com/downloads/feed_any/supported_html_entities.txt) can be used. The attributes might be anything, but their values have to be surrounded by quotes (e.g., ```<div attribute='value'>```). Only opening tags are expected. It is possible to include various nested entities (e.g., ```<div attr="whatever"><a>```).
- The URLs have to start with "http://" or "https://". In any other scenario, all the contents after "//" are assumed to be comments and are ignored.
- All the entry inputs can include multiple constraints (e.g., ```contain "target"```) related through the logical (short-circuit) operators ```and```/```or```. 
- The parsing algorithm tends to analyse the entry input information in a sequential fashion, from top to bottom.
- It is possible to include as many additional inputs (i.e., "Entry additional") as desired.


## Authorship & Copyright

I, Alvaro Carballo Garcia (varocarbas), am the sole author of each single bit of this code.

Equivalently to what happens with all my other online contributions, this code can be considered public domain. For more information about my copyright/authorship attribution ideas, visit the corresponding pages of my sites:
- https://customsolvers.com/copyright/
ES: https://customsolvers.com/copyright_es/
- https://varocarbas.com/copyright/
ES: https://varocarbas.com/copyright_es/
