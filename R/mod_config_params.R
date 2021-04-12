#' UDF Configuration Parameters

configParamsUI <- function(id) {
  ns <- shiny::NS(id)
  shiny::tagList(

    shiny::selectInput(
      inputId = ns("uri_vcf"),
      label = "TileDB-VCF Dataset URI",
      choices = c(
        "tiledb://TileDB-Inc/vcf-1kg-phase3",
        "tiledb://TileDB-Inc/vcf-1kg-nygc"
      )
    ),

    shiny::sliderInput(
      inputId = ns("vcf_query_nodes"),
      label = "VCF Query Nodes",
      min = 1,
      max = 20,
      value = 5,
      step = 1
    ),

    shiny::selectInput(
      inputId = ns("node_memory_budget"),
      label = "Node Memory Budget",
      choices = 2^(7:11),
      selected = 512
    )
  )
}

configParamsServer <- function(id) {

  shiny::moduleServer(id, function(input, output, session) {

    shiny::reactive({
      message("Assembling query params")
      list(
        array_uri = input$uri_vcf,
        vcf_parallelization = input$vcf_query_nodes,
        memory_budget = as.integer(input$node_memory_budget)
      )
    })

  })
}


#' Config Parameters Module Test App
#'
#' @examples
#' configParamsApp()
configParamsApp <- function() {
  ui <- fluidPage(
    shinyjs::useShinyjs(),
    configParamsUI("params"),
    shiny::verbatimTextOutput("out")
  )
  server <- function(input, output, session) {
    config_params <- configParamsServer("params")
    output$out <- shiny::renderPrint({
      config_params()
    })
  }
  shinyApp(ui, server)
}

