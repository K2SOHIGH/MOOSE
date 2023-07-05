#!/usr/bin/env python
# -*- coding: utf-8 -*-

from pathlib import Path

import click
import yaml

from bin.setup_moose import default_setting
from bin.setup_anvio import setup_anvio
from bin.genomes_aai import compute_aai
from bin.genomes_genecall import genecall
from bin.genomes_classify import classify
from bin.genomes_quality import quality
from bin.cds_annotate import annotate

from moose.utils.log import set_logger_level
from moose.utils import utils


class CustomFormatter(click.HelpFormatter):    
    group_color = {
        "genomes":"\x1B[38;5;208m",
        "cds":"\u001b[32m",
        "setup":"\x1b[38;5;162m",
    }
    
    def __init__(self,
                indent_increment=2, width=None, max_width=None):
        super().__init__(indent_increment,width,max_width)
        #self.color =  "\u001b[34m"#"\u001b[37m"

    def write_heading(self,heading):
        click.HelpFormatter.write_heading(
            self,
            self.color+heading+"\x1b[0m"
            )
                
    def write_usage(self,prog,args='',prefix=None):        
        col = "\x1b[0m"
        if len(prog.split()) > 1:
            c = prog.split()[1]         
            if c in self.group_color:
                col = self.group_color[c]

        click.HelpFormatter.write_usage( self,      
            col+prog+"\x1b[0m",
            args,
            prefix
        )
        self.color = col

class OptionDefault(click.Option):
    def __init__(self, *args, **kwargs):  
        super(OptionDefault, self).__init__(*args, **kwargs)

    def default_moose_setting(self,ctx):
        moose_config_file = Path.home() / '.moose.conf'    
        d = {}
        if moose_config_file.exists():
            with open(moose_config_file,'r') as f:
                d = yaml.load(f,Loader=yaml.SafeLoader)
        if self.name in d:
            return d[self.name]
        return self.default
    
    def get_default(self, ctx, **kwargs):                
        return  self.default_moose_setting(ctx)




click.Context.formatter_class = CustomFormatter
@click.group(context_settings=utils.CONTEXT_SETTING, )
@click.option('--conda-dir',
            cls=OptionDefault,            
            default=str(Path.home() / ".moose/conda-envs/"),
            )
@click.option('--config-dir',
            cls=OptionDefault,    
            default=str(Path.home() / ".moose/configs/"),            
            )
@click.option('--snakargs',
            cls=OptionDefault,    
            default="--use-conda",            
            )
@click.option('--debug',
            is_flag=True,
            cls=OptionDefault,    
            default=False,
            callback=set_logger_level,
            )

@click.pass_context
def cli(ctx,**kwargs):
    ctx.obj.update(kwargs)


@click.group()
@click.pass_context
def genomes(ctx,**kwargs):
    """Genomes commands"""
    

@click.group()
@click.pass_context
def cds(ctx,**kwargs):
    desc = """CDS commands"""

@click.group()
@click.pass_context
def setup(ctx,**kwargs):
    desc = """setup commands"""
    



# GENOMES SUBCMDS
genomes.add_command(compute_aai)
genomes.add_command(genecall)
genomes.add_command(classify)
genomes.add_command(quality)

# CDS SUBCMDS
cds.add_command(annotate)

# SETUP SUBCMDS
setup.add_command(default_setting)
setup.add_command(setup_anvio)

# CMDS
cli.add_command(genomes)
cli.add_command(cds)
cli.add_command(setup)
def entry_point():  
    cli(obj={})
    

if __name__ == '__main__':
    entry_point()
