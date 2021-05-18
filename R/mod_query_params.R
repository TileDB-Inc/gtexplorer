#' UDF Query Parameters Module UI
#'
#' @param id ID for module
#' @noRd
queryParamsUI <- function(id) {
  ns <- shiny::NS(id)
  shiny::div(
    id = ns("setup"),
    # style="display:inline-block;vertical-align:top;",
    shiny::fluidRow(

      shiny::column(
        width = 1,
        shiny::br(),
        shiny::actionButton(ns("opts"), "", icon = icon("plus"))
      ),

      shiny::column(
        width = 9,
        # shiny::br(),
        shiny::selectizeInput(
          inputId = ns("gene"),
          label = "",
          choices = NULL,
          multiple = FALSE,
          width = "100%"
        )
      ),

      shiny::column(
        width = 2,
        shiny::br(),
        shiny::actionButton(ns("reset"), "Reset Inputs", icon = icon("undo"), class = "btn btn-primary")
      )
    )
  )
}

#' UDF Query Parameters Module Server
#'
#' @param id ID for module
#' @returns Filtered version of the `tbl_genes` data.frame with row for each
#' `gene_id` associated with the selected gene name.
#' @noRd
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
#' \dontrun{
#'  queryParamsApp()
#' }
#' @export
queryParamsApp <- function() {
  ui <- fluidPage(
    shinyjs::useShinyjs(),
    queryParamsUI("params"),
    shiny::verbatimTextOutput("out")
  )
  server <- function(input, output, session) {
    query_params <- queryParamsServer("params")
    output$out <- shiny::renderPrint({
      req(query_params())
      message("Submitting")
      query_params()
    })
  }
  shinyApp(ui, server)
}

