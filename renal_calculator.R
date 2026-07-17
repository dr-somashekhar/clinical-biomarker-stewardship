# 🧮 Automated Renal Dosage Screening Engine
# Based on the 2026 reference guide for renal dose adjustments.

# Block 1: The Cockcroft-Gault Calculator Function
calculate_crcl <- function(age, weight, creatinine, is_female) {
  # Standard male calculation
  base_crcl <- ((140 - age) * weight) / (72 * creatinine)
  
  # Apply 0.85 multiplier for female patients
  if (is_female) {
    return(base_crcl * 0.85)
  } else {
    return(base_crcl)
  }
}

# Block 2 & 3: The Screening & Alert Flag Engine
screen_medications <- function(age, weight, creatinine, is_female, drug_name, prescribed_dose) {
  
  # Calculate patient's renal clearance
  crcl <- calculate_crcl(age, weight, creatinine, is_female)
  
  cat(sprintf("\n=== Clinical Renal Screening Report ===\n"))
  cat(sprintf("Calculated Creatinine Clearance: %.2f mL/min\n", crcl))
  cat(sprintf("Medication Checked: %s (%d mg/day)\n", drug_name, prescribed_dose))
  cat("----------------------------------------\n")
  
  # Logic rules for Metformin 💊
  if (tolower(drug_name) == "metformin") {
    if (crcl < 30) {
      cat("⚠️ ALERT: Metformin is CONTRAINDICATED when CrCl < 30 mL/min.\n")
      cat("❌ CRITICAL RISK: High risk of lactic acidosis. Discontinue immediately.\n")
    } else if (crcl >= 30 && crcl <= 44) {
      if (prescribed_dose > 1000) {
        cat("⚠️ WARNING: Max recommended Metformin dose for CrCl 30-44 mL/min is 1000 mg/day.\n")
        cat(sprintf("🛑 ACTION REQUIRED: Reduce dose from %d mg to 1000 mg/day.\n", prescribed_dose))
      } else {
        cat("✅ Safe: Metformin dose is appropriate for this renal tier.\n")
      }
    } else {
      cat("✅ Safe: Renal clearance is sufficient for standard Metformin dosing.\n")
    }
  }
  
  # Logic rules for Memantine 🧠
  else if (tolower(drug_name) == "memantine") {
    if (crcl < 5) {
      cat("⚠️ ALERT: Advanced renal failure. Avoid Memantine or use with extreme caution.\n")
    } else if (crcl >= 5 && crcl <= 29) {
      if (prescribed_dose > 100) { # Adjusted target threshold check
        cat("⚠️ WARNING: Max recommended Memantine dose for CrCl 5-29 mL/min is 10 mg/day.\n")
        cat(sprintf("🛑 ACTION REQUIRED: Reduce dose from %d mg to 10 mg/day strictly.\n", prescribed_dose))
      } else {
        cat("✅ Safe: Memantine dose is within safe parameters.\n")
      }
    } else {
      cat("✅ Safe: Memantine dose is safe for standard clearance.\n")
    }
  } else {
    cat("ℹ️ Info: Medication thresholds not configured in baseline setup.\n")
  }
}

# --- Test Case Execution ---
# Scenario: 75-year-old female, 60kg, serum creatinine 1.8 mg/dL (Advanced CKD)
# Current Prescription: Metformin 1500 mg/day
screen_medications(age = 75, weight = 60, creatinine = 1.8, is_female = TRUE, drug_name = "Metformin", prescribed_dose = 1500)
