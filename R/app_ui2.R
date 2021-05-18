app_ui_navbar <- function(request) {
  navbarPage(
    title = "gtexplorer",
    windowTitle = "gtexplorer",
    fluid = TRUE,
    theme = bslib::bs_theme(
      version = 4,
      primary = "#3190ff"
    ),
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
            h1("TileDB", class = "center"),
            h3("GTEx Explorer", class = "center")
          )
        ),

        queryParamsUI("params"),
        app_ui_results(),
      ), # div.container

      br(),
      br(),
      div(
        style = "position:fixed;bottom:0px;right:43%;",
        shiny::fluidRow(
          p(
            class = "center",
            "Visit",
            a("chrip.sh",
              href = "https://chirp.sh",
              target = "_blank"),
            "for more information."
          )
        )
      ) # div.footer

    ) # tabPanel
  ) # navbar page
}
