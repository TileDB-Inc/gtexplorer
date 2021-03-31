#' TileDB Cloud API Client
#'
#' @description Minimal client to submit generic UDFs.
#'
#' @section Authentication: requires an authentication token to
#'   communicate with TileDB Cloud.
#'
#' @export
#' @examples
#' \dontrun{
#' cli <- TileDBClient$new()
#' cli
#'
#' # retrieve user profile
#' cli$user()
#' }

TileDBClient <- R6::R6Class(
  "TileDBClient",
  public = list(
    #' @field url TileDB Cloud API URL
    url = NULL,
    #' @field token Access token
    token = NULL,

    #' @description Create a new `TileDBClient`
    #' @param url Override the default TileDB Cloud API URL
    #' @param token TileDB REST API token. This is optional if the environment
    #'   variable `TILEDB_REST_TOKEN` is defined, but the `token` argument takes
    #'   precedence if both are defined.
    initialize = function(token = NULL, url = NULL) {

      self$url <- "https://api.tiledb.com"
      self$token <- token %||% Sys.getenv("TILEDB_REST_TOKEN")
      private$check_token()

      headers <- list(
        `X-TILEDB-REST-API-KEY` = self$token,
        `Content-Type` = "application/json"
      )

      private$client <- crul::HttpClient$new(
        url = self$url,
        headers = headers,
        opts = list(
          encode = "json"
        )
      )
    },

    #' @description print method for the `TileDBClient` class
    #' @param x self
    #' @param ... ignored
    print = function(...) {
      cat("<tiledbcloud client>", sep = "\n")
      cat(paste0("  url: ", self$url), sep = "\n")
      cat(paste0("  token: ", substr(self$token, 1, 5), "..."), sep = "\n")
      invisible(self)
    },

    #' @description Retrieve TileDB Cloud user profile
    user = function() {
      private$request(path = "user")
    },

    #' @description Retrieve information for a registered UDF
    #' @param namespace Namespace of a user or organization
    #' @param name Registered UDF name
    udf_info = function(namespace, name) {
      stopifnot(is.character(namespace))
      stopifnot(is.character(name))
      private$request(path = url_path("udf", namespace, name))
    },

    #' @description Submit a generic UDF
    #' @param namespace Namespace of a user or organization
    #' @param name Registered UDF name
    #' @param args List of arguments passed to the UDF
    submit_udf = function(namespace, name, args = NULL) {
      stopifnot(is.character(namespace))
      stopifnot(is.character(name))

      body = list(
        udf_info_name = name,
        result_format = "json"
      )

      if (!is.null(args)) {
        stopifnot(is.list(args))
        body$argument <- jsonlite::toJSON(args, auto_unbox = TRUE, null = "null")
      }

      private$request(
        method = "post",
        path = url_path("udfs/generic", namespace),
        body = body
      )
    }

  ),

  private = list(
    client = NULL,

    check_token = function() {
      if (!nzchar(self$token)) {
        stop(
          "No TileDB Cloud token detected.\n",
          "A valid token must be passed to the `token` argument or the ",
          "`TILEDB_REST_TOKEN` environment variable.",
          call. = FALSE
        )
      }
    },

    request = function(method = "get", path = "", query = list(), body = NULL) {
      cli <- private$client
      path <- paste0("/v1/", path)
      resp <- cli$verb(method, path, query = query, body = body, encode = "json")

      if (resp$status_code >= 400) {
        cat(jsonlite::fromJSON(resp$parse("UTF-8"))$message)
      }

      if (!resp$success()) fauxpas::http(resp, behavior = "stop")
      jsonlite::fromJSON(resp$parse("UTF-8"), simplifyVector = FALSE)
    }
  )
)
