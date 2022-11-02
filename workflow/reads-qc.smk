include: "rules/fun.smk"

"""
    LOGGER
"""
snakemake_logger = logging.getLogger()

wlogger = log.setlogger(__name__)
    
wlogger.setLevel(logging.INFO)
wlogger.addHandler(
    log.stream_handler(logging.INFO)
)

"""
    CONFIGS and GLOBALS
"""
RESDIR = config["RESDIR"]
SAMPLES_DIR = "SAMPLES"


SAMPLES = sample.Samples(config["INPUT"])
SAMPLES_W_LR = get_sample_with_long_reads()

"""
    SETUP
"""
wlogger.info("Grabing configuration and input files =°")

READS = SAMPLES.sample2reads() 

rule reads_qc:
    output:
        os.path.join(RESDIR  ,"reads_qc_report.html"),
    input:
        expand(
            os.path.join(
                RESDIR , SAMPLES_DIR, "{sample}" , "qc_reads" ,"multiqc_qc_reads_report.html"
            ), sample = SAMPLES.samples,
        )
    conda:
        "envs/multiqc.1.13.yaml"
    params:
        multiqc_target = RESDIR,
        outdir = RESDIR,
        name = "reads_qc_report.html",
    shell:
        "multiqc {params.multiqc_target} -d -dd 3 -o {params.outdir} -n {params.name}"
  
    
rule reads_qc_multiqc:
    output:
        os.path.join(RESDIR , SAMPLES_DIR, "{sample}" , "qc_reads" ,"multiqc_qc_reads_report.html"),
    input:
        LRQC = lambda wildcards: os.path.join( RESDIR , SAMPLES_DIR, "{sample}" , "qc-reads" , "nanoplot" ) if SAMPLES.get_sample_by_id(wildcards.sample).long else [],
        SRQC = lambda wildcards: os.path.join( RESDIR , SAMPLES_DIR, "{sample}" , "qc-reads" , "nanoplot" ) if SAMPLES.get_sample_by_id(wildcards.sample).forward or SAMPLES.get_sample_by_id(wildcards.sample).single else [],
    conda:
        "envs/multiqc.1.13.yaml"
    params:
        multiqc_target = os.path.join(RESDIR,  SAMPLES_DIR , "{sample}" , "qc-reads"),
        outdir = RESDIR,
        name = "multiqc_qc_reads_report.html",
    shell:
        "multiqc {params.multiqc_target} -d -dd 3 -o {params.outdir} -n {params.name}"
 
rule reads_qc_nanoplot:
    output:
        directory( os.path.join( RESDIR , SAMPLES_DIR, "{sample}" , "qc-reads" , "nanoplot" ) ),
    input:
        lambda wildcards : SAMPLES.get_sample_by_id(wildcards.sample).long,
    params:
        outdir = os.path.join( RESDIR , SAMPLES_DIR, "{sample}" ,  "qc-reads" , "nanoplot" ),
    conda:
        "envs/nanoplot.1.40.yaml"
    threads: 
        10
    shell:
        "NanoPlot --fastq {input} --loglength -o {params.outdir}  -t {threads}"


rule reads_qc_fastqc:
    output:
        directory(os.path.join(RESDIR , SAMPLES_DIR, "{sample}" ,  "qc-reads" , "fastqc")),
    input:
        lambda wildcards : SAMPLES.get_sample_by_id(wildcards.sample).forward,        
        lambda wildcards : SAMPLES.get_sample_by_id(wildcards.sample).reverse,
        lambda wildcards : SAMPLES.get_sample_by_id(wildcards.sample).single,
    params:
        outdir = os.path.join(RESDIR , SAMPLES_DIR, "{sample}" ,  "qc-reads" , "fastqc" ),
    conda:
        "envs/fastqc.0.11.9.yaml"
    threads: 
        10
    shell:
        "mkdir -p {output} && fastqc {input} -o {params.outdir} -t {threads}"


