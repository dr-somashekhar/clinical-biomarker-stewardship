make_long <- function() {
  # 10 patients x 4 timepoints; patient 1 has admission PCT = 0 and died.
  data.frame(Patient_ID = rep(1:10, each = 4), Time_Hour = rep(c(0, 24, 48, 72), 10),
             PCT_Level = c(0, 1, 1, 1, rep(3, 36)), Baseline_SOFA = 5,
             Mortality_30D = rep(c(1, rep(0, 9)), each = 4))
}

test_that("empty or NULL data returns a placeholder plot", {
  expect_s3_class(build_stewardship_heatmap(NULL), "ggplot")
  expect_s3_class(build_stewardship_heatmap(data.frame()), "ggplot")
})

test_that("counts patients, not rows, and keeps PCT = 0", {
  d <- build_stewardship_heatmap(make_long())$data
  expect_equal(sum(d$n), 10)
  expect_equal(d$n[d$pct_bucket == "<0.1" & d$sofa_bucket == "4-6"], 1)
  expect_equal(d$n[d$pct_bucket == ">=2" & d$sofa_bucket == "4-6"], 9)
})

test_that("every band combination is drawn, and small cells are suppressed", {
  d <- build_stewardship_heatmap(make_long())$data
  expect_equal(nrow(d), 5 * 4)
  expect_true(all(is.na(d$risk_pct[d$n < 5])))
  expect_equal(d$risk_pct[d$pct_bucket == ">=2" & d$sofa_bucket == "4-6"], 0)
  expect_equal(d$label[d$pct_bucket == "<0.1" & d$sofa_bucket == "4-6"], "n=1\n(suppressed)")
})

test_that("min_cell_n is configurable", {
  d <- build_stewardship_heatmap(make_long(), min_cell_n = 1)$data
  expect_equal(d$risk_pct[d$pct_bucket == "<0.1" & d$sofa_bucket == "4-6"], 100)
})

test_that("missing columns and negative PCT error clearly", {
  expect_error(build_stewardship_heatmap(make_long()[, -2]), "Time_Hour")
  bad <- make_long()
  bad$PCT_Level[1] <- -1
  expect_error(build_stewardship_heatmap(bad), "Negative PCT")
})

test_that("works end to end on a simulated cohort", {
  d <- build_stewardship_heatmap(simulate_cohort(n = 200, seed = 1))$data
  expect_equal(sum(d$n), 200)
})
