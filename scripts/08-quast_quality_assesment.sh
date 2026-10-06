#!/bin/bash

#SBATCH --job-name=quast_quality_assesment 
#SBATCH --cpus-per-task=16
#SBATCH --time=02:00:00
#SBATCH --mem=64G
#SBATCH --partition=pshort_el8
#SBATCH --output=/data/users/dpatel/assembly_annotation_course/logs/output/quast_%j.o
#SBATCH --error=/data/users/dpatel/assembly_annotation_course/logs/error/quast_%j.e

# setting paths, to access container, the assemblies, the reference and where to get the output
CONTAINER="/containers/apptainer/quast_5.2.0.sif"
BASE_DIR="/data/users/dpatel/assembly_annotation_course/output"
OUTPUT_DIR="/data/users/dpatel/assembly_annotation_course/output/quast"

# reference genome and annotation 
REF_GENOME="/data/courses/assembly-annotation-course/references/Arabidopsis_thaliana.TAIR10.dna.toplevel.fa"
REF_FEATURES="/data/courses/assembly-annotation-course/references/Arabidopsis_thaliana.TAIR10.57.gff3"

# the three genome assemblies (same order as the labels)
FLYE="${BASE_DIR}/flye_assembly/assembly.fasta"
HIFIASM="${BASE_DIR}/hifiasm_assembly/RRS10.bp.p_ctg.fa"
LJA="${BASE_DIR}/LJA_assembly/assembly.fasta"
LABELS="flye,hifiasm,lja"


# run QUAST without reference (genome size estimated for Arabidopsis thaliana, ~135 Mb)
# apptainer exec --bind /data/ ${CONTAINER} quast.py \
#     -o ${OUTPUT_DIR}/quast_no_ref \
#     --labels ${LABELS} \
#     --eukaryote \
#     --large \
#     --est-ref-size 135000000 \
#     --threads $SLURM_CPUS_PER_TASK \
#     ${FLYE} ${HIFIASM} ${LJA}

# run QUAST with reference and annotation
apptainer exec --bind /data/ ${CONTAINER} quast.py \
    -o ${OUTPUT_DIR}/quast_with_ref \
    --labels ${LABELS} \
    --eukaryote \
    --large \
    -r ${REF_GENOME} \
    --features gene:${REF_FEATURES} \
    --threads $SLURM_CPUS_PER_TASK \
    ${FLYE} ${HIFIASM} ${LJA}

# --eukaryote  tells quast the genome is eukaryotic
# --large is when genomes is over 100 Mb (arabidopsis ~ 135Mb)
# --est-ref-size gives the expected genome size in the no-reference run, so QUAST can calculate NG50
# --labels sets the names shown in the report instead of the long file paths.
# -r is the reference genome, which enables misassembly detection and genome fraction (%) coverage.
# --features gene: is the annotation, which lets QUAST count how many reference genes are fully or partly covered
