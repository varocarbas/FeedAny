#!/usr/bin/perl

use strict;
use warnings;

use FindBin; 
use lib "$FindBin::RealBin/modules/";
use common;

Run();

#Starts the application.
sub Run
{
	InitialActions();
	MainExecution();
}

#Triggers all the main actions, from input analysis to output generation.
sub MainExecution()
{
	foreach my $input (Inputs_Analysis::GetInputs())
	{
		print("Analysing " . $input->{"Name"} . "\n");
		
		my $output = Outputs_Main::GetOutput($input);

		if (!defined($output))
		{
			print("ERROR -- No output will be generated for " . $input->{"Name"} . ".\n");
			next;
		}
		else { Outputs_RSS::GenerateOutputRSS($output); }
	}	
}

#Calls to all the methods performing all the actions required before starting the properly-speaking execution (e.g., input analysis).
sub InitialActions
{
	Globals_Variables::InitialActionsGlobals();
	IO::InitialActionsIO();
}
