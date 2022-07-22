import json


from utils import utils

RESDIR = config["RESDIR"]
INPUTFILE = config["INPUT"]

INPUTS = json.load(open(INPUTFILE))
ASSEMBLER = ["megahit","unicycler","spades"]


rule assembly:
    input:
        expand(
            os.path.join(RESDIR , "{sample}" , "contig-qc" ,"multiqc_report.html"),
            sample = [config["NAME"]],
        ),
        # expand(
        #     os.path.join( RESDIR,"{sample}", "profiles", "{assembler}_profile", "PROFILE.db" ),
        #     assembler = ASSEMBLER,
        #     sample = [config["NAME"]],   
        # )

rule contigs_qc:
    output:
        os.path.join(RESDIR , "{sample}" , "contig-qc" ,"multiqc_report.html"),
    input:
        expand(
            os.path.join(
                RESDIR , "{{sample}}", "bam" , "{{sample}}_{assembler}.sorted.bam"
            ),            
            assembler = ASSEMBLER,
        ),       
        expand(
            os.path.join(RESDIR, "{{sample}}" , "contigs-qc","report.html"),            
        )    
    conda:
        "./envs/multiqc.yaml"     
    params:
        multiqc_target = RESDIR,
        outdir = os.path.join(RESDIR , "{sample}" , "contig-qc"),
    shell:
        "multiqc {params.multiqc_target} -d -dd 3 -o {params.outdir}"


def get_contigs(wildcards):
    if wildcards.assembler == "megahit":
        return os.path.join(
            RESDIR , "{sample}", "megahit" , "final.contigs.fa"
        )
    if wildcards.assembler == "unicycler":
        return os.path.join( 
            RESDIR , "{sample}", "unicycler","assembly.fasta")
    
    if wildcards.assembler == "spades":
        return os.path.join( 
            RESDIR , "{sample}", "spades","contigs.fasta")


rule reformat_contigs:
    """
        reformat contigs for anvi'o
    """
    output:
        contigs = os.path.join(
            RESDIR , "{sample}", "contigs" , "{sample}.{assembler}.contigs.fa"
        ),
        tsv =  os.path.join(
            RESDIR , "{sample}", "tables" , "{sample}.{assembler}.contigs.tsv"
        ),
    input:
        get_contigs,
    run:
        contig = 0
        with open(str(output.tsv),"w") as tblout:
            with open(str(output.contigs),'w') as fastaout:
                with open(str(input),'r') as streamin:
                    for line in streamin.readlines():
                        if line.startswith(">"):
                            contig+=1
                            contigid = "c_%i" % contig
                            fastaout.write( ">%s\n" % contigid )
                            tblout.write( "%s\t%s\n" %  ( line[1:] , contigid ) )
                        else:
                            fastaout.write( line )


include: "./rules/anvio.smk"
include: "./rules/contigs_quality.smk"
include: "./rules/bowtie2.smk"
include: "./rules/megahit.smk"
include: "./rules/spades.smk"
include: "./rules/unicycler.smk"                            