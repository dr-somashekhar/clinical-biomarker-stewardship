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
#' Buckets admission PCT and baseline SOFA into clinical bands and colours each
#' cell by observed 30-day mortality.
#'
#' Input is long format (one row per patient per `Time_Hour`, see
#' `DATA_DICTIONARY.md`). Only the admission row (`Time_Hour == 0`) of each
#' patient is used, so every patient is counted once. PCT bands follow
#' [pct_cutoffs], with an extra 2 ng/mL band for severity. Every band
#' combination is drawn, empty ones included, and each tile shows its `n`.
#' Cells with fewer than `min_cell_n` patients show no percentage: small cells
#' give unstable estimates and can re-identify individuals.
#'
#' @param clinical_data Data frame with columns `Patient_ID`, `Time_Hour`,
#'   `PCT_Level`, `Baseline_SOFA` and `Mortality_30D`.
#' @param min_cell_n Minimum patients per cell before its mortality is shown.
#' @return A ggplot object. A placeholder plot is returned when
#'   `clinical_data` is `NULL` or empty, so the app doesn't crash on load.
#' @examples
#' build_stewardship_heatmap(simulate_cohort(n = 300, seed = 2026))
#' @importFrom rlang .data
#' @export
build_stewardship_heatmap <- function(clinical_data, min_cell_n = 5L) {

  # Quick sanity check -- if the dataframe hasn't loaded yet, don't crash the app!
  if (is.null(clinical_data) || nrow(clinical_data) == 0L) {
    return(ggplot2::ggplot() + ggplot2::theme_void() +
             ggplot2::ggtitle("Waiting for patient data..."))
  }
  cells <- heatmap_cells(clinical_data, min_cell_n)

  ggplot2::ggplot(cells, ggplot2::aes(x = .data$pct_bucket, y = .data$sofa_bucket,
                                      fill = .data$risk_pct)) +
    ggplot2::geom_tile(color = "white", linewidth = 1) +

    # Adding the hard numbers right on the tiles so no one has to guess the color shade
    ggplot2::geom_text(ggplot2::aes(label = .data$label), size = 3.5, fontface = "bold") +

    # Sequential light-to-dark red: readable with red-green colour blindness
    ggplot2::scale_fill_distiller(palette = "OrRd", direction = 1, limits = c(0, 100),
                                  na.value = "grey90", name = "30-day mortality (%)") +
    ggplot2::labs(
      title    = "Clinical Triage: Admission PCT vs. Baseline SOFA",
      subtitle = sprintf("One row per patient (Time_Hour = 0); cells with n < %d suppressed",
                         min_cell_n),
      x = "Admission PCT (ng/mL)",
      y = "Baseline SOFA"
    ) +

    # Stripping out the background grid for a cleaner dashboard look
    ggplot2::theme_minimal() +
    ggplot2::theme(
      panel.grid = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(face = "bold", size = 15)
    )
}

# One row per PCT band x SOFA band, with n, deaths, risk_pct (NA when
# suppressed) and the tile label. Kept separate from the plot so the numbers
# can be tested without reaching into ggplot internals.
heatmap_cells <- function(clinical_data, min_cell_n) {
  required <- c("Patient_ID", "Time_Hour", "PCT_Level", "Baseline_SOFA", "Mortality_30D")
  missing_cols <- setdiff(required, names(clinical_data))
  if (length(missing_cols) > 0L) {
    stop("Missing required column(s): ", paste(missing_cols, collapse = ", "), call. = FALSE)
  }
  if (any(clinical_data$PCT_Level < 0, na.rm = TRUE)) {
    stop("Negative PCT values found; check units/ETL.", call. = FALSE)
  }

  # Squishing admission PCT and SOFA into clinical buckets, one row per patient.
  # This makes the heatmap look like an actionable grid instead of a messy scatterplot.
  clinical_data |>
    dplyr::filter(.data$Time_Hour == 0) |>
    dplyr::distinct(.data$Patient_ID, .keep_all = TRUE) |>
    dplyr::mutate(
      pct_bucket = cut(.data$PCT_Level, breaks = c(0, pct_cutoffs, 2, Inf), right = FALSE,
                       labels = c("<0.1", "0.1-<0.25", "0.25-<0.5", "0.5-<2", ">=2")),
      sofa_bucket = cut(.data$Baseline_SOFA, breaks = c(0, 4, 7, 10, 25), right = FALSE,
                        labels = c("0-3", "4-6", "7-9", "10-24"))
    ) |>
    dplyr::filter(!is.na(.data$pct_bucket), !is.na(.data$sofa_bucket),
                  !is.na(.data$Mortality_30D)) |>
    dplyr::group_by(.data$sofa_bucket, .data$pct_bucket, .drop = FALSE) |>
    dplyr::summarise(n = dplyr::n(), deaths = sum(.data$Mortality_30D), .groups = "drop") |>
    dplyr::mutate(
      risk_pct = dplyr::if_else(.data$n >= min_cell_n, 100 * .data$deaths / .data$n, NA_real_),
      label    = dplyr::if_else(is.na(.data$risk_pct),
                                paste0("n=", .data$n, "\n(suppressed)"),
                                sprintf("%.1f%%\nn=%d", .data$risk_pct, .data$n))
    )
}
