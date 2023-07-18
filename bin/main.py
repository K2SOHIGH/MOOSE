    #!/usr/bin/env python
# -*- coding: utf-8 -*-

import yaml
from importlib import resources
from pathlib import Path

import click

from moose import workflows
from moose.utils import io,utils
from moose.utils.log import logger
from bin import config as configuration
from bin import misc


class MooseDefault(click.Option):
    def __init__(self, *args, **kwargs):
        super(MooseDefault, self).__init__(*args, **kwargs)

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

class CustomFormatter(click.HelpFormatter):    
    group_color = {
        "genomes":"\x1B[38;5;208m",
        "cds":"\u001b[32m",
        "setup":"\x1b[38;5;162m",
    }
    
    def __init__(self,
                indent_increment=2, width=None, max_width=None):
        super().__init__(indent_increment,width,max_width)

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

@click.pass_context
def snakemake_cmd(ctx,**kwargs):
    """"""
    logger.debug('Entry point call back function.')
    utils.run(None,ctx)


class Liststr(str):
    def back_to_list(self):
        return self.split(',')

class ClickOPT(click.Option):    
    TYPES_MAPPING = {
        "integer" : int,
        "float": float,
        "str": str,
        "list": list,
        "dict": dict,    
        None: str,
    }

    def __init__(self,*args,**kwargs):            
        kwargs = self._parse_opt(*args, **kwargs)
        super().__init__(*args,**kwargs)

    def _parse_opt(self,*args,**kwargs):        
        default_value = kwargs.get('default')        
        if isinstance(default_value,bool):
            kwargs['is_flag'] = True
            kwargs['type'] = bool
        elif isinstance(default_value,list):
            kwargs['default'] = Liststr(",".join(default_value))
            kwargs['type'] = Liststr
        elif isinstance(default_value,dict):
            raise TypeError('dict instance is not supported')
        else:            
            if kwargs.get('choices') and isinstance(kwargs.get('choices'),list):                
                choices = [ str(_) for _ in [default_value] + kwargs.pop('choices')]
                kwargs['type'] = click.Choice(choices)     
                if not default_value:
                    default_value = choices[0]
            else:
                # use click default
                if default_value:
                    #t = self.TYPES_MAPPING[kwargs.get('type')]
                    kwargs['type'] = type(default_value)#t
                else:
                    default_value = ""
                    t = self.TYPES_MAPPING[kwargs.get('type')]  if self.TYPES_MAPPING[kwargs.get('type')] else str                    
                    kwargs['type'] = t
                        
        if kwargs.get('required'):                
            kwargs.pop('default')
           
        return kwargs
    
class Config:
    def __init__(self,name,workflow_path):
        self.name = name
        self.path = workflow_path
        self.info = ""
        self.load_config()
        self.load_help()
        self.build_cmd()
        self.clickopts()
        logger.debug(
            'loading {} module [{}]'.format(                
                self.name,
                self.path,
                )
            )


    def build_cmd(self):
        self.cmd = click.Command(
            name=self.name,
            short_help="",
            callback=snakemake_cmd,
            no_args_is_help=True,
            help=self.info
        )
        
    
    def load_help(self):
        f = Path(self.path) / "README.md"
        if f.exists():
            with open(str(f)) as fh:
                self.info = fh.read()
        
    def load_config(self,file=None):        
        if not file:
            self.configfile = Path(self.path) / "config" / "config.yaml"
        else:
            self.configfile = Path(file)
        if self.configfile.exists():
            self.raw_config = yaml.load(open(self.configfile),Loader=yaml.SafeLoader)
            self.parse_config()
        else:
            raise FileExistsError(self.configfile)

    def parse_dict(self,mk,d):
        nd = {}
        for k,e in d.items():            
            k = mk+"-moose-"+k
            if isinstance(e,dict):
                nd.update(self.parse_dict(k,e))
            else:
                nd[k] = e
        return nd
    
    def get_opt_meta(self):
        self.opt_meta = {}
        for k in list(self.raw_config.keys()):
            if k.endswith('.conf'):
                kconf = self.raw_config.pop(k)
                self.opt_meta[k.replace('.conf','')]=kconf        

    def parse_config(self):
        self.config = {}
        self.get_opt_meta()
        for key, value in self.raw_config.items():            
            if isinstance(value,dict):
                # flatten dict
                self.config.update(
                    self.parse_dict(key,value))
            else:
                self.config[key]=value
    
    def build_dcls(self,key):
        return ["-{}".format(key[0]),
            "--{}".format(key),
        ]

    def clickopts(self):
        self.opts = []
        short_flags = []
        
        for key, value in self.config.items():
            params_dcls = self.build_dcls(key)            
            if params_dcls[0] not in short_flags:
                short_flags.append(params_dcls[0])
            else:
                params_dcls.pop(0)        

            kwargs = {}
            if key in self.opt_meta:                
                kwargs = self.opt_meta[key]
                            
            opt = ClickOPT(
                params_dcls,
                default=value,
                **kwargs
                )
            
            self.opts.append(opt)
            self.cmd.params.append(opt)


def init_cmds():
    snakeflows =  Path(resources.files(workflows)) # Path('moose/workflows/')
    for parent in snakeflows.glob("*"):        
        pname = parent.name#child.parents[0]                
        if pname.startswith('_') or  pname.startswith('.'):
            continue
        pname = str(parent.name)#.replace('_','-') 
        for child in parent.glob("*"):            
            cname = str(child.name)
            if cname.startswith('_') or  cname.startswith('.'):
                continue            
            #cname = cname#.replace('_','-')
            configfile = child / 'config' / 'config.yaml'
            snakefile = child / 'workflow' / 'Snakefile'             
            if snakefile.exists() and configfile.exists():                                               
                if  pname not in cli.commands:
                    cli.add_command(click.Group(pname))                
                cmd = Config(cname,str(child))                       
                cli.commands[pname].add_command(cmd.cmd)
            else:
                logger.warning('Module structure is invalid and will be skip [{}/{}].'.format(
                    pname,
                    cname
                ))


context_settings=utils.CONTEXT_SETTING                  
click.Context.formatter_class = CustomFormatter
@click.group(context_settings=utils.CONTEXT_SETTING)
@click.option('--moose-dir',
            cls=MooseDefault,                  
            default=str(Path.home() / ".moose"),
            )
# @click.option('--config-dir',
#             cls=MooseDefault,            
#             default=str(Path.home() / ".moose/configs/"),            
#             )
@click.option('--snakargs',  
            cls=MooseDefault,          
            default="--use-conda",            
            )
@click.option('--debug',
            cls=MooseDefault,
            is_flag=True,            
            default=False,            
            )



@click.pass_context
def cli(ctx,**kwargs):
    ctx.obj.update(kwargs)


cli.add_command(configuration.setup)
cli.add_command(misc.misc)



def entry_point():      
    init_cmds()
    cli(obj={}) 


if __name__ == '__main__':
    entry_point()
