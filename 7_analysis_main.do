/*------------------------------------------------------------------------------
This dofile analyses
-	The life course vocational decline by using linear probability models

This do-file produces the following tables and figures:
- 	Table 3: Linear Probability models for the Life-course with Employment as
	Dependent Variable
-	Figure 2: Predicted Probabilities of Being Employed for different levels
	of linkage strength over the life-course 
-	Figure 3: Conditional Marginal Effects of Linkage Strength at different
	Ages

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
* Table 3: Regression Table Main Analysis of Vocational Decline
********************************************************************************

/* 
For the regression models in the table we use linear probability models 
(regress) with the centered age variable that is divided by ten for 
readability and a standardized variable for the linkage strength. Models are
carried out separately for men and women
*/

*-------------------------------------------------------------------------------
* Men
*-------------------------------------------------------------------------------

preserve

replace age_c = age_c/10 // Divide age variable by 10 for readability of coeff.
keep if female==0					// only keep men
egen std_ls = std(ls_edfld)			// standardize linkage measure for sample

* Model 1
regress employed std_ls age_c c.age_c#c.age_c ///
	i.edlev_isced i.region i.year [pweight=wgt]
estimates store m1_men

* Model 2
regress employed std_ls age_c c.age_c#c.age_c c.age_c#c.std_ls ///
	i.edlev_isced i.region i.year [pweight=wgt]
estimates store m2_men

* Model 3
regress employed std_ls age_c c.age_c#c.age_c c.age_c#c.age_c#c.age_c ///
	c.age_c#c.age_c#c.age_c#c.age_c ///
	i.edlev_isced i.region i.year [pweight=wgt]
estimates store m3_men

* Model 4
regress employed std_ls age_c c.age_c#c.age_c c.age_c#c.age_c#c.age_c ///
	c.age_c#c.age_c#c.age_c#c.age_c ///
	c.age_c#c.std_ls c.age_c#c.age_c#c.std_ls ///
	c.age_c#c.age_c#c.age_c#c.std_ls c.age_c#c.age_c#c.age_c#c.age_c#c.std_ls ///
	i.edlev_isced i.region i.year [pweight=wgt]
estimates store m4_men

restore

*-------------------------------------------------------------------------------
* Women
*-------------------------------------------------------------------------------

preserve

replace age_c = age_c/10 // Divide age variable by 10 for readability of coeff.
keep if female==1					// only keep women
egen std_ls = std(ls_edfld)			// standardize linkage measure for sample

* Model 1
regress employed std_ls age_c c.age_c#c.age_c ///
	i.edlev_isced i.region i.year [pweight=wgt]
estimates store m1_women

* Model 2
regress employed std_ls age_c c.age_c#c.age_c c.age_c#c.std_ls ///
	i.edlev_isced i.region i.year [pweight=wgt]
estimates store m2_women

* Model 3
regress employed std_ls age_c c.age_c#c.age_c c.age_c#c.age_c#c.age_c ///
	c.age_c#c.age_c#c.age_c#c.age_c ///
	i.edlev_isced i.region i.year [pweight=wgt]
estimates store m3_women

* Model 4
regress employed std_ls age_c c.age_c#c.age_c c.age_c#c.age_c#c.age_c ///
	c.age_c#c.age_c#c.age_c#c.age_c ///
	c.age_c#c.std_ls c.age_c#c.age_c#c.std_ls ///
	c.age_c#c.age_c#c.age_c#c.std_ls c.age_c#c.age_c#c.age_c#c.age_c#c.std_ls ///
	i.edlev_isced i.region i.year [pweight=wgt]
estimates store m4_women

restore

*-------------------------------------------------------------------------------
* Table with all models
*-------------------------------------------------------------------------------

esttab m1_men m2_men m3_men m4_men m1_women m2_women m3_women m4_women ///
	using "$tables/Table3_decline.rtf", replace ///
	cells(b(fmt(3)) & _star se(par)) stats(N r2 bic) 
	
********************************************************************************
* Figure 2: Predicted Probability Plots
********************************************************************************

/* For the figures we use the original age variable (not centered) and an
unstandardized version of the linkage strength variable
*/

*-------------------------------------------------------------------------------
* Figure 2a: Men, Simple Model (Model 2)
*-------------------------------------------------------------------------------

preserve

keep if female==0

* We look at the predicted probabilities for three groups
sum ls_edfld, detail
local p10 = r(p10)		// low linkage strength 10th percentile
sum ls_edfld, detail
local mean = r(mean)	// medium linkage strength, mean
sum ls_edfld, detail
local p90 = r(p90)		// high linkage strength 90th percentile

regress employed ls_edfld age c.age#c.age c.age#c.ls_edfld i.edlev_isced ///
	i.region i.year [pweight=wgt]

