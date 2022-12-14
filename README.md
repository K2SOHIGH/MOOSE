# MAKO
MetAgenomics worKflOw

<p align="center">
  <img src="mako.png">
</p>

MAKO is basically a bunch of wrapper/tools to process one or more samples/genomes through classical workflows in (meta)genomics such as megahit, SPADES, CheckM, GTDB-TK, Prodigal, etc...
Most of those wrappers/tools rely on [snakemake](https://snakemake.readthedocs.io/en/stable/) and can be easily deployed on a cluster.

# summary

- **Setup databases.** 
	- [mako-setup-anvio-databases](#mako-setup-anvio-databases) - Initialize anvio-databases (Kegg, Cog, Pfam and SCG) and anvio conda environment. 
	- [mako-setup-interproscan](#mako-setup-interproscan) - Download interproscan databases and executable. 
	- [mako-setup-kaiju](#mako-setup-kaiju) - Download kaiju database using direct url (faster) or kaiju-makedb utility.


- **Reads processing.**
	- [mako-reads-qc)](#mako-reads-qc) - Quality check short reads and long reads using respectively [fastqc](https://github.com/s-andrews/FastQC) and [nanoplot](https://github.com/wdecoster/NanoPlot). 
	- [mako-reads-assembly](#mako-reads-assembly) - Assemble short reads and long reads in short-reads-only (SRO) or short-reads-first (SRF \[hybrid\]) modes using [megahit](https://github.com/voutcn/megahit) (SRO-only), [spades](https://github.com/ablab/spades) and/or [unicycler](https://github.com/rrwick/Unicycler).

- **Contigs processing.**
	- [mako-contigs-classify](#mako-contigs-classify) - Taxonomically classify contigs using [Kaiju](https://github.com/bioinformatics-centre/kaiju). 
	- [mako-contigs-profiling](#mako-genomes-profiling) - Profile contigs using [anvio](https://github.com/merenlab/anvio) and BAM files (i.e (meta)-genomics anvio workflow). Useful for manual binning with anvio-interactive. 
	
- **CDS processing**
	- [mako-cds-funannotate](#mako-cds-funannotate) - Functionnal annotation of CDS using [interproscan](https://interproscan-docs.readthedocs.io/en/latest).
	
- **Genomes processing.**
	- [mako-genomes-genecall](#mako-genomes-genecall) - call genes from genomes in fasta format using [prodigal](https://github.com/hyattpd/Prodigal). 
	- [mako-genomes-quality](#mako-genomes-quality) - Estimate genomes quality using [checkM](https://ecogenomics.github.io/CheckM/).
	- [mako-genomes-classify](#mako-genomes-classify) - Genomes taxonomic classification using [GTDB-TK.V2](https://ecogenomics.github.io/GTDBTk/).
	- [mako-genomes-estimate](#mako-genomes-estimate) - Quickly estimate genome(s) taxonomy and quality using [anvio](https://github.com/merenlab/anvio).
	- [mako-genomes-pangenomics](#mako-genomes-pangenomics) - Run a pangenomics analysis on a set of genomes following the anvio pangenomics workflow. 

	

	

## Setup databases.

### mako-setup-anvio-databases
Download anvio pfam,ncbi cog, kegg and scg databases. Make them available for anvio-dependant workflows.

```
 mako-setup-anvio-databases -d ANVIO_DBDIR --reset 
```

### mako-setup-interproscan
Download interproscan databases and executable. Make them available for [mako-cds-funannotate](#mako-cds-funannotate) command.

```
mako-setup-interproscan -d INTERPROSCAN_SETUP
```

### mako-setup-kaiju
Download kaiju database(s) and make them available for [mako-reads-classify](#mako-reads-classify) command.
if --kaiju option set then kaiju-makedb utility will be used to download a database and index it.
:warning: might be slow and memory intensive, see [Kaiju](https://github.com/bioinformatics-centre/kaiju) documentation for details.

```
 mako-setup-kaiju --db fungi -d kaijuDB/fungi
```


## Reads processing.
### mako-reads-qc
Check your reads quality using [fastQC](https://github.com/s-andrews/FastQC) for short reads and [NanoPlot](https://github.com/wdecoster/NanoPlot) for long ones. Summarize all your samples reads quality in a single report using [MultiQC](https://multiqc.info/).

`mako-make-sample-file` might be used to produce the input file.

Exemple usage :

```
mako-make-sample-file -i <dir> -1 _R1 -2 _R2 -l _LR_1 > samples.yaml
mako-reads-qc -i samples.yaml -o READSQC 
```

### mako-reads-assembly
Assemble your reads using one or more strategy:

- SRO : short reads only [megahit, spades , unicycler]
- SRF : short reads first [spades, unicycler]

Map your reads against your assembly for coverage estimation using [bowtie2](https://bowtie-bio.sourceforge.net/bowtie2/manual.shtml) and [samtools](http://www.htslib.org/).
Estimate assembly quality using [seqfu](https://github.com/telatin/seqfu2) and [Quast](https://github.com/ablab/quast).
Summarize all your samples' assembly quality in a single report using [MultiQC](https://multiqc.info/).

Again, `mako-make-sample-file` might be used to produce the input file.

Exemple usage :

```
mako-make-sample-file -i <dir> -1 _R1 -2 _R2 -l _LR_1 > samples.yaml
mako-reads-assembly -i samples.yaml -o ASSEMBLY --workflow SRO SRF -a unicycler
```

## Contigs processing.
### mako-contigs-classify
Use [Kaiju](https://github.com/bioinformatics-centre/kaiju) to classify [taxonomy] contigs. 
The default input type is anvio contigs database. For each database provided, gene will be called using anvio, classify using kaiju and then imported back to the database.
You can also run `mako-contigs-classify` on fastq or fasta files but paired-end reads are not yet supported.

Exemple usage :

```
mako-contigs-classify -i CONTIGS.db -o kaijuOUT
```

### mako-contigs-profiling.

Annotate and profile one or more assembly with anvio-databases and bam(s) file(s) using [anvio](https://github.com/merenlab/anvio). `mako-contigs-profiling` follow [anvio's metagenomics workflow](https://merenlab.org/2016/06/22/anvio-tutorial-v2) to annotates genes in your assembly, detect SCG and estimate contigs/split abundance. With `mako-contigs-classify` and `mako-contigs-profiling` you're ready to bin mannualy your assembly.

Exemple usage :

```
mako-contigs-profiling -i samples.yaml -o ANVIO-PROFILES
```
Where samples.yaml fellow the format below:

```yaml
{sampleID}:
	fasta: /path/to/assembly
	bams:
		{bamID}: /path/to/sorted/bam/
```

## CDS processing.
### mako-cds-funannotate

Analyze CDS fasta file(s) in proteic format with [interproscan](https://interproscan-docs.readthedocs.io/en/latest).

```
mako-cds-funannotate -i /CDS/DIR -e .fasta.gz -o INTERPROSCAN-CLASSIFY -t 15
```



## Genomes processing.
### mako-genomes-genecall

Predict genes in your input genome(s) using [Prodigal](https://github.com/hyattpd/Prodigal).

Exemple usage :

```
mako-genomes-genecall-prodigal -i <dir_with_fna> -e .fna.gz -o GENECALL
```



### mako-genomes-classify

Classify your input genome(s) using [GTDB-TK.V2](https://ecogenomics.github.io/GTDBTk/) and GTDB release 207.

Exemple usage :

```
mako-genomes-classify -i <dir_with_*.fna.gz_files> -e .fna.gz -o GTDBTK-CLASSIF
```

### mako-genomes-quality

Estimate completness and redundancy of your input genome(s) using [CheckM](https://ecogenomics.github.io/CheckM/).

Exemple usage :

```
makos-genomes-quality-i <dir_with_*.fna.gz_files> -e .fna.gz -o QUALITY
```

### mako-genomes-estimate
Quick estimation of your input genome(s) taxonomy and quality using [anvio](https://github.com/merenlab/anvio).

Exemple usage :

```
mako-genomes-estimate-i <dir_with_*.fna.gz_files> -e .fna.gz -o ANVIO-ESTIMATE
```

### mako-genomes-pangenomics
Annotate and Perform pangenomics analysis on a set of genomes using [anvio pangenomics workflow](https://merenlab.org/2016/11/08/pangenomics-v2/#running-a-pangenome-analysis).

Exemple usage :

```
mako-genomes-pan-anvio -i <dir_with_*.fna.gz_files> -e .fna.gz -o ANVIO-PANGENOMICS
```

