# Create internal data objects required for the UI

library(GenomeInfoDb)
library(rtracklayer)
library(usethis)
library(purrr)

# Genome Chromosomes ------------------------------------------------------
# Create tables with chromosome lengths for each supported genome version
# names(GenomeInfoDb:::SUPPORTED_UCSC_GENOMES)

genomes <- c(
  grch37 = "hg19",
  grch38 = "hg38"
)

supported_genomes <- genomes %>%
  map(~ GenomeInfoDb::Seqinfo(genome = .x)) %>%
  map(GenomeInfoDb::seqlengths)


# gencode gene annotations ------------------------------------------------

gtf <- rtracklayer::import(
  "https://storage.googleapis.com/gtex_analysis_v8/reference/gencode.v26.GRCh38.genes.gtf"
)

tbl_genes <- gtf %>%
  as.data.frame() %>%
  subset(
    type == "gene",
    select = c("gene_id", "gene_name")
  )


# export ------------------------------------------------------------------

usethis::use_data(
  tbl_genes,
  supported_genomes,
  internal = TRUE,
  overwrite = TRUE
)
