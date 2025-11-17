# UKA Nutrition Program Impact Analysis

**Econometric Analysis of the Causal Effect of UKA Exposure on Child BMI**

Econ 20: Econometrics  
Professor Duque  
Dartmouth College  
Fall 2025

## Team Members

- **Cameron Keith** - cameron.s.keith.26@dartmouth.edu
- **Josh Wolfson** - josh.s.wolfson.26@dartmouth.edu
- **Annabella Wu** - annabella.wu.26@dartmouth.edu
- **Jesse Dong** - jesse.c.dong.26@dartmouth.edu

## Research Question

**Does exposure to the UKA nutrition program improve child BMI-for-age z-scores?**

This project uses a **selection-on-observables** approach to estimate the causal effect of 12 months of program exposure (compared to 0 months) on child nutritional outcomes, measured by BMI-for-age z-scores.

## Project Overview

### Key Features
- **Panel data analysis** with 9,087 child-measurement observations
- **Quasi-experimental design** comparing children with different exposure levels
- **Matching on age** to create comparable treatment/control groups
- **Multiple specifications** to test robustness to control variables
- **Fixed effects** for locality and calendar time
- **Frisch-Waugh-Lovell (FWL) visualizations** to demonstrate control variable effects

### Research Design

We compare children with approximately:
- **Treatment group**: 12 months of program exposure (window: 11-13 months)
- **Control group**: 0 months of program exposure (window: 0-1 months)

Both groups are restricted to "early joiners" who enrolled within 30 days of program launch in their locality. This ensures comparability and reduces selection bias.

### Identification Strategy

The key identifying assumption is that **conditional on observables** (age, baseline BMI, anemia status, household SES, locality, and calendar time), program exposure is as-good-as-random. We control for:

1. **Age** (matching variable via fixed effects)
2. **Baseline health** (BMI z-score, anemia status)
3. **Socioeconomic status** (calorie/iron intake, food spending)
4. **Locality fixed effects** (community-level characteristics)
5. **Calendar fixed effects** (seasonal patterns, secular trends)

## Directory Structure

```
econ-uka-exposure/
├── data/                          # Data files
│   ├── panelUKA_fuzzymerge.xlsx  # Primary merged panel dataset
│   ├── censo_anon.xlsx           # Anonymized census data
│   ├── edi_anon.xlsx             # Anonymized EDI data
│   ├── panel_anon.xlsx           # Anonymized panel data
│   └── uka_exposure_dataset.dta  # Processed Stata dataset (generated)
│
├── src/                           # Stata analysis scripts
│   ├── create_dataset.do         # Data cleaning and processing
│   ├── run_12m_regressions.do    # Main regression analysis (12-month horizon)
│   └── run_all_m_regressions.do  # Regression analysis (all horizons: 3-36 months)
│
├── results/                       # Regression output and visualizations
│   └── exp_12m/                  # Results for 12-month exposure analysis
│       ├── uka_12m_results.tex   # Regression table (LaTeX)
│       ├── uka_12m_results.html  # Regression table (HTML)
│       ├── coef_stability_12m.png       # Coefficient stability plot
│       ├── baseline_12m.png             # Baseline specification scatter plot
│       ├── fwl_12m.png                  # FWL residual plot
│       ├── comparison_12m.png           # Side-by-side comparison
│       └── fwl_demonstration_12m.png    # FWL theorem demonstration
│
├── logs/                          # Execution logs
│   ├── create_dataset.log        # Dataset creation log
│   ├── run_12m_regressions.log   # 12-month regression log
│   └── run_all_m_regressions.log # All-horizons regression log
│
├── eda/                           # Exploratory data analysis
│   ├── sumstats_uka.txt          # Summary statistics (text)
│   └── sumstats_uka.xls          # Summary statistics (Excel)
│
├── docs/                          # Documentation and slides
│   ├── Project overview.pdf      # Project description
│   ├── Group Presentation Slides.pdf
│   └── UKA.pdf                   # Background documentation
│
├── README.md                      # This file
├── CURSOR.md                      # Project context for Cursor AI
└── CLAUDE.md                      # Project context for Claude AI
```

## How to Run the Analysis

### Prerequisites
- **Stata** (version 13 or higher recommended)
- Required Stata packages:
  - `estout` (for regression tables)
  - All other commands use built-in Stata functionality

### Installation
1. Clone or download this repository
2. Ensure the `data/` folder contains the required Excel files
3. Update the `basepath` variable in each `.do` file to match your local directory

### Running the Complete Analysis

#### Step 1: Create the Dataset
```stata
cd "/Users/[YOUR_USERNAME]/path/to/econ-uka-exposure"
do src/create_dataset.do
```

