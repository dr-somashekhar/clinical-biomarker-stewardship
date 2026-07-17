# 📊 Clinical Drug Risk Mapping Matrix Generator
# Based on the 2026 reference guide for renal dose adjustments.

# Load required libraries
library(ggplot2)

# 1. Construct the clinical risk dataset
risk_data <- data.frame(
  Drug = factor(c("NSAIDs\n(Ibuprofen/Diclofenac)", "NSAIDs\n(Ibuprofen/Diclofenac)", "NSAIDs\n(Ibuprofen/Diclofenac)", "NSAIDs\n(Ibuprofen/Diclofenac)",
                  "Dabigatran\n(DOAC)", "Dabigatran\n(DOAC)", "Dabigatran\n(DOAC)", "Dabigatran\n(DOAC)",
                  "Apixaban\n(DOAC)", "Apixaban\n(DOAC)", "Apixaban\n(DOAC)", "Apixaban\n(DOAC)",
                  "Metformin\n(Antidiabetic)", "Metformin\n(Antidiabetic)", "Metformin\n(Antidiabetic)", "Metformin\n(Antidiabetic)"),
                levels = c("Metformin\n(Antidiabetic)", "Apixaban\n(DOAC)", "Dabigatran\n(DOAC)", "NSAIDs\n(Ibuprofen/Diclofenac)")),
  
  Renal_Tier = factor(c("Tier 1: eGFR >=60", "Tier 2: eGFR 30-59", "Tier 3: eGFR 15-29", "Tier 4: eGFR <15 / HD",
                        "Tier 1: eGFR >=60", "Tier 2: eGFR 30-59", "Tier 3: eGFR 15-29", "Tier 4: eGFR <15 / HD",
                        "Tier 1: eGFR >=60", "Tier 2: eGFR 30-59", "Tier 3: eGFR 15-29", "Tier 4: eGFR <15 / HD",
                        "Tier 1: eGFR >=60", "Tier 2: eGFR 30-59", "Tier 3: eGFR 15-29", "Tier 4: eGFR <15 / HD"),
                      levels = c("Tier 1: eGFR >=60", "Tier 2: eGFR 30-59", "Tier 3: eGFR 15-29", "Tier 4: eGFR <15 / HD")),
  
  Risk_Level = factor(c("Caution", "High Risk", "Contraindicated", "Contraindicated",
                        "Safe", "Dose Adjusted", "Contraindicated", "Contraindicated",
                        "Safe", "Safe", "Dose Adjusted", "Caution"),
                      levels = c("Safe", "Dose Adjusted", "Caution", "High Risk", "Contraindicated"))
)

# 2. Build the interactive heatmap plot
ggplot(risk_data, aes(x = Renal_Tier, y = Drug, fill = Risk_Level)) +
  geom_tile(color = "white", size = 0.5) +
  scale_fill_manual(values = c("Safe" = "green4", 
                               "Dose Adjusted" = "yellow", 
                               "Caution" = "orange", 
                               "High Risk" = "darkorange2", 
                               "Contraindicated" = "red")) +
  labs(title = "Medication Safety Risk Matrix Across Renal Function Tiers",
       subtitle = "Clinical Reference Framework (2026)",
       x = "Renal Function Tiers (eGFR mL/min/1.73m²)",
       y = "High-Alert Medication Class",
       fill = "Risk Stratification") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 15, hjust = 1),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank())
