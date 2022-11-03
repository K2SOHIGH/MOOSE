rule assembly_rename_megahit:
    output:
        os.path.join(RESDIR, SAMPLES_DIR , "{sample}", "{assembly_type}" , "megahit" , "contigs.fa" )
    input:
        fa = os.path.join(RESDIR, SAMPLES_DIR , "{sample}", "{assembly_type}" , "megahit" , "final.contigs.fa"),
        flag = os.path.join(RESDIR, SAMPLES_DIR , "{sample}", "{assembly_type}" , "megahit" , "assembly_graphs"),        
    shell:
        "mv {input.fa} {output}"


rule assembly_with_megahit_graph:
    output:
        directory(
            os.path.join(RESDIR, SAMPLES_DIR , "{sample}", "{assembly_type}" , "megahit" , "assembly_graphs")
        )
    input:
        os.path.join(RESDIR, SAMPLES_DIR , "{sample}", "{assembly_type}" , "megahit" , "final.contigs.fa")
    params:
        intermediate_contigs = os.path.join(RESDIR, SAMPLES_DIR , "{sample}", "{assembly_type}" , "megahit" , "intermediate_contigs")
    shell:
        'for k in $(ls {params.intermediate_contigs}/*.contigs.fa | grep -v "final") ; do '
        '   megahit_toolkit contig2fastg $(echo $k | cut -d "." -f1 | sed "s/.*\/k//g") $k > {output}/$k.fastg ; '
        'done '
    

rule assembly_with_megahit:
    output:
        os.path.join(RESDIR, SAMPLES_DIR , "{sample}", "{assembly_type}" , "megahit" , "final.contigs.fa")
    input:
        R1 = lambda wildcards : get_qc_reads(wildcards, wildcards.sample, "forward"),
        R2 = lambda wildcards : get_qc_reads(wildcards, wildcards.sample, "reverse"),
        SR = lambda wildcards : get_qc_reads(wildcards, wildcards.sample, "single"),
    conda:
        "../envs/megahit.1.2.9.yaml"
    log:
        os.path.join(RESDIR, SAMPLES_DIR , "{sample}", "{assembly_type}" , "megahit" , "megahit.log")
    threads:
        10
    params:
        megahit_forward_reads = lambda wildcards,input: "-1 {}".format(",".join(input.R1)) if input.R1 else "",
        megahit_reverse_reads = lambda wildcards,input: "-2 {}".format(",".join(input.R2)) if input.R2 else "",
        megahit_single_reads = lambda wildcards,input: "-r {}".format(",".join(input.SR))  if input.SR else "",
        outdir = os.path.join(RESDIR, SAMPLES_DIR , "{sample}", "{assembly_type}" , "megahit"),
        megahit_cmd = utils.parse_megahit_cmdline(config["MEGAHIT"]) if config["MEGAHIT"] else "",
        kmers = "--k-list {}".format(config["KLIST"]) if config["KLIST"] else "",
    shell:
        "rm -r {params.outdir} &&   "
        "megahit                    "
        "{params.kmers}             "
        "{params.megahit_forward_reads} "
        "{params.megahit_reverse_reads} "
        "{params.megahit_single_reads}  "
        "-o {params.outdir}         "
        "{params.megahit_cmd}       "
        "-t {threads} > {log}       "
        
