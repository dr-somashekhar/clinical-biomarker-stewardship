# ==============================================================================
# Shiny Dashboard
#
# The ward-round front end for the package: one tab per tool, each a Shiny
# module so the server logic can be tested with shiny::testServer() and the
# main server block stays uncluttered. All clinical logic lives in the package
# functions; the modules only collect inputs and display results.
#
# shiny is a suggested dependency, so the rest of the package works without it.
# ==============================================================================

#' Run the stewardship Shiny app
#'
#' Three tabs: the PCT stop rule for one patient's serial values, renal dose
#' screening for one order, and the PCT x SOFA risk heatmap for a simulated or
#' uploaded cohort.
#'
#' Research and educational use only; not a medical device. Uploaded files
#' stay in the R session's memory and are never written to disk by the app, but
#' do not upload identifiable patient data.
#'
#' @param ... Passed to [shiny::shinyApp()], e.g. `options = list(port = 8080)`.
#' @return A Shiny app object; printing it (or calling this at the console)
#'   launches the app.
#' @examples
#' if (interactive()) run_app()
#' @importFrom rlang %||%
#' @export
run_app <- function(...) {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop("The app needs the 'shiny' package: install.packages(\"shiny\")", call. = FALSE)
  }
  shiny::shinyApp(ui = app_ui(), server = app_server, ...)
}

app_ui <- function() {
  shiny::navbarPage(
    title = "PCT Stewardship",
    header = shiny::div(
      class = "container-fluid",
      shiny::div(
        class = "alert alert-warning", role = "alert",
        shiny::strong("Research and educational use only."),
        " Not a medical device. Verify every output against current labelling and",
        " the local formulary. Do not enter identifiable patient data."
      )
    ),
    shiny::tabPanel("PCT stop rule", mod_pct_ui("pct")),
    shiny::tabPanel("Renal dose screening", mod_renal_ui("renal")),
    shiny::tabPanel("Cohort risk heatmap", mod_cohort_ui("cohort"))
  )
}

app_server <- function(input, output, session) {
  mod_pct_server("pct")
  mod_renal_server("renal")
  mod_cohort_server("cohort")
}

# --- Shared helpers ------------------------------------------------------------

# Parses "2.5, 1.8; 0.4 0.15" into c(2.5, 1.8, 0.4, 0.15).
parse_pct_input <- function(text) {
  tokens <- strsplit(trimws(text %||% ""), "[,;[:space:]]+")[[1]]
  tokens <- tokens[nzchar(tokens)]
  if (length(tokens) == 0L) stop("Enter at least one PCT value.", call. = FALSE)
  values <- suppressWarnings(as.numeric(tokens))
  if (anyNA(values)) {
    stop("Not a number: ", paste(tokens[is.na(values)], collapse = ", "), call. = FALSE)
  }
  values
}

# Runs `expr`, returning the error condition instead of throwing, so reactives
# can show the message to the user via show_if_error().
try_or_error <- function(expr) tryCatch(expr, error = function(e) e)

# Stops the current render with the error's message shown in place of the output.
show_if_error <- function(x) {
  is_error <- inherits(x, "error")
  shiny::validate(shiny::need(!is_error, if (is_error) conditionMessage(x) else ""))
  x
}

alert <- function(type, ...) {
  shiny::div(class = paste0("alert alert-", type), role = "alert", ...)
}

error_alert <- function(err) alert("danger", shiny::strong("Check inputs: "), conditionMessage(err))

# Silently blanks an output when its input is an error; the error itself is
# shown once, by the tab's status message.
req_no_error <- function(x) {
  shiny::req(!inherits(x, "error"))
  x
}

plot_res <- 96

regimen_choices <- function(drug) {
  rules <- renal_dose_rules[renal_dose_rules$drug == drug, , drop = FALSE]
  stats::setNames(rules$regimen_id, rules$regimen_label)
}

# --- PCT stop rule -------------------------------------------------------------

