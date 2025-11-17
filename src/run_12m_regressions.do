/*
UKA Group Project - Selection on Observables Analysis
Econ 20: Measuring the causal impact of UKA exposure
11/17/2025
Professor Duque

by:
Josh Wolfson,  josh.s.wolfson.26@dartmouth.edu
Cameron Keith, cameron.s.keith.26@dartmouth.edu
Annabella Wu,  annabella.wu.26@dartmouth.edu
Jesse Dong,    jesse.c.dong.26@dartmouth.edu

run_12m_regressions.do

This stata script loads the cleaned dataset from 'data/uka_exposure_dataset.dta' 
and runs the regressions on treatment_12, which measures the UKA exposure effect 
of 12 months.

Note: Please run create_dataset.do before executing this file. 
The log will be saved in 'logs/run_12m_regressions.log'.
*/

** Note: Please change this line to your working directory
// local basepath "/Users/joshuawolfson/Desktop/Econ20/FinalProj"
clear all

local basepath "/Users/cameronkeith/Desktop/Econ/Econ 20/econ-uka-exposure"
cd "`basepath'"

capture log close

capture mkdir "logs"
capture mkdir "results"
capture mkdir "results/exp_12m"
log using "`basepath'/logs/run_12m_regressions.log", replace
label data "UKA Exposure 12 months Regressions - Created on $S_DATE"

use "`basepath'/data/uka_exposure_dataset.dta", clear

/*
Regression Analysis: 
Show how treatment effect changes as we add control variables
NOTE: Age FE included in ALL specifications (required for matching ages across treatment and control groups)
*/

* Restrict to sample first
keep if sample_12

* Store observation count
quietly count
local N_obs = r(N)

* (1) Treatment + Age FE only (baseline specification)
eststo m1: reg p_imc treatment_12 ///
    i.rounded_edad_meses
local coef_1 = _b[treatment_12]
local se_1 = _se[treatment_12]

* (2) Add baseline health controls
eststo m2: reg p_imc treatment_12 ///
    bmi_baseline anemia_baseline male ///
    i.rounded_edad_meses
local coef_2 = _b[treatment_12]
local se_2 = _se[treatment_12]

* (3) Add SES controls
eststo m3: reg p_imc treatment_12 ///
    bmi_baseline anemia_baseline male ///
    `sesvars' ///
    i.rounded_edad_meses
local coef_3 = _b[treatment_12]
local se_3 = _se[treatment_12]

* (4) Add grupo fixed effects
eststo m4: reg p_imc treatment_12 ///
    bmi_baseline anemia_baseline male ///
    `sesvars' ///
    i.rounded_edad_meses ///
    i.grupo_fe
local coef_4 = _b[treatment_12]
local se_4 = _se[treatment_12]

* (5) Full specification: add calendar fixed effects
eststo m5: reg p_imc treatment_12 ///
    bmi_baseline anemia_baseline male ///
    `sesvars' ///
    i.rounded_edad_meses ///
    i.grupo_fe ///
    i.calendar_fe
local coef_5 = _b[treatment_12]
local se_5 = _se[treatment_12]


* Export regression table (TEX + HTML for PNG conversion)


* LaTeX format (for paper)
esttab m1 m2 m3 m4 m5 using "`basepath'/results/exp_12m/uka_12m_results.tex", ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(treatment_12 bmi_baseline anemia_baseline male calories_weekly iron_weekly food_spending) ///
    order(treatment_12 bmi_baseline anemia_baseline male calories_weekly iron_weekly food_spending) ///
    stats(N r2, fmt(0 3) labels("Observations" "R-squared")) ///
    indicate("Age FE = *.rounded_edad_meses" ///
             "Grupo FE = *.grupo_fe" ///
             "Calendar FE = *.calendar_fe") ///
    mtitles("(1)" "(2)" "(3)" "(4)" "(5)") ///
    mgroups("Age FE" "Health" "SES" "Grupo FE" "Full", pattern(1 1 1 1 1)) ///
    title("Effect of UKA Exposure on Child BMI: 12 Months") ///
    label ///
    booktabs ///
    replace

