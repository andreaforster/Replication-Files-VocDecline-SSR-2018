/*------------------------------------------------------------------------------
This dofile analyses: 
- 	the linkage strength (occupational specificity) of each educational 
	category in the data that contains at least 100 observations
	This means that the output of this do-file is a list of educational 
	categories which are linked to one value of linkage strength
-	Linkage strength is calculated separately for the three age groups (35 or
	younger, 36-50, 51 or older)
-	

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

********************************************************************************
* Calculate linkage strength separately for the three age cohorts
*******************************************************************************

forval x=1(1)3	{

* open data
use "$posted/seg_data_2010-2012_age`x'_SSR", clear

*-------------------------------------------------------------------------------
* Generate separate educational Level and Field variables from the levelfield
* variable that was produced in the last do-file 
*-------------------------------------------------------------------------------

gen n_weight=1

drop level field
gen level=trunc(levelfield/100)
gen field=mod(levelfield,100)

* drop obersvations with missing data on key variables education and occupation
drop if level==. 
drop if field==. 
drop if isco3d==.	

*-------------------------------------------------------------------------------
* rescale weights for the analysis
*-------------------------------------------------------------------------------

egen totwgt=sum(wgt)
gen wt=(wgt/totwgt)*_N

*-------------------------------------------------------------------------------
/* Collapse data according to level field and occupation. Now, each row contains
the weighted number of individuals in each educational categories that share one 
occupation */
*-------------------------------------------------------------------------------

collapse (count) n_weight [pw=wt], by(level field isco3d)

*-------------------------------------------------------------------------------
* Calculate total observations for cells (levelfields, levels, occupations)
*-------------------------------------------------------------------------------
					egen n_weight_total=total(n_weight) //total obs
bys level field: 	egen n_edfld=total(n_weight) 		//total obs in the single levelfields
bys level:			egen n_edlev=total(n_weight) 		//total obs in the single levels across all fields
bys isco3d: 		egen n_occ=total(n_weight)			//total obs in occupation across levelfields
	
*-------------------------------------------------------------------------------
* Calculate relative proportions/probabilities
*-------------------------------------------------------------------------------

gen p_edfld_occ			=	n_weight/n_weight_tot	//relative proportion in a field/level/occ cell of total observations
gen p_edfld				=	n_edfld/n_weight_tot	//relative proportion in a levelandfield of total observations
gen p_occ				=	n_occ/n_weight_tot		//relative proportion in an occupation of all observations

gen p_edfld_given_ed	=	n_edfld/n_edlev			//relative proportion in a levelandfield of all observations within a level
gen p_occ_given_edfld	=	p_edfld_occ/p_edfld		//relative proportion in occupation for all obs in a levelandfield
gen p_edfld_given_occ	=	p_edfld_occ/p_occ		//relative proportion in levelandfield for all obs in an occupation

*-------------------------------------------------------------------------------
* Calculate local segregation for levelfield using formula for the M index
*-------------------------------------------------------------------------------

/* m = prob. of being in an occup. given the levelfield * ln 
(being in occup. given levelfield/being in occup. across all obs) */
gen m_g_part= p_occ_given_edfld*ln(p_occ_given_edfld/p_occ)  // 

* sum m for each educational category
bys level field: egen ls_edfld = total(m_g_part)

*-------------------------------------------------------------------------------
* Save local segregation of levelfields
*-------------------------------------------------------------------------------

* keep only relevant variables
keep level field ls_edfld
sort level field

*-------------------------------------------------------------------------------
* Descriptive information of linkage strength index
*-------------------------------------------------------------------------------

collapse (mean) ls_edfld, by(level field)

hist ls_edfld, width(0.1) normal
sum ls_edfld, detail

*-------------------------------------------------------------------------------
* Generate an indicator for the cohort
*-------------------------------------------------------------------------------

gen cohort = `x'

save "$posted/seg_indicators_SSR_2010-2012_age`x'.dta", replace

}

*

********************************************************************************
* Combine the three data sets with the three linkage measures for the cohorts
* and save it again
********************************************************************************

use "$posted/seg_indicators_SSR_2010-2012_age1.dta", clear
append using "$posted/seg_indicators_SSR_2010-2012_age2.dta"
append using "$posted/seg_indicators_SSR_2010-2012_age3.dta"

lab def coh_lab 1 "16-35" 2 "36-50" 3 "51-65"
lab val cohort coh_lab

save "$posted/graphdata_appendixC.dta", replace

