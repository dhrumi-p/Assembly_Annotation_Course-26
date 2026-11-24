# Run GENESPACE on the five genomes
#
# Called by script 29 (inside the GENESPACE container) with one argument:
#   path : output/comparisons/GENESPACE contains bed/ and peptide/ from script 27.
#
# Output (in the GENESPACE directory): GENESPACE results (orthogroups,
#   synteny, dotplots, riparian plots, pan-gene tables) + pangenome_matrix.rds

library(GENESPACE)

# Get the GENESPACE working directory from the command line (passed by script 29)
args <- commandArgs(trailingOnly = TRUE)
wd <- args[1]

# Initialise: checks the bed/ and peptide/ inputs and sets the parameters
# path2mcscanx: MCScanX (synteny tool) inside the container
# nCores = 20: must match --cpus-per-task in script 29
gpar <- init_genespace(wd = wd, path2mcscanx = "/usr/local/bin", nCores = 20)

# Run the full pipeline: DIAMOND hits -> OrthoFinder orthogroups ->
# syntenic blocks -> plots and pan-gene tables
out <- run_genespace(gpar)

# Build the pan-gene table with TAIR10 as the reference genome
# transform = TRUE      : one row per gene (long format)
# showArrayMem = TRUE   : include tandem array members
# showNSOrtho = TRUE    : include non-syntenic orthologues
# maxMem2Show = Inf     : show all members of each entry
pangenome <- query_pangenes(out, bed = NULL, refGenome = "TAIR10", transform = TRUE,
                            showArrayMem = TRUE, showNSOrtho = TRUE, maxMem2Show = Inf)

# Save the pan-gene table as an R object for later analysis
saveRDS(pangenome, file = file.path(wd, "pangenome_matrix.rds"))