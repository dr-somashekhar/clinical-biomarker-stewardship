test_that("empty or NULL data returns a placeholder plot", {
  expect_s3_class(build_stewardship_heatmap(NULL), "ggplot")
  expect_s3_class(build_stewardship_heatmap(data.frame()), "ggplot")
})

test_that("heatmap aggregates mortality per PCT x SOFA cell", {
  d <- data.frame(PCT_Level = c(0.1, 0.1, 5), Baseline_SOFA = c(2, 2, 12),
                  Mortality_30D = c(0, 1, 1))
  p <- build_stewardship_heatmap(d)
  expect_s3_class(p, "ggplot")
  expect_equal(sort(p$data$risk_score), c(50, 100))
})
