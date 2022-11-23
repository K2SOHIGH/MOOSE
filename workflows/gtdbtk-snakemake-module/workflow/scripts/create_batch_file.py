with open(str(snakemake.output),'w') as f:
    for path,id in snakemake.params.bins_tuple:
        f.write("{}\tUSER_{}\n".format(path,id))