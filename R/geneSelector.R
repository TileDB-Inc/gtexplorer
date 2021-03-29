
geneSelectorUI <- function(id) {
  ns <- NS(id)
  tagList(
    selectizeInput(
      inputId = ns("gene"),
      label = "Gene Symbol",
      choices = c(`Database not loaded...` = "")
    )
  )
}


# param annotable: one of annotable's provided tibbles
geneSelector <- function(input, output, session, genes) {

  observeEvent(genes(), {
    req(genes())
    cat("\n\nUpdating possible symbols in search box...\n", file = stderr())

    updateSelectizeInput(
      session,
      inputId = "gene",
      choices = setNames(genes()$entrez, genes()$symbol),
      selected = c(Search = ""),
      server = TRUE,
      options = list(
        placeholder = "Enter Gene Symbol",
        openOnFocus = FALSE
      )
    )
  })


  # return selected gene
  reactive({
    filter(genes(), entrez == input$gene)
  })
}
