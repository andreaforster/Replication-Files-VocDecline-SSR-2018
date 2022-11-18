version 14.2
clear
set more off

* Set paths to working directories

/* Customize this path to the location on your computer where the downloaded 
replication folder is located */

global workingDir "H:\Andrea\linkages decline\replication files SSR\"

*-------------------------------------------------------------------------------
global data		"${workingDir}\00_data"		// raw data
global dofiles 	"${workingDir}\01_dofiles"	// do-files
global posted	"${workingDir}\02_posted"	// output data
global figures 	"${workingDir}\03_figures"	// figures
global tables 	"${workingDir}\04_tables"	// tables
*-------------------------------------------------------------------------------

do "$dofiles\1_prep_data.do"
do "$dofiles\2_prepvar_linkage.do"
do "$dofiles\3_analysis_linkage.do"
do "$dofiles\4_merge_linkage.do"
do "$dofiles\5_prepvar_main.do"
do "$dofiles\6_analysis_descriptives.do"
do "$dofiles\7_analysis_main.do"
do "$dofiles\8_prepvar_appendixC.do"
do "$dofiles\9_analysis_linkage_appendixC.do"
