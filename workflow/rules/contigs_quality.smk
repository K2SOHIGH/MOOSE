rule quast:
    output:
        os.path.join(RESDIR, "{sample}" , "contigs-qc","report.html"),
    input:
        expand(
            os.path.join(
                RESDIR , "{{sample}}", "contigs" , "{{sample}}.{assembler}.contigs.fa"
            ),
            assembler = ASSEMBLER,
        ),     
    params:
        outdir = os.path.join(RESDIR, "{sample}" , "contigs-qc"),
        labels = ",".join(ASSEMBLER),
    shell:
        "quast -o {params.outdir} {input} -l {params.labels}"