**What this does:**
- Imports and cleans the merged panel data
- Removes BMI outliers and missing observations
- Calculates age and program exposure variables
- Creates treatment/control indicators for multiple exposure horizons (3-36 months)
- Generates control variables (baseline health, SES, fixed effects)
- Saves processed dataset to `data/uka_exposure_dataset.dta`
- Produces summary statistics in `eda/sumstats_uka.xls`

**Output:** `data/uka_exposure_dataset.dta` + log file in `logs/create_dataset.log`

---

#### Step 2: Run Main Regressions (12-Month Horizon)
```stata
do src/run_12m_regressions.do
```

**What this does:**
- Loads the processed dataset
- Runs 5 regression specifications with progressively more controls:
  1. Age FE only (baseline)
  2. + Baseline health controls (BMI, anemia, sex)
  3. + SES controls (calories, iron, food spending)
  4. + Grupo fixed effects
  5. Full specification (+ calendar FE)
- Exports regression tables (`.tex` and `.html`)
- Creates visualizations:
  - Coefficient stability plot
  - Baseline scatter plot
  - FWL residual plot
  - Side-by-side comparison
  - FWL theorem demonstration

**Output:** Results in `results/exp_12m/` + log file in `logs/run_12m_regressions.log`

---

#### Step 3 (Optional): Run Regressions for All Exposure Horizons
```stata
do src/run_all_m_regressions.do
```

**What this does:**
- Runs the same analysis for exposure horizons from 3-36 months
- Useful for robustness checks and exploring dose-response relationships

**Output:** Results in `results/exp_*m/` directories + log file

### Quick Start (All Steps)
```stata
cd "/Users/[YOUR_USERNAME]/path/to/econ-uka-exposure"
do src/create_dataset.do
do src/run_12m_regressions.do
```

## Data Description

### Primary Dataset: `panelUKA_fuzzymerge.xlsx`
Merged panel dataset with 203 variables and 9,087 observations tracking children's nutritional measurements over time.

### Key Variables

#### Outcome Variable
- `p_imc` — BMI-for-age z-score (WHO standards)
  - Valid range: -5 to 5 (extreme outliers removed)

#### Treatment Variables (Constructed)
- `treatment_12` — Binary indicator (1 = 12 months exposure, 0 = control)
- `program_exposure` — Continuous months since program started in locality
- `enrolled_at_start` — Child enrolled within 30 days of program launch

#### Control Variables

**Baseline Health:**
- `bmi_baseline` — Baseline BMI-for-age z-score (from initial measurement)
- `anemia_baseline` — Baseline anemia status (1 = anemic)
- `male` — Child sex (1 = male, 0 = female)

**Socioeconomic Status:**
- `calories_weekly` — Weekly household calorie intake
- `iron_weekly` — Weekly household iron intake (mg)
- `food_spending` — Weekly household food expenditure

**Fixed Effects:**
- `rounded_edad_meses` — Age in months (rounded) for matching
- `grupo_fe` — Grupo (community group) fixed effects
- `calendar_fe` — Calendar year-month fixed effects

#### Identifiers
- `id_ninio` — Unique child identifier
- `id_localidad` — Locality identifier
- `id_municipio` — Municipality identifier
- `id_grupo` — Grupo identifier

### Sample Construction

1. **Start with full panel:** 9,087 observations
2. **Remove outliers:** Drop BMI z-scores outside [-5, 5]
3. **Restrict to early joiners:** Keep only children enrolled within 30 days of program start
4. **Define exposure windows:**
   - Control: 0-1 months of exposure
   - Treatment: 11-13 months of exposure
5. **One observation per child:** Select measurement closest to target exposure level

**Final sample size varies by specification** (typically 1,000-3,000 observations)

## Key Results

### Regression Specifications

All specifications include age fixed effects (matching variable). We progressively add controls to test robustness:

| Specification | Controls | Purpose |
|---------------|----------|---------|
| (1) Age FE | Age matching only | Baseline effect |
| (2) Health | + Baseline BMI, anemia, sex | Control for baseline health |
| (3) SES | + Calorie/iron intake, food spending | Control for household wealth |
| (4) Grupo FE | + Community fixed effects | Control for locality characteristics |
| (5) Full | + Calendar fixed effects | Control for time trends |

### Interpretation

The **coefficient stability plot** shows how the estimated treatment effect changes as we add controls. If the coefficient remains relatively stable, this suggests that:
1. Selection bias is limited after matching on age
2. The selection-on-observables assumption is plausible
3. Unobserved confounders are likely to be minimal

The **FWL plots** demonstrate that controlling for covariates is equivalent to residualizing both the outcome and treatment variables and regressing the residuals on each other.

### Balance Checks

Before interpreting results as causal, verify that treatment and control groups are balanced on baseline characteristics (see log files for balance tests).

## Visualizations

### 1. Coefficient Stability Plot (`coef_stability_12m.png`)
Shows how the treatment effect estimate changes across specifications. Stable coefficients suggest robust estimates.

