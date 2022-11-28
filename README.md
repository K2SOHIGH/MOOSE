# MAKOS
MetAgenomics worKflOws 

<p align="center">
  <img src="mako.png">
</p>

MAKOS is basically a bunch of wrapper/tools to process one or more samples/genomes through classical workflows in (meta)genomics such as megahit, SPADES, CheckM, GTDB-TK, Prodigal, etc...
Most of those wrappers/tools rely on [snakemake](https://snakemake.readthedocs.io/en/stable/) and can be easily deployed on a cluster.

# summary

- [setup](#setup)
	- [mako-setup-anvio-databases](#mako-setup-anvio-databases) :white_check_mark:
	- [mako-setup-interproscan](#mako-setup-interproscan) :white_check_mark:

- [reads-based-features](#reads-based-features)
	- [mako-reads-qc](#mako-reads-qc) :white_check_mark:
	- [mako-reads-assembly](#mako-reads-assembly) :warning:
		- SRO :white_check_mark:
		- SRF :warning:
		- SRL :warning:
		
- [genomes-based-features](#genomes-based-features)
	- [mako-genomes-genecall-prodigal](#mako-genomes-genecall-prodigal) :white_check_mark:
	- [mako-genomes-quality-checkm](#mako-genomes-quality-checkm) :warning:
	- [mako-genomes-classify-gtdbtk](#mako-genomes-classify-gtdbtk) :warning:	
	- [mako-genomes-estimate-anvio](#mako-genomes-estimate-anvio) :white_check_mark:
	- [mako-genomes-pan-anvio](#mako-genomes-pan-anvio) :white_check_mark:
	- [mako-genomes-profile-anvio](#mako-genomes-profile-anvio) :white_check_mark:
	
- [cds-based-features](#cds-based-features)
	- [mako-cds-classify-interproscan](#mako-cds-classify-interproscan) :white_check_mark:
	

## setup         [:arrow_up:](#summary)

### mako-setup-interproscan

Download interproscan databases and executable. Make them available for [mako-cds-classify-interproscan](#mako-cds-classify-interproscan) command.


```
mako-setup-interproscan -d INTERPROSCAN_SETUP
```

### mako-setup-anvio-databases

Download anvio pfam,ncbi cog, kegg and scg databases. Make them available for anvio-dependant workflows.


```
 mako-setup-anvio-databases -d ANVIO_DBDIR --reset 
```

## cds-based-features      [:arrow_up:](#summary)

### mako-cds-classify-interproscan

Analyze CDS fasta file(s) in proteic format with interproscan and output an unique table.

```mako-cds-classify-interproscan -i /CDS/DIR -e .fasta.gz -o INTERPROSCAN-CLASSIFY -t 15```


## reads-based-features     [:arrow_up:](#summary)

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

## genomes-based-features     [:arrow_up:](#summary)

### mako-genomes-genecall-prodigal
Predict genes in your input genome(s) using Prodigal

Exemple usage :

```
mako-genomes-genecall-prodigal -i <dir_with_fna> -e .fna.gz -o GENECALL
```



### mako-genomes-classify-gtdbtk
**WARNING : waiting an access to my cluster to test it.**

Classify your input genome(s) using GTDB-TK V2 and GTDB release 207.

Exemple usage :

```
mako-genomes-classify-gtdb-tk -i <dir_with_*.fna.gz_files> -e .fna.gz -o GTDBTK-CLASSIF
```
### mako-genomes-quality-checkm
**WARNING : waiting an access to my cluster to test it.**

Estimate completness and redundancy of your input genome(s) using CheckM.
Exemple usage :

```
makos-genomes-quality-checkm -i <dir_with_*.fna.gz_files> -e .fna.gz -o QUALITY
```

### mako-genomes-estimate-anvio
Estimate your input genome(s) taxonomy and quality using anvi'o.

Exemple usage :

```
mako-genomes-estimate-anvio -i <dir_with_*.fna.gz_files> -e .fna.gz -o ANVIO-ESTIMATE
```

### mako-genomes-profile-anvio

Annotate and profile one or more genomes with anvio-databases and bam(s) file(s) using anvio.

Exemple usage :

```
mako-genomes-profile-anvio -i samples.yaml -o ANVIO-PROFILES
```

### mako-genomes-pan-anvio
Annotate and Perform pangenomics analysis on a set of genomes using anvio.
Exemple usage :

```
mako-genomes-pan-anvio -i <dir_with_*.fna.gz_files> -e .fna.gz -o ANVIO-PANGENOMICS
```
