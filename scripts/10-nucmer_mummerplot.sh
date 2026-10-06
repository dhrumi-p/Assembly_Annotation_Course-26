#!/bin/bash

#SBATCH --job-name=nucmer_mummerplot
#SBATCH --cpus-per-task=16
#SBATCH --time=02:00:00
#SBATCH --mem=64G
#SBATCH --partition=pshort_el8
#SBATCH --array=0-5
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null


# array=0-5 (this tells slurm to run 6 copies of the same script, one per comparison)

# comparisions
# each assembly against the reference: Flye vs ref, Hifiasm vs ref, LJA vs ref
# the assemblies against each other: Flye vs Hifiasm, Flye vs LJA, Hifiasm vs LJA

# setting paths, to access container, the assemblies, the reference and where to get the output
CONTAINER="/containers/apptainer/mummer4_gnuplot.sif"
BASE_DIR="/data/users/dpatel/assembly_annotation_course/output"
OUTPUT_DIR="/data/users/dpatel/assembly_annotation_course/output/nucmer_mummer"

# reference genome and the three genome assemblies
REF_GENOME="/data/courses/assembly-annotation-course/references/Arabidopsis_thaliana.TAIR10.dna.toplevel.fa"
FLYE="${BASE_DIR}/flye_assembly/assembly.fasta"
HIFIASM="${BASE_DIR}/hifiasm_assembly/RRS10.bp.p_ctg.fa"
LJA="${BASE_DIR}/LJA_assembly/assembly.fasta"

# the six comparisons (same order in all three lists)
# 0-2 = each assembly vs reference, 3-5 = assemblies vs each other
NAMES=("flye_vs_ref" "hifiasm_vs_ref" "lja_vs_ref" \
       "flye_vs_hifiasm" "flye_vs_lja" "hifiasm_vs_lja")
REFS=("${REF_GENOME}" "${REF_GENOME}" "${REF_GENOME}" \
      "${FLYE}" "${FLYE}" "${HIFIASM}")
QUERIES=("${FLYE}" "${HIFIASM}" "${LJA}" \
         "${HIFIASM}" "${LJA}" "${LJA}")

# pick the comparison for this array task
NAME=${NAMES[$SLURM_ARRAY_TASK_ID]}
REF=${REFS[$SLURM_ARRAY_TASK_ID]}
QUERY=${QUERIES[$SLURM_ARRAY_TASK_ID]}

# send the log files to names based on the comparison
exec > /data/users/dpatel/assembly_annotation_course/logs/output/nucmer_${NAME}.o # all normal output from here on to this location
exec 2> /data/users/dpatel/assembly_annotation_course/logs/error/nucmer_${NAME}.e # all error messages from here on to this file


# step 1: align the query genome to the reference genome with nucmer
apptainer exec --bind /data/ ${CONTAINER} nucmer \
    --prefix=${NAME} \
    --breaklen=1000 \
    --mincluster=1000 \
    --threads=$SLURM_CPUS_PER_TASK \
    ${REF} \
    ${QUERY}

# step 2: draw the dotplot from the .delta file with mummerplot
apptainer exec --bind /data/ ${CONTAINER} mummerplot \
    -R ${REF} \
    -Q ${QUERY} \
    --filter \
    -t png \
    --large \
    --layout \
    --fat \
    -p ${NAME} \
    ${NAME}.delta

# nucmer:
# --prefix sets the name of the output files (NAME.delta)
# --breaklen 1000 is how far an alignment can be extended through poorly matching regions before it stops

# --mincluster 1000 is the minimum length of a cluster of matches to be kept as an alignment (removes short, noisy hits)
# If a cluster's total match length is under 1,000 bp, nucmer discards it, and it won't appear in the .delta file or the dotplot

# --threads is the number of CPUs used

# mummerplot:
# -R and -Q give the reference and query FASTA, so the plot shows all sequences in the right order
# --filter keeps only the best 1-to-1 alignments (removes repeats and noise)
# -t png saves the plot as a png image
# --large makes a big, high-resolution plot
# --layout orders and orients the contigs to best match the reference (makes a clean diagonal)
# --fat draws thicker lines, so alignments are easier to see
# -p sets the name of the output files (NAME.png)




#Plot	X-axis (reference)	Y-axis (query)
#flye_vs_ref	TAIR10	Flye
#hifiasm_vs_ref	TAIR10	Hifiasm
#lja_vs_ref	TAIR10	LJA
#flye_vs_hifiasm	Flye	Hifiasm
#flye_vs_lja	Flye	LJA
#hifiasm_vs_lja	Hifiasm	LJA