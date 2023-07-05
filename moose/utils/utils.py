import yaml
from pathlib import Path
from importlib import resources

from moose.utils.snake import Snake
from moose.utils.log  import logger as logging
from moose.utils.io import InputObj1,Pattern,Extension
from moose import workflows


CONTEXT_SETTING = {
    'show_default': True,
    'help_option_names':['-h', '--help']
    }


def run(_,ctx):
    logging.info("""    
    #######################################
    #                                     #
    #                MOOSE                #
    #                                     #
    #######################################
    """)  
    logging.debug('DEBUG mode')
    
    module_name = ctx.info_name.lower().replace('-','_')

    # MAKE CONFIG FILE    
    # Update Snakefile configuration with CLI values and run workflow.
    module_path = Path(resources.files(workflows))
    module = Snake( str(module_path / ctx.parent.info_name / module_name) )

    params = {}
    for i,j in ctx.params.items():
        
        if isinstance(j,InputObj1):
            j = j.parse_input(j.path,ctx)
        if isinstance(j,Extension) or isinstance(j,Pattern):
            j = str(j)
        params[i]=j
    
    module.config.update(params)    
    configfile = str(
        Path(ctx.obj['config_dir']) / "{}.config.yaml".format(module_name))
    
        
    module.dump_config(configfile)

    conda_prefix = ctx.obj['conda_dir']
    snakargs = ctx.obj["snakargs"].split()
    snakargs.extend(["--configfile" , configfile , "--conda-prefix" , conda_prefix])
    
    logging.info(module_name.upper() + " - start ")
    module.run(snakargs)   
    logging.info(module_name.upper() + " - end ")



def show_config(config):    
    logging.info("CONFIGURATION :\n"+yaml.dump(config, default_flow_style=False))



class Pipeline:
    def __init__(self,modules):
        self.modules=modules




# def get_snakefile(dir, keyword):
#     return os.path.abspath(
#         glob.glob( 
#             os.path.join(dir,'workflows/*{}*/Snakefile'.format(keyword))
#             )[0]
#         )

# def get_anvio_db_path():
#     f = os.path.abspath(os.path.join(__file__, ".." , ".." , "resources" , "anviodb.txt" )  )
#     print(f)
#     if os.path.exists(f):
#         db = ""
#         logger.info("check if {} exists ...".format(f))
#         with open(f) as s:
#             for line in s.readlines():
#                 db = line.strip()
#         if os.path.isdir(db):
#             logger.info("Anvio databases found here : {} ".format(db))
#             return os.path.abspath(db)
#         else:
#             return ""                
#     else:     
#         logger.error("Run otto-setup-anvio-databases first")
#         exit(-1)
        

# def module(module,args):
#     """
#     temporary files were problematic 
#     when executing otto module on a 
#     cluster (slurm)
#     """
#     configdir = os.path.expanduser( '~' )
#     configdir = os.path.abspath(
#         os.path.join(os.path.dirname(__file__),".." )
#         )        
#     condastorage = os.path.join(configdir,"condaenvs")
#     configstorage = os.path.join(configdir,"configfiles")
#     os.makedirs(condastorage,exist_ok=True)
#     os.makedirs(configstorage,exist_ok=True)
#     logger.info("Running %s !" % module)    
#     logger.info("Snakemake will install conda environment in %s" % condastorage)    
#     configfile = os.path.join(configstorage,"config-{}.{}.{}.yaml".format(module,date.today(), random.randint(0,1000000) ))
#     logger.info("Configuration file : %s" % configfile)    
#     #configfile = tempfile.NamedTemporaryFile(mode="w+")  
#     CONFIG = args2dict(args)    
#     yaml.dump( CONFIG, open(configfile,"w") )    
#     #configfile.flush()
#     SNAKEFILE =  get_snakefile(os.path.join(os.path.dirname(__file__),".."),module)
#     cmd = """
#         snakemake --snakefile  {snakefile} -j{threads} --rerun-triggers mtime --use-conda --configfile {config} --conda-prefix {cp} {snakargs}
#     """.format(
#         snakefile = SNAKEFILE ,
#         threads = args.threads,
#         cp = condastorage,
#         config = configfile,
#         snakargs = args.snakargs
#     )