### 2. Baseline Scatter Plot (`baseline_12m.png`)
Raw relationship between treatment and outcome, controlling only for age matching.

### 3. FWL Residual Plot (`fwl_12m.png`)
Shows the relationship after partialling out all control variables. Slope equals the full regression coefficient.

### 4. Side-by-Side Comparison (`comparison_12m.png`)
Compares baseline vs. full specification side-by-side to show the impact of controls.

### 5. FWL Theorem Demonstration (`fwl_demonstration_12m.png`)
Verifies that the full regression coefficient equals the slope of the FWL residual plot (should be mathematically identical).

## Technical Notes

### Research Design Considerations

**Threats to Identification:**
1. **Age confounding** — Controlled via age fixed effects (matching variable)
2. **Baseline health selection** — Controlled via baseline BMI and anemia
3. **Locality differences** — Controlled via locality/grupo fixed effects
4. **Seasonal/time trends** — Controlled via calendar fixed effects
5. **Household SES** — Controlled via calorie intake, iron intake, food spending

**Assumptions:**
- **Selection on observables:** Conditional on controls, treatment assignment is as-good-as-random
- **No spillovers:** Children in control group are not affected by treated children
- **Stable unit treatment value (SUTVA):** Treatment effect is the same for all children

### Stata Implementation Details

- **Standard errors:** Consider clustering at locality level (`vce(cluster id_localidad)`)
- **Missing data:** Listwise deletion (complete case analysis)
- **Age matching:** Rounded to nearest month for discrete fixed effects
- **Duplicate handling:** Each child contributes exactly one observation (verified with `duplicates report id_ninio`)

## Files You Can Modify

### Safe to Edit
- `src/*.do` — Analysis scripts (save new versions if making substantial changes)
- `README.md`, `CURSOR.md`, `CLAUDE.md` — Documentation

### DO NOT MODIFY
- `data/censo_anon.xlsx` — Original census data
- `data/edi_anon.xlsx` — Original EDI data  
- `data/panel_anon.xlsx` — Original panel data
- `data/panelUKA_fuzzymerge.xlsx` — Primary merged dataset

All data manipulation should occur in Stata scripts, preserving the original source files.

## Reproducibility

To ensure reproducibility:
1. **Update file paths:** Change `basepath` in each `.do` file to your local directory
2. **Run scripts in order:** `create_dataset.do` → `run_12m_regressions.do`
3. **Check log files:** Review `logs/*.log` for errors and summary output
4. **Verify duplicates:** Ensure `duplicates report id_ninio` shows zero duplicates in final sample
5. **Document changes:** If modifying sample definitions or controls, save as new script version

## Troubleshooting

### Common Issues

**Problem:** "File not found" error  
**Solution:** Update `basepath` variable at the top of each `.do` file

**Problem:** "Log file already open" error  
**Solution:** Close existing log with `log close` before running, or comment out `log using` line

**Problem:** Duplicate observations per child  
**Solution:** Check sample construction logic in `create_dataset.do`; each child should have exactly 1 observation

**Problem:** Balance tests show large differences  
**Solution:** May need to refine treatment/control windows or add more controls

**Problem:** Package not found (e.g., `estout`)  
**Solution:** Install with `ssc install estout, replace`

## Dependencies

### Required Software
- Stata 13 or higher
- Standard Stata packages (built-in)
- `estout` package for regression tables (auto-installed by `create_dataset.do`)

### Data Requirements
- Excel files in `data/` directory
- Sufficient disk space for generated datasets and visualizations

## Future Extensions

Potential directions for further analysis:
- [ ] Heterogeneous treatment effects (by age, sex, baseline health)
- [ ] Dose-response analysis (multiple exposure horizons)
- [ ] Placebo tests (falsification checks with pre-treatment outcomes)
- [ ] Alternative matching methods (propensity score matching, coarsened exact matching)
- [ ] Robustness to different age control specifications
- [ ] Analysis of differential attrition/missing data patterns

## References

### Program Background
See `docs/UKA.pdf` for details on the UKA nutrition program.

### WHO Growth Standards
BMI-for-age z-scores based on WHO Child Growth Standards (2006).

## License

This project is for academic purposes only. Data files are anonymized for privacy protection.

---

## Contact

For questions or comments, please contact any team member:
- Cameron Keith: cameron.s.keith.26@dartmouth.edu
- Josh Wolfson: josh.s.wolfson.26@dartmouth.edu
- Annabella Wu: annabella.wu.26@dartmouth.edu
- Jesse Dong: jesse.c.dong.26@dartmouth.edu

**Course:** Econ 20 - Econometrics  
**Instructor:** Professor Duque  
**Institution:** Dartmouth College  
**Term:** Fall 2025

