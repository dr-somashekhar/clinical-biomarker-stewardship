# ==============================================================================
# Synthetic Cohort Generator
#
# Produces a long-format dataset matching DATA_DICTIONARY.md so the heatmap,
# tests and teaching material never need real patient data. All effect sizes
# are illustrative, chosen to give clinically plausible shapes, and are NOT
# estimates from any real population.
# ==============================================================================

#' Simulate a synthetic stewardship cohort
#'
#' One row per patient per `Time_Hour` (0, 24, 48, 72). Responders' PCT decays
#' with an 18-36 h half-life; non-responders stay near baseline. Sicker
#' (higher-SOFA) patients are less likely to respond. `PCT_Clearance` and
#' `ASP_Recommendation` are computed with [pct_clearance()] and
#' [asp_recommendation()], and `Abx_Duration` is the day of the first
#' "Discontinue" recommendation (7 days if never reached).
#'
#' @param n Number of patients.
#' @param seed Optional RNG seed for reproducibility. Note that this calls
#'   [set.seed()] and so changes the global RNG state.
#' @return A data frame with the columns described in `DATA_DICTIONARY.md`.
#' @examples
#' cohort <- simulate_cohort(n = 50, seed = 2026)
#' head(cohort)
#' @importFrom stats plogis rbinom rgamma rlnorm rnorm rpois runif
#' @export
simulate_cohort <- function(n = 200L, seed = NULL) {
  if (!is.numeric(n) || length(n) != 1L || is.na(n) || n < 1) {
    stop("`n` must be a single positive number.", call. = FALSE)
  }
  n <- as.integer(n)
  if (!is.null(seed)) set.seed(seed)
  hours <- c(0, 24, 48, 72)
  n_t   <- length(hours)

  # --- Patient-level baseline ---
  infection_source <- sample(c("CAP", "VAP", "Sepsis_Unknown"), n, replace = TRUE,
                             prob = c(0.5, 0.2, 0.3))
  ward <- ifelse(infection_source == "VAP", "ICU",
                 sample(c("ICU", "General_Medicine"), n, replace = TRUE, prob = c(0.3, 0.7)))
  sofa <- pmin(24L, rpois(n, ifelse(ward == "ICU", 8, 3)))
  empiric_abx <- ifelse(ward == "ICU",
                        sample(c("Meropenem", "Pip-Tazo"), n, replace = TRUE, prob = c(0.6, 0.4)),
                        sample(c("Pip-Tazo", "Meropenem"), n, replace = TRUE, prob = c(0.8, 0.2)))

  # --- PCT kinetics (patients x timepoints) ---
  baseline_pct <- rlnorm(n, meanlog = log(ifelse(ward == "ICU", 2, 0.4)), sdlog = 1.2)
  responder    <- runif(n) < plogis(2 - 0.25 * sofa)
  half_life_h  <- ifelse(responder, runif(n, 18, 36), Inf)
  decay <- 0.5^outer(1 / half_life_h, hours)
  noise <- matrix(exp(rnorm(n * n_t, 0, 0.1)), n, n_t)
  noise[, 1] <- 1
  pct <- round(baseline_pct * decay * noise, 3)

  clearance <- matrix(t(apply(pct, 1, pct_clearance)), n, n_t)
  asp_rec   <- matrix(t(apply(pct, 1, asp_recommendation)), n, n_t)
  first_stop_h <- apply(asp_rec == "Discontinue", 1,
                        function(x) if (any(x)) hours[which(x)[1]] else NA_real_)
  abx_duration <- ifelse(is.na(first_stop_h), 7L, pmax(1L, as.integer(first_stop_h / 24)))

  # --- Outcomes ---
  mortality <- rbinom(n, 1, plogis(-4 + 0.3 * sofa + 0.3 * log(baseline_pct) + 1.2 * !responder))
  los <- pmax(abx_duration, as.integer(round(rgamma(n, shape = 2, scale = 2 + 0.5 * sofa)))) + 1L
  cdi <- rbinom(n, 1, plogis(-5 + 0.25 * abx_duration))

  pct_long <- as.vector(t(pct))
  each_row <- function(x) rep(x, each = n_t)
  data.frame(
    Patient_ID         = each_row(seq_len(n)),
    Admission_Ward     = each_row(ward),
    Infection_Source   = each_row(infection_source),
    Baseline_SOFA      = each_row(sofa),
    Time_Hour          = rep(hours, n),
    PCT_Level          = pct_long,
    PCT_Clearance      = round(100 * as.vector(t(clearance)), 1),
    WBC_Count          = round(pmax(1, rnorm(n * n_t, 8 + 3 * log1p(pct_long), 2)), 1),
    Empiric_Abx        = each_row(empiric_abx),
    ASP_Recommendation = as.vector(t(asp_rec)),
    Abx_Duration       = each_row(abx_duration),
    Length_of_Stay     = each_row(los),
    Mortality_30D      = each_row(mortality),
    CDI_Event          = each_row(cdi),
    stringsAsFactors   = FALSE
  )
}
