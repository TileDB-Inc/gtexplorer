# Adopted from vcr
`%||%` <- function(x, y) {
  if (is.null(x) || all(nchar(x) == 0) || length(x) == 0) y else x
}

#' Shortcut for constructing a URL path from components
#' Also removes double forward slashes.
#' @param ... character vectors with path components
#' @noRd
url_path <- function(...) {
  paste0(list(...), collapse = "/")
}