* HTML format (open in browser and screenshot for PNG)
esttab m1 m2 m3 m4 m5 using "`basepath'/results/exp_12m/uka_12m_results.html", ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(treatment_12 bmi_baseline anemia_baseline male calories_weekly iron_weekly food_spending) ///
    order(treatment_12 bmi_baseline anemia_baseline male calories_weekly iron_weekly food_spending) ///
    stats(N r2, fmt(0 3) labels("Observations" "R-squared")) ///
    indicate("Age FE = *.rounded_edad_meses" ///
             "Grupo FE = *.grupo_fe" ///
             "Calendar FE = *.calendar_fe") ///
    mtitles("(1)" "(2)" "(3)" "(4)" "(5)") ///
    title("Effect of UKA Exposure on Child BMI: 12 Months") ///
    replace

display _newline(1)
display as result "Regression table exported:"
display as text "  - TEX:  uka_12m_results.tex (for paper)"
display as text "  - HTML: uka_12m_results.html (open in browser, screenshot for PNG)"
display _newline(1)

* Clear stored estimates
eststo clear


* GRAPH 1: Coefficient Stability Plot
* Shows how treatment effect changes across specifications


* Create coefficient plot dataset
clear
set obs 5
gen spec = _n
gen coef = .
gen se = .
gen ci_lower = .
gen ci_upper = .
gen label = ""

replace coef = `coef_1' if spec == 1
replace se = `se_1' if spec == 1
replace label = "Age FE" if spec == 1

replace coef = `coef_2' if spec == 2
replace se = `se_2' if spec == 2
replace label = "Health" if spec == 2

replace coef = `coef_3' if spec == 3
replace se = `se_3' if spec == 3
replace label = "SES" if spec == 3

replace coef = `coef_4' if spec == 4
replace se = `se_4' if spec == 4
replace label = "Grupo FE" if spec == 4

replace coef = `coef_5' if spec == 5
replace se = `se_5' if spec == 5
replace label = "Full" if spec == 5

* Calculate confidence intervals
replace ci_lower = coef - 1.96*se
replace ci_upper = coef + 1.96*se

* Create coefficient plot
twoway ///
    (rcap ci_lower ci_upper spec, lcolor(navy)) ///
    (scatter coef spec, mcolor(navy) msize(medium)), ///
    xlabel(1 "Age FE" 2 "Health" 3 "SES" 4 "Grupo FE" 5 "Full", angle(45)) ///
    xtitle("Specification") ///
    ytitle("Treatment Effect (BMI z-score)") ///
    title("Coefficient Stability Across Specifications") ///
    subtitle("12-Month UKA Exposure") ///
    legend(off) ///
    yline(0, lpattern(dash) lcolor(red)) ///
    note("Note: Bars show 95% confidence intervals. All models control for age (matching variable).")

graph export "`basepath'/results/exp_12m/coef_stability_12m.png", replace width(2400)
graph display


* Reload the main dataset for remaining graphs

use "`basepath'/data/uka_exposure_dataset.dta", clear
keep if sample_12


* GRAPH 2: Baseline Plot (Age FE Only)
* Shows relationship conditional on age matching


twoway ///
    (scatter p_imc treatment_12, msymbol(o) msize(vsmall) mcolor(navy%30) jitter(2)) ///
    (lfit p_imc treatment_12, lcolor(red) lwidth(medium)), ///
    xtitle("Treatment (12 months exposure)") ///
    ytitle("BMI-for-age z-score") ///
    title("Baseline: Controlling for Age Only") ///
    subtitle("12-Month UKA Exposure") ///
    legend(off) ///
    note("Coefficient: β = `=string(`coef_1', "%6.3f")' (SE = `=string(`se_1', "%6.3f")') | Controls: Age FE")

graph export "`basepath'/results/exp_12m/baseline_12m.png", replace
graph display


* Create residuals for FWL plots


* Residualize p_imc on all controls + FE (excluding treatment_12)
quietly reg p_imc ///
    bmi_baseline anemia_baseline male ///
    `sesvars' ///
    i.rounded_edad_meses ///
    i.grupo_fe ///
    i.calendar_fe
predict double y_resid, resid

* Residualize treatment_12 on the same controls + FE
quietly reg treatment_12 ///
    bmi_baseline anemia_baseline male ///
    `sesvars' ///
    i.rounded_edad_meses ///
    i.grupo_fe ///
    i.calendar_fe
