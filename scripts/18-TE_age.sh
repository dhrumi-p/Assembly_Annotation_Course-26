#!/bin/bash

#SBATCH --job-name=TE_age
#SBATCH --partition=pibu_el8
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --reservation=class-sbl-30004-2026-10-21
#SBATCH --output=/data/users/dpatel/assembly_annotation_course/logs/output/TE_age_%j.o
#SBATCH --error=/data/users/dpatel/assembly_annotation_course/logs/error/TE_age_%j.e

# Stop on failed commands, unset variables, or failures within pipelines.
set -euo pipefail

# Shared course software and project folder
COURSEDIR=/data/courses/genome_annotation_resources/2026
WORKDIR=/data/users/dpatel/assembly_annotation_course

# Container with R 4.4 and the plotting packages
R_SIF="$COURSEDIR/containers/Annotation_analysis_R4.4.sif"

# path to the R script
RSCRIPT="$WORKDIR/scripts/18-TE_age.R"

# Folder with the parseRM landscape tables from script 16
OUTDIR="$WORKDIR/output/parseRM_TE_divergence"

# Prevent inherited container settings from changing the course environment.
unset SINGULARITY_BIND APPTAINER_BIND

cd "$OUTDIR"
# The R script saves its plot into Plots
mkdir -p Plots

# Run the R script from inside OUTDIR
apptainer exec -C --bind "$WORKDIR" --bind "$COURSEDIR" --pwd "$OUTDIR" "$R_SIF" \
    Rscript --vanilla "$RSCRIPT"