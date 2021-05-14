#' UDF Query Parameters Module

queryParamsUI <- function(id) {
  ns <- shiny::NS(id)
  shiny::div(
    id = ns("setup"),

    shiny::selectInput(
      inputId = ns("genome"),
      label = "Genome Build",
      choices = c("GRCh37", "GRCh38")
    ),

    shiny::selectizeInput(
      inputId = ns("gene"),
      label = "Gene Symbol",
      choices = NULL,
      multiple = TRUE,
      options = list(
        maxItems = 3,
        plugins = list(
          "remove_button"
        )
      )
    ),

    shiny::fluidRow(
      shiny::column(
        width = 4,
        shiny::actionButton(ns("fill_example"), "Example Query")
      ),
      shiny::column(
        width = 4,
        shiny::actionButton(ns("reset"), "Reset Inputs", icon = icon("undo"))
      )
    )

  )
}


# param annotable: one of annotable's provided tibbles
queryParamsServer <- function(id) {

  shiny::moduleServer(id, function(input, output, session) {

    txdb <- shiny::reactive({
      message("Retrieving transcript database for genome build")
      switch(tolower(input$genome),
        grch37 = TxDb.Hsapiens.UCSC.hg19.knownGene::TxDb.Hsapiens.UCSC.hg19.knownGene,
        grch38 = TxDb.Hsapiens.UCSC.hg38.knownGene::TxDb.Hsapiens.UCSC.hg38.knownGene
      )
    })

    # load appropriate annotables table
    all_genes <- shiny::reactive({
      req(input$genome)
      message("Retrieving genes for genome build")

      # TODO: create an internal index of gene names and drop annotables
      utils::data(list = tolower(input$genome), package = "annotables")

      # TODO: better handling of duplicate ensembl IDs and symbols
      dplyr::distinct(
        get(tolower(input$genome)),
        .keep_all = TRUE
      )
    })

    shiny::observeEvent(all_genes(), {
      # shiny::req(genes())
      cat("\nUpdating possible symbols in search box...\n", file = stderr())

      shiny::updateSelectizeInput(
        session,
        inputId = "gene",
        choices = setNames(all_genes()$ensgene, all_genes()$symbol),
        selected = "",
        server = TRUE
      )
    })

    selected_genes <- reactive({
      shiny::req(input$gene)
      message("Selecting genes from table of all genes")
      all_genes()[all_genes()$ensgene %in% input$gene, ]
    })

    shiny::observeEvent(input$fill_example, {

      # updating server-side selection requires passing the choices again
      shiny::updateSelectizeInput(session, "gene",
        selected = "ENSG00000149295", # DRD2
        server = TRUE,
        choices = setNames(all_genes()$ensgene, all_genes()$symbol)
      )
    })

    shiny::observeEvent(input$reset, shinyjs::reset(id = "setup"))

    shiny::reactive({
      message("Assembling query params")

      list(
        genome = tolower(input$genome),
        gene_id = setNames(selected_genes()$ensgene, selected_genes()$symbol)
      )
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

