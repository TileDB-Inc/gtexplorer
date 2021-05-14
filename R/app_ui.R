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
        title = "TileDB GTEx Explorer",
        titleWidth = 350
      ),
      sidebar = dashboardSidebar(
        width = 350,
        sidebarMenu(

          menuItem(
            "Configure",
            configParamsUI("params"),
            tabName = "configure",
            icon = icon("cogs"),
            startExpanded = FALSE
          ),

          menuItem(
            "Query",
            queryParamsUI("params"),
            tabName = "dashboard",
            icon = icon("dashboard"),
            startExpanded = TRUE
          ),

           menuItem(
            "Test",
            shiny::checkboxInput("return_example_results", "Example Results"),
            icon = icon("bug")
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
              shiny::plotOutput("plot_results")
            ),
            width = 12
          )
        )

      )
    )
}
