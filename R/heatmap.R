# ==============================================================================
# Sepsis & Biomarker Risk Heatmap Module
#
# Personal Note:
# During my time managing clinical trials and teaching pharmacotherapeutics,
# I noticed students and clinicians alike struggle to mentally cross-reference
# multiple lab values at once on the ward. I designed this heatmap to bridge
# that gap -- turning raw Procalcitonin and SOFA scores into an instant visual
# triage tool for antibiotic stewardship.
#
# Kept as a standalone function so a future Shiny server can call it without
# the plotting logic cluttering the main server block.
# ==============================================================================

#' PCT vs. SOFA mortality risk heatmap
#'
#' Buckets continuous PCT and SOFA scores into clinical bands and colours each
#' cell by mean 30-day mortality, using a traffic-light scheme familiar to
#' ward staff.
#'
#' @param clinical_data Data frame with columns `PCT_Level`, `Baseline_SOFA`
#'   and `Mortality_30D` (see `DATA_DICTIONARY.md`).
#' @return A ggplot object. A placeholder plot is returned when
#'   `clinical_data` is `NULL` or empty, so the app doesn't crash on load.
#' @importFrom rlang .data
#' @export
build_stewardship_heatmap <- function(clinical_data) {

  # Quick sanity check -- if the dataframe hasn't loaded yet, don't crash the app!
  if (is.null(clinical_data) || nrow(clinical_data) == 0) {
    return(ggplot2::ggplot() + ggplot2::theme_void() +
             ggplot2::ggtitle("Waiting for patient data..."))
  }

  # Squishing the continuous PCT and SOFA scores into clinical buckets.
  # This makes the heatmap look like an actionable grid instead of a messy scatterplot.
  plot_ready_data <- clinical_data |>
    dplyr::mutate(
      pct_bucket = cut(.data$PCT_Level, breaks = c(0, 0.25, 0.5, 2.0, 10, Inf),
                       labels = c("Normal", "Mild", "Moderate", "High", "Critical")),
      sofa_bucket = cut(.data$Baseline_SOFA, breaks = c(-1, 3, 6, 9, Inf),
                        labels = c("Low (0-3)", "Mod (4-6)", "Severe (7-9)", "Critical (10+)"))
    ) |>
    dplyr::group_by(.data$sofa_bucket, .data$pct_bucket) |>
    # Calculating the actual risk score for the color gradient
    dplyr::summarise(patient_count = dplyr::n(),
                     risk_score = mean(.data$Mortality_30D) * 100,
                     .groups = "drop")

  ggplot2::ggplot(plot_ready_data,
                  ggplot2::aes(x = .data$pct_bucket, y = .data$sofa_bucket,
                               fill = .data$risk_score)) +
    ggplot2::geom_tile(color = "white", linewidth = 1) +

    # Light green for safe, dark red for high mortality risk
    ggplot2::scale_fill_gradient(low = "#e5f5e0", high = "#de2d26", name = "Mortality Risk (%)") +

    # Adding the hard numbers right on the tiles so no one has to guess the color shade
    ggplot2::geom_text(ggplot2::aes(label = paste0(round(.data$risk_score, 1), "%")),
                       size = 4, color = "black", fontface = "bold") +

    ggplot2::labs(
      title = "Clinical Triage: PCT vs. SOFA Risk Matrix",
      subtitle = "Instantly highlights high-risk patients needing aggressive de-escalation review",
      x = "Procalcitonin (PCT) Range",
      y = "SOFA Score Bucket"
    ) +

    # Stripping out the background grid for a cleaner dashboard look
    ggplot2::theme_minimal() +
    ggplot2::theme(
      panel.grid.major = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(face = "bold", size = 15)
    )
}