mod_pct_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::sidebarLayout(
    shiny::sidebarPanel(
      shiny::textAreaInput(ns("pct_text"), "Serial PCT values (ng/mL), oldest first",
                           value = "2.5, 1.8, 0.4, 0.15, 0.08", rows = 3),
      shiny::numericInput(ns("interval_days"), "Days between measurements",
                          value = 1, min = 0.25, step = 0.25),
      shiny::sliderInput(ns("stop_drop"), "Stop when decline from peak reaches (%)",
                         min = 50, max = 95, value = 80, step = 5),
      shiny::checkboxInput(ns("use_abs_stop"),
                           sprintf("Also stop when PCT < %s ng/mL", pct_cutoffs[[2]]),
                           value = TRUE)
    ),
    shiny::mainPanel(
      shiny::uiOutput(ns("verdict")),
      shiny::plotOutput(ns("kinetics"), height = "320px"),
      shiny::tableOutput(ns("timeline"))
    )
  )
}

mod_pct_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    pct_values <- shiny::reactive(try_or_error(parse_pct_input(input$pct_text)))
    abs_stop   <- shiny::reactive(if (isTRUE(input$use_abs_stop)) pct_cutoffs[[2]] else 0)
    stop_drop  <- shiny::reactive(input$stop_drop / 100)

    # A data frame, or the error to show the user.
    timeline <- shiny::reactive({
      pct <- pct_values()
      if (inherits(pct, "error")) return(pct)
      if (!is.numeric(input$interval_days) || !isTRUE(input$interval_days > 0)) {
        return(simpleError("Days between measurements must be a positive number."))
      }
      try_or_error(data.frame(
        Day            = (seq_along(pct) - 1) * input$interval_days,
        PCT            = pct,
        Band           = as.character(classify_pct(pct)),
        Decline        = sprintf("%.0f%%", 100 * pct_clearance(pct)),
        Recommendation = asp_recommendation(pct, stop_drop(), abs_stop()),
        stringsAsFactors = FALSE
      ))
    })

    output$verdict <- shiny::renderUI({
      tl <- timeline()
      if (inherits(tl, "error")) return(error_alert(tl))
      latest <- tl[nrow(tl), ]
      type <- switch(latest$Recommendation,
                     Discontinue = "success", `De-escalate` = "warning", "info")
      alert(type,
            shiny::strong(sprintf("Latest recommendation: %s.", latest$Recommendation)),
            sprintf(" PCT %s ng/mL (%s), %s decline from peak.",
                    format(latest$PCT), gsub("_", " ", latest$Band), latest$Decline))
    })

    output$kinetics <- shiny::renderPlot(res = plot_res, {
      tl <- req_no_error(timeline())
      shiny::validate(shiny::need(nrow(tl) >= 2, "Enter at least two values to plot kinetics."))
      plot_pct_kinetics(data.frame(Patient = "Patient", Day = tl$Day, PCT = tl$PCT),
                        stop_drop = stop_drop(), abs_stop = abs_stop())
    })

    output$timeline <- shiny::renderTable({
      tl <- req_no_error(timeline())
      tl$Day  <- format(tl$Day, drop0trailing = TRUE)
      tl$PCT  <- format(tl$PCT, drop0trailing = TRUE)
      tl$Band <- gsub("_", " ", tl$Band)
      tl
    })

    list(timeline = timeline)
  })
}

# --- Renal dose screening ------------------------------------------------------

mod_renal_ui <- function(id) {
  ns <- shiny::NS(id)
  drugs <- unique(renal_dose_rules$drug)
  shiny::sidebarLayout(
    shiny::sidebarPanel(
      shiny::numericInput(ns("age"), "Age (years)", value = 68, min = 18, max = 120),
      shiny::numericInput(ns("weight"), "Actual body weight (kg)", value = 105, min = 20),
      shiny::numericInput(ns("height"), "Height (cm)", value = 160, min = 100),
      shiny::numericInput(ns("scr"), "Serum creatinine (mg/dL)", value = 1.8,
                          min = 0.1, step = 0.1),
      shiny::radioButtons(ns("sex"), "Sex", choices = c(Female = "female", Male = "male"),
                          inline = TRUE),
      shiny::selectInput(ns("drug"), "Drug", choices = drugs),
      shiny::selectInput(ns("regimen"), "Ordered regimen",
                         choices = regimen_choices(drugs[[1]]),
                         selected = utils::tail(regimen_choices(drugs[[1]]), 1))
    ),
    shiny::mainPanel(
      shiny::uiOutput(ns("status")),
      shiny::tableOutput(ns("details"))
    )
  )
}

