.onAttach <- function(libname, pkgname) {
  shiny::addResourcePath("www", system.file("www", package = "gtexplorer"))
}

.onUnload <- function(libname, pkgname) {
  shiny::removeResourcePath("www")
}
