#   parse command line arguments

import os
import re
import yaml
import logging
try:
    from workflow.utils import log    
    logger = log.setlogger(__name__)     
    logger.setLevel(logging.INFO)
    logger.addHandler(
        log.stream_handler(logging.INFO)
    )
except ModuleNotFoundError:
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.INFO)


def file_to_list(file):
    l = []    
    if file: 
        if os.path.exists(file):
            with open(file) as stream:
                for line in stream.readlines():
                    l.append(line.strip())
            return l
        else:
            logger.error("File doesn't exists ! [{}]".format(file))
            exit(-1)
    return l
        
def _parse_paired_end_short_reads(r1,r2):   
    
    paired_end_reads = [] 
    if r1 and r2:
        if (len(r1.split(','))!=len(r2.split(','))):
            logger.error("reverse and forward read should have the same number of input files")
            exit(-1)
        for _reads in zip(r1.split(","),r2.split(",")):
            paired_end_reads.append(";".join(list(_reads)))
        return paired_end_reads
    elif r1 or r2:
            logger.error("reverse reads should be accompanied by forward reads")    
            exit(-1)
    else:
        return None
    
def _parse_longreads(lr,lt):
    longreads={"long_reads":[]}
    longreads["long_reads_type"] = lt    
    if lr:
        longreads["long_reads"] = lr.split(",")
    return longreads

def _parse_unpaired(u):
    singlereads={"single_reads":[]}
    # singlereads[""] = "single"  
    if u:
        singlereads["single_reads"] = u.split(",")
    return  singlereads

def parse_input_files(id,r1,r2,u,lr,lt):
    """
        r1 = forward reads (left)
        r2 = reverse reads (right)
    """
    inputs = {
        id:{
            "reads":{},                        
            }
    }    
    sr = _parse_paired_end_short_reads(r1,r2)
    if sr:
        inputs[id]["reads"].update({"paired_end" : sr})                 
    if lr:         
        inputs[id]["reads"].update(_parse_longreads(lr,lt))
        inputs[id]["long_reads_type"] = lt
    if u:
        inputs[id]["reads"].update(_parse_unpaired(u))
    return inputs

##########################################################################################

# SNAKEMAKE FUNCTIONS


def _split_cmd(cmd:str , exclude:list=None):
    cmd = " "+cmd
    c = cmd.split(" -")    
    ncmd = []
    for i in c:
        k = "-%s" % str(i)
        if k.split(" ")[0] not in exclude:               
            ncmd.append(k)
    return " ".join(ncmd)

def parse_unicycler_cmdline(cmd:str):
    return _split_cmd(
        cmd,
        ["-1","-2","-l","-s","--unpaired","--long","--kmers","--threads","-t","-o","--out","--short1","--short2"]
    
    )
    
def parse_megahit_cmdline(cmd:str):
    return _split_cmd(
        cmd,
        ["-1","-2","-r","--k-list","-t","--num-cpu-threads","-o","--out-dir","--out-prefix"]
    )

def parse_spades_cmdline(cmd:str):
    return _split_cmd(
        cmd,
        ["-1","-2","--12","-s","--merged","--pe-12","--pe-1","--pe-2","--pe-s","-k"
            "--pe-m","--pe-or","--s","--mp-12","--mp-1","--mp-2","--mp-s","--mp-or",
                "--hqmp-12","--hqmp-1","--hqmp-2","--hqmp-s","--hqmp-or","--sanger","--pacbio","--nanopore"])
        