#!/bin/bash

#SBATCH --job-name=LTR_plots
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=4
#SBATCH --mem=4G
#SBATCH --time=01:00:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --reservation=class-sbl-30004-2026-10-14
#SBATCH --output=/data/users/dpatel/assembly_annotation_course/logs/output/LTR_plots_%j.o
#SBATCH --error=/data/users/dpatel/assembly_annotation_course/logs/error/LTR_plots_%j.e


# paths 
COURSEDIR=/data/courses/genome_annotation_resources/2026
WORKDIR=/data/users/dpatel/assembly_annotation_course 

# changing to LTR_full_length, so that it can fetch the required files 
cd "$WORKDIR/output/LTR_full_length"

apptainer exec -C \
    --bind "$WORKDIR" \
    --bind "$COURSEDIR" \
    --pwd "$PWD" \
    "$COURSEDIR/containers/Annotation_analysis_R4.4.sif" \
    Rscript --vanilla "$COURSEDIR/scripts/03-full_length_LTRs_identity_copy.R"

    