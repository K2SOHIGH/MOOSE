#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import click
import os
import json
import logging
import yaml
import sys

try:    
    from yaml import CLoader as Loader, CDumper as Dumper
except ImportError:
    from yaml import Loader, Dumper


from workflow.utils import utils
from workflow.utils import log

logger = log.setlogger("MGW")
    
logger.setLevel(logging.INFO)
logger.addHandler(
    log.stream_handler(logging.INFO)
)

@click.group()
def cli():
    """
       decription
    """

#  .................................................................................

#                            QC COMMAND

#  .................................................................................

@click.command()

@click.option('-N', '--name' , "NAME" , required=True , type=str)

@click.option('-o', '--output-dir' , "RESDIR" , default = "." , type=str)

@click.option('-1', "R1" , default=None ,  type=str , help = "multiple libraries of forward reads can be specified [comma separation]")

@click.option('-2', "R2" , default = None , type=str , help = "multiple libraries of reverse reads can be specified [comma separation]")

@click.option('-st', '--shortreads-type'  , "ST" , default = "paired-end" , 
    type=click.Choice([ "paired-end" , "mate-pair" ], case_sensitive = False), 
    help = "specify longread source" )

@click.option('-U', "SINGLE" , default = None , type=str , help = "single reads files ")

@click.option('-L' , '--longread' , "L" , default = None , type=str , help = "multiple libraries of long-reads can be specified [comma separation]")

@click.option('-lt' , '--longread-type'  , "LT" , default = "nanopore" , 
    type=click.Choice([ "nanopore" , "pacbio" ], case_sensitive=False), 
    help = "specify longread source" )

@click.option('-s', '--snakargs', 'SNAKARGS' , type=str,
    default = "-j25 --use-conda --printshellcmds --nolock" , help = "snakemake configuration" )


def qc(NAME,RESDIR,R1,R2,ST,SINGLE,L,LT,SNAKARGS):
    """
        Run assembly
    """
    RESDIR = os.path.abspath(RESDIR)

    INPUT = utils.parse_input_files(R1,R2,ST,SINGLE,L,LT)
    
    os.makedirs( RESDIR , exist_ok=True )

    json.dump( INPUT, open( os.path.join( RESDIR , "qc-dataset.yaml" ) ,"w" ) )

    configuration = {
        "NAME" : NAME,
        "RESDIR" : RESDIR,
        "INPUT" :  os.path.join( RESDIR , "qc-dataset.yaml"),
        "SNAKARGS":SNAKARGS,
    }

    yaml.dump( configuration, open( os.path.join( RESDIR , "qc-config.yaml" ) ,"w" ) )

    SNAKEFILE =  os.path.join(os.path.dirname(__file__), 'workflow/readqc.smk')

    cmd = """
        snakemake --snakefile {snakefile} --use-conda --configfile {config} {snakargs}
    """.format( 
        snakefile = SNAKEFILE , 
        config    = os.path.join( RESDIR , "qc-config.yaml"),
        snakargs  = SNAKARGS 
    )
    
    print("running : " + cmd + " ... ")
    
    os.system(cmd)    
    



#  .................................................................................

#                            ASSEMBLY COMMAND

#  .................................................................................

@click.command()

@click.option('-N', '--name' , "NAME" , type=str)

@click.option('-o', '--output-dir' , "RESDIR" , default = "." , type=str)

@click.option('-1', "R1" , default=None ,  type=str , help = "multiple libraries of forward reads can be specified [comma separation]")

@click.option('-2', "R2" , default = None , type=str , help = "multiple libraries of reverse reads can be specified [comma separation]")

@click.option('-st', '--shortreads-type'  , "ST" , default = "paired-end" , 
    type=click.Choice([ "paired-end" , "mate-pair" ], case_sensitive = False), 
    help = "specify longread source" )

@click.option('-s', "SINGLE" , default = None , type=str , help = "single reads files ")

@click.option('-l' , '--longread' , "L" , default = None , type=str , help = "multiple libraries of long-reads can be specified [comma separation]")

@click.option('-lt' , '--longread-type'  , "LT" , default = "nanopore" , 
    type=click.Choice([ "nanopore" , "pacbio" ], case_sensitive=False), 
    help = "specify longread source" )

@click.option('-a' , '--assembler' , "ASSEMBLER" , default = ["all"] , multiple=True,
    type=click.Choice([ "megahit" , "unicycler", "spades" , "all" ], case_sensitive=False), 
    help="assembler to use, by default spades, unicycler and megahit will be ran" )

@click.option('-k' , '--k-list' , "KLIST" , default = "21,33,55,77,99" , type=str , 
    help="list of kmer length to use, --mc, --uc and --sc might take \
    precedence on -k if another list is defined"    
)

@click.option('-m','--mode' , default = 'single', 
    type=click.Choice([ "meta" , "single" ], case_sensitive=False), 
    help = "workflow mode"
)

