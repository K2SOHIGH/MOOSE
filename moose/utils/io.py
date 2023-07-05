import click
import logging
from pathlib import Path

from moose.utils.log  import logger as logging

class IO:
    def __init__():
        """"""
    def input_from_dir(self, path , extension , pattern=None):    
        files = {}
        if path.is_dir():
            if pattern:
                pattern = "*" + pattern
            else:
                pattern = ''
            for p in path.rglob('{}*{}'.format(pattern,extension)):
                files[p.name.replace(extension,'')] = str(p.absolute())
            if files:
                return files
            logging.error('can\'t find files under {} following {}*{}'.format(
                str(path),pattern,extension
            ))
            raise FileNotFoundError
        else:
            logging.error("{} is not a directory".format(input))
            raise NotADirectoryError
                
    def input_from_file(self, path, extension):
        files = {} 
        if path.is_file():        
            with open(str(path),'r') as fh:
                for line in fh.readlines():
                    l = line.strip.split()
                    genome_path = Path(l[0])
                    label = genome_path.name.replace(extension,'')
                    if len(l)>1:
                        label = l[1]                
                    if genome_path.exists():
                        files[label] = str(genome_path.absolute())      
                    else:
                        logging.error("{} do not exists".format(path))                
                        raise FileNotFoundError
            return files
        logging.error("{} is not a file".format(path))
        raise FileNotFoundError
    
    def click_context_get_params_by_type(self,ctx,params_type):
        for i,j in ctx.params.items():
            if isinstance(j, params_type):
                return j
        return None

    def get_extension(self,ctx):
        return str(self.click_context_get_params_by_type(ctx,Extension))

    def get_pattern(self,ctx):
        return str(self.click_context_get_params_by_type(ctx,Pattern))
      
    def parse_input(self, path, ctx):    
        if path.is_dir():
            return self.input_from_dir(
                path,
                self.get_extension(ctx),
                self.get_pattern(ctx))
        elif path.is_file():            
            return self.input_from_file(
                path,
                self.get_extension(ctx))
        else:
            logging.error("{} is neither a file nor a directory".format(path))
            raise ValueError

class InputObj1(IO):
    def __init__(self,path:str):
        self.path = Path(path)

class InputType1(click.ParamType):
    name = "genome_input_type"
    def convert(self, value, param, ctx):
        if isinstance(value, str):
            v = Path(value)
            if v.is_file():
                return InputObj1(value)
            elif v.is_dir():
                return InputObj1(value)
            else:
                pass
        self.fail(f"{value!r} is neither a file nor a directory", param, ctx)



class Extension:
    def __init__(self, name):
        self.name = name
    def __str__(self):
        return self.name

class ExtensionInputType(click.ParamType):
    name = "extension_input_type"
    def convert(self, value, param, ctx):
        if isinstance(value, str):
            return Extension(value)
        self.fail(f"{value!r} is not a string.", param, ctx)

class Pattern:
    def __init__(self, name):
        self.name = name
    def __str__(self):
        return self.name

class PatternInputType(click.ParamType):
    name = "pattern_input_type"
    def convert(self, value, param, ctx):
        if isinstance(value, str):
            return Pattern(value)
        self.fail(f"{value!r} is not a string.", param, ctx)