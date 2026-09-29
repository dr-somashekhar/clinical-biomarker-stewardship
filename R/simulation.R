# ==============================================================================
# Procalcitonin (PCT) Kinetics Plot
#
# Built this to visualize the clinical decision-making process for stopping
# empiric Abx. Each patient's curve is coloured by whether the stop rule in
# pct_decline_from_peak() is met, so the legend reflects the algorithm rather
# than a hand-written label.
# ==============================================================================

#' Example PCT kinetics over a standard 7-day antibiotic course
#'
#' Two illustrative patients sampled daily on days 0-7:
#' * Patient A, a responder: PCT halves fairly quickly after proper source
#'   control and adequate empiric coverage.
#' * Patient B, a non-responder: a resistant organism or lack of source
#'   control is suspected, and PCT stays persistently elevated.
#'
#' @return Data frame with columns `Patient`, `Day`, `PCT` (ng/mL).
#' @export
pct_kinetics_example <- function() {
  data.frame(
    Patient = rep(c("Patient A", "Patient B"), each = 8),
    Day     = rep(0:7, times = 2),
    PCT     = c(2.5, 1.8, 0.4, 0.15, 0.08, 0.05, 0.05, 0.05,
                2.5, 2.7, 2.4, 2.6, 2.3, 2.5, 2.2, 2.4),
    stringsAsFactors = FALSE
  )
}

#' Plot PCT clearance curves coloured by the stop rule
#'
#' @param kinetics Data frame with columns `Patient`, `Day` and `PCT` (ng/mL).
#'   Defaults to [pct_kinetics_example()].
#' @inheritParams pct_decline_from_peak
#' @return A ggplot object.
#' @examples
#' plot_pct_kinetics()
#' @importFrom rlang .data
#' @export
plot_pct_kinetics <- function(kinetics = pct_kinetics_example(), stop_drop = 0.80,
                              abs_stop = pct_cutoffs[[2]]) {
  kinetics <- label_stop_outcome(kinetics, stop_drop, abs_stop)

  # Named Okabe-Ito colours: colour-blind safe, and not dependent on factor order.
  outcome_cols <- stats::setNames(c("#0072B2", "#D55E00"), stop_outcome_levels)
  likely_cutoff <- pct_cutoffs[[3]]

  ggplot2::ggplot(kinetics, ggplot2::aes(x = .data$Day, y = .data$PCT,
                                         color = .data$Outcome, group = .data$Patient)) +
    ggplot2::geom_line(linewidth = 1.2) +
    ggplot2::geom_point(size = 3) +
    ggplot2::scale_color_manual(values = outcome_cols, drop = FALSE) +
    # I always like using dashed h-lines for clinical thresholds so they pop out
    # during ward rounds.
    ggplot2::geom_hline(yintercept = likely_cutoff, linetype = "dashed", color = "grey40") +
    ggplot2::annotate("text", x = max(kinetics$Day) - 1.5, y = likely_cutoff * 1.3,
                      label = sprintf("Bacterial infection likely (>= %s ng/mL)", likely_cutoff),
                      color = "grey30") +
    ggplot2::labs(
      title = "Procalcitonin (PCT) Kinetics: Stewardship De-escalation Model",
      subtitle = sprintf("Stop rule: >= %.0f%% decline from peak or PCT < %s ng/mL",
                         100 * stop_drop, abs_stop),
      x = "Day of Antibiotic Therapy",
      y = "Serum PCT (ng/mL)",
      color = NULL
    ) +
    ggplot2::theme_minimal()
}

stop_outcome_levels <- c("Stop rule met", "Stop rule not met")

# Sorts by patient and day and adds an `Outcome` factor saying whether each
# patient's series meets the stop rule. Kept separate from the plot so it can
# be tested without reaching into ggplot internals.
label_stop_outcome <- function(kinetics, stop_drop, abs_stop) {
  missing_cols <- setdiff(c("Patient", "Day", "PCT"), names(kinetics))
  if (length(missing_cols) > 0L) {
    stop("Missing required column(s): ", paste(missing_cols, collapse = ", "), call. = FALSE)
  }
  kinetics <- kinetics[order(kinetics$Patient, kinetics$Day), , drop = FALSE]
  stop_met <- vapply(split(kinetics$PCT, kinetics$Patient),
                     function(p) pct_decline_from_peak(p, stop_drop, abs_stop)$stop_signal,
                     logical(1))
  kinetics$Outcome <- factor(ifelse(stop_met[kinetics$Patient],
                                    stop_outcome_levels[[1]], stop_outcome_levels[[2]]),
                             levels = stop_outcome_levels)
  kinetics
}
