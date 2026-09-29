test_that("kinetics plot builds", {
  p <- plot_pct_kinetics()
  expect_true(inherits(p, "ggplot"))
  expect_no_error(ggplot2::ggplot_build(p))
})

test_that("patients are labelled by the stop rule", {
  labelled <- label_stop_outcome(pct_kinetics_example(), stop_drop = 0.8, abs_stop = 0.25)
  outcome <- unique(labelled[, c("Patient", "Outcome")])
  expect_equal(as.character(outcome$Outcome[outcome$Patient == "Patient A"]), "Stop rule met")
  expect_equal(as.character(outcome$Outcome[outcome$Patient == "Patient B"]), "Stop rule not met")
})

test_that("kinetics input is validated and sorted by day", {
  expect_error(plot_pct_kinetics(data.frame(Day = 1, PCT = 1)), "Patient")
  shuffled <- pct_kinetics_example()[16:1, ]
  expect_equal(label_stop_outcome(shuffled, 0.8, 0.25)$Day[1:8], 0:7)
})
