gtexplorer_theme <- function() {
  bslib::bs_add_rules(
    bslib::bs_theme(
      version = 4,
      primary = "#4d9fff",
      # decrease color-contrast ratio to keep text white with brand color
      "min-contrast-ratio" = 2,
      base_font = bslib::font_google("Inter")
    ),
    rules = sass::sass_file(
      system.file("assets/custom.scss", package = "gtexplorer")
    )
  )
}
