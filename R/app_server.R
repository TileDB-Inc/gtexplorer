#' Server-side logic
#'
#' @param input,output,session Internal parameters for {shiny}
#' @import shiny
#' @importFrom glue glue_data
#' @importFrom dplyr distinct
#' @importFrom jsonlite toJSON
#' @importFrom DT datatable renderDataTable JS
#' @noRd

app_server <- function(input, output, session) {

  query_params <- queryParamsServer("params")
  config_params <- configParamsServer("params")

  query_results <- shiny::eventReactive(input$run_query, {
    if (input$return_example_results) {
      message("Returning example results")
      return(example_results)
    } else {
      message("Submitting UDF to TileDB Cloud")
      cli <- TileDBClient$new()

      udf_start <- Sys.time()
      results <- cli$submit_udf(
        namespace = "TileDB-Inc",
        name = "TileDB-Inc/vcf_annotation_example",
        args = c(query_params(), config_params())
      )
      udf_stop <- Sys.time()
      udf_time <- difftime(udf_stop, udf_start, units = "secs")
      message(
        glue::glue("UDF took {round(udf_time, 1)} sec")
      )
      return(jsonlite::fromJSON(results)$data)
    }
  })

  tbl_results <- reactive({
    shiny::req(query_results())

    query_results() %>%

      # add gene symbol
      dplyr::mutate(
        gene_name = names(query_params()$gene_id)[
          match(gene_id, query_params()$gene_id)
        ]
      ) %>%

      # add sample annotations
      dplyr::inner_join(tbl_samples, by = c(sample_name = "sampleuid")) %>%
      dplyr::inner_join(tbl_samplehpopair, by = c(sample_name = "sampleuid")) %>%
      dplyr::inner_join(tbl_hpoterms, by = "hpoid") %>%
      dplyr::select(-hpoid) %>%

      # reorder columns
      dplyr::select(
        sample_name,
        pop,
        gender,
        hponame,
        contig,
        pos_start,
        pos_end,
        gene_name,
        ref,
        alt,
        consequence,
        codons,
        dplyr::everything()
      )
  })

  output$table_results <- DT::renderDataTable({
    req(tbl_results())
    message("Converting results to a table")

    DT::datatable(
      tbl_results(),
      style = "bootstrap",
      selection = "single",
      extensions = c("Responsive"),
      callback = DT::JS("$('div.dwnld').append($('#download_results'));"),
      options = list(
        dom = 'B<"dwnld">frtip'
      )
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
}
