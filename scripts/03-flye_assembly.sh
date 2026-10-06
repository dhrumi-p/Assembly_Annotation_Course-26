#!/bin/bash

#SBATCH --job-name=flye_assembly
#SBATCH --cpus-per-task=16
#SBATCH --time=1-00:00:00
#SBATCH --mem=64G
#SBATCH --partition=pibu_el8
#SBATCH --output=/data/users/dpatel/assembly_annotation_course/logs/output/flye_assembly_%j.o
#SBATCH --error=/data/users/dpatel/assembly_annotation_course/logs/error/flye_assembly_%j.e 

# setting paths, to acess container and also the reads file and where to get the output 
 CONTAINER="/containers/apptainer/flye_2.9.5.sif"
 INPUT_DIR="/data/users/dpatel/assembly_annotation_course/raw_data/RRS10/ERR11437326.fastq.gz" # genome assembly  
 OUTPUT_DIR="/data/users/dpatel/assembly_annotation_course/output/flye_assembly" 

# run Flye assembly
apptainer exec --bind /data/ ${CONTAINER} flye \
    --pacbio-hifi ${INPUT_DIR} \
    --out-dir ${OUTPUT_DIR} \
    --threads $SLURM_CPUS_PER_TASK


# using --pacbio-hifi since we have that reads, it is to be changed based on the reads we have 