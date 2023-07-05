import click
import yaml
from pathlib import Path
from moose.utils  import utils
from moose.utils.log import logger

@click.command(
        "default_setting",
        short_help="Update default values for --snakargs and --debug.",
        context_settings=utils.CONTEXT_SETTING, 
        )
@click.option(
    '--snakargs',
    help = 'snakemake parameters to use as default',
    type = str
    )

@click.option('--conda-dir',
            default=str(Path.home() / ".moose/conda-envs/"),
            )

@click.option('--config-dir',
            default=str(Path.home() / ".moose/configs/"),
            )

@click.option(
    '--set-debug',
    is_flag = True,
    help = 'always show debug messages.',
    )

@click.pass_context
def default_setting(ctx,snakargs,conda_dir,config_dir,set_debug):        
    moose_config_file = Path.home() / '.moose.conf'    
    conf = {
        "snakargs":snakargs,
        "conda_dir":conda_dir,
        "config_dir":config_dir,
        "debug":set_debug
    }
    with open(moose_config_file,'w') as f:
        yaml.dump(conf,f)
    logger.info('moose config file created. [{}]'.format(moose_config_file))

if __name__=="__main__":
    default_setting()