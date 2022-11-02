


# rule polypolish:
#     output:        
#         touch(os.path.join( RESDIR , "{sample}", "{assembler_assembly_type}",  "dummy.polyshing" )),
#     input:
#         fasta = os.path.join( RESDIR , "{sample}", "{assembler_assembly_type}" ,  "final_contigs_reformat.fasta"),
#         sam = os.path.join(RESDIR , "{sample}", "{assembler_assembly_type}" , "read_mapping" ,  "polypolish_{forward}.sam"),
#     wildcard_constraints:
#         assembler_assembly_type = ".*long_reads"
#     shell:
#         "polypolish_insert_filter.py --in1 alignments_1.sam --in2 alignments_2.sam --out1 filtered_1.sam --out2 filtered_2.sam && "
#         "polypolish draft.fasta filtered_1.sam filtered_2.sam > polished.fasta"



# rule polypolish_mapping_read:
#     output:
#         temp(os.path.join(RESDIR , "{sample}", "{assembler_assembly_type}" , "read_mapping"  , "polypolish_{polypolish_read}.sam")),
#     input:
#         expand(
#             os.path.join(RESDIR , "{{sample}}", "{{assembler_assembly_type}}", "bowtie2_index.{idx}")
#             , idx = ["1.bt2", "2.bt2", "3.bt2", "4.bt2", "rev.1.bt2","rev.2.bt2"]
#         ),
#         reads = lambda wildcards : utils.get_reads( INPUTS[wildcards.sample] , wildcards.polypolish_read ),        
#     params:
#         r1inp = lambda wildcards, input: bowtie2_input_read("R1",input.R1),
#         r2inp = lambda wildcards, input: bowtie2_input_read("R2",input.R2),
#         #urinp = lambda wildcards, input: bowtie2_input_read("U",input.UR + input.LR),
#         index = os.path.join(RESDIR , "{sample}", "{assembler_assembly_type}", "bowtie2_index"),
#     threads: 15
#     priority: 80
#     conda:
#         "../envs/bowtie2.yaml"
#     shell:
#         "bowtie2 "
#         "-p {threads} "             # number of parallel threads
#         "--no-unal "                # remove unmapped reads (decrease size)
#         "-x {params.index} "       # index for mapping        
#         "-r {input.reads} "        
#         "-S {output} "








# # rule POLCA:
# #     output:

# #     input:
# #         contigs = os.path.join( RESDIR , "{sample}", "{assembler_assembly_type}" ,  "final_contigs_reformat.fasta"),
# #         R1 = lambda wildcards : utils.get_reads( INPUTS[wildcards.sample] , "left_reads" ),
# #         R2 = lambda wildcards : utils.get_reads( INPUTS[wildcards.sample] , "right_reads" ),
# #     threads:
# #         15
# #     shell:
# #         "polca.sh "
# #         "-a {input.contigs} "
# #         "-r '{params.R1} {params.R2}' "
# #         "-t {threads} "
# #         "-m {threads} "
# # rule ntEDIT:
# #     output:
# #     input:
# #     shell:
# #         "nthits && ntedit"

# # rule pilon_polishing:
# #     output:
# #         os.path.join( RESDIR , "{sample}" ,"{assembler_assembly_type}", "pilon_polishing" , "pilon.fasta" )
# #     input:
# #         contigs = os.path.join( RESDIR , "{sample}", "{assembler_assembly_type}" ,  "final_contigs_reformat.fasta"),
# #         bams = ...
# #     params:
# #         outdir = os.path.join( RESDIR , "{sample}" ,"{assembler_assembly_type}", "pilon_polishing" )
    
# #     wildcard_constraints:
# #         assembler_assembly_type = ".*long_reads"
# #     shell:
# #         "pilon --genome {input.contigs} "
# #         "--bam {input.bam} "
# #         "--outdir {params.outdir} "