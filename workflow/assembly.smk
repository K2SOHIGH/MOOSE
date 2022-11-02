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

ASSEMBLERS = config["ASSEMBLERS"]
LR_ASSEMBLERS = [a for a in ASSEMBLERS if a != "megahit"]

WORKFLOWS = config["WORKFLOWS"]
SAMPLES = sample.Samples(config["INPUT"])
SAMPLES_W_LR = get_sample_with_long_reads()


"""
    SETUP
"""
wlogger.info("Grabing configuration and input files =°")
validate_samples()

SAMPLES.samples.update( 
    extend_with_coassembly() 
)

MAPPERS = parse_mappers()

READS = SAMPLES.sample2reads()    
wlogger.info("we can start assembling ! ")
onstart:
    wlogger.info("Starting assembly WORKFLOW")
onerror:
    wlogger.error("an error occured during assembly WORKFLOW :(")

rule assembly:
    output:                
        os.path.join(RESDIR  ,"assembly_report.html")            
    input:
        expand(
            os.path.join(RESDIR , SAMPLES_DIR , "{sample}" ,"assembly_report.html"),
            sample = SAMPLES.samples,
        )
    conda:
        "envs/multiqc.1.13.yaml"     
    params:
        multiqc_target = RESDIR,
        outdir = RESDIR,
        name = "assembly_report.html",
    shell:
        "multiqc {params.multiqc_target} -d -dd 3 -o {params.outdir} -n {params.name}"

    
rule assembly_sample_report:
    output:
        os.path.join(RESDIR , SAMPLES_DIR , "{sample}" ,"assembly_report.html"),
    input:          
        expand(
            os.path.join(RESDIR, SAMPLES_DIR, "{{sample}}" , "contigs-qc", "{qc_contigs}_contigs_report.html"),
            qc_contigs = ["raw","afterqc"]
        ),
        os.path.join(RESDIR , SAMPLES_DIR , "{sample}", "mapping.done"),
    conda:
        "envs/multiqc.1.13.yaml"     
    params:
        multiqc_target = os.path.join(RESDIR , SAMPLES_DIR , "{sample}"),
        outdir = RESDIR,
        name = "assembly_report.html",
    shell:
        "multiqc {params.multiqc_target} -d -dd 3 -o {params.outdir} -n {params.name}"

rule assembly_filtering:
    """
        filter contigs below a certain size and reformat contigs names for anvi'o
    """
    output:
        contigs =os.path.join( 
            RESDIR , SAMPLES_DIR, "{sample}","{assembly_type}" , "{assembler}" ,  "final_assembly.fasta"
        ),
        tsv =  os.path.join(
            RESDIR, SAMPLES_DIR , "{sample}","{assembly_type}" , "{assembler}" , "contigs_table.tsv"
        ),
        txt =  os.path.join(
            RESDIR, SAMPLES_DIR , "{sample}","{assembly_type}" , "{assembler}" , "contigs_filterout.txt"
        ),
    params:
        min_contig_len = config["min_contig_length"] if "min_contig_length" in config else 1000 ,
    input:
        os.path.join(RESDIR, SAMPLES_DIR , "{sample}","{assembly_type}" , "{assembler}" , "contigs.fa" )
    run:
        contig = 0
        total_contigs = 0
        filter_out_contig = 0
        with open(str(output.tsv),"w") as tblout:
            with open(str(output.txt),'w') as txtout:
                with open(str(output.contigs),'w') as fastaout:
                    with open(str(input),'r') as streamin:
                        sequence = ""
                        for line in streamin.readlines():
                            if line.startswith(">"):
                                based_header = line.strip().replace(">")
                                total_contigs += 1
                                if sequence:
                                    if len(sequence)>params.min_contig_len:
                                        contigid = "c_{}".format(contig) 
                                        fastaout.write( ">{}\n".format(contigid) )
                                        fastaout.write( "{}\n".format(sequence) )                                    
                                        tblout.write( "{}\t{}\t{}\n".format( line[1:] , contigid , wildcards.sample) )
                                        contig+=1
                                        sequence = "" #reset sequence
                                    else:
                                        txtout.write("{}\n".format( based_header)) 
                                        filter_out_contig += 1
                            else:
                                sequence += line.strip()
                            

include: "./rules/bowtie2.smk"
include: "./rules/contigs_quality.smk"
include: "./rules/megahit.smk"
include: "./rules/spades.smk"
include: "./rules/unicycler.smk"
include: "./rules/reads_processing.smk"