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
        selected = "DRD2",
        server = TRUE,
        options = list(
          placeholder = "Enter Gene Symbol",
          openOnFocus = FALSE
        )
      )
    })

    # return row for selected gene
    shiny::reactive({
      shiny::validate(
        shiny::need(input$gene, "Must select a gene to run the query.")
      )

      out <- genes()[genes()$symbol == input$gene,]
      message(
        glue::glue("Selected {input$gene} with {nrow(out)} associated Ensembl IDs")
      )
      out
    })

  })
}
