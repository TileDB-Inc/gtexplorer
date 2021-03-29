# Create tables with chromosome lengths for each supported genome version
# names(GenomeInfoDb:::SUPPORTED_UCSC_GENOMES)
library(GenomeInfoDb)
library(purrr)
library(usethis)

genomes <- c(
  grch37 = "hg19",
  grch38 = "hg38"
)

available_contigs <- genomes %>%
  map(~ GenomeInfoDb::Seqinfo(genome = .x)) %>%
  map(GenomeInfoDb::seqlengths)

dir.create("data", showWarnings = FALSE)
save(available_contigs, file = "data/available_contigs.rda", compress = "bzip2")

