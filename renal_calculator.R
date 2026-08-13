# =========================================================================================
# 🧮 Clinical Pharmacokinetics: Renal Dosing Calculator
# 
# I wrote this script because relying on raw Actual Body Weight (ABW) in the standard 
# Cockcroft-Gault equation often leads to supratherapeutic dosing and toxicity in 
# obese patients. This function dynamically calculates Ideal Body Weight (IBW) and 
# Adjusted Body Weight (AdjBW) based on standard clinical pharmacy protocols before 
# estimating clearance.
# =========================================================================================

screen_medications <- function(age_yrs, weight_kg, height_cm, scr_mgdl, sex_is_female, drug_name, prescribed_dose) {
  
  # --- 1. EHR Input Validation ---
  # Catching bad EHR data before it breaks the math. You'd be surprised how often 
  # a patient's height is entered as 15 cm instead of 150 cm in the real world.
  if (age_yrs < 18) stop("Clinical Error: Calculator validated for adults (18+) only. Use Schwartz equation for peds.")
  if (weight_kg <= 20 | height_cm <= 100) stop("Data Error: Weight and height values seem clinically impossible. Check inputs.")
  if (scr_mgdl < 0.1) stop("Data Error: Serum creatinine seems artificially low. Watch out for rounding errors.")
  if (is.null(drug_name) | drug_name == "") stop("Script Error: Missing drug name parameter.")
  
  # --- 2. Anthropometric Calculations (Devine Formula) ---
  # Convert cm to inches for the standard Devine IBW formula
  ht_inches <- height_cm / 2.54 
  inches_over_60 <- ifelse(ht_inches > 60, ht_inches - 60, 0)
  
  # Base IBW calculation
  ibw_base <- ifelse(sex_is_female, 45.5, 50.0)
  ibw_kg <- ibw_base + (2.3 * inches_over_60)
  
  # --- 3. Dosing Weight Logic ---
  # If the patient is >20% over their IBW, ABW overestimates clearance, so we use AdjBW.
  # If they are cachectic/underweight (ABW < IBW), we just use ABW to avoid overdosing.
  wgt_ratio <- weight_kg / ibw_kg
  
  if (weight_kg < ibw_kg) {
    dosing_wgt <- weight_kg
    wgt_type_used <- "Actual Body Weight (Patient is Underweight)"
    
  } else if (wgt_ratio > 1.20) {
    # Standard AdjBW formula with a 0.4 correction factor
    dosing_wgt <- ibw_kg + 0.4 * (weight_kg - ibw_kg)
    wgt_type_used <- "Adjusted Body Weight (Obese: >20% over IBW)"
    
  } else {
    dosing_wgt <- ibw_kg
    wgt_type_used <- "Ideal Body Weight (Within normal limits)"
  }
  
  # --- 4. Cockcroft-Gault Clearance Calculation ---
  # The classic 1976 equation. Still the FDA gold standard for drug labeling!
  crcl_raw <- ((140 - age_yrs) * dosing_wgt) / (72 * scr_mgdl)
  crcl_final <- ifelse(sex_is_female, crcl_raw * 0.85, crcl_raw)
  
  # --- 5. Pharmacotherapy Stewardship Logic ---
  # Using Cefepime as the primary test case here since it's notorious for causing 
  # neurotoxicity/encephalopathy if it accumulates in renal failure.
  
  clinical_flag <- "Unreviewed"
  rec_dose <- "Consult clinical pharmacist."
  drug_target <- tolower(drug_name)
  
  if (drug_target == "cefepime") {
    
    # Stratifying by renal function breakpoints
    if (crcl_final >= 50) {
      rec_dose <- "2g IV q8h (Standard Empiric)"
    } else if (crcl_final >= 11 & crcl_final < 50) {
      rec_dose <- "2g IV q12h OR 1g IV q8h (Moderate Impairment)"
    } else {
      rec_dose <- "1g IV q24h (Severe Impairment)"
    }
    
    # Final Stewardship Check against what the physician ordered
    if (tolower(prescribed_dose) == tolower(rec_dose)) {
      clinical_flag <- "✅ Approved: Dose matches renal clearance."
    } else {
      clinical_flag <- "⚠️ INTERVENTION REQUIRED: Potential Toxicity or Under-dosing."
    }
    
  } else {
    clinical_flag <- paste("No stewardship protocol built for", drug_name, "yet.")
  }
  
  # --- 6. Structured Data Return ---
  # Returning a clean, structured list rather than just printing text to the console. 
  # This makes it infinitely easier to plug this script into a Shiny Dashboard later.
  
  results_payload <- list(
    Patient_Age = age_yrs,
    SCr_mg_dL = scr_mgdl,
    Weight_Model_Used = wgt_type_used,
    Calculated_Dosing_Weight = round(dosing_wgt, 1),
    Estimated_CrCl_mL_min = round(crcl_final, 1),
    Target_Drug = drug_name,
    Physician_Order = prescribed_dose,
    Guideline_Recommendation = rec_dose,
    Stewardship_Action = clinical_flag
  )
  
  return(results_payload)
}

# -----------------------------------------------------------------------------------------
# Test Case (Uncomment to run): 
# 68yo Female, 105kg, 160cm tall, SCr 1.8. Ordered: Cefepime 2g q8h.
# -----------------------------------------------------------------------------------------
# test_patient <- screen_medications(age_yrs = 68, weight_kg = 105, height_cm = 160, 
#                                    scr_mgdl = 1.8, sex_is_female = TRUE, 
#                                    drug_name = "Cefepime", prescribed_dose = "2g IV q8h")
# print(test_patient)
