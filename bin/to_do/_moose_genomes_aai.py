# #!/usr/bin/env python3
# # -*- coding: utf-8 -*-
# import os
# import argparse
# import multiprocessing

# from moose.utils  import utils

# MMSEQS2 = "Steinegger, M., Söding, J. MMseqs2 enables sensitive protein sequence searching for the analysis of massive data sets. Nat Biotechnol 35, 1026–1028 (2017). https://doi.org/10.1038/nbt.3988"
# EZAAI = "Kim, D., Park, S. & Chun, J. Introducing EzAAI: a pipeline for high throughput calculations of prokaryotic average amino acid identity. J Microbiol. 59, 476–480 (2021). https://doi.org/10.1007/s12275-021-1154-0"
# PRODIGAL = "Hyatt, D., Chen, GL., LoCascio, P.F. et al. Prodigal: prokaryotic gene recognition and translation initiation site identification. BMC Bioinformatics 11, 119 (2010). https://doi.org/10.1186/1471-2105-11-119"

# MODULE = os.path.basename(__file__)

# def get_args():
#     parser = argparse.ArgumentParser(
#         prog=MODULE,
#         description="""
#         All-vs-All genomes comparison for AAI computation.

#         Proteomes from input genomes will be predicted using prodigal(1). 
#         AAI will be computed between all combination of genome using MMSEQS2(2) 
#         and based on EzAAI(3) workflow.

#         (1) {}
#         (2) {}
#         (3) {}
#         """.format(PRODIGAL,MMSEQS2,EZAAI), 
#         formatter_class=argparse.RawTextHelpFormatter)

#     parser.add_argument('-i', 
#                         "--input", 
#                         dest='inputdir' , 
#                         required=True, 
#                         type=str, 
#                         help = "input directory.")
    
#     parser.add_argument('--cds',                         
#                         dest='cds',
#                         action='store_true',                        
#                         help='Skeep prodigal if files under <inputdir> are CDS fasta files.')
    
#     parser.add_argument('-e', 
#                         "--extension", 
#                         dest='extension' , 
#                         default='.fna', 
#                         type=str, 
#                         help = "Genome file extension. [.fna]")
    
#     parser.add_argument('-p', 
#                         "--pattern", 
#                         dest='pattern' , 
#                         default=None, 
#                         type=str, 
#                         help = "Genome file pattern. [None]")    
 
#     parser.add_argument('-o', 
#                         '--output', 
#                         dest='output',
#                         default = "{}-results".format(MODULE),
#                         type=str,
#                         help='Output directory.')

#     parser.add_argument('--id',                          
#                         dest='AAI_ID_THRESHOLD',                        
#                         default = 0.4,                     
#                         help='identity threshold for reciprocal search.')

#     parser.add_argument('--cov',                          
#                         dest='AAI_COV_THRESHOLD',                        
#                         default = 0.5,                     
#                         help='coverage threshold for reciprocal search.')

#     parser.add_argument('--debug',                         
#                         dest='debug',
#                         action='store_true',                        
#                         help='debug mode.')

#     parser.add_argument(        
#         '--threads',
#         type = int,
#         default = multiprocessing.cpu_count()-1,
#         help = "number of threads",
#     )

#     parser.add_argument('--snakargs', dest='snakargs', type=str, default="",
#             help='snakmake arguments')

#     args = parser.parse_args()
#     return args




import click



@click.command()
def AAI():
    click.echo("Hello, World!")

@click.command()
def AAI2():
    click.echo("Hello, World!")