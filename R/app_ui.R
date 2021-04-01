#' Application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#' @import shiny
#' @noRd

app_ui <- function(request) {
  shiny::tagList(
    shiny::navbarPage(
      theme = bslib::bs_theme(
        primary = "#001f75",
        version = 3
      ),
      title = "Quokka TileDB",
      shiny::tabPanel(
        "Home",
        shiny::sidebarLayout(
          sidebarPanel = shiny::sidebarPanel(
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
            sampleFilterUI("sample_filter"),

            shiny::h4("Variant Filters"),
            shiny::checkboxInput(
              inputId = "coding_only",
              label = "Restrict to coding changes",
              value = TRUE
            ),
            shiny::selectizeInput(
              inputId = "consequence",
              label = "VEP Consequence",
              choices = vep_consequences,
              selected = "missense_variant",
              multiple = TRUE,
              options = list(
                placeholder = "Select consequence",
                maxItems = 3,
                plugins = list("remove_button")
              )
            ),

            shiny::actionButton("run_query", "Search"),
            shiny::downloadButton("reset", "Reset"),
            shiny::downloadButton("download_results", "Download")
          ),

          mainPanel = shiny::mainPanel(
            shinycssloaders::withSpinner(DT::dataTableOutput("table_results"))
          )
        ),

      )
    )
  )
}
