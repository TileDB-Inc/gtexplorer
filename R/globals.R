#' Declare global variables
#'
#' Global variables:
#' - `supported_genomes` a named list indexed by supported genome versions
#'   (e.g., `grch37`). Each list element contains a named integer vector where
#'   keys are contig names and values are contig lengths.
#'
#' @noRd
#' @importFrom utils globalVariables

utils::globalVariables(
  c("supported_genomes")
)
