import yaml
import logging
import hashlib
from utils import utils
from utils import log
from utils import sample 



"""
    FUNCTIONS
"""


def get_assembly_products(wildcards):
    file = "final_assembly.fasta"
    if hasattr(wildcards , "qc_contigs"):
        if wildcards.qc_contigs == 'raw':
            file = "contigs.fa"    
    assemblies = []
    for workflow , assemblers in WORKFLOWS.items():
        assemblies += expand( products[workflow] , 
        sample = wildcards.sample , 
        assembly_type = workflow ,
        assembler = assemblers ,
        file = file
        )
    return assemblies

def get_mapping_products(wildcards):
    BAMS = []
    for workflow , assemblers in WORKFLOWS.items():
        BAMS += expand( products["bams"] , 
            sample = wildcards.sample , 
            assembly_type = workflow ,
            assembler = assemblers ,
            mapper = MAPPERS[wildcards.sample]
        )
    return BAMS



def get_qc_reads(wildcards , sample_id , read_type):    
    sample = SAMPLES.get_sample_by_id(sample_id)
    qc_reads = []
    attr = read_type
    if read_type == "reverse":
        attr = "forward"
    for r in sample.__dict__["_{}".format(attr)]:
        hs = hashlib.sha256(
            os.path.abspath(r).encode('utf-8')
        ).hexdigest()        
        qc_reads.append(
            os.path.join(
                RESDIR, SAMPLES_DIR , wildcards.sample, "qc_reads", "{}_{}.fq.gz".format(read_type,hs)
            )
        )    
    return qc_reads  

def get_sample_with_long_reads():    
    sample_w_lr = sample.Samples()
    for sid, SAMPLE in SAMPLES.samples.items():
        if SAMPLE.long:
            sample_w_lr.samples[sid] = SAMPLE
    return sample_w_lr

def parse_mappers():    
    f = config["MAPPERS"]
    mappers_dict = {}
    if f is not None:
        if os.path.exists(f):
            mappers_dict = yaml.load(open(f) , Loader=yaml.SafeLoader )
        else:
            wlogger.error("{} does not exist . Ciao !".format(f))
            exit(-1)
    for sid in SAMPLES.samples:
        if sid not in mappers_dict:
            mappers_dict[sid]=[sid]
    return mappers_dict    

def extend_with_coassembly():
    COASSEMBLIES = utils.file_to_list(config["COASSEMBLY"])
    coassembly_samples = {}
    for coa in COASSEMBLIES:
        samples_to_coassemble = coa.split(";")
        coassembly_id = "Co_{}".format("_".join(samples_to_coassemble)) 
        coassembly_samples[coassembly_id] = SAMPLES.merge_sample( coassembly_id , samples_to_coassemble )
    return coassembly_samples


def format_spades_paired_end_inputs(wildcards,input):
    paired_end_reads = ""
    if len(input.R1) > 1 and len(input.R2) > 1:
        shorts = zip(input.R1,input.R2)
        cpt = 1
        for r1,r2 in shorts:                       
            paired_end_reads += "--{prefix}{cpt}-1 {r1} --{prefix}{cpt}-2 {r2} ".format(
                prefix = "pe",
                cpt = cpt,
                r1 = r1,
                r2 = r2,
            )
            cpt += 1 
        return paired_end_reads
    elif len(input.R1) == 1 and len(input.R2) == 1:        
        paired_end_reads = "-1 {} -2 {}".format(
            input.R1,
            input.R2
        )          
        return paired_end_reads
    else:
        return ""
    

def format_spades_single_end_inputs(wildcards,input):
    single_end_reads = ""
    if len(input.SR) > 1:        
        cpt = 1
        for sr in input.SR:                
            single_end_reads += "-s{cpt} {sr} ".format(                
                cpt = cpt,
                sr = sr,                
            )
            cpt += 1 
    elif len(input.SR) == 1:
        single_end_reads = "-s {}".format(input.SR)        
    else:
        return ""
    return single_end_reads
    
def format_spades_long_reads_inputs(wildcards,input):
    long_reads = ""
    long_reads_type = SAMPLES.get_sample_by_id(wildcards.sample).long_reads_type
    if long_reads_type not in ["nanopore","pacbio"]:
        wlogger.error("long reads type should be either nanopore or pacbio. ")
        exit(-1)
    for lr in input.LR:        
        long_reads += "--{} {} ".format(long_reads_type, lr)        
    return long_reads 

# def format_spades_long_reads_inputs(wildcards,input):
#     long_reads = ""
#     if len(input.LR) > 1:        
#         wlogger.error("Multiple longreads files are not supported by SPADES")
#         exit(-1)
#     elif len(input.LR) == 1:
#         if SAMPLES.get_sample_by_id(wildcards.sample).long_reads_type == "nanopore":
#             long_reads = "--nanopore {}".format(input.LR)        
#         elif SAMPLES.get_sample_by_id(wildcards.sample).long_reads_type == "pacbio":
#             long_reads = "--pacbio {}".format(input.LR)        
#         else:
#             return ""
#     else:
#         return ""
#     return long_reads 

def unicycler_get_reads(wildcards , reads , reads_type):    
    if reads:
        return os.path.join(
            RESDIR, SAMPLES_DIR , wildcards.sample, "tmp" , "{}_tmp.fq.gz".format(reads_type)
        )
    return []

def concat_unicycler_input(wildcards): 
    reads = []    
    if wildcards.reads_type == "forward" or wildcards.reads_type == "reverse":
        i = 0
        if wildcards.reads_type == "reverse":
            i = 1        
        reads = [ READS[_][i] for _ in utils.get_reads( SAMPLES[wildcards.sample]["reads"] , "paired_end") ] 
    else:
        reads = [ READS[_] for _ in utils.get_reads( SAMPLES[wildcards.sample]["reads"] , wildcards.reads_type) ] 
    return reads    