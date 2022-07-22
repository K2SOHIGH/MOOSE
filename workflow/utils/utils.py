
def _parse_shortreads(r1,r2,st):
    shortreads = {}
    if st == "paired-end":
        orientation = "fr"
        left = r1 
        right = r2
    else:
        orientation = "fr"        
        left = r2
        right = r1

    shortreads["type"] = st
    shortreads["orientation"] = "fr"
    shortreads["right reads"] = right.split(",")
    shortreads["left reads"] = left.split(",")
    return shortreads

def _parse_longreads(lr,lt):
    longreads={}
    longreads["type"] = lt    
    longreads["single reads"] = lr.split(",")
    return longreads

def _parse_unpaired(u):
    singlereads={}
    singlereads["type"] = "single"   
    singlereads["single reads"] = u.split(",")
    return singlereads

def parse_input_files(r1,r2,st,u,lr,lt):
    """
        r1 = forward reads (left)
        r2 = reverse reads (right)
    """
    inputs = []
    inputs.append(
        _parse_shortreads(r1,r2,st)
    )
    if lr:         
        inputs.append(_parse_longreads(lr,lt))
    if u:
        inputs.append(_parse_unpaired(u))
    return inputs


def get_forward_reads(wildcards,INP):
    r1 = []
    for i in INP:
        if i["type"] == "paired-end" or i["type"] == "mate-pair":
            r1 += i["left reads"]
    return r1

def get_reverse_reads(wildcards,INP):
    r2 = []
    for i in INP:
        if i["type"] == "paired-end" or i["type"] == "mate-pair":
            r2 += i["right reads"]
    return r2
    
def get_single_reads(wildcards,INP):
    ur = []
    for i in INP:
        if i["type"] == "single":
            ur += i["single reads"]
    return ur

def get_long_reads(wildcards,INP):
    lr = []
    for i in INP:
        if i["type"] == "nanopore" or i["type"] == "pacbio":
            lr += i["single reads"]    
    return lr

def _split_cmd(cmd:str , exclude:list=None):
    cmd = " "+cmd
    c = cmd.split(" -")    
    ncmd = []
    for i in c:
        k = "-%s" % str(i)
        if k.split(" ")[0] not in exclude:               
            ncmd.append(k)
    return " ".join(ncmd)


def parse_unicycler_cmdline(cmd:str):
    return _split_cmd(
        cmd,
        ["-1","-2","-l","-s","--unpaired","--long","--kmers","--threads","-t","-o","--out","--short1","--short2"]
    
    )
    
def parse_megahit_cmdline(cmd:str):
    return _split_cmd(
        cmd,
        ["-1","-2","-r","--k-list","-t","--num-cpu-threads","-o","--out-dir","--out-prefix"]
    )

def parse_spades_cmdline(cmd:str):
    return _split_cmd(
        cmd,
        ["-1","-2","--12","-s","--merged","--pe-12","--pe-1","--pe-2","--pe-s",
            "--pe-m","--pe-or","--s","--mp-12","--mp-1","--mp-2","--mp-s","--mp-or",
                "--hqmp-12","--hqmp-1","--hqmp-2","--hqmp-s","--hqmp-or","--sanger","--pacbio","--nanopore"]
        )


def resolve_bam(INPUT):
    combidict = {}
    if yf:
        # if a mapping file is provided , a list of mapping steps will be generated 
        with open(yf) as yfstream:
            yfd = yaml.load(yfstream,Loader = yaml.SafeLoader)
        for sample, readsrcs in yfd.items():
            l = readsrcs.strip().split(',')
            if sample not in combidict:
                combidict[sample] = []
            for src in l:
                combidict[sample].append('%s__against__%s' % (src,sample))
    else:
        # if mapping file is not provided, then we will try to map sample read against sample assembly.
        for sample,_ in SAMLPES.items():
            combidict[sample] = [sample]
    return combidict
