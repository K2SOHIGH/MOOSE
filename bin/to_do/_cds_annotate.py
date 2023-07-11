#!/usr/bin/env python
# -*- coding: utf-8 -*-

import click
from pathlib import Path
import multiprocessing
from moose.utils  import utils,io
from bin.cli_setting import CONTEXT_SETTING

MODULE = __name__.split('.')[-1]

# def find_interpro():
#     f = os.path.abspath(os.path.join(__file__, '..' , '..' , 'resources' , 'interproscan.txt' ) )
#     print(f)
#     if os.path.exists(f):
#         interprodir = open(f).read()
#         if os.path.isdir(interprodir):
#             return interprodir
#     return None
        
@click.command('annotate',
        short_help='Annotate CDS using interproscan.',
        context_settings=CONTEXT_SETTING, 
        )
        
@click.option('-i','--input','INPUT',
        type = io.InputType1(),
        required=True,
        help='yaml file containing path to translated cds files , a fasta file or a directory containing fasta files'
        )

@click.option(
      '-e','--extension',
        type=io.ExtensionInputType(),
        default='.fna.gz',
        help='files extension'
    )

@click.option(
      '-p','--pattern',
        type=io.PatternInputType(),
        default='',
        help='files pattern'
    )

@click.option('--type',
        default='proteic',
        type=click.Choice(['proteic','nucleic'], case_sensitive=False),
        help= 'input sequences type'
    )

@click.option('-o','--output-directory','RESDIR',
        type = str,
        default='moose_cds_annota_res',
        help='output directory'
    )

@click.option('--interproscan-dir',                
        type = str,
        # default=find_interpro(),
        # help='path to interproscan directory [default : {}]'.format(find_interpro())
    )    

@click.option('-t','--threads',
        type = int,
        default = multiprocessing.cpu_count()-1,
        help = 'number of threads',
    )

@click.pass_context
def annotate(ctx,**kwargs):    
    '''Annotate CDS using interproscan (1)\n

    (1) Philip Jones and others, InterProScan 5: genome-scale protein function classification, Bioinformatics, Volume 30, Issue 9, May 2014, Pages 1236–1240, https://doi.org/10.1093/bioinformatics/btu031
    '''
    utils.run(MODULE,ctx)


