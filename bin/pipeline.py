#!/usr/bin/env python
# -*- coding: utf-8 -*-
from pathlib import Path
from importlib import resources
import yaml
from bin.main import cli as main_cmd
from moose.utils.log import logger
from moose import workflows
from moose.utils import snake


class Pipeline:
    def __init__(self,modules:list):
        self.module_names = [m.split('::') for m in modules]
        self.availables = {}
        self.modules = {}
        self.init_available_module()
        self.get_module_config()

    def init_available_module(self):
        self.availables = {}
        for cn1,first_level_cmd in main_cmd.commands.items(): 
            self.availables[cn1]={}           
            for cn2,second_level_cmd in first_level_cmd.commands.items():                                
                self.availables[cn1][cn2] = second_level_cmd

    
    def get_module_config(self):
        for parent,module in self.module_names:
            if parent in self.availables:
                if module in self.availables[parent]:
                    module_path = Path(resources.files(workflows))                    
                    module_obj = snake.Snake( str(module_path / parent / module.replace('-','_')) )                    
                    module_name = "{}_{}".format(parent,module)
                    self.modules[module_name] = module_obj
                else:
                    logger.error('{} command doesn\'t exists'.format(module) )
            else:
                logger.error('{} command doesn\'t exists'.format(parent) )

    def dump_pipeline_config(self,file):
        config = {}
        for n,m in self.modules.items():
            config[n] = m.config
        yaml.dump(config,open(file,'w'))

    def fill_module_template(self,name,snakefile):
        return """subworkflow {name}:
    snakefile: {snakefile}
    configfile: {configfile}

use rule * from {name} as {name}_*
""".format(name=name.replace('-','_'),snakefile=snakefile)


    def make_pipeline_snakefile(self,file):
        with open(file,'w') as fh:
            for n,m in self.modules.items():
                snakefile = m.get_snakefile()
                fh.write(self.fill_module_template(n,snakefile))


p = Pipeline(['genomes::compute-aai','genomes::quality','genomes::classify','cds::annotate'])
p.dump_pipeline_config('test.config.yaml')
p.make_pipeline_snakefile('test.snake.yaml')

