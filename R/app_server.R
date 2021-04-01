#' Server-side logic
#'
#' @param input,output,session Internal parameters for {shiny}
#' @import shiny
#' @importFrom glue glue_data
#' @importFrom dplyr distinct
#' @importFrom jsonlite toJSON
#' @noRd

app_server <- function(input, output, session) {

  all_contigs <- shiny::reactive({
    message("Retrieving contigs for genome build")
    supported_genomes[[tolower(input$genome)]]
  })

  # selected_contig <- regionSelectorServer(
  #   id = "region_selector",
  #   contigs = all_contigs
  # )

  # load appropriate annotables table
  all_genes <- shiny::reactive({
    message("Retrieving genes for genome build")

    # TODO: create an internal index of gene names and drop annotables
    utils::data(list = tolower(input$genome), package = "annotables")

    # TODO: better handling of duplicate ensembl IDs and symbols
    dplyr::distinct(
      get(tolower(input$genome)),
      .keep_all = TRUE
    )
  })

  selected_gene <- geneSelectorServer(
    id = "gene_selector",
    genes = all_genes
  )

  selected_hpo <- hpoSelectorServer(
    id = "hpo_selector",
    hpo_terms = hpo_terms
  )

  shiny::observeEvent(input$reset, {
    shinyjs::reset(id = "setup")
    shiny::updateSelectInput(
      inputId = "population",
      selected = "Any"
    )
  })

  udf_output <- shiny::eventReactive(input$run_query, {

    # bed_regions <- glue::glue_data(selected_gene(), "{chr}:{start}-{end}")

    # assemble UDF parameters
    udf_params <- list(
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
      pop = input$`sample_filter-population`,
      gender = input$`sample_filter-gender`,
      # regions = as.list(bed_regions),
      # variant_filters = list(
      #   coding_only = input$coding_only
      # ),
      # sample_filters = list(
      #   hpoids = selected_hpo()
      # ),
      # region_partition = c(0L, 1L),
      vcf_parallelization = 10,
      memory_budget = 512L,
      hponame = selected_hpo()
    )


    message("Submitting UDF to TileDB Cloud")
    cli <- TileDBClient$new()

    cli$submit_udf(
      namespace = "TileDB-Inc",
      name = "TileDB-Inc/vcf_annotation_example",
      args = udf_params
    )
  })

  tbl_results <- reactive({
    req(udf_output())
    jsonlite::fromJSON(udf_output())$data
  })

  output$table_results <- DT::renderDataTable({
    req(tbl_results())
    message("Converting results to a table")

    DT::datatable(
      tbl_results(),
      style = "bootstrap",
      selection = "single",
      extensions = "Responsive"
    )
  })


  output$download_results <- shiny::downloadHandler(
    filename = "tiledb-quokka-export.csv",
    content = function(file) {
      readr::write_csv(tbl_results(), file)
    }
  )


}
