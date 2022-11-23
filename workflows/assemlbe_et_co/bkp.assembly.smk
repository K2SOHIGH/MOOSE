
# ASSEMBLY_TYPES = config["ASSEMBLY_TYPES"]

# ASSEMBLER_AND_TYPES = []
# for i in ASSEMBLERS:
#     for j in ASSEMBLY_TYPES:
#         if i == "megahit":
#             if j == "short_reads":
#                 ASSEMBLER_AND_TYPES.append( i + "-" + j ) 
#         else:
#             ASSEMBLER_AND_TYPES.append( i + "-" + j ) 

# rule assembly:
    # input:
    #     expand(
    #         os.path.join(RESDIR , "{sample}" , "contig-qc" ,"multiqc_report.html"), sample=INPUTS
    #     )
# rule long_read_assembly_polyshing:
#     output:
#         touch( os.path.join(RESDIR , "{sample}",  "polyshing.done") )
#     input:    
#         expand(
#             os.path.join( RESDIR , "{{sample}}", "{assembler_assembly_type}" ,  "polyshing.done" ), 
#             assembler_assembly_type = [at for at in ASSEMBLER_AND_TYPES if re.search("long_reads",at)],
#         )   
     
# rule contigs_qc:
#     output:
#         os.path.join(RESDIR , "{sample}" , "contig-qc" ,"multiqc_report.html"),
#     input:          
#         os.path.join(RESDIR, "{sample}" , "contigs-qc","report.html"),        
#     conda:
#         "./envs/multiqc.yaml"     
#     params:
#         multiqc_target = RESDIR,
#         outdir = os.path.join(RESDIR , "{sample}" , "contig-qc"),
#     shell:
#         "multiqc {params.multiqc_target} -d -dd 3 -o {params.outdir}"
# rule reformat_contigs:
#     """
#         reformat contigs for anvi'o
#     """
#     output:
#         contigs = os.path.join(
#             RESDIR , "{sample}", "{assembler}-{assembly_type}" ,  "final_contigs_reformat.fasta"
#         ),
#         tsv =  os.path.join(
#             RESDIR , "{sample}", "{assembler}-{assembly_type}" , "contigs_table.tsv"
#         ),
#     input:
#         os.path.join(RESDIR , "{sample}", "{assembler}-{assembly_type}" , "contigs.fasta" )
#     run:
#         contig = 0
#         with open(str(output.tsv),"w") as tblout:
#             with open(str(output.contigs),'w') as fastaout:
#                 with open(str(input),'r') as streamin:
#                     for line in streamin.readlines():
#                         if line.startswith(">"):
#                             contig+=1
#                             contigid = "c_{}".format(contig)
#                             fastaout.write( ">{}\n".format(contigid) )
#                             tblout.write( "{}\t{}\t{}\n".format( line[1:] , contigid , wildcards.sample) )
#                         else:
#                             fastaout.write( line )
# #include: "./rules/anvio.smk"
# #include: "./rules/polishing.smk"
# include: "./rules/contigs_quality.smk"
# include: "./rules/bowtie2.smk"
# include: "./rules/megahit.smk"
# include: "./rules/spades.smk"
# include: "./rules/unicycler.smk"