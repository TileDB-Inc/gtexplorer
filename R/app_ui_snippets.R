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

build_r_snippet <- function(gene_id) {
  sprintf("
library(tiledb)

gtex_array <- tiledb_array(
  uri = \"s3://genomic-datasets/biological-databases/data/tables/gtex-analysis-rnaseqc-gene-tpm\",
  is.sparse = TRUE,
  attrs = \"tpm\",
  as.data.frame = TRUE
)

tbl_tpms <- gtex_array[\"%s\", ]", gene_id)
}

build_py_snippet <- function(gene_id) {
  sprintf("
import tiledb

uri = \"s3://genomic-datasets/biological-databases/data/tables/gtex-analysis-rnaseqc-gene-tpm\"

gtex_array = tiledb.open(uri)

df_tpms = (gtex_array
  .query(
    attrs = [\"tpm\"],
    dims = [\"sample\", \"gene_id\"])
  .df[\"%s\",:]
)", gene_id)
}
