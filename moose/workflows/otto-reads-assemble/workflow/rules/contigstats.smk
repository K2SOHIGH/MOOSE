rule assembly_contig_stats:
    output:
        os.path.join(RESDIR, SAMPLES_DIR, "{sample}" , "{qc_contigs}-stats", "assembly.stats.tsv"),
    input:
        get_assembly_products,        
    conda:
        "../envs/seqfu.yaml"
    params:
        outdir = os.path.join(RESDIR, SAMPLES_DIR, "{sample}", "{qc_contigs}-stats"),        
    shell:
        "seqfu stats {input} > {output}"

rule assembly_contig_qual_with_quast:
    output:
        os.path.join(RESDIR, SAMPLES_DIR, "{sample}" , "{qc_contigs}-contigs-qc", "report.html"),
    input:
        get_assembly_products,        
    conda:
        "../envs/quast.5.2.0.yaml"
    params:
        outdir = os.path.join(RESDIR, SAMPLES_DIR, "{sample}", "{qc_contigs}-contigs-qc"),
        labels = lambda wildcards,input : ",".join([ "_".join(os.path.dirname(i).split("/")[-2:])  for i in input if i]),
    shell:
        "quast -o {params.outdir} {input} -l {params.labels}"