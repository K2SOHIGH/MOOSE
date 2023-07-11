import sys
import click
import yaml
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
      default = sys.stdout,
      help = 'output yaml file',
      type = str,
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
    else:
        pattern="*"+pattern
    for p in path.rglob('{}*{}'.format(pattern,extension)):
                files[p.name.replace(extension,'')] = str(p.absolute())
    
    if isinstance(output,str):
          p = Path(output).parent
          p.mkdir(parents=True, exist_ok=True)
          output = open(str(output),'w')

    yaml.dump(files, output)
    

@click.group()
@click.pass_context
def misc(ctx,**kwargs):
    """misc commands group"""

misc.add_command(make_input_file)



# if __name__=="__main__":
#     make_input_file()