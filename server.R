library(annotables)
# library(biomaRt)
# library(biolink)
# library(glue)
library(dplyr)
library(purrr)
library(jsonlite)


function(input, output, session) {

  all_contigs <- reactive({
    available_contigs[[tolower(input$genome)]]
  })

  regions <- callModule(
    regionSelector,
    "region_selector",
    contigs = all_contigs
  )

  # load appropriate annotables table
  all_genes <- reactive({
    get(tolower(input$genome)) %>%
      # TODO: better handling of duplicate ensembl IDs and symbols
      distinct(.keep_all = TRUE)
  })

  genes <- callModule(
    geneSelector,
    "gene_selector",
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
      bed_regions <- glue::glue_data(genes(), "{chr}:{start}-{end}")

      params <- list(
        uri = input$uri_vcf,
        geneid = genes()$ensgene,
        regions = as.list(bed_regions),
        contigs = regions()
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