predict double t_resid, resid


* GRAPH 3: FWL Plot (Full Specification)
* Shows relationship after partialling out all controls


twoway ///
    (scatter y_resid t_resid, msymbol(o) msize(vsmall) mcolor(navy%30) jitter(2)) ///
    (lfit y_resid t_resid, lcolor(red) lwidth(medium)), ///
    xtitle("Residualized treatment (12 months of exposure)") ///
    ytitle("Residualized BMI-for-age z-score") ///
    title("Full Specification (After All Controls)") ///
    subtitle("12-Month UKA Exposure") ///
    legend(off) ///
    note("Coefficient: β = `=string(`coef_5', "%6.3f")' (SE = `=string(`se_5', "%6.3f")') | Full controls: Health, SES, Age FE, Grupo FE, Calendar FE")

graph export "`basepath'/results/exp_12m/fwl_12m.png", replace
graph display


* GRAPH 4: Side-by-Side Comparison (Baseline vs Full)
* Shows how controls affect the estimated relationship


* Panel A: Baseline (Age FE only)
twoway ///
    (scatter p_imc treatment_12, msymbol(o) msize(vsmall) mcolor(navy%30) jitter(2)) ///
    (lfit p_imc treatment_12, lcolor(red) lwidth(medium)), ///
    xtitle("Treatment") ///
    ytitle("BMI z-score") ///
    title("(A) Age FE only: β = `=string(`coef_1', "%5.3f")'", size(medium)) ///
    legend(off) ///
    name(baseline, replace)

* Panel B: Full specification (FWL)
twoway ///
    (scatter y_resid t_resid, msymbol(o) msize(vsmall) mcolor(navy%30) jitter(2)) ///
    (lfit y_resid t_resid, lcolor(red) lwidth(medium)), ///
    xtitle("Residualized treatment") ///
    ytitle("Residualized BMI z-score") ///
    title("(B) Full controls: β = `=string(`coef_5', "%5.3f")'", size(medium)) ///
    legend(off) ///
    name(fwl, replace)

* Combine panels
graph combine baseline fwl, ///
    rows(1) ///
    title("Robustness to Control Variables: 12-Month UKA Exposure") ///
    note("Note: Both panels control for age (matching variable). Panel B adds health, SES, grupo FE, and calendar FE.")

graph export "`basepath'/results/exp_12m/comparison_12m.png", replace width(3000)
graph display

* Clean up graph names
graph drop baseline fwl


* GRAPH 5: FWL Theorem Demonstration
* Shows full regression coefficient = FWL slope


* Store full regression coefficient and CI
local beta_full = `coef_5'
local se_full = `se_5'
local ci_lower = `beta_full' - 1.96*`se_full'
local ci_upper = `beta_full' + 1.96*`se_full'

* Verify FWL gives same coefficient
quietly reg y_resid t_resid
local beta_fwl = _b[t_resid]

