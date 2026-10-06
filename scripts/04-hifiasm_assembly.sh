#!/bin/bash

#SBATCH --job-name=hifiasm_assembly
#SBATCH --cpus-per-task=16
#SBATCH --time=1-00:00:00
#SBATCH --mem=64G
#SBATCH --partition=pibu_el8
#SBATCH --output=/data/users/dpatel/assembly_annotation_course/logs/output/hifiasm_assembly_%j.o
#SBATCH --error=/data/users/dpatel/assembly_annotation_course/logs/error/hifiasm_assembly_%j.e 

# setting paths, to acess container and also the reads file and where to get the output 
 CONTAINER="/containers/apptainer/hifiasm_0.25.0.sif"
 INPUT_DIR="/data/users/dpatel/assembly_annotation_course/raw_data/RRS10/ERR11437326.fastq.gz"   
 OUTPUT_DIR="/data/users/dpatel/assembly_annotation_course/output/hifiasm_assembly" 

# run LJA assembly
apptainer exec --bind /data/ ${CONTAINER} hifiasm \
    -o ${OUTPUT_DIR}/RRS10 \
    -t $SLURM_CPUS_PER_TASK \
    ${INPUT_DIR}

# convert the primary contig GFA to FASTA (course command)
awk '/^S/{print ">"$2;print $3}' \
    ${OUTPUT_DIR}/RRS10.bp.p_ctg.gfa > ${OUTPUT_DIR}/RRS10.bp.p_ctg.fa 

    