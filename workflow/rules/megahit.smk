
rule rename_megahit_assembly:
    output:
        os.path.join( RESDIR , "{sample}" , "megahit-{assembly_type}" ,"contigs.fasta")
    input:
        os.path.join( RESDIR , "{sample}" , "megahit-{assembly_type}" ,"final.contigs.fa")
    wildcard_constraints:
        assembly_type = "short_reads",    
    shell:
        "mv {input} {output}"

rule megahit:
    output:
        os.path.join(RESDIR , "{sample}", "megahit-{assembly_type}", "final.contigs.fa")
    input:
        R1 = lambda wildcards : utils.get_reads( INPUTS[wildcards.sample] , "left_reads" ),
        R2 = lambda wildcards : utils.get_reads( INPUTS[wildcards.sample] , "right_reads" ),
        UR = lambda wildcards : utils.get_reads( INPUTS[wildcards.sample] , "single_reads" ),
    conda:
        "../envs/megahit.yaml"
    log:
        os.path.join(RESDIR , "{sample}", "megahit-{assembly_type}", "megahit.log")
    threads:
        10
    params:
        megahit_inputs = lambda wildcards: utils.set_megahit_input_cmdline(INPUTS[wildcards.sample]),
        outdir = os.path.join( RESDIR , "{sample}" , "megahit-{assembly_type}" ),
        megahit_cmd = utils.parse_megahit_cmdline(config["MEGAHIT"]) if config["MEGAHIT"] else "",
    shell:
        "rm -r {params.outdir} && "
        "megahit "
        "{params.megahit_inputs} "
        "-o {params.outdir} "
        "{params.megahit_cmd} "
        "-t {threads} > {log}"
