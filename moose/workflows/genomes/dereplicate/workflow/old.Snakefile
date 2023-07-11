configfile: "config/config.yaml"

import os
import yaml
import logging
import pandas as pd

from snakemake import logger

try:
    from otto.utils import io
except:
    logger.error("Error while importing io module.")
    exit(-1)

def validate_config():
    if config["GTDB"] is None or not os.path.isdir(config["GTDB"]):
        logger.error("GTDB is missing ! See u !")
        exit(-1)
    if config["GTDB_mash"]:
        config["GTDB_mash"] = {i.split("=")[0]:i.split("=")[1]  for i in config["GTDB_mash"].split(",")}             
    return None

validate_config()
BINS = io.parse_input(config["genome_input"] , config["genome_extension"] )


if not BINS:
    logger.error("Can't retrieve your bins :( you might check your input or the genome extension.")
    exit(-1)   

tmp_dir= os.path.join(config["res_dir"],"tmp")
BATCHES = io.bins2batches(BINS,config["batch_size"])

COLUMNS = """user_genome classification
fastani_reference
fastani_reference_radius
fastani_taxonomy
fastani_ani
fastani_af
closest_placement_reference
closest_placement_taxonomy
closest_placement_ani
closest_placement_af
pplacer_taxonomy
classification_method
note
other_related_references(genome_id,species_name,radius,ANI,AF)
aa_percent
translation_table
red_value
warnings
-"""

# Conditional final target (ani results might be desired)
final_target = [os.path.join(config["res_dir"],"gtdbtk.ar53.bac120.summary.clean.tsv"),                                                     
            os.path.join(config["res_dir"],"gtdbtk.ar53.classify.tree"),
            os.path.join(config["res_dir"],"gtdbtk.bac120.classify.tree"),
            os.path.join(config["res_dir"],"identify","batch_file.tsv"),        
            ]

if config["GTDB_isani"]:
    final_target += [
        os.path.join(config["res_dir"],"gtdbtk.ani_summary.tsv"), 
        os.path.join(config["res_dir"],"gtdbtk.ani_closest.tsv")
    ]

rule target_gtdbtk:
    # GTDBTK target 
    output:
        os.path.join(config["res_dir"],"gtdb-tk.done"),
    input:
        final_target,
        config["res_dir"] + "/benchmark.txt",
    shell:
        "touch {output}"

rule expand_benchmark:
    output:                
        config["res_dir"] + "/benchmark.txt"
    input:
        align = expand(config["res_dir"] + "/benchmarks/align/{batch}.txt",batch=BATCHES.keys()),
        identify = expand(config["res_dir"] + "/benchmarks/identify/{batch}.txt",batch=BATCHES.keys()),
        classify = config["res_dir"] + "/benchmarks/classify/classify.txt"
    params:
        benchmarkdir = config["res_dir"] + "/benchmarks/"
    shell:
        "head -n +1 {input.align[0]} | sed 's/$/\tSTEP/g' >> {output} &&"
        "tail -q -n +2 {input.align} | sed 's/$/\talign/g' >> {output} && "
        "tail -q -n +2 {input.identify} | sed 's/$/\tidentify/g' >> {output} && "
        "tail -q -n +2 {input.classify} | sed 's/$/\tclassify/g' >> {output} && "
        "rm -r {params.benchmarkdir}"

rule concatenate_ani:
    output:
        os.path.join(config["res_dir"],"gtdbtk.{result}.tsv"),
    input:
        expand(os.path.join(tmp_dir,"{batch}","ani","gtdbtk.{{result}}.tsv"),batch=BATCHES.keys())
    params:
        first = lambda wildcards, input: input[0] if len(input) > 1 else input,
    shell:
        "head -n 1 {params.first} > {output} && "
        "tail -q -n +2 {input} >> {output} "
    
