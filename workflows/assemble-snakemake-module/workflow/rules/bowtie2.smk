rule mapping_expand_products:
    output:
        touch(
            temp(
                os.path.join(RESDIR , SAMPLES_DIR , "{sample}", "mapping.done")
            ),
        )
    input:
        get_mapping_products,
        # get_sro_mapping_products,
        # get_srf_lrf_mapping_products,
 
rule mapping_sort_and_index:
    """
    """
    output:
        os.path.join(RESDIR , SAMPLES_DIR , "{sample}", "{assembly_type}" , "{assembler}" , "BAMs" , "{mapper}.sorted.bam"),
        os.path.join(RESDIR , SAMPLES_DIR , "{sample}", "{assembly_type}" , "{assembler}" , "BAMs" , "{mapper}.sorted.bam.bai"),
    input:
        os.path.join(RESDIR , SAMPLES_DIR , "{sample}", "{assembly_type}" , "{assembler}" , "BAMs" , "{mapper}.filtered.sam")
    threads: 1
    priority: 90
    conda:
        "../envs/samtools.1.16.1.yaml"
    shell:
        "samtools view -u {input} | "
        "samtools sort "
        "-@ {threads} "             # number of threads used
        "-o {output[0]} "
        "&& samtools index "
        "{output[0]} "
        
rule mapping_filter_bam:
    """
        Filter reads based on mapping quality and identity.
        Output is temporary because it will be sorted.
    """
    output:
        temp(
            os.path.join(RESDIR , SAMPLES_DIR , "{sample}", "{assembly_type}" , "{assembler}" , "BAMs" , "{mapper}.filtered.sam")
        ),
    input:
        os.path.join(RESDIR , SAMPLES_DIR , "{sample}", "{assembly_type}" , "{assembler}" , "BAMs" , "{mapper}.sam"),
    conda:
        "../envs/bamutils.yaml"
    params:
        min_mapq = config["min_quality"],
        min_idt = config["min_identity"],
        min_len = config["min_len"],
        pp = config["properly_paired"],
    script:
        "../scripts/bamprocess.py"

rule mapping_bowtie2:
    '''
        required by summarize_contig_depth
    '''
    output:
        temp(
            os.path.join(RESDIR , SAMPLES_DIR , "{sample}", "{assembly_type}" , "{assembler}" , "BAMs" , "{mapper}.sam"),
        )
    input:
        expand(
            os.path.join(RESDIR , SAMPLES_DIR , "{{sample}}", "{{assembly_type}}" , "{{assembler}}" , "index" , "bowtie2_index.{idx}"),
            idx = ["1.bt2", "2.bt2", "3.bt2", "4.bt2", "rev.1.bt2","rev.2.bt2"]
        ),
        R1 = lambda wildcards : get_qc_reads(wildcards, wildcards.mapper ,"forward"),
        R2 = lambda wildcards : get_qc_reads(wildcards, wildcards.mapper ,"reverse"),
        SR = lambda wildcards : get_qc_reads(wildcards, wildcards.mapper ,"single" ),
    params:
        r1inp = lambda wildcards, input: "-1 " + " -1 ".join(input.R1) if input.R1 else "",
        r2inp = lambda wildcards, input: "-2 " + " -2 ".join(input.R2) if input.R2 else "",
        srinp = lambda wildcards, input: "-U " + " -U ".join(input.SR) if input.SR else "",
        index = os.path.join(RESDIR , SAMPLES_DIR , "{sample}", "{assembly_type}" , "{assembler}" , "index" , "bowtie2_index"),
    threads: 15
    priority: 80
    conda:
        "../envs/bowtie2.2.4.5.yaml"
    shell:
        "bowtie2 "
        "-p {threads} "             # number of parallel threads
        "--no-unal "                # remove unmapped reads (decrease size)
        "-x {params.index} "       # index for mapping
        "{params.r1inp} "
        "{params.r2inp} "
        "{params.srinp} "
        "-S {output} "


rule mapping_bowtie2_index:
    output:
        expand(
            os.path.join(RESDIR , SAMPLES_DIR , "{{sample}}", "{{assembly_type}}" , "{{assembler}}" , "index" , "bowtie2_index.{idx}"),
            idx = ["1.bt2", "2.bt2", "3.bt2", "4.bt2", "rev.1.bt2","rev.2.bt2"]
        ),   
    input:
        contigs = os.path.join( 
            RESDIR , SAMPLES_DIR,  "{sample}", "{assembly_type}" , "{assembler}" ,  "final_assembly.fasta"
        ),
    params:
        index = os.path.join(RESDIR , SAMPLES_DIR , "{sample}", "{assembly_type}" , "{assembler}" , "index" , "bowtie2_index"),        
    conda:
        "../envs/bowtie2.2.4.5.yaml"
    shell:
        "bowtie2-build {input.contigs} {params.index}"

            