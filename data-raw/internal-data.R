# Create internal data objects required for the UI

library(GenomeInfoDb)
library(tiledb)
library(usethis)
library(purrr)
library(stringr)

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

tbl_samples <- subset(
  samples_array[],
  select = -`__tiledb_rows`
)

# Synthetic pairings of sample IDs and HPOs -------------------------------
samplehpopair_array <- tiledb::tiledb_array(
  uri = "s3://genomic-datasets/biological-databases/data/tables/samplehpopair",
  as.data.frame = TRUE,
  is.sparse = FALSE
)

tbl_samplehpopair <- subset(samplehpopair_array[], select = -`__tiledb_rows`)

# Human Phenotype Ontology data -------------------------------------------
# Create a character vector of HPO IDs indexed by their term names

hpoterms_array <- tiledb::tiledb_array(
  uri = "s3://genomic-datasets/biological-databases/data/tables/hpoterms",
  as.data.frame = TRUE,
  is.sparse = FALSE,
  attrs = c("hpoid", "hponame")
)

tbl_hpoterms <- subset(hpoterms_array[], select = -`__tiledb_rows`)

# filter for terms actually assigned to samples
stopifnot(anyDuplicated(tbl_hpoterms$hponame) == 0)
stopifnot(anyDuplicated(tbl_hpoterms$hpoid) == 0)

tbl_hpoterms <- subset(
  tbl_hpoterms,
  hponame != "All" & hpoid %in% unique(tbl_samplehpopair$hpoid)
)

tbl_hpoterms <- tbl_hpoterms[order(tbl_hpoterms$hponame), ]


# VEP Consequences --------------------------------------------------------
# vep_array <- tiledb::tiledb_array(
#   uri = "s3://genomic-datasets/biological-databases/data/tables/vepvariantannotation",
#   as.data.frame = TRUE,
#   is.sparse = TRUE,
#   attrs = "consequence"
# )

# tbl_veps <- vep_array[]

tbl_veps <- readr::read_csv(
  "/Users/aaronwolen/Documents/tiledb/projects/biological-databases/data/tables/public.vepvariantannotation.csv.gz"
)

vep_consequences <- str_subset(unique(tbl_veps$consequence), fixed("&"), negate = TRUE)


# export ------------------------------------------------------------------

usethis::use_data(
  tbl_hpoterms,
  tbl_samplehpopair,
  tbl_samples,
  supported_genomes,
  vep_consequences,
  internal = TRUE,
  overwrite = TRUE
)
