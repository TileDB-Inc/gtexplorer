
regionSelectorUI <- function(id) {
  ns <- NS(id)
  tagList(
    selectizeInput(
      inputId = ns("contig"),
      label = "Chromosome",
      choices = c(`Database not loaded...` = "")
    )
  )
}


# param contigs: vector of named chromosome lengths
regionSelector <- function(input, output, session, contigs) {

  observeEvent(contigs(), {
    req(contigs())
    cat("\n\nUpdating contigs in search box...\n", file = stderr())
    updateSelectizeInput(
      session,
      inputId = "contig",
      choices = names(contigs()),
      selected = c(Search = ""),
      server = TRUE,
      options = list(
        placeholder = "Enter chromosome",
        openOnFocus = FALSE
      )
    )
  })

  reactive({
    input$contig
  })
}
