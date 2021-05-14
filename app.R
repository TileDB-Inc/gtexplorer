# options(repos = BiocManager::repositories())
# rsconnect::deployApp(
#   appName = "gtexplorer",
#   appFiles = c(
#     ".Renviron",
#     "app.R",
#     "DESCRIPTION",
#     "LICENSE",
#     "LICENSE.md",
#     "man",
#     "NAMESPACE",
#     "R",
#     "shiny-gtex.Rproj"
#   )
# )

pkgload::load_all(export_all = FALSE, helpers = FALSE, attach_testthat = FALSE)
gtexplorer::run_app()
