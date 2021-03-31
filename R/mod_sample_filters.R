
sampleFilterUI <- function(id) {
  ns <- shiny::NS(id)
  shiny::tagList(

    shiny::selectizeInput(
      inputId = ns("gender"),
      label = "Gender",
      multiple = FALSE,
      choices = c("Any", sample_metadata$gender)
    ),

    shiny::selectizeInput(
      inputId = ns("population"),
      label = "Population",
      multiple = FALSE,
      choices = c("Any", sample_metadata$pop)
    )

  )
}
