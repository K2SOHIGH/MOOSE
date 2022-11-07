


rule assembly_rename_miniasm:
    output:
        os.path.join(RESDIR, SAMPLES_DIR , "{sample}", "{assembly_type}" , "miniasm" , "contigs.fa" )
    input:
        fa = os.path.join(RESDIR, SAMPLES_DIR , "{sample}", "{assembly_type}" , "miniasm" , "final.contigs.fa"),
        flag = os.path.join(RESDIR, SAMPLES_DIR , "{sample}", "{assembly_type}" , "miniasm" , "assembly_graphs"),        
    shell:
        "mv {input.fa} {output}"

rule assembly_polishing_with_minipolish:
    shell:
        "minipolish -t 8 long_reads.fastq.gz assembly.gfa > polished.gfa"

rule assembly_with_miniasm:
output:
    "miniasm-graph.gfa"
shell:
    "miniasm -f {input.lr} {input.overlap} > {output}"

rule assembly_lr_mapping_minimap2:
    output:
        overlap.paf.gz
    params:
        lrt = "ava-ont" if lrt == "nanopore" else "ava-pb"
    shell:
        "minimap2 {input} {input} -x {params.lrt} | gzip > {outpt}" 