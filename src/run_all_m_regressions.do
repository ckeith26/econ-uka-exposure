/*
UKA Group Project - Selection on Observables Analysis
Econ 20: Measuring the causal impact of UKA exposure

11/17/2025
Professor Duque

by:
Cameron Keith, cameron.s.keith.26@dartmouth.edu
Josh Wolfson,  josh.s.wolfson.26@dartmouth.edu
Annabella Wu,  annabella.wu.26@dartmouth.edu
Jesse Dong,    jesse.c.dong.26@dartmouth.edu

run_all_m_regressions.do

This stata script loads the cleaned dataset from 'data/uka_exposure_dataset.dta' 
and runs all regressions on treatment variables for each month from 3-36 months exposure.

Note: Please run create_dataset.do before executing this file. 
The log will be saved in 'logs/run_all_m_regressions.log'. 
*/

** Note: Please change this line to your working directory
// local basepath "/Users/joshuawolfson/Desktop/Econ20/FinalProj"
clear all

local basepath "/Users/cameronkeith/Desktop/Econ/Econ 20/econ-uka-exposure"
cd "`basepath'"

capture log close
log using "`basepath'/logs/run_all_m_regressions.log", replace

* Create main results directory
capture mkdir "`basepath'/results"

display _newline(3)
display as result "{hline 80}"
display as result "UKA EXPOSURE ANALYSIS: 3-36 MONTHS"
display as result "Starting analysis at: $S_TIME on $S_DATE"
display as result "{hline 80}"
display _newline(2)


* MAIN LOOP: Run analysis for each exposure horizon (3-36 months)


