/*------------------------------------------------------------------------------
This dofile prepares:
-	all variables needed for the main regression analysis of vocational decline

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


* open data prepared in do-file 4 (with the merged linkage strength)
use "$posted/regress_data_2010-2012_SSR.dta",clear

********************************************************************************
* Age
********************************************************************************

/* We only keep individuals between 16 and 65, the common age for being active
in the labor market */
drop if age < 16
drop if age > 65

/* we center the existing age variable so that age 16 (the youngest age) is 0 in 
our analysis */
gen age_c = age-16

********************************************************************************
* Age squared
********************************************************************************

* we manually generate a variable for age squared and a centered version of it
gen age2 = age*age
gen age2_c = age_c*age_c

********************************************************************************
* Educational level (ISCED)
********************************************************************************

/* 
We recode the isced levels into 7 categories
*/

recode isced 								///
	(10				=1 "pre-primary")		///
	(20				=2 "primary")			///
	(30 31 32 33 	=3 "lower secondary")	///
	(40 41 42 		=4 "upper secondary")	///
	(50				=5 "post-sec")			///
	(61 62			=6 "tertiary")			///
	(70				=7 "doctorate")			///
	(99				=.)						///
	, gen(edlev_isced)

********************************************************************************
* Vocational and General Education (dichotomous indicator) defined according 
*to SOI nummbers
********************************************************************************
/*
We first generate a variable that differentiates different types of education.
Then we define educational types in the following way: VWO, HAVO, VMBO, WO 
as general and MBO HBO as vocational. 
*/

gen ed_type = . 
		
*-------------------------------------------------------------------------------
* SOI levels 1 and 2
*-------------------------------------------------------------------------------

replace ed_type=1 if level==10
replace ed_type=1 if level==20

*-------------------------------------------------------------------------------
* SOI level 3
*-------------------------------------------------------------------------------

/* if field is 01 (=general) we code to type 2 (=vmbo), all other
fieds we code to type 3 (= mbo1, lowest level of mbo) */
	
replace ed_type=2 if (level==31|level==32|level==33)&(field==01) // general 	
replace ed_type=3 if (level==31|level==32|level==33)&(field!=01) // vocational 
	
*-------------------------------------------------------------------------------
* SOI level 4
*-------------------------------------------------------------------------------
	
/* code different levels of MBO separately (mbo2 to mbo4, mbo1 was coded above)
Here all codes in level 4 are first coded as vocational*/

replace ed_type=4 if level==41 // mbo2
replace ed_type=5 if level==42 // mbo3
replace ed_type=6 if level==43 // mbo4

/* Now we recode those codes in level 4 that are actually general. We use
the codes for havo and vwo to code them into a separate category */

replace ed_type=7 if 	soi2006==420120 | soi2006==420124 | /// havo
						soi2006==420125 | soi2006==420151 | ///
						soi2006==420191 

replace ed_type=8 if 	soi2006==430120 | soi2006==430126 | /// vwo
						soi2006==430127 | soi2006==430128 | ///
						soi2006==430129 | soi2006==430151 | ///
						soi2006==430191 

*-------------------------------------------------------------------------------
* SOI levels 5 to 7
*-------------------------------------------------------------------------------

replace ed_type=9 if level==51 | level==52 // hbo

replace ed_type=10 if level>52 & level<72
	
*-------------------------------------------------------------------------------
* Assigning labels
*-------------------------------------------------------------------------------	

lab def ed_type_lab ///
	1 "Prim." 		///
	2 "Laag sec." 	///
	3 "Mbo 1"		///
	4 "Mbo 2" 		///
	5 "Mbo 3" 		///
	6 "Mbo 4" 		///
	7 "Havo" 		///
	8 "Vwo" 		///
	9 "Hbo" 		///
	10 "Wo"
lab val ed_type ed_type_lab

gen voc =0
	replace voc=1 if 	///
	ed_type==3 | 		///
	ed_type==4 | 		///
	ed_type==5 | 		///
	ed_type==6 | 		///
	ed_type==9


********************************************************************************
* Region
********************************************************************************

recode region 					///
	(20=1 "Groningen")			///
	(21=2 "Friesland")			///
	(22=3 "Drenthe")			///
	(23=4 "Overijssel")			///
	(24=5 "Flevoland")			///
	(25=6 "Gelderland")			///
	(26=7 "Utrecht")			///
	(27=8 "Noord-Holland")		///
	(28=9 "Zuid-Holland")		///
	(29=10 "Zeeland")			///
	(30=11 "Noord-Brabant ")	///
	(31=12 "Limburg")			///
	, gen(region_new)

drop region
rename region_new region

********************************************************************************
* Reduce data set to relevant variables
********************************************************************************

keep employed rinpersoons rinpersoon id id_ebb wave age age2 		///
	age_c age2_c female edlev_isced voc ineduc region wgt 			///
	ls_edfld levelfield level field isco3d year ed_type

*******************************************************************************
* Obtain Final Sample
*******************************************************************************

*-------------------------------------------------------------------------------
* Listwise deletion to obtain a sample without missing data
*-------------------------------------------------------------------------------

keep if !missing(employed, age_c, age2_c, ls_edfld, voc, female, ///
	edlev_isced, region, year)
	
*-------------------------------------------------------------------------------
* Only keep individuals who are not in education
*-------------------------------------------------------------------------------

drop if ineduc==1

*-------------------------------------------------------------------------------
* Delete Duplicates
*-------------------------------------------------------------------------------

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

save "$posted\analysis_data_2010-2012_SSR.dta", replace
