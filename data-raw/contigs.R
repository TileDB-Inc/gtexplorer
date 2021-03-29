# Create tables with chromosome lengths for each supported genome version
# names(GenomeInfoDb:::SUPPORTED_UCSC_GENOMES)
library(GenomeInfoDb)
library(purrr)
library(usethis)

genomes <- c(
  grch37 = "hg19",
  grch38 = "hg38"
)

supported_genomes <- genomes %>%
  map(~ GenomeInfoDb::Seqinfo(genome = .x)) %>%
  map(GenomeInfoDb::seqlengths)

usethis::use_data(supported_genomes, internal = TRUE)
