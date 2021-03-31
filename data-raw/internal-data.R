# Create internal data objects required for the UI

library(GenomeInfoDb)
library(tiledb)
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


# 1KG Sample Metadata -----------------------------------------------------
samples_array <- tiledb::tiledb_array(
  uri = "s3://genomic-datasets/biological-databases/data/tables/sample",
  as.data.frame = TRUE,
  is.sparse = FALSE,
  attrs = c("sampleuid", "pop", "super_pop", "gender")
)

tbl_samples <- samples_array[]

sample_metadata <- subset(
  tbl_samples,
  select = -c(`__tiledb_rows`, sampleuid)
)

sample_metadata <- lapply(sample_metadata, unique)



# Human Phenotype Ontology data -------------------------------------------
# Create a character vector of HPO IDs indexed by their term names

hpoterms_array <- tiledb::tiledb_array(
  uri = "s3://genomic-datasets/biological-databases/data/tables/hpoterms",
  as.data.frame = TRUE,
  is.sparse = FALSE,
  attrs = c("hpoid", "hponame")
)

tbl_hpoterms <- hpoterms_array[]


samplehpopair_array <- tiledb::tiledb_array(
  uri = "s3://genomic-datasets/biological-databases/data/tables/samplehpopair",
  as.data.frame = TRUE,
  is.sparse = FALSE
)

tbl_samplehpopair <- samplehpopair_array[]


# filter for terms actually assigned to samples
stopifnot(anyDuplicated(tbl_hpoterms$hponame) == 0)
stopifnot(anyDuplicated(tbl_hpoterms$hpoid) == 0)

tbl_hpoterms <- subset(
  tbl_hpoterms,
  hponame != "All" & hpoid %in% unique(tbl_samplehpopair$hpoid)
)

hpo_terms <- setNames(tbl_hpoterms$hpoid, tbl_hpoterms$hponame)


# export ------------------------------------------------------------------

usethis::use_data(
  hpo_terms,
  sample_metadata,
  supported_genomes,
  internal = TRUE,
  overwrite = TRUE
)
