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
  selected_genes <- queryParamsServer("params")

  output$table_results <- DT::renderDataTable({
    req(tbl_results())
    message("Rendering table of selected genes")

    DT::datatable(
      selected_genes(),
      style = "bootstrap",
      selection = "single",
      extensions = c("Responsive")
    )
  })

  tbl_results <- shiny::eventReactive(input$run_query, {
    message("Querying array")
    tdb_genes[selected_genes()$gene_id,]
  })

  output$download_results <- shiny::downloadHandler(
    filename = "tiledb-quokka-export.csv",
    content = function(file) {
      readr::write_csv(tbl_results(), file)
    }
  )

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
        label = sprintf("Gene expression for %s", unique(isolate(selected_genes()$gene_name)))
      ) +
      theme_bw(12) +
      theme(
        axis.title.x = element_blank(),
        axis.text.x = element_text(angle = -45, hjust = 0, vjust = 1)
      )
  })

}
