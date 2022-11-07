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
    SETUP
"""

RESDIR = config["RESDIR"]
SAMPLES_DIR = "SAMPLES"

products = {
    "SRO": os.path.join(
        RESDIR, SAMPLES_DIR , "{sample}", "{assembly_type}" , "{assembler}" , "{file}" ),
    "SRF": os.path.join(
        RESDIR, SAMPLES_DIR , "{sample}", "{assembly_type}" , "{assembler}" , "{file}" ),
    "bams":os.path.join(
        RESDIR , SAMPLES_DIR , "{sample}" , "{assembly_type}" , "{assembler}" , "BAMs" , "{mapper}.sorted.bam"),
}



SAMPLES = sample.Samples(config["INPUT"])
#SAMPLES_W_LR = get_sample_with_long_reads()

wlogger.info("Grabing configuration and input files =°")
ASSEMBLERS = config["ASSEMBLERS"]


if "all" in ASSEMBLERS:
    ASSEMBLERS = ["megahit" , "unicycler", "spades"]


WORKFLOWS = setup_workflows(ASSEMBLERS)
wlogger.info("workflows choosen by user  : \n\t- {}".format("\n\t- ".join(WORKFLOWS)))
wlogger.info("Assemblers choosen by user : \n\t- {}".format("\n\t- ".join(ASSEMBLERS)) )
    
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
        os.path.join(RESDIR  ,"assembly_report.html"),  
        os.path.join(RESDIR  ,"assembly.yaml"),         
        os.path.join(RESDIR  ,"bams.yaml"),         
    input:
        expand(
            os.path.join(RESDIR , SAMPLES_DIR , "{sample}" ,"assembly_report.html"),
            sample = SAMPLES.samples,
        ),
        contigs = expand(
            os.path.join(RESDIR, SAMPLES_DIR, "{sample}" , "contigsfile.yaml"),
            sample = SAMPLES.samples,
        ),
        bams = expand(
            os.path.join(RESDIR, SAMPLES_DIR, "{sample}" , "bamsfile.yaml"),
            sample = SAMPLES.samples,
        ),
        stats = os.path.join(RESDIR, SAMPLES_DIR, "assembly.stats.tsv"),
    conda:
        "envs/multiqc.1.13.yaml"     
    params:
        multiqc_target = RESDIR,
        outdir = RESDIR,
        name = "assembly_report.html",
    shell:
        "cat {input.contigs} > {output[1]} ; "
        "cat {input.bams} > {output[2]} ; "
        "rm -rf {params.outdir}/assembly_report* ; "        
        "multiqc {params.multiqc_target} -d -dd 3 -o {params.outdir} -n {params.name} "

rule assembly_make_anvio_bams_file:
    output:
        temp(os.path.join(RESDIR, SAMPLES_DIR, "{sample}" , "bamsfile.yaml")),
    input:
        get_mapping_products,         
    run:
        bams_dict = {}
        for fi in input:
            b_id = os.path.basename(fi).replace(".sorted.bam","")
            bams_dict[b_id] = os.path.abspath(fi)
        yaml.dump( { wildcards.sample : bams_dict  } ,  open(str(output) , 'w' ) ),


rule assemby_stats:
    output:
        os.path.join(RESDIR, SAMPLES_DIR, "assembly.stats.tsv"),
    input:
        expand(
            os.path.join(RESDIR, SAMPLES_DIR, "{sample}" , "{qc_contigs}-stats", "assembly.stats.tsv"),
            sample = SAMPLES.samples,
            qc_contigs = ["raw","filtered"],
        )
    shell:
        "head -n 1 {input[0]} > {output} && tail -q -n +2 {input} > {output}"



rule assembly_make_anvio_contigs_file:
    output:
        temp(os.path.join(RESDIR, SAMPLES_DIR, "{sample}" , "contigsfile.yaml")),
    input:
        get_assembly_products,            
    run:
        assembly_dict = {}
        for fi in input:
            a_id = "_".join(os.path.dirname(fi).split("/")[-2:])
            assembly_dict[a_id] = os.path.abspath(fi)
        yaml.dump( { wildcards.sample : assembly_dict  } ,  open(str(output) , 'w' ) ),

rule assembly_sample_report:
    output:
        os.path.join(RESDIR , SAMPLES_DIR , "{sample}" ,"assembly_report.html"),
    input:          
        expand(
            os.path.join(RESDIR, SAMPLES_DIR, "{{sample}}" , "{qc_contigs}-contigs-qc", "report.html"),
            qc_contigs = ["raw","filtered"]
        ),
        os.path.join(RESDIR , SAMPLES_DIR , "{sample}", "mapping.done"),
    conda:
        "envs/multiqc.1.13.yaml"     
    params:
        multiqc_target = os.path.join(RESDIR , SAMPLES_DIR , "{sample}"),
        outdir = os.path.join(RESDIR , SAMPLES_DIR , "{sample}"),
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
    input:
        os.path.join(RESDIR, SAMPLES_DIR , "{sample}","{assembly_type}" , "{assembler}" , "contigs.fa" )
    params: 
        min_contig_len = int(config["min_contig_length"]) if "min_contig_length" in config else 1000 ,
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
                                based_header = line.strip().replace(">","")
                                total_contigs += 1
                                if sequence:
                                    if len(sequence)>1000:#params.min_contig_len
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
include: "./rules/contigstats.smk"
include: "./rules/megahit.smk"
include: "./rules/spades.smk"
include: "./rules/unicycler.smk"
include: "./rules/reads_processing.smk"