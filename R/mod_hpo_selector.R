hpoSelectorUI <- function(id) {
  ns <- shiny::NS(id)
  shiny::tagList(
    shiny::selectizeInput(
      inputId = ns("hpo"),
      label = "HPO Term",
      choices = c(`Database not loaded...` = ""),
      multiple = TRUE,
      options = list(
        placeholder = "Enter HPO Term",
        maxItems = 3,
        plugins = list(
          "remove_button"
        )
      )
    )
  )
}


# param annotable: one of annotable's provided tibbles
hpoSelectorServer <- function(id, hpo_terms) {
  shiny::moduleServer(id, function(input, output, session) {

    cat("\nUpdating HPO terms in search box...\n", file = stderr())

    shiny::updateSelectizeInput(
      session,
      inputId = "hpo",
      choices = names(hpo_terms),
      server = TRUE
    )

    shiny::reactive({
      input$hpo
    })

  })
}
