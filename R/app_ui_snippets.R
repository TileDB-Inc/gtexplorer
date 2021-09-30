#' Generate R/Python Source Code for Accessing Results
#'
#' @noRd
app_ui_snippets <- function() {
  shiny::div(
    shiny::fluidRow(
      shiny::column(
        width = 2,
        tags$h4("R", class = "text-right")
      ),
      shiny::column(
        width = 10,
        shiny::verbatimTextOutput("r_snippet")
      )
    ),
    shiny::fluidRow(
      shiny::column(
        width = 2,
        tags$h4("Python", class = "text-right")
      ),
      shiny::column(
        width = 10,
        shiny::verbatimTextOutput("py_snippet")
      )
    )
  )
}

build_r_snippet <- function(uri, gene_id) {
  sprintf("
library(tiledb)

gtex_array <- tiledb_array(
  uri = \"%s\",
  is.sparse = TRUE,
  attrs = \"tpm\",
  return_as = \"tibble\"
)

tbl_tpms <- gtex_array[\"%s\", ]", uri, gene_id)
}

build_py_snippet <- function(uri, gene_id) {
  sprintf("
import tiledb

gtex_array = tiledb.open(\"%s\")

df_tpms = (gtex_array
  .query(
    attrs = [\"tpm\"],
    dims = [\"sample\", \"gene_id\"])
  .df[\"%s\",:]
)", uri, gene_id)
}
