#!/bin/bash

#SBATCH --job-name=blastp_hit_analysis
#SBATCH --partition=pibu_el8
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=00:30:00
#SBATCH --output=/data/users/dpatel/assembly_annotation_course/logs/output/blastp_hit_analysis_%j.o
#SBATCH --error=/data/users/dpatel/assembly_annotation_course/logs/error/blastp_hit_analysis_%j.e

#
# Script 26: manual analysis of the BLASTP results (script 25)
#
# maker_functional_gff failed on our GFF; since there is some issue in the gff file
# so the UniProt functions are linked to the proteins directly from the
# BLAST best-hit tables instead. All input files are only READ.
#
# Every part reports results per PROTEIN (all isoforms) and per GENE
# (gene = protein ID without the -RA/-RB/... isoform suffix).
#
#   Part 1 - proportion of proteins / genes with a UniProt / TAIR10 hit
#   Part 2 - UniProt function of each best hit; how many are "uncharacterized"
#   Part 3 - length and AED of proteins / genes with vs. without a UniProt hit
#   Part 4 - is FLC (AT5G10140) in the annotation? Its genes, Pfam domains and GO terms
#
# Input:  filtered proteins + GFF3 (final_gene_annotation/), BLAST tables (comparisons/)
# Output: output/comparisons/blastp_analysis/ (tables + blastp_summary.txt)
#

# Stop on failed commands, unset variables, or failures within pipelines.
set -euo pipefail

# Paths

# Course software and project folder
COURSEDIR=/data/courses/genome_annotation_resources/2026
WORKDIR=/data/users/dpatel/assembly_annotation_course

# Analysis container (contains seqkit)
ANALYSIS_SIF="$COURSEDIR/containers/Annotation_analysis_R4.4.sif"

# Final annotation files (inputs, read only)
INP_DIR="$WORKDIR/output/MAKER_merged/final_gene_annotation"
PROTEINS="$INP_DIR/assembly.all.maker.proteins.fasta.renamed.filtered.fasta"
GENES="$INP_DIR/filtered.genes.renamed.gff3"

# BLAST results from script 25 (inputs, read only)
CMP_DIR="$WORKDIR/output/comparisons"
UNI_BEST="$CMP_DIR/blastp_uniprot.besthits.tsv"
TAIR_BEST="$CMP_DIR/blastp_TAIR10.besthits.tsv"
TAIR_ALL="$CMP_DIR/blastp_TAIR10.tsv"

# UniProt database (its FASTA headers contain the protein descriptions)
UNIPROT="$COURSEDIR/data/uniprot_viridiplantae_reviewed.fa"

# Output directory for this analysis
OUT_DIR="$CMP_DIR/blastp_analysis"
SUMMARY="$OUT_DIR/blastp_summary.txt"

# Prevent inherited container settings from changing the course environment.
unset SINGULARITY_BIND APPTAINER_BIND SINGULARITY_TMPDIR

mkdir -p "$OUT_DIR"
cd "$OUT_DIR"

# Everything printed from here on goes both to the log and to blastp_summary.txt
exec > >(tee "$SUMMARY")

# percent = 100 * part / total, with one decimal
pct () { awk -v a="$1" -v b="$2" 'BEGIN { printf "%.1f", (b > 0 ? 100 * a / b : 0) }'; }

# gene ID = protein ID without the isoform suffix (RRS0000001-RA -> RRS0000001)
to_gene () { sed 's/-R[A-Z]*$//'; }


# Part 1: proportion of proteins / genes with a significant hit (evalue < 1e-5)
total=$(grep -c '>' "$PROTEINS")
uni_hits=$(cut -f1 "$UNI_BEST" | sort -u | wc -l)
tair_hits=$(cut -f1 "$TAIR_BEST" | sort -u | wc -l)

# genes: from the GFF; a gene has a hit if at least one of its isoforms has a hit
total_genes=$(awk -F'\t' '$3 == "gene"' "$GENES" | wc -l)
uni_genes=$(cut -f1 "$UNI_BEST" | to_gene | sort -u | wc -l)
tair_genes=$(cut -f1 "$TAIR_BEST" | to_gene | sort -u | wc -l)

echo "== Part 1: proteins and genes with a BLASTP hit (evalue < 1e-5) =="
echo "-- per protein (all isoforms) --"
echo "Filtered proteins:                 $total"
echo "With a UniProt hit:                $uni_hits ($(pct "$uni_hits" "$total") %)"
echo "Without a UniProt hit:             $((total - uni_hits)) ($(pct $((total - uni_hits)) "$total") %)"
echo "With a TAIR10 hit:                 $tair_hits ($(pct "$tair_hits" "$total") %)"
echo "-- per gene (hit = at least one isoform has a hit) --"
echo "Genes in filtered annotation:      $total_genes"
echo "With a UniProt hit:                $uni_genes ($(pct "$uni_genes" "$total_genes") %)"
echo "Without a UniProt hit:             $((total_genes - uni_genes)) ($(pct $((total_genes - uni_genes)) "$total_genes") %)"
echo "With a TAIR10 hit:                 $tair_genes ($(pct "$tair_genes" "$total_genes") %)"
echo


