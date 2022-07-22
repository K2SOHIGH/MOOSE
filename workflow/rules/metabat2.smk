rule Metabat2:
    output:
        directory(config['res_dir'] + "/{sample}/BINS/"),
    input:
        contigs = lambda wildcards: SAMPLES[wildcards.sample],
        depth = config['res_dir'] + "/{sample}/depth.txt",
    params:
        bin_prefix = config['res_dir'] + "/{sample}/BINS/{sample}"
    conda:
        "envs/metabat2.2.15.yaml"
    shell:
        "metabat2 -i {input.contigs} "
        "-a {input.depth} "
        "-o {params.bin_prefix} "


def _aggregate_bam_inputs(wildcards):
    # sample,reads =  wildcards.combi.split('__against__')
    print(wildcards)
    combs = COMBIS[wildcards.sample]
    return expand(TMPDIR + "/{combi}/{combi}.sorted.bam",combi = combs )


rule summarize_contig_depth:
    '''
        Compute reads coverage depth to perform binning.
    '''
    output:
        config['res_dir'] + "/{sample}/depth.txt",
    input:
        bams = _aggregate_bam_inputs,
    conda:
        "envs/metabat2.2.15.yaml"
    threads: 5
    shell:
        #"touch {output}"
        "jgi_summarize_bam_contig_depths --outputDepth {output} {input.bams}"