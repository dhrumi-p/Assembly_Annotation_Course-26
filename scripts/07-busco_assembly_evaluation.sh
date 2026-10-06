#!/bin/bash

#SBATCH --job-name=busco_assemblies
#SBATCH --cpus-per-task=16
#SBATCH --time=02:00:00
#SBATCH --mem=64G
#SBATCH --partition=pshort_el8
#SBATCH --array=0-3
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null

# array=0-3 (this tells the slrum that 4 copies of the same script, with different details)
 
# setting paths, to access container and where to get the output
CONTAINER="/containers/apptainer/busco_5.7.1.sif"
OUTPUT_DIR="/data/users/dpatel/assembly_annotation_course/output/busco"
BASE_DIR="/data/users/dpatel/assembly_annotation_course/output"


# the four assemblies (same order in all three lists)
 INPUTS=("${BASE_DIR}/flye_assembly/assembly.fasta" \
         "${BASE_DIR}/hifiasm_assembly/RRS10.bp.p_ctg.fa" \
         "${BASE_DIR}/LJA_assembly/assembly.fasta" \
         "${BASE_DIR}/trinity_assembly/trinity_assembly.Trinity.fasta")
 


# defining the parametr values for the busco
NAMES=("flye" "hifiasm" "lja" "trinity")
LINEAGE="brassicales_odb10"
MODES=("genome" "genome" "genome" "transcriptome")

# pick the assembly for this array task (0 = flye, 1 = hifiasm, 2 = lja, 3 = trinity)
 NAME=${NAMES[$SLURM_ARRAY_TASK_ID]}
 INPUT=${INPUTS[$SLURM_ARRAY_TASK_ID]}
 MODE=${MODES[$SLURM_ARRAY_TASK_ID]}

# send the log files to names based on the assembly
exec > /data/users/dpatel/assembly_annotation_course/logs/output/busco_${NAME}.o # all normal output form here on to this location
exec 2> /data/users/dpatel/assembly_annotation_course/logs/error/busco_${NAME}.e # all error messages from here on to this file 


# run BUSCO
apptainer exec --bind /data/ ${CONTAINER} busco \
    -i ${INPUT} \
    -o busco_${NAME} \
    --out_path ${OUTPUT_DIR} \
    -m ${MODE} \
    -l ${LINEAGE} \
    -c $SLURM_CPUS_PER_TASK

    