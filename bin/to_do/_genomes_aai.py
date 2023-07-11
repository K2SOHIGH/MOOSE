import click

from moose.utils  import utils,io

MODULE = __name__.split('.')[-1]

@click.command(
        "compute-aai",
        short_help="compute all-vs-all genomes AAI.",
        context_settings=utils.CONTEXT_SETTING, 
        )

@click.option(
    '-i','--input','input_genomes',
    help = 'input genomes',
    required=True,
    type = io.InputType1()
    )

@click.option(
    '--cds',                         
    is_flag=True, 
    default=False,
    help='Skeep prodigal if files under <inputdir> are CDS fasta files.'
    )

@click.option(
    '-e','--extension',                 
    default='.fna', 
    type=io.ExtensionInputType(), 
    help = 'Genome file extension'
    )

@click.option(
    '-p','--pattern',                     
    default='', 
    type=io.PatternInputType(), 
    help = 'Genome file pattern'
    )    

@click.option(
    '-o','--output', 
    default = '{}-results'.format(MODULE),
    type=str,
    help='Output directory.'
    )

@click.option(
    '--id','AAI_ID_THRESHOLD',
    default = 0.4,                     
    help='identity threshold for reciprocal search.'
    )

@click.option(
    '--cov','AAI_COV_THRESHOLD',
    default = 0.5,                     
    help='coverage threshold for reciprocal search.'
    )

@click.pass_context
# @utils.docstring_parameter()
def compute_aai(ctx,*args,**kwargs):    
    '''All-vs-All genomes comparison for AAI computation.\n

    \x1b[33;20mINPUT\x1b[0m is either a tabular file with one genome path per line in first column and optionnaly a label in second column or
    a directory containing {pattern}*{extension} files.

    Proteomes from input genomes will be predicted using prodigal(1).\n 
    AAI will be computed between all combination of genome using MMSEQS2(2) 
    and based on EzAAI(3) workflow.
    \n
    (1) Kim, D., Park, S. & Chun, J. Introducing EzAAI: a pipeline for high throughput calculations of prokaryotic average amino acid identity. J Microbiol. 59, 476–480 (2021). https://doi.org/10.1007/s12275-021-1154-0
    \n
    (2) Steinegger, M., Söding, J. MMseqs2 enables sensitive protein sequence searching for the analysis of massive data sets. Nat Biotechnol 35, 1026–1028 (2017). https://doi.org/10.1038/nbt.3988
    \n
    (3) Hyatt, D., Chen, GL., LoCascio, P.F. et al. Prodigal: prokaryotic gene recognition and translation initiation site identification. BMC Bioinformatics 11, 119 (2010). https://doi.org/10.1186/1471-2105-11-119


    '''
 
    utils.run(MODULE,ctx)
    

if __name__=="__main__":
    compute_aai()