
sampleFilterUI <- function(id) {
  ns <- shiny::NS(id)
  shiny::tagList(

    shiny::selectizeInput(
      inputId = ns("gender"),
      label = "Gender",
      multiple = FALSE,
      selected = "female",
      choices = c("Any", sample_metadata$gender)
    ),

    shiny::selectizeInput(
      inputId = ns("population"),
      label = "Population",
      multiple = FALSE,
      selected = "GBR",
      choices = c("Any", sample_metadata$pop)
    )

  )
}
