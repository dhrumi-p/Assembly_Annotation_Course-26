#!/bin/bash

#SBATCH --job-name=TE_circlize
#SBATCH --partition=pibu_el8
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
#SBATCH --time=02:00:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --reservation=class-sbl-30004-2026-10-21
#SBATCH --output=/data/users/dpatel/assembly_annotation_course/logs/output/TE_circlize_%j.o
#SBATCH --error=/data/users/dpatel/assembly_annotation_course/logs/error/TE_circlize_%j.e

# Stop on failed commands, unset variables, or failures within pipelines.
set -euo pipefail

# Shared course software and your project folder
COURSEDIR=/data/courses/genome_annotation_resources/2026
WORKDIR=/data/users/dpatel/assembly_annotation_course

# Container with R 4.4, circlize and samtools
R_SIF="$COURSEDIR/containers/Annotation_analysis_R4.4.sif"

# Inputs
GENOME="$WORKDIR/output/flye_assembly/assembly.fasta"
RSCRIPT="$WORKDIR/scripts/14-run_TE_circlize.R"

# Output folder for the plot
OUTDIR="$WORKDIR/output/TE_circlize"

# Prevent inherited container settings from changing the course environment.
unset SINGULARITY_BIND APPTAINER_BIND

mkdir -p "$OUTDIR"
cd "$OUTDIR"

# Step 1: index the assembly; creates assembly.fasta.fai next to assembly.fasta
# this is needed to get the length of scaffolds 
apptainer exec -C --bind "$WORKDIR" "$R_SIF" \
    samtools faidx "$GENOME"

# Step 2: run the R script from inside OUTDIR, so 02-TE_density.pdf is saved there
apptainer exec -C --bind "$WORKDIR" --bind "$COURSEDIR" --pwd "$OUTDIR" "$R_SIF" \
    Rscript --vanilla "$RSCRIPT"

