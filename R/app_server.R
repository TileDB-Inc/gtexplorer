#' Server-side logic
#'
#' @param input,output,session Internal parameters for {shiny}
#' @importFrom DT datatable renderDT JS
#' @import shiny
#' @importFrom dplyr inner_join
#' @noRd

app_server <- function(input, output, session) {

  tdb_genes <- open_gtex_array()
  selected_genes <- queryParamsServer("params")


  output$table_genes <- DT::renderDT({
    req(selected_genes())
    message("Rendering table of selected genes")

    DT::datatable(
      selected_genes(),
      style = "bootstrap4",
      selection = list(mode = "single", selected = 1, target = "row"),
      extensions = c("Responsive"),
      options = list(
        stateSave = TRUE
      )
    )
  })

  selected_gene_id <- eventReactive(input$table_genes_rows_selected, {
    message(
      sprintf(
        "Selecting gene_id from row %i of table",
        input$table_genes_rows_selected
      )
    )
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

  output$plot_results <- plotly::renderPlotly({
    req(tbl_results())
    message("Rendering results plot\n")
    build_boxplot(
      dplyr::inner_join(tbl_results(), tbl_samples, by = "sample")
    )
  })

}
