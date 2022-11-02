import yaml
import logging
import hashlib
from utils import utils
from utils import log
from utils import sample 

"""
    FUNCTIONS
"""

def get_sro_assembly_products(wildcards):
    """

    """
    if wildcards.qc_contigs == 'raw':
        file = "contigs.fa"
    else:
        file = "final_assembly.fasta"
    if "SRO" in WORKFLOWS:
        if get_qc_reads(wildcards, wildcards.sample , "forward") or \
            get_qc_reads(wildcards, wildcards.sample , "single"):
            return expand(
                os.path.join(RESDIR, SAMPLES_DIR , "{{sample}}", "{assembly_type}" , "{assembler}" , file ),
                assembly_type = "SRO" , assembler = ASSEMBLERS,
            )
    return []

def get_srf_lrf_assembly_products(wildcards):
    """

    """
    if wildcards.qc_contigs == 'raw':
        file = "contigs.fa"
    else:
        file = "final_assembly.fasta"

    wlr_workflows = [ w for w in WORKFLOWS if w != "SRO" ]
    
    if wlr_workflows and LR_ASSEMBLERS:
        if get_qc_reads(wildcards, wildcards.sample , "long"):            
            return expand(
                os.path.join(RESDIR, SAMPLES_DIR , "{{sample}}", "{assembly_type}" , "{assembler}" , file ),
                assembly_type = wlr_workflows , assembler = LR_ASSEMBLERS,
            )
    return []

def get_sro_mapping_products(wildcards):
    if "SRO" in WORKFLOWS:
        if get_qc_reads(wildcards, wildcards.sample , "forward") or \
            get_qc_reads(wildcards, wildcards.sample , "single"):
            return expand(
                os.path.join(RESDIR , SAMPLES_DIR , wildcards.sample , "{assembly_type}" , "{assembler}" , "BAMs" , "{mapper}.sorted.bam"),
                assembly_type = "SRO" , assembler = ASSEMBLERS , mapper = MAPPERS[wildcards.sample]
            )
    return []

def get_srf_lrf_mapping_products(wildcards):
    wlr_workflows = [ w for w in WORKFLOWS if w != "SRO" ]
    if  WORKFLOWS and LR_ASSEMBLERS:
        if get_qc_reads(wildcards, wildcards.sample , "long"):        
            return expand(
                os.path.join(RESDIR , SAMPLES_DIR , wildcards.sample , "{assembly_type}" , "{assembler}" , "BAMs" , "{mapper}.sorted.bam"),
                assembly_type = wlr_workflows , assembler = ASSEMBLERS , mapper = MAPPERS[wildcards.sample]
            )
    return []    

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

def validate_samples():    
    wlogger.info("Number of sample(s) : {}".format(len(SAMPLES.samples))    )
    wlogger.info("Validating SAMPLE files and configuration ...")    
    for sid, SAMPLE in SAMPLES.samples.items():        
        if "auto" not in WORKFLOWS:             
            if (len(SAMPLE.forward)==0 or len(SAMPLE.single)==0) and ("SRO" in WORKFLOWS or "hybrid" in WORKFLOWS) :
                wlogger.error("Can't perform SRO, SRF neither LRF assembly if you don't provide short reads [{}]".format(sid))
                exit(-1)                
            if (len(SAMPLE.long)==0 )  and ("SRF" in WORKFLOWS or "LRF" in WORKFLOWS) :
                wlogger.error("Can't perform SRF / LRF assembly if you don't provide long reads [{}]".format(sid))
                exit(-1)    
    wlogger.info("Things seems good .... but who know ?")  

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
    elif len(input.R1) == 1 and len(input.R2) == 1:
        paired_end_reads = "-1 {} -2 {}".format(
            input.R1,
            input.R2
        )        
    else:
        return ""
    return paired_end_reads

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
    if len(input.LR) > 1:        
        wlogger.error("Multiple longreads files are not supported by SPADES")
        exit(-1)
    elif len(input.LR) == 1:
        if SAMPLES.get_sample_by_id(wildcards.sample).long_reads_type == "nanopore":
            long_reads = "--nanopore {}".format(input.LR)        
        elif SAMPLES.get_sample_by_id(wildcards.sample).long_reads_type == "pacbio":
            long_reads = "--pacbio {}".format(input.LR)        
        else:
            return ""
    else:
        return ""
    return long_reads 

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