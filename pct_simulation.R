# 🧪 Procalcitonin (PCT) Stewardship Simulation Script
# This script simulates patient PCT kinetic clearance curves over a 7-day stay.

# Load required libraries for plotting
library(ggplot2)

# 1. Create mock data for two patient scenarios
days <- 0:7

# Scenario A: Responding Patient (PCT drops by >80%)
pct_responder <- c(2.5, 1.8, 0.4, 0.15, 0.08, 0.05, 0.05, 0.05)

# Scenario B: Non-Responding Patient (Treatment Failure/Stable High PCT)
pct_non_responder <- c(2.5, 2.7, 2.4, 2.6, 2.3, 2.5, 2.2, 2.4)

# Combine into a clean data frame
data_responder <- data.frame(Day = days, PCT = pct_responder, Group = "Responding Patient (>80% Drop)")
data_non_responder <- data.frame(Day = days, PCT = pct_non_responder, Group = "Non-Responding Patient (Failure)")
plot_data <- rbind(data_responder, data_non_responder)

# 2. Generate the clinical clearance plot
ggplot(plot_data, aes(x = Day, y = PCT, color = Group, group = Group)) +
  geom_line(size = 1.2) +
  geom_point(size = 3) +
  scale_color_manual(values = c("red", "green4")) +
  labs(title = "Simulated Patient Procalcitonin (PCT) Kinetics Over 7 Days",
       x = "Hospital Admission (Days)",
       y = "Serum PCT Concentration (ng/mL)") +
  theme_minimal() +
  geom_hline(yintercept = 0.5, linetype = "dashed", color = "orange") +
  annotate("text", x = 6, y = 0.6, label = "De-escalation Threshold (0.5 ng/mL)", color = "orange")
