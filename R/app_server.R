#' Server-side logic
#'
#' You can override the default array URI with the environment variable,
#' `GTEXPLORER_URI`.
#'
#' @param input,output,session Internal parameters for {shiny}
#' @importFrom DT datatable renderDT JS
#' @import shiny
#' @importFrom dplyr inner_join
#' @noRd

app_server <- function(input, output, session) {

  array_uri <- Sys.getenv(
    x = "GTEXPLORER_URI",
    unset = "tiledb://TileDB-Inc/gtex-analysis-rnaseqc-gene-tpm"
  )

  tdb_genes <- open_gtex_array(array_uri, attrs = "tpm")
  selected_genes <- queryParamsServer("params")


  output$table_genes <- DT::renderDT({
    req(selected_genes())
    message("Rendering table of selected genes")

    DT::datatable(
      selected_genes(),
      rownames = FALSE,
      style = "bootstrap4",
      selection = list(mode = "single", selected = 1, target = "row"),
      extensions = c("Responsive"),
      options = list(
        stateSave = TRUE,
        searching = FALSE,
        paging = TRUE,
        info = FALSE,
        lengthChange = FALSE
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

  output$r_snippet <- shiny::renderText({
    message("Updating R snippet")
    build_r_snippet(array_uri, selected_gene_id())
  })

  output$py_snippet <- shiny::renderText({
    message("Updating Python snippet")
    build_py_snippet(array_uri, selected_gene_id())
  })

  tbl_results <- shiny::reactive({
    req(selected_gene_id())
    message(sprintf("Querying array for %s", selected_gene_id()))
    tdb_genes[selected_gene_id(),]
  })

  shiny::observeEvent(selected_genes(), {
    req(input$`main-tabs` != "Results")
    message("Switching to results tab")
    shiny::updateTabsetPanel(session, "main-tabs",
      selected = "Results"
    )
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
      dplyr::inner_join(tbl_results(), tbl_samples, by = "sample"),
      title = sprintf(
        "Gene expression for %s (%s)",
        selected_genes()$gene_name[1],
        selected_gene_id()
      )
    )
  })

}
