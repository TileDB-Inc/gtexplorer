# rsconnect::deployApp(
#   appName = "quokka3",
#   appFiles = c(
#     "app.R",
#     "DESCRIPTION",
#     "LICENSE",
#     "LICENSE.md",
#     "man",
#     "NAMESPACE",
#     "R",
#     "rsconnect",
#     "shiny-quokka.Rproj"
#   )
# )

pkgload::load_all(export_all = FALSE, helpers = FALSE, attach_testthat = FALSE)
quokka3::run_app()