mod_renal_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    shiny::observeEvent(input$drug, ignoreInit = TRUE, {
      choices <- regimen_choices(input$drug)
      shiny::updateSelectInput(session, "regimen", choices = choices,
                               selected = utils::tail(choices, 1))
    })

    screening <- shiny::reactive({
      shiny::req(input$drug, input$regimen)
      try_or_error(screen_medications(
        age_yrs = input$age, weight_kg = input$weight, height_cm = input$height,
        scr_mgdl = input$scr, sex_is_female = identical(input$sex, "female"),
        drug_name = input$drug, prescribed_regimen_id = input$regimen
      ))
    })

    output$status <- shiny::renderUI({
      res <- screening()
      if (inherits(res, "error")) return(error_alert(res))
      switch(res$status,
        approved = alert("success", shiny::strong("Approved."),
                         " The ordered regimen matches the estimated renal function."),
        intervention_required = alert(
          "danger", shiny::strong("Intervention required."),
          sprintf(" At CrCl %s mL/min the rules recommend %s.",
                  res$crcl_ml_min, res$recommended_label)
        ),
        alert("warning", shiny::strong("No protocol."),
              " No renal dosing rules exist for this drug; consult a clinical pharmacist.")
      )
    })

    output$details <- shiny::renderTable({
      res <- req_no_error(screening())
      recommended <- if (is.na(res$recommended_label)) "-" else res$recommended_label
      data.frame(
        Item  = c("Weight model", "Ideal body weight (kg)", "Dosing weight (kg)",
                  "Estimated CrCl (mL/min)", "Recommended regimen"),
        Value = c(res$weight_model, res$ibw_kg, res$dosing_weight_kg,
                  res$crcl_ml_min, recommended),
        stringsAsFactors = FALSE
      )
    })

    list(screening = screening)
  })
}

# --- Cohort risk heatmap -------------------------------------------------------

mod_cohort_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::sidebarLayout(
    shiny::sidebarPanel(
      shiny::radioButtons(ns("source"), "Data",
                          choices = c("Simulated cohort" = "simulated", "Upload CSV" = "upload")),
      shiny::conditionalPanel(
        "input.source == 'simulated'", ns = ns,
        shiny::numericInput(ns("n"), "Patients", value = 1000, min = 10, max = 20000, step = 100),
        shiny::numericInput(ns("seed"), "Random seed", value = 2026, step = 1)
      ),
      shiny::conditionalPanel(
        "input.source == 'upload'", ns = ns,
        shiny::fileInput(ns("upload"), "Long-format CSV (see DATA_DICTIONARY.md)",
                         accept = c(".csv", "text/csv")),
        shiny::helpText("Synthetic or fully de-identified data only.")
      ),
      shiny::numericInput(ns("min_cell_n"), "Hide mortality in cells with fewer than n patients",
                          value = 5, min = 1, step = 1)
    ),
    shiny::mainPanel(
      shiny::plotOutput(ns("heatmap"), height = "480px"),
      shiny::textOutput(ns("summary"))
    )
  )
}

mod_cohort_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    cohort <- shiny::reactive({
      if (identical(input$source, "upload")) {
        shiny::req(input$upload)
        return(try_or_error(utils::read.csv(input$upload$datapath, stringsAsFactors = FALSE)))
      }
      shiny::validate(shiny::need(isTRUE(input$n >= 1 && input$n <= 20000),
                                  "Patients must be between 1 and 20,000."))
      seed <- if (is.numeric(input$seed) && !is.na(input$seed)) input$seed else NULL
      try_or_error(simulate_cohort(input$n, seed = seed))
    })

    cells <- shiny::reactive({
      data <- show_if_error(cohort())
      shiny::validate(shiny::need(isTRUE(input$min_cell_n >= 1),
                                  "Minimum cell size must be at least 1."))
      show_if_error(try_or_error(heatmap_cells(data, input$min_cell_n)))
    })

    output$heatmap <- shiny::renderPlot(res = plot_res, {
      cells()
      build_stewardship_heatmap(cohort(), input$min_cell_n)
    })

    output$summary <- shiny::renderText({
      tbl <- tryCatch(cells(), error = function(e) shiny::req(FALSE))
      sprintf("%d patients shown; %d of %d cells suppressed (n < %s).",
              sum(tbl$n), sum(is.na(tbl$risk_pct)), nrow(tbl), input$min_cell_n)
    })

    list(cohort = cohort, cells = cells)
  })
}