@click.option('-mc' , default = None, type = str , help="quoted string of megahit commandline extra parameters")

@click.option('-uc' , default = None, type = str , help="quoted string of unicycler commandline extra parameters")

@click.option('-sc' , default = None, type = str , help="quoted string of spades commandline extra parameters")

@click.option('--min-quality' , default = 20, type = int , help="min quality read")

@click.option('--min-identity' , default = 95, type = int , help="min identity read")

@click.option('--min-length' , default = 100, type = int , help="min length read")

@click.option('--properly-paired/--unproperly_paired', default=True  , help="should read be properly paired ?")

@click.option('--logfile' , default = None, type = str , help="logfile")

@click.option('--snakargs', 'SNAKARGS' , type=str,
    default = "-j25 --use-conda --printshellcmds --nolock" , help = "snakemake configuration" )


def assemble(NAME, RESDIR , R1 , R2 , ST , SINGLE , L , LT , ASSEMBLER , KLIST , mode , mc , uc , sc , min_quality, min_identity, min_length , properly_paired , logfile ,  SNAKARGS ):
    """
        Run assembly
    """
    RESDIR = os.path.abspath(RESDIR)
    
    if logfile:
        logger.addHandler(
            log.file_handler(logfile,logging.info)
        )

    cprefix = os.path.join( os.path.abspath( os.path.dirname(__file__)) , "condaenv")
        
    logger.info("Snakemake will install conda environment in %s" % cprefix)
    

    if NAME is None:
        # generate one ... 
        NAME = "MGW"

    logger.info("Parsing input files ...")

    ## parse input from command line (only one sample allowed)
    logger.info("Parsing input files from commandline (one sample allowed) ...")
    
    INPUT = utils.parse_input_files(NAME, R1,R2,ST,SINGLE,L,LT)
    
    logger.info("Sample(s) to assemble : {}".format("".join(INPUT.keys())))
    
    for i,j in INPUT.items():
        if "long_reads" in j and ("right_reads" in j or "single_reads" in j):
            ASSEMBLY_TYPES = ["short_reads","long_reads","hybrid"]                        
        elif "long_reads" in j and ("right_reads" not in j or "single_reads" not in j):
            ASSEMBLY_TYPES = ["long_reads"]
            if ASSEMBLER == "megahit":
                logger.error("megahit can't perform long reads assembly.")
                exit(1)
        elif "long_reads" not in j and ("right_reads" in j or "single_reads" in j):
            ASSEMBLY_TYPES = ["short_reads"]
        else:
            logger.error("maybe you should provide reads to assemble ;)")
            exit(1)

    if "all" in ASSEMBLER:
        ASSEMBLER = ("megahit" , "unicycler", "spades")


    logger.info("Based on input files , {} assembly will be performed.".format( ", ".join(ASSEMBLY_TYPES)))
    
    logger.info("Results will be store in {}".format(RESDIR))
    
    os.makedirs( RESDIR , exist_ok=True )

    inputfile = os.path.join( RESDIR , "assembly-dataset.yaml" )
    
    json.dump( INPUT, open( inputfile ,"w" ) )
    
    configuration = {
        "NAME" : NAME,
        "RESDIR" : RESDIR,
        "INPUT" :  os.path.join( RESDIR , "assembly-dataset.yaml"),
        "ASSEMBLER" : list(ASSEMBLER),
        "ASSEMBLY_TYPES" : ASSEMBLY_TYPES,
        "KLIST": KLIST,
        "MODE":mode,
        "MEGAHIT":mc,
        "UNICYCLER":uc,
        "SPADES":sc,
        "min_quality":min_quality,
        "min_identity":min_identity,
        "min_len":min_length,
        "properly_paired":properly_paired,
        "SNAKARGS":SNAKARGS,
    }

    configfile = os.path.join( RESDIR , "assembly-config.yaml" )
    yaml.dump( configuration, open( configfile ,"w" ) )

    logger.info("Configfile : {}".format(configfile))
    logger.info("Inputfile : {}".format( inputfile ))
    
    SNAKEFILE =  os.path.join(os.path.dirname(__file__), 'workflow/assembly.smk')

    cmd = """
        snakemake --snakefile {snakefile} --use-conda --configfile {config} {snakargs}
    """.format( 
        snakefile = SNAKEFILE , 
        config    = os.path.join( RESDIR , "assembly-config.yaml"),
        snakargs  = SNAKARGS 
    )
    
    logger.info("running : \n{}\n".format( cmd ) )
    
    o = os.system(cmd)
    
    if o == 0:
        logger.info("assembly(ies) terminate with exit code 0 ! Congrats ! ")
    else:
        logger.error("Hum ... something went wrong while executing the workflow ... ")


 

cli.add_command(qc)    
cli.add_command(assemble)


if __name__ == '__main__':
    cli() 