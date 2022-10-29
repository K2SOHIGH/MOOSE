rule quast:
    output:
        os.path.join(RESDIR, "{sample}" , "contigs-qc","report.html"),
    input:
        expand(
            os.path.join(
                RESDIR , "{{sample}}", "{assembler_assembly_type}" ,  "final_contigs_reformat.fasta"
            ), assembler_assembly_type = ASSEMBLER_AND_TYPES,
        )        
    params:
        outdir = os.path.join(RESDIR, "{sample}" , "contigs-qc"),
        labels = ",".join(ASSEMBLER_AND_TYPES),
    shell:
        "quast -o {params.outdir} {input} -l {params.labels}"