import os
import click
import multiprocessing

from moose.utils import utils,io

PRODIGAL = 'Hyatt, D., Chen, GL., LoCascio, P.F. et al. Prodigal: prokaryotic gene recognition and translation initiation site identification. BMC Bioinformatics 11, 119 (2010). https://doi.org/10.1186/1471-2105-11-119'

MODULE = os.path.basename(__file__)

MODULE = __name__.split('.')[-1]

@click.command(context_settings={'show_default': True})

@click.option(
        '-i','--input','genome_input',
        type = io.InputType1(),
        required=True,
        help='yaml file containing path to genomes files in fasta format , a fasta file or a directory containing fasta files'
        )

@click.option(
      '-e','--extension',
        type=io.ExtensionInputType(),
        default='.fna.gz',
        help='genome file extension'
    )

@click.option(
      '-p','--pattern',
        type=io.PatternInputType(),
        default='',
        help='genome file pattern'
    )

@click.option(
        '-o','--output-directory','output',
        type = str,
        default='moose-prodigal',
        help='output directory'
    )

@click.option(
        '--checkm-stats',                
        type = str,
        default=None,
        help='Set prodigal mode for each genome based on their quality [overwite --mode].'
    )    

@click.option(
        '-m','--mode',
        type = str,
        default=None,
        help='Define prodigal mode.'
    )    
    
@click.option(
        '-t','--threads',
        type = int,
        default = multiprocessing.cpu_count()-1,
        help = 'number of threads',
    )

@click.pass_context
def genecall(ctx,**kwargs):    
    '''Predict genes in input genomes using prodigal (1)\n

    (1) Hyatt, D., Chen, GL., LoCascio, P.F. et al. Prodigal: prokaryotic gene recognition and translation initiation site identification. BMC Bioinformatics 11, 119 (2010). https://doi.org/10.1186/1471-2105-11-119
    '''
    utils.run(MODULE,ctx)
