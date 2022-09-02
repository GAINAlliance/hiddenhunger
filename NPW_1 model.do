


*******************************************************************************************
* Bayesian Hierarchical Logistic regression 
*******************************************************************************************

* Set directory first

* Model number
local num = 16
use input_data.dta, clear
log using model.smcl, replace
 di "Model number" `num'

 bayes, rseed(52) nchains(4) burnin(100000) mcmcsize(1000) thinning(100) saving(draws, replace) showreffects({Reg0} {Stud0}) restubs(Reg Stud) prior({Reg0:sigma2}, uniform(0,5)) prior({Stud0:sigma2}, uniform(0,5)): melogit any_def_cnt sdi || region_number: ||survey_no:, binomial(any_def_nstar)
 bayesstats grubin
log close

bayesgraph diagnostics _all, acopts(lags(100)) saving(checksmod`num',replace)
forvalues X = 1/4 {
	graph use checksmod`num'`X'
	graph export checksmod`num'`X'.pdf, replace
	erase checksmod`num'`X'.gph
	}
forvalues X = 1/6 {
	bayesgraph diagnostics {Reg0[`X']}, acopts(lags(100))
	graph export checksmod`num'Reg`X'.pdf, replace
	}








