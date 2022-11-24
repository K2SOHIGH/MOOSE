# MAKO
MetAgenomics worKflOws 

<p align="center">
  <img src="mako.png">
</p>

MAKO is basically a bunch of wrapper/tools to process one or more samples/genomes through classical workflows in (meta)genomics such as megahit, SPADES, CheckM, GTDB-TK, Prodigal, etc...
Most of those wrappers/tools rely on [snakemake](https://snakemake.readthedocs.io/en/stable/) and can be easily deployed on a cluster.

# Current features

- [reads-based-features](#reads-based-features)
	- [mako-reads-qc](#mako-reads-qc)
	- [mako-reads-assembly](#mako-reads-assembly)
- [genomes-based-features](#genomes-based-features)
	- [mako-genomes-genecall-prodigal](#mako-genomes-genecall-prodigal)
	- [mako-genomes-estimate-anvio](#mako-genomes-estimate-anvio)
	- [mako-genomes-classify-checkm](#mako-genomes-classify-checkm)
	- [mako-genomes-estimate-anvio](#mako-genomes-estimate-anvio)


## reads-based-features

### mako-reads-qc

Check your reads quality using fastqc for short reads and nanoplot for long ones. Summarize all your samples reads quality in a single report using multiqc.

mako-make-sample-file might be used to produce the input file.

Exemple usage :

```
mako-make-sample-file -i <dir> -1 _R1 -2 _R2 -l _LR_1 > samples.yaml
mako-reads-qc -i samples.yaml -o READSQC 
```

### mako-reads-assembly

**WARNING : SRF and LRF not tested yet.**

Assemble your reads using one or more strategy:

- SRO : short reads only [megahit, spades , unicycler]
- SRF : short reads first [spades, unicycler]
- LRF : long reads first [minmap2,miniasm,pilon and minipolish]

Map your reads against your assembly for coverage estimation using bowtie2 and samtools.
Estimate assembly quality using seqfu and Quast.
Summarize all your samples' assembly quality in a single report using multiqc.

Again, mako-make-sample-file might be used to produce the input file.

Exemple usage :

```
mako-make-sample-file -i <dir> -1 _R1 -2 _R2 -l _LR_1 > samples.yaml
mako-reads-assembly -i samples.yaml -o ASSEMBLY --workflow SRO SRF  
```

## genomes-based-features

### mako-genomes-genecall-prodigal
Predict genes in your input genome(s) using Prodigal

Exemple usage :

```
mako-genomes-genecall-prodigal -i <dir_with_fna> -e .fna.gz -o GENECALL
```

### mako-genomes-estimate-anvio
Estimate your input genome(s) taxonomy and quality using anvi'o.

Exemple usage :

```
mako-genomes-estimate-anvio -i <dir_with_*.fna.gz_files> -e .fna.gz -o ANVIO-ESTIMATE
```

### mako-genomes-classify-gtdbtk
**WARNING : waiting an access to my cluster to test it.**

Classify your input genome(s) using GTDB-TK V2 and GTDB release 207.

Exemple usage :

```
mako-genomes-classify-gtdb-tk -i <dir_with_*.fna.gz_files> -e .fna.gz -o CLASSIF
```
### mako-genomes-quality-checkm
**WARNING : waiting an access to my cluster to test it.**

Estimate completness and redundancy of your input genome(s) using CheckM.
Exemple usage :

```
mako-genomes-quality-checkm -i <dir_with_*.fna.gz_files> -e .fna.gz -o QUALITY
```


