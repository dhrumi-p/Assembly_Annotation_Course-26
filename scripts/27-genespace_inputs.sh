#!/bin/bash

#SBATCH --job-name=genespace_inputs
#SBATCH --partition=pibu_el8
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=00:30:00
#SBATCH --output=/data/users/dpatel/assembly_annotation_course/logs/output/genespace_inputs_%j.o
#SBATCH --error=/data/users/dpatel/assembly_annotation_course/logs/error/genespace_inputs_%j.e

#
# Script 27: prepare the GENESPACE inputs for five genomes (Week 4, Step 1)
#
#   Part 1 - BED + protein FASTA of our accession (RRS_10)
#   Part 2 - copy TAIR10 BED + FASTA from the course directory
#   Part 3 - copy BED + FASTA of three other accessions (Lian et al.)
#   Part 4 - validate that BED and FASTA gene IDs match for every genome
#
# Input:  filtered.genes.renamed.gff3 (read only), longest proteins (script 24),
#         course files for TAIR10 and the other accessions
# Output: output/comparisons/GENESPACE/bed/*.bed and peptide/*.fa
#

# Stop on failed commands, unset variables, or failures within pipelines.
set -euo pipefail

# Three other accessions (names exactly as listed in Lian_et_al/GENESPACE/bed, without .bed)
# Kar-1, Are_6, Est_0 (files use "_" instead of "-")
OTHERS=(Kar_1 Are_6 Est_0)

# Our accession name; GENESPACE does not allow "-", so RRS-10 becomes RRS_10
Accession=RRS_10

# Paths

# Course software and project folder
COURSEDIR=/data/courses/genome_annotation_resources/2026
WORKDIR=/data/users/dpatel/assembly_annotation_course

# Final annotation files (inputs, read only)
INP_DIR="$WORKDIR/output/MAKER_merged/final_gene_annotation"
GENES="$INP_DIR/filtered.genes.renamed.gff3"

# Longest protein per gene, made in script 24 (annotation_quality subfolder)
LONGEST_PROTEINS="$INP_DIR/annotation_quality/assembly.all.maker.proteins.fasta.renamed.longest.fasta"

# GENESPACE working directory (outputs)
OUT_DIR="$WORKDIR/output/comparisons"
GENESPACE_DIR="$OUT_DIR/GENESPACE"

# Course files for the other genomes
LIAN_DIR="$COURSEDIR/data/Lian_et_al/GENESPACE"

# Stop early if the accession placeholders were not replaced
if [[ " ${OTHERS[*]} " == *"ACCESSION_"* ]]; then
    echo "ERROR: replace ACCESSION_1/2/3 in OTHERS=(...) with three real accession names" >&2
    exit 1
fi

mkdir -p "$GENESPACE_DIR/bed" "$GENESPACE_DIR/peptide" "$GENESPACE_DIR/tmp"
cd "$GENESPACE_DIR"


# Part 1: our accession
# BED = scaffold, start, end, gene ID (tab-separated). BED is 0-based,
# so 1 is subtracted from the GFF3 start.
grep -P "\tgene\t" "$GENES" > "$GENESPACE_DIR/temp_genes.gff3"

# Gene ID = first attribute in column 9 (ID=gene_name)
awk 'BEGIN{OFS="\t"} {split($9,a,";"); split(a[1],b,"="); print $1, $4-1, $5, b[2]}' \
    "$GENESPACE_DIR/temp_genes.gff3" > "$GENESPACE_DIR/bed/${Accession}.bed"

# FASTA: remove descriptions and the transcript suffix (-RA, -RB, ...) from headers,
# so the protein IDs match the gene IDs in the BED file
sed '/^>/s/ .*//' "$LONGEST_PROTEINS" | sed '/^>/s/-R[A-Z]*$//' \
    > "$GENESPACE_DIR/peptide/${Accession}.fa"


# Part 2: TAIR10 reference (already uses gene IDs, one protein per gene)
cp "$COURSEDIR/data/TAIR10.bed" "$GENESPACE_DIR/bed/TAIR10.bed"
cp "$COURSEDIR/data/TAIR10.fa"  "$GENESPACE_DIR/peptide/TAIR10.fa"


# Part 3: three other accessions (already prepared; 0-based BED, underscores in names)
for other in "${OTHERS[@]}"; do
    cp "$LIAN_DIR/bed/${other}.bed"    "$GENESPACE_DIR/bed/${other}.bed"
    cp "$LIAN_DIR/peptide/${other}.fa" "$GENESPACE_DIR/peptide/${other}.fa"
done


# Part 4: validate matching IDs for all five genomes
# For each genome: number of genes, duplicate IDs, IDs only in BED, IDs only in FASTA.
# All three problem columns must be 0.
echo "Validation of BED vs FASTA gene IDs:"
printf "%-15s %8s %8s %10s %13s %13s %6s\n" "genome" "BED" "FASTA" "duplicates" "only_in_BED" "only_in_FASTA" "check"
failed=0
for g in "$Accession" TAIR10 "${OTHERS[@]}"; do
    cut -f4 "bed/${g}.bed" | sort > "tmp/${g}.bed.ids"
    grep '^>' "peptide/${g}.fa" | sed 's/^>//; s/ .*//' | sort > "tmp/${g}.fa.ids"

    n_bed=$(wc -l < "tmp/${g}.bed.ids")
    n_fa=$(wc -l < "tmp/${g}.fa.ids")
    # IDs that occur more than once in the BED or in the FASTA
    dups=$(( $(uniq -d "tmp/${g}.bed.ids" | wc -l) + $(uniq -d "tmp/${g}.fa.ids" | wc -l) ))
    only_bed=$(comm -23 <(sort -u "tmp/${g}.bed.ids") <(sort -u "tmp/${g}.fa.ids") | wc -l)
    only_fa=$(comm -13 <(sort -u "tmp/${g}.bed.ids") <(sort -u "tmp/${g}.fa.ids") | wc -l)

    status=OK
    if [ "$dups" -ne 0 ] || [ "$only_bed" -ne 0 ] || [ "$only_fa" -ne 0 ]; then
        status=FAIL; failed=1
    fi
    printf "%-15s %8s %8s %10s %13s %13s %6s\n" "$g" "$n_bed" "$n_fa" "$dups" "$only_bed" "$only_fa" "$status"
done

echo
ls -lh "$GENESPACE_DIR/bed" "$GENESPACE_DIR/peptide"

if [ "$failed" -ne 0 ]; then
    echo "ERROR: at least one genome has mismatching IDs; fix before running GENESPACE" >&2
    exit 1
fi
echo "All five genomes passed. Inputs are ready in $GENESPACE_DIR"