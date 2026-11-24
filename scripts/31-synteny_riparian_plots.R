# Script 31: riparian (synteny) plots with GENESPACE
#
# Called by 31-run_riparian_plots.sh inside the GENESPACE container.
# Output: output/comparisons/GENESPACE/processed_riparian/*.pdf
#
# we run this script twice so 

# Run 1: only Plot 1 is active (Plots 2 and 3 are commented out).
#        Look at my_accession_vs_TAIR10.pdf and note scaffolds with twisted braids.
# Run 2: put those scaffold names in "flips", comment out Plot 1,
#        un-comment Plots 2 and 3, and submit again.

library(GENESPACE)

# GENESPACE working directory and our accession
wd <- "/data/users/dpatel/assembly_annotation_course/output/comparisons/GENESPACE"
focal_genome <- "RRS_10"

# Load the GENESPACE parameters saved by the run in script 29 (creates gsParam)
load(file.path(wd, "results", "gsParams.rda"))
dir.create(file.path(wd, "processed_riparian"), showWarnings = FALSE)




# Plot 1: our accession vs TAIR10, scaffolds ordered by synteny   (Run 1)
plot_riparian(
  gsParam,
  genomeIDs = c("TAIR10", focal_genome),
  refGenome = "TAIR10",
  reorderBySynteny = TRUE,
  pdfFile = file.path(wd, "processed_riparian", "my_accession_vs_TAIR10.pdf")
)


# after getting the plot 1, the following contigs are there and in this order 
#The contig order in plot 1, from left to right:
#contig_72, contig_89, contig_93, contig_113, contig_90, contig_96, contig_98, contig_103, contig_141,
# contig_68, contig_65, contig_105, contig_118, contig_124, contig_146, contig_106, contig_119, contig_139, contig_147



# Scaffolds to flip for display (assembled in reverse orientation -> twisted braid).
# we forst need to get the plot 1, from there we can see why synteny region are not aligning and we think can be because 
# that the scafolds was inverted so then for those two only we can run the invert thing in plot2 

# Run 1: leave as NULL. Run 2: add the exact scaffold names, e.g.
# change the name of the contig below based on the plot1 and then re run , and then comment out plot 1 then 
flips <- data.frame(genome = focal_genome,
                    chr = c("contig_89", "contig_93", "contig_113", "contig_90", "contig_96",
                            "contig_103", "contig_141", "contig_105", "contig_124",
                            "contig_106", "contig_139", "contig_147"))

# Plot 2: same, with improved order and the flipped scaffolds   (Run 2)
plot_riparian(
   gsParam,
   genomeIDs = c("TAIR10", focal_genome),
   refGenome = "TAIR10",
   reorderBySynteny = TRUE,
   syntenyWeight = 1,
   invertTheseChrs = flips,
   pdfFile = file.path(wd, "processed_riparian", "my_accession_vs_TAIR10_oriented.pdf")
)


# Plot 3: all five genomes   (Run 2)
 plot_riparian(
   gsParam,
   refGenome = "TAIR10",
   reorderBySynteny = TRUE,
   syntenyWeight = 1,
   invertTheseChrs = flips,
   scalePlotWidth = 1.5,
   pdfFile = file.path(wd, "processed_riparian", "all_genomes_TAIR10.pdf")
 )