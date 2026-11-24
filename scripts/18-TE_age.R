library(reshape2)
library(tidyverse)
library(data.table)

# Input: binned divergence table from script 16 (parseRM, 1% bins)
data <- "/data/users/dpatel/assembly_annotation_course/output/parseRM_TE_divergence/assembly.fasta.mod.EDTA.RM.nonzero.out.landscape.Div.Rname.tab"

rep_table <- fread(data, header = FALSE, sep = "\t")

colnames(rep_table) <- c("Rname", "Rclass", "Rfam", 1:50)
rep_table <- rep_table %>% filter(Rfam != "unknown")
rep_table$fam <- paste(rep_table$Rclass, rep_table$Rfam, sep = "/")

print(table(rep_table$fam)) # print here to get data in the logs

rep_table.m <- melt(rep_table)

# Same superfamily order as in script 17
rep_table.m$fam <- factor(rep_table.m$fam, levels = c(
  "LTR/Copia", "LTR/Gypsy", "DNA/DTA", "DNA/DTC", "DNA/DTH", "DNA/DTM", "DNA/DTT", "DNA/Helitron",
  "MITE/DTA", "MITE/DTC", "MITE/DTH", "MITE/DTM"
))

rep_table.m$distance <- as.numeric(rep_table.m$variable) / 100 # as it is percent divergence

# Dating: T = K / 2r
# K = divergence (distance), r = 8.22e-9 substitutions per site per year
# (Brassicaceae synonymous substitution rate, Kagale et al. 2014)
r <- 8.22e-9
rep_table.m$age <- rep_table.m$distance / (2 * r)       # age in years
rep_table.m$age_mya <- rep_table.m$age / 1e6             # age in million years

# remove helitrons as EDTA is not able to annotate them properly
rep_table.m <- rep_table.m %>% filter(fam != "DNA/Helitron")

# Summary table: Mbp per superfamily per age bin (useful for the report)
age_summary <- rep_table.m %>%
  group_by(fam, distance, age_mya) %>%
  summarise(Mbp = sum(value) / 1e6, .groups = "drop")
write.table(age_summary, "TE_age_summary.tsv", sep = "\t", quote = FALSE, row.names = FALSE)

# TE landscape plotted against estimated age instead of divergence
ggplot(rep_table.m, aes(fill = fam, x = age_mya, weight = value / 1000000)) +
  geom_bar() +
  cowplot::theme_cowplot() +
  scale_fill_brewer(palette = "Paired") +
  xlab("Estimated age (million years ago)") +
  ylab("Sequence (Mbp)") +
  theme(axis.text.x = element_text(angle = 90, vjust = 1, size = 9, hjust = 1), plot.title = element_text(hjust = 0.5))

ggsave(filename = "Plots/TE_landscape_age.pdf", width = 10, height = 5, useDingbats = F)