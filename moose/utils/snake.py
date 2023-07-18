import os
import logging
import re
import yaml
import multiprocessing
from pathlib import Path
from moose.utils.log  import logger as logging


class Snake:
    def __init__(self,workflow):
        self.workflow = str(Path(workflow).absolute())
        self.name = str(Path(workflow).name)
        self.configfile = str(self.get_configfile())
        self.config = self.load_default_config()
        # self.default_snakargs = ["--rerun-triggers", "mtime", "--use-conda" ,"--jobs" , ]

    def get_snakefile(self):            
        return os.path.join(self.workflow,'workflow',"Snakefile")
        
    def get_configfile(self):        
        return os.path.join(self.workflow,"config","config.yaml")

    def load_default_config(self):
        return yaml.load(open(self.get_configfile()),Loader=yaml.SafeLoader)
            
    def dump_config(self,file):
        dirname = os.path.abspath(os.path.dirname(file))
        os.makedirs(dirname,exist_ok=True)
        yaml.dump(self.config, open(file,'w') )
        logging.debug('snakemake config file : {}'.format(file))
        return file

    def run(self, snakargs = []):
        args = []
        if "--snakefile" not in snakargs:
            args += ['--snakefile' , self.get_snakefile()]
        if "--configfile" not in snakargs:
            args += ["--configfile", self.configfile]
        if "--use-conda" not in snakargs:
            args += ["--use-conda"]
        if "--jobs" not in snakargs and not re.search("-j[0-9]+"," ".join(snakargs)):
            args += ["--jobs",str(multiprocessing.cpu_count())]

        args += snakargs        
    
        logging.debug("""running : snakemake %s """ % " ".join(args))
        
        cmd = "snakemake {}".format( " ".join(args))            
        snakex = os.system(cmd)
        if snakex != 0:
            logging.error("Hum ... something went wrong while executing the module ... :( ")
            exit(-1)            
        logging.info("Great , workflow finished without error :)" )       
        if "-n" in args or "--dryrun" in args or "--dry-run" in args:
            logging.warning("ps : it was a dryrun !")
        return snakex  