#!/bin/bash

#SBATCH --job-name=riparian_plots
#SBATCH --partition=pibu_el8
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=00:30:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --reservation=class-sbl-30004-2026-11-11 
#SBATCH --output=/data/users/dpatel/assembly_annotation_course/logs/output/riparian_plots_%j.o
#SBATCH --error=/data/users/dpatel/assembly_annotation_course/logs/error/riparian_plots_%j.e

#
# Script 31: riparian synteny plots
#
# Runs scripts/31-synteny_riparian_plots.R inside the GENESPACE container.

# Input:  GENESPACE results from script 29 (results/gsParams.rda)
# Output: output/comparisons/GENESPACE/processed_riparian/*.pdf (set in the R script)
#

# Stop on failed commands, unset variables, or failures within pipelines.
set -euo pipefail

# Paths

# Course software and project folder
COURSEDIR=/data/courses/genome_annotation_resources/2026
WORKDIR=/data/users/dpatel/assembly_annotation_course

# GENESPACE container
GENESPACE_SIF="$COURSEDIR/containers/genespace_latest.sif"

# The R script
RSCRIPT="/data/users/dpatel/assembly_annotation_course/scripts/31-synteny_riparian_plots.R"

# Prevent inherited container settings from changing the course environment.
unset SINGULARITY_BIND APPTAINER_BIND SINGULARITY_TMPDIR

# Host-backed temporary storage for R (same as script 29)
TMPDIR="$WORKDIR/output/comparisons/GENESPACE_R_tmp"
mkdir -p "$TMPDIR"

cd "$WORKDIR"

apptainer exec --cleanenv \
    --bind /data --bind "$WORKDIR" \
    --bind "$TMPDIR":/temp --env TMPDIR=/temp --pwd "$WORKDIR" \
    "$GENESPACE_SIF" Rscript "$RSCRIPT"




