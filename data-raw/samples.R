# 1KG Sample Metadata
# Create a list of variables containing unique levels in each

library(tiledb)
library(usethis)


# download ----------------------------------------------------------------
samples_array <- tiledb::tiledb_array(
  uri = "s3://genomic-datasets/biological-databases/data/tables/sample",
  as.data.frame = TRUE,
  is.sparse = FALSE,
  attrs = c("sampleuid", "pop", "super_pop", "gender")
)

tbl_samples <- samples_array[]


# filter ------------------------------------------------------------------
sample_metadata <- subset(
  tbl_samples,
  select =
  -c(`__tiledb_rows`, sampleuid)
)

sample_metadata <- lapply(sample_metadata, unique)


# export ------------------------------------------------------------------
usethis::use_data(sample_metadata, internal = TRUE, overwrite = TRUE)
