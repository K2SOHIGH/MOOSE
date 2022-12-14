#   parse command line arguments

import os
import re
import tempfile
import shutil
import random
import glob
from datetime import date
import yaml
import logging
try:
    from . import log
    logger = log.setlogger(__name__)     
except ModuleNotFoundError:
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.INFO)

def bins2batches(bins,batch_size):    
    batches = {"batch-{}".format(x//batch_size):list(bins.keys())[x:x+batch_size] for x in range(0,len(bins.keys()),batch_size) if x <= len(bins.keys())}
    return batches

def get_snakefile(dir, keyword):    
    return os.path.abspath(
        glob.glob( 
            os.path.join(dir,'workflows/*{}*/*/Snakefile'.format(keyword))
            )[0]
        )

def get_anvio_db_path():
    f = os.path.abspath(os.path.join(__file__, ".." , ".." , "resources" , "anviodb.txt" )  )
    print(f)
    if os.path.exists(f):
        db = ""
        logger.info("check if {} exists ...".format(f))
        with open(f) as s:
            for line in s.readlines():
                db = line.strip()
        if os.path.isdir(db):
            logger.info("Anvio databases found here : {} ".format(db))
            return os.path.abspath(db)
        else:
            return ""                
    else:     
        logger.error("Run mako-setup-anvio-databases first")
        exit(-1)
        

def module(module,args):
    """
    temporary files were problematic 
    when executing mako module on a 
    cluster (slurm)
    """
    configdir = os.path.expanduser( '~' )
    configdir = os.path.abspath(
        os.path.join(os.path.dirname(__file__),".." )
        )        
    condastorage = os.path.join(configdir,"condaenvs")
    configstorage = os.path.join(configdir,"configfiles")
    os.makedirs(condastorage,exist_ok=True)
    os.makedirs(configstorage,exist_ok=True)
    logger.info("Running %s !" % module)    
    logger.info("Snakemake will install conda environment in %s" % condastorage)    
    configfile = os.path.join(configstorage,"config-{}.{}.{}.yaml".format(module,date.today(), random.randint(0,1000000) ))
    logger.info("Configuration file : %s" % configfile)    
    #configfile = tempfile.NamedTemporaryFile(mode="w+")  
    CONFIG = args2dict(args)    
    yaml.dump( CONFIG, open(configfile,"w") )    
    #configfile.flush()
    SNAKEFILE =  get_snakefile(os.path.join(os.path.dirname(__file__),".."),module)
    cmd = """
        snakemake --snakefile  {snakefile} -j{threads} --rerun-triggers mtime --use-conda --configfile {config} --conda-prefix {cp} {snakargs}
    """.format(
        snakefile = SNAKEFILE ,
        threads = args.threads,
        cp = condastorage,
        config = configfile,
        snakargs = args.snakargs
    )

    logger.info("""running : 
        %s """ % cmd )
    excode = os.system(cmd)
    
    if excode != 0:
        logger.error("Hum ... something went wrong while executing the workflow ... :( ")
        exit(-1)
    logger.info("Great , %s finished without error :)" % module)   
    os.remove(configfile)
    return excode 
        
def args2dict(args):
    config = {}
    for arg in vars(args):        
        config[arg] = getattr(args,arg)
    return config


def parse_profile_anvio_input(f):
    pass

def input_from_dir(input , extension):
    if input:
        if os.path.isdir(input):
            #IDS, = glob_wildcards(input + "/{id}." + extension)
            IDS = glob.glob(input + "/*" + extension)
            return {
                os.path.basename(i).split(extension)[0] : os.path.abspath(i) for i in IDS
                }

def input_from_yaml(input):
    if input:
        if os.path.exists(input):
            conff = open(input)
            datas = yaml.load(conff,Loader=yaml.FullLoader)
            return datas
        else:
            msg="""WORKFLOW INPUT : {} not found
            """
            logging.error(msg.format(input))
            raise FileNotFoundError(msg.format(input))
    else:
        return None

def input_is_fasta(input,extension):    
    if input:
        if os.path.exists(input):
            n = os.path.basename(input).split(extension)[0]
            return {n : os.path.abspath(input)}


def parse_input(input , extension):
    if input:
        if os.path.isdir(input):
            return input_from_dir(input, extension)
        elif os.path.isfile(input):
            if input.endswith(".yaml"):
                return input_from_yaml(input)
            return input_is_fasta(input,extension)
        else:
            return None
    return None


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
        