margins, at(age=(16 20 25 30 35 40 45 50 55 60 65) ///
	ls_edfld=(`p10' `mean' `p90')) atmeans
	
marginsplot, scheme(s2color) xtitle(Age) ytitle(Predicted Probabilities) 	///
	title("") ylabel(0.2 0.4 0.6 0.8 1,angle(horizontal))					///
	plotopts(msize(small) mlwidth(vthin) lwidth(medthin)) 					///
	legend(col(1) order(1 2 3) label(1 "Low Occ. Specificity (10th perc.)") ///
	label(2 "Average Occ. Specificity") 									///
	label(3 "High Occ. Specificity (90th perc.)")) 							///
	graphregion(color(white)) yscale(range(0 1))
graph export "$figures/Figure2a_pp_men.pdf", replace

restore

*-------------------------------------------------------------------------------
* Figure 2b: Men, Full Model with all Interactions (Model 4)
*-------------------------------------------------------------------------------

preserve
keep if female==0

* We look at the predicted probabilities for three groups
sum ls_edfld, detail
local p10 = r(p10)		// low linkage strength 10th percentile
sum ls_edfld, detail
local mean = r(mean)	// medium linkage strength, mean
sum ls_edfld, detail
local p90 = r(p90)		// high linkage strength 90th percentile

regress employed ls_edfld age c.age#c.age c.age#c.age#c.age 				///
	c.age#c.age#c.age#c.age 												///
	c.age#c.ls_edfld c.age#c.age#c.ls_edfld c.age#c.age#c.age#c.ls_edfld 	///
	c.age#c.age#c.age#c.age#c.ls_edfld 										///
	i.edlev_isced i.region i.year [pweight=wgt]

margins, at(age=(16 20 25 30 35 40 45 50 55 60 65) ///
	ls_edfld=(`p10' `mean' `p90')) atmeans
	
marginsplot, scheme(s2color) xtitle(Age) ytitle(Predicted Probabilities) 	///
	title("") ylabel(0.2 0.4 0.6 0.8 1,angle(horizontal))					///
	plotopts(msize(small) mlwidth(vthin) lwidth(medthin)) 					///
	legend(col(1) order(1 2 3) label(1 "Low Occ. Specificity (10th perc.)") ///
	label(2 "Average Occ. Specificity") 									///
	label(3 "High Occ. Specificity (90th perc.)")) 							///
	graphregion(color(white)) yscale(range(0 1))
	
graph export "$figures/Figure2b_pp_men_age4.pdf", replace

restore

*-------------------------------------------------------------------------------
* Figure 2c: Women, Simple Model (Model 2)
*-------------------------------------------------------------------------------

preserve
keep if female==1

* We look at the predicted probabilities for three groups
sum ls_edfld, detail
local p10 = r(p10)		// low linkage strength 10th percentile
sum ls_edfld, detail
local mean = r(mean)	// medium linkage strength, mean
sum ls_edfld, detail
local p90 = r(p90)		// high linkage strength 90th percentile

regress employed ls_edfld age c.age#c.age c.age#c.ls_edfld i.edlev_isced ///
	i.region i.year [pweight=wgt]

margins, at(age=(16 20 25 30 35 40 45 50 55 60 65) ///
	ls_edfld=(`p10' `mean' `p90')) atmeans

marginsplot, scheme(s2color) xtitle(Age) ytitle(Predicted Probabilities) 	///
	title("") ylabel(0.2 0.4 0.6 0.8 1,angle(horizontal))					///
	plotopts(msize(small) mlwidth(vthin) lwidth(medthin)) 					///
	legend(col(1) order(1 2 3) label(1 "Low Occ. Specificity (10th perc.)") ///
	label(2 "Average Occ. Specificity") 									///
	label(3 "High Occ. Specificity (90th perc.)")) 							///
	graphregion(color(white)) yscale(range(0 1))
	
graph export "$figures/Figure2c_pp_women.pdf", replace	

restore

*-------------------------------------------------------------------------------
* Figure 2d: Women, Full Model with all interactions (Model 4)
*-------------------------------------------------------------------------------

preserve
keep if female==1

* We look at the predicted probabilities for three groups
sum ls_edfld, detail
local p10 = r(p10)		// low linkage strength 10th percentile
sum ls_edfld, detail
local mean = r(mean)	// medium linkage strength, mean
sum ls_edfld, detail
local p90 = r(p90)		// high linkage strength 90th percentile

regress employed ls_edfld age c.age#c.age c.age#c.age#c.age 				///
	c.age#c.age#c.age#c.age 												///
	c.age#c.ls_edfld c.age#c.age#c.ls_edfld c.age#c.age#c.age#c.ls_edfld 	///
	c.age#c.age#c.age#c.age#c.ls_edfld 										///
	i.edlev_isced i.region i.year [pweight=wgt]