# Part 2: UniProt function of each best hit
# UniProt headers look like: >sp|Q9XXX|NAME_ARATH Description OS=... OX=... GN=...
# BLAST reports the hit either as the full ID (sp|Q9XXX|NAME_ARATH) or only the
# accession (Q9XXX), so Table 1 stores the description under both keys.
# Table 1: UniProt ID <tab> description (text before " OS=")
grep '^>' "$UNIPROT" | sed 's/^>//' | \
    awk '{ id = $1; $1 = ""; sub(/^ /, ""); sub(/ OS=.*/, ""); desc = $0
           print id "\t" desc
           n = split(id, p, "|"); if (n >= 2) print p[2] "\t" desc }' \
    > uniprot_descriptions.tsv

# Table 2: our protein <tab> best UniProt hit <tab> %identity <tab> evalue <tab> description
awk -F'\t' 'NR == FNR { d[$1] = $2; next }
            { desc = ($2 in d) ? d[$2] : "NA"; print $1 "\t" $2 "\t" $3 "\t" $11 "\t" desc }' \
    uniprot_descriptions.tsv "$UNI_BEST" > uniprot_besthits_with_function.tsv

# per protein
with_desc=$(awk -F'\t' '$5 != "NA"' uniprot_besthits_with_function.tsv | wc -l)
unchar=$(awk -F'\t' 'tolower($5) ~ /uncharacterized|unknown protein|hypothetical/' \
         uniprot_besthits_with_function.tsv | wc -l)
described=$((with_desc - unchar))

# per gene: "described" if at least one isoform has a described function;
# "uncharacterized" if its isoforms only hit uncharacterized proteins
read -r genes_described genes_unchar < <(awk -F'\t' '
    { g = $1; sub(/-R[A-Z]*$/, "", g); d = tolower($5)
      if ($5 == "NA") next
      if (d ~ /uncharacterized|unknown protein|hypothetical/) unc[g] = 1; else fun[g] = 1 }
    END { nf = 0; nu = 0
          for (g in fun) nf++
          for (g in unc) if (!(g in fun)) nu++
          print nf, nu }' uniprot_besthits_with_function.tsv)

echo "== Part 2: function of the best UniProt hits =="
echo "-- per protein --"
echo "Best hits with a UniProt description:             $with_desc of $uni_hits"
echo "Best hit is uncharacterized/unknown/hypothetical: $unchar ($(pct "$unchar" "$uni_hits") % of hits)"
echo "Best hit has a described function:                $described ($(pct "$described" "$total") % of all proteins)"
echo "-- per gene --"
echo "Genes with a described UniProt function:          $genes_described ($(pct "$genes_described" "$total_genes") % of all genes)"
echo "Genes whose hits are only uncharacterized:        $genes_unchar ($(pct "$genes_unchar" "$total_genes") % of all genes)"
echo "Genes without any UniProt hit:                    $((total_genes - uni_genes)) ($(pct $((total_genes - uni_genes)) "$total_genes") % of all genes)"
echo




# Part 3: length and AED bias of proteins / genes without a UniProt hit
# seqkit fx2tab -n -l : full header <tab> length (amino acids)
# The MAKER header contains the AED, e.g. ">RRS0026908-RA protein AED:0.46 ..."
apptainer exec --cleanenv --bind "$COURSEDIR" --bind "$WORKDIR" --pwd "$OUT_DIR" "$ANALYSIS_SIF" \
    seqkit fx2tab -n -l "$PROTEINS" > protein_lengths_raw.tsv

# Table 3: protein <tab> length <tab> AED <tab> with_hit / no_hit
awk -F'\t' 'NR == FNR { hit[$1] = 1; next }
    { split($1, h, " "); id = h[1]; len = $2
      aed = "NA"; if (match($1, /AED:[0-9.]+/)) aed = substr($1, RSTART + 4, RLENGTH - 4)
      print id "\t" len "\t" aed "\t" ((id in hit) ? "with_hit" : "no_hit") }' \
    "$UNI_BEST" protein_lengths_raw.tsv > protein_length_AED_uniprot.tsv

# Table 4 (per gene): gene <tab> length of longest isoform <tab> its AED <tab> with_hit / no_hit
# (a gene counts as with_hit if any of its isoforms has a UniProt hit)
awk -F'\t' '{ g = $1; sub(/-R[A-Z]*$/, "", g)
              if (!(g in len) || $2 > len[g]) { len[g] = $2; aed[g] = $3 }
              if ($4 == "with_hit") hit[g] = 1 }
    END { for (g in len) print g "\t" len[g] "\t" aed[g] "\t" ((g in hit) ? "with_hit" : "no_hit") }' \
    protein_length_AED_uniprot.tsv | sort > gene_length_AED_uniprot.tsv

