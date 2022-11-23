#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pysam
import argparse
import time


if __name__ == '__main__':
    # parsing script arguments
    try:
        f_infile = str(snakemake.input)
        f_outfile = str(snakemake.output)

        min_mapq = snakemake.params.min_mapq
        min_idt = snakemake.params.min_idt
        min_len = snakemake.params.min_len
        pp = snakemake.params.pp
        dryrun = False

    except NameError:
        parser = argparse.ArgumentParser(
            prog='bampreprocess',
            description='Filter reads in a BAM file. ')
        parser.add_argument(
            'infile', type=str,
            help='input BAM file')
        parser.add_argument(
            '-o', '--outfile', nargs='?', type=argparse.FileType('w'),
            help='(Required) name of the filtered BAM file')
        parser.add_argument(
            '-q', '--mapping-quality', nargs='?', type=int,
            default=20,
            help='minimum mapping quality to keep a read (default: 20)')
        parser.add_argument(
            '-m', '--minimum-identity', nargs='?', type=int,
            default=95,
            help='minimum percentage of matching identity to keep a read '
            '(default: 95)')
        parser.add_argument(
            '--min-len', nargs='?', type=int,
            default=50,
            help='minimum alignement length '
            '(default: 50)')
        parser.add_argument(
            '--properly-paired-only', action='store_true',
            help='(Optional) keep only properly paired reads ')
        parser.add_argument(
            '-n', '--dry-run', action='store_true',
            help='(Optional) do not write output file but still report filtering')
        args = parser.parse_args()

        f_infile = args.infile
        f_outfile = args.outfile
        pp = args.properly_paired_only 
        min_idt = args.minimum_identity
        min_mapq  = args.mapping_quality
        min_len = args.min_len
        dryrun = args.dry_run

    if dryrun:
        print('Dry run is enabled, no output file will be written.')

    print("loading file :\t",f_infile)

    start_time = time.time()
    # Initialize counters for filtering logs
    inreads = 0
    filtreads = 0
    filtmapq = 0
    filtmapi = 0
    filtlen = 0
    outreads = 0
    

    # Open BAM to parse
    with pysam.AlignmentFile(f_infile, 'rb') as infile, \
            pysam.AlignmentFile(f_outfile, 'wb', template=infile) as outfile:
        for read in infile:
            inreads += 1
            # Check if not properly paired, if it's required
            if pp and not read.is_proper_pair:
                filtreads += 1
                continue
            # Check MAPQ and identity thresholds
            # The % identity is computed using the NM tag (= edit distance)
            # and the read length. We remove the undefined bases present in
            # the reference because Ns are automatically counted as mismatches
            # in NM.
            mismatches = (
                (read.get_tag('NM') - read.get_tag('XN'))
                / read.query_length
            )
            idt = (1 - mismatches) * 100
            # MAPQ measures the probability that the mapping was unique on ref
            mapq = read.mapping_quality
            aln_length = read.reference_end - read.reference_start


            if (idt < min_idt) or (mapq < min_mapq) or (aln_length < min_len):
                # Counting for logs
                filtreads += 1
                filtmapq += (mapq < min_mapq)
                filtmapi += (idt < min_idt)
                filtlen += (aln_length < min_len)
                continue

            # If every test was passed, write the read to the output file
            outreads += 1
            if not dryrun:
                outfile.write(read)

    print('Number of reads in original file: {}'.format(
        inreads))
    print('Reads removed: {0} ({1:.2f}%)'.format(
        filtreads, 100 * filtreads / inreads))
    print('... because of MAPQ: {0} ({1:.2f}%)'.format(
        filtmapq, 100 * filtmapq / inreads))
    print('... because of identity: {0} ({1:.2f}%)'.format(
        filtmapi, 100 * filtmapi / inreads))
    print('... because of alignement length: {0} ({1:.2f}%)'.format(
        filtlen, 100 * filtlen / inreads))
    print('... because of both: {0} ({1:.2f}%)'.format(
        (filtmapq+filtmapi+filtlen-filtreads),
        100 * (filtmapq+filtmapi+filtlen-filtreads) / inreads))
    print('New number of reads: {}'.format(
        outreads))
    print('Total time: {0:.2f} minutes'.format(
        (time.time() - start_time)/60))
