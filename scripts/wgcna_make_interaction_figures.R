#!/usr/bin/env Rscript

# WGCNA Figure Builder: Genotype x Development Stage Module Effects
#
# Purpose:
# - Create publication-ready exploratory figures showing module-trait
#   relationships and genotype-by-stage interaction patterns in module
#   eigengenes.
#
# Inputs (defaults):
# - results/wgcna_stage5/module_trait_associations.csv
# - results/wgcna_stage5/module_eigengenes.csv
# - data/All_Counts_Sample_Info.csv
# - results/wgcna_stage6/module_best_trait_pairs.csv
#
# Outputs:
# - results/wgcna_figures/module_trait_heatmap_fdr05.png
# - results/wgcna_figures/top_modules_interaction_lines.png
# - results/wgcna_figures/module_group_mean_heatmap.png
#
# Usage:
#   Rscript scripts/wgcna_make_interaction_figures.R

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(tidyr)
  library(pheatmap)
})

base <- "/Users/dlowry/Developer/Playground"
fig_dir <- file.path(base, "results", "wgcna_figures")
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

assoc <- read.csv(file.path(base, "results", "wgcna_stage5", "module_trait_associations.csv"), check.names = FALSE)
MEs <- read.csv(file.path(base, "results", "wgcna_stage5", "module_eigengenes.csv"), row.names = 1, check.names = FALSE)
meta <- read.csv(file.path(base, "data", "All_Counts_Sample_Info.csv"), check.names = FALSE)
module_best <- read.csv(file.path(base, "results", "wgcna_stage6", "module_best_trait_pairs.csv"), check.names = FALSE)

meta$sample_number <- as.character(meta$sample_number)
meta <- meta %>%
  mutate(
    genotype = factor(genotype, levels = c("Coast", "Inland")),
    development_stage = factor(development_stage, levels = c("2leaf", "4leaf", "6leaf", "8leaf", "bud"))
  )

# Align metadata to module eigengene rows (sample IDs)
meta_aligned <- meta[match(rownames(MEs), meta$sample_number), , drop = FALSE]
if (any(is.na(meta_aligned$sample_number))) {
  stop("Metadata alignment failed for module eigengenes.")
}

# Figure 1: Module-trait correlation heatmap (FDR < 0.05 emphasis)
plot_df <- assoc %>%
  filter(trait %in% c("genotypeInland", "development_stage4leaf", "development_stage6leaf", "development_stage8leaf", "development_stagebud")) %>%
  mutate(
    sig = case_when(
      fdr_bh < 0.001 ~ "***",
      fdr_bh < 0.01 ~ "**",
      fdr_bh < 0.05 ~ "*",
      TRUE ~ ""
    ),
    label = sprintf("%.2f%s", cor, sig)
  )

module_order <- plot_df %>%
  group_by(module) %>%
  summarize(max_abs_cor = max(abs(cor), na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(max_abs_cor)) %>%
  pull(module)

plot_df$module <- factor(plot_df$module, levels = module_order)

p1 <- ggplot(plot_df, aes(x = trait, y = module, fill = cor)) +
  geom_tile(color = "white", linewidth = 0.2) +
  geom_text(aes(label = label), size = 3) +
  scale_fill_gradient2(low = "#2166ac", mid = "white", high = "#b2182b", midpoint = 0, limits = c(-1, 1)) +
  labs(
    title = "Module-Trait Correlations",
    subtitle = "Labels show correlation and FDR significance (* <0.05, ** <0.01, *** <0.001)",
    x = "Trait contrast",
    y = "Module eigengene",
    fill = "Correlation"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    axis.text.x = element_text(angle = 30, hjust = 1),
    panel.grid = element_blank()
  )

ggsave(file.path(fig_dir, "module_trait_heatmap_fdr05.png"), p1, width = 10, height = 8, dpi = 300)

# Figure 2: Interaction line plots for top modules
# Select top modules by strongest module-trait signal
mods_top <- module_best %>%
  mutate(abs_cor = abs(cor)) %>%
  arrange(desc(abs_cor), fdr_bh) %>%
  slice_head(n = 8) %>%
  pull(module)

me_long <- MEs %>%
  tibble::rownames_to_column("sample_number") %>%
  select(sample_number, all_of(mods_top)) %>%
  pivot_longer(-sample_number, names_to = "module", values_to = "eigengene") %>%
  left_join(meta_aligned %>% select(sample_number, genotype, development_stage), by = "sample_number")

sum_df <- me_long %>%
  group_by(module, genotype, development_stage) %>%
  summarize(
    mean_eigengene = mean(eigengene, na.rm = TRUE),
    se_eigengene = sd(eigengene, na.rm = TRUE) / sqrt(n()),
    n = n(),
    .groups = "drop"
  )

p2 <- ggplot(sum_df, aes(x = development_stage, y = mean_eigengene, color = genotype, group = genotype)) +
  geom_line(linewidth = 0.7) +
  geom_point(size = 1.8) +
  geom_errorbar(aes(ymin = mean_eigengene - se_eigengene, ymax = mean_eigengene + se_eigengene), width = 0.15, linewidth = 0.35) +
  facet_wrap(~ module, scales = "free_y", ncol = 4) +
  scale_color_manual(values = c("Coast" = "#1b9e77", "Inland" = "#d95f02")) +
  labs(
    title = "Genotype x Development Stage Patterns in Top Module Eigengenes",
    subtitle = "Mean +/- SE per group",
    x = "Development stage",
    y = "Module eigengene (mean)",
    color = "Genotype"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    axis.text.x = element_text(angle = 25, hjust = 1),
    strip.text = element_text(face = "bold")
  )

ggsave(file.path(fig_dir, "top_modules_interaction_lines.png"), p2, width = 14, height = 9, dpi = 300)

# Figure 3: Group-mean heatmap (module x genotype_stage)
me_group <- me_long %>%
  mutate(group = paste(genotype, development_stage, sep = "_")) %>%
  group_by(module, group) %>%
  summarize(mean_eigengene = mean(eigengene, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = group, values_from = mean_eigengene)

me_mat <- as.matrix(me_group[, -1, drop = FALSE])
rownames(me_mat) <- me_group$module

# keep module ordering consistent with figure 1
keep_mod <- intersect(module_order, rownames(me_mat))
me_mat <- me_mat[keep_mod, , drop = FALSE]

png(file.path(fig_dir, "module_group_mean_heatmap.png"), width = 1500, height = 1200, res = 150)
pheatmap(
  me_mat,
  color = colorRampPalette(c("#313695", "#f7f7f7", "#a50026"))(120),
  cluster_rows = TRUE,
  cluster_cols = TRUE,
  scale = "row",
  fontsize_row = 9,
  fontsize_col = 9,
  main = "Module Eigengene Means by Genotype x Development Stage (row-scaled)"
)
dev.off()

# Write manifest
manifest <- c(
  "Generated figures:",
  file.path(fig_dir, "module_trait_heatmap_fdr05.png"),
  file.path(fig_dir, "top_modules_interaction_lines.png"),
  file.path(fig_dir, "module_group_mean_heatmap.png")
)
writeLines(manifest, file.path(fig_dir, "README_figures.txt"))

cat("FIGURES_OK\n")
cat(paste(manifest, collapse = "\n"), "\n")