# Print n, mean / median length, % short (<100 aa) and mean AED for both groups of a table
group_stats () {
    local table="$1"
    printf "%-10s %8s %12s %14s %18s %10s\n" "group" "n" "mean_len_aa" "median_len_aa" "short_<100aa_(%)" "mean_AED"
    for g in with_hit no_hit; do
        # mean length, % short proteins and mean AED
        stats=$(awk -F'\t' -v g="$g" '$4 == g { n++; s += $2; if ($2 < 100) sh++; if ($3 != "NA") { a += $3; na++ } }
            END { if (n == 0) { print "0 0 0 0"; exit }
                  printf "%d %.0f %.1f %.2f", n, s / n, 100 * sh / n, (na ? a / na : 0) }' "$table")
        # median length
        median=$(awk -F'\t' -v g="$g" '$4 == g { print $2 }' "$table" | sort -n | \
            awk '{ v[NR] = $1 } END { if (NR == 0) print 0; else if (NR % 2) print v[(NR + 1) / 2]; else print (v[NR / 2] + v[NR / 2 + 1]) / 2 }')
        read -r n mean shortp aed <<< "$stats"
        printf "%-10s %8s %12s %14s %18s %10s\n" "$g" "$n" "$mean" "$median" "$shortp" "$aed"
    done
}

echo "== Part 3: proteins and genes with vs. without a UniProt hit =="
echo "-- per protein (all isoforms) --"
group_stats protein_length_AED_uniprot.tsv
echo "-- per gene (longest isoform; with_hit = any isoform has a hit) --"
group_stats gene_length_AED_uniprot.tsv
echo



# Part 4: FLC (AT5G10140)
# Our proteins whose BEST TAIR10 hit is FLC, and all proteins with any FLC hit
grep -i "AT5G10140" "$TAIR_BEST" > FLC_TAIR10_besthits.tsv || true
grep -i "AT5G10140" "$TAIR_ALL"  > FLC_TAIR10_allhits.tsv  || true

echo "== Part 4: FLC (AT5G10140) =="
echo "Proteins whose best TAIR10 hit is FLC: $(wc -l < FLC_TAIR10_besthits.tsv)"
echo "Genes whose best TAIR10 hit is FLC:    $(cut -f1 FLC_TAIR10_besthits.tsv | to_gene | sort -u | wc -l)"
echo "Proteins with any hit to FLC:          $(cut -f1 FLC_TAIR10_allhits.tsv | sort -u | wc -l)"
echo "Genes with any hit to FLC:             $(cut -f1 FLC_TAIR10_allhits.tsv | to_gene | sort -u | wc -l)"

# All proteins with any FLC hit: their strongest FLC hit (identity, evalue) and best TAIR10 hit overall
echo
echo "All proteins with an FLC hit (best FLC hit; best TAIR10 hit overall):"
printf "  %-16s %-12s %10s %12s   %s\n" "protein" "gene" "identity_%" "evalue" "best_TAIR10_hit"
sort -k1,1 -k12,12gr FLC_TAIR10_allhits.tsv | awk -F'\t' '!seen[$1]++' | \
    while IFS=$'\t' read -r q s pid rest; do
        ev=$(awk -F'\t' -v q="$q" -v s="$s" '$1 == q && $2 == s { print $11; exit }' FLC_TAIR10_allhits.tsv)
        best=$(awk -F'\t' -v q="$q" '$1 == q { print $2; exit }' "$TAIR_BEST")
        printf "  %-16s %-12s %10s %12s   %s\n" "$q" "$(echo "$q" | to_gene)" "$pid" "$ev" "${best:-none}"
    done

# For each protein with FLC as best hit: BLAST numbers, UniProt function,
# its gene line and mRNA line from the GFF (Pfam domains = Dbxref, GO terms = Ontology_term)
cut -f1 FLC_TAIR10_besthits.tsv | sort -u | while read -r q; do
    gene=$(echo "$q" | to_gene)
    echo
    echo "-- $q (gene $gene) --"
    awk -F'\t' -v q="$q" '$1 == q { print "TAIR10 best hit: " $2 "  identity: " $3 "%  evalue: " $11 }' FLC_TAIR10_besthits.tsv
    awk -F'\t' -v q="$q" '$1 == q { print "UniProt best hit: " $2 "  " $5 }' uniprot_besthits_with_function.tsv
    echo "GFF gene line:"
    awk -F'\t' -v g="$gene" '$3 == "gene" && $9 ~ ("ID=" g ";") { print "  " $1 ":" $4 "-" $5 " (" $7 "), gene length " $5 - $4 + 1 " bp" }' "$GENES"
    echo "  isoforms: $(awk -F'\t' -v g="$gene" '$3 == "mRNA" && $9 ~ ("Parent=" g ";") ' "$GENES" | wc -l),  exons (all isoforms): $(awk -F'\t' -v g="$gene" '$3 == "exon" && $9 ~ ("Parent=" g "-R") ' "$GENES" | wc -l)"
    echo "GFF mRNA line:"
    awk -F'\t' -v q="$q" '$3 == "mRNA" && $9 ~ ("ID=" q ";") { print "  " $1 ":" $4 "-" $5 " (" $7 ")"; print "  " $9 }' "$GENES"
done
echo