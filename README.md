# De novo Genome Assembly and Annotation – *Arabidopsis thaliana* RRS10

Course project for Genome and Transcriptome Assembly and Genome Annotation, 2026.

Genome assembly of the *Arabidopsis thaliana* accession **RRS10** from PacBio HiFi reads, transcriptome assembly from Illumina RNA-seq data, evaluation and comparison of the assemblies, followed by transposable element (TE) annotation, gene annotation and comparative genomics with other *A. thaliana* accessions.


## Workflow

Scripts are in the `scripts` folder, numbered in order of execution.

### Part A – Genome and transcriptome assembly

#### 1. Read QC and k-mer analysis (01–02)
- **FastQC** – checks read quality (base quality, length, GC content, adapters)
- **Jellyfish** – counts k-mers in the reads and builds a k-mer histogram
- **GenomeScope 2.0** – estimates genome size, heterozygosity and coverage from the k-mer histogram (web server)

#### 2. Genome assembly (03–05)
- **Flye** – long-read assembler based on a repeat graph
- **hifiasm** – HiFi assembler based on a string graph; haplotype-aware (primary contigs used)
- **LJA** – HiFi assembler based on de Bruijn graphs with very large k-mers

#### 3. Transcriptome assembly (06)
- **Trinity** – de novo assembles RNA-seq reads into transcripts and isoforms

#### 4. Assembly evaluation (07–09)
- **BUSCO** – measures gene completeness using conserved single-copy genes (brassicales_odb10)
- **QUAST** – reports contiguity statistics (N50, number of contigs, length), plus misassemblies and genome fraction against the reference
- **Merqury** – compares assembly and read k-mers to estimate base accuracy (QV) and completeness, without a reference

#### 5. Genome comparison (10)
- **nucmer / mummerplot** – align the assemblies to the reference and to each other, and draw dot plots

### Part B – Genome annotation (Flye assembly)

#### 6. TE annotation (11–13)
- **EDTA** – de novo TE annotation; builds a TE library and annotates TEs in the genome
- **TEsorter** – classifies intact LTR retrotransposons into Copia/Gypsy clades
- **LTR plots** – LTR identity of intact elements per clade (identity 1.00 = recent insertion)

#### 7. TE distribution and classification (14–15)
- **circlize** – circos plot of TE superfamily density along the largest contigs
- **TEsorter** – clade classification of all Copia and Gypsy sequences in the TE library

#### 8. TE dynamics (16–18)
- **parseRM** – bins RepeatMasker divergence of TE copies (1% bins)
- **TE landscape** – amount of TE sequence (Mbp) per divergence bin and superfamily
- **TE age** – converts divergence to insertion time (T = K / 2r, r = 8.22 × 10⁻⁹)

#### 9. Gene annotation (19–21)
- **MAKER** – gene prediction combining AUGUSTUS with transcript (Trinity) and protein (TAIR10, UniProt) evidence; repeats masked with the EDTA TE library
- **Merge and rename** – combine MAKER outputs into one GFF/FASTA and give genes short IDs

#### 10. Functional annotation and quality (22–24)
- **InterProScan** – finds protein domains (Pfam) and GO terms
- **AED / domain filter** – keeps gene models supported by evidence (AED) or a Pfam domain
- **BUSCO + AGAT** – completeness of the predicted proteins and gene model statistics

#### 11. Homology search (25–26)
- **BLASTP** – searches the proteins against UniProt and TAIR10
- **Hit analysis** – counts genes with and without homologs and adds protein descriptions

#### 12. Comparative genomics (27–31)
- **GENESPACE** – orthologs (OrthoFinder) plus gene order (synteny) between RRS10, TAIR10, Kar_1, Are_6 and Est_0
- **Pangenome** – classifies pan-genes as core, accessory or accession-specific; finds copy-variable genes
- **Riparian plots** – synteny plots, with reversed contigs flipped for display

## Results and Summary

**Assembly**
- **hifiasm** produced the most contiguous assembly (N50 17.2 Mb, largest contig about one chromosome), but with about 450 small redundant contigs (duplication ratio 1.26) and 77 missing BUSCO genes.
- **Flye** and **LJA** are less contiguous, but cleaner (duplication close to 1.0) and more complete (99.8% BUSCO).
- QUAST, BUSCO and Merqury agree: there is no single best assembly, but a trade-off between contiguity and completeness/redundancy.
- Misassemblies and the ~26 Mb of unaligned sequence relative to Col-0 should be interpreted with caution, as RRS10 is a different accession and the reference lacks most centromeric repeats.

**TE annotation**
- TEs cover **18.6 Mb (13.5%)** of the genome; **Gypsy** is the most abundant superfamily (4.9%), mostly in pericentromeric regions.
- Intact **Copia** elements peak at 1.00 LTR identity (very recent activity), while **Gypsy** shows a broader, older distribution.
- The TE landscape shows a main **Gypsy burst at ~7–11% divergence (≈ 4–7 million years ago)**.

**Gene annotation**
- **27,538 gene models** .
- **97.8%** of gene models have AED ≤ 0.5 .
- **96.7%** BUSCO complete for the predicted proteins.

**Comparative genomics**
- **19 contigs** cover all 5 TAIR10 chromosomes with conserved gene order.
- Twisted braids came from **12 contigs assembled in reverse orientation**; after flipping them, all braids are straight (no inversions).
- Pangenome of 5 genomes: **70.7% core**, 22.2% accessory, 7.2% accession-specific; 494 core genes vary in copy number (tandem arrays).

## Repository structure

```
├── .gitignore
├── README.md
└── scripts/      # scripts 01 to 31 (.sh = SLURM job, .R = plotting/analysis)
```

Raw data and output files are not included in this repository.
