import sys
import json
import os
import argparse
import time
import glob
import tempfile
import logging
from functools import wraps
import gzip


def timeit(func):
    @wraps(func)
    def timeit_wrapper(*args, **kwargs):
        start_time = time.perf_counter()
        result = func(*args, **kwargs)
        end_time = time.perf_counter()
        total_time = end_time - start_time
        logging.debug(f'Function {func.__name__}{args} {kwargs} Took {total_time:.4f} seconds')
        return result
    return timeit_wrapper

# set up logging to file
class CustomFormatter(logging.Formatter):
    grey = "\x1b[38;20m"
    yellow = "\x1b[33;20m"
    red = "\x1b[31;20m"
    bold_red = "\x1b[31;1m"
    reset = "\x1b[0m"
    black = "\u001b[30m"
    green = "\u001b[32m"
    blue = "\u001b[34m"
    magenta = "\u001b[35m"
    cyan = "\u001b[36m"
    white = "\u001b[37m"
    lightpurple = "\x1b[38;5;69m" #[38;5;141m" #"\x1b[38;5;84m"
    pink90 = "\x1b[38;5;162m" #"\x1b[38;5;214m"
    
    def __init__(self, fmt,datefmt="%Y-%m-%d %H:%M:%S"):
        super().__init__()
        self.fmt = fmt
        self.datefmt = datefmt
        self.FORMATS = {
            logging.DEBUG: self.yellow + self.fmt + self.reset,
            logging.INFO: self.lightpurple + self.fmt + self.reset,
            logging.WARNING: self.pink90 + self.fmt + self.reset,
            logging.ERROR: self.red + self.fmt + self.reset,
            logging.CRITICAL: self.bold_red + self.fmt + self.reset
        }
    
    def format(self, record):
        log_fmt = self.FORMATS.get(record.levelno)                
        formatter = logging.Formatter(log_fmt,self.datefmt)
        return formatter.format(record)


# set up logging to console
console = logging.StreamHandler()
console.setLevel(logging.INFO)
# set a format which is simpler for console use
format = "[%(asctime)s] [%(levelname)s] CAAI | %(message)s"
console.setFormatter(CustomFormatter(format))
logging.basicConfig(     
    level=logging.INFO, 
    handlers=[console]
 )


@timeit
def create_db(fasta,outfile,v=1):        
    cmd = "mmseqs createdb {} {} -v {}".format(
        fasta,
        outfile,
        v,
        )
    excode = os.system(cmd)
    logging.info("Create sequence database [{}].".format(os.path.basename(outfile)))    
    logging.debug("cmd:\n"+cmd)
    if excode != 0:
        logging.error("{} command as failed".format(cmd))
        raise OSError       

@timeit
def search(query,target,out,tmp,aln_mode=2,id=0.4,cov=0.5,v=1):    
    cmd = """mmseqs search {} {} {} {}\
    --alignment-mode {} --min-seq-id {} -a\
    -c {} -v {}""".format(query,
                   target,
                   out,
                   tmp,                   
                   aln_mode,
                   id,
                   cov,
                   v)
    logging.info("Search {} vs {} using mmseqs2.".format(os.path.basename(query),os.path.basename(target)))
    logging.debug("cmd:\n"+cmd)
    excode = os.system(cmd)
    if excode != 0:
        logging.error("{} command as failed".format(cmd))
        raise OSError
        
@timeit
def filter(resdb, out, nl = 1 , v=0):
    cmd = "mmseqs filterdb {} {} --extract-lines {} -v {}".format(
        resdb,
        out,
        nl,
        v)
    logging.info("filter alignments results [{}].".format(os.path.basename(resdb)))
    logging.debug('cmd:\n'+cmd)
    excode = os.system(cmd)
    if excode != 0:
        logging.error("{} command as failed".format(cmd))
        raise OSError
        
@timeit
def convert(query,target,res,tab,format=["query","target","evalue","pident","qcov","tcov" ,'qlen', 'tlen', 'alnlen' ,'fident', 'nident'  ],v=1):
    cmd = "mmseqs convertalis {} {} {} {} --format-output {} -v {}".format(
        query,
        target,
        res,
        tab,
        ",".join(format),
        v
    )
    logging.info("convert aln to table [{}].".format(os.path.basename(res)))
    logging.debug("cmd:\n"+cmd)
    excode = os.system(cmd)
    if excode != 0:
        raise OSError

