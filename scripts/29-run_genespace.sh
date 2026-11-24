#!/bin/bash

#SBATCH --job-name=run_genespace
#SBATCH --partition=pibu_el8
#SBATCH --nodes=1
#SBATCH --cpus-per-task=20
#SBATCH --mem=64G
#SBATCH --time=02:00:00
#SBATCH --output=/data/users/dpatel/assembly_annotation_course/logs/output/run_genespace_%j.o
#SBATCH --error=/data/users/dpatel/assembly_annotation_course/logs/error/run_genespace_%j.e

#
# Script 29: run GENESPACE 
#
# Runs the R script 28-genespace.R inside the GENESPACE container on the
# five genomes prepared by script 27 (RRS_10, TAIR10, Kar_1, Are_6, Est_0).
#
# Input:  output/comparisons/GENESPACE/bed/ and peptide/ (script 27)
# Output: GENESPACE results in output/comparisons/GENESPACE/
#         (orthofinder/, syntenicHits/, dotplots/, riparian/, pangenes/,
#          results/, pangenome_matrix.rds)
#

# Stop on failed commands, unset variables, or failures within pipelines.
set -euo pipefail

# Paths

# Course software and project folder
COURSEDIR=/data/courses/genome_annotation_resources/2026
WORKDIR=/data/users/dpatel/assembly_annotation_course

# GENESPACE working directory (contains bed/ and peptide/ from script 27)
GENESPACE_DIR="$WORKDIR/output/comparisons/GENESPACE"

# GENESPACE container (R + GENESPACE + DIAMOND + OrthoFinder + MCScanX)
GENESPACE_SIF="$COURSEDIR/containers/genespace_latest.sif"

# The R script (script 28)
RSCRIPT="$WORKDIR/scripts/28-genespace.R"

# Prevent inherited container settings from changing the course environment.
unset SINGULARITY_BIND APPTAINER_BIND SINGULARITY_TMPDIR

# Use host-backed temporary storage for R's parallel workers
# (the container's own /tmp is too small)
TMPDIR="$WORKDIR/output/comparisons/GENESPACE_R_tmp"
mkdir -p "$TMPDIR"

cd "$WORKDIR"

# Run the R script; the GENESPACE directory is passed as its only argument (wd)
apptainer exec --cleanenv \
    --bind /data --bind "$WORKDIR" \
    --bind "$TMPDIR":/temp --env TMPDIR=/temp --pwd "$WORKDIR" \
    "$GENESPACE_SIF" Rscript "$RSCRIPT" "$GENESPACE_DIR"



    