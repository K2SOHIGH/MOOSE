rule assembly_rename_miniasm:
    output:
        os.path.join(RESDIR, SAMPLES_DIR , "{sample}", "LRF" , "miniasm" , "contigs.fa" )
    input:
        os.path.join(RESDIR, SAMPLES_DIR , "{sample}", "LRF" , "miniasm" , "pilon.fasta"),
    shell:
        "mv {input} {output}"

rule assembly_polishing_with_pilon:
    output:
        os.path.join(RESDIR, SAMPLES_DIR , "{sample}", "LRF" , "miniasm" , "pilon.fasta"),
    input:
        raw = os.path.join(RESDIR, SAMPLES_DIR , "{sample}", "LRF" , "miniasm" , "polished.fasta"),
        bam = os.path.join(RESDIR, SAMPLES_DIR , "{sample}", "LRF" , "miniasm" , "polished.bam"),
    conda:
        "../envs/bowtie2.2.4.5.yaml"
    params:
        outdir = os.path.join(RESDIR, SAMPLES_DIR , "{sample}","LRF" , "miniasm"),
    shell:
        "pilon --genome {input.raw} --frags {input.bam} --outdir {params.outdir} "

rule assembly_lrf_mapping:
    output:
        bam = os.path.join(RESDIR, SAMPLES_DIR , "{sample}","LRF" , "miniasm" , "polished.bam"),
        sam = os.path.join(RESDIR, SAMPLES_DIR , "{sample}","LRF" , "miniasm" , "polished.sam"),
    input:
        fasta = os.path.join(RESDIR, SAMPLES_DIR , "{sample}","LRF" , "miniasm" , "polished.fasta" ),
        R1 = lambda wildcards : get_qc_reads(wildcards, wildcards.sample ,"forward"),
        R2 = lambda wildcards : get_qc_reads(wildcards, wildcards.sample ,"reverse"),
        SR = lambda wildcards : get_qc_reads(wildcards, wildcards.sample ,"single" ),
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
        "samtools view -u {output.sam} | samtools sort -@ {threads} -o {output.bam} | samtools index {output.bam}"


rule assembly_convert_gfa_to_fasta:
    output:
        os.path.join(RESDIR, SAMPLES_DIR , "{sample}","LRF" , "miniasm" , "polished.fasta" )
    input:
        os.path.join(RESDIR, SAMPLES_DIR , "{sample}","LRF" , "miniasm" , "polished.gfa" )
    run:
        with open(str(output),"w") as streamout:
            with open(str(input)) as streamint:
                for l in streamin.readlines():
                    if l.startswith("S"):
                        _ , header , sequence, _ = l.split()
                        streamout.write(">{}\n{}\n".format(header,sequence))
        
            
def gfa2fasta(file):
    with open(file) as stream:
        for l in stream.readlines():
            if l.startswith("S"):
                _ , header , sequence, _ = l.split()
                print(">{}\n{}".format(header,sequence))

        

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
        "minipolish {params.lrt} --rounds 5 -t {threads} {input.reads} {input.gfa} > {output}"

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
        "minimap2 -t -x {params.lrt} {threads} {input} {input} - | gzip > {output}"
