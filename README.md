# Replication-Files-VocDecline-SSR-2018

Andrea Forster and Thijs Bol, January 2018

In this replication set you can find the code and (parts of) the data that were used to perform 
the analyses in the article Forster, Andrea G. and Thijs Bol (2018). 
Vocational education and employment over the life course using a new measure of occupational specificity. Social Science Research 70: 176-197. 
If you have any questions, please send an e-mail to email@andrea-forster.com or t.bol@uva.nl. 

## Data

For this paper we use data from the Dutch Labor Force Survey (EBB), rounds 2010-2012. The EBB has a scientific use file which can be downloaded by researchers. 
For this article, however, we used a much more detailed and complete file that can only be accessed by applying for (remote) access via
Statistics Netherlands (Centraal Bureau voor de Statistiek, CBS). Therefore, the analyses cannot be replicated using the code available in this respository unless
the research acquires said access to the data.

## Code

The code consists of 10 Stata do-files that mirror the analsyses process chronologically. 

**0_master.do:**
  * Ties together all do-files and runs them in the correct order.

**1_prep_data.do:** 
  * cleanes the needed variables in the raw data files of the EBB 
  * combines the several rounds of the EBB used in this paper. 

**2_prepvar_linkage.do:** 
  * prepares the variables necessary to carry out the segregation analysis with the goal
	of obtaining the occupational specificity of each educational category
	These Variables are: Current occupation and highest education
  * Defines a sample of young workers for which we want to calculate the occupational
	specificity using occupation and education
  * Creates a set of educational categories that contain at least 100 observations, so
	that we do not face sparse cell bias
  
**3_analysis_linkage.do:** 
  * analyses the linkage strength (occupational specificity) of each educational 
	category in the data that contains at least 100 observations
	This means that the output of this do-file is a list of educational 
	categories which are linked to one value of linkage strength
  
**4_merge_linkage.do:** 
  * merges the linkage strength measure that was created in do-file "3_analysis_linkage.do" to each 
  individual in the EBB data set that was created in do-file "1_prep_data.do"
  
**5_prepvar_main.do:**
  * prepares all variables needed for the main regression analysis of vocational decline
  
**6_analysis_descriptives.do:**
  * produces descriptive statistics for all variables for the final sample
  * produces percentage of observations in the re-coded broader fields of education
  * produces density plot of vocational vs general education and t-test for difference
  
**7_analysis_main.do:**
  * analyses life course vocational decline by using linear probability models
 
**8_prepvar_appendixC.do:**
  * prepares the variables necessary to carry out the segregation analysis with the goal
	of obtaining the occupational specificity of each educational category
	These Variables are: Current occupation and highest education for
  * prepares three different age cohorts (young, middle, old) for the robustness check in
	Appendix C
  * prepares a set of educational categories that contain at least 100 observations, so
	that we do not face sparse cell bias

**9_analysis_linkage_appendixC.do:**
  * analyses the linkage strength (occupational specificity) of each educational 
	category in the data that contains at least 100 observations
	This means that the output of this do-file is a list of educational 
	categories which are linked to one value of linkage strength
  * calculates linkage strength separately for the three age groups (35 or
	younger, 36-50, 51 or older)


## Output 

* Table 1: Descriptive Statistics for the Full Regression Sample
* Table 3: Linear Probability models for the Life-course with Employment as Dependent Variable

* Figure 1: Occupational Specificity of Vocational and General Programs

*	Figure 2: Predicted Probabilities of Being Employed for different levels
	of linkage strength over the life-course 
  
*	Figure 3: Conditional Marginal Effects of Linkage Strength at different Ages

* Appendix Table B1: Existing Level-Field Combinations and their Linkage Strength

*	Appendix Table B2: List of 3-digit ISCO categories
