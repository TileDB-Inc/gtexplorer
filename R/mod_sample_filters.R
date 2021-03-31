
sampleFilterUI <- function(id) {
  ns <- shiny::NS(id)
  shiny::tagList(

    shiny::selectInput(
      inputId = ns("gender"),
      label = "Gender",
      multiple = FALSE,
      choices = c("all", sample_metadata$gender)
    ),

    shiny::selectInput(
      inputId = ns("population"),
      label = "Population",
      multiple = FALSE,
      choices = sample_metadata$pop
    )

  )
}
