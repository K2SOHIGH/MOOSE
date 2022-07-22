rule spades:
    output:
        os.path.join( RESDIR , "{sample}" "spades","contigs.fasta"),
        os.path.join( RESDIR , "{sample}" "spades","scaffold.fasta"),
    input:
        config["INPUT"],
    params:
        outdir = os.path.join( RESDIR , "{sample}" "spades"),
        spades_cmd = utils.parse_spades_cmdline(config["SPADES"]) if config["SPADES"] else "",
    conda:
        "../envs/spades-3.15.5.yaml"
    threads:
        20
    shell:
        "spades.py --dataset {input} "
        "-o {params.outdir} "
        "-t {threads} "

