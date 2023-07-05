

rule assembly_with_spades:
    output:        
        os.path.join( RESDIR, SAMPLES_DIR , "{sample}", "{assembly_type}" , "spades" , "contigs.fa"),        
    input:
        R1 = lambda wildcards : get_qc_reads(wildcards, wildcards.sample, "forward"),
        R2 = lambda wildcards : get_qc_reads(wildcards, wildcards.sample, "reverse"),
        SR = lambda wildcards : get_qc_reads(wildcards, wildcards.sample, "single" ),
        LR = lambda wildcards : get_qc_reads(wildcards, wildcards.sample, "long"   ),
    params:
        spades_paired_end_reads = lambda wildcards, input : format_spades_paired_end_inputs(wildcards,input) if wildcards.assembly_type in ["SRO","SRF"] else "",
        spades_single_end_reads  = lambda wildcards, input : format_spades_single_end_inputs(wildcards,input) if wildcards.assembly_type in ["SRO","SRF"] else "", 
        spades_long_reads  = lambda wildcards, input : format_spades_long_reads_inputs(wildcards,input) if wildcards.assembly_type in ["SRF"] else "",                
        outdir = os.path.join( RESDIR, SAMPLES_DIR , "{sample}", "{assembly_type}" , "spades"),
        spades_cmd = utils.parse_spades_cmdline(config["SPADES"]) if config["SPADES"] else "",
        assembly_mode = "--{}".format(config["MODE"]) if config["MODE"] else "",
        kmers = "-k {}".format(" ".join(config["KLIST"])) if config["KLIST"] else "" ,
    log:
        os.path.join( RESDIR, SAMPLES_DIR , "{sample}", "{assembly_type}" , "spades" , "mgw_spades.log"),
    conda:
        "../envs/spades-3.15.5.yaml"
    threads:
        8
    shell:
        "spades.py "
        "{params.assembly_mode} "
        "{params.kmers} "
        "{params.spades_paired_end_reads} "
        "{params.spades_single_end_reads} "
        "{params.spades_long_reads} "
        "-o {params.outdir} "        
        "-t {threads} > {log} && "
        "mv {params.outdir}/contigs.fasta {output}"
