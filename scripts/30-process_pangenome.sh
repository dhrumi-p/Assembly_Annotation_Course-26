#!/bin/bash

#SBATCH --job-name=process_pangenome
#SBATCH --partition=pibu_el8
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=00:30:00
#SBATCH --output=/data/users/dpatel/assembly_annotation_course/logs/output/process_pangenome_%j.o
#SBATCH --error=/data/users/dpatel/assembly_annotation_course/logs/error/process_pangenome_%j.e

#
# Script 30: process the GENESPACE pangenome 
#
# Runs  copy of the course script process_pangenome.R (30.R file)
#   Step 4 - copies per accession, core / accessory / accession-specific entries,
#            plots/pangenome_presence_frequency.pdf
#   Step 5 - copy-variable core entries (all genes vs. syntenic PASS genes only),
#            plots/copy_variable_core_comparison.pdf
#
# Input:  GENESPACE/pangenes/TAIR10_pangenes.txt.gz (script 29)
# Output: GENESPACE/process_pangenome/plots/ and tables/
#

# Stop on failed commands, unset variables, or failures within pipelines.
set -euo pipefail

# Paths

# Course software and project folder
COURSEDIR=/data/courses/genome_annotation_resources/2026
WORKDIR=/data/users/dpatel/assembly_annotation_course

# Analysis container (R 4.4)
ANALYSIS_SIF="$COURSEDIR/containers/Annotation_analysis_R4.4.sif"

# Our edited copy of the course R script
RSCRIPT="$WORKDIR/scripts/30-process_pangenome.R"

# Prevent inherited container settings from changing the course environment.
unset SINGULARITY_BIND APPTAINER_BIND SINGULARITY_TMPDIR

# Host-backed temporary storage for R
TMPDIR="$WORKDIR/output/comparisons/Annotation_R_tmp"
mkdir -p "$TMPDIR"

cd "$WORKDIR"

apptainer exec --cleanenv \
    --bind /data --bind "$WORKDIR" \
    --bind "$TMPDIR":/temp --env TMPDIR=/temp --pwd "$WORKDIR" \
    "$ANALYSIS_SIF" Rscript "$RSCRIPT"