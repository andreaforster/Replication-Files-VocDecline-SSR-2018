/*------------------------------------------------------------------------------
This dofile: 
- 	merges the linkage strength measure that was created in do-file 
"3_analysis_linkage.do" to each in individual in the EBB data set that was 
created in do-file "1_prep_data.do"

This do-file produces the following tables and figures:
- 	none

Programs that need to be downloaded:
-	

Data needed/Data version used in paper:
-	The data used in this paper can be accessed via Statistics Netherlands (CBS).
	A data user contract of your institution with CBS is required to access the 
	data. More information can be found here: 
	https://www.cbs.nl/en-gb/our-services/customized-services-microdata
	/microdata-conducting-your-own-research
	
-  	Enquete Beroepsbevolking 2010 (version: March 2015)
-  	Enquete Beroepsbevolking 2011 (version: March 2015)
-  	Enquete Beroepsbevolking 2012 (version: March 2015)

-	oplref.dta (provided with replication files)
------------------------------------------------------------------------------*/
version 14.2
clear
set more off

* Set paths to working directories

/* Customize this path to the location on your computer where the downloaded 
replication folder is located */

*global workingDir "C:\Users\...\replication_files"

*-------------------------------------------------------------------------------
global data		"${workingDir}\00_data"		// raw data
global dofiles 	"${workingDir}\01_dofiles"	// do-files
global posted	"${workingDir}\02_posted"	// output data
global figures 	"${workingDir}\03_figures"	// figures
global tables 	"${workingDir}\04_tables"	// tables
*-------------------------------------------------------------------------------


/* open data set that was created in do-file 1 (contains all individuals not 
only those who are young and employed)*/
use "$posted/ebb_2010-2012_SSR.dta", clear

/*
In this do-file we repeat some of the steps from do-file "2_prepvar_linkage.do"
as we want to merge the information that we obtained in do-files 2 and 3 to
the original data set. To make the merge successful we have to re-code the 
educational and occupational categories in the data set from do-file 1 in a way 
that they match the categories that we used in do-file 2 and 3. After these
re-codings we can merge the linkage strength to the data set. 
*/

********************************************************************************
* Code Occupation Variable from ISCO08 Codes
********************************************************************************

/* Generate a 3-digit code for occupations by taking the first three digits
(levels of detail) from the ISCO 2008 variables. We use three digits of detail
to obtain a sufficient level of detail without creating many sparse cells */

gen isco3d=trunc(isco08/10)

/* we can only merge linkage strength to individuals of which we have 
information on educational categories. This is why we have to drop individuals
without information on level
*/

keep if level!=.

********************************************************************************
* Code Education Variable from SOI2006 Codes
********************************************************************************

/* Create 2-digit SOI field code (2 levels of detail) 
out of 4-digit SOI field code */

gen field2d=trunc(field/100)
recode field2d 00 99=. 		// set unknown fields to missing 

/* generate a levefield code that combines the level and field information from 
SOI (first 2 digits are level, second 2 digits are field)*/

gen levelfield=(level*100) + field2d

/* Recode all fields in the levels 10 and 20 to 01 "general". In levels 10 and 
20 all fields are considered as general as this is pre-primary and 
primary education */

replace levelfield=1001 if level==10
replace levelfield=2001 if level==20

********************************************************************************
* Merge
********************************************************************************

/* 
We merge the linkage strength measure in three steps. This has to do with the 
fact that we recoded some of the educational categories in do-file 2 as they 
did contain less than 100 observations. We first merge without re-coding any
categories in the "use" data. Some observations cannot be merged then as their
educational category was recoded to less detail in the "using" data. 
Second, we identify the observations that couldn't be merged and recode their 
educational category by changing the last digit to zero. We try to merge again.
Third, we identify again the observations that still couldn't be merged and 
recode the remaining field digit to zero. 
*/

*-------------------------------------------------------------------------------
* First Step: Merge without recoding
*-------------------------------------------------------------------------------

* save old level and field variable in different variable (for data checks)
rename level level_step1 
rename field field_step1

* generate new level and field variable from the levelfield variable
gen level=trunc(levelfield/100)
gen field=mod(levelfield,100)
drop if level==. 
drop if field==. 

* merge data
drop _merge	
sort level field
merge m:1 level field using "$posted/seg_indicators_SSR_2010-2012.dta"	

drop ls_edfld 

*-------------------------------------------------------------------------------
* Second Step: Recode the last field digit to zero and merge
*-------------------------------------------------------------------------------

* recode the last digit of the levelfield variable to zero
replace levelfield=(trunc(levelfield/10))*10 if _merge==1

* save old level and field variables in different variable (for data checks)
rename level level_step2 
rename field field_step2

* generate new level and field variable from the recoded levelfield variable
gen level=trunc(levelfield/100)
gen field=mod(levelfield,100)
drop if level==. 
drop if field==. 

* merge data
drop _merge	
sort level field
merge m:1 level field using "$posted/seg_indicators_SSR_2010-2012.dta"	

drop ls_edfld 

*-------------------------------------------------------------------------------
* Third Step: Recode the remaining field information to zero and put the 
* Observations in the "Other" category (98), then merge again
*-------------------------------------------------------------------------------

* Recode the remaining field digit to zero 
replace levelfield=(trunc(levelfield/100))*100 if _merge==1

* Recode the levelfields with double zero into category "Other"
replace levelfield=3198 if levelfield==3100
replace levelfield=3298 if levelfield==3200
replace levelfield=3398 if levelfield==3300
replace levelfield=4198 if levelfield==4100
replace levelfield=4298 if levelfield==4200
replace levelfield=4398 if levelfield==4300
replace levelfield=5198 if levelfield==5100
replace levelfield=5298 if levelfield==5200
replace levelfield=5398 if levelfield==5300
replace levelfield=6098 if levelfield==6000
replace levelfield=7098 if levelfield==7000

* save old level and field variable in different variable (for data checks)
rename level level_step3
rename field field_step3

* generate new level and field variable from the recoded levelfield variable
gen level=trunc(levelfield/100)
gen field=mod(levelfield,100)
drop if level==. 
drop if field==. 

* merge data
drop _merge	
sort level field
merge m:1 level field using "$posted/seg_indicators_SSR_2010-2012.dta"	

********************************************************************************
* Save merged data set
********************************************************************************

save "$posted/regress_data_2010-2012_SSR.dta", replace
