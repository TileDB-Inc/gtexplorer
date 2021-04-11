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
        choices = c("Any", unique(tbl_samples[[.x]]))
      )
    ),

    shiny::selectizeInput(
      inputId = ns("hpo"),
      label = "HPO Term",
      choices = setNames(tbl_hpoterms$hpoid, tbl_hpoterms$hponame),
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
    # shiny::checkboxInput(
    #   inputId = ns("coding_only"),
    #   label = "Restrict to coding changes",
    #   value = TRUE
    # ),
    shiny::selectizeInput(
      inputId = ns("consequence"),
      label = "VEP Consequence",
      choices = vep_consequences,
      multiple = TRUE,
      options = list(
        maxItems = 3,
        plugins = list("remove_button")
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
        # options = list(
        #   placeholder = "Enter Gene Symbol",
        #   openOnFocus = TRUE
        # )
      )
    })

    selected_gene <- reactive({
      shiny::req(input$gene)
      message("Selecting gene from table of all genes")
      all_genes()[all_genes()$ensgene == input$gene, ]
    })

    selected_regions <- reactive({
      req(selected_gene())
      gene_filter <- list(gene_id = selected_gene()$entrez[1])
      regions <- as.data.frame(
        GenomicFeatures::exons(txdb(), filter = gene_filter)
      )
      regions$seqnames <- stringr::str_remove(regions$seqnames, "chr")
      glue::glue_data(as.data.frame(regions), "{seqnames}:{start}-{end}")
    })

    selected_samples <- shiny::reactive({
      message(glue::glue("Filtering samples"))

      if (input$pop == "Any" && input$gender == "Any" && is.null(input$hpo)) {
        message("No sample filtering parameters set")
        return(NULL)
      }

      index_pop <- index_gender <- rep(TRUE, nrow(tbl_samples))
      if (input$pop != "Any")
        index_pop <- tbl_samples$pop == input$pop
      if (input$gender != "Any")
        index_gender <- tbl_samples$gender == input$gender

      samples <- tbl_samples[index_pop & index_gender, "sampleuid"]
      message(glue::glue("Selected {length(samples)} metadata samples"))

      if (!is.null(input$hpo)) {
        message(glue::glue("Filtering samples for HPO: {input$hpo}"))
        hpo_samples <- tbl_samplehpopair$sampleuid[
          tbl_samplehpopair$hpoid %in% input$hpo
        ]
        message(glue::glue("Selected {length(samples)} hpo samples"))
        samples <- intersect(samples, hpo_samples)
        message(glue::glue("{length(samples)} samples in common"))
      }
      samples
    })

    shiny::observeEvent(input$fill_example, {
      shiny::updateSelectizeInput(session, "pop", selected = "GBR")
      shiny::updateSelectizeInput(session, "gender", selected = "female")
      shiny::updateSelectizeInput(session, "consequence", selected = "missense_variant")
      shiny::updateSelectizeInput(session, "hpo", selected = "HP:0020137")

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
        gene_id = selected_gene()$ensgene[1],
        regions = selected_regions(),
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
        samples = selected_samples()
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

