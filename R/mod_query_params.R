queryParamsUI <- function(id) {
  ns <- shiny::NS(id)
  shiny::tagList(

    shiny::textInput(
      inputId = ns("uri_vcf"),
      label = "TileDB-VCF Dataset URI",
      value = "tiledb://TileDB-Inc/vcf-1kg-phase3",
      placeholder = "e.g., tiledb://TileDB-Inc/vcf-1kg-phase3"
    ),

    shiny::selectInput(
      inputId = ns("genome"),
      label = "Genome Build",
      choices = c("GRCh37", "GRCh38")
    ),

    shiny::selectizeInput(
      inputId = ns("gene"),
      label = "Gene Symbol",
      choices = NULL
    ),

    shiny::h4("Filter Samples"),
    # sample metadata filters
    purrr::imap(
      list(Gender = "gender", Population = "pop"),
      ~ shiny::selectizeInput(
        inputId = ns(.x),
        label = .y,
        multiple = FALSE,
        choices = c("Any", sample_metadata[[.x]])
      )
    ),

    shiny::selectizeInput(
      inputId = ns("hpo"),
      label = "HPO Term",
      choices = names(hpo_terms),
      multiple = TRUE,
      options = list(
        # placeholder = "Enter HPO Term",
        maxItems = 3,
        plugins = list(
          "remove_button"
        )
      )
    ),


    shiny::h4("Variant Filters"),
    shiny::checkboxInput(
      inputId = ns("coding_only"),
      label = "Restrict to coding changes",
      value = TRUE
    ),
    shiny::selectizeInput(
      inputId = ns("consequence"),
      label = "VEP Consequence",
      choices = vep_consequences,
      selected = "missense_variant",
      multiple = TRUE,
      options = list(
        placeholder = "Select consequence",
        maxItems = 3,
        plugins = list("remove_button")
      )
    ),

    shiny::actionButton(ns("run_query"), "Search"),
    shiny::actionButton(ns("reset"), "Reset"),

  )
}


# param annotable: one of annotable's provided tibbles
queryParamsServer <- function(id) {

  shiny::moduleServer(id, function(input, output, session) {

    all_contigs <- shiny::reactive({
      message("Retrieving contigs for genome build")
      supported_genomes[[tolower(input$genome)]]
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
        choices = c("", all_genes()$symbol),
        # selected = "DRD2",
        server = TRUE
        # options = list(
        #   placeholder = "Enter Gene Symbol",
        #   openOnFocus = TRUE
        # )
      )
    })

    observe({
      message(glue::glue("There are now {nrow(all_genes())} genes."))
    })

    selected_gene <- reactive({
      # req(genes())
      req(input$gene)
      # browser()
      message("Selecting gene from table of all genes")
      all_genes()[all_genes()$symbol == input$gene,]
    })

    observe({
      message(glue::glue("Selected gene: {selected_gene()}"))
    })

    shiny::observeEvent(input$reset, {
      shinyjs::reset(id = "setup")
      shiny::updateSelectInput(
        inputId = "pop",
        selected = "Any"
      )
    })

    shiny::eventReactive(input$run_query, {
      message("Assembling UDF to TileDB Cloud")
      list(
        array_uri = input$uri_vcf,
        gene_name = selected_gene()$symbol[1],
        consequence = input$consequence,
        attrs = list(
          "sample_name",
          "contig",
          "pos_start",
          "pos_end",
          # "fmt_GT",
          "query_bed_start",
          "query_bed_end"
        ),
        pop = input$pop,
        gender = input$gender,
        vcf_parallelization = 10,
        memory_budget = 512L,
        hponame = input$hpo
      )
    })

  })
}


queryParamsApp <- function() {
  ui <- fluidPage(
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

# queryParamsApp()
