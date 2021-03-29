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


  params <- shiny::eventReactive(input$run_query, {
      bed_regions <- glue::glue_data(selected_gene(), "{chr}:{start}-{end}")

      params <- list(
        uri = input$uri_vcf,
        geneid = selected_gene()$ensgene,
        regions = as.list(bed_regions),
        filters = list(
          coding_only = input$coding_only
        )
      )
    }
  )

  output$params <- shiny::renderText({
    jsonlite::toJSON(params(), auto_unbox = TRUE, pretty = TRUE)
  })
}