rule ani_rep:
    output:
        os.path.join(tmp_dir,"{batch}","ani","gtdbtk.ani_summary.tsv"),
        os.path.join(tmp_dir,"{batch}","ani","gtdbtk.ani_closest.tsv"),
    input:
        os.path.join(tmp_dir,"{batch}", 'batch_file.tsv')
    conda: 
        os.path.join("envs","gtdbtk_2.1.yaml")
    resources:
        mem= 200000 ,
        mem_mb= 200000 ,
        # time= 24:00:00, # time limit for each job
        cpus_per_task= 20,  
    threads: 
        20
    log:
        os.path.join(config['res_dir'],"logs","ani","gtdbtk_ani_{batch}.log")        
    params:
        out_dir = os.path.join(tmp_dir,"{batch}","ani"),
        gtdbtk_data = config["GTDB"],
        extension = config["genome_extension"],
        min_af = config["GTDB_fa_min_af"],
        mash_k = config["GTDB_mash"]["k"],
        mash_s = config["GTDB_mash"]["s"],
        mash_d = config["GTDB_mash"]["d"],
        mash_v = config["GTDB_mash"]["v"],
    benchmark:
        config["res_dir"] + "/benchmarks/ani/{batch}.txt"    
    shell:
        "export GTDBTK_DATA_PATH={params.gtdbtk_data}; "
        "gtdbtk ani_rep "
        "--batchfile {input} "
        "--out_dir {params.out_dir} "
        "--mash_k {params.mash_k} "
        "--mash_s {params.mash_s} "
        "--mash_d {params.mash_d} "
        "--mash_v {params.mash_v} "
        "--min_af {params.min_af} "
        "-x {params.extension} "
        "--cpus {threads} "
        "&>> {log}"

rule GTDBTK_clean_table:
    output:
        os.path.join(config["res_dir"],"gtdbtk.ar53.bac120.summary.clean.tsv")
    input:
        os.path.join(config["res_dir"],"gtdbtk.ar53.bac120.summary.tsv")
    run:            
        df = pd.read_csv(str(input),sep="\t",header=None,index_col=None)
        df.columns = COLUMNS.split()
        df.user_genome = df.user_genome.str.replace("USER_","")
        df.to_csv(str(output),sep="\t",header=True,index=False)

rule concatenate_archaea_and_bacteria_results:
    output:
        os.path.join(config["res_dir"],"gtdbtk.ar53.bac120.summary.tsv")                                            
    input:
        bac = os.path.join(config["res_dir"],"gtdbtk.bac120.summary.tsv"),
                        #"classify", 
        ar = os.path.join(config["res_dir"], "gtdbtk.ar53.summary.tsv"), 
                        #"classify", 
    shell:
        "cat {input.bac} "                # keep header from first input
        "<(tail -q -n +2 {input.ar}) "  # remove header from other input
        "> {output} "

rule GTDBTK_Classify:
    """ GTDBTk classify step on a set of genomes.

    From documentation:
        Finally, the classify step uses pplacer to find the maximum-likelihood 
        placement of each genome in the GTDB-Tk reference tree. GTDB-Tk 
        classifies each genome based on its placement in the reference tree, 
        its relative evolutionary divergence, and/or average nucleotide 
        identity (ANI) to reference genomes.
    """
    output:
        temp(os.path.join(config["res_dir"],  "gtdbtk.ar53.summary.tsv")),
        os.path.join(config["res_dir"], "gtdbtk.ar53.classify.tree"),
        temp(os.path.join(config["res_dir"], "gtdbtk.bac120.summary.tsv")),
        os.path.join(config["res_dir"], "gtdbtk.bac120.classify.tree"),
    input: 
        ##align
        os.path.join(config["res_dir"],"align", "gtdbtk.ar53.msa.fasta.gz"),
        os.path.join(config["res_dir"],"align", "gtdbtk.ar53.user_msa.fasta.gz"),
        os.path.join(config["res_dir"],"align", "gtdbtk.bac120.msa.fasta.gz"),
        os.path.join(config["res_dir"],"align", "gtdbtk.bac120.user_msa.fasta.gz"),           
        os.path.join(config["res_dir"],"align", "gtdbtk.bac120.filtered.tsv"),
        os.path.join(config["res_dir"],"align", "gtdbtk.ar53.filtered.tsv"), 
        ##identify - not used
        os.path.join(config["res_dir"],"identify", "gtdbtk.bac120.markers_summary.tsv"),
        os.path.join(config["res_dir"],"identify", "gtdbtk.translation_table_summary.tsv"),
        os.path.join(config["res_dir"],"identify", "gtdbtk.ar53.markers_summary.tsv"),
        ##batch file
        os.path.join(config["res_dir"],"identify","batch_file.tsv"),        
    conda: 
        os.path.join("envs","gtdbtk_2.1.yaml")
    resources:
        mem= 180000,
        mem_mb= 180000,
        time= "10-12", # time limit for each job
        nodes= 1,
        cpus_per_task= 15,           
    threads: 
        15
    log:
        os.path.join(config["res_dir"],"logs","gtdbtk_classify_all.log")
    params:
        extension = config["genome_extension"],
        align_dir = os.path.join(config["res_dir"]),
        outdir = os.path.join(config["res_dir"]),
        batchfile = os.path.join(config["res_dir"],"identify","batch_file.tsv"),
        gtdbtk_data = config["GTDB"],
    benchmark:
        config["res_dir"] + "/benchmarks/classify/classify.txt"    
    shell:
        "export GTDBTK_DATA_PATH={params.gtdbtk_data}; "
        "gtdbtk classify "
        "--batchfile {params.batchfile} "
        "--extension {params.extension} "
        "--align_dir {params.align_dir} "
        "--out_dir {params.outdir} "
        "--cpus {threads} &>> {log} && touch {output} "

