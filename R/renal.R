# =========================================================================================
# Clinical Pharmacokinetics: Renal Dosing Calculator
#
# I wrote this because relying on raw Actual Body Weight (ABW) in the standard
# Cockcroft-Gault equation often leads to supratherapeutic dosing and toxicity in
# obese patients. The helpers below calculate Ideal Body Weight (IBW) and Adjusted
# Body Weight (AdjBW) based on standard clinical pharmacy protocols before
# estimating clearance.
#
# RESEARCH / EDUCATIONAL USE ONLY. Not a medical device. Every breakpoint in
# `renal_dose_rules` must be verified against current product labelling and the
# local formulary before any clinical use.
# =========================================================================================

#' Renal dose-adjustment rules
#'
#' One row per CrCl band per drug. `crcl_lower` is the inclusive lower bound
#' (mL/min) of the band. Adding a drug means adding rows here, not code.
#'
#' Cefepime bands follow the label table for the 2 g q8h regimen
#' (>= 60 / 30-59 / 11-29 / < 11 mL/min). Verify against the current label and
#' local formulary before use.
#'
#' @format A data frame with columns `drug`, `crcl_lower`, `regimen_id`,
#'   `regimen_label`.
#' @export
renal_dose_rules <- data.frame(
  drug          = "cefepime",
  crcl_lower    = c(0, 11, 30, 60),
  regimen_id    = c("1g_q24h", "2g_q24h", "2g_q12h", "2g_q8h"),
  regimen_label = c("1 g IV q24h", "2 g IV q24h", "2 g IV q12h", "2 g IV q8h"),
  stringsAsFactors = FALSE
)

# Catching bad EHR data before it breaks the math. You'd be surprised how often
# a patient's height is entered as 15 cm instead of 150 cm in the real world.
assert_number <- function(x, name, lower, upper) {
  if (!is.numeric(x) || length(x) != 1L || is.na(x)) {
    stop(sprintf("`%s` must be a single, non-missing number.", name), call. = FALSE)
  }
  if (x < lower || x > upper) {
    stop(sprintf("`%s` = %s is outside the plausible range [%s, %s]. Check EHR units.",
                 name, format(x), lower, upper), call. = FALSE)
  }
  invisible(x)
}

# Validates every screen_medications() input before any math runs.
assert_patient_inputs <- function(age_yrs, weight_kg, height_cm, scr_mgdl, sex_is_female,
                                  drug_name) {
  assert_number(age_yrs,   "age_yrs",   18,  120)
  assert_number(weight_kg, "weight_kg", 20,  350)
  assert_number(height_cm, "height_cm", 100, 250)
  assert_number(scr_mgdl,  "scr_mgdl",  0.1, 20)
  if (!is.logical(sex_is_female) || length(sex_is_female) != 1L || is.na(sex_is_female)) {
    stop("`sex_is_female` must be TRUE or FALSE.", call. = FALSE)
  }
  valid_drug <- is.character(drug_name) && length(drug_name) == 1L &&
    !is.na(drug_name) && nzchar(trimws(drug_name))
  if (!valid_drug) stop("`drug_name` must be a single non-empty string.", call. = FALSE)
  invisible(TRUE)
}

#' Ideal body weight (Devine formula)
#'
#' Patients at or below 60 inches (152.4 cm) get the base weight only; the
#' Devine formula is known to underestimate IBW in shorter patients.
#'
#' @param height_cm Height in cm.
#' @param female Logical; `TRUE` for female.
#' @return IBW in kg. Vectorised.
#' @export
ideal_body_weight <- function(height_cm, female) {
  ifelse(female, 45.5, 50) + 2.3 * pmax(height_cm / 2.54 - 60, 0)
}

#' Dosing weight for Cockcroft-Gault
#'
#' If the patient is >20% over IBW, ABW overestimates clearance, so AdjBW is used.
#' If they are underweight (ABW < IBW), ABW is used to avoid overdosing.
#' Otherwise IBW is used.
#'
#' @param weight_kg Actual body weight in kg.
#' @param ibw_kg Ideal body weight in kg.
#' @param obesity_ratio ABW/IBW ratio above which AdjBW is used.
#' @param adj_factor AdjBW correction factor.
#' @return Dosing weight in kg. Vectorised.
#' @export
dosing_weight <- function(weight_kg, ibw_kg, obesity_ratio = 1.2, adj_factor = 0.4) {
  ifelse(weight_kg < ibw_kg, weight_kg,
         ifelse(weight_kg / ibw_kg > obesity_ratio,
                ibw_kg + adj_factor * (weight_kg - ibw_kg),
                ibw_kg))
}

