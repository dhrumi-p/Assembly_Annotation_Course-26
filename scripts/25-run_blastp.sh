#!/bin/bash

#SBATCH --job-name=run_blastp
#SBATCH --partition=pibu_el8
#SBATCH --nodes=1
#SBATCH --cpus-per-task=20
#SBATCH --mem=16G
#SBATCH --time=03:00:00
#SBATCH --output=/data/users/dpatel/assembly_annotation_course/logs/output/run_blastp_%j.o
#SBATCH --error=/data/users/dpatel/assembly_annotation_course/logs/error/run_blastp_%j.e

#
# Script 25: sequence homology to functionally validated proteins
#
#   Part 1 - BLASTP of the filtered proteins against UniProt (reviewed plant
#            proteins) and TAIR10 (A. thaliana reference), run in parallel
#   Part 2 - keep the best hit per protein for each database
#   Part 3 - add the UniProt functions to copies of the protein FASTA and GFF3
#
# Input  (in final_gene_annotation/): filtered protein FASTA, filtered.genes.renamed.gff3
# Output (in output/comparisons/):    blastp_uniprot.tsv, blastp_TAIR10.tsv,
#                                     *.besthits.tsv, maker_proteins.filtered.Uniprot.fasta,
#                                     filtered.genes.Uniprot.gff3
#

# Stop on failed commands, unset variables, or failures within pipelines.
set -euo pipefail

# Paths

# Course software and project folder
COURSEDIR=/data/courses/genome_annotation_resources/2026
WORKDIR=/data/users/dpatel/assembly_annotation_course

# MAKER container 
MAKER_SIF="$COURSEDIR/containers/MAKER_3.01.03.sif"

# Folder with the final annotation files (inputs)
INP_DIR="$WORKDIR/output/MAKER_merged/final_gene_annotation"
PROTEINS="$INP_DIR/assembly.all.maker.proteins.fasta.renamed.filtered.fasta"
GENES="$INP_DIR/filtered.genes.renamed.gff3"

# Reference protein databases (already indexed with makeblastdb)
UNIPROT="$COURSEDIR/data/uniprot_viridiplantae_reviewed.fa"
TAIR10="$COURSEDIR/data/TAIR10_pep_20110103_representative_gene_model"

# Output directory for the comparison results
OUT_DIR="$WORKDIR/output/comparisons"

# Prevent inherited container settings from changing the course environment.
unset SINGULARITY_BIND APPTAINER_BIND SINGULARITY_TMPDIR

mkdir -p "$OUT_DIR/tmp"
cd "$OUT_DIR"

# Part 1: BLASTP against UniProt and TAIR10
# BLAST+ is loaded as a cluster module 
# Module scripts can use unset variables, so "set -u" is paused around it.
set +u
module load BLAST+/2.15.0-gompi-2021a
set -u

# The databases are already indexed, so makeblastdb is not needed:
# makeblastdb -in "$UNIPROT" -dbtype prot
# makeblastdb -in "$TAIR10" -dbtype prot

# Both searches run at the same time ("&" = run in the background), 10 CPUs each.
# -outfmt 6        : tabular output (query, subject, %identity, ..., evalue, bitscore)
# -evalue 1e-5     : keep only significant hits
# -max_target_seqs : keep up to 10 hits per protein
blastp -query "$PROTEINS" -db "$UNIPROT" -num_threads 10 -outfmt 6 \
    -evalue 1e-5 -max_target_seqs 10 -out "$OUT_DIR/blastp_uniprot.tsv" &
uniprot_job=$!   # remember the process ID of the UniProt search

blastp -query "$PROTEINS" -db "$TAIR10" -num_threads 10 -outfmt 6 \
    -evalue 1e-5 -max_target_seqs 10 -out "$OUT_DIR/blastp_TAIR10.tsv" &
tair_job=$!      # remember the process ID of the TAIR10 search

# Wait for both searches; with "set -e" the job stops if either one failed
wait "$uniprot_job"
wait "$tair_job"




# Part 2: keep the highest-scoring hit for each query protein
# sort: by protein ID (col 1), then highest bitscore (col 12), then lowest evalue (col 11)
# awk:  print only the first (= best) line seen for each protein
for reference in uniprot TAIR10; do
    sort -k1,1 -k12,12gr -k11,11g "$OUT_DIR/blastp_${reference}.tsv" | \
        awk -F '\t' '!seen[$1]++' > "$OUT_DIR/blastp_${reference}.besthits.tsv"
done




# Part 3: add the UniProt functions to copies of the protein FASTA and GFF3
# (the original files in final_gene_annotation/ stay unchanged)
apptainer exec --cleanenv --env TMPDIR=/tmp \
    --bind /data --bind "$WORKDIR" --bind "$OUT_DIR/tmp":/tmp \
    --pwd "$OUT_DIR" "$MAKER_SIF" \
    maker_functional_fasta "$UNIPROT" "$OUT_DIR/blastp_uniprot.besthits.tsv" "$PROTEINS" \
    > "$OUT_DIR/maker_proteins.filtered.Uniprot.fasta"

apptainer exec --cleanenv --env TMPDIR=/tmp \
    --bind /data --bind "$WORKDIR" --bind "$OUT_DIR/tmp":/tmp \
    --pwd "$OUT_DIR" "$MAKER_SIF" \
    maker_functional_gff "$UNIPROT" "$OUT_DIR/blastp_uniprot.besthits.tsv" "$GENES" \
    > "$OUT_DIR/filtered.genes.Uniprot.gff3"

