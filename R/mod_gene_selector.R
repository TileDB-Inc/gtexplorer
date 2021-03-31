geneSelectorUI <- function(id) {
  ns <- shiny::NS(id)
  shiny::tagList(
    shiny::selectizeInput(
      inputId = ns("gene"),
      label = "Gene Symbol",
      multiple = TRUE,
      choices = c(`Database not loaded...` = "")
    )
  )
}


# param annotable: one of annotable's provided tibbles
geneSelectorServer <- function(id, genes) {
  shiny::moduleServer(id, function(input, output, session) {

    shiny::observeEvent(genes(), {
      shiny::req(genes())
      cat("\nUpdating possible symbols in search box...\n", file = stderr())

      shiny::updateSelectizeInput(
        session,
        inputId = "gene",
        choices = genes()$symbol,
        selected = c(Search = ""),
        server = TRUE,
        options = list(
          placeholder = "Enter Gene Symbol",
          openOnFocus = FALSE
        )
      )
    })

    # return row for selected gene
    shiny::reactive({
      genes()[genes()$ensgene == input$gene,]
    })

  })
}
