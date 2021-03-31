# remotes::install_github("tiledb-inc/tiledb-cloud-r")
library(tiledbcloud)
library(glue)

cl <- ApiClient$new(basePath="https://api.tiledb.com/v1",
                    accessToken=Sys.getenv("TILEDB_REST_TOKEN"),
                    username=Sys.getenv("TILEDB_REST_USERNAME"),
                    password=Sys.getenv("TILEDB_REST_PASSWORD"))

api <- UserApi$new(cl)
api$apiClient$apiKeys['X-TILEDB-REST-API-KEY'] <- Sys.getenv("TILEDB_REST_TOKEN")

api$GetSession()
## -- does NOT work unless we modify R/api_client.R
res <- api$GetUser()
## Array Example

array_uri <- list(
  samples = "tiledb://TileDB-Inc/vcf-1kg_sample_phenotype"
)


# delayed sql -------------------------------------------------------------

delayed_sql <- SqlApi$new(cl)
sample_query <- SQLParameters$new(
  name = "Filter Samples",
  query = glue(
    "select sampleuid from `{array_uri$samples}`"
  )
)

delayed_sql$RunSQL("tiledb-inc", sample_query)



# registered UDF ----------------------------------------------------------
udf_namespace <- "aaronwolen"
udf_name <- "quokka3_read_gene_partition"
udf_fullname <- file.path(udf_namespace, udf_name)

vcf_params <- list(
  uri = "aaronwolen/quokka3_read_gene_partition",
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
  memory_budget_mb = 1024L
)


udf <- UDF$new(
  udf_info_name = udf_name,
  result_format = UDFResultType$new("json"),
  argument = vcf_params
)

udf_api <- UdfApi$new(cl)
udf_api$GetUDFInfo(namespace = udf_namespace, name = udf_name)


udf_result <- udf_api$SubmitGenericUDF(
  namespace = udf_namespace,
  udf = udf
)

udf_result$content


out = tiledb.cloud.udf.exec(
    name = udf_name,
    task_name = "Quokka3QueryRegion",
    uri = udf_uri,
    attrs = vcf_attrs,
    regions = udf_regions,
    region_partition = (0,1),
    samples = ["HG00097"],
    memory_budget_mb = 1024
)
