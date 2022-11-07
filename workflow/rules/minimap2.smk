


rule assembly_polishing_with_pilon:
    output:
    input:
        os.path.join(RESDIR, SAMPLES_DIR , "{sample}","LRF" , "miniasm" , "polished.gfa" )
    shell:


rule assembly_lrf_mapping:
    output:
    input:
        fasta = os.path.join(RESDIR, SAMPLES_DIR , "{sample}","LRF" , "miniasm" , "polished.fasta" ),
        R1 = lambda wildcards : get_qc_reads(wildcards, wildcards.mapper ,"forward"),
        R2 = lambda wildcards : get_qc_reads(wildcards, wildcards.mapper ,"reverse"),
        SR = lambda wildcards : get_qc_reads(wildcards, wildcards.mapper ,"single" ),
    params:
        r1inp = lambda wildcards, input: "-1 " + " -1 ".join(input.R1) if input.R1 else "",
        r2inp = lambda wildcards, input: "-2 " + " -2 ".join(input.R2) if input.R2 else "",
        srinp = lambda wildcards, input: "-U " + " -U ".join(input.SR) if input.SR else "",
        index = os.path.join(RESDIR , SAMPLES_DIR , "{sample}", "LRF" , "miniasm" , "bowtie2_index"),
    threads: 15
    priority: 80
    conda:
        "../envs/bowtie2.2.4.5.yaml"
    shell:
        "bowtie2-build {input.fasta} {params.index} && "
        "bowtie2 "
        "-p {threads} "             # number of parallel threads
        "--no-unal "                # remove unmapped reads (decrease size)
        "-x {params.index} "       # index for mapping
        "{params.r1inp} "
        "{params.r2inp} "
        "{params.srinp} "
        "-S {output.sam} && "
        "samtools view -u {output.sam} | samtools sort -@ {threads} "


rule assembly_convert_gfa_to_fasta:
    output:
        os.path.join(RESDIR, SAMPLES_DIR , "{sample}","LRF" , "miniasm" , "polished.fasta" )
    input:
        os.path.join(RESDIR, SAMPLES_DIR , "{sample}","LRF" , "miniasm" , "polished.gfa" )
    shell:
        """
            awk '/^S/{print ">"$2" "$3}' {input} | tr ' ' '\n'
        """
        

rule assembly_polishing_with_minipolish:
    output:
        os.path.join(RESDIR, SAMPLES_DIR , "{sample}","LRF" , "miniasm" , "polished.gfa" )
    input:
        reads = lambda wildcards : get_qc_reads(wildcards, wildcards.sample, "long"),
        gfa = os.path.join(RESDIR, SAMPLES_DIR , "{sample}","LRF" , "miniasm" , "raw.gfa" ),
    params:
        lrt = lambda wildcards : "" if 
            SAMPLES.get_sample_by_id(wildcards.sample).long_reads_type == "nanopore" else
            "--pacbio"
    threads:
        10
    shell:
        "minipolish {lrt} --rounds 5 -t {threads} {input.reads} {input.gfa} > {output}"

rule assembly_with_miniasm:
    output:
        os.path.join(RESDIR, SAMPLES_DIR , "{sample}","LRF" , "miniasm" , "raw.gfa" )
    input:
        lr = lambda wildcards : get_qc_reads(wildcards, wildcards.sample, "long"),
        paf = os.path.join(RESDIR, SAMPLES_DIR , "{sample}","LRF" , "miniasm" , "overlap.paf.gz" ),
    conda:
        "../envs/miniasm.yaml"
    shell:
        "miniasm -s 1000 -f {input.lr} {input.paf} > {output}"



rule assembly_finding_lr_overlap_with_minimap2:
    output:
        os.path.join(RESDIR, SAMPLES_DIR , "{sample}","LRF" , "miniasm" , "overlap.paf.gz" )
    input:
        lambda wildcards : get_qc_reads(wildcards, wildcards.sample, "long"),
    params:
        lrt = lambda wildcards : "ava-ont" if 
            SAMPLES.get_sample_by_id(wildcards.sample).long_reads_type == "nanopore" else
            "ava-pb"
    conda:
        "../envs/minimap2.yaml"
    threads:
        10
    shell:
        "minimap2 -t -x {params.lrt} {threads} {input} {input} - | gzip > {outpt}"
