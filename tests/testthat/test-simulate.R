test_that("simulate_cohort matches the data dictionary", {
  cohort <- simulate_cohort(n = 25, seed = 2026)
  expect_equal(nrow(cohort), 25 * 4)
  expect_named(cohort, c("Patient_ID", "Admission_Ward", "Infection_Source", "Baseline_SOFA",
                         "Time_Hour", "PCT_Level", "PCT_Clearance", "WBC_Count", "Empiric_Abx",
                         "ASP_Recommendation", "Abx_Duration", "Length_of_Stay",
                         "Mortality_30D", "CDI_Event"))
  expect_setequal(unique(cohort$Time_Hour), c(0, 24, 48, 72))
  expect_true(all(cohort$Admission_Ward %in% c("ICU", "General_Medicine")))
  expect_true(all(cohort$Infection_Source %in% c("CAP", "VAP", "Sepsis_Unknown")))
  expect_true(all(cohort$Admission_Ward[cohort$Infection_Source == "VAP"] == "ICU"))
  expect_true(all(cohort$Baseline_SOFA >= 0 & cohort$Baseline_SOFA <= 24))
  expect_true(all(cohort$PCT_Level >= 0))
  expect_true(all(cohort$PCT_Clearance >= 0 & cohort$PCT_Clearance <= 100))
  expect_true(all(cohort$ASP_Recommendation %in% c("Continue", "De-escalate", "Discontinue")))
  expect_true(all(cohort$Mortality_30D %in% 0:1))
  expect_true(all(cohort$CDI_Event %in% 0:1))
  expect_true(all(cohort$Length_of_Stay > cohort$Abx_Duration))
})

test_that("derived columns agree with the algorithm", {
  cohort <- simulate_cohort(n = 30, seed = 7)
  for (id in unique(cohort$Patient_ID)) {
    p <- cohort[cohort$Patient_ID == id, ]
    expect_equal(p$ASP_Recommendation, asp_recommendation(p$PCT_Level))
    expect_equal(p$PCT_Clearance, round(100 * pct_clearance(p$PCT_Level), 1))
  }
})

test_that("seed makes output reproducible and n is validated", {
  expect_identical(simulate_cohort(10, seed = 3), simulate_cohort(10, seed = 3))
  expect_equal(nrow(simulate_cohort(1, seed = 3)), 4)
  expect_error(simulate_cohort(0), "positive")
  expect_error(simulate_cohort(c(1, 2)), "positive")
})
