#' Application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#' @import shiny shinydashboard
#' @noRd

app_ui <- function(request) {
  # shiny::tagList(
    shinydashboard::dashboardPage(
      # shinyjs::useShinyjs(),
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
          ),
          menuItem(
            "Settings",
            shiny::actionButton("example_results", "Example Results"),
            tabName = "settings",
            icon = icon("th")
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

        # tabItems(
        #  tabItem("table",
        #     fluidRow(
        #      shinycssloaders::withSpinner(DT::dataTableOutput("table_results"))
        #     )
        #  )
        # )
      )
    )
  # )
}
