# ==============================================================================
# Procalcitonin (PCT) Stewardship Algorithm
#
# The single source of truth for PCT decision thresholds. The simulation, the
# heatmap and any future Shiny app read `pct_cutoffs` from here, so changing a
# threshold is a one-line edit instead of a hunt through three scripts.
#
# RESEARCH / EDUCATIONAL USE ONLY. Not a medical device.
# ==============================================================================

#' PCT decision cut-offs (ng/mL)
#'
#' Lower edges of the "unlikely", "possible" and "likely" bands described in
#' the README. Bands are left-closed: a value exactly on a cut-off belongs to
#' the higher band (0.5 ng/mL counts as "likely").
#'
#' @format A numeric vector of length 3: `c(0.1, 0.25, 0.5)`.
#' @export
pct_cutoffs <- c(0.1, 0.25, 0.5)

# Serial PCT values must be numeric, non-missing and non-negative.
assert_pct_series <- function(pct_series, min_length = 1L) {
  if (!is.numeric(pct_series) || length(pct_series) < min_length || anyNA(pct_series)) {
    stop(sprintf("`pct_series` needs >= %d non-missing numeric PCT value(s) (ng/mL).",
                 min_length), call. = FALSE)
  }
  if (any(pct_series < 0)) stop("PCT cannot be negative; check units/ETL.", call. = FALSE)
  invisible(pct_series)
}

#' Classify PCT values into README decision bands
#'
#' @param pct Numeric PCT values in ng/mL. `NA` is allowed and stays `NA`.
#' @return A factor with levels `"highly_unlikely"` (< 0.1), `"unlikely"`
#'   (0.1 to < 0.25), `"possible"` (0.25 to < 0.5) and `"likely"` (>= 0.5).
#' @examples
#' classify_pct(c(0.05, 0.1, 0.3, 0.5, 4))
#' @export
classify_pct <- function(pct) {
  if (!is.numeric(pct)) stop("`pct` must be numeric (ng/mL).", call. = FALSE)
  if (any(pct < 0, na.rm = TRUE)) stop("PCT cannot be negative; check units/ETL.", call. = FALSE)
  cut(pct, breaks = c(-Inf, pct_cutoffs, Inf), right = FALSE,
      labels = c("highly_unlikely", "unlikely", "possible", "likely"))
}

#' Running PCT decline from peak
#'
#' At each timepoint, the fractional drop from the highest value seen so far.
#'
#' @param pct_series Serial PCT values (ng/mL) in time order.
#' @return Numeric vector in `[0, 1]`, same length as `pct_series`.
#' @examples
#' pct_clearance(c(2.5, 1.8, 0.4, 0.15))
#' @export
pct_clearance <- function(pct_series) {
  assert_pct_series(pct_series)
  peak <- cummax(pct_series)
  ifelse(peak > 0, (peak - pct_series) / peak, 0)
}

# Stop rule shared by pct_decline_from_peak() and asp_recommendation().
pct_stop_signal <- function(pct_series, stop_drop, abs_stop) {
  pct_clearance(pct_series) >= stop_drop | pct_series < abs_stop
}

#' Evaluate the 80% decline-from-peak stop rule
#'
#' The stop signal fires when PCT has fallen by at least `stop_drop` from its
#' peak, or when the latest value is below `abs_stop`.
#'
#' @param pct_series Serial PCT values (ng/mL) in time order; at least two.
#' @param stop_drop Fractional decline from peak that signals stopping.
#' @param abs_stop Absolute PCT (ng/mL) below which stopping is signalled
#'   regardless of decline. Defaults to the "unlikely" upper edge (0.25). Set
#'   to `0` to rely on the decline rule alone.
#' @return A list with `peak`, `current`, `decline_fraction`, `category` and
#'   `stop_signal`.
#' @examples
#' pct_decline_from_peak(c(2.5, 1.8, 0.4, 0.15, 0.08))$stop_signal  # TRUE
#' pct_decline_from_peak(c(2.5, 2.7, 2.4, 2.6))$stop_signal         # FALSE
#' @export
pct_decline_from_peak <- function(pct_series, stop_drop = 0.80, abs_stop = pct_cutoffs[[2]]) {
  assert_pct_series(pct_series, min_length = 2L)
  n <- length(pct_series)
  list(
    peak             = max(pct_series),
    current          = pct_series[[n]],
    decline_fraction = pct_clearance(pct_series)[[n]],
    category         = as.character(classify_pct(pct_series[[n]])),
    stop_signal      = pct_stop_signal(pct_series, stop_drop, abs_stop)[[n]]
  )
}

#' Stewardship recommendation at each PCT timepoint
#'
#' Applies the stop rule first; otherwise a value in the "possible" band
#' (0.25 to < 0.5 ng/mL, clinical discretion) is flagged for de-escalation
#' review, and anything higher means continue.
#'
#' @inheritParams pct_decline_from_peak
#' @param pct_series Serial PCT values (ng/mL) in time order; one or more.
#' @return Character vector of `"Continue"`, `"De-escalate"` or
#'   `"Discontinue"`, same length as `pct_series`.
#' @examples
#' asp_recommendation(c(2.5, 1.8, 0.4, 0.15))
#' @export
asp_recommendation <- function(pct_series, stop_drop = 0.80, abs_stop = pct_cutoffs[[2]]) {
  assert_pct_series(pct_series)
  stop_now <- pct_stop_signal(pct_series, stop_drop, abs_stop)
  category <- classify_pct(pct_series)
  ifelse(stop_now, "Discontinue", ifelse(category == "possible", "De-escalate", "Continue"))
}