rule keepBatch:
    output:
        os.path.join(config["res_dir"],"identify","batch_file.tsv"),
    input:
        os.path.join(tmp_dir,"batch_file.tsv"),
    params: 
        p = os.path.join(config['merge_with'],"identify",'batch_file.tsv') if config['merge_with'] \
            else "" ,
    shell:
        "cat {input} > {output} ; "
        "if [ ! -z {params.p} ] ; then "
        "   cat {params.p} >> {output} ; "
        "fi"

rule merge_batches_tsv_identify:
    output:
        os.path.join(config["res_dir"],"identify", "gtdbtk.{resultfile}.tsv"),
    input:
        expand(os.path.join(tmp_dir,"{batch}","identify", "gtdbtk.{{resultfile}}.tsv"),batch=BATCHES.keys())
    threads: 
        1
    params:
        first = lambda wildcards, input: input[0] if len(input) > 1 else input,
        p = os.path.join(config['merge_with'],"identify","gtdbtk.{resultfile}.tsv") if config['merge_with'] \
            else "" ,    
    shell:
        "head -n 1 {params.first} > {output} && "
        "tail -q -n +2 {input} >> {output} && "
        "if [ ! -z {params.p} ] ; then "
        "   tail -q -n +2  {params.p} >> {output} ; "
        "fi && touch {output}"            

rule merge_batches_tsv_align:
    output:
        os.path.join(config["res_dir"],"align", "gtdbtk.{resultfile}.tsv"),
    input:
        expand(os.path.join(tmp_dir,"{batch}","align", "gtdbtk.{{resultfile}}.tsv"),batch=BATCHES.keys())
    threads: 
        1
    params:
        first = lambda wildcards, input: input[0] if len(input) > 1 else input,
        p = os.path.join(config['merge_with'],"align","gtdbtk.{resultfile}.tsv") if config['merge_with'] \
            else "" ,            
    shell:
        "head -n 1 {params.first} > {output} && "
        "tail -q -n +2 {input} >> {output}  && "     
        "if [ ! -z {params.p} ] ; then "
        "   tail -q -n +2  {params.p} >> {output} ; "
        "fi && touch {output}"

rule merge_batches_fasta_align:
    """ Merge fasta files from previous steps, so we only have
    one tree for all the genomes (and not one tree per batch) after
    the Classify step.
    """
    output:
        os.path.join(config["res_dir"],"align","gtdbtk.{resultfile}.fasta.gz"),
    input:
        expand(os.path.join(tmp_dir,"{batch}","align","gtdbtk.{{resultfile}}.fasta.gz"),batch=BATCHES.keys()) 
    threads: 
        1
    params: 
        p = os.path.join(config['merge_with'],"align",'gtdbtk.{resultfile}.fasta.gz') if config['merge_with'] \
            else "" ,
    shell:
        "cat {input} > {output} ; "
        "if [ ! -z {params.p} ] ; then "
        "   cat {params.p} >> {output} ; "
        "fi"

