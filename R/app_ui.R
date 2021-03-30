#' Application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#' @import shiny
#' @noRd

app_ui <- function(request) {
  shiny::tagList(

    shiny::fluidPage(
      shiny::titlePanel("Quokka TileDB"),
      shiny::sidebarPanel(
        id = "setup",

        shiny::textInput(
          inputId = "uri_vcf",
          label = "TileDB-VCF Dataset URI",
          value = "tiledb://TileDB-Inc/vcf-1kg-phase3",
          placeholder = "e.g., tiledb://TileDB-Inc/vcf-1kg-phase3"
        ),

        shiny::selectInput(
          inputId = "genome",
          label = "Genome Build",
          choices = c("GRCh37", "GRCh38")
        ),

        geneSelectorUI("gene_selector"),
        # regionSelectorUI("region_selector"),

        shiny::h4("Filter Samples"),
        hpoSelectorUI("hpo_selector"),


        shiny::checkboxGroupInput(
          inputId = "modules",
          "Family Role",
          c(
            "Proband",
            "Sibling",
            "Mother",
            "Other",
            "Father",
            "Unknown"
          ),
          inline = FALSE
        ),

        shiny::h4("Filters"),
        shiny::checkboxInput(
          inputId = "coding_only",
          label = "Restrict to coding changes",
          value = FALSE
        ),

        shiny::actionButton("run_query", "Search")
      ),

      shiny::mainPanel(
        shinycssloaders::withSpinner(
          DT::dataTableOutput("table_results")
        )
      )
    )
  )
}
