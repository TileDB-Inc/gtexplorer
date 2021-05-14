# Create internal data objects required for the UI

library(rtracklayer)
library(readr)
library(usethis)
library(purrr)


# gencode gene annotations ------------------------------------------------
# ~200 gene_names are associated with multiple gene_ids

gtf <- rtracklayer::import(
  "https://storage.googleapis.com/gtex_analysis_v8/reference/gencode.v26.GRCh38.genes.gtf"
)

tbl_genes <- gtf %>%
  as.data.frame() %>%
  subset(
    type == "gene",
    select = c("gene_id", "gene_name")
  )


# gtex sample annotations -------------------------------------------------

tbl_samples <- readr::read_tsv(
  "https://storage.googleapis.com/gtex_analysis_v8/annotations/GTEx_Analysis_v8_Annotations_SampleAttributesDS.txt",
  col_types = cols(SMGTC = col_character())
)

tbl_samples <- tbl_samples %>%
  subset(
    select = c("SAMPID", "SMTS", "SMTSD")
  )

names(tbl_samples)[1] <- "sample"


# export ------------------------------------------------------------------

usethis::use_data(
  tbl_samples,
  tbl_genes,
  internal = TRUE,
  overwrite = TRUE
)
