#!/bin/bash

#SBATCH --job-name=merqury_assemblies
#SBATCH --cpus-per-task=16
#SBATCH --time=02:00:00
#SBATCH --mem=64G
#SBATCH --partition=pshort_el8
#SBATCH --output=/data/users/dpatel/assembly_annotation_course/logs/output/merqury_%j.o
#SBATCH --error=/data/users/dpatel/assembly_annotation_course/logs/error/merqury_%j.e

# setting paths, to access container, the reads, the assemblies and where to get the output
CONTAINER="/containers/apptainer/merqury_1.3.sif"
READS="/data/users/dpatel/assembly_annotation_course/raw_data/RRS10/ERR11437326.fastq.gz"
BASE_DIR="/data/users/dpatel/assembly_annotation_course/output"
OUTPUT_DIR="/data/users/dpatel/assembly_annotation_course/output/merqury"

# merqury needs this path variable to find its own scripts inside the container
export MERQURY="/usr/local/share/merqury"

# k-mer size (selecting the most widely used value)
K=31

# the three genome assemblies (same order in both lists)
NAMES=("flye" "hifiasm" "lja")
ASSEMBLIES=("${BASE_DIR}/flye_assembly/assembly.fasta" \
            "${BASE_DIR}/hifiasm_assembly/RRS10.bp.p_ctg.fa" \
            "${BASE_DIR}/LJA_assembly/assembly.fasta")


# step 1: build the meryl k-mer database from the HiFi reads (skipped if it already exists)
if [ ! -d ${OUTPUT_DIR}/RRS10.meryl ]; then
    apptainer exec --bind /data/ ${CONTAINER} meryl \
        k=${K} \
        count \
        threads=$SLURM_CPUS_PER_TASK \
        ${READS} \
        output ${OUTPUT_DIR}/RRS10.meryl
fi

# step 2: run merqury on each assembly, each in its own folder
# (merqury writes its results into the current folder, so we cd into each one)
for i in 0 1 2; do
    NAME=${NAMES[$i]}
    ASSEMBLY=${ASSEMBLIES[$i]}

    mkdir -p ${OUTPUT_DIR}/${NAME}
    cd ${OUTPUT_DIR}/${NAME}

    apptainer exec --bind /data/ ${CONTAINER} ${MERQURY}/merqury.sh \
        ${OUTPUT_DIR}/RRS10.meryl \
        ${ASSEMBLY} \
        ${NAME}
done

# k=31 is the k-mer size used to count k-mers
# meryl count builds a k-mer database (all k-mers + how often they appear) from the reads
# merqury.sh compares the read k-mers with the assembly k-mers to estimate quality (QV) and completeness 