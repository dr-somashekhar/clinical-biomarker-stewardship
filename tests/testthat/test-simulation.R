test_that("kinetics plot colours patients by the stop rule", {
  p <- plot_pct_kinetics()
  expect_s3_class(p, "ggplot")
  outcome <- unique(p$data[, c("Patient", "Outcome")])
  expect_equal(as.character(outcome$Outcome[outcome$Patient == "Patient A"]), "Stop rule met")
  expect_equal(as.character(outcome$Outcome[outcome$Patient == "Patient B"]), "Stop rule not met")
  expect_silent(ggplot2::ggplot_build(p))
})

test_that("kinetics plot validates columns and sorts by day", {
  expect_error(plot_pct_kinetics(data.frame(Day = 1, PCT = 1)), "Patient")
  shuffled <- pct_kinetics_example()[16:1, ]
  expect_equal(plot_pct_kinetics(shuffled)$data$Day[1:8], 0:7)
})
