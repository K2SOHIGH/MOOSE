# processing short_reads

rule reads_processing_long_reads:
    output:
        temp(
            os.path.join(
                RESDIR, SAMPLES_DIR , "{sample}", "qc_reads", "long_{lr}.fq.gz"
            )
        )
    input:
        lambda wildcards : READS[ "long_" + wildcards.lr ],
    params:
        lr_min_length = config["lr_min_len"] if "lr_min_len" in config else 5000,
        target_bases = config["lr_target_bases"] if "lr_target_bases" in config else 10000000,  # --target_bases {params.target_bases} 
        keep = 90                                                                                       
    conda:
        "../envs/filtlong.0.2.1.yaml"
    threads:
        10
    shell:
        "filtlong --length_weight 3 --min_length {params.lr_min_length} --keep_percent {params.keep} {input} | gzip > {output}"

 
rule reads_processing_single_end:
    output:
        temp(
            os.path.join(
                RESDIR, SAMPLES_DIR , "{sample}", "qc_reads", "single_{se}.fq.gz"
            )
        )     
    input:
        lambda wildcards : READS[ "single_" + wildcards.se ],
    log:
        os.path.join(RESDIR, SAMPLES_DIR , "{sample}", "qc_reads", "cutadapt.se.{se}.log")
    params:
        per_base_quality = 20,
    conda:
        "../envs/cutadapt.4.1.yaml"
    threads:
        10
    shell:
        "cutadapt -q {params.per_base_quality} -o {output} "        
        "-Z "
        "-j {threads} "
        "{input} > {log}"
        

rule reads_processing_paired_end:
    output:
        forward_qc = temp(
            os.path.join(
                RESDIR, SAMPLES_DIR , "{sample}", "qc_reads", "forward_{pe}.fq.gz"
            )
        ),
        reverse_qc = temp(
            os.path.join(
                RESDIR, SAMPLES_DIR , "{sample}", "qc_reads", "reverse_{pe}.fq.gz"
            )
        ),
    input:
        frw = lambda wildcards : READS[ "forward_"+wildcards.pe ],        
        rev = lambda wildcards : READS[ "reverse_"+wildcards.pe ],
    params:        
        per_base_quality = 20,
    log:
        os.path.join(RESDIR, SAMPLES_DIR , "{sample}", "qc_reads", "cutadapt.pe.{pe}.log")
    conda:
        "../envs/cutadapt.4.1.yaml"
    threads:
        10
    shell:
        "cutadapt -q {params.per_base_quality} -o {output.forward_qc} "
        "-p {output.reverse_qc} "
        "-Z "
        "-j {threads} "
        "{input.frw} "
        "{input.rev} > {log}"