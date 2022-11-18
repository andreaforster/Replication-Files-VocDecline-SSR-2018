/*------------------------------------------------------------------------------
This dofile prepares: 
- 	the variables necessary to carry out the segregation analysis with the goal
	of obtaining the occupational specificity of each educational category
	These Variables are: Current occupation and highest education
-	A sample of young workers for which we want to calculate the occupational
	specificity using occupation and education
- 	A set of educational categories that contain at least 100 observations, so
	that we do not face sparse cell bias

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


/* open data set prepared in do-file 1 */
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
* Select target group of young workers to calculate linkage strength
********************************************************************************
/* 
We want to calculate linkage with a sample of young workers who are not more 
than 15 years older than the normal school leaving age for their respective 
educational level. Therefore, we determine the regular school leaving age
for each eduational level 10 to 70 and add 15 years to this age. 
For levels 10 and 20 we use a school leaving age of 15 as minimum, as students 
do on a regular basis leave school before this age. 
*/

* Determine cut-off age for each level of education 
gen age_cut =999
	replace age_cut = 30 if level==10 | level==20			  // primary or less
	replace age_cut = 30 if level==31 | level==32 | level==33 // lower secondary	
	replace age_cut = 32 if level==41 | level==42			  // upper secondary
	replace age_cut = 33 if level==43						  // pre-academic
	replace age_cut = 34 if level==51						  // short tertiary
	replace age_cut = 36 if level==52 | level==53			  // bachelor
	replace age_cut = 38 if level==60						  // master
	replace age_cut = 42 if level==70						  // doctorate

/* Keep those individuals who are not older than the cut-off age and at maximum
42 years old */
keep if age <= age_cut
drop if age>42
	
/* We also drop respondents below 16. We do not expect individuals that are 
younger than 16 to be on the labor market under normal circumstances */
drop if age<16

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
/* Recode educational categories so that there are no categories with less than
100 observations. We do this to avoid sparse cell bias. Analyses on the right
size of the cells are available upon request from the authors
Categories with less than 100 observations are recoded into broader educational
categories. They are not dropped from the sample. 
*/
********************************************************************************

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

* list final number of levelfields
distinct levelfield 

/* Save data set with the prepared educational and occupational categories
in the next step those will be used to calculate occupational specificity */

save "$posted/seg_data_2010-2012_SSR.dta", replace
