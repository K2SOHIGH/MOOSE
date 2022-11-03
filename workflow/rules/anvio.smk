
rule anvio_merge_profile:
    output:
        os.path.join(RESDIR , SAMPLES_DIR , "{sample}" , "AnvioMAgic" , "{assembly}" , "MERGED_PROFILES", "PROFILE.db" ),
    input:
        expand(
            os.path.join(RESDIR , SAMPLES_DIR , "{{sample}}" , "AnvioMAgic" , "{{assembly}}" , "PROFILES", "{bam}" , "PROFILE.db" ),
            bam = BAMS[wildcards.sample]
        )        
    params:
        outdir =  os.path.join(RESDIR , SAMPLES_DIR , "{sample}" , "AnvioMAgic" , "{assembly}" , "MERGED_PROFILES"),
    threads:
        10
    conda:
        "../envs/anvio-7.1.yaml"
    shell:
        "anvi-merge "
        "-S {wildcards.sample} "
        "-c {input.db} "
        "-o {params.outdir} {input} "


rule anvio_profile:
    output:
        os.path.join(RESDIR , SAMPLES_DIR , "{sample}" , "AnvioMAgic" , "{assembly}" , "PROFILES", "{bam}" , "PROFILE.db" ),
    input:
        bam = lambda wildcards: BAMS[wildcards.sample][wildcards.bam]
        db = os.path.join(RESDIR , SAMPLES_DIR , "{sample}" , "AnvioMAgic" , "{assembly}" , "CONTIGS.db"),
        f1 = os.path.join(RESDIR , SAMPLES_DIR , "{sample}" , "AnvioMAgic" , "{assembly}" , "scg.done"),
        f2 = os.path.join(RESDIR , SAMPLES_DIR , "{sample}" , "AnvioMAgic" , "{assembly}" , "cogs.done"),
    params:
        os.path.join(RESDIR , SAMPLES_DIR , "{sample}" , "AnvioMAgic" , "{assembly}" , "PROFILES", "{bam}"),
    threads:
        10
    conda:
        "../envs/anvio-7.1.yaml"
    shell:
        "anvi-profile -i {input.bam} "
        "-W "
        "-c {input.db} "
        "-T {threads} "
        "--output-dir {params.outdir} "
        "--sample-name {wildcards.mapper} "
        "--cluster-contigs"

rule anvio_import_taxo:
    output:
        os.path.join(RESDIR , SAMPLES_DIR , "{sample}" , "AnvioMAgic" , "{assembly}" , "scg.done"),
    input:
        os.path.join(RESDIR , SAMPLES_DIR , "{sample}" , "AnvioMAgic" , "{assembly}" , "CONTIGS.db"),
        DBFILE,
    params:
        mode = "--metagenome-mode" if config["META"] else "",
    conda:
        "../envs/anvio-7.1.yaml"
    shell:
        "anvi-estimate-scg-taxonomy {params.mode} -c {input[0]} && touch {output}"


rule anvio_cogs:
    output:
        os.path.join(RESDIR , SAMPLES_DIR , "{sample}" , "AnvioMAgic" , "{assembly}" , "cogs.done"),
    input:
        os.path.join(RESDIR , SAMPLES_DIR , "{sample}" , "AnvioMAgic" , "{assembly}" , "CONTIGS.db"),
        DBFILE,
    threads:
        10
    conda:
        "../envs/anvio-7.1.yaml"
    shell:
        "anvi-run-ncbi-cogs -c {input[0]} --num-threads {threads} && touch {output}"


rule anvio_contig_db:
    output:
        os.path.join(RESDIR , SAMPLES_DIR , "{sample}", "{assembly_type}" , "{assembler}" , "AnvioMAgic" , "CONTIGS.db"),
    input:
        os.path.join( 
            RESDIR , SAMPLES_DIR,  "{sample}", "{assembly_type}" , "{assembler}" ,  "final_assembly.fasta"
        ),
    conda:
        "../envs/anvio-7.1.yaml"
    threads:
        10
    shell:
        "anvi-gen-contigs-database -T {threads} -f {input} -o {output} -n '{wildcards.sample}_{wildcards.assembler}' && anvi-run-hmms -c {input} --just-do-it"



rule anvio_setup_target:
    output:
        DBFILE,
    input:
        expand(
            os.path.join(RESDIR, "anvio-{db}-setup.done"), db = ["scg","cogs","keggs","pfams"]
        )
    params:
        DBCONFIG = dbs,
    run:
        if params.DBCONFIG:
            yaml.dump(params.DBCONFIG,open(str(output),'w'))


rule anvio_setup:
    output:
        temp(os.path.join(RESDIR, "anvio-scg-setup.done")),
        temp(os.path.join(RESDIR, "anvio-cogs-setup.done")),
        temp(os.path.join(RESDIR, "anvio-pfams-setup.done")),
        temp(os.path.join(RESDIR, "anvio-keggs-setup.done")),
    params:        
        # IS_DBFILE = IS_DBFILE,
        PFAMDIR = "--pfam-data-dir {}".format(os.path.join(config["DBDIR"],"PFAM")) if config["DBDIR"] else "",
        SCGDIR  = "--scgs-taxonomy-data-dir {}".format(os.path.join(config["DBDIR"],"SCG")) if config["DBDIR"] else "",
        COGDIR  = "--cog-data-dir {}".format(os.path.join(config["DBDIR"],"COGS")) if config["DBDIR"] else "",
        KEGGDIR = "--kegg-data-dir {}".format(os.path.join(config["DBDIR"],"KEGGS")) if config["DBDIR"] else "",
    conda:
        "../envs/anvio-7.1.yaml"
    shell:
        """
            anvi-setup-scg-taxonomy {params.SCGDIR} -T {threads} && touch {output[0]} || true ;
            anvi-setup-ncbi-cogs    {params.COGDIR} -T {threads} && touch {output[1]} || true ;
            anvi-setup-pfams        {params.PFAMDIR} && touch {output[2]} || true ;
            anvi-setup-kegg-kofams  {params.KEGGDIR} && touch {output[3]} || true ;               
        """