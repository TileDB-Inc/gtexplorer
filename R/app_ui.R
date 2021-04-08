#' Application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#' @import shiny
#' @noRd

app_ui <- function(request) {
  shiny::tagList(
    shinyjs::useShinyjs(),
    shiny::navbarPage(
      theme = bslib::bs_theme(
        primary = "#001f75",
        version = 3
      ),
      title = "Quokka TileDB",
      shiny::tabPanel(
        "Home",
        shiny::sidebarLayout(
          sidebarPanel = shiny::sidebarPanel(
            queryParamsUI("params"),
            shiny::downloadButton("download_results", "Download")
          ),

          mainPanel = shiny::mainPanel(
            shinycssloaders::withSpinner(DT::dataTableOutput("table_results"))
          )
        ),

      )
    )
  )
}
