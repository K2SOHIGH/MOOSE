#   parse command line arguments

import os
import re
from workflow.utils import log
import logging



# logger = logging.get_logger()

def _parse_shortreads(r1,r2,st):
    shortreads = {"right_reads":[], "left_reads":[] , "short_reads_type": ""}
    if st == "paired-end":        
        left = r1 
        right = r2
    else:
        left = r2
        right = r1

    shortreads["short_reads_type"] = st    
    
    if right and left:
        if (len(right.split(','))==len(left.split(','))) : # check if both r1 and r2 are defined and if the number of forward reads input files == the reverse ones            
            shortreads["right_reads"] = right.split(",")            
            shortreads["left_reads"] = left.split(",")
            return  shortreads
        else:
            raise NameError("reverse and forward read should have the same number of input files")
    elif right or left:
            raise NameError("reverse reads should be accompanied by forward reads")    
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

def parse_input_files(id,r1,r2,st,u,lr,lt):
    """
        r1 = forward reads (left)
        r2 = reverse reads (right)
    """
    inputs = {id:{}}

    sr = _parse_shortreads(r1,r2,st)
    if sr:
        inputs[id].update(sr) 
    if lr:         
        inputs[id].update(_parse_longreads(lr,lt))
    if u:
        inputs[id].update(_parse_unpaired(u))
    return inputs





def set_megahit_input_cmdline(sample_input):
    input_commandline = []
    if all(value in sample_input for value in ["left_reads","right_reads"]):
        input_commandline.append(
            "-1 {}".format(",".join(sample_input["left_reads"]))
        )
        input_commandline.append(
            "-2 {}".format(",".join(sample_input["right_reads"]))
        )
    if "single_reads" in sample_input:
        input_commandline.append(
            "-r {}".format(",".join(sample_input["single_reads"]))
        )
    return " ".join(input_commandline)

def set_spades_input_cmdline(sample_input , assembly_type = "hybrid"):
    input_commandline = []
    
    paired_end_reads = ""
    
    if all(value in sample_input for value in ["left_reads","right_reads"]):
        if sample_input["short_reads_type"] == "paired-end":
            prefix="pe"
        else:
            prefix="mp"
        
        if len(sample_input["left_reads"]) > 1 :
            shorts = zip(sample_input["left_reads"],sample_input["right_reads"])
            cpt = 1
            for r1,r2 in shorts:                
                paired_end_reads += "--{prefix}{cpt}-1 {r1} --{prefix}{cpt}-2 {r2} ".format(
                    prefix = prefix,
                    cpt = cpt,
                    r1 = r1,
                    r2 = r2,
                )
                cpt += 1 
        else:
            paired_end_reads = "-1 {} -2 {}".format(
                sample_input["left_reads"][0],
                sample_input["right_reads"][0]
            )
    single_reads = ""
    if "single_reads" in sample_input:        
        if len(sample_input["single_reads"])>1:
            cpt=1
            for sr in sample_input["single_reads"]:
                single_reads += "-s{} {} ".format(cpt,sr)
                cpt+=1
        else:
            single_reads = "-s {}".format( "".join(sample_input["single_reads"][0]) )

    long_reads = ""
    if "long_reads" in sample_input:
        if len(sample_input["long_reads"])>1:
            raise NameError("Multiple longreads files are not supported by SPADES")
        elif len(sample_input["long_reads"])==1:
            long_reads = "--nanopore {}".format(sample_input["long_reads"][0])
        else:
            pass
            
    if assembly_type == "long_reads":
        return long_reads
    elif assembly_type == "short_reads":
        return  " ".join( [paired_end_reads , single_reads])
    else:
        return " ".join( [paired_end_reads , single_reads , long_reads]  )

def set_unicycler_input_cmdline(unicycler_input_files, assembly_type="hybrid"):

    for file in unicycler_input_files:
        paired_end_reads = ""
        if re.search("left_reads", file):
            paired_end_reads += "-1 {} ".format(file)
        if re.search("right_reads", file):
            paired_end_reads += "-2 {} ".format(file)
        single_reads = ""
        if re.search("single_reads", file):
            single_reads = "-s {} ".format(file)
        long_reads = ""
        if re.search("long_reads", file):
            long_reads = "-l {} ".format(file)
    
    if assembly_type == "longread_only":
        return long_reads
    elif assembly_type == "shortread_only":
        return  " ".join( [paired_end_reads , single_reads])
    else:
        return " ".join( [paired_end_reads , single_reads , long_reads]  )
            


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
        ["-1","-2","--12","-s","--merged","--pe-12","--pe-1","--pe-2","--pe-s",
            "--pe-m","--pe-or","--s","--mp-12","--mp-1","--mp-2","--mp-s","--mp-or",
                "--hqmp-12","--hqmp-1","--hqmp-2","--hqmp-s","--hqmp-or","--sanger","--pacbio","--nanopore"]
        )


def get_reads(INP,reads_type):
    if reads_type in INP:            
        return INP[reads_type]
    return []