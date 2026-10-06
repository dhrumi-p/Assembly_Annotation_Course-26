#!/bin/bash

#SBATCH --job-name=LJA_assembly
#SBATCH --cpus-per-task=16
#SBATCH --time=1-00:00:00
#SBATCH --mem=64G
#SBATCH --partition=pibu_el8
#SBATCH --output=/data/users/dpatel/assembly_annotation_course/logs/output/LJA_assembly_%j.o
#SBATCH --error=/data/users/dpatel/assembly_annotation_course/logs/error/LJA_assembly_%j.e

# setting paths, to access container and also the reads file and where to get the output
CONTAINER="/containers/apptainer/lja-0.2.sif"
INPUT_DIR="/data/users/dpatel/assembly_annotation_course/raw_data/RRS10/ERR11437326.fastq.gz"
OUTPUT_DIR="/data/users/dpatel/assembly_annotation_course/output/LJA_assembly"

# run LJA assembly
apptainer exec --bind /data/ ${CONTAINER} lja \
    --diploid \
    -o ${OUTPUT_DIR} \
    --reads ${INPUT_DIR} \
    -t $SLURM_CPUS_PER_TASK

# diploid since the plant genome we r dealing with is heterozygous 