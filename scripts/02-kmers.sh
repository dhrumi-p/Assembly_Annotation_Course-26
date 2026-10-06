#!/bin/bash

#SBATCH --job-name=kmer_assembly_annotation
#SBATCH --cpus-per-task=4
#SBATCH --time=01:00:00
#SBATCH --mem=64G
#SBATCH --partition=pshort_el8
#SBATCH --output=/data/users/dpatel/assembly_annotation_course/logs/output/kmer_%j.o
#SBATCH --error=/data/users/dpatel/assembly_annotation_course/logs/error/kmer_%j.e

 # setting paths, to acess container and also the reads file and where to get the output 
 CONTAINER="/containers/apptainer/jellyfish-2.2.6--0.sif"
 INPUT_DIR="/data/users/dpatel/assembly_annotation_course/raw_data/RRS10/ERR11437326.fastq.gz" # since we r isolating k mers from the genome 
 OUTPUT_DIR="/data/users/dpatel/assembly_annotation_course/output/jellyfish_kmer"

 # generating files for the output of jellyfish_kmer (basically to get the unique kmers from the genome)
OUT_KMER=${OUTPUT_DIR}/k_mer_counts.jf
OUT_HIST=${OUTPUT_DIR}/readss.histo


#zcat is there since we need to open the zip in order to count the contents
# -m 21 is the length of kmer 
apptainer exec --bind /data/ ${CONTAINER} jellyfish count \
    -C -m 21 \
    -s 5000000000 \
    -t $SLURM_CPUS_PER_TASK \
    -o ${OUT_KMER} \
    <(zcat ${INPUT_DIR})


#Histogram
apptainer exec --bind /data/ ${CONTAINER} jellyfish histo -t $SLURM_CPUS_PER_TASK "${OUT_KMER}" > "${OUT_HIST}"