#!/bin/bash

#SBATCH --job-name=MAKER_merge
#SBATCH --partition=pibu_el8
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=02:00:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --reservation=class-sbl-30004-2026-10-28
#SBATCH --output=/data/users/dpatel/assembly_annotation_course/logs/output/MAKER_merge_%j.o
#SBATCH --error=/data/users/dpatel/assembly_annotation_course/logs/error/MAKER_merge_%j.e

# Stop on failed commands, unset variables, or failures within pipelines.
set -euo pipefail

# Shared course software and project folder
COURSEDIR=/data/courses/genome_annotation_resources/2026
WORKDIR=/data/users/dpatel/assembly_annotation_course

# MAKER container (contains gff3_merge and fasta_merge)
MAKER_SIF="$COURSEDIR/containers/MAKER_3.01.03.sif"

# MAKER run folder (folder where the output of the MAKER job is present )
OUTDIR="$WORKDIR/output/MAKER"

# Separate folder for the merged GFF3 and FASTA files
MERGEDIR="$WORKDIR/output/MAKER_merged"

# Prevent inherited container settings from changing the course environment.
unset SINGULARITY_BIND APPTAINER_BIND SINGULARITY_TMPDIR

mkdir -p "$OUTDIR/tmp" "$MERGEDIR"

# Run from the MAKER folder: the index log uses paths relative to it
cd "$OUTDIR"

# Find the MAKER datastore index log (lists every contig and its result folder).
# nullglob: if nothing matches, the array is empty instead of holding the pattern.
shopt -s nullglob
INDEXES=(*.maker.output/*_master_datastore_index.log)

# Stop with a clear message unless exactly one index file was found
if [ "${#INDEXES[@]}" -ne 1 ]; then
    echo "ERROR: expected exactly 1 datastore index log, found ${#INDEXES[@]}" >&2
    exit 1
fi
INDEX="${INDEXES[0]}"
echo "Using datastore index: $INDEX"

# Step 1: merge all per-contig GFF3 files into one GFF3 (with sequences at the end)
apptainer exec --cleanenv --env TMPDIR=/tmp --bind "$OUTDIR/tmp":/tmp \
    --bind "$COURSEDIR" --bind "$WORKDIR" --pwd "$OUTDIR" "$MAKER_SIF" \
    gff3_merge -d "$INDEX" -o "$MERGEDIR/assembly.all.maker.gff"

# Step 2: same merge, but without the FASTA sequences (-n); smaller and easier to use
apptainer exec --cleanenv --env TMPDIR=/tmp --bind "$OUTDIR/tmp":/tmp \
    --bind "$COURSEDIR" --bind "$WORKDIR" --pwd "$OUTDIR" "$MAKER_SIF" \
    gff3_merge -n -d "$INDEX" -o "$MERGEDIR/assembly.all.maker.noseq.gff"

# Step 3: merge all predicted protein and transcript FASTA files
# (writes assembly.all.maker.proteins.fasta, assembly.all.maker.transcripts.fasta, ...)
apptainer exec --cleanenv --env TMPDIR=/tmp --bind "$OUTDIR/tmp":/tmp \
    --bind "$COURSEDIR" --bind "$WORKDIR" --pwd "$OUTDIR" "$MAKER_SIF" \
    fasta_merge -d "$INDEX" -o "$MERGEDIR/assembly"


