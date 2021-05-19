#' Quokka3
#'
#' Run the Quokka3 application in your browser.
#'
#' @inheritParams shiny::shinyApp
#'
#' @export
run_app <- function(
  onStart = NULL,
  options = list(),
  enableBookmarking = NULL) {

  shiny::shinyApp(
    ui = app_ui_navbar,
    server = app_server,
    onStart = onStart,
    options = options,
    enableBookmarking = enableBookmarking
  )
}