#     logger.info("""running : 
#         %s """ % cmd )
#     excode = os.system(cmd)
    
#     if excode != 0:
#         logger.error("Hum ... something went wrong while executing the workflow ... :( ")
#         exit(-1)
#     logger.info("Great , %s finished without error :)" % module)
#     if "-n" in args or "--dryrun" in args or "--dry-run" in args:
#             logger.warning("it was a dryrun !")
#     os.remove(configfile)
#     return excode 
        
# def args2dict(args):
#     config = {}
#     for arg in vars(args):        
#         config[arg] = getattr(args,arg)
#     return config


# def parse_profile_anvio_input(f):
#     pass



# def file_to_list(file):
#     l = []    
#     if file: 
#         if os.path.exists(file):
#             with open(file) as stream:
#                 for line in stream.readlines():
#                     l.append(line.strip())
#             return l
#         else:
#             logger.error("File doesn't exists ! [{}]".format(file))
#             exit(-1)
#     return l
        
# def _parse_paired_end_short_reads(r1,r2):   
    
#     paired_end_reads = [] 
#     if r1 and r2:
#         if (len(r1.split(','))!=len(r2.split(','))):
#             logger.error("reverse and forward read should have the same number of input files")
#             exit(-1)
#         for _reads in zip(r1.split(","),r2.split(",")):
#             paired_end_reads.append(";".join(list(_reads)))
#         return paired_end_reads
#     elif r1 or r2:
#             logger.error("reverse reads should be accompanied by forward reads")    
#             exit(-1)
#     else:
#         return None
    
# def _parse_longreads(lr,lt):
#     longreads={"long_reads":[]}
#     longreads["long_reads_type"] = lt    
#     if lr:
#         longreads["long_reads"] = lr.split(",")
#     return longreads

# def _parse_unpaired(u):
#     singlereads={"single_reads":[]}
#     # singlereads[""] = "single"  
#     if u:
#         singlereads["single_reads"] = u.split(",")
#     return  singlereads

# def parse_input_files(id,r1,r2,u,lr,lt):
#     """
#         r1 = forward reads (left)
#         r2 = reverse reads (right)
#     """
#     inputs = {
#         id:{
#             "reads":{},                        
#             }
#     }    
#     sr = _parse_paired_end_short_reads(r1,r2)
#     if sr:
#         inputs[id]["reads"].update({"paired_end" : sr})                 
#     if lr:         
#         inputs[id]["reads"].update(_parse_longreads(lr,lt))
#         inputs[id]["long_reads_type"] = lt
#     if u:
#         inputs[id]["reads"].update(_parse_unpaired(u))
#     return inputs

# ##########################################################################################

# # SNAKEMAKE FUNCTIONS


# def _split_cmd(cmd:str , exclude:list=None):
#     cmd = " "+cmd
#     c = cmd.split(" -")    
#     ncmd = []
#     for i in c:
#         k = "-%s" % str(i)
#         if k.split(" ")[0] not in exclude:               
#             ncmd.append(k)
#     return " ".join(ncmd)

# def parse_unicycler_cmdline(cmd:str):
#     return _split_cmd(
#         cmd,
#         ["-1","-2","-l","-s","--unpaired","--long","--kmers","--threads","-t","-o","--out","--short1","--short2"]
    
#     )
    
# def parse_megahit_cmdline(cmd:str):
#     return _split_cmd(
#         cmd,
#         ["-1","-2","-r","--k-list","-t","--num-cpu-threads","-o","--out-dir","--out-prefix"]
#     )

# def parse_spades_cmdline(cmd:str):
#     return _split_cmd(
#         cmd,
#         ["-1","-2","--12","-s","--merged","--pe-12","--pe-1","--pe-2","--pe-s","-k"
#             "--pe-m","--pe-or","--s","--mp-12","--mp-1","--mp-2","--mp-s","--mp-or",
#                 "--hqmp-12","--hqmp-1","--hqmp-2","--hqmp-s","--hqmp-or","--sanger","--pacbio","--nanopore"])
        