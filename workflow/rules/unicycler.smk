def get_unicycler_input(wildcards , input_type ,fun): 
    if fun( wildcards , INPUTS ):
        return os.path.join(RESDIR , wildcards.sample , "unicycler" , "%s.tmp" % input_type)
    else:
        return []

rule unicycler:
    output:
        os.path.join( RESDIR , "{sample}" "unicycler","assembly.fasta")
    input:
        R1 = lambda wildcards : get_unicycler_input(wildcards,"R1",utils.get_forward_reads),
        R2 = lambda wildcards : get_unicycler_input(wildcards,"R2",utils.get_reverse_reads),
        UR = lambda wildcards : get_unicycler_input(wildcards,"unpaired",utils.get_single_reads),
        LR = lambda wildcards : get_unicycler_input(wildcards,"longread",utils.get_long_reads),
    params:
        r1inp = lambda wildcards, input: "-1 %s" % input.R1 if input.R1 else "",
        r2inp = lambda wildcards, input: "-2 %s" % input.R2 if input.R2 else "",
        urinp = lambda wildcards, input: "-s %s" % input.UR if input.UR else "",
        lrinp = lambda wildcards, input: "-l %s" % input.LR if input.LR else "",
        outdir = os.path.join( RESDIR , "{sample}" "unicycler"),
        unicycler_cmd = utils.parse_unicycler_cmdline(config["UNICYCLER"]) if config["UNICYCLER"] else "",
    threads:
        20
    resources:
        mem = 200000,
        mem_mb = 200000, 
        nodes = 1,
        cpus_per_task = 20,
    conda:
        "../envs/unicycler-0.5.0.yaml"
    shell:
        "unicycler "
        "{params.r1inp} "
        "{params.r2inp} "
        "{params.urinp} "
        "{params.lrinp} "
        "-o {params.outdir} "    
        "--threads {threads} "
        "{params.unicycler_cmd}"


def unicycler_input(wildcards):
    if wildcards.reads == "R1":
        return utils.get_forward_reads(wildcards , INPUTS )
    if wildcards.reads == "R2":
        return utils.get_reverse_reads(wildcards , INPUTS )
    if wildcards.reads == "unpaired":
        return utils.get_single_reads( wildcards , INPUTS )
    if wildcards.reads == "longread":
        return utils.get_long_reads( wildcards , INPUTS )

rule unicycler_concat_input:
    output:
        temp(os.path.join(RESDIR,"{sample}","unicycler","{reads}.tmp")),
    input:
        unicycler_input
    shell:        
        "cat {input} > {output} "