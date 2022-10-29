rule anvio_profile:
    output:
        os.path.join( RESDIR,"{sample}", "profiles", "{assembler}_profile", "PROFILE.db" ),
    input:
        bam = os.path.join( RESDIR , "{sample}" , "bam" , "{sample}_{assembler}.sorted.bam" ),
        db = os.path.join( RESDIR, "{sample}" , "anvio", "contig.{assembler}.db"),
        f1 = os.path.join(RESDIR,"{sample}","anvio","taxo.{assembler}.done"),
        f2 = os.path.join( RESDIR , "{sample}" , 'anvio', "cogs.{assembler}.done"),
    params:
        outdir =  os.path.join( RESDIR, "{sample}","anvio","{assembler}_profile" ),
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
        "--sample-name {wildcards.sample}_{wildcards.assembler} "
        "--cluster-contigs"


rule anvio_import_taxo:
    output:
        os.path.join(RESDIR,"{sample}","anvio","taxo.{assembler}.done"),
    input:
        db = os.path.join(RESDIR,"{sample}","anvio","contig.{assembler}.db"), 
        f1 = os.path.join(RESDIR,"{sample}","anvio","taxo.{assembler}.setup"),
    conda:
        "../envs/anvio-7.1.yaml"
    shell:
        "anvi-estimate-scg-taxonomy --metagenome-mode -c {input.db} && touch {output}"

rule anvio_setup_taxo:
    output:
        os.path.join(RESDIR,"{sample}","anvio","taxo.{assembler}.setup"),
    input:
        db = os.path.join(RESDIR,"{sample}","anvio","contig.{assembler}.db"),  
    conda:
        "../envs/anvio-7.1.yaml"
    shell:
        "anvi-run-scg-taxonomy -c {input.db} && touch {output}"
      
rule anvio_cogs:
    output:
        os.path.join( RESDIR , "{sample}" , 'anvio', "cogs.{assembler}.done"),
    input:
        db = os.path.join(RESDIR,"{sample}" ,'anvio',"contig.{assembler}.db"),
        f1 = os.path.join(RESDIR,"{sample}","anvio","cogs.{assembler}.setup"),
    threads:
        10
    conda:
        "../envs/anvio-7.1.yaml"
    shell:
        "anvi-run-ncbi-cogs -c {input.db} --num-threads {threads} && touch {output}"

rule anvio_setup_cogs:
    output:
        os.path.join(RESDIR,"{sample}","anvio","cogs.{assembler}.setup"),
    conda:
        "../envs/anvio-7.1.yaml"
    shell:
        "anvi-setup-ncbi-cogs && touch {output}"


rule anvio_contig_db:
    output:
        os.path.join(RESDIR,"{sample}" ,'anvio',"contig.{assembler}.db"),
    input:
        os.path.join(
                RESDIR , "{sample}", "contigs" , "{sample}.{assembler}.contigs.fa"
        ), 
    conda:
        "../envs/anvio-7.1.yaml"
    shell:
        "anvi-gen-contigs-database -f {input} -o {output} -n '{wildcards.sample}_{wildcards.assembler}' && anvi-run-hmms -c {input} --just-do-it"

