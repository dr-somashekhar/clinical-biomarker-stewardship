# pctsteward 0.1.0

First packaged release.

## New features

* PCT algorithm: `pct_cutoffs`, `classify_pct()`, `pct_clearance()`,
  `pct_decline_from_peak()` (80% decline stop rule) and `asp_recommendation()`.
* `simulate_cohort()` generates a synthetic long-format cohort matching
  `DATA_DICTIONARY.md`.
* `plot_pct_kinetics()` colours each patient by whether the stop rule is met.
* Renal dosing helpers `ideal_body_weight()`, `dosing_weight()`,
  `cockcroft_gault()` and `recommend_regimen()`, driven by the
  `renal_dose_rules` table.
* Vignette: "PCT-guided stewardship workflow".

## Bug fixes

* `screen_medications()` flagged every order for intervention, including
  correct ones, because it compared free-text orders with labels carrying a
  bracketed suffix. Orders are now regimen IDs.
* `screen_medications()` crashed with R internal errors on `NULL`, `NA` or
  vector inputs; it now gives a clear error naming the bad input.
* `build_stewardship_heatmap()` counted every timepoint as a separate patient,
  dropped PCT values of exactly 0, and used bands that did not match the
  README cut-offs. It now uses one admission row per patient, shows `n` on
  every tile, and hides mortality for cells with fewer than `min_cell_n`
  patients.

## Breaking changes

* `screen_medications()` takes `prescribed_regimen_id` (e.g. `"2g_q8h"`)
  instead of `prescribed_dose`, and returns snake_case fields with a
  machine-readable `status`.
* Cefepime CrCl breakpoints changed from 50 / 11 mL/min to
  60 / 30 / 11 mL/min (2 g q8h label table).
