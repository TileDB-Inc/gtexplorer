#' Server-side logic
#'
#' @param input,output,session Internal parameters for {shiny}
#' @import shiny
#' @import ggplot2
#' @importFrom glue glue_data
#' @importFrom dplyr distinct
#' @importFrom jsonlite toJSON
#' @importFrom DT datatable renderDataTable JS
#' @noRd

app_server <- function(input, output, session) {

  tdb_genes <- open_array()
  selected_genes <- queryParamsServer("params")


  output$table_genes <- DT::renderDT({
    req(selected_genes())
    message("Rendering table of selected genes")

    DT::datatable(
      selected_genes(),
      style = "bootstrap",
      selection = list(mode = "single", selected = 1, target = "row"),
      extensions = c("Responsive"),
      options = list(
        stateSave = TRUE
      )
    )
  })

  selected_gene_id <- reactive({
    req(input$table_genes_rows_selected)
    message("Updating selected gene_id from table")
    selected_genes()$gene_id[input$table_genes_rows_selected]
  })

  tbl_results <- shiny::reactive({
    req(selected_gene_id())
    message(sprintf("Querying array for %s", selected_gene_id()))
    tdb_genes[selected_gene_id(),]
  })

  # output$download_results <- shiny::downloadHandler(
  #   filename = "tiledb-quokka-export.csv",
  #   content = function(file) {
  #     readr::write_csv(tbl_results(), file)
  #   }
  # )

  output$plot_results <- shiny::renderPlot({
    req(tbl_results())
    message("Rendering results plot\n")

    tbl_results() %>%
      dplyr::inner_join(tbl_samples, by = "sample") %>%
    ggplot() +
      aes(SMTS, tpm) +
      geom_boxplot(aes(fill = SMTS), show.legend = FALSE) +
      scale_y_continuous("TPM") +
      ggtitle(
        label = sprintf(
          "Gene expression for %s (%s)",
          unique(isolate(selected_genes()$gene_name)),
          isolate(selected_gene_id())
        )
      ) +
      theme_bw(12) +
      theme(
        axis.title.x = element_blank(),
        axis.text.x = element_text(angle = -45, hjust = 0, vjust = 1)
      )
  })

}
