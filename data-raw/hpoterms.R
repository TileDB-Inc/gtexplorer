# Human Phenotype Ontology data
# Create a character vector of HPO IDs indexed by their term names

library(tiledb)
library(usethis)


# download ----------------------------------------------------------------
hpoterms_array <- tiledb::tiledb_array(
  uri = "s3://genomic-datasets/biological-databases/data/tables/hpoterms",
  as.data.frame = TRUE,
  is.sparse = FALSE,
  attrs = c("hpoid", "hponame")
)

tbl_hpoterms <- hpoterms_array[]


# filter ------------------------------------------------------------------
stopifnot(anyDuplicated(tbl_hpoterms$hponame) == 0)
stopifnot(anyDuplicated(tbl_hpoterms$hpoid) == 0)

tbl_hpoterms <- subset(tbl_hpoterms, hponame != "All")


# export ------------------------------------------------------------------
hpoterms <- setNames(tbl_hpoterms$hpoid, tbl_hpoterms$hponame)
usethis::use_data(hpoterms, internal = TRUE, overwrite = TRUE)