@timeit
def count_cds(fasta):
    c = 0
    if fasta.endswith('.gz'):
        fhandler = gzip.open(fasta,'rt')
    else:
        fhandler = open(fasta,'r')
    for l in fhandler.readlines():
        if l.startswith('>'):
            c+=1
    fhandler.close()
    return c


def compute_aai(vice,versa):    
    names = ["query","target","evalue","pident","qcov","tcov" ,'qlen', 'tlen', 'alnlen' , 'fident', 'nident' ]    
    vice_df  = pd.read_csv(vice , sep='\t', header=None, names=names)     
    versa_df = pd.read_csv(versa, sep='\t', header=None, names=names)     
    hits_pairs = list(set(list(zip(vice_df["query"],vice_df["target"])) + list(zip(vice_df["target"],vice_df["query"]))))
    n = 0
    reciprocal_hits_aai_sum = 0
    reciprocal_hits_length_sum = 0

    vice = vice_df.set_index(["query","target"]).T.to_dict()
    versa = versa_df.set_index(["target","query"]).T.to_dict()
    for p in hits_pairs:
        if p in vice and p in versa:
            n+=1
            reciprocal_hits_aai_sum += int(vice[p]["pident"]) + int(versa[p]["pident"])
            #reciprocal_hits_length_sum += int(vice[p]["qlen"]) + int(versa[p]["qlen"])
    aai = reciprocal_hits_aai_sum / (n*2) if n>0 else 0
    #mlen = reciprocal_hits_length_sum / (n*2) if n>0 else 0
    if aai == 0:
        logging.warning('No reciprocal match found.') 

    logging.info("Estimated AAI   : {}%".format(round(aai,3)))
    logging.info("Forward hits    : {}".format(vice_df.shape[0]))
    logging.info("Reverse hits    : {}".format(versa_df.shape[0]))
    logging.info("reciprocal hits : {}".format(n))
    return n, aai , vice_df.shape[0], versa_df.shape[0]

def compute_coverage(n,faa1,faa2):
    c1 = count_cds(faa1)
    c2 = count_cds(faa2)
    return (n*2)/(c1+c2),c1,c2

def get_args():
    parser = argparse.ArgumentParser(
                    prog='calculate',
                    description='Compute AAI between two proteomes'
                    )
    parser.add_argument('-i', help="proteome(s)")
    parser.add_argument('-j', help="proteome(s)")
    parser.add_argument('-d', help="proteome directory")
    parser.add_argument('-e', help="proteome extension", default='.faa')   
    parser.add_argument('-p', help="proteome pattern", default=None)
    parser.add_argument('-o', '--out',default=sys.stdout, help="Output file, default is stdin")     
    parser.add_argument('-t', '--tmp',default=None, help="temp directory")     
    parser.add_argument('--aln-mode',default=2, help="mmseqs alignments mode")     
    parser.add_argument('--id',default=0.4, help="mmseqs identity threshold")     
    parser.add_argument('--cov',default=0.5, help="mmseqs coverage threshold")     
    parser.add_argument('--debug',action="store_true", help='print debug')     
    
    args = parser.parse_args()
    return args

def get_snakargs():
    args = argparse.Namespace()
    args.i = str(globals()['snakemake'].input.i)
    args.j = ",".join([str(i) for i in globals()['snakemake'].input.j])
    args.d = globals()['snakemake'].params.d
    args.e = globals()['snakemake'].params.e
    args.p = globals()['snakemake'].params.p
    args.tmp = globals()['snakemake'].params.t
    args.aln_mode = globals()['snakemake'].params.aln_mode
    args.id =  globals()['snakemake'].params.id
    args.cov = globals()['snakemake'].params.cov
    args.debug = globals()['snakemake'].params.debug
    args.out = str(globals()['snakemake'].output)
    return args
    
def parse_args():    
    if "snakemake" in globals():
        return get_snakargs()
    else:
        return get_args()

