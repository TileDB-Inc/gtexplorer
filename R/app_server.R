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


  results <- shiny::eventReactive(input$run_query, {

    # bed_regions <- glue::glue_data(selected_gene(), "{chr}:{start}-{end}")

    # assemble UDF parameters
    udf_params <- list(
      array_uri = input$uri_vcf,
      gene_name = selected_gene()$symbol[1],
      # consequence = "missense_variant",
      attrs = list(
        "sample_name",
        "contig",
        "pos_start",
        "pos_end",
        "fmt_GT",
        "query_bed_start",
        "query_bed_end"
      ),
      pop = input$`sample_filter-population`,
      # regions = as.list(bed_regions),
      # variant_filters = list(
      #   coding_only = input$coding_only
      # ),
      # sample_filters = list(
      #   hpoids = selected_hpo()
      # ),
      # region_partition = c(0L, 1L),
      vcf_parallelization = 10,
      memory_budget = 512L
    )

    message("Submitting UDF to TileDB Cloud")
    cli <- TileDBClient$new()

    cli$submit_udf(
      namespace = "TileDB-Inc",
      name = "TileDB-Inc/vcf_annotation_example",
      args = udf_params
    )
  })

  output$table_results <- DT::renderDataTable({
    req(results())
    message("Converting results to a table")

    # convert to a data frame
    out <- jsonlite::fromJSON(
      results(),
      simplifyDataFrame = TRUE,
      simplifyMatrix = FALSE
    )

    DT::datatable(
      data = tibble::as_tibble(out),
      style = "bootstrap",
      selection = "single"
    )
  })
}
