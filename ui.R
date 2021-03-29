fluidPage(
  shinyjs::useShinyjs(),

  titlePanel("Quokka TileDB"),
    wellPanel(
      id = "setup",

      shiny::textInput(
        inputId = "uri_vcf",
        label = "TileDB-VCF Dataset URI",
        value = "tiledb://TileDB-Inc/vcf-1kg-phase3-data",
        placeholder = "e.g., tiledb://TileDB-Inc/vcf-1kg-phase3-data"
      ),

      selectInput(
        inputId = "genome",
        label = "Genome Build",
        choices = c("GRCh37", "GRCh38")
      ),

      geneSelectorUI("gene_selector"),
      regionSelectorUI("gene_selector"),

      checkboxGroupInput(
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
        inline = TRUE
      ),

      actionButton("run_query", "Search")
    ),


    shiny::verbatimTextOutput("params"),
    shiny::verbatimTextOutput("test")

    # geneDetailsTableUI("gene_details"),
    # genePlotUI("gene_plot"),
    # entrezDetailsUI("entrez_details"),
    # gtexPlotUI("gtex_plot"),
    # uiOutput("section_generif")
)
