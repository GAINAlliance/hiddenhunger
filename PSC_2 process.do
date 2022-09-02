* Obtain prevalence estimates from draws
* This is for a one-covariate logistic regression
* Inference at country level
clear
clear matrix
clear mata
set maxvar 120000

* Note: set directory prior to running

* select the model to process
local num = 15
local poptype = "pop_under5"

* process draws yes/no
local processdraws = 1

if `processdraws' {

	use country_covariates.dta, clear
	keep if year == 2013
	tempfile countries popdat
	save `popdat'
	keep iso3 sdi region_number
	levelsof iso3, local(iso3s)
	gen index = 1
	reshape wide sdi region_number, i(index) j(iso3) string
	save `countries'


	use draws.dta, clear
	gen draw = _n
	sum draw
	local num_draws = r(max)
	keep draw eq*
	
	* merge in country covariate data
	gen index = 1
	merge m:1 index using `countries'

	* drop study random effects
	drop eq2* eq4_p1

	* assign the region numbers correctly. The regions are misnumbered because there were no input data from MENA (region 5); correct this first. 
	ren eq1_p6 eq1_p7
	ren eq1_p5 eq1_p6
	
	* draw from a standard normal distribution for each draw for region 5
	drawnorm eq1_p5
	* Multiply by the SD of the region random effects (sqrt of the variance)
	replace eq1_p5 = eq1_p5*sqrt(eq3_p1)
	order eq1*

	* select the correct a_j for each survey, then compute prevalence for each country-draw
	foreach iso3 in `iso3s' {
		quietly gen a_j`iso3' = .
		forvalues region = 1/7 {
			capture replace a_j`iso3' = eq1_p`region' if region_number`iso3' == `region'
			}	
		gen any_def`iso3' = invlogit(a_j`iso3'+sdi`iso3'*eq5_p1+eq5_p2)
	}
	
	keep draw any_def* 
	reshape long any_def, i(draw) j(iso3) string
	reshape wide any_def, i(iso3) j(draw)
	
	* merge in population, and compute pop-weighted prevalences
	merge 1:1 iso3 using `popdat'
	forvalues X = 1/`num_draws' {
		gen num`X' = any_def`X'*`poptype'
	}
	tempfile regdata
	save `regdata'
	replace analysis_group = "Globe"
	replace region_number = 0
	append using `regdata'
	collapse (sum) num* pop*, by(region_number analysis_group)
	forvalues X = 1/`num_draws' {
		gen prev`X' = num`X'/`poptype'
	}

	egen any_def = rowmean(prev*)
	egen any_defupr = rowpctile(prev*), p(95)
	egen any_deflwr = rowpctile(prev*), p(5)
	egen any_nummean = rowmean(num*)
	egen any_numupr = rowpctile(num*), p(95)
	egen any_numlwr = rowpctile(num*), p(5)


	keep region_number any* pop_npw_15_49 pop_under5 analysis_group

	save results.dta, replace
}





