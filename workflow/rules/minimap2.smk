




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
        "minipolish {lrt} --rounds 5 -t {threads} {input.reads} {input.gfa} > {output}"

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
        "minimap2 -t -x {params.lrt} {threads} {input} {input} - | gzip > {outpt}"
