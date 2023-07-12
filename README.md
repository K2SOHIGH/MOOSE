# MOOSE - MetaOmics and Omics SuitE


Moose is basically a bunch of wrapper/tools to process one or more data types from the OMICs world through classical workflows in (meta)omics such as assembly, binning, QCs , genecall, etc...
Most of those wrappers/tools rely on [snakemake](https://snakemake.readthedocs.io/en/stable/) and can be easily deployed on a cluster.

# Summary

**Miscellaneous**:
- [set-default]() - Set default parameters for global moose options. 
- [make-input-file]() - Create a yaml file from directory and subdirectories.

**Genomes processing:** 
- [Gene call](#moose-genomes-genecall) - Predict genes from genomes using [prodigal](https://github.com/hyattpd/Prodigal). 
- [Average Amino Acid Identity (AAI)](#genomes_aai_computation) - Pairwise comparison of proteomes using [mmseqs2](https://github.com/soedinglab/MMseqs2) and AAI computation based on [EzAAI](https://github.com/endixk/ezaai) workflow.	
- [Quality](#moose-genomes-quality) - Estimate genomes quality using [checkM](https://ecogenomics.github.io/CheckM/).
- [Classify](#moose-genomes-classify) - Genomes taxonomic classification using [GTDB-TK.V2](https://ecogenomics.github.io/GTDBTk/).


## Add a new snakemake module

A snakemake workflow should be structured as it is recommended by snakemake and should be stored under moose / workflows / {category} / {module name}
```
├── README.md
├── config
│   └── config.yaml
└── workflow
    ├── Snakefile
    └── envs
        └── <condaenv.yaml>
```

IMPORTANT : declaration variable inside a module should be protected for example with the name of the module as a prefix. Don't forget that python code outside rules is always executed by snakemake. Thus variable conflict could occure when pipeline utility will be implemented. Note that i'have two possibility to implemented the pipeline utility:
- run each command sequencialy with configfiles provided by the user ... in this case module configuration and python code will be isolated.
- create a new snakemake with subworkflows. In this case configuration should be isolated but python code of all subworkflows will be executed.

moose will detect the module as a child of {category} and a command line interface will be built from the configfile required by snakemake.
The config file should look like this one :

```
input : 'test/cds.yaml'
input.conf:
  required: True
  help: 'yaml file containg path to genomes (genome_label: genome_path)'

output : 'moose-res/genomes/genecall'
output.conf:
  required: True
  help: 'Output directory'

checkm_stats: null
checkm_stats.conf:
  help: 'CheckM statistics'

mode: 'normal'
mode.conf:
  choices:
    - 'train'
    - 'anon'
    - 'meta'
    - 'single'
  help: 'Prodigal mode setting.'

```

Command line Interface can be configured by setting a .conf attached to an option. Several parameters can be set :
- required (boolean), the option will be mandatory.
- choices (list), the option will have limited values.
- help (str), display a message about the option.

## Genomes processing.
### moose-genomes-genecall 

Predict genes in your input genome(s) using [Prodigal](https://github.com/hyattpd/Prodigal).

Exemple usage :

```
moose genomes genecall -i <yaml file> -o GENECALL
```

### moose-genomes-aai

Compare two or more proteoms using mmseqs2 [mmseqs2](https://github.com/soedinglab/MMseqs2) and compute AAI based on the [EzAII workflow](https://github.com/endixk/ezaai). Only the lower part of the triangular matrix will be filled.

Exemple usage :

```
moose genomes genecall -i <yaml file> -o GENECALL
```

### moose-genomes-classify

Classify your input genome(s) using [GTDB-TK.V2](https://ecogenomics.github.io/GTDBTk/) and GTDB release 207.

Exemple usage :

```
moose-genomes-classify -i <yaml file> -o GTDBTK-CLASSIF
```

### moose-genomes-quality

Estimate completness and redundancy of your input genome(s) using [CheckM](https://ecogenomics.github.io/CheckM/).

Exemple usage :

```
moose-genomes-quality -i <yaml file>  -o QUALITY
```


<!-- # summary

- **Setup databases.** 
	- [otto-setup-anvio-databases](#otto-setup-anvio-databases) - Initialize anvio-databases (Kegg, Cog, Pfam and SCG) and anvio conda environment. 
	- [otto-setup-interproscan](#otto-setup-interproscan) - Download interproscan databases and executable. 
	- [otto-setup-kaiju](#otto-setup-kaiju) - Download kaiju database using direct url (faster) or kaiju-makedb utility.


- **Reads processing.**
	- [otto-reads-qc](#otto-reads-qc) - Quality check short reads and long reads using respectively [fastqc](https://github.com/s-andrews/FastQC) and [nanoplot](https://github.com/wdecoster/NanoPlot). 
	- [otto-reads-assembly](#otto-reads-assembly) - Assemble short reads and long reads in short-reads-only (SRO) or short-reads-first (SRF \[hybrid\]) modes using [megahit](https://github.com/voutcn/megahit) (SRO-only), [spades](https://github.com/ablab/spades) and/or [unicycler](https://github.com/rrwick/Unicycler).

- **Contigs processing.**
	- [otto-contigs-classify](#otto-contigs-classify) - Taxonomically classify contigs using [Kaiju](https://github.com/bioinformatics-centre/kaiju). 
	- [otto-contigs-profiling](#otto-genomes-profiling) - Profile contigs using [anvio](https://github.com/merenlab/anvio) and BAM files (i.e (meta)-genomics anvio workflow). Useful for manual binning with anvio-interactive. 
	
- **CDS processing**
	- [otto-cds-funannotate](#otto-cds-funannotate) - Functionnal annotation of CDS using [interproscan](https://interproscan-docs.readthedocs.io/en/latest).
	
- **Genomes processing.**
	- [otto-genomes-genecall](#otto-genomes-genecall) - call genes from genomes in fasta format using [prodigal](https://github.com/hyattpd/Prodigal). 
	- [otto-genomes-quality](#otto-genomes-quality) - Estimate genomes quality using [checkM](https://ecogenomics.github.io/CheckM/).
	- [otto-genomes-classify](#otto-genomes-classify) - Genomes taxonomic classification using [GTDB-TK.V2](https://ecogenomics.github.io/GTDBTk/).
	- [otto-genomes-estimate](#otto-genomes-estimate) - Quickly estimate genome(s) taxonomy and quality using [anvio](https://github.com/merenlab/anvio).
	- [otto-genomes-pangenomics](#otto-genomes-pangenomics) - Run a pangenomics analysis on a set of genomes following the anvio pangenomics workflow. 

	

	

## Setup databases.

### otto-setup-anvio-databases
Download anvio pfam,ncbi cog, kegg and scg databases. Make them available for anvio-dependant workflows.

```
 otto-setup-anvio-databases -d ANVIO_DBDIR --reset 
```

### otto-setup-interproscan
Download interproscan databases and executable. Make them available for [otto-cds-funannotate](#otto-cds-funannotate) command.

```
otto-setup-interproscan -d INTERPROSCAN_SETUP
```

### otto-setup-kaiju
Download kaiju database(s) and make them available for [otto-reads-classify](#otto-reads-classify) command.
if --kaiju option set then kaiju-makedb utility will be used to download a database and index it.

:warning: It might be slow and memory intensive, see [Kaiju](https://github.com/bioinformatics-centre/kaiju) documentation for details.

```
 otto-setup-kaiju --db fungi -d kaijuDB/fungi
```


## Reads processing.
### otto-reads-qc
Check your reads quality using [fastQC](https://github.com/s-andrews/FastQC) for short reads and [NanoPlot](https://github.com/wdecoster/NanoPlot) for long ones. Summarize all your samples reads quality in a single report using [MultiQC](https://multiqc.info/).

`otto-make-sample-file` might be used to produce the input file.

Exemple usage :

```
otto-make-sample-file -i <dir> -1 _R1 -2 _R2 -l _LR_1 > samples.yaml
otto-reads-qc -i samples.yaml -o READSQC 
```

where samples.yaml should have the structure below:

```yaml
sampleID:
  long_reads_type: nanopore
  reads:
    long_reads:
    - /path/to/long/reads
    paired_end:
    - /path/to/short/readsP1;/path/to/short/readsP2
```

### otto-reads-assembly
Assemble your reads using one or more strategy:

- SRO : short reads only [megahit, spades , unicycler]
- SRF : short reads first [spades, unicycler]

Map your reads against your assembly for coverage estimation using [bowtie2](https://bowtie-bio.sourceforge.net/bowtie2/manual.shtml) and [samtools](http://www.htslib.org/).
Estimate assembly quality using [seqfu](https://github.com/telatin/seqfu2) and [Quast](https://github.com/ablab/quast).
Summarize all your samples' assembly quality in a single report using [MultiQC](https://multiqc.info/).

Again, `otto-make-sample-file` might be used to produce the input file.

Exemple usage :

```
otto-make-sample-file -i <dir> -1 _R1 -2 _R2 -l _LR_1 > samples.yaml
otto-reads-assembly -i samples.yaml -o ASSEMBLY --workflow SRO SRF -a unicycler
```

See `otto-reads-qc` for details about sample.yaml.

## Contigs processing.
### otto-contigs-classify
Use [Kaiju](https://github.com/bioinformatics-centre/kaiju) to classify [taxonomy] contigs. 
The default input type is anvio contigs database. For each database provided, gene will be called using anvio, classify using kaiju and then imported back to the database.
You can also run `otto-contigs-classify` on fastq or fasta files but paired-end reads are not yet supported.

Exemple usage :

```
otto-contigs-classify -i CONTIGS.db -o kaijuOUT
```

### otto-contigs-profiling.

Annotate and profile one or more assembly with anvio-databases and bam(s) file(s) using [anvio](https://github.com/merenlab/anvio). `otto-contigs-profiling` follow [anvio's metagenomics workflow](https://merenlab.org/2016/06/22/anvio-tutorial-v2) to annotates genes in your assembly, detect SCG and estimate contigs/split abundance. With `otto-contigs-classify` and `otto-contigs-profiling` you're ready to bin mannualy your assembly.

Exemple usage :

```
otto-contigs-profiling -i samples.yaml -o ANVIO-PROFILES
```
Where samples.yaml fellow the format below:

```yaml
sampleID:
    fasta: /path/to/assembly
    bams:
        bamID: /path/to/sorted/bam/
```

## CDS processing.
### otto-cds-funannotate

Analyze CDS fasta file(s) in proteic format with [interproscan](https://interproscan-docs.readthedocs.io/en/latest).

```
otto-cds-funannotate -i /CDS/DIR -e .fasta.gz -o INTERPROSCAN-CLASSIFY -t 15
```



## Genomes processing.
### otto-genomes-genecall

Predict genes in your input genome(s) using [Prodigal](https://github.com/hyattpd/Prodigal).

Exemple usage :

```
otto-genomes-genecall-prodigal -i <dir_with_fna> -e .fna.gz -o GENECALL
```



### otto-genomes-classify

Classify your input genome(s) using [GTDB-TK.V2](https://ecogenomics.github.io/GTDBTk/) and GTDB release 207.

Exemple usage :

```
otto-genomes-classify -i <dir_with_*.fna.gz_files> -e .fna.gz -o GTDBTK-CLASSIF
```

### otto-genomes-quality

Estimate completness and redundancy of your input genome(s) using [CheckM](https://ecogenomics.github.io/CheckM/).

Exemple usage :

```
ottos-genomes-quality-i <dir_with_*.fna.gz_files> -e .fna.gz -o QUALITY
```

### otto-genomes-estimate
Quick estimation of your input genome(s) taxonomy and quality using [anvio](https://github.com/merenlab/anvio).

Exemple usage :

```
otto-genomes-estimate-i <dir_with_*.fna.gz_files> -e .fna.gz -o ANVIO-ESTIMATE
```

### otto-genomes-pangenomics
Annotate and Perform pangenomics analysis on a set of genomes using [anvio pangenomics workflow](https://merenlab.org/2016/11/08/pangenomics-v2/#running-a-pangenome-analysis).

Exemple usage :

```
otto-genomes-pan-anvio -i <dir_with_*.fna.gz_files> -e .fna.gz -o ANVIO-PANGENOMICS
```
 -->
