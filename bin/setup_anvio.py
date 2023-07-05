#!/usr/bin/env python
# -*- coding: utf-8 -*-

import click
from pathlib import Path
import multiprocessing
from moose.utils  import utils,io

MODULE = __name__.split('.')[-1]

@click.command('setup-anvio',
        short_help='Setup anvi\'o databases.',
        context_settings=utils.CONTEXT_SETTING, 
        )
        

@click.option('-d','--dir-anvio', 
        required=True,
        default=Path.home() / ".moose/databases/anvio",
        type=str, 
        help = 'Directory where anvio databases will be stored.')

@click.option('-o','--output', 
        required=True,
        default=Path.home() / ".moose/anvio.conf",
        type=str, 
        help = 'Anvio config file.')

@click.option('-f','--force',   
        is_flag=True,
        default=False,
        help = 'reset anvi\'o databases.')  

@click.option('-t','--threads',
        type = int,
        default = multiprocessing.cpu_count()-1,
        help = 'number of threads',
    )

@click.option('--snakargs','snakargs', 
        type=str, 
        default='',
        help='snakmake arguments')



@click.pass_context
# @utils.docstring_parameter()
def setup_anvio(ctx,*args,**kwargs):    
    '''Setup databases used by AnvIO (1).\n
    (1) Eren, A.M., Kiefl, E., Shaiber, A. et al. Community-led, integrated, reproducible multi-omics with anvi’o. Nat Microbiol 6, 3–6 (2021). https://doi.org/10.1038/s41564-020-00834-3
    '''
 
    utils.run(MODULE,ctx)
    

if __name__=="__main__":
    setup_anvio()