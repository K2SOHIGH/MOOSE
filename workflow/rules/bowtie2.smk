
rule sort_and_index_binning:
    """
    """
    output:
        os.path.join(RESDIR , "{sample}", "{assembler_assembly_type}" , "read_mapping"  , "{sample}.sorted.bam"),
        os.path.join(RESDIR , "{sample}", "{assembler_assembly_type}" , "read_mapping"  , "{sample}.sorted.bam.bai"),
    input:
        os.path.join(RESDIR , "{sample}", "{assembler_assembly_type}" , "read_mapping"  , "{sample}.filtered.sam")
    threads: 1
    priority: 90
    conda:
        "../envs/samtools.yaml"
    shell:
        "samtools view -u {input} | "
        "samtools sort "
        "-@ {threads} "             # number of threads used
        "-o {output[0]} "
        "&& samtools index "
        "{output[0]} "
        #"&> {log} "


rule filter_bam:
    """
        Filter reads based on mapping quality and identity.
        Output is temporary because it will be sorted.
    """
    output:
        temp(os.path.join(RESDIR , "{sample}", "{assembler_assembly_type}" , "read_mapping"  , "{sample}.filtered.sam")),
    input:
        os.path.join(RESDIR , "{sample}", "{assembler_assembly_type}" , "read_mapping"  , "{sample}.sam"),
    conda:
        "../envs/bamutils.yaml"
    params:
        min_mapq = config["min_quality"],
        min_idt = config["min_identity"],
        min_len = config["min_len"],
        pp = config["properly_paired"],
    script:
        "scripts/bamprocess.py"

def bowtie2_input_read(reads_type:str,reads:list):
    if reads:
        if reads_type == "R1":
            return "-1 %s" % ",".join(reads)
        elif reads_type == "R2":
            return "-2 %s" % ",".join(reads)
        else:
            return "-U %s" % ",".join(reads)
    return []

rule short_read_mapping:
    '''
        required by summarize_contig_depth
    '''
    output:
        temp(os.path.join(RESDIR , "{sample}", "{assembler_assembly_type}" , "read_mapping"  , "{sample}.sam")),
    input:
        expand(
            os.path.join(RESDIR , "{{sample}}", "{{assembler_assembly_type}}", "bowtie2_index.{idx}")
            , idx = ["1.bt2", "2.bt2", "3.bt2", "4.bt2", "rev.1.bt2","rev.2.bt2"]
        ),
        R1 = lambda wildcards : utils.get_reads( INPUTS[wildcards.sample] , "left_reads" ),
        R2 = lambda wildcards : utils.get_reads( INPUTS[wildcards.sample] , "right_reads" ),
        #UR = lambda wildcards : utils.get_reads( INPUTS[wildcards.sample] , "single_reads" ),
        #LR = lambda wildcards : utils.get_reads( INPUTS[wildcards.sample] , "long_reads" ),   
    params:
        r1inp = lambda wildcards, input: bowtie2_input_read("R1",input.R1),
        r2inp = lambda wildcards, input: bowtie2_input_read("R2",input.R2),
        #urinp = lambda wildcards, input: bowtie2_input_read("U",input.UR + input.LR),
        index = os.path.join(RESDIR , "{sample}", "{assembler_assembly_type}", "bowtie2_index"),
    threads: 15
    priority: 80
    conda:
        "../envs/bowtie2.yaml"
    shell:
        "bowtie2 "
        "-p {threads} "             # number of parallel threads
        "--no-unal "                # remove unmapped reads (decrease size)
        "-x {params.index} "       # index for mapping
        "{params.r1inp} "
        "{params.r2inp} "
        #"{params.urinp} "
        "-S {output} "


rule contigs_index:
    output:
        expand(
            os.path.join(RESDIR , "{{sample}}", "{{assembler_assembly_type}}" , "bowtie2_index.{idx}")
            , idx = ["1.bt2", "2.bt2", "3.bt2", "4.bt2", "rev.1.bt2","rev.2.bt2"]
        ),     
    input:
        contigs = os.path.join( 
            RESDIR , "{sample}", "{assembler_assembly_type}" ,  "final_contigs_reformat.fasta"
        ),
    params:
        index = os.path.join(
                RESDIR , "{sample}", "{assembler_assembly_type}" , "bowtie2_index"
            ),        
    conda:
        "../envs/bowtie2.yaml"
    shell:
        "bowtie2-build {input.contigs} {params.index}"

            