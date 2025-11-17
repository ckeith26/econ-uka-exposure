/*
UKA Group Project – Selection on Observables Analysis
Econ 20: Measuring the causal impact of UKA exposure

11/17/2025
Professor Duque

by:
Josh Wolfson,  josh.s.wolfson.26@dartmouth.edu
Cameron Keith, cameron.s.keith.26@dartmouth.edu
Annabella Wu,  annabella.wu.26@dartmouth.edu
Jesse Dong,    jesse.c.dong.26@dartmouth.edu

create_dataset.do:

This stata script loads, cleans, processes, creates, and saves the final dataset to 'UKA_exposure_dataset.dta'. It also summarizes the treatment and control vars used in other regressions and saves the result to 'logs/sumstats_uka.xls'. 

Note: Please change line 26 to your working directory to run this code. Also, the data can either be in the working directory or in a folder, 'data' (in the working directory). The log file will be saved in 'logs/create_dataset.log'.
*/
* 0. Setup
clear all

* Note: Please change this line to your working directory
// local basepath "/Users/joshuawolfson/Desktop/Econ20/FinalProj"
local basepath "/Users/cameronkeith/Desktop/Econ/Econ 20/econ-uka-exposure"
cd "`basepath'"

* set up eda and data folders
capture mkdir "eda"
capture mkdir "data"
capture mkdir "logs"
capture mkdir "results"

capture log close
log using "`basepath'/logs/create_dataset.log", replace

* Try loading from working directory first
capture import excel using "panelUKA_fuzzymerge.xlsx", firstrow clear

* If that failed (_rc != 0), try from data subdirectory
if _rc != 0 {
    display as text "File not found in working directory, trying data/ folder..."
    import excel using "`basepath'/data/panelUKA_fuzzymerge.xlsx", firstrow clear
}

* 1. Basic cleaning and sample restrictions

drop borrado
drop Borrado
rename _all, lower

* Identify duplicates of (child, measurement date)
duplicates tag id_ninio peso_fsoma, gen(dup)

* Drop duplicates (keep the first occurrence)
drop if dup

* Clean up helper variable
drop dup

* Outcome: BMI-for-age z-score, drop missing and extreme outliers
drop if missing(p_imc) | p_imc < -5 | p_imc > 5

* Need measurement date and birth date
drop if missing(peso_fsoma) | missing(fnac_ym)


* 2. Date variables and age calculation
* Convert measurement date string to Stata date
gen double date_meas = date(peso_fsoma, "DM20Y")
format date_meas %td

* Convert birth year-month to monthly date
gen date_birth_m = monthly(fnac_ym, "YM")
format date_birth_m %tm

* Measurement month
gen meas_m = mofd(date_meas)
format meas_m %tm

* Clean age in months at measurement
gen edad_meses = peso_edad
label var edad_meses "Age in months at measurement"

* Rounded age in months
gen rounded_edad_meses = round(edad_meses)
label var rounded_edad_meses "Age in months (rounded)"

* Calendar time variable for fixed effects
gen calendar_ym = meas_m
format calendar_ym %tm
label var calendar_ym "Calendar year-month of measurement"



* 3. Core controls: sex, baseline health

* Child sex (dummy)
gen byte male = (sexonum == 2) if !missing(sexonum)
label var male "Male child"

* Baseline BMI (first panel BMI z-score, pre-exposure)
gen bmi_baseline = p_imc_ini
label var bmi_baseline "Baseline BMI-for-age z-score (initial panel measurement)"

* Baseline anemia (1 = anemic at baseline, 0 = not anemic)
gen byte anemia_baseline = .
replace anemia_baseline = 1 if hb_anemiadicot_ini == "ANEMICO"
replace anemia_baseline = 0 if hb_anemiadicot_ini != "ANEMICO" & !missing(hb_anemiadicot_ini)
label var anemia_baseline "Baseline anemia status (1 = anemic)"


* 4. Socioeconomic status controls available in panelUKA_fuzzymerge

* Build a macro of SES variables that exist and are non-missing
local sesvars

* Weekly calorie intake
capture confirm variable total_calorias_semana
if !_rc {
    gen calories_weekly = total_calorias_semana
    label var calories_weekly "Weekly calorie intake"
    quietly count if !missing(calories_weekly)
    if r(N) > 0 local sesvars `sesvars' calories_weekly
}

* Weekly iron intake
capture confirm variable total_hierro_semana
if !_rc {
    gen iron_weekly = total_hierro_semana
    label var iron_weekly "Weekly iron intake (mg)"
    quietly count if !missing(iron_weekly)
    if r(N) > 0 local sesvars `sesvars' iron_weekly
}

