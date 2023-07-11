import click
import multiprocessing

from moose.utils  import utils,io

MODULE = __name__.split('.')[-1]

@click.command('estimate',
               short_help='Estimate genomes quality and taxonomy using AnvIO.',
               context_settings=utils.CONTEXT_SETTING, 
        )

@click.option('-i','--input','genome_input',
              type=str,
              required=True,
              type = io.InputType1(),
              help='yaml file containing path to fasta files, a fasta file or a directory containing fasta files'
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

@click.option('-o', '--output-dir', 'outputdir', 
              default = '.', 
              type=str)

@click.option('-d', '--db', 'DBDIR', 
              default = None, 
              type=str, 
              help='where anvi\'o database should be stored')
            
@click.option('--threads',
              type = int,
              default = multiprocessing.cpu_count()-1,
              help = 'number of threads',
    )

@click.option('--snakargs', 'snakargs', 
              type=str, 
              default='',
              help='snakmake arguments')

@click.pass_context
def estimate(ctx,*args,**kwargs):    
    '''Quickly estimate genomes quality and taxonomy using AnvIO (1).\n
    \n
    (1) Eren, A.M., Kiefl, E., Shaiber, A. et al. Community-led, integrated, reproducible multi-omics with anvi’o. Nat Microbiol 6, 3–6 (2021). https://doi.org/10.1038/s41564-020-00834-3
    '''
 
    utils.run(MODULE,ctx)
    

if __name__=="__main__":
    estimate()