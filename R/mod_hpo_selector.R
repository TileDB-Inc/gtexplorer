hpoSelectorUI <- function(id) {
  ns <- shiny::NS(id)
  shiny::tagList(
    shiny::selectizeInput(
      inputId = ns("hpo"),
      label = "HPO Term",
      choices = c(`Database not loaded...` = "")
    )
  )
}


# param annotable: one of annotable's provided tibbles
hpoSelectorServer <- function(id, hpoterms) {
  shiny::moduleServer(id, function(input, output, session) {

    cat("\nUpdating HPO terms in search box...\n", file = stderr())

    shiny::updateSelectizeInput(
      session,
      inputId = "hpo",
      choices = hpoterms,
      selected = c(Search = ""),
      server = TRUE,
      options = list(
        placeholder = "Enter HPO Term",
        openOnFocus = FALSE
      )
    )

    shiny::reactive({
      input$hpo
    })

  })
}
