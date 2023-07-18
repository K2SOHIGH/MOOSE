import sys
import click
import yaml
import re
from pathlib import Path
from moose.utils  import utils
from moose.utils.log import logger

@click.command(
        "make-input-file",
        short_help="make a yaml file from a directory, pattern and extension.",
        context_settings=utils.CONTEXT_SETTING, 
        )

@click.option(
      '-o','--output',
      type = str, default='-',
      help = 'output yaml file',      
)

@click.option(
    '-d','--dir',
    default = '.',
    help = 'root directory to scan',
    type = str
    )

@click.option(
    '-e','--extension',
    help = "target files' extension.",
    required = True,
    type = str
    )

@click.option(
    '-p','--pattern',
    default=None,
    help = "pattern to avoid file ambiguity.",
    type = str,   
    )


def make_input_file(output,dir,extension,pattern):        
    path  = Path(dir).absolute()
    files = {}
    if not pattern:
        pattern=""
    logger.debug('root dir : {}'.format(path))
    
    for p in path.rglob("*"):
        a = re.search('.*{}.*{}'.format(pattern,extension),str(p.name))
        if a is not None:            
            files[p.name.replace(extension,'')] = str(p.absolute())
    
    
    if output != '-':
        p = Path(output).parent
        p.mkdir(parents=True, exist_ok=True)
        output = open(str(output),'w')
        yaml.dump(files, output)
    else:
        yaml.dump(files, sys.stdout)
    
    

@click.group()
@click.pass_context
def misc(ctx,**kwargs):
    """misc commands group"""

misc.add_command(make_input_file)



# if __name__=="__main__":
#     make_input_file()