* Panel A: Full regression coefficient (as point estimate with CI)
preserve
clear
set obs 1
gen spec = 1
gen coef = `beta_full'
gen ci_lower_plot = `ci_lower'
gen ci_upper_plot = `ci_upper'

twoway ///
    (rcap ci_lower_plot ci_upper_plot spec, lcolor(navy) lwidth(thick)) ///
    (scatter coef spec, mcolor(navy) msize(large)), ///
    xlabel(none) ///
    xtitle("") ///
    ytitle("Treatment Effect (BMI z-score)") ///
    title("(A) Full Regression Coefficient", size(medium)) ///
    subtitle("β = `=string(`beta_full', "%6.3f")'") ///
    legend(off) ///
    yline(0, lpattern(dash) lcolor(red)) ///
    xscale(range(0.5 1.5)) ///
    note("Coefficient from full regression with all controls") ///
    name(full_reg, replace)

restore

* Panel B: FWL scatter plot (shows SAME coefficient)
twoway ///
    (scatter y_resid t_resid, msymbol(o) msize(vsmall) mcolor(navy%30) jitter(2)) ///
    (lfit y_resid t_resid, lcolor(red) lwidth(medium)), ///
    xtitle("Residualized treatment") ///
    ytitle("Residualized BMI z-score") ///
    title("(B) FWL: Same Coefficient", size(medium)) ///
    subtitle("β = `=string(`beta_fwl', "%6.3f")'") ///
    legend(off) ///
    note("Frisch-Waugh-Lovell: Slope of residuals plot") ///
    name(fwl_demo, replace)

* Combine to show equivalence
graph combine full_reg fwl_demo, ///
    rows(1) ///
    title("Frisch-Waugh-Lovell Theorem Demonstration") ///
    subtitle("12-Month UKA Exposure") ///
    note("Note: Both panels show β = `=string(`beta_full', "%6.3f")'. " ///
         "Panel A: Coefficient from full regression. Panel B: Slope from FWL residuals. Mathematically identical.")

graph export "`basepath'/results/exp_12m/fwl_demonstration_12m.png", replace width(3000)
graph display

* Clean up
graph drop full_reg fwl_demo


* Display detailed analysis summary in log


display _newline(2)
display as result "{hline 80}"
display as result "ANALYSIS SUMMARY: 12-MONTH UKA EXPOSURE"
display as result "{hline 80}"
display _newline(1)

display as text "Specification progression (all conditional on age):"
display as text "{hline 80}"
display as text "  (1) Age FE only (baseline):           " as result %6.3f `coef_1' as text " (SE = " as result %6.3f `se_1' as text ")"
display as text "  (2) + Baseline health controls:       " as result %6.3f `coef_2' as text " (SE = " as result %6.3f `se_2' as text ")"
display as text "  (3) + SES controls:                   " as result %6.3f `coef_3' as text " (SE = " as result %6.3f `se_3' as text ")"
display as text "  (4) + Grupo fixed effects:            " as result %6.3f `coef_4' as text " (SE = " as result %6.3f `se_4' as text ")"
display as text "  (5) Full (+ Calendar FE):             " as result %6.3f `coef_5' as text " (SE = " as result %6.3f `se_5' as text ")"
display as text "{hline 80}"
display _newline(1)

display as text "Robustness Analysis (conditional on age matching):"
display as text "{hline 80}"
local total_change = `coef_1' - `coef_5'
local pct_change = (`total_change'/`coef_1') * 100
display as text "  Total change (Age FE to Full):        " as result %6.3f `total_change'
display as text "  Percent change:                       " as result %6.1f `pct_change' "%"

display _newline(1)
display as text "Incremental changes (conditional on age):"
display as text "  Adding health controls:               " as result %6.3f (`coef_2' - `coef_1')
display as text "  Adding SES controls:                  " as result %6.3f (`coef_3' - `coef_2')
display as text "  Adding grupo FE:                      " as result %6.3f (`coef_4' - `coef_3')
display as text "  Adding calendar FE:                   " as result %6.3f (`coef_5' - `coef_4')

display _newline(1)
display as text "FWL Verification:"
display as text "  Full regression coefficient:          " as result %6.3f `beta_full'
display as text "  FWL residuals slope:                  " as result %6.3f `beta_fwl'
display as text "  Difference (should be ~0):            " as result %9.6f (`beta_full' - `beta_fwl')

display _newline(1)
display as text "Interpretation:"
display as text "  Age FE ensures we compare children of the same age (matching design)."
display as text "  Remaining differences come from health/SES selection within age groups."

if abs(`pct_change') < 10 {
    display as text "  Small change (<10%) suggests weak confounding after age matching."
    display as text "  Selection-on-observables assumption appears plausible."
}
else if abs(`pct_change') < 30 {
    display as text "  Moderate change (10-30%) after age matching."
    display as text "  Health/SES controls matter beyond age."
}
else {
    display as text "  Large change (>30%) even after age matching."
    display as text "  Substantial confounding from health/SES within age groups."
}

display as result "{hline 80}"
display _newline(1)

display as result "OUTPUT FILES CREATED:"
display as text "  Tables:"
display as text "    - uka_12m_results.tex (for LaTeX/paper)"
display as text "    - uka_12m_results.html (open in browser, screenshot for PNG)"
display _newline(1)
display as text "  Graphs (PNG):"
display as text "    - coef_stability_12m.png"
display as text "    - baseline_12m.png"
display as text "    - fwl_12m.png"
display as text "    - comparison_12m.png"
display as text "    - fwl_demonstration_12m.png"
display _newline(1)

log close