#' Cockcroft-Gault creatinine clearance
#'
#' The classic 1976 equation, still the reference for most drug labelling.
#'
#' @param age_yrs Age in years.
#' @param dosing_wt_kg Dosing weight in kg (see [dosing_weight()]).
#' @param scr_mgdl Serum creatinine in mg/dL.
#' @param female Logical; applies the 0.85 correction when `TRUE`.
#' @return Estimated CrCl in mL/min. Vectorised.
#' @export
cockcroft_gault <- function(age_yrs, dosing_wt_kg, scr_mgdl, female) {
  crcl <- ((140 - age_yrs) * dosing_wt_kg) / (72 * scr_mgdl)
  ifelse(female, 0.85 * crcl, crcl)
}

#' Recommended regimen for a drug at a given CrCl
#'
#' @param drug Drug name (case-insensitive).
#' @param crcl Creatinine clearance in mL/min. Vectorised.
#' @param rules Rules table; defaults to [renal_dose_rules].
#' @return Regimen ID(s), or `NA_character_` if no protocol exists for `drug`.
#' @export
recommend_regimen <- function(drug, crcl, rules = renal_dose_rules) {
  drug_rules <- rules[rules$drug == tolower(trimws(drug)), , drop = FALSE]
  if (nrow(drug_rules) == 0L) return(NA_character_)
  drug_rules <- drug_rules[order(drug_rules$crcl_lower), , drop = FALSE]
  drug_rules$regimen_id[findInterval(crcl, drug_rules$crcl_lower)]
}

#' Screen a single medication order against renal-dosing rules
#'
#' Returns a structured list rather than printing to the console, so it can be
#' plugged straight into a Shiny dashboard or an API.
#'
#' @param age_yrs Age in years (adults only, 18-120). Use the Schwartz equation
#'   for paediatrics.
#' @param weight_kg Actual body weight in kg.
#' @param height_cm Height in cm.
#' @param scr_mgdl Serum creatinine in mg/dL.
#' @param sex_is_female `TRUE` or `FALSE`.
#' @param drug_name Drug name, e.g. `"cefepime"`.
#' @param prescribed_regimen_id The ordered regimen as a regimen ID from
#'   `rules$regimen_id`, e.g. `"2g_q8h"`.
#' @param rules Rules table; defaults to [renal_dose_rules].
#' @return A list. `status` is one of `"approved"`,
#'   `"intervention_required"` or `"no_protocol"`.
#' @examples
#' # 68yo female, 105 kg, 160 cm, SCr 1.8, ordered cefepime 2 g q8h
#' screen_medications(68, 105, 160, 1.8, TRUE, "cefepime", "2g_q8h")
#' @export
screen_medications <- function(age_yrs, weight_kg, height_cm, scr_mgdl, sex_is_female,
                               drug_name, prescribed_regimen_id,
                               rules = renal_dose_rules) {
  assert_patient_inputs(age_yrs, weight_kg, height_cm, scr_mgdl, sex_is_female, drug_name)

  ibw  <- ideal_body_weight(height_cm, sex_is_female)
  dw   <- dosing_weight(weight_kg, ibw)
  crcl <- cockcroft_gault(age_yrs, dw, scr_mgdl, sex_is_female)
  recommended  <- recommend_regimen(drug_name, crcl, rules)
  weight_model <- if (weight_kg < ibw) "ABW" else if (weight_kg / ibw > 1.2) "AdjBW" else "IBW"

  # Compare regimen IDs, never free-text labels: display strings drift, codes don't.
  status <- if (is.na(recommended)) {
    "no_protocol"
  } else if (identical(prescribed_regimen_id, recommended)) {
    "approved"
  } else {
    "intervention_required"
  }

  list(
    weight_model        = weight_model,
    ibw_kg              = round(ibw, 1),
    dosing_weight_kg    = round(dw, 1),
    crcl_ml_min         = round(crcl, 1),
    drug                = drug_name,
    prescribed_regimen  = prescribed_regimen_id,
    recommended_regimen = recommended,
    recommended_label   = rules$regimen_label[match(recommended, rules$regimen_id)],
    status              = status
  )
}
