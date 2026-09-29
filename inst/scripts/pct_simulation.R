# Simulating Procalcitonin (PCT) kinetics over a standard 7-day antibiotic course.
# Built this to visualize the clinical decision-making process for stopping empiric Abx.
#
# Install the package first (see README), then from the repo root:
#   Rscript inst/scripts/pct_simulation.R
# The figure is written to output/ (git-ignored).

library(pctsteward)

kinetics <- pct_kinetics_example()

# Print the algorithm's verdict for each patient alongside the figure.
for (patient in unique(kinetics$Patient)) {
  verdict <- pct_decline_from_peak(kinetics$PCT[kinetics$Patient == patient])
  cat(sprintf("%s: %.0f%% decline from peak, stop signal = %s\n",
              patient, 100 * verdict$decline_fraction, verdict$stop_signal))
}

dir.create("output", showWarnings = FALSE)
ggplot2::ggsave("output/pct_kinetics.png", plot_pct_kinetics(kinetics),
                width = 9, height = 5, dpi = 150)
cat("Saved output/pct_kinetics.png\n")
