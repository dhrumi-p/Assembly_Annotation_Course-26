#!/bin/bash

#SBATCH --job-name=trinity_assembly
#SBATCH --cpus-per-task=16
#SBATCH --time=1-00:00:00
#SBATCH --mem=64G
#SBATCH --partition=pibu_el8
#SBATCH --output=/data/users/dpatel/assembly_annotation_course/logs/output/trinity_assembly_%j.o
#SBATCH --error=/data/users/dpatel/assembly_annotation_course/logs/error/trinity_assembly_%j.e

# for trinity we have module available and not the container 
module load Trinity

# setting paths, to access the reads file and where to get the output
INPUT_DIR="/data/users/dpatel/assembly_annotation_course/raw_data/RNAseq_Sha"
OUTPUT_DIR="/data/users/dpatel/assembly_annotation_course/output/trinity_assembly"

# run Trinity (paired-end de novo transcriptome assembly)
Trinity \
    --seqType fq \
    --left  ${INPUT_DIR}/ERR754081_1.fastq.gz \
    --right ${INPUT_DIR}/ERR754081_2.fastq.gz \
    --max_memory 64G \
    --CPU $SLURM_CPUS_PER_TASK \
    --output ${OUTPUT_DIR}


    