* Weekly household spending on food (numeric SES proxy)
* Search for variable with label containing 'alimentación'
ds, has(varlabel "*alimenta*")
local foodvar `r(varlist)'

if "`foodvar'" != "" {
    di as result "Using food spending variable: `foodvar'"

    gen food_spending = `foodvar'
    label var food_spending "Weekly household food expenditure"

    quietly count if !missing(food_spending)
    if r(N) > 0 local sesvars `sesvars' food_spending
} 
else {
    di as error "Food spending variable not found — skipping."
}


* 5. Age controls and fixed effects

* Age polynomial
gen age         = edad_meses
gen age_squared = edad_meses^2
gen age_cubed   = edad_meses^3
label var age         "Age in months"
label var age_squared "Age squared"
label var age_cubed   "Age cubed"

* Calendar FE (year-month)
egen calendar_fe = group(calendar_ym)
label var calendar_fe "Calendar year-month FE"

* Municipio FE
egen municipio_fe = group(id_municipio)
label var municipio_fe "municipio FE"

* Locality FE
egen locality_fe = group(id_localidad)
label var locality_fe "Locality FE"

* Grupo FE
egen grupo_fe = group(id_grupo)
label var grupo_fe "grupo FE"



* 6. Program exposure variables

* Program start date in each community (earliest measurement date)
bys id_grupo: egen start_date_grupo = min(date_meas)
format start_date_grupo %td
gen start_m_grupo = mofd(start_date_grupo)
format start_m_grupo %tm
label var start_m_grupo "Program start month in grupo"


* Program start date in each locality (earliest measurement date)
bys id_localidad: egen start_date_locality = min(date_meas)
format start_date_locality %td
gen start_m_locality = mofd(start_date_locality)
format start_m_locality %tm
label var start_m_locality "Program start month in locality"

* Program start date in each municipio (earliest measurement date)
bys id_municipio: egen start_date_municipio = min(date_meas)
format start_date_municipio %td
gen start_m_municipio = mofd(start_date_municipio)
format start_m_municipio %tm
label var start_m_municipio "Program start month in municipio"

* Program start date in each estado (earliest measurement date)
// bys id_estado: egen start_date_estado = min(date_meas)
// format start_date_estado %td
// gen start_m_estado = mofd(start_date_estado)
// format start_m_estado %tm
// label var start_m_estado "Program start month in estado"

* Each child's first measurement date
bys id_ninio: egen first_meas_child = min(date_meas)
format first_meas_child %td

* Months of program exposure (time since program started in locality)
gen program_exposure = meas_m - start_m_locality
label var program_exposure "Months since program start in locality"

* Child enrolled at program start (within 30 days)
gen enrolled_at_start = (abs(first_meas_child - start_date_locality) <= 30)
label var enrolled_at_start "Child enrolled within 30 days of locality program start"


* 7. Define treatment and control groups

* Keep only early joiners
keep if enrolled_at_start == 1

* Define eligibility windows (mask each measurement)
gen in_control_window = inrange(program_exposure, 0, 1)

* Distance to the target month within each window
gen dist_0  = abs(program_exposure) if in_control_window

* For each child, pick the closest control obs (if any)
bysort id_ninio (dist_0 date_meas): ///
    gen best_control = in_control_window & dist_0 == dist_0[1]

ssc install estout, replace

forvalues t = 3(1)36 {
    local lo = `t' - 1
    local hi = `t' + 1

    * Treated: ~t months exposure
    gen treat_`t'   = inrange(program_exposure, `lo', `hi')

    * Control: ~0 months exposure
    gen control_`t' = inrange(program_exposure, 0, 1)

    * Sample: either treated or control
    gen sample_`t'  = treat_`t' | control_`t'

    * Treatment indicator
    gen treatment_`t' = treat_`t'

    di "------ Horizon `t' months ------"
    tab treatment_`t' if sample_`t'
}

* 8. Summary statistics table

* Child-level treatment + pre/post flags
* Define vars once
local sumvars p_imc male bmi_baseline anemia_baseline ///
    calories_weekly iron_weekly food_spending age

display "`sumvars'"	
	
* 1) Treated: 4 months exposure
preserve
    keep if treatment_12
    outreg2 using "eda/sumstats_uka.xls", ///
        sum(log) ///
        keep(`sumvars') ///
        ctitle("Treated, 12 months exposure") ///
        replace
restore

* 2) Control: just joined / 0 months exposure
preserve
    keep if best_control
    outreg2 using "eda/sumstats_uka.xls", ///
        sum(log) ///
        keep(`sumvars') ///
        ctitle("Control, 0 months exposure") ///
        append
restore 

label data "UKA Exposure Dataset Creation - Created on $S_DATE"
save "`basepath'/data/uka_exposure_dataset.dta", replace

log close