@timeit
def main():
    args = parse_args()   
    if args.debug:
        logging.getLogger().removeHandler(logging.getLogger().handlers[0])
        logging.getLogger().setLevel(logging.DEBUG)
        # set up logging to console
        debug = logging.StreamHandler()
        debug.setLevel(logging.DEBUG)
        # set a format which is simpler for console use        
        debug.setFormatter(CustomFormatter(format))
        logging.getLogger().addHandler(debug)
        logging.debug("DEBUG")

    if args.i and args.j:
        if args.d:
            logging.error("Choose either -i and -j to compare proteome(s) i vs proteome(s) j or -d to perform a all-vs-all comparison of proteomes under a specific directory")
            exit(-1)
        else:
            fis = [os.path.abspath(f) for f in args.i.split(',')]
            logging.info("Number of proteomes in I : {}".format(len(fis)))
            fjs = [os.path.abspath(f) for f in args.j.split(',')]
            logging.info("Number of proteomes in J : {}".format(len(fjs)))
            logging.info("Number of comparisons: {}".format(int(len(fis)*len(fjs))))
    elif args.d:
        logging.debug('glob : {}/{}*{}'.format(args.d,'*'+args.p if args.p else '' ,args.e ))
        fis = glob.glob('{}/{}*{}'.format(args.d,'*'+args.p if args.p else '' ,args.e ))
        
        if not fis:
            logging.error("Fail to glob files from {} [{}, {}].".format(args.d,args.e,args.p))
            exit(-1)
        #fis = [fis[i] for i in range(0,0)]
        fjs = fis.copy()
        logging.info("Number of proteomes in D : {}".format(len(fis)))
        logging.info("Number of comparisons: {}".format(
            int(len(fis)*((len(fis)-1)/2)))
        )
        logging.debug("Theorical number of comparisons: {}".format(int(len(fis)*len(fis))))
    else:
        logging.error("Inputs proteomes are missing.")
        logging.error("Choose either -i and -j to compare proteome(s) i vs proteome(s) j or -d to perform a all-vs-all comparison of proteomes under a specific directory")
        exit(-1)

    idx=0
    total = len(fis)*len(fjs)
    results = {}
    for i in fis:
        if i in fjs:
            fjs.remove(i)
        for j in fjs:
            if args.tmp:
                tmpdirname=args.tmp + "/" + str(idx)
                flush=False
                os.makedirs(os.path.abspath(tmpdirname),exist_ok=True)    
            else:
                temp_dir = tempfile.TemporaryDirectory()
                tmpdirname = temp_dir.name
                flush = True          
            
            tmpres = os.path.join(tmpdirname,'res.json')
            if os.path.exists(tmpres):
                logging.info('{} vs {} comparison already done. skip it.'.format(i,j))
                results[idx] = json.load(open(tmpres))
                idx+=1
                continue
              
            create_db(
                i, 
                tmpdirname  + "/querydb"
                )
            create_db(
                j, 
                tmpdirname  + "/targetdb"
                )    
            # search query vs target
            search(
                tmpdirname + "/querydb",
                tmpdirname + "/targetdb",
                tmpdirname + "/resDB",
                tmpdirname + "/tmp",
                aln_mode=args.aln_mode,
                id=args.id,
                cov=args.cov
                )
            # filter 
            filter(
                tmpdirname + "/resDB",
                tmpdirname + "/filterDB",
            )

            convert(
                tmpdirname + "/querydb",
                tmpdirname + "/targetdb",
                tmpdirname + "/filterDB",
                tmpdirname + "/aln.tab"
            )

            # search target vs query
            search(
                tmpdirname + "/targetdb",
                tmpdirname + "/querydb",
                tmpdirname + "/rev_resDB",
                tmpdirname + "/tmp",
                aln_mode=args.aln_mode,
                id=args.id,
                cov=args.cov
                )
            
            filter(
                tmpdirname + "/rev_resDB",
                tmpdirname + "/rev_filterDB",
            )

            convert(
                tmpdirname + "/targetdb",
                tmpdirname + "/querydb",
                tmpdirname + "/rev_filterDB",
                tmpdirname + "/rev_aln.tab"
            )

            # merge table
            n,aai,forward,reverse = compute_aai(tmpdirname + "/aln.tab" , tmpdirname + "/rev_aln.tab")
            cov, cds1, cds2 = compute_coverage(n,i,j)
            results[idx] = {
                "ID1" : i,
                "ID2" : j,
                "CDS count 1" : cds1,
                "CDS count 2" : cds2,
                "Forward match":forward,
                "Reverse match":reverse,
                "Reciprocal match" : n,
                "AAI" : round(aai,3),
                "Coverage":round(cov,5)
            }
            json.dump(results[idx],open(tmpres,'w'))
            idx+=1
            logging.info("{}/{} done".format(idx,total))
            if flush:
                temp_dir.cleanup()
    pd.DataFrame(results).T[
        ['ID1','ID2','CDS count 1', 'CDS count 2','Forward match','Reverse match','Reciprocal match','AAI', 'Coverage']
        ].to_csv(args.out,sep='\t')


if __name__ == "__main__":
    main()