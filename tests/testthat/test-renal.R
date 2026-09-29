test_that("guideline-concordant order is approved (regression: label-string mismatch)", {
  r <- screen_medications(40, 70, 175, 1.0, FALSE, "Cefepime", "2g_q8h")
  expect_equal(r$recommended_regimen, "2g_q8h")
  expect_equal(r$recommended_label, "2 g IV q8h")
  expect_equal(r$status, "approved")
})

test_that("obese elderly female uses AdjBW and is flagged for 2g q8h", {
  r <- screen_medications(68, 105, 160, 1.8, TRUE, "cefepime", "2g_q8h")
  expect_equal(r$weight_model, "AdjBW")
  expect_equal(r$crcl_ml_min, 34.7)
  expect_equal(r$recommended_regimen, "2g_q12h")
  expect_equal(r$status, "intervention_required")
})

test_that("weight model selection covers ABW, IBW and AdjBW", {
  expect_equal(screen_medications(40, 50, 175, 1, FALSE, "cefepime", "2g_q8h")$weight_model, "ABW")
  expect_equal(screen_medications(40, 72, 175, 1, FALSE, "cefepime", "2g_q8h")$weight_model, "IBW")
  expect_equal(screen_medications(40, 120, 175, 1, FALSE, "cefepime", "2g_q8h")$weight_model, "AdjBW")
})

test_that("CrCl band lower bounds are inclusive", {
  expect_equal(recommend_regimen("cefepime", c(5, 10.9, 11, 29.9, 30, 59.9, 60)),
               c("1g_q24h", "1g_q24h", "2g_q24h", "2g_q24h", "2g_q12h", "2g_q12h", "2g_q8h"))
})

test_that("invalid inputs fail with clear messages, not R internals", {
  expect_error(screen_medications(40, 70, 175, 1, FALSE, NULL, "x"), "drug_name")
  expect_error(screen_medications(40, 70, 175, 1, FALSE, "  ", "x"), "drug_name")
  expect_error(screen_medications(NA, 70, 175, 1, FALSE, "cefepime", "x"), "age_yrs")
  expect_error(screen_medications(c(40, 50), 70, 175, 1, FALSE, "cefepime", "x"), "single")
  expect_error(screen_medications(16, 70, 175, 1, FALSE, "cefepime", "x"), "age_yrs")
  expect_error(screen_medications(40, 70, 15, 1, FALSE, "cefepime", "x"), "height_cm")
  expect_error(screen_medications(40, 70, 175, 0.05, FALSE, "cefepime", "x"), "scr_mgdl")
  expect_error(screen_medications(40, 70, 175, 1, NA, "cefepime", "x"), "sex_is_female")
})

test_that("unknown drug returns no_protocol", {
  r <- screen_medications(40, 70, 175, 1, FALSE, "vancomycin", "x")
  expect_equal(r$status, "no_protocol")
  expect_true(is.na(r$recommended_regimen))
})

test_that("Devine IBW floors at base weight for short patients", {
  expect_equal(ideal_body_weight(150, TRUE), 45.5)
  expect_equal(ideal_body_weight(152.4, FALSE), 50)
})

test_that("helpers are vectorised for cohort screening", {
  ibw <- ideal_body_weight(c(160, 175), c(TRUE, FALSE))
  expect_length(ibw, 2)
  expect_length(cockcroft_gault(c(40, 70), dosing_weight(c(60, 110), ibw), c(1, 2), c(TRUE, FALSE)), 2)
})
