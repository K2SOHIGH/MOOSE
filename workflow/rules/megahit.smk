
rule megahit:
    output:
        os.path.join(
            RESDIR , "{sample}", "megahit","final.contigs.fa"
        )
    input:
        R1 = lambda wildcards : utils.get_forward_reads(wildcards , INPUTS ),
        R2 = lambda wildcards : utils.get_reverse_reads(wildcards , INPUTS ),
        UR = lambda wildcards : utils.get_single_reads( wildcards , INPUTS ),
    conda:
        "../envs/megahit.yaml"
    threads:
        10
    params:
        r1inp = lambda wildcards, input: " ".join( [ "-1 %s" % i  for i in input.R1] ),
        r2inp = lambda wildcards, input: " ".join( [ "-2 %s" % i  for i in input.R2] ),
        urinp = lambda wildcards, input: " ".join( [ "-r %s" % i  for i in input.UR] ),
        outdir = os.path.join( RESDIR , "{sample}" , "megahit" ),
        megahit_cmd = utils.parse_megahit_cmdline(config["MEGAHIT"]) if config["MEGAHIT"] else "",
    shell:
        "rm -r {params.outdir} && "
        "megahit {params.r1inp} "
        "{params.r2inp} "
        "{params.urinp} "
        "-o {params.outdir} "
        "{params.megahit_cmd} "
        "-t {threads} "
