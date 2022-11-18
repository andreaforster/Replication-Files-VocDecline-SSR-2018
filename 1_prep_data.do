/*------------------------------------------------------------------------------
This dofile prepares: 
- 	a working data set that combines variables from the EBB rounds 2010 to 2012
	that are relevant for our analyses

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

* global workingDir "C:\Users\...\replication_files"

*-------------------------------------------------------------------------------
global data		"${workingDir}\00_data"		// raw data
global dofiles 	"${workingDir}\01_dofiles"	// do-files
global posted	"${workingDir}\02_posted"	// output data
global figures 	"${workingDir}\03_figures"	// figures
global tables 	"${workingDir}\04_tables"	// tables
*-------------------------------------------------------------------------------


********************************************************************************
* Prepare relevant variables from EBBs 2010-2012
********************************************************************************

/* save the three EBB data sets in the folder "/repliaction_files/00_data", 
naming them ebb2010.dta, ebb2011.dta and ebb2012.dta */

* Loop to make the same changes to each of the three data sets (2010,2011,2012)
forval x=2010(1)2012	{
	
	*** Open EBB data set
	use "$data/ebb`x'.dta", clear
	
	*** convert all variable lables to lower case letters
	foreach v of var * {
		rename `v' `=lower("`v'")'
	}
	
	*** prepare variables for destring: this sets all "-", "X" and "x" to "0"
	foreach var of varlist ebbtypisco ebbtypisco2008 ebbtypiscor ///
		ebbtypisco2008r {
			replace `var'=subinstr(`var', "-", "0", .) 
			replace `var'=subinstr(`var', "X", "0", .) 
			replace `var'=subinstr(`var', "x", "0", .)
	}
	
	*** Destring ID and wave information variables
	destring ebbstkpersidversleuteld, gen(id_ebb)
	rename ebbstkpeilingnummer wave
	rename ebbaflkwartaal quarter
	rename ebbafljaar year
	
	*** Destring ISCO code for current job
	destring ebbtypisco, gen(isco88)
	destring ebbtypisco2008, gen(isco08)
		
	*** Destring SOI code for highest education
	destring ebbtypsoi2006idhb, gen(oplnr)
	destring ebbtypsoi2006hb, gen(soi2006)
	
	*** Destring variable that indicates whether individual is in education
	destring ebbtypsoi2006idact, gen(actopl)
	gen ineduc=0
		replace ineduc=1 if actopl!=.
	
	*** Rename ISCED variables for level and orientation of highest education
	rename ebbaflisced7hb isced
	rename ebbtypisced2006hborien isced_orient
	
	*** Generate variable for employment status
	recode ebbaflbetwrknu 2=0, gen(employed)
	
	*** Generate variables for socio-demographics of individual
	rename ebbafllft age 										// Age
	recode ebbhhbmv (1=0 "male") (2=1 "female"), gen(female)	// Gender
	rename ebbcdlrprovwo region									// Region
	
	*** Generate sample weights
	gen wgt=ebbgewjaargewichta

	*** select relevant variables that will be kept in the data set
	keep rinpersoons rinpersoon id_ebb wave quarter year ///
		isco88 isco08 oplnr soi2006 ///
		ineduc isced isced_orient employed ///
		age female region wgt
	
	*** generate variables for levels and fields of education from SOI code
	gen field=mod(soi2006,10000)	// last four digits of soi are field of edu
	gen level=trunc(soi2006/10000)  // first two digits of soi are level of edu
	
	*** Merge information on level and fields of education from oplref data
	gen oplnr_str = string(oplnr, "%06.0f") // make string out of variable
	drop oplnr
	rename oplnr_str oplnr
	
	merge m:1 oplnr using "$data/oplref.dta"
	keep if _merge==3
	
	*** save the three data sets with selected variables
	save "$posted/ebb`x'_SSR.dta", replace
} 	


********************************************************************************
* Append the three generated data sets (2010, 2011, 2012) to obtain one working
* data set 
********************************************************************************

use "$posted/ebb2010_SSR.dta", clear

forval x=2011(1)2012	{
	append using "$posted/ebb`x'_SSR.dta"
}
*
compress

********************************************************************************
* Further recodings in generated data set
********************************************************************************

* We exclude military occupations (ISCO code: 0)
recode isco88 0=.
recode isco08 0=.

/* Missings in ISCO08, level and field are recoded from high numbers 
	to missing in Stata */
	
recode isco08 9999=.
recode level 99=.
recode field 9900 9911=.

********************************************************************************
* Save combined working dataset 
********************************************************************************
save "$posted/ebb_2010-2012_SSR.dta", replace

