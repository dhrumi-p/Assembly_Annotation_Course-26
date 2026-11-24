#!/bin/bash

#SBATCH --job-name=rename_gene_IDs
#SBATCH --partition=pibu_el8
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --reservation=class-sbl-30004-2026-10-28
#SBATCH --output=/data/users/dpatel/assembly_annotation_course/logs/output/rename_gene_IDs_%j.o
#SBATCH --error=/data/users/dpatel/assembly_annotation_course/logs/error/rename_gene_IDs_%j.e

# Stop on failed commands, unset variables, or failures within pipelines.
set -euo pipefail

# Shared course software and project folder
COURSEDIR=/data/courses/genome_annotation_resources/2026
WORKDIR=/data/users/dpatel/assembly_annotation_course
# path to the container 
MAKER_SIF="$COURSEDIR/containers/MAKER_3.01.03.sif"

# Merged MAKER files(generated from script 20 in Maker_merged in the output folder) and the folder for the final annotation
MERGEDIR="$WORKDIR/output/MAKER_merged"
FINALDIR="$MERGEDIR/final_gene_annotation"

# File names of the merged MAKER outputs
protein="assembly.all.maker.proteins.fasta"
transcript="assembly.all.maker.transcripts.fasta"
gff="assembly.all.maker.noseq.gff"

# Accession prefix for the new gene IDs (3-4 letters, e.g. ALT for Altai).
# >>> Replace ACC with your accession's short name before submitting <<<
prefix=RRS

# Prevent inherited container settings from changing the course environment.
unset SINGULARITY_BIND APPTAINER_BIND SINGULARITY_TMPDIR

mkdir -p "$FINALDIR/tmp"

# Step 1: copy the merged files into final_gene_annotation/ under new names;
# the originals in MAKER_merged/ stay unchanged
cp "$MERGEDIR/$gff"        "$FINALDIR/${gff}.renamed.gff"
cp "$MERGEDIR/$protein"    "$FINALDIR/${protein}.renamed.fasta"
cp "$MERGEDIR/$transcript" "$FINALDIR/${transcript}.renamed.fasta"

cd "$FINALDIR"

echo "IDs before renaming:"
cut -f9 "${gff}.renamed.gff" | cut -d ';' -f1 | sed 's/ID=//g' | head || true

# Step 2: build the old-ID -> new-ID table (e.g. RRS0000001, RRS0000001.RA)
apptainer exec --cleanenv --env TMPDIR=/tmp --bind "$FINALDIR/tmp":/tmp \
    --bind "$COURSEDIR" --bind "$WORKDIR" --pwd "$FINALDIR" "$MAKER_SIF" \
    maker_map_ids --prefix "$prefix" --justify 7 "${gff}.renamed.gff" > id.map

# Step 3: apply the new IDs to the GFF and both FASTA files (edited in place)
apptainer exec --cleanenv --env TMPDIR=/tmp --bind "$FINALDIR/tmp":/tmp \
    --bind "$COURSEDIR" --bind "$WORKDIR" --pwd "$FINALDIR" "$MAKER_SIF" \
    map_gff_ids id.map "${gff}.renamed.gff"

apptainer exec --cleanenv --env TMPDIR=/tmp --bind "$FINALDIR/tmp":/tmp \
    --bind "$COURSEDIR" --bind "$WORKDIR" --pwd "$FINALDIR" "$MAKER_SIF" \
    map_fasta_ids id.map "${protein}.renamed.fasta"

apptainer exec --cleanenv --env TMPDIR=/tmp --bind "$FINALDIR/tmp":/tmp \
    --bind "$COURSEDIR" --bind "$WORKDIR" --pwd "$FINALDIR" "$MAKER_SIF" \
    map_fasta_ids id.map "${transcript}.renamed.fasta"

echo "IDs after renaming:"
cut -f9 "${gff}.renamed.gff" | cut -d ';' -f1 | sed 's/ID=//g' | head || true