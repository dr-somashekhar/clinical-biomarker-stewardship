# Procalcitonin (PCT) Stewardship for Resource-Limited Wards

> ⚠️ **Research and educational use only.** This software is not a medical device and has not been validated for clinical decision-making. Dosing outputs must be verified by a qualified clinician against current product labelling and the local formulary. Do not enter identifiable patient data.

Simulating kinetic clearance curves and clinical decision logic for procalcitonin-guided antibiotic de-escalation in resource-limited wards. This repository contains the clinical logic, implementation frameworks, and data simulation protocols based on our 2026 narrative review published in the *Indo American Journal of Pharmaceutical Sciences*. 📊

## Project Overview
In tight resource settings, empirical antibiotic overuse accelerates antimicrobial resistance (AMR). This project digitizes a **Procalcitonin-Guided Antibiotic Stewardship Algorithm** designed to safely guide antibiotic de-escalation in secondary and tertiary care wards (such as ESI hospitals).

## Core Algorithmic Logic
The clinical decision support engine applies specific PCT cutoffs (ng/mL) to optimize prescribing:
*  **< 0.1 ng/mL:** Bacterial infection highly unlikely; strongly encourage withholding or stopping antibiotics.
*  **0.1 – 0.25 ng/mL:** Bacterial infection unlikely; discourage initiation.
*  **0.25 – 0.5 ng/mL:** Possible bacterial infection; use clinical discretion.
*  **> 0.5 ng/mL:** Bacterial infection highly likely; safely continue or escalate therapy.
*  **The 80% Rule:** Regardless of the absolute value, a drop of **≥80% from the peak PCT value** is a validated signal that the infection is resolving and antibiotics can be safely stopped.

## Installation
Requires R ≥ 4.1.

```r
# install.packages("remotes")
remotes::install_github("dr-somashekhar/clinical-biomarker-stewardship")
```

Or, from a local clone:

```r
# install.packages("devtools")
devtools::install()
```

## Quickstart

```r
library(pctsteward)

# 68yo female, 105 kg, 160 cm, SCr 1.8 mg/dL; ordered cefepime 2 g IV q8h
res <- screen_medications(
  age_yrs = 68, weight_kg = 105, height_cm = 160, scr_mgdl = 1.8,
  sex_is_female = TRUE, drug_name = "cefepime", prescribed_regimen_id = "2g_q8h"
)
res$crcl_ml_min          #> 34.7
res$recommended_label    #> "2 g IV q12h"
res$status               #> "intervention_required"

# Supported regimens and CrCl bands
renal_dose_rules
```

`status` is one of `"approved"`, `"intervention_required"` or `"no_protocol"`. Orders are passed as a regimen ID from `renal_dose_rules$regimen_id` (e.g. `"2g_q8h"`), not free text.

To draw the PCT kinetics figure:

```sh
Rscript inst/scripts/pct_simulation.R
```

## Repository Contents
| Path | Purpose |
| :--- | :--- |
| `R/renal.R` | Renal dosing calculator: Devine IBW, AdjBW, Cockcroft-Gault, rule-table dose screening (`screen_medications()`) |
| `R/heatmap.R` | PCT × SOFA mortality risk heatmap (`build_stewardship_heatmap()`) |
| `inst/scripts/pct_simulation.R` | Simulated PCT clearance curves for a responder and a non-responder |
| `tests/testthat/` | Unit tests |
| `DATA_DICTIONARY.md` | Variables, units and coding for the simulated datasets |

## Development

```r
devtools::document()   # regenerate NAMESPACE and man/ from roxygen comments
devtools::test()       # run the test suite
devtools::check()      # full R CMD check
```

See [CONTRIBUTING.md](CONTRIBUTING.md) and [SECURITY.md](SECURITY.md).

## License
MIT — see [LICENSE.md](LICENSE.md).
