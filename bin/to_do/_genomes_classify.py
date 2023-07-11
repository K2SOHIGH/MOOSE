import click
import multiprocessing
from moose.utils  import utils,io

MODULE = __name__.split('.')[-1]

@click.command(context_settings={'show_default': True})
@click.option('-i','--input','genome_input',
        type = io.InputType1(),
        required=True,
        help='yaml file containing path to translated cds files , a fasta file or a directory containing fasta files'
        )

@click.option('-e','--extension',
        type=io.ExtensionInputType(),
        default='.fna.gz',
        help='genome file extension'
    )

@click.option('-p','--pattern',
        type=io.PatternInputType(),
        default='',
        help='genome file pattern'
    )


@click.option('-o','--output',
        type = str,
        default = '{}-results'.format(MODULE),                     
        help='output directory'
    )

@click.option('--merge-with',        
        type = str,
        default=None,
        help='path to another gtdb-wf results directory'
    )    

@click.option('--gtdb-datas','GTDB',
        type = str,
        required=True,
        help='path to GTDB database'
    )

@click.option(
        '-z','--batch-size',
        type = int,
        default=1000,
        help='number of genomes to process at once'
    )



@click.option('--ani','GTDB_isani',
        is_flag=True,
        help='run GTDB ANI workflow'
    )

@click.option('--gtdb-mash-params','GTDB_mash',
        type = str,
        default = 'k=16,s=5000,d=0.1,v=1.0',
        help='mash parmameters'
    )

@click.option('--gtdb-fmf','GTDB_fa_min_af', 
        type=float, 
        default=0.65
    )

        
@click.pass_context
def classify(ctx,**kwargs):    
    """Classify genomes using GTDB-TK V2 (1) and the GTDB database (2).\n    
    (1) Pierre-Alain Chaumeil and others, GTDB-Tk v2: memory friendly classification with the genome taxonomy database, Bioinformatics, Volume 38, Issue 23, 1 December 2022, Pages 5315–5316, https://doi.org/10.1093/bioinformatics/btac672
    \n
    (2) Donovan H Parks and others, GTDB: an ongoing census of bacterial and archaeal diversity through a phylogenetically consistent, rank normalized and complete genome-based taxonomy, Nucleic Acids Research, Volume 50, Issue D1, 7 January 2022, Pages D785–D794, https://doi.org/10.1093/nar/gkab776
    """
    utils.run(MODULE,ctx)



    
