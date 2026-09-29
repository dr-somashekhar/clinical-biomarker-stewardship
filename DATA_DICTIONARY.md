# 📚 Data Dictionary & Clinical Codebook

This document describes the simulated variables and pharmacokinetic/pharmacodynamic (PK/PD) features utilized within the Antimicrobial Stewardship Program (ASP) and Procalcitonin (PCT) kinetics models.

Data are in **long format**: one row per patient per `Time_Hour`. Patient-level variables (sections 1, 3 and 4) repeat on every row for that patient; analyses of patient-level outcomes must use one row per patient (e.g. `Time_Hour == 0`). `simulate_cohort()` generates a dataset in exactly this shape.

## 1. Patient Demographics & Clinical Baseline
| Variable Name | Data Type | Description | Unit / Coding |
| :--- | :--- | :--- | :--- |
| `Patient_ID` | Integer | Unique identifier for the simulated patient | `1` to `N` |
| `Admission_Ward` | Categorical | Hospital unit of admission | `ICU`, `General_Medicine` |
| `Infection_Source`| Categorical | Primary diagnosis driving systemic inflammatory response | `CAP` (Comm. Acquired Pneumonia), `VAP` (Ventilator Acquired), `Sepsis_Unknown` |
| `Baseline_SOFA` | Numeric | Sequential Organ Failure Assessment score at admission | Scale `0` - `24` |

## 2. Serial Biomarker Kinetics (Longitudinal Data)
| Variable Name | Data Type | Description | Unit / Coding |
| :--- | :--- | :--- | :--- |
| `Time_Hour` | Numeric | Time elapsed since initial empirical antibiotic administration | Hours (`0`, `24`, `48`, `72`) |
| `PCT_Level` | Numeric | Serum Procalcitonin concentration | $ng/mL$ |
| `PCT_Clearance` | Numeric | Percentage decrease of PCT from the highest value up to this timepoint (`pct_clearance()`) | Percentage (%) |
| `WBC_Count` | Numeric | White Blood Cell Count | $10^3/\mu L$ |

## 3. Pharmacotherapy & Stewardship Interventions
| Variable Name | Data Type | Description | Unit / Coding |
| :--- | :--- | :--- | :--- |
| `Empiric_Abx` | Categorical | Initial broad-spectrum antibiotic regimen | e.g., `Pip-Tazo`, `Meropenem` |
| `ASP_Recommendation`| Categorical | Output of `asp_recommendation()` at this timepoint: `Discontinue` if ≥80% decline from peak or PCT < 0.25 ng/mL; else `De-escalate` if PCT is 0.25 to < 0.5 ng/mL; else `Continue` | `Continue`, `De-escalate`, `Discontinue` |
| `Abx_Duration` | Numeric | Total consecutive days of active antibiotic therapy (simulated as the day of the first `Discontinue`, minimum 1; 7 if never reached) | Days |

## 4. Clinical Outcomes
| Variable Name | Data Type | Description | Unit / Coding |
| :--- | :--- | :--- | :--- |
| `Length_of_Stay` | Numeric | Total hospital length of stay | Days |
| `Mortality_30D` | Binary | 30-day all-cause mortality | `0` = Alive, `1` = Deceased |
| `CDI_Event` | Binary | Occurrence of Clostridioides difficile infection (collateral damage metric) | `0` = No, `1` = Yes |

*Note: All datasets are synthetically generated to model antimicrobial stewardship algorithms and contain no real patient Protected Health Information (PHI).*
