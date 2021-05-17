#' UDF Query Parameters Module

queryParamsUI <- function(id) {
  ns <- shiny::NS(id)
  shiny::div(
    id = ns("setup"),

    shiny::selectizeInput(
      inputId = ns("gene"),
      label = "Gene Symbol",
      choices = NULL,
      multiple = FALSE
    ),

    shiny::fluidRow(
      shiny::column(
        width = 4,
        shiny::actionButton(ns("reset"), "Reset Inputs", icon = icon("undo"))
      )
    )

  )
}


queryParamsServer <- function(id) {

  shiny::moduleServer(id, function(input, output, session) {

    all_genes <- shiny::reactive({
      message("Retrieving all gene names")
      unique(tbl_genes$gene_name)
    })

    shiny::observeEvent(all_genes(), {
      cat("Updating possible symbols in search box...\n", file = stderr())

      shiny::updateSelectizeInput(
        session,
        inputId = "gene",
        choices = all_genes(),
        selected = "SNORA1",
        server = TRUE
      )
    })

    shiny::observeEvent(input$reset, shinyjs::reset(id = "setup"))

    shiny::reactive({
      shiny::req(input$gene)
      message(sprintf("Filtering table of all genes for %s", input$gene))
      tbl_genes[tbl_genes$gene_name == input$gene,]
    })

  })
}


#' Query Parameters Module Test App
#'
#' @examples
#' queryParamsApp()
queryParamsApp <- function() {
  ui <- fluidPage(
    shinyjs::useShinyjs(),
    queryParamsUI("params"),
    shiny::verbatimTextOutput("out")
  )
  server <- function(input, output, session) {
    query_params <- queryParamsServer("params")
    output$out <- shiny::renderPrint({
      message("Submitting")
      query_params()
    })
  }
  shinyApp(ui, server)
}

