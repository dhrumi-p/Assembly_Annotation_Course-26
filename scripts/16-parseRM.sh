#!/bin/bash

#SBATCH --job-name=parseRM_divergence
#SBATCH --partition=pibu_el8
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
#SBATCH --time=02:00:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --reservation=class-sbl-30004-2026-10-21
#SBATCH --output=/data/users/dpatel/assembly_annotation_course/logs/output/parseRM_divergence_%j.o
#SBATCH --error=/data/users/dpatel/assembly_annotation_course/logs/error/parseRM_divergence_%j.e

# Stop on failed commands, unset variables, or failures within pipelines.
set -euo pipefail

# Shared course software and your project folder
COURSEDIR=/data/courses/genome_annotation_resources/2026
WORKDIR=/data/users/dpatel/assembly_annotation_course

# Container with perl, R 4.4 and the course scripts' dependencies
R_SIF="$COURSEDIR/containers/Annotation_analysis_R4.4.sif"

# EDTA annotation folder that contains the RepeatMasker output (input, left untouched)
genome=assembly.fasta
ANNODIR="$WORKDIR/output/EDTA/$genome.mod.EDTA.anno"

# Separate output folder for the filtered file and the landscape tables
OUTDIR="$WORKDIR/output/parseRM_TE_divergence"

# Prevent inherited container settings from changing the course environment.
unset SINGULARITY_BIND APPTAINER_BIND

mkdir -p "$OUTDIR"
cd "$OUTDIR"

# Step 1: remove hits with 0% divergence (column 2), which can be the
# library copy matching itself. NR == 1 keeps the first header line.
# Reads from the EDTA folder, writes the filtered file into OUTDIR.
awk 'NR == 1 || $2 != 0' "$ANNODIR/$genome.mod.EDTA.RM.out" > "$genome.mod.EDTA.RM.nonzero.out"


# Step 2: bin divergence values in 1% steps (up to 50%) per TE superfamily.
# parseRM writes its tables next to the input file, so they also land in OUTDIR.
# -i input file, -l max divergence and bin size, -v verbose
apptainer exec -C --bind "$WORKDIR" --bind "$COURSEDIR" --pwd "$OUTDIR" "$R_SIF" \
    perl "$WORKDIR/scripts/16-parseRM.pl" \
    -i "$genome.mod.EDTA.RM.nonzero.out" \
    -l 50,1 \
    -v

