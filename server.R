library(annotables)
# library(biomaRt)
# library(biolink)
# library(glue)
library(dplyr)
library(purrr)
library(jsonlite)


function(input, output, session) {

  all_contigs <- reactive({
    message("Retrieving contigs for genome build")
    available_contigs[[tolower(input$genome)]]
  })

  selected_contig <- regionSelectorServer(
    id = "region_selector",
    contigs = all_contigs
  )

  # load appropriate annotables table
  all_genes <- reactive({
    message("Retrieving genes for genome build")
    get(tolower(input$genome)) %>%
      # TODO: better handling of duplicate ensembl IDs and symbols
      distinct(.keep_all = TRUE)
  })

  selected_gene <- geneSelectorServer(
    id = "gene_selector",
    genes = all_genes
  )

  # callModule(
  #   genePlot,
  #   "gene_plot",
  #   modules = reactive(input$modules),
  #   genome = reactive(input$genome),
  #   gene = gene,
  #   mart = mart_connection
  # )


  params <- eventReactive(input$run_query, {
      bed_regions <- glue::glue_data(selected_gene(), "{chr}:{start}-{end}")

      params <- list(
        uri = input$uri_vcf,
        geneid = selected_gene()$ensgene,
        regions = as.list(bed_regions),
        contig = selected_contig()
      )
    }
  )

  output$params <- shiny::renderText({
    jsonlite::toJSON(params(), auto_unbox = TRUE, pretty = TRUE)
  })

  # output$test <- shiny::renderPrint({
  #   regions()
  # })

  # callModule(geneDetailsTable, "gene_details", gene)
  # callModule(entrezDetails, "entrez_details", gene)
  # callModule(gtexPlot, "gtex_plot", gene)
}
