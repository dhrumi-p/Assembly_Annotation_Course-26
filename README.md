# De novo Genome and Transcriptome Assembly – *Arabidopsis thaliana* RRS10

Course project for Genome and Transcriptome Assembly, 2026.

Genome assembly of the *Arabidopsis thaliana* accession **RRS10** from PacBio HiFi reads, transcriptome assembly from Illumina RNA-seq data, and evaluation and comparison of the assemblies.

## Data

- **RRS10 whole-genome reads** (PacBio HiFi) – used for genome assembly, k-mer analysis and Merqury
- **RNAseq_Sha** (Illumina paired-end RNA-seq) – used for transcriptome assembly
- ***A. thaliana* reference genome** (Col-0, TAIR10) – used for QUAST and genome comparison

Raw data and output files are not included in this repository.

## Workflow

Scripts are in the `scripts` folder, numbered in order of execution.

### 1. Read QC and k-mer analysis (01–02)
- **FastQC** – checks read quality (base quality, length, GC content, adapters)
- **Jellyfish** – counts k-mers in the reads and builds a k-mer histogram
- **GenomeScope 2.0** – estimates genome size, heterozygosity and coverage from the k-mer histogram (web server)

### 2. Genome assembly (03–05)
- **Flye** – long-read assembler based on a repeat graph
- **hifiasm** – HiFi assembler based on a string graph; haplotype-aware (primary contigs used)
- **LJA** – HiFi assembler based on de Bruijn graphs with very large k-mers

### 3. Transcriptome assembly (06)
- **Trinity** – de novo assembles RNA-seq reads into transcripts and isoforms

### 4. Assembly evaluation (07–09)
- **BUSCO** – measures gene completeness using conserved single-copy genes (brassicales_odb10)
- **QUAST** – reports contiguity statistics (N50, number of contigs, length), plus misassemblies and genome fraction against the reference
- **Merqury** – compares assembly and read k-mers to estimate base accuracy (QV) and completeness, without a reference

### 5. Genome comparison (10)
- **nucmer / mummerplot** – align the assemblies to the reference and to each other, and draw dot plots

## Results and Summary

- **hifiasm** produced the most contiguous assembly (N50 17.2 Mb, largest contig about one chromosome), but with about 450 small redundant contigs (duplication ratio 1.26) and 77 missing BUSCO genes.
- **Flye** and **LJA** are less contiguous, but cleaner (duplication close to 1.0) and more complete (99.8% BUSCO).
- QUAST, BUSCO and Merqury agree: there is no single best assembly, but a trade-off between contiguity and completeness/redundancy.
- Misassemblies and the ~26 Mb of unaligned sequence relative to Col-0 should be interpreted with caution, as RRS10 is a different accession and the reference lacks most centromeric repeats.

## Repository structure

```
.
├── .gitignore
├── README.md
└── scripts/      # scripts 01 to 10
```
