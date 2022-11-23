rule assembly_rename_unicycler:
    output:
        os.path.join(RESDIR, SAMPLES_DIR , "{sample}","{assembly_type}" , "unicycler" , "contigs.fa" )
    input:
        os.path.join(RESDIR, SAMPLES_DIR , "{sample}","{assembly_type}" , "unicycler" , "assembly.fasta" )
    shell:
        "mv {input} {output}"


rule assembly_with_unicycler:
    output:
        os.path.join(RESDIR, SAMPLES_DIR , "{sample}","{assembly_type}" , "unicycler" , "assembly.fasta" )
    input:        
        R1 = lambda wildcards : unicycler_get_reads( wildcards,  get_qc_reads(wildcards, wildcards.sample, "forward"), "forward"  ),
        R2 = lambda wildcards : unicycler_get_reads( wildcards,  get_qc_reads(wildcards, wildcards.sample, "reverse"), "reverse"  ),
        SR = lambda wildcards : unicycler_get_reads( wildcards,  get_qc_reads(wildcards, wildcards.sample, "single" ), "single"  ),
        LR = lambda wildcards : unicycler_get_reads( wildcards,  get_qc_reads(wildcards, wildcards.sample, "long"), "long"  ),        
    params:
        unicycler_paired_end_reads = lambda wildcards, input : "-1 {} -2 {}".format(input.R1,input.R2) if input.R1 and input.R2 else "",
        unicycler_single_end_reads = lambda wildcards, input : "-s {}".format(input.SR) if input.SR else "",
        unicycler_long_reads       = lambda wildcards, input : "-l {}".format(input.LR) if input.LR else "",
        outdir  = os.path.join(RESDIR, SAMPLES_DIR , "{sample}","{assembly_type}" , "unicycler"),
        unicycler_cmd = utils.parse_unicycler_cmdline(config["UNICYCLER"]) if config["UNICYCLER"] else "",        
        #kmers = config["KLIST"],
        kmers = "--kmers {}".format(",".join(config["KLIST"])) if config["KLIST"] else "" ,

    log:
        os.path.join(RESDIR, SAMPLES_DIR , "{sample}","{assembly_type}" , "unicycler" , "mgw_unicycler.log" )
    threads:
        10
    resources:
        mem = 200000,
        mem_mb = 200000, 
        nodes = 1,
        cpus_per_task = 20,
    conda:
        "../envs/unicycler-0.5.0.yaml"
    shell:        
        "unicycler "
        "{params.kmers} "
        "{params.unicycler_paired_end_reads} "
        "{params.unicycler_single_end_reads} "
        "{params.unicycler_long_reads} "
        "-o {params.outdir} "    
        "--threads 10 "        
        "{params.unicycler_cmd} > {log}"


rule assembly_concat_input_unicycler:
    output:
        temp(
            os.path.join(
                RESDIR, SAMPLES_DIR, "{sample}", "tmp" , "{reads}_tmp.fq.gz"
            ),
        )
    input:
        lambda wildcards: get_qc_reads(wildcards, wildcards.sample, wildcards.reads),        
    shell:        
        "cat {input} > {output} "