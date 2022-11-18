/*------------------------------------------------------------------------------
This dofile prepares:
- 	the variables necessary to carry out the segregation analysis with the goal
	of obtaining the occupational specificity of each educational category
	These Variables are: Current occupation and highest education for
-	three different age cohorts (young, middle, old) for the robustness check in
	Appendix C
- 	A set of educational categories that contain at least 100 observations, so
	that we do not face sparse cell bias

This do-file produces the following tables and figures:
-	none

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


use "$posted/ebb_2010-2012_SSR.dta", clear

********************************************************************************
* Drop those with missings on key variables
********************************************************************************

/* We need complete data on education and occupation to be able to calculate 
linkage strength. We restrict the sample to those who are employed and have
information on level of education */

drop if isco08==.
drop if level==. 

********************************************************************************
* select target group
********************************************************************************

drop if age<16
drop if age>65
	
/* We also drop those who are still in education as we focus on individuals 
who have left full time education */
drop if ineduc==1

********************************************************************************
* Code Occupation Variable from ISCO08 Codes
********************************************************************************

/* Generate a 3-digit code for occupations by taking the first three digits
(levels of detail) from the ISCO 2008 variables. We use three digits of detail
to obtain a sufficient level of detail without creating many sparse cells */

gen isco3d=trunc(isco08/10)
keep if level!=. & isco3d!=.

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
* Delete Duplicates
********************************************************************************
/* 
Some individuals have taken part in several rounds of the EBB. We only keep the
first observation for each individual. Furthermore, we also drop individuals who
lack an ID variable as we cannot identify duplicates for those individuals
*/

drop if rinpersoon==""
sort rinpersoon year wave 

duplicates tag rinpersoon year wave, gen(tag)
drop if tag==1

sort rinpersoon year wave
duplicates report rinpersoon year wave

egen wave_uniq=group(year wave)
sort rinpersoon wave_uniq

bys rinpersoon: gen n_wave=_n
keep if n_wave==1
duplicates report rinpersoon

count

********************************************************************************
* Generate three age groups for the different cohorts for which we analyse 
* linkage strength
********************************************************************************

/* In appendix C we calculate linkage strength using three different cohorts:
young (35 or younger), middle (36 yo 50), old (50 or older)
*/

gen age1 =0
	replace age1 = 1 if age<=35

gen age2 =0
	replace age2 = 1 if age>35 & age<=50

gen age3 =0
	replace age3 = 1 if age>50
	

********************************************************************************
* Recode minimum cell sizes of 100 obs for educational categories for each of
* the three age cohorts
********************************************************************************

forval x=1(1)3	{

preserve
keep if age`x'==1

* check in which levelfields the number of observations is below the cut-off
bys levelfield: gen n=_N
gen obs=1 if n<100
	replace obs=0 if n>=100
bys levelfield: egen mis_lf=sum(obs)
tab levelfield if mis_lf!=0

/* recode last digit of the field code to zero if the cell size is 
below the cut-off */
replace levelfield=(trunc(levelfield/10))*10 if mis_lf!=0
distinct levelfield 

* drop created auxiliary variables
drop mis_lf n
drop obs

* check in which levelfields the number of observations is still below cut-off
bys levelfield: gen n=_N
gen obs=1 if n<100
	replace obs=0 if n>=100
bys levelfield: egen mis_lf=sum(obs)
tab levelfield if mis_lf!=0

/* recode the remaining digit of the field code to zero if cell size is 
still below cut-off */
replace levelfield=(trunc(levelfield/100))*100 if mis_lf!=0 
distinct levelfield  

* drop created auxiliary variables
drop mis_lf n
drop obs

* check in which levelfields the number of observations is still below cut-off
bys levelfield: gen n=_N
gen obs=1 if n<100
	replace obs=0 if n>=100
bys levelfield: egen mis_lf=sum(obs)
tab levelfield if mis_lf!=0

* drop created auxiliary variables
drop mis_lf 
drop n
drop obs

/* Recode field codes for those categories that lost all information 
(double zero at the end). These observations are put in category "other" 
Those categories that lost only one digit of the field code remain in a 
category with only one level of detail for field with one zero at the 
end (e.g. 3120). 
*/
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

* check again in which levelfields number of observations is below cut-off
bys levelfield: gen n=_N
gen obs=1 if n<100
	replace obs=0 if n>=100
bys levelfield: egen mis_lf=sum(obs)
tab levelfield if mis_lf!=0

* drop created auxiliary variables
drop mis_lf n
drop obs

* final number of levelfields
distinct levelfield 

save "$posted/seg_data_2010-2012_age`x'_SSR", replace

restore
}

