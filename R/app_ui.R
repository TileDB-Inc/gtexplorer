#' Application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#' @import shinydashboard
#' @importFrom DT DTOutput
#' @importFrom shinycssloaders withSpinner
#' @importFrom shinyjs useShinyjs
#' @noRd

app_ui <- function(request) {
    shinydashboard::dashboardPage(
      shinyjs::useShinyjs(),
      # theme = bslib::bs_theme(primary = "#001f75", version = 3),
      header = dashboardHeader(
        title = "TileDB GTEx Explorer",
        titleWidth = 350
      ),

      sidebar = dashboardSidebar(
        width = 350,
        sidebarMenu(
          menuItem(
            "Query",
            queryParamsUI("params"),
            tabName = "dashboard",
            icon = icon("dashboard"),
            startExpanded = TRUE
          )
        )
      ),

      body = dashboardBody(
        # fluidRow(
        #   valueBoxOutput("samples"),
        #   valueBoxOutput("variants"),
        #   valueBoxOutput("consequences")
        # ),

        fluidRow(
          box(
            shinycssloaders::withSpinner(
              DT::DTOutput("table_genes")
            ),
            width = 12
          )
        ),

        fluidRow(
          box(
            shinycssloaders::withSpinner(
              plotly::plotlyOutput("plot_results", height = "550px")
            ),
            width = 12
          )
        )

      )
    )
}
