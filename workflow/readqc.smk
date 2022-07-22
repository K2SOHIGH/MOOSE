import json


from utils import utils

RESDIR = config["RESDIR"]
INPUTFILE = config["INPUT"]


INPUTS = json.load(open(INPUTFILE))

rule all:
    input:
        expand(
            os.path.join(
                RESDIR , "{sample}" , "reads-qc" ,"multiqc_report.html"
            ), sample = config["NAME"],
        )

rule multiqc:
    output:
        os.path.join(RESDIR , "{sample}" , "reads-qc" ,"multiqc_report.html"),
    input:
        LRQC = lambda wildcards: os.path.join( RESDIR, "{sample}" , "reads-qc" ,"nanoplot" ) if utils.get_long_reads(wildcards,INPUTS) else [],
        SRQC = lambda wildcards: os.path.join( RESDIR, "{sample}" , "reads-qc" ,"fastqc" ) if utils.get_forward_reads(wildcards,INPUTS) else [],
    params:
        targetdir = os.path.join(RESDIR , "{sample}" , "reads-qc"),
    conda:
        "envs/multiqc.yaml"
    shell:
        "multiqc {params.targetdir} -d -dd 3 -o {params.targetdir}"

rule nanoplot:
    output:
        directory( os.path.join( RESDIR, "{sample}" , "reads-qc" , "nanoplot" ) ),
    input:
        lambda wildcards : utils.get_long_reads( wildcards , INPUTS ),
    params:
        outdir = os.path.join( RESDIR, "{sample}" ,  "reads-qc" , "nanoplot" ),
    conda:
        "envs/nanoplot.yaml"
    shell:
        "NanoPlot --fastq {input} --loglength -o {params.outdir}"


rule fastqc:
    output:
        directory(os.path.join(RESDIR , "{sample}" ,  "reads-qc" , "fastqc")),
    input:
        lambda wildcards : utils.get_single_reads( wildcards , INPUTS ),
        lambda wildcards : utils.get_forward_reads( wildcards , INPUTS ),
        lambda wildcards : utils.get_reverse_reads( wildcards , INPUTS ),
    params:
        outdir = os.path.join(RESDIR , "{sample}" ,  "reads-qc" , "fastqc" ),
    conda:
        "envs/fastqc.yaml"
    shell:
        "mkdir -p {output} && fastqc {input} -o {params.outdir}"