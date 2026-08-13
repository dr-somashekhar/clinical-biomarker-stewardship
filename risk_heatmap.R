# ==============================================================================
# 🌡️ Sepsis & Biomarker Risk Heatmap Module
#
# Personal Note:
# During my time managing clinical trials and teaching pharmacotherapeutics, 
# I noticed students and clinicians alike struggle to mentally cross-reference 
# multiple lab values at once on the ward. I designed this heatmap to bridge 
# that gap—turning raw Procalcitonin and SOFA scores into an instant visual 
# triage tool for antibiotic stewardship.
#
# Architecture Note:
# I moved this specific plotting logic out of the main app.R file. Keeping the 
# UI and Server components separated into different scripts makes debugging 
# so much easier and keeps the main server block from getting cluttered.
# ==============================================================================

library(ggplot2)
library(dplyr)

# Wrapping this in a function so it can be cleanly sourced by the Shiny server
build_stewardship_heatmap <- function(clinical_data) {
  
  # Quick sanity check—if the dataframe hasn't loaded yet, don't crash the app!
  if(is.null(clinical_data) || nrow(clinical_data) == 0) {
    return(ggplot() + theme_void() + ggtitle("Waiting for patient data..."))
  }

  # Squishing the continuous PCT and SOFA scores into clinical buckets.
  # This makes the heatmap look like an actionable grid instead of a messy scatterplot.
  plot_ready_data <- clinical_data %>%
    mutate(
      pct_bucket = cut(PCT_Level, breaks = c(0, 0.25, 0.5, 2.0, 10, Inf), 
                       labels = c("Normal", "Mild", "Moderate", "High", "Critical")),
                       
      sofa_bucket = cut(Baseline_SOFA, breaks = c(-1, 3, 6, 9, Inf),
                        labels = c("Low (0-3)", "Mod (4-6)", "Severe (7-9)", "Critical (10+)"))
    ) %>%
    group_by(sofa_bucket, pct_bucket) %>%
    
    # Calculating the actual risk score for the color gradient
    summarise(patient_count = n(), risk_score = mean(Mortality_30D) * 100, .groups = "drop")
  
  
  # Building the actual visualization. 
  # I'm sticking to a classic traffic-light color scheme because it's universally 
  # understood by medical staff during rounds.
  risk_viz <- ggplot(plot_ready_data, aes(x = pct_bucket, y = sofa_bucket, fill = risk_score)) +
    geom_tile(color = "white", linewidth = 1) +
    
    # Light green for safe, dark red for high mortality risk
    scale_fill_gradient(low = "#e5f5e0", high = "#de2d26", name = "Mortality Risk (%)") +
    
    # Adding the hard numbers right on the tiles so no one has to guess the color shade
    geom_text(aes(label = paste0(round(risk_score, 1), "%")), 
              size = 4, color = "black", fontface = "bold") +
              
    labs(
      title = "Clinical Triage: PCT vs. SOFA Risk Matrix",
      subtitle = "Instantly highlights high-risk patients needing aggressive de-escalation review",
      x = "Procalcitonin (PCT) Range",
      y = "SOFA Score Bucket"
    ) +
    
    # Stripping out the background grid for a cleaner dashboard look
    theme_minimal() +
    theme(
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      plot.title = element_text(face = "bold", size = 15)
    )
    
  return(risk_viz)
}
