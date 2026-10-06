#!/bin/bash

#SBATCH --job-name=Fastqc_assembly_annotation
#SBATCH --cpus-per-task=4
#SBATCH --time=01:00:00
#SBATCH --mem=8G
#SBATCH --partition=pshort_el8
#SBATCH --output=/data/users/dpatel/assembly_annotation_course/logs/output/fastqc_%j.o
#SBATCH --error=/data/users/dpatel/assembly_annotation_course/logs/error/fastqc_%j.e

 # setting paths, to acess container and also the reads file and where to get the output 
 CONTAINER="/containers/apptainer/fastqc-0.12.1.sif"
 INPUT_DIR="/data/users/dpatel/assembly_annotation_course/raw_data"
 OUTPUT_DIR="/data/users/dpatel/assembly_annotation_course/output/fastqc"

 # to run containers apptainers are required 
 # By default apptainer reads my directories to the container, it does for home directory, but that doesnto have my sample
 # and the other folders and so bind is used here 
 # so binds helps to connect the folder from my computer(here cluster) to the container
 # so, first we have added the input directory in code and then with -o we have given the path for output directory
 #apptainer exec --bind /data/users/dpatel/assembly_annotation_course:/data/users/dpatel/assembly_annotation_course "$CONTAINER" fastqc \
    #"$INPUT_DIR"/*.fastq.gz \
    #-o "$OUTPUT_DIR" \
    #-t $SLURM_CPUS_PER_TASK

apptainer exec --bind /data:/data "$CONTAINER" fastqc \
    "$INPUT_DIR"/*/*.fastq.gz \
    -o "$OUTPUT_DIR" \
    -t $SLURM_CPUS_PER_TASK


echo "FastQC analysis complete" 