All-vs-All genomes comparison for AAI computation.
\x1b[33;20mINPUT\x1b[0m is either a tabular file with one genome path per line in first column and optionnaly a label in second column or a directory containing {pattern}*{extension} files. Proteomes from input genomes will be predicted using prodigal(1). AAI will be computed between all combination of genome using MMSEQS2(2) and based on EzAAI(3) workflow.

(1) Kim, D., Park, S. & Chun, J. Introducing EzAAI: a pipeline for high throughput calculations of prokaryotic average amino acid identity. J Microbiol. 59, 476–480 (2021). https://doi.org/10.1007/s12275-021-1154-0

(2) Steinegger, M., Söding, J. MMseqs2 enables sensitive protein sequence searching for the analysis of massive data sets. Nat Biotechnol 35, 1026–1028 (2017). https://doi.org/10.1038/nbt.3988

(3) Hyatt, D., Chen, GL., LoCascio, P.F. et al. Prodigal: prokaryotic gene recognition and translation initiation site identification. BMC Bioinformatics 11, 119 (2010). https://doi.org/10.1186/1471-2105-11-119