rule GTDBTK_Align:
    """ GTDBTk align step on a given batch of genomes.

    From documentation:
        The align step concatenates the aligned marker genes and filters the 
        concatenated Multiple Sequence Alignments (MSA) to approximately 
        5,000 amino acids.
    """
    output:
        os.path.join(tmp_dir,"{batch}","align","gtdbtk.ar53.msa.fasta.gz"),
        os.path.join(tmp_dir,"{batch}","align","gtdbtk.ar53.user_msa.fasta.gz"),
        os.path.join(tmp_dir,"{batch}","align","gtdbtk.ar53.filtered.tsv"),
        os.path.join(tmp_dir,"{batch}","align","gtdbtk.bac120.msa.fasta.gz"),
        os.path.join(tmp_dir,"{batch}","align","gtdbtk.bac120.user_msa.fasta.gz"),
        os.path.join(tmp_dir,"{batch}","align","gtdbtk.bac120.filtered.tsv"),
    input:
        os.path.join(tmp_dir,"{batch}","identify","gtdbtk.bac120.markers_summary.tsv"),
        os.path.join(tmp_dir,"{batch}","identify","gtdbtk.translation_table_summary.tsv"),
        os.path.join(tmp_dir,"{batch}","identify","gtdbtk.ar53.markers_summary.tsv"),
    conda: 
        os.path.join("envs","gtdbtk_2.1.yaml")
    resources:
        mem= 125000,
        mem_mb= 125000,
        time= "7-12", # time limit for each job
        nodes= 1,
        cpus_per_task= 10,           
    threads: 
        10
    log:
        os.path.join(config['res_dir'],"logs","align","gtdbtk_align_{batch}.log")
    params:
        batch_dir = os.path.join( tmp_dir, "{batch}" ),
        gtdbtk_data = config["GTDB"],
    benchmark:
        config["res_dir"] + "/benchmarks/align/{batch}.txt"            
    shell:
        "export GTDBTK_DATA_PATH={params.gtdbtk_data}; "
        "gtdbtk align "
        "--identify_dir {params.batch_dir} "
        "--out_dir {params.batch_dir} "
        "--cpus {threads} "
        "&>> {log} "
        "&& touch {output} " #touch output to avoid missing file i.e ar53 missing files in most cases


rule GTDBTK_Identify:
    """ GTDBTk identify step on a given batch of genomes.
    From documentation:
        The identify step calls genes using Prodigal, and uses HMM models and 
        the HMMER package to identify the 120 bacterial and 122 archaeal marker 
        genes used for phylogenetic inference. Multiple sequence alignments 
        (MSA) are obtained by aligning marker genes to their respective HMM 
        model. 
    """
    output:
        os.path.join(tmp_dir,"{batch}","identify","gtdbtk.bac120.markers_summary.tsv"),
        os.path.join(tmp_dir,"{batch}","identify","gtdbtk.translation_table_summary.tsv"),
        os.path.join(tmp_dir,"{batch}","identify","gtdbtk.ar53.markers_summary.tsv"),
    input:
        os.path.join(tmp_dir,"{batch}", 'batch_file.tsv')
    conda: 
        os.path.join("envs","gtdbtk_2.1.yaml")
    resources:
        mem = 200000,
        mem_mb = 200000,
        time= "7-12", # time limit for each job
        nodes= 1,
        cpus_per_task= 20,           
    threads: 
        20   
    params:
        extension = config["genome_extension"],
        batch_dir = os.path.join(tmp_dir,"{batch}"),
        gtdbtk_data = config["GTDB"]#os.path.abspath(os.path.join("Database","release89")),
    benchmark:
        config["res_dir"] + "/benchmarks/identify/{batch}.txt"
    log:
        os.path.join(config['res_dir'],"logs","taxonomy", "gtdbtk_identify_{batch}.log")
    shell:
        "export GTDBTK_DATA_PATH={params.gtdbtk_data}; "
        "gtdbtk identify "
        "--batchfile {input} "
        "--extension {params.extension} "
        "--out_dir {params.batch_dir} "
        "--cpus {threads} "
        "&>> {log} "


rule expand_batch_file:
    output:
        os.path.join(tmp_dir,"batch_file.tsv")
    input:
        expand(os.path.join(tmp_dir,"{batch}", 'batch_file.tsv'),batch=BATCHES.keys())
    shell:
        "cat {input} > {output}"

rule gtdb_bins_into_batches:
    output:
        os.path.join(tmp_dir,"{batch}", 'batch_file.tsv')
    input:
        lambda wildcards: [BINS[i] for i in BATCHES[wildcards.batch]],
    threads: 
        1
    params:
        bins_tuple = lambda wildcards: [(BINS[i],i) for i in BATCHES[wildcards.batch]],
    script:
        os.path.join('scripts','create_batch_file.py')          
