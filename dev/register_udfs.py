import tiledb.cloud
from quokka3_udfs import vcf_annotation_example

namespace = "TileDB-Inc"
udf_name = "vcf_annotation_example"
udf_func = vcf_annotation_example

try:
    tiledb.cloud.udf.info(namespace=namespace, name=udf_name)
except tiledb.cloud.tiledb_cloud_error.TileDBCloudError:
    print(f"Registering new UDF: {udf_name}")
    tiledb.cloud.udf.register_udf(
        func=udf_func,
        name=udf_name,
        namespace=namespace,
        type="generic",
        include_source_lines=False,
    )
else:
    print(f"Update existing UDF: {udf_name}")
    tiledb.cloud.udf.update_udf(
        func=udf_func, name=udf_name, namespace=namespace, type="generic",
    )

tiledb.cloud.udf.update_udf(
  func=vcf_annotation_example, name=udf_name, namespace=namespace, type="generic",
)




tiledb.cloud.udf.register_udf(
    func=udf_func,
    name="vcf_annotation_example",
    namespace=namespace,
    type="generic",
    include_source_lines=False,
)
