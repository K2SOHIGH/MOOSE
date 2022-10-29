def get_unicycler_input(wildcards): 
    files = []
    for read_type in ["left_reads","right_reads","single_reads","long_reads"]:
        if utils.get_reads( INPUTS[wildcards.sample] , read_type ):
            files.append(os.path.join(RESDIR , wildcards.sample , "unicycler" , "%s.tmp" % read_type))
    return files



rule rename_unicycler_assembly:
    output:
        os.path.join( RESDIR , "{sample}" , "unicycler-{assembly_type}" ,"contigs.fasta")
    input:
        os.path.join( RESDIR , "{sample}" , "unicycler-{assembly_type}","assembly.fasta")
    shell:
        "mv {input} {output}"


rule unicycler:
    output:
        os.path.join( RESDIR , "{sample}" , "unicycler-{assembly_type}" ,"assembly.fasta")
    input:
        get_unicycler_input,
    params:
        unicycler_input = lambda wildcards,input : utils.set_unicycler_input_cmdline(input),
        outdir = os.path.join( RESDIR , "{sample}" , "unicycler-{assembly_type}"),
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
        "{params.unicycler_input} "
        "-o {params.outdir} "    
        "--threads {threads} "
        "{params.unicycler_cmd}"



def concat_unicycler_input (wildcards):
    return utils.get_reads( INPUTS[wildcards.sample] , wildcards.reads)

rule unicycler_concat_input:
    output:
        temp(os.path.join(RESDIR,"{sample}","unicycler","{reads}.tmp")),
    input:
        concat_unicycler_input,            
    shell:        
        "cat {input} > {output} "