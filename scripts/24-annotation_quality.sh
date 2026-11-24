#!/bin/bash

#SBATCH --job-name=annotation_quality
#SBATCH --partition=pibu_el8
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=03:00:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --reservation=class-sbl-30004-2026-10-28
#SBATCH --output=/data/users/dpatel/assembly_annotation_course/logs/output/annotation_quality_%j.o
#SBATCH --error=/data/users/dpatel/assembly_annotation_course/logs/error/annotation_quality_%j.e

#
# Script 24: quality assessment of the final gene annotation
#
#   Part 1 - keep the longest protein and transcript per gene (input for BUSCO) (to avoid for duplication)
#   Part 2 - BUSCO on the longest proteins and transcripts (completeness)
#   Part 3 - AGAT statistics on the final GFF3 (gene structure numbers)
#
# Input  (in final_gene_annotation/): filtered protein/transcript FASTA files,
#                                     filtered.genes.renamed.gff3
# Output (in final_gene_annotation/annotation_quality/): *.renamed.longest.fasta,
#                                     busco_proteins/, busco_transcripts/, annotation.stat
# annotation stat had the AGAT results 
#

# Stop on failed commands, unset variables, or failures within pipelines.
set -euo pipefail

# Paths

# Course software and project folder
COURSEDIR=/data/courses/genome_annotation_resources/2026
WORKDIR=/data/users/dpatel/assembly_annotation_course

# Containers: seqkit (analysis container) and AGAT
ANALYSIS_SIF="$COURSEDIR/containers/Annotation_analysis_R4.4.sif"
AGAT_SIF="$COURSEDIR/containers/AGAT_v1.4.1.sif"

# Folder with the final annotation files (inputs)
INP_DIR="$WORKDIR/output/MAKER_merged/final_gene_annotation"

# output directory for quality-assessment results
OUT_DIR="$INP_DIR/annotation_quality"

# Base file names 
protein="assembly.all.maker.proteins.fasta"
transcript="assembly.all.maker.transcripts.fasta"

# Prevent inherited container settings from changing the course environment.
unset SINGULARITY_BIND APPTAINER_BIND SINGULARITY_TMPDIR

mkdir -p "$OUT_DIR"
cd "$OUT_DIR"



# Part 1: longest isoform per gene 
# Genes can have several isoforms (RRS0000001-RA, RRS0000001-RB, ...).
# BUSCO would count extra isoforms as duplicated genes, so we keep one
# record per gene: the longest one 
#
# Function arguments: $1 = input FASTA, $2 = output FASTA, $3 = file for kept IDs
longest_per_gene () {
    local in="$1" out="$2" ids="$3"

    # seqkit fx2tab -n -i -l : print "ID <tab> length" for every sequence
    # awk: gene name = ID without "-RA"/"-RB"/...; remember the longest ID per gene
    #      (">" not ">=" so that on a tie the first record is kept)
    apptainer exec --cleanenv --bind "$COURSEDIR" --bind "$WORKDIR" --pwd "$OUT_DIR" "$ANALYSIS_SIF" \
        seqkit fx2tab -n -i -l "$in" \
    | awk -F'\t' '{
            id = $1; len = $2
            gene = id; sub(/-R[A-Z]+$/, "", gene)
            if (!(gene in best) || len > best[gene]) { best[gene] = len; pick[gene] = id }
        }
        END { for (g in pick) print pick[g] }' > "$ids"

    # Extract only the selected IDs from the FASTA file
    apptainer exec --cleanenv --bind "$COURSEDIR" --bind "$WORKDIR" --pwd "$OUT_DIR" "$ANALYSIS_SIF" \
        seqkit grep -f "$ids" "$in" -o "$out"

    echo "$in: $(grep -c '>' "$in") sequences -> $out: $(grep -c '>' "$out") (one per gene)"
}

longest_per_gene "$INP_DIR/${protein}.renamed.filtered.fasta" \
                 "${protein}.renamed.longest.fasta" \
                 longest_protein_ids.txt

longest_per_gene "$INP_DIR/${transcript}.renamed.filtered.fasta" \
                 "${transcript}.renamed.longest.fasta" \
                 longest_transcript_ids.txt

# Check: should equal the counts of the longest files above
echo "Genes in filtered.genes.renamed.gff3: $(awk -F'\t' '$3 == "gene"' "$INP_DIR/filtered.genes.renamed.gff3" | wc -l)"




# Part 2: BUSCO 
# BUSCO searches for conserved single-copy genes of the Brassicales (brassicales_odb10)
# Module scripts can use unset variables, so "set -u" is paused around it.
set +u
module load BUSCO/5.4.2-foss-2021a # BUSCO loaded as the module 
set -u

# ignore Python packages from your home folder
export PYTHONNOUSERSITE=1   

busco -i "${protein}.renamed.longest.fasta" -l brassicales_odb10 -o busco_proteins -m proteins -c "$SLURM_CPUS_PER_TASK"
busco -i "${transcript}.renamed.longest.fasta" -l brassicales_odb10 -o busco_transcripts -m transcriptome -c "$SLURM_CPUS_PER_TASK"
# -m mode

# Print the one-line BUSCO summaries to the log
echo "BUSCO proteins:";    grep "C:" busco_proteins/short_summary*.txt    || true
echo "BUSCO transcripts:"; grep "C:" busco_transcripts/short_summary*.txt || true




# Part 3: AGAT statistics 
apptainer exec --cleanenv --bind "$COURSEDIR" --bind "$WORKDIR" --pwd "$OUT_DIR" "$AGAT_SIF" \
    agat_sp_statistics.pl --gff "$INP_DIR/filtered.genes.renamed.gff3" --output annotation.stat

echo "Done. Results in $OUT_DIR: busco_proteins/, busco_transcripts/, annotation.stat"