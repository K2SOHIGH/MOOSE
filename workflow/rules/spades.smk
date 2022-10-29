rule spades:
    output:
        os.path.join( RESDIR , "{sample}", "spades-{assembly_type}", "contigs.fasta"),
        os.path.join( RESDIR , "{sample}", "spades-{assembly_type}", "scaffold.fasta"),
    params:
        spades_input =  lambda wildcards: utils.set_spades_input_cmdline(INPUTS[wildcards.sample] , wildcards.assembly_type ),
        outdir = os.path.join( RESDIR , "{sample}" , "spades-{assembly_type}"),
        spades_cmd = utils.parse_spades_cmdline(config["SPADES"]) if config["SPADES"] else "",
    conda:
        "../envs/spades-3.15.5.yaml"
    threads:
        20
    shell:
        "spades.py "
        "{params.spades_input} "
        "-o {params.outdir} "
        "-t {threads} "

