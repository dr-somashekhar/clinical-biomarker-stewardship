# Simulating Procalcitonin (PCT) kinetics over a standard 7-day antibiotic course.
# Built this to visualize the clinical decision-making process for stopping empiric Abx.

library(ggplot2)

# Tracking days 0 to 7 (8 timepoints total). 
# Note: Ensure the PCT arrays match this length exactly to avoid dataframe binding errors!
tx_days <- 0:7 

# Patient A: Responding well to therapy. 
# PCT halves fairly quickly after proper source control and adequate empiric coverage.
pct_lvl_improving <- c(2.5, 1.8, 0.4, 0.15, 0.08, 0.05, 0.05, 0.05)

# Patient B: Non-responder. 
# Suspecting a resistant bug or lack of source control. PCT stays persistently elevated.
pct_lvl_failing <- c(2.5, 2.7, 2.4, 2.6, 2.3, 2.5, 2.2, 2.4)

# Squishing it together into data frames for ggplot mapping
df_clin_improving <- data.frame(Day = tx_days, PCT = pct_lvl_improving, Cohort = "Responsive (>80% Clearance)")
df_clin_failing   <- data.frame(Day = tx_days, PCT = pct_lvl_failing, Cohort = "Refractory (Stable/High)")

combined_pct_kinetics <- rbind(df_clin_improving, df_clin_failing)

# Visualizing the clearance curves.
# I always like using dashed h-lines for clinical thresholds so they pop out during ward rounds.
ggplot(combined_pct_kinetics, aes(x = Day, y = PCT, color = Cohort, group = Cohort)) +
  geom_line(size = 1.2) +
  geom_point(size = 3) +
  scale_color_manual(values = c("red", "green4")) +
  labs(title = "Procalcitonin (PCT) Kinetics: Stewardship De-escalation Model",
       x = "Days Post-Admission",
       y = "Serum PCT (ng/mL)") +
  theme_minimal() +
  
  # Clinical Note: 0.5 ng/mL is standard for lower RTI de-escalation (CAP/VAP), 
  # though some aggressive protocols push for 0.25 ng/mL. Sticking with 0.5 here.
  geom_hline(yintercept = 0.5, linetype = "dashed", color = "orange") +
  annotate("text", x = 5.5, y = 0.65, label = "De-escalation Threshold (0.5 ng/mL)", color = "orange")
