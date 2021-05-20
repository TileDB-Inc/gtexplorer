gtexplorer_theme <- function() {
  bslib::bs_add_rules(
    bslib::bs_theme(
      version = 4,
      primary = "#3190ff",
      base_font = bslib::font_google("Inter")
    ),
    rules = sass::sass_file(
      system.file("assets/custom.scss", package = "gtexplorer")
    )
  )
}
