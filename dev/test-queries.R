library(tiledb)

array_uri <- "s3://genomic-datasets/biological-databases/data/tables/gtex-analysis-rnaseqc-gene-tpm"


tiledb::tiledb_stats_enable()

tdb_genes <- tiledb::tiledb_array(
  array_uri,
  query_type = "READ",
  is.sparse = TRUE,
  as.data.frame = TRUE,
  attrs = "tpm"
)




tdb_genes["ENSG00000227232.5",]
