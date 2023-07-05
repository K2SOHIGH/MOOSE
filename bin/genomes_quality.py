import click
import multiprocessing
from moose.utils  import utils,io

MODULE = __name__.split('.')[-1]

@click.command(context_settings={'show_default': True})
@click.option(
      '-i','--input','genome_input',
        type=io.InputType1(),
        required=True,
        help='yaml file containing path to fasta files , a fasta file or a directory containing fasta files'
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
      '-o','--output','output',
        default = '{}-results'.format(MODULE),                     
        type=str,
        help='output directory'
    )

@click.option(
      '--tmp','TMP',
        default=None,
        type=str,
        help='temporary directory'
    )

@click.option(
      '-d','--checkm-datas','CheckM_data',
        type=str,        
        required=True,
        help='path to checkm datas',
    )

@click.option(
      '-z','--batch-size',
        default=1000,
        type=int,
        help='number of genomes to process at once'
    )

@click.option(
      '-m','--low-memory',        
        is_flag=True,
        help='low memory mode'
    )

@click.option(
      '-t','--taxonomy','taxonomy_wf',
        type=str,
        default = None,
        help='taxonomy mode enable, take a string "rank;taxon" are required'
    )

@click.option(        
      '--threads',
        type = int,
        default = multiprocessing.cpu_count()-1,
        help = 'number of threads',
    )


@click.pass_context
def quality(ctx,**kwargs):    
    '''Estimate genomes' quality using CheckM (1)\n
    (1) Parks DH, Imelfort M, Skennerton CT, Hugenholtz P, Tyson GW. 
    CheckM: assessing the quality of microbial genomes recovered from isolates, single cells, and metagenomes. 
    Genome Res. 2015 Jul;25(7):1043-55. doi: 10.1101/gr.186072.114. Epub 2015 May 14. PMID: 25977477; PMCID: PMC4484387.
    '''
    
    utils.run(MODULE,ctx)



