import os
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

wlogger.info("Grabing configuration and input files =°")
RESDIR = config["RESDIR"]
SAMPLES_DIR = "SAMPLES"


CONTIGS = yaml.load(open(config["CONTIGS"]), Loader= yaml.SafeLoader )
BAMS = yaml.load(open(config["BAMS"]), Loader= yaml.SafeLoader )

if CONTIGS:
    for s in CONTIGS:
        if s not in BAMS:
            wlogger.error("Missing bam(s) file(s) for sample {}".format(s))
            exit(-1)
else:
    wlogger.error("CONTIGs file is empty. Byebye ! ")
    exit(-1)
wlogger.info("Input files seems corrects .... continuing ")
DBFILE = os.path.join(os.path.dirname(__file__), ".." ,".anviodb.yaml")

if os.path.exists( DBFILE ) : # db already present
    wlogger.info("anvi'o databased are already installed ! Great :)")
    IS_DBFILE = True
else:
    IS_DBFILE = False
    wlogger.info("anvi'o databased are missing and will be installed !")
    dbs = {"pfam":None,"cog":None,"scg":None,"kegg":None}
    if "DBDIR" in config:
        pass
    else:
        config["DBDIR"] = None
    if config["DBDIR"]:
        dbs["pfam"] = os.path.abspath(
                    os.path.join(config["DBDIR"], "PFAM"))
        dbs["cog"] = os.path.abspath(
                    os.path.join(config["DBDIR"], "COG"))
        dbs["scg"] = os.path.abspath(
                    os.path.join(config["DBDIR"], "SCG"))
        dbs["kegg"] = os.path.abspath(
                    os.path.join(config["DBDIR"], "KEGG"))
    
wlogger.info("we can start anvi'o magic ! ")
onstart:
    wlogger.info("Anvio magic start ! ")
onerror:
    wlogger.error("an error occured during anvio-magic WORKFLOW :(")

PRODUCTS = {
    "anvio-profile": os.path.join(RESDIR , SAMPLES_DIR , "{sample}" , "AnvioMAgic" , "{assembly}" , "PROFILES", "{bam}" , "PROFILE.db" ),
    "anvio-merge": os.path.join(RESDIR , SAMPLES_DIR , "{sample}" , "AnvioMAgic" , "{assembly}" , "MERGED_PROFILES", "PROFILE.db" ),
}

def get_anvio_products(wildcards , product_type):
    template = PRODUCTS[product_type]
    files = expand(
            template, 
            sample = wildcards.sample , 
            assembly = CONTIGS[wildcards.sample], 
            bams = BAMS[wildcards.bams],
        )
    return files

rule anvio:
    input:
        expand(
            os.path.join(RESDIR , SAMPLES_DIR , "{sample}", "anvio.done"), sample = CONTIGS
        )


rule anvio_contigs_workflow:
    output:
        touch(
            temp(
                os.path.join(RESDIR , SAMPLES_DIR , "{sample}", "anvio.done")
            ),
        )
    input:
        lambda wildcards : get_anvio_products(wildcards , "anvio-merge") \
            if len(BAMS[wildcards.sample]) > 1 else \
            get_anvio_products(wildcards , "anvio-profile")
        



include: "rules/anvio.smk"