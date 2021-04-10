"""
Example:
import tiledb.cloud

out = tiledb.cloud.udf.exec(
    name = "TileDB-Inc/vcf_annotation_example",
    task_name = "Quokka3QueryRegionTest",
    array_uri = "tiledb://TileDB-Inc/vcf-1kg-phase3",
    attrs = ["sample_name", "contig", "pos_start", "pos_end", "query_bed_start", "query_bed_end"],
    gene_name = "DRD2",
    consequence = "missense_variant",
    vcf_parallelization = 5,
    samples = ["HG00100","HG00125","HG00127","HG00130","HG00137","HG00154","HG00235","HG00236","HG00254","HG00257","HG00262"],
    memory_budget = 512
)
"""

def vcf_annotation_example(
    gene_name=None,
    array_uri=None,
    consequence=None,
    attrs=None,
    memory_budget=512,
    vcf_parallelization=1,
    samples=None
):
    import tiledb
    import tiledb.cloud
    import tiledbvcf
    import os
    from tiledb.cloud.compute import Delayed, DelayedSQL

    tiledb.cloud.login(
        host=os.environ["TILEDB_REST_SERVER_ADDRESS"],
        token=os.environ["TILEDB_REST_TOKEN"],
    )


    print(
      "Parameters:\n"
      f"...gene_name={gene_name}\n"
      f"...array_uri={array_uri}\n"
      f"...consequence={consequence}\n"
      f"...attrs={attrs}\n"
      f"...memory_budget={memory_budget}\n"
      f"...vcf_parallelization={vcf_parallelization}\n"
      f"...samples={0 if samples is None else len(samples)}\n"
    )

    # For this demo we will look at the BRCA2 gene
    # gene_name = 'KCNQ2'

    # VEP consequence (e.g., missense_variant, stop_gained, etc)
    # consequence = "missense_variant"

    # TileDB-VCF dataset containing variants from the 1000 Genomes Project phase 3 release
    # array_uri = "tiledb://TileDB-Inc/vcf-1kg-phase3"

    # VCF attributes to retrieve
    if attrs is None:
        attrs = [
            "sample_name",
            "contig",
            "pos_start",
            "pos_end",
            # "fmt_GT",
            "query_bed_start",
            "query_bed_end",
        ]

    ensembl_query = """SELECT
                      ensemblexon.chrom chrom,
                      ensemblexon.pos_start pos_start,
                      ensemblexon.pos_end pos_end,
                      ensemblgene.gene_id,
                      ensemblgene.gene_name,
                      ensemblgene.strand,
                      ensemblexon.transcript_id,
                      ensemblexon.exon_number
                    FROM `tiledb://TileDB-Inc/ensemblgene_sparse` ensemblgene
                    LEFT JOIN `tiledb://TileDB-Inc/ensemblexon_sparse` ensemblexon ON ensemblexon.gene_id = ensemblgene.gene_id
                    WHERE ensemblgene.gene_name = '{}'""".format(
        gene_name
    )

    # Varient annotation
    vep_query = """SELECT vepvariantannotation.chrom,
      vepvariantannotation.pos_start,
      vepvariantannotation.pos_end,
      vepvariantannotation.ref,
      vepvariantannotation.alt,
      vepvariantannotation.consequence,
      vepvariantannotation.codons,
      vepvariantannotation.aminoacids
    FROM `tiledb://TileDB-Inc/vepvariantannotation` vepvariantannotation
    WHERE gene_id = (
        select gene_id
        from `tiledb://TileDB-Inc/ensemblgene_sparse`
        WHERE gene_name = '{}')""".format(
        gene_name
    )

    if consequence is not None:
      if isinstance(consequence, str):
        vep_query += f" AND consequence = '{consequence}'"
      else:
        vep_query +=  "AND consequence IN (" + ','.join(f'"{i}"' for i in consequence) + ")"


    def build_regions(ensembl_df):
        """
        Helper function to convert chromosome, start/end to proper region syntax
        """
        import pandas

        regions = []
        for row in ensembl_df.itertuples():
            regions.append(f"{row.chrom}:{row.pos_start}-{row.pos_end}")

        return pandas.unique(regions).tolist()

    def read_gene_partition(
        uri, attrs, regions, region_partition, samples, memory_budget_mb
    ):
        """
        This function will issue the VCF read
        """
        import pyarrow as pa
        import pandas

        # print(f"Reading partition {region_partition[0]} of {region_partition[1]}")

        cfg = tiledbvcf.ReadConfig(
            region_partition=region_partition, memory_budget_mb=memory_budget_mb,
        )
        ds = tiledbvcf.Dataset(uri, mode="r", cfg=cfg, stats=True)

        if isinstance(samples, pandas.DataFrame):
            samples = samples.values.flatten()

        res = [ds.read_arrow(attrs=attrs, regions=regions, samples=samples)]
        count = 0
        while not ds.read_completed():
            res.append(ds.continue_read_arrow())
            count += 1

        table = pa.concat_tables(res, promote=False)

        # print(f"Retrieved {df.shape[0]} records (DataFrame = {df.memory_usage().sum() / 1e+6}Mb)")
        print(f"Had {count} incomplete queries")
        print(f"Retrieved table:\n---\n{table}\n---\n")

        return table

    # This lets us combine multiple VCF results into one arrow table
    def combine_vcf_results(df_list):
        import pyarrow as pa

        print(f"Input list contains {len(df_list)} items")
        return pa.concat_tables([x for x in df_list if x is not None])

    # This function will join the ensemble data with the variant information
    def annotate_variants(vcf_data, ensembl_df, vep_df):
        import pyarrow as pa

        if isinstance(vcf_data, pa.Table):
            vcf_data = vcf_data.to_pandas()

        # The VCF bed start is zero indexed but ensembl is 1 index, so shift by one
        vcf_data["query_bed_start"] += 1

        # Fixup ensembl, need to force pandas to treat the chromosome as a string
        ensembl_df = ensembl_df.astype({"chrom": "str"})

        results = vcf_data.merge(
            ensembl_df.drop_duplicates().rename(
                columns={
                    "pos_start": "query_bed_start",
                    "pos_end": "query_bed_end",
                    "chrom": "contig",
                }
            ),
            how="left",
        )

        # Add VEP data
        results = results.merge(
            vep_df.rename(columns={"chrom": "contig"}).astype({"contig": "str"}),
            how="inner",
        )

        return results

    # tiledb.cloud.client.client.retry_mode("forceful")
    delayed_veps = DelayedSQL(vep_query, name="VEPs")
    delayed_ensembl = DelayedSQL(ensembl_query, name="Regions")
    delayed_regions = Delayed(build_regions, name="Build_Regions", local=True)(
        delayed_ensembl
    )

    delayed_reads = []
    for p in range(vcf_parallelization):
        delayed_reads.append(
            Delayed(
                read_gene_partition,
                name=f"Query region {p+1}",
                local=False,
                result_format=tiledb.cloud.UDFResultType.ARROW,
            )(
                array_uri,
                attrs,
                delayed_regions,
                (p, vcf_parallelization),
                samples,
                memory_budget,
            )
        )

    delayed_vcf_results = Delayed(combine_vcf_results, name="Combine", local=True)(
        delayed_reads
    )

    delayed_results = Delayed(annotate_variants, name="Annotate_Variants", local=True)(
        delayed_vcf_results, delayed_ensembl, delayed_veps
    )

    results = delayed_results.compute()
    return results.to_json(orient = "table", index = False)
