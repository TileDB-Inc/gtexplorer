#' Open TileDB GTEx Array
#'
#' @param uri Location of TileDB array to open
#' @param attrs Array attributes to include
#' @param verbose Logical, print message with array's location
#' @returns `tiledb_array` object
#' @importFrom tiledb tiledb_array
#' @export

open_gtex_array <- function(
  uri,
  attrs,
  verbose = FALSE) {
  if (verbose) {
    message(sprintf("Opening array from: '%s'", uri))
  }

  tiledb::tiledb_array(
    uri,
    is.sparse = TRUE,
    attrs = attrs,
    return_as = "tibble"
  )
}
