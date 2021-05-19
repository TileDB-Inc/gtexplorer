app_ui_results <- function() {
  div(
    id = "options",
    shiny::fluidRow(
      DT::DTOutput("table_genes")
    ),
    shiny::fluidRow(
        plotly::plotlyOutput("plot_results", height = "550px")
    )
  )
}

