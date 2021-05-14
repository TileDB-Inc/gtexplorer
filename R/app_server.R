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

  tdb_genes <- open_array()
  query_params <- queryParamsServer("params")

  tbl_results <- shiny::eventReactive(input$run_query, {
    if (input$return_example_results) {
      message("Returning example results")
      return(example_results)
    } else {
      message("Retrieving gene from array")
      gene_id <- subset(tbl_genes, gene_name == names(query_params()$gene_id))
      if (nrow(gene_id) > 1) {
        message(
          sprintf("%i IDs matched %s", nrow(gene_id), query_params()$gene_id)
        )
      }
      tibble::tibble(tdb_genes[gene_id$gene_id[1],])
    }
  })

  # output$table_results <- DT::renderDataTable({
  #   req(tbl_results())
  #   message("Rendering results table")
  #
  #   DT::datatable(
  #     tbl_results(),
  #     style = "bootstrap",
  #     selection = "single",
  #     extensions = c("Responsive"),
  #     callback = DT::JS("$('div.dwnld').append($('#download_results'));"),
  #     options = list(
  #       dom = 'B<"dwnld">frtip'
  #     )
  #   )
  # })
  #
  # output$download_results <- shiny::downloadHandler(
  #   filename = "tiledb-quokka-export.csv",
  #   content = function(file) {
  #     readr::write_csv(tbl_results(), file)
  #   }
  # )

  output$plot_results <- shiny::renderPlot({
    req(tbl_results())
    message("Rendering results plot")

    tbl_results() %>%
      dplyr::inner_join(tbl_samples, by = "sample") %>%
    ggplot() +
      aes(SMTS, tpm) +
      geom_boxplot(aes(fill = SMTS), show.legend = FALSE) +
      scale_y_continuous("TPM") +
      ggtitle(
        label = sprintf("Gene expression for %s", names(query_params()$gene_id))
      ) +
      theme_bw(12) +
      theme(
        axis.title.x = element_blank(),
        axis.text.x = element_text(angle = -45, hjust = 0, vjust = 1)
      )
  })

}
