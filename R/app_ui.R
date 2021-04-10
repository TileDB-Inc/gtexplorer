#' Application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#' @import shiny shinydashboard
#' @importFrom DT dataTableOutput
#' @importFrom shinycssloaders withSpinner
#' @noRd

app_ui <- function(request) {
    shinydashboard::dashboardPage(
      shinyjs::useShinyjs(),
      # theme = bslib::bs_theme(primary = "#001f75", version = 3),
      header = dashboardHeader(
        title = "Quokka TileDB",
        titleWidth = 350
      ),
      sidebar = dashboardSidebar(
        width = 350,
        sidebarMenu(
          menuItem(
            "Query",
            queryParamsUI("params"),
            shiny::actionButton("run_query", "Search"),
            shiny::checkboxInput("return_example_results", "Example Results"),
            tabName = "dashboard",
            icon = icon("dashboard"),
            startExpanded = TRUE
          )
        )
      ),

      body = dashboardBody(
        fluidRow(
          valueBoxOutput("samples"),
          valueBoxOutput("variants"),
          valueBoxOutput("consequences")
        ),

        fluidRow(
          box(
            shiny::downloadButton("download_results", "Download"),
            shinycssloaders::withSpinner(
              DT::dataTableOutput("table_results")
            ),
            width = 12
          )
        )
      )
    )
}
