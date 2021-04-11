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
            "Configure",
            configParamsUI("params"),
            tabName = "configure",
            icon = icon("cogs"),
            startExpanded = FALSE
          ),

          menuItem(
            "Query",
            queryParamsUI("params"),
            shiny::fluidRow(
              shiny::column(
                width = 4,
                shiny::actionButton(
                  "run_query",
                  "Run Query",
                  icon = icon("search")
                )
              )
            ),
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
