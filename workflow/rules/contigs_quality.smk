rule assembly_quast:
    output:
        os.path.join(RESDIR, SAMPLES_DIR, "{sample}" , "contigs-qc", "{qc_contigs}_contigs_report.html"),
    input:
        get_sro_assembly_products,
        get_srf_lrf_assembly_products,
    conda:
        "../envs/quast.5.2.0.yaml"
    params:
        outdir = os.path.join(RESDIR, SAMPLES_DIR, "{sample}","contigs-qc"),
        labels = lambda wildcards,input : ",".join([ "_".join(os.path.dirname(i).split("/")[-2:])  for i in input if i]),
    shell:
        "quast -o {params.outdir} {input} -l {params.labels}"