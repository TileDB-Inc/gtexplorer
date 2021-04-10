#' Server-side logic
#'
#' @param input,output,session Internal parameters for {shiny}
#' @import shiny
#' @importFrom glue glue_data
#' @importFrom dplyr distinct
#' @importFrom jsonlite toJSON
#' @noRd

app_server <- function(input, output, session) {

  query_params <- queryParamsServer("params")

  query_results <- shiny::eventReactive(input$run_query, {
    message("Submitting UDF to TileDB Cloud")
    cli <- TileDBClient$new()

    cli$submit_udf(
      namespace = "TileDB-Inc",
      name = "TileDB-Inc/vcf_annotation_example",
      args = query_params()
    )
  })

  tbl_results <- reactive({
    req(query_results())
    jsonlite::fromJSON(query_results())$data %>%
      dplyr::select(-transcript_id, -exon_number) %>%
      dplyr::select(
        sample_name,
        hponame,
        contig,
        pos_start,
        pos_end,
        gene_name,
        ref,
        alt,
        consequence,
        codons,
        everything()
      ) %>%
    dplyr::distinct()
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

  output$samples <- renderValueBox({
    valueBox(
      dplyr::n_distinct(tbl_results()$sample_name),
      "Unique Samples",
      icon = icon("users")
    )
  })

  output$variants <- renderValueBox({
    valueBox(
      nrow(dplyr::distinct(tbl_results(), pos_start, pos_end)),
      "Unique Variants",
      icon = icon("dna"),
      color = "blue"
    )
  })

  output$consequences <- renderValueBox({
    valueBox(
      dplyr::n_distinct(tbl_results()$consequence),
      "Variant Consequences",
      icon = icon("exclamation-triangle"),
      color = "orange"
    )
  })


  output$download_results <- shiny::downloadHandler(
    filename = "tiledb-quokka-export.csv",
    content = function(file) {
      readr::write_csv(tbl_results(), file)
    }
  )


  tbl_results <- shiny::eventReactive(input$example_results, {
    message("Loading example results table...")
    example_results
  })

}
