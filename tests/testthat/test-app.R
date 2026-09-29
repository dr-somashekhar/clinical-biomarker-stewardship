skip_if_not_installed("shiny")

test_that("parse_pct_input accepts common separators and rejects junk", {
  expect_equal(parse_pct_input("2.5, 1.8; 0.4\n0.15  0.08"), c(2.5, 1.8, 0.4, 0.15, 0.08))
  expect_equal(parse_pct_input(" 0.3 "), 0.3)
  expect_error(parse_pct_input(""), "at least one")
  expect_error(parse_pct_input(NULL), "at least one")
  expect_error(parse_pct_input("1.2, abc, 0.4"), "abc")
})

test_that("run_app launches in the browser by default", {
  launched <- NULL
  local_mocked_bindings(launch_in_browser = function(app) launched <<- app)
  expect_null(run_app())
  expect_s3_class(launched, "shiny.appobj")
})

test_that("run_app builds an app object and the UI renders", {
  expect_s3_class(run_app(launch = FALSE), "shiny.appobj")
  html <- as.character(app_ui())
  expect_match(html, "Research and educational use only")
  expect_match(html, "PCT stop rule")
  expect_match(html, "Renal dose screening")
  expect_match(html, "Cohort risk heatmap")
})

test_that("app server starts all three modules", {
  shiny::testServer(app_server, {
    expect_true(TRUE)
  })
})

test_that("PCT module applies the stop rule and its settings", {
  shiny::testServer(mod_pct_server, {
    session$setInputs(pct_text = "2.5, 1.8, 0.4, 0.15, 0.08", interval_days = 1,
                      stop_drop = 80, use_abs_stop = TRUE)
    tl <- timeline()
    expect_equal(tl$Recommendation,
                 c("Continue", "Continue", "Discontinue", "Discontinue", "Discontinue"))
    expect_equal(tl$Day, 0:4)
    expect_match(output$verdict$html, "Latest recommendation: Discontinue")
    expect_match(output$verdict$html, "alert-success")
    expect_true(is.list(output$kinetics))
    expect_match(output$timeline, "Discontinue")
    expect_match(output$timeline, "highly unlikely")
    expect_no_match(output$timeline, "0.000")

    session$setInputs(pct_text = "0.3, 0.2", use_abs_stop = FALSE)
    expect_equal(timeline()$Recommendation, c("De-escalate", "Continue"))
    expect_match(output$verdict$html, "alert-info")

    session$setInputs(pct_text = "0.45")
    expect_match(output$verdict$html, "alert-warning")
    expect_error(output$kinetics, "at least two values")

    session$setInputs(interval_days = 12, pct_text = "3, 1")
    expect_equal(timeline()$Day, c(0, 12))
  })
})

test_that("PCT module shows each input error once, in the verdict", {
  shiny::testServer(mod_pct_server, {
    expect_error_shown <- function(pattern) {
      expect_s3_class(timeline(), "error")
      expect_match(conditionMessage(timeline()), pattern)
      expect_match(output$verdict$html, "alert-danger")
      expect_match(output$verdict$html, pattern)
      expect_error(output$kinetics, class = "shiny.silent.error")
      expect_error(output$timeline, class = "shiny.silent.error")
    }
    session$setInputs(pct_text = "2.5, oops", interval_days = 1, stop_drop = 80,
                      use_abs_stop = TRUE)
    expect_error_shown("oops")
    session$setInputs(pct_text = "2.5, -1")
    expect_error_shown("negative")
    session$setInputs(pct_text = "2.5, 1", interval_days = 0)
    expect_error_shown("positive")
    session$setInputs(interval_days = NA)
    expect_error_shown("positive")
  })
})

test_that("regimen menu defaults to the standard (highest-CrCl) regimen", {
  expect_match(as.character(mod_renal_ui("renal")),
               '<option value="2g_q8h" selected>', fixed = TRUE)
  shiny::testServer(mod_renal_server, {
    session$setInputs(drug = "cefepime")
    session$setInputs(drug = "cefepime")  # observer is ignoreInit; fire it once
    expect_true(TRUE)
  })
})

test_that("renal module screens orders and reports each status", {
  shiny::testServer(mod_renal_server, {
    session$setInputs(age = 68, weight = 105, height = 160, scr = 1.8, sex = "female",
                      drug = "cefepime", regimen = "2g_q8h")
    expect_equal(screening()$status, "intervention_required")
    expect_match(output$status$html, "Intervention required")
    expect_match(output$status$html, "2 g IV q12h")
    expect_match(output$details, "AdjBW")

    session$setInputs(regimen = "2g_q12h")
    expect_equal(screening()$status, "approved")
    expect_match(output$status$html, "Approved")

    session$setInputs(sex = "male", age = 40, weight = 70, height = 175, scr = 1,
                      regimen = "2g_q8h")
    expect_equal(screening()$status, "approved")
  })
})

test_that("renal module handles unknown drugs and bad inputs", {
  shiny::testServer(mod_renal_server, {
    session$setInputs(age = 40, weight = 70, height = 175, scr = 1, sex = "male",
                      drug = "vancomycin", regimen = "x")
    expect_equal(screening()$status, "no_protocol")
    expect_match(output$status$html, "No protocol")
    expect_match(output$details, "<td> - </td>", fixed = TRUE)

    session$setInputs(drug = "cefepime", regimen = "2g_q8h", age = NA)
    expect_s3_class(screening(), "error")
    expect_match(output$status$html, "alert-danger")
    expect_match(output$status$html, "age_yrs")
    expect_error(output$details, class = "shiny.silent.error")
    session$setInputs(age = 16)
    expect_match(output$status$html, "outside the plausible range")
  })
})

test_that("cohort module simulates, validates and summarises", {
  shiny::testServer(mod_cohort_server, {
    session$setInputs(source = "simulated", n = 300, seed = 1, min_cell_n = 5)
    expect_equal(sum(cells()$n), 300)
    expect_match(output$summary, "^300 patients shown")
    expect_true(is.list(output$heatmap))

    session$setInputs(seed = NA)
    expect_equal(sum(cells()$n), 300)

    session$setInputs(n = 0)
    expect_error(cells(), "between 1 and 20,000")
    expect_error(output$heatmap, "between 1 and 20,000")
    expect_error(output$summary, class = "shiny.silent.error")
    session$setInputs(n = 300, min_cell_n = 0)
    expect_error(cells(), "at least 1")
  })
})

test_that("cohort module reads uploads and rejects bad files", {
  good <- tempfile(fileext = ".csv")
  bad  <- tempfile(fileext = ".csv")
  on.exit(unlink(c(good, bad)))
  utils::write.csv(simulate_cohort(40, seed = 2), good, row.names = FALSE)
  utils::write.csv(data.frame(x = 1:3), bad, row.names = FALSE)

  shiny::testServer(mod_cohort_server, {
    session$setInputs(source = "upload", min_cell_n = 5)
    expect_error(cells())  # waits for a file (req)

    session$setInputs(upload = list(datapath = good, name = "cohort.csv"))
    expect_equal(sum(cells()$n), 40)

    session$setInputs(upload = list(datapath = bad, name = "bad.csv"))
    expect_error(cells(), "Missing required column")
  })
})
