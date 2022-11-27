# MAKOS
MetAgenomics worKflOws 

**TO DO**

- mako-contigs-anvi-magic-mtg (use fna as input and perform profiling + annotations using pfam / kegg and cogg ~ metagenomics workflow)
	- anvi-gen-contigs-database
	- anvi-run-kegg-kofams
	- anvi-run-ncbi-cogs
	- anvi-run-pfam
	- anvi-run-hmms
	- anvi-run-taxonomy
	- anvi-profile
	- anvi-merge
- mako-contigs-anvi-magic-pan (use fna as input and perform pangenomics analysis)
	- anvi-gen-contigs-database
	- anvi-run-kegg-kofams
	- anvi-run-ncbi-cogs
	- anvi-run-pfam
	- anvi-run-hmms
	- anvi-gen-genomes-storage (combining all data from all genomes)
	- anvi-pan-genome (compare all genes to build genes clusters)
	- anvi-display-pan



<p align="center">
  <img src="mako.png">
</p>

MAKOS is basically a bunch of wrapper/tools to process one or more samples/genomes through classical workflows in (meta)genomics such as megahit, SPADES, CheckM, GTDB-TK, Prodigal, etc...
Most of those wrappers/tools rely on [snakemake](https://snakemake.readthedocs.io/en/stable/) and can be easily deployed on a cluster.

# Current features

- [reads-based-features](#reads-based-features)
	- [makos-reads-qc](#makos-reads-qc)
	- [makos-reads-assembly](#makos-reads-assembly)
- [genomes-based-features](#genomes-based-features)
	- [makos-genomes-genecall-prodigal](#makos-genomes-genecall-prodigal)
	- [makos-genomes-estimate-anvio](#makos-genomes-estimate-anvio)
	- [makos-genomes-classify-checkm](#makos-genomes-classify-checkm)
	- [makos-genomes-estimate-anvio](#makos-genomes-estimate-anvio)


## reads-based-features

### makos-reads-qc

Check your reads quality using fastqc for short reads and nanoplot for long ones. Summarize all your samples reads quality in a single report using multiqc.

makos-make-sample-file might be used to produce the input file.

Exemple usage :

```
makos-make-sample-file -i <dir> -1 _R1 -2 _R2 -l _LR_1 > samples.yaml
makos-reads-qc -i samples.yaml -o READSQC 
```

### makos-reads-assembly

**WARNING : SRF and LRF not tested yet.**

Assemble your reads using one or more strategy:

- SRO : short reads only [megahit, spades , unicycler]
- SRF : short reads first [spades, unicycler]
- LRF : long reads first [minmap2,miniasm,pilon and minipolish]

Map your reads against your assembly for coverage estimation using bowtie2 and samtools.
Estimate assembly quality using seqfu and Quast.
Summarize all your samples' assembly quality in a single report using multiqc.

Again, makos-make-sample-file might be used to produce the input file.

Exemple usage :

```
makos-make-sample-file -i <dir> -1 _R1 -2 _R2 -l _LR_1 > samples.yaml
makos-reads-assembly -i samples.yaml -o ASSEMBLY --workflow SRO SRF  
```

## genomes-based-features

### makos-genomes-genecall-prodigal
Predict genes in your input genome(s) using Prodigal

Exemple usage :

```
makos-genomes-genecall-prodigal -i <dir_with_fna> -e .fna.gz -o GENECALL
```

### makos-genomes-estimate-anvio
Estimate your input genome(s) taxonomy and quality using anvi'o.

Exemple usage :

```
makos-genomes-estimate-anvio -i <dir_with_*.fna.gz_files> -e .fna.gz -o ANVIO-ESTIMATE
```

### makos-genomes-classify-gtdbtk
**WARNING : waiting an access to my cluster to test it.**

Classify your input genome(s) using GTDB-TK V2 and GTDB release 207.

Exemple usage :

```
makos-genomes-classify-gtdb-tk -i <dir_with_*.fna.gz_files> -e .fna.gz -o GTDBTK-CLASSIF
```
### makos-genomes-quality-checkm
**WARNING : waiting an access to my cluster to test it.**

Estimate completness and redundancy of your input genome(s) using CheckM.
Exemple usage :

```
makos-genomes-quality-checkm -i <dir_with_*.fna.gz_files> -e .fna.gz -o QUALITY
```

## contigs-based-features

### mako-contigs-anvio-magic

Profile your contigs with BAM files using anvi-profile 

```
makos-genomes-quality-checkm -i <dir_with_*.fna.gz_files> -e .fna.gz -o QUALITY
```

## cds-based-features

### makos-setup-interproscan

Download interproscan databases and executable to a specific location.

```
makos-setup-interproscan -d path/to/interproscan/directory
```

### makos-cds-classify-interproscan

Annotate cds in proteic or nucleic format from one or more fasta file using interproscan databases and output a single table.

```
makos-cds-classify-interproscan -i <dir_with_*.fasta> --type proteic -e .fasta -o. INTERPRO-CLASSIFY --threads 15
```







-
