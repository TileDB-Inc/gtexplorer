vcf_params <- list(
  uri = "tiledb://TileDB-Inc/vcf-1kg-phase3",
  attrs = c(
    "sample_name",
    "contig",
    "pos_start",
    "pos_end",
    "fmt_GT",
    "query_bed_start",
    "query_bed_end"
  ),
  regions = list("13:32928998-32929425"),
  region_partition = c(0, 1),
  samples = list("HG00097"),
  memory_budget_mb = 512L
)

cat(jsonlite::toJSON(vcf_params))


out <- TileDBClient$new()$submit_udf(namespace = "aaronwolen",
                              name = "aaronwolen/quokka3_read_gene_partition",
                              args = vcf_params)

