#' Build GTEx boxplot
#' @param data data.frame containing columns: SMTS, SMTSD, and tpm
#' @examples
#' \dontrun{
#' tdb_genes <- open_array()
#' tbl_results <- tbd_genes["ENSG00000202059.1",]
#' tbl_results <- merge(tbl_results, tbl_samples, by = "sample")
#' build_boxplot(tbl_results)
#' }
#' @importFrom plotly plot_ly layout
#' @importFrom scales dscale hue_pal

build_boxplot <- function(data) {
  tissues <- sort(unique(data$SMTS))
  tissue_colors  <- scales::dscale(
    tissues,
    palette = scales::hue_pal(l = 70)
  )

  bp <- plotly::plot_ly(
    data = data,
    x = ~SMTSD,
    y = ~tpm,
    color = ~SMTS,
    type = "box",
    colors = tissue_colors,
    boxpoints = "outliers",
    hoveron = "boxes",
    jitter = 0.75,
    marker = list(
      # color = "gray",
      size = 4,
      opacity = 0.5
    )
  )

  plotly::layout(
    p = bp,
    showlegend = FALSE,
    margin = list(b = 200),
    xaxis = list(
      title = "",
      tickangle = 45
    ),
    yaxis = list(
      rangemode = "tozero"
    )
  )
}
