def vcf_annotation_example(
    gene_name=None,
    array_uri=None,
    consequence=None,
    attrs=None,
    memory_budget=512,
    vcf_parallelization=1,
    pop=None,
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
            "fmt_GT",
            "query_bed_start",
            "query_bed_end",
        ]

    # Sample query
    sample_query = (
        "select sampleuid from `tiledb://TileDB-Inc/vcf-1kg_sample_phenotype`"
    )
    if pop is not None:
        sample_query += f" WHERE pop = '{pop}'"

    hpo_query = """SELECT
        samplehpopair.sampleuid,
        samplehpopair.hpoid,
        hpoterms.hpodef
        FROM `tiledb://TileDB-Inc/vcf-1kg_sample_phenotype` 1kg_sample_phenotype
        LEFT JOIN `tiledb://TileDB-Inc/samplehpopair` samplehpopair ON samplehpopair.sampleuid = 1kg_sample_phenotype.sampleuid
        LEFT JOIN `tiledb://TileDB-Inc/hpoterms` hpoterms ON hpoterms.hpoid = samplehpopair.hpoid
        WHERE hpoterms.hpodef != 'NA'
        """
    if pop is not None:
        hpo_query += f" AND pop = '{pop}'"

    ensembl_query = """SELECT
                      ensemblexon.chrom chrom,
                      ensemblexon.pos_start pos_start,
                      ensemblexon.pos_end pos_end,
                      ensemblgene.gene_id,
                      ensemblgene.gene_name,
                      ensemblgene.strand,
                      ensemblexon.exon_id,
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
      vepvariantannotation.consequence,
      vepvariantannotation.codons,
      vepvariantannotation.aminoacids,
      vepvariantannotation.sift,
      vepvariantannotation.startpos_cds,
      vepvariantannotation.stoppos_cds,
      vepvariantannotation.startpos_protein,
      vepvariantannotation.stoppos_protein
    FROM `tiledb://TileDB-Inc/vepvariantannotation` vepvariantannotation
    WHERE gene_id = (
        select gene_id
        from `tiledb://TileDB-Inc/ensemblgene_sparse`
        WHERE gene_name = '{}')""".format(
        gene_name
    )
    if consequence is not None:
        vep_query += f" AND consequence = '{consequence}'"

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

    # This function will join the VCF variants with the sample annotations
    def annotate_samples(vcf_data, sample_df):
        import pyarrow as pa

        if isinstance(vcf_data, pa.Table):
            vcf_data = vcf_data.to_pandas()

        return vcf_data.merge(
            sample_df.rename(columns={"sampleuid": "sample_name"}), how="inner"
        )

    # Retrieve specified samples
    delayed_samples = DelayedSQL(sample_query, name="Samples")

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
                delayed_samples,
                memory_budget,
            )
        )

    delayed_vcf_results = Delayed(combine_vcf_results, name="Combine", local=True)(
        delayed_reads
    )

    delayed_hpo = DelayedSQL(
        hpo_query,
        name="HPO",
        init_commands=[
            "SET mytile_reopen_for_every_query=0, mytile_compute_table_records=1"
        ],
    )
    delayed_samples = Delayed(annotate_samples, name="Annotate_Samples")(
        delayed_vcf_results, delayed_hpo
    )

    delayed_results = Delayed(annotate_variants, name="Annotate_Variants", local=True)(
        delayed_samples, delayed_ensembl, delayed_veps
    )

    results = delayed_results.compute()
    return results.to_json()
