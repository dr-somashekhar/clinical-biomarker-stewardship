test_that("classify_pct matches README bands, left-closed", {
  expect_equal(as.character(classify_pct(c(0, 0.09, 0.1, 0.24, 0.25, 0.49, 0.5, 3))),
               c("highly_unlikely", "highly_unlikely", "unlikely", "unlikely",
                 "possible", "possible", "likely", "likely"))
  expect_true(is.na(classify_pct(NA_real_)))
  expect_error(classify_pct(-1), "negative")
  expect_error(classify_pct("0.3"), "numeric")
})

test_that("pct_clearance is the running decline from peak", {
  expect_equal(pct_clearance(c(1, 2, 1, 0.4)), c(0, 0, 0.5, 0.8))
  expect_equal(pct_clearance(c(0, 0)), c(0, 0))
  expect_error(pct_clearance(c(1, NA)), "non-missing")
  expect_error(pct_clearance(c(1, -0.1)), "negative")
})

test_that("80% rule fires for responder and not for non-responder", {
  responder <- pct_decline_from_peak(c(2.5, 1.8, 0.4, 0.15, 0.08))
  expect_true(responder$stop_signal)
  expect_equal(responder$peak, 2.5)
  expect_equal(responder$current, 0.08)
  expect_equal(responder$category, "highly_unlikely")
  expect_false(pct_decline_from_peak(c(2.5, 2.7, 2.4, 2.6))$stop_signal)
})

test_that("stop rule boundaries: exactly 80% decline, and abs_stop", {
  expect_true(pct_decline_from_peak(c(5, 1))$stop_signal)                    # exactly 80%
  expect_false(pct_decline_from_peak(c(5, 1.01))$stop_signal)
  expect_true(pct_decline_from_peak(c(0.3, 0.2))$stop_signal)                # < 0.25
  expect_false(pct_decline_from_peak(c(0.3, 0.2), abs_stop = 0)$stop_signal) # decline only
  expect_error(pct_decline_from_peak(0.3), ">= 2")
})

test_that("asp_recommendation maps each timepoint", {
  expect_equal(asp_recommendation(c(3, 2.5, 0.4, 0.3, 0.1)),
               c("Continue", "Continue", "Discontinue", "Discontinue", "Discontinue"))
  expect_equal(asp_recommendation(c(0.45, 0.4)), c("De-escalate", "De-escalate"))
  expect_equal(asp_recommendation(0.05), "Discontinue")
})
