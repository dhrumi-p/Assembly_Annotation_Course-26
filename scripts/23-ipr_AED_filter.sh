#!/bin/bash

#SBATCH --job-name=ipr_AED_filter
#SBATCH --partition=pibu_el8
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --reservation=class-sbl-30004-2026-10-28
#SBATCH --output=/data/users/dpatel/assembly_annotation_course/logs/output/ipr_AED_filter_%j.o
#SBATCH --error=/data/users/dpatel/assembly_annotation_course/logs/error/ipr_AED_filter_%j.e

#
# Script 23: refine and filter the MAKER gene annotation
#
# These steps come after InterProScan
#   Part 1 - add InterProScan results (Pfam, InterPro, GO) to the GFF
#   Part 2 - summarise AED (Annotation Edit Distance) values (gene model quality)
#   Part 3 - quality filter: keep well-supported gene models
#   Part 4 - keep only gene features in the GFF
#   Part 5 - extract protein and transcript sequences of the kept genes
#
# Input  (in final_gene_annotation/): renamed GFF + FASTA files (needed for part5),
#                                     output.iprscan (script 22)
# Output (in final_gene_annotation/): filtered.genes.renamed.gff3 and the
#                                     filtered protein/transcript FASTA files




# Stop on failed commands, unset variables, or failures within pipelines.
set -euo pipefail

# Paths 
# Course software and project folder
COURSEDIR=/data/courses/genome_annotation_resources/2026
WORKDIR=/data/users/dpatel/assembly_annotation_course

# Containers: MAKER (ipr_update_gff, AED and quality-filter scripts)
# and the analysis container (seqkit, for extracting FASTA sequences)
MAKER_SIF="$COURSEDIR/containers/MAKER_3.01.03.sif"
ANALYSIS_SIF="$COURSEDIR/containers/Annotation_analysis_R4.4.sif"

# Working folder: renamed files from script 21 + output.iprscan from script 22
FINALDIR="$WORKDIR/output/MAKER_merged/final_gene_annotation"

# Base file names of the merged MAKER outputs
protein="assembly.all.maker.proteins.fasta"       # predicted protein sequences
transcript="assembly.all.maker.transcripts.fasta" # predicted transcript sequences
gff="assembly.all.maker.noseq.gff"                # gene annotation without sequences (noseq)

# Prevent inherited container settings from changing the course environment.
unset SINGULARITY_BIND APPTAINER_BIND SINGULARITY_TMPDIR

# Scratch folder for temporary files (bound to /tmp inside the container)
mkdir -p "$FINALDIR/tmp"
cd "$FINALDIR"




# Part 1: add InterProScan results to the GFF 
# ipr_update_gff adds the Pfam domains, InterPro IDs and GO terms found by
# InterProScan to the matching mRNA lines of the renamed GFF.
apptainer exec --cleanenv --env TMPDIR=/tmp --bind "$FINALDIR/tmp":/tmp \
    --bind "$COURSEDIR" --bind "$WORKDIR" --pwd "$FINALDIR" "$MAKER_SIF" \
    ipr_update_gff "${gff}.renamed.gff" output.iprscan > "${gff}.renamed.iprscan.gff"




# Part 2: AED distribution 
# AED (Annotation Edit Distance) scores how well each gene model agrees with
# the evidence (Trinity transcripts, protein alignments):
#   0 = perfect agreement, 1 = no evidence support.
# AED_cdf_generator.pl writes the cumulative distribution in 0.025 steps:
# each line = AED value and the fraction of genes with an AED at or below it.
# Most genes should fall between 0 and 0.5.
apptainer exec --cleanenv --env TMPDIR=/tmp --bind "$FINALDIR/tmp":/tmp \
    --bind "$COURSEDIR" --bind "$WORKDIR" --pwd "$FINALDIR" "$MAKER_SIF" \
    perl /usr/local/bin/AED_cdf_generator.pl -b 0.025 "${gff}.renamed.gff" > assembly.all.maker.renamed.gff.AED.txt

# Print the AED table to the log file
echo "AED cumulative distribution:"
cat assembly.all.maker.renamed.gff.AED.txt




# Part 3: quality filter 
# quality_filter.pl -s keeps transcripts that have AED < 1 (some evidence
# support) and/or a Pfam domain; unsupported predictions are removed.
apptainer exec --cleanenv --env TMPDIR=/tmp --bind "$FINALDIR/tmp":/tmp \
    --bind "$COURSEDIR" --bind "$WORKDIR" --pwd "$FINALDIR" "$MAKER_SIF" \
    perl /usr/local/bin/quality_filter.pl -s "${gff}.renamed.iprscan.gff" > "${gff}_iprscan_quality_filtered.gff"




# Part 4: keep only gene features 
# The MAKER GFF also contains evidence lines (EST/protein alignments, repeats).
# Keep only the gene models: gene, mRNA, exon, CDS and UTR lines (column 3).
grep -P "\tgene\t|\tCDS\t|\texon\t|\tfive_prime_UTR\t|\tthree_prime_UTR\t|\tmRNA\t" \
    "${gff}_iprscan_quality_filtered.gff" > filtered.genes.renamed.gff3

# Add the required GFF3 header as the first line
sed -i '1i##gff-version 3' filtered.genes.renamed.gff3

# Check: list the feature types left in the file (printed to the log)
echo "Feature types kept:"
cut -f3 filtered.genes.renamed.gff3 | sort | uniq

# Part 5: extract sequences of the kept gene models 
# Collect the IDs of all remaining mRNAs (e.g. RRS0000001.RA) into list.txt
grep -P "\tmRNA\t" filtered.genes.renamed.gff3 | awk '{print $9}' | cut -d ';' -f1 | sed 's/ID=//g' > list.txt
echo "mRNAs kept after filtering: $(wc -l < list.txt)"

# Keep only the transcripts whose ID is in list.txt (seqkit grep -f = IDs from file)
apptainer exec --cleanenv --bind "$COURSEDIR" --bind "$WORKDIR" --pwd "$FINALDIR" "$ANALYSIS_SIF" \
    seqkit grep -f list.txt "${transcript}.renamed.fasta" -o "${transcript}.renamed.filtered.fasta"

# Same for the protein sequences
apptainer exec --cleanenv --bind "$COURSEDIR" --bind "$WORKDIR" --pwd "$FINALDIR" "$ANALYSIS_SIF" \
    seqkit grep -f list.txt "${protein}.renamed.fasta" -o "${protein}.renamed.filtered.fasta"

# final annotation files 
#   filtered.genes.renamed.gff3                               - filtered gene models
#   assembly.all.maker.proteins.fasta.renamed.filtered.fasta    - their proteins
#   assembly.all.maker.transcripts.fasta.renamed.filtered.fasta - their transcripts
echo "Final annotation files in $FINALDIR:"
ls -lh filtered.genes.renamed.gff3 "${protein}.renamed.filtered.fasta" "${transcript}.renamed.filtered.fasta"