margins, at(age=(16 20 25 30 35 40 45 50 55 60 65) ///
	ls_edfld=(`p10' `mean' `p90')) atmeans
	
marginsplot, scheme(s2color) xtitle(Age) ytitle(Predicted Probabilities) 	///
	title("") ylabel(0.2 0.4 0.6 0.8 1,angle(horizontal))					///
	plotopts(msize(small) mlwidth(vthin) lwidth(medthin)) 					///
	legend(col(1) order(1 2 3) label(1 "Low Occ. Specificity (10th perc.)") ///
	label(2 "Average Occ. Specificity") 									///
	label(3 "High Occ. Specificity (90th perc.)")) 							///
	graphregion(color(white)) yscale(range(0 1))
	
graph export "$figures/Figure2d_pp_women_age4.pdf", replace

restore

********************************************************************************
* Figure 3: Conditional marginal effect plots final models
********************************************************************************

/* For the figures we use the original age variable (not centered) and an
unstandardized version of the linkage strength variable
*/

*-------------------------------------------------------------------------------
* Figure 3a: Men, Simple Model (Model 1)
*-------------------------------------------------------------------------------

preserve
keep if female==0

regress employed ls_edfld age c.age#c.age c.age#c.ls_edfld i.edlev_isced ///
	i.region i.year [pweight=wgt]

margins, dydx(ls_edfld) at(age= (16 20 25 30 35 40 45 50 55 60 65)) atmeans

marginsplot, scheme(s2color) xtitle(Age) 								///
	ytitle(Conditional Marginal Effect of Occ. Specificity) title("") 	///
	yline(0) ylabel(-0.15 (0.05) 0.15 ,angle(horizontal)) 				///
	graphregion(color(white))
	
graph export "$figures/Figure3a_me_men.pdf", replace

restore

*-------------------------------------------------------------------------------
* Figure 3b: Men, Full Model with all Interactions (Model 4)
*-------------------------------------------------------------------------------

preserve
keep if female==0

regress employed ls_edfld age c.age#c.age c.age#c.age#c.age 				///
	c.age#c.age#c.age#c.age 												///
	c.age#c.ls_edfld c.age#c.age#c.ls_edfld c.age#c.age#c.age#c.ls_edfld 	///
	c.age#c.age#c.age#c.age#c.ls_edfld 										///
	i.edlev_isced i.region i.year [pweight=wgt]
	
margins, dydx(ls_edfld) at(age= (16 20 25 30 35 40 45 50 55 60 65)) atmeans

marginsplot, scheme(s2color) xtitle(Age) 								///
	ytitle(Conditional Marginal Effect of Occ. Specificity) title("") 	///
	yline(0) ylabel(-0.15 (0.05) 0.15 ,angle(horizontal)) 				///
	graphregion(color(white))
	
graph export "$figures/Figure3b_me_men_age4.pdf", replace

restore

*-------------------------------------------------------------------------------
* Figure 3c: Women, Simple Model (Model 1)
*-------------------------------------------------------------------------------

preserve

keep if female==1

regress employed ls_edfld age c.age#c.age c.age#c.ls_edfld i.edlev_isced ///
	i.region i.year [pweight=wgt]

margins, dydx(ls_edfld) at(age= (16 20 25 30 35 40 45 50 55 60 65)) atmeans

marginsplot, scheme(s2color) xtitle(Age) 								///
	ytitle(Conditional Marginal Effect of Occ. Specificity) title("") 	///
	yline(0) ylabel(-0.15 (0.05) 0.15 ,angle(horizontal)) 				///
	graphregion(color(white))
		
graph export "$figures/Figure3c_me_women.pdf", replace
restore

*-------------------------------------------------------------------------------
* Figure 3d: Women, Full Model with all Interactions (Model 4)
*-------------------------------------------------------------------------------

preserve

keep if female==1

regress employed ls_edfld age c.age#c.age c.age#c.age#c.age 				///
	c.age#c.age#c.age#c.age 												///
	c.age#c.ls_edfld c.age#c.age#c.ls_edfld c.age#c.age#c.age#c.ls_edfld 	///
	c.age#c.age#c.age#c.age#c.ls_edfld 										///
	i.edlev_isced i.region i.year [pweight=wgt]
	
margins, dydx(ls_edfld) at(age=(16 20 25 30 35 40 45 50 55 60 65)) atmeans

marginsplot, scheme(s2color) xtitle(Age) 								///
	ytitle(Conditional Marginal Effect of Occ. Specificity) title("") 	///
	yline(0) ylabel(-0.15 (0.05) 0.15 ,angle(horizontal)) 				///
	graphregion(color(white))

graph export "$figures/Figure3d_me_women_age4.pdf", replace

restore

