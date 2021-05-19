app_ui_navbar <- function(request) {
  navbarPage(
    title = "gtexplorer",
    windowTitle = "gtexplorer",
    fluid = TRUE,
    theme = gtexplorer_theme(),
    id = "tabs",

    shiny::tabPanel(
      title = "HOME",
      shinyjs::useShinyjs(),

      div(
        class = "container",
        style = "min-height:90vh;",

        div(
          style = "width: 100%; position: relative;z-index:-9;",
          div(
            # style = "padding-top:20px;",
            h1("TileDB", class = "font-weight-bold"),
            h3("GTEx Explorer", class = "font-weight-light", style = "margin-top: 0em;")
          )
        ),

        queryParamsUI("params"),

        tabsetPanel(
          type = "tabs",
          tabPanel(
            "About",
            shiny::includeMarkdown(system.file("assets/about.md", package = "gtexplorer")),
            class = "p-3"
          ),
          tabPanel("Results", app_ui_results(), class = "p-3"),
          tabPanel("Snippets", app_ui_snippets(), class = "p-3")
        ),

      ) # div.container

    ) # tabPanel
  ) # navbar page
}