forvalues t = 3(1)36 {
    
    display _newline(3)
    display as result "{hline 80}"
    display as result "PROCESSING EXPOSURE HORIZON: `t' MONTHS"
    display as result "{hline 80}"
    display _newline(1)
    
    * Create output directory for this exposure level
    capture mkdir "`basepath'/results/exp_`t'm"
    
    * Load fresh data for this iteration
    use "`basepath'/data/uka_exposure_dataset.dta", clear
    
    * Check if sample exists for this exposure level
    quietly count if sample_`t' == 1
    if r(N) == 0 {
        display as error "No observations for `t'-month exposure. Skipping..."
        continue
    }
    
    display as text "Sample size for `t'-month exposure: " as result r(N)
    local N_obs = r(N)
    
    * Restrict to sample
    keep if sample_`t'
    

    * Run Regression Analysis

    
    display as text "Running regressions..."
    
    * (1) Treatment + Age FE only (baseline specification)
    quietly eststo m1: reg p_imc treatment_`t' ///
        i.rounded_edad_meses
    local coef_1 = _b[treatment_`t']
    local se_1 = _se[treatment_`t']
    
    * (2) Add baseline health controls
    quietly eststo m2: reg p_imc treatment_`t' ///
        bmi_baseline anemia_baseline male ///
        i.rounded_edad_meses
    local coef_2 = _b[treatment_`t']
    local se_2 = _se[treatment_`t']
    
    * (3) Add SES controls
    quietly eststo m3: reg p_imc treatment_`t' ///
        bmi_baseline anemia_baseline male ///
        `sesvars' ///
        i.rounded_edad_meses
    local coef_3 = _b[treatment_`t']
    local se_3 = _se[treatment_`t']
    
    * (4) Add grupo fixed effects
    quietly eststo m4: reg p_imc treatment_`t' ///
        bmi_baseline anemia_baseline male ///
        `sesvars' ///
        i.rounded_edad_meses ///
        i.grupo_fe
    local coef_4 = _b[treatment_`t']
    local se_4 = _se[treatment_`t']
    
    * (5) Full specification: add calendar fixed effects
    quietly eststo m5: reg p_imc treatment_`t' ///
        bmi_baseline anemia_baseline male ///
        `sesvars' ///
        i.rounded_edad_meses ///
        i.grupo_fe ///
        i.calendar_fe
    local coef_5 = _b[treatment_`t']
    local se_5 = _se[treatment_`t']
    
    * Display results summary
    display _newline(1)
    display as text "Coefficients for `t'-month exposure:"
    display as text "  (1) Age FE:        " as result %6.3f `coef_1' as text " (SE = " as result %6.3f `se_1' as text ")"
    display as text "  (2) + Health:      " as result %6.3f `coef_2' as text " (SE = " as result %6.3f `se_2' as text ")"
    display as text "  (3) + SES:         " as result %6.3f `coef_3' as text " (SE = " as result %6.3f `se_3' as text ")"
    display as text "  (4) + Grupo FE:    " as result %6.3f `coef_4' as text " (SE = " as result %6.3f `se_4' as text ")"
    display as text "  (5) Full:          " as result %6.3f `coef_5' as text " (SE = " as result %6.3f `se_5' as text ")"
    

    * Export regression tables (TEX + HTML only)

    
    display as text "Exporting regression tables..."
    
    * LaTeX format (for paper)
    quietly esttab m1 m2 m3 m4 m5 using "`basepath'/results/exp_`t'm/uka_`t'm_results.tex", ///
        b(3) se(3) ///
        star(* 0.10 ** 0.05 *** 0.01) ///
        keep(treatment_`t' bmi_baseline anemia_baseline male calories_weekly iron_weekly food_spending) ///
        order(treatment_`t' bmi_baseline anemia_baseline male calories_weekly iron_weekly food_spending) ///
        stats(N r2, fmt(0 3) labels("Observations" "R-squared")) ///
        indicate("Age FE = *.rounded_edad_meses" ///
                 "Grupo FE = *.grupo_fe" ///
                 "Calendar FE = *.calendar_fe") ///
        mtitles("(1)" "(2)" "(3)" "(4)" "(5)") ///
        mgroups("Age FE" "Health" "SES" "Grupo FE" "Full", pattern(1 1 1 1 1)) ///
        title("Effect of UKA Exposure on Child BMI: `t' Months") ///
        label ///
        booktabs ///
        replace
    
    * HTML format (open in browser and screenshot for PNG)
    quietly esttab m1 m2 m3 m4 m5 using "`basepath'/results/exp_`t'm/uka_`t'm_results.html", ///
        b(3) se(3) ///
        star(* 0.10 ** 0.05 *** 0.01) ///
        keep(treatment_`t' bmi_baseline anemia_baseline male calories_weekly iron_weekly food_spending) ///
        order(treatment_`t' bmi_baseline anemia_baseline male calories_weekly iron_weekly food_spending) ///
        stats(N r2, fmt(0 3) labels("Observations" "R-squared")) ///
        indicate("Age FE = *.rounded_edad_meses" ///
                 "Grupo FE = *.grupo_fe" ///
                 "Calendar FE = *.calendar_fe") ///
        mtitles("(1)" "(2)" "(3)" "(4)" "(5)") ///
        title("Effect of UKA Exposure on Child BMI: `t' Months") ///
        replace
    
    * Clear stored estimates
    eststo clear
    

    * GRAPH 1: Coefficient Stability Plot

    
    display as text "Creating graphs..."
    
    preserve
    clear
    set obs 5
    gen spec = _n
    gen coef = .
    gen se = .
    gen ci_lower = .
    gen ci_upper = .
    
    replace coef = `coef_1' if spec == 1
    replace se = `se_1' if spec == 1
    
    replace coef = `coef_2' if spec == 2
    replace se = `se_2' if spec == 2
    
    replace coef = `coef_3' if spec == 3
    replace se = `se_3' if spec == 3
    
    replace coef = `coef_4' if spec == 4
    replace se = `se_4' if spec == 4
    
    replace coef = `coef_5' if spec == 5
    replace se = `se_5' if spec == 5
    
    * Calculate confidence intervals
    replace ci_lower = coef - 1.96*se
    replace ci_upper = coef + 1.96*se
    
    * Create coefficient plot
    quietly twoway ///
        (rcap ci_lower ci_upper spec, lcolor(navy)) ///
        (scatter coef spec, mcolor(navy) msize(medium)), ///
        xlabel(1 "Age FE" 2 "Health" 3 "SES" 4 "Grupo FE" 5 "Full", angle(45)) ///
        xtitle("Specification") ///
        ytitle("Treatment Effect (BMI z-score)") ///
        title("Coefficient Stability Across Specifications") ///
        subtitle("`t'-Month UKA Exposure") ///
        legend(off) ///
        yline(0, lpattern(dash) lcolor(red)) ///
        note("Note: Bars show 95% confidence intervals. All models control for age (matching variable).")
    
    quietly graph export "`basepath'/results/exp_`t'm/coef_stability_`t'm.png", replace width(2400)
    
    restore
    

    * Reload data for remaining graphs

    
    use "`basepath'/data/uka_exposure_dataset.dta", clear
    keep if sample_`t'
    

    * GRAPH 2: Baseline Plot (Age FE Only)

    
    quietly twoway ///
        (scatter p_imc treatment_`t', msymbol(o) msize(vsmall) mcolor(navy%30) jitter(2)) ///
        (lfit p_imc treatment_`t', lcolor(red) lwidth(medium)), ///
        xtitle("Treatment (`t' months exposure)") ///
        ytitle("BMI-for-age z-score") ///
        title("Baseline: Controlling for Age Only") ///
        subtitle("`t'-Month UKA Exposure") ///
        legend(off) ///
        note("Coefficient: β = `=string(`coef_1', "%6.3f")' (SE = `=string(`se_1', "%6.3f")') | Controls: Age FE")
    
    quietly graph export "`basepath'/results/exp_`t'm/baseline_`t'm.png", replace
    

    * Create residuals for FWL plots

    
    * Residualize p_imc on all controls + FE (excluding treatment)
    quietly reg p_imc ///
        bmi_baseline anemia_baseline male ///
        `sesvars' ///
        i.rounded_edad_meses ///
        i.grupo_fe ///
        i.calendar_fe
    capture drop y_resid
    quietly predict double y_resid, resid
    
    * Residualize treatment on the same controls + FE
    quietly reg treatment_`t' ///
        bmi_baseline anemia_baseline male ///
        `sesvars' ///
        i.rounded_edad_meses ///
        i.grupo_fe ///
        i.calendar_fe
    capture drop t_resid
    quietly predict double t_resid, resid
    
    * Verify FWL gives same coefficient
    quietly reg y_resid t_resid
    local beta_fwl = _b[t_resid]
    

    * GRAPH 3: FWL Plot (Full Specification)

    
    quietly twoway ///
        (scatter y_resid t_resid, msymbol(o) msize(vsmall) mcolor(navy%30) jitter(2)) ///
        (lfit y_resid t_resid, lcolor(red) lwidth(medium)), ///
        xtitle("Residualized treatment (`t' months of exposure)") ///
        ytitle("Residualized BMI-for-age z-score") ///
        title("Full Specification (After All Controls)") ///
        subtitle("`t'-Month UKA Exposure") ///
        legend(off) ///
        note("Coefficient: β = `=string(`coef_5', "%6.3f")' (SE = `=string(`se_5', "%6.3f")') | Full controls: Health, SES, Age FE, Grupo FE, Calendar FE")
    
    quietly graph export "`basepath'/results/exp_`t'm/fwl_`t'm.png", replace
    

    * GRAPH 4: Side-by-Side Comparison (Baseline vs Full)

    
    * Panel A: Baseline (Age FE only)
    quietly twoway ///
        (scatter p_imc treatment_`t', msymbol(o) msize(vsmall) mcolor(navy%30) jitter(2)) ///
        (lfit p_imc treatment_`t', lcolor(red) lwidth(medium)), ///
        xtitle("Treatment") ///
        ytitle("BMI z-score") ///
        title("(A) Age FE: β = `=string(`coef_1', "%5.3f")'", size(medium)) ///
        legend(off) ///
        name(baseline_`t', replace)
    
    * Panel B: Full specification (FWL)
    quietly twoway ///
        (scatter y_resid t_resid, msymbol(o) msize(vsmall) mcolor(navy%30) jitter(2)) ///
        (lfit y_resid t_resid, lcolor(red) lwidth(medium)), ///
        xtitle("Residualized treatment") ///
        ytitle("Residualized BMI z-score") ///
        title("(B) Full: β = `=string(`coef_5', "%5.3f")'", size(medium)) ///
        legend(off) ///
        name(fwl_`t', replace)
    
    * Combine panels
    quietly graph combine baseline_`t' fwl_`t', ///
        rows(1) ///
        title("Robustness to Control Variables: `t'-Month UKA Exposure") ///
        note("Note: Both panels control for age (matching variable). Panel B adds health, SES, grupo FE, and calendar FE.")
    
    quietly graph export "`basepath'/results/exp_`t'm/comparison_`t'm.png", replace width(3000)
    
    * Clean up graph names
    quietly graph drop baseline_`t' fwl_`t'
    

    * GRAPH 5: FWL Theorem Demonstration

    
    * Store full regression coefficient and CI
    local beta_full = `coef_5'
    local se_full = `se_5'
    local ci_lower = `beta_full' - 1.96*`se_full'
    local ci_upper = `beta_full' + 1.96*`se_full'
    
    * Panel A: Full regression coefficient
    preserve
    clear
    set obs 1
    gen spec = 1
    gen coef = `beta_full'
    gen ci_lower_plot = `ci_lower'
    gen ci_upper_plot = `ci_upper'
    
    quietly twoway ///
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
        name(full_reg_`t', replace)
    
    restore
    
    * Panel B: FWL scatter plot
    quietly twoway ///
        (scatter y_resid t_resid, msymbol(o) msize(vsmall) mcolor(navy%30) jitter(2)) ///
        (lfit y_resid t_resid, lcolor(red) lwidth(medium)), ///
        xtitle("Residualized treatment") ///
        ytitle("Residualized BMI z-score") ///
        title("(B) FWL: Same Coefficient", size(medium)) ///
        subtitle("β = `=string(`beta_fwl', "%6.3f")'") ///
        legend(off) ///
        note("Frisch-Waugh-Lovell: Slope of residuals plot") ///
        name(fwl_demo_`t', replace)
    
    * Combine to show equivalence
    quietly graph combine full_reg_`t' fwl_demo_`t', ///
        rows(1) ///
        title("Frisch-Waugh-Lovell Theorem Demonstration") ///
        subtitle("`t'-Month UKA Exposure") ///
        note("Note: Both panels show β = `=string(`beta_full', "%6.3f")'. " ///
             "Panel A: Coefficient from full regression. Panel B: Slope from FWL residuals. Mathematically identical.")
    
    quietly graph export "`basepath'/results/exp_`t'm/fwl_demonstration_`t'm.png", replace width(3000)
    
    * Clean up
    quietly graph drop full_reg_`t' fwl_demo_`t'
    

    * Display summary

    
    local total_change = `coef_1' - `coef_5'
    local pct_change = (`total_change'/`coef_1') * 100
    
    display _newline(1)
    display as text "Analysis summary for `t'-month exposure:"
    display as text "  Total change (Age FE to Full):    " as result %6.3f `total_change'
    display as text "  Percent change:                   " as result %6.1f `pct_change' "%"
    display as text "  FWL verification (should be ~0):  " as result %9.6f (`beta_full' - `beta_fwl')
    
    display as result "{hline 80}"
    display as text "Completed `t'-month analysis"
    display as result "{hline 80}"
    
} // End of main loop


* Final summary


display _newline(3)
display as result "{hline 80}"
display as result "ALL ANALYSES COMPLETE"
display as result "Finished at: $S_TIME on $S_DATE"
display as result "{hline 80}"
display _newline(1)
display as text "Results saved in: `basepath'/results/exp_[3-36]m/"
display _newline(1)
display as text "Files created for each exposure horizon:"
display as text "  Tables:"
display as text "    - uka_[X]m_results.tex (for LaTeX/paper)"
display as text "    - uka_[X]m_results.html (open in browser, screenshot for PNG)"
display _newline(1)
display as text "  Graphs (PNG):"
display as text "    - coef_stability_[X]m.png"
display as text "    - baseline_[X]m.png"
display as text "    - fwl_[X]m.png"
display as text "    - comparison_[X]m.png"
display as text "    - fwl_demonstration_[X]m.png"
display _newline(1)

log close
