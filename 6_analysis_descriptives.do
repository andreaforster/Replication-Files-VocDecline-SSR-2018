/*------------------------------------------------------------------------------
This dofile produces
-	Descriptive statistics for all variables for the final sample
-	Percentage of observations in the re-coded broader fields of education
-	Density Plot of Vocational vs General education and t-test for difference

This do-file produces the following tables and figures:
- 	Table 1: Descriptive Statistics for the Full Regression Sample
-	Figure 1: Occupational Specificity of Vocational and General Programs
- 	Appendix Table B1: Existing Level-Field Combinations and their Linkage Strength
- 	Appendix Table B2: List of 3-digit ISCO categories

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

* open data
use "$posted\analysis_data_2010-2012_SSR.dta", clear


********************************************************************************
* Percentage in broad fields (those we recoded because of sparse cells) 
* mentioned in Section 5.1
********************************************************************************

count
count if field==10 | field==20 | field==30 | field==40 | field==50 | ///
	field==60 | field==70 | field==80 | field==90 | field==98
	
********************************************************************************
* Table 1: Descriptive Statistics of all variables	
********************************************************************************	

estpost sum employed age ls_edfld voc edlev_isced ///
	region year [aweight=wgt] if female==0
estimates store men

estpost sum employed age ls_edfld voc edlev_isced ///
	region year [aweight=wgt] if female==1
estimates store women	
		
esttab men women using "$tables/descriptives.rtf" ///
	, replace nostar wide nopar cells("mean(fmt(2)) sd(fmt(2)) ") 
	
bys female: fre voc [aweight=wgt]
bys female: fre employed [aweight=wgt]
bys female: fre edlev_isced [aweight=wgt]
bys female: fre region [aweight=wgt], 
bys female: fre year [aweight=wgt]
	
********************************************************************************
* Figure 1: Density Plots of Vocational vs General Education
********************************************************************************
preserve

* Collapse data for density figure
gen n=1
collapse (count) n (mean) ls_edfld (mean) voc, by(level field)

/* Sometimes coding of the level-fields is not clearly voc or gen, if the 
level-field is to more than 80% vocational, we recode to vocational (=1) */
replace voc =1 if voc >0.8

* Density Plot
twoway (kdensity ls_edfld if voc==1) (kdensity ls_edfld if voc==0) ///
	, xtitle("Occupational Specificity") ytitle("Density") title("") ///
	legend(order(1 2) label(1 "Vocational") label(2 "General")) ///
	ylabel(,angle(horizontal)) ///
	scheme(s2mono) graphregion(color(white))

graph export "$figures/figure1_density_voc-gen.pdf", replace	

* t-test for density distribution, Section 7.1
ttest ls_edfld, by(voc)

restore

********************************************************************************
* Appendix Table B1: Linkage Strength for all Level-field combinations
********************************************************************************

table field level, c(mean ls_edfld) format(%9.3f) 

********************************************************************************
* Appendix Table B2: List of all ISCO categories in the data
********************************************************************************
table isco3d, c(freq) 
