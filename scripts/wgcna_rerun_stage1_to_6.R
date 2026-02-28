#!/usr/bin/env Rscript

# WGCNA Rerun Pipeline (Stages 1-6 + Final Option 1 Exports)
#
# Purpose:
# - Reproduce the full analysis path used in this run from raw input CSVs.
# - Apply the approved human decisions at each gate.
# - Emit stage outputs and final hub-gene shortlist artifacts.
#
# Required inputs:
# - Expression CSV with the first five embedded metadata rows followed by gene rows.
# - Metadata CSV containing sample_number and trait columns.
#
# Defaults:
# --expr=data/GSE280929_All_count_data_labelled.csv
# --meta=data/All_Counts_Sample_Info.csv
# --out=results/wgcna_rerun
# --threads=2
#
# Usage:
#   Rscript scripts/wgcna_rerun_stage1_to_6.R \
#     --expr=data/GSE280929_All_count_data_labelled.csv \
#     --meta=data/All_Counts_Sample_Info.csv \
#     --out=results/wgcna_rerun \
#     --threads=2
#
# Notes on baked-in approved decisions:
# - Gate A: remove sample IDs 76, 77, 78
# - Gate C: signed-hybrid network, power=5
# - Gate D: minModuleSize=30, deepSplit=2, mergeCutHeight=0.25
# - Gate E: significance FDR<0.05 and |cor|>=0.5 using genotypeInland + stage columns
# - Gate F: strict hubs (|MM|>=0.80 and |GS|>=0.40) without per-module cap

suppressPackageStartupMessages({
  library(DESeq2)
  library(WGCNA)
})

options(stringsAsFactors = FALSE)

# Print CLI usage and exit.
print_usage <- function() {
  cat(
    "Usage:
",
    "  Rscript scripts/wgcna_rerun_stage1_to_6.R [--expr=PATH] [--meta=PATH] [--out=DIR] [--threads=N]

",
    "Example:
",
    "  Rscript scripts/wgcna_rerun_stage1_to_6.R --expr=data/GSE280929_All_count_data_labelled.csv --meta=data/All_Counts_Sample_Info.csv --out=results/wgcna_rerun --threads=2
",
    sep = ""
  )
}

if (any(commandArgs(trailingOnly = TRUE) %in% c("--help", "-h"))) {
  print_usage()
  quit(save = "no", status = 0)
}

# Parse --flag=value style CLI arguments.
get_arg <- function(flag, default = NULL) {
  args <- commandArgs(trailingOnly = TRUE)
  prefix <- paste0("--", flag, "=")
  hit <- args[startsWith(args, prefix)]
  if (length(hit) == 0) return(default)
  sub(prefix, "", hit[[1]])
}

expr_path <- get_arg("expr", "data/GSE280929_All_count_data_labelled.csv")
meta_path <- get_arg("meta", "data/All_Counts_Sample_Info.csv")
out_base <- get_arg("out", "results/wgcna_rerun")
threads <- as.integer(get_arg("threads", "2"))

if (!file.exists(expr_path)) stop("Expression file not found: ", expr_path)
if (!file.exists(meta_path)) stop("Metadata file not found: ", meta_path)

allowWGCNAThreads(nThreads = threads)

dir.create(out_base, recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(out_base, "stage1"), showWarnings = FALSE)
dir.create(file.path(out_base, "stage3"), showWarnings = FALSE)
dir.create(file.path(out_base, "stage4"), showWarnings = FALSE)
dir.create(file.path(out_base, "stage5"), showWarnings = FALSE)
dir.create(file.path(out_base, "stage6"), showWarnings = FALSE)
dir.create(file.path(out_base, "final"), showWarnings = FALSE)

cat("[1/6] Stage 1: intake, QC, filtering, VST\n")
expr_raw <- read.csv(expr_path, check.names = FALSE)
meta <- read.csv(meta_path, check.names = FALSE)

sample_ids <- colnames(expr_raw)[-1]
embedded_rows <- expr_raw[1:5, ]
gene_df <- expr_raw[-(1:5), ]

count_mat <- as.matrix(gene_df[, -1, drop = FALSE])
mode(count_mat) <- "numeric"
rownames(count_mat) <- gene_df[[1]]
colnames(count_mat) <- sample_ids

meta$sample_number <- as.character(meta$sample_number)
meta_aligned <- meta[match(sample_ids, meta$sample_number), , drop = FALSE]
if (any(is.na(meta_aligned$sample_number))) stop("Metadata/sample alignment failed")

lib_sizes <- colSums(count_mat)
log_counts <- log2(count_mat + 1)
sample_cor <- cor(log_counts, use = "pairwise.complete.obs")
conn <- rowSums(sample_cor, na.rm = TRUE) - 1
z_conn <- (conn - mean(conn, na.rm = TRUE)) / sd(conn, na.rm = TRUE)
outlier_flag <- z_conn < -2.5
outlier_samples <- names(which(outlier_flag))

min_samples <- ceiling(0.20 * ncol(count_mat))
keep_gene <- rowSums(count_mat >= 10) >= min_samples
count_filt <- count_mat[keep_gene, , drop = FALSE]

dds <- DESeqDataSetFromMatrix(
  countData = round(count_filt),
  colData = meta_aligned,
  design = ~ 1
)
vst_obj <- vst(dds, blind = TRUE)
vst_mat <- assay(vst_obj)

datExpr_all <- as.data.frame(t(vst_mat))
gsg_all <- goodSamplesGenes(datExpr_all, verbose = 0)

stage1_summary <- c(
  paste0("samples_total=", ncol(count_mat)),
  paste0("genes_total=", nrow(count_mat)),
  paste0("genes_kept_filter_ge10_in_20pct=", nrow(count_filt)),
  paste0("genes_removed_filter=", nrow(count_mat) - nrow(count_filt)),
  paste0("library_size_min=", format(min(lib_sizes), scientific = FALSE)),
  paste0("library_size_median=", format(median(lib_sizes), scientific = FALSE)),
  paste0("library_size_max=", format(max(lib_sizes), scientific = FALSE)),
  paste0("outlier_candidates_zltneg2.5=", sum(outlier_flag)),
  paste0("outlier_samples=", paste(outlier_samples, collapse = ",")),
  paste0("goodSamplesGenes_allOK=", gsg_all$allOK),
  paste0("embedded_metadata_rows=", paste(embedded_rows[[1]], collapse = "|"))
)
writeLines(stage1_summary, file.path(out_base, "stage1", "stage1_summary.txt"))
write.csv(data.frame(sample_number = names(lib_sizes), lib_size = as.numeric(lib_sizes)),
          file.path(out_base, "stage1", "library_sizes.csv"), row.names = FALSE)
write.csv(data.frame(sample_number = names(z_conn), z_connectivity = as.numeric(z_conn), outlier_flag = as.logical(outlier_flag)),
          file.path(out_base, "stage1", "sample_connectivity_qc.csv"), row.names = FALSE)
write.csv(data.frame(gene_id = rownames(count_filt)),
          file.path(out_base, "stage1", "genes_kept_filter.csv"), row.names = FALSE)
write.csv(vst_mat, file.path(out_base, "stage1", "vst_matrix_genes_x_samples.csv"), row.names = TRUE)

# Approved Gate A decision: remove outliers 76,77,78 if present
approved_outliers <- c("76", "77", "78")
keep_samples <- setdiff(colnames(vst_mat), approved_outliers)
datExpr <- as.data.frame(t(vst_mat[, keep_samples, drop = FALSE]))
gsg <- goodSamplesGenes(datExpr, verbose = 0)
if (!gsg$allOK) datExpr <- datExpr[gsg$goodSamples, gsg$goodGenes]

cat("[2/6] Stage 3: soft-threshold power analysis\n")
powers <- 1:20
sft_signed <- pickSoftThreshold(datExpr, powerVector = powers, networkType = "signed", corFnc = "cor", verbose = 0)
sft_sh <- pickSoftThreshold(datExpr, powerVector = powers, networkType = "signed hybrid", corFnc = "cor", verbose = 0)

to_df <- function(x, network_type) {
  d <- x$fitIndices
  d$network_type <- network_type
  d
}
fit_df <- rbind(to_df(sft_signed, "signed"), to_df(sft_sh, "signed_hybrid"))
write.csv(fit_df, file.path(out_base, "stage3", "soft_threshold_fit_indices.csv"), row.names = FALSE)

pick_candidate <- function(df) {
  idx <- which(df$SFT.R.sq >= 0.8)
  if (length(idx) > 0) {
    i <- min(idx)
  } else {
    i <- which.max(df$SFT.R.sq)
  }
  df[i, c("Power", "SFT.R.sq", "mean.k.")]
}

cand_signed <- pick_candidate(subset(fit_df, network_type == "signed"))
cand_sh <- pick_candidate(subset(fit_df, network_type == "signed_hybrid"))

stage3_summary <- c(
  paste0("samples_used=", nrow(datExpr)),
  paste0("genes_used=", ncol(datExpr)),
  paste0("outliers_removed=", paste(approved_outliers, collapse = ",")),
  paste0("signed_candidate_power=", cand_signed$Power),
  paste0("signed_candidate_r2=", signif(cand_signed$SFT.R.sq, 4)),
  paste0("signed_candidate_mean_k=", signif(cand_signed$mean.k., 4)),
  paste0("signed_hybrid_candidate_power=", cand_sh$Power),
  paste0("signed_hybrid_candidate_r2=", signif(cand_sh$SFT.R.sq, 4)),
  paste0("signed_hybrid_candidate_mean_k=", signif(cand_sh$mean.k., 4))
)
writeLines(stage3_summary, file.path(out_base, "stage3", "stage3_power_summary.txt"))

# Approved Gate C decision
chosen_power <- 5
chosen_network_type <- "signed hybrid"
chosen_tom_type <- "signed"

cat("[3/6] Stage 4: module parameter comparison\n")
run_cfg <- function(name, minModuleSize, deepSplit, mergeCutHeight) {
  net <- blockwiseModules(
    datExpr,
    power = chosen_power,
    networkType = chosen_network_type,
    TOMType = chosen_tom_type,
    minModuleSize = minModuleSize,
    deepSplit = deepSplit,
    mergeCutHeight = mergeCutHeight,
    reassignThreshold = 0,
    numericLabels = TRUE,
    pamRespectsDendro = FALSE,
    saveTOMs = FALSE,
    verbose = 0
  )
  tab <- table(net$colors)
  non_grey <- tab[names(tab) != "0"]
  data.frame(
    config = name,
    samples = nrow(datExpr),
    genes = ncol(datExpr),
    power = chosen_power,
    network_type = "signed_hybrid",
    minModuleSize = minModuleSize,
    deepSplit = deepSplit,
    mergeCutHeight = mergeCutHeight,
    module_count_total_including_grey = length(tab),
    module_count_non_grey = length(non_grey),
    grey_gene_count = ifelse("0" %in% names(tab), as.integer(tab[["0"]]), 0L),
    min_non_grey_module_size = ifelse(length(non_grey) > 0, min(as.integer(non_grey)), NA_integer_),
    median_non_grey_module_size = ifelse(length(non_grey) > 0, as.numeric(median(as.integer(non_grey))), NA_real_),
    max_non_grey_module_size = ifelse(length(non_grey) > 0, max(as.integer(non_grey)), NA_integer_)
  )
}

cfg_a <- run_cfg("A_defaultish", minModuleSize = 30, deepSplit = 2, mergeCutHeight = 0.25)
cfg_b <- run_cfg("B_more_granular", minModuleSize = 20, deepSplit = 3, mergeCutHeight = 0.20)
write.csv(rbind(cfg_a, cfg_b), file.path(out_base, "stage4", "module_param_comparison.csv"), row.names = FALSE)
write.csv(datExpr, file.path(out_base, "stage4", "datExpr_samples_x_genes.csv"), row.names = TRUE)

# Approved Gate D decision: config A
cat("[4/6] Stage 5: module-trait associations\n")
net <- blockwiseModules(
  datExpr,
  power = chosen_power,
  networkType = chosen_network_type,
  TOMType = chosen_tom_type,
  minModuleSize = 30,
  deepSplit = 2,
  mergeCutHeight = 0.25,
  reassignThreshold = 0,
  numericLabels = TRUE,
  pamRespectsDendro = FALSE,
  saveTOMs = FALSE,
  verbose = 0
)
MEs <- orderMEs(net$MEs)

meta2 <- meta[match(rownames(datExpr), meta$sample_number), , drop = FALSE]
if (any(is.na(meta2$sample_number))) stop("Metadata alignment failed in Stage 5")

trait_df <- data.frame(
  genotype = factor(meta2$genotype),
  development_stage = factor(meta2$development_stage)
)
trait_mm <- model.matrix(~ 0 + genotype + development_stage, data = trait_df)
colnames(trait_mm) <- make.names(colnames(trait_mm))

modTraitCor <- cor(MEs, trait_mm, use = "p")
modTraitP <- corPvalueStudent(modTraitCor, nSamples = nrow(datExpr))

assoc <- do.call(rbind, lapply(seq_len(nrow(modTraitCor)), function(i) {
  data.frame(
    module = rownames(modTraitCor)[i],
    trait = colnames(modTraitCor),
    cor = as.numeric(modTraitCor[i, ]),
    p_value = as.numeric(modTraitP[i, ])
  )
}))
assoc$fdr_bh <- p.adjust(assoc$p_value, method = "BH")
assoc <- assoc[order(assoc$fdr_bh, -abs(assoc$cor)), ]

write.csv(assoc, file.path(out_base, "stage5", "module_trait_associations.csv"), row.names = FALSE)
write.csv(data.frame(sample = rownames(datExpr), trait_mm),
          file.path(out_base, "stage5", "trait_design_matrix.csv"), row.names = FALSE)
write.csv(data.frame(gene = names(net$colors), module_label = net$colors),
          file.path(out_base, "stage5", "gene_module_labels.csv"), row.names = FALSE)
write.csv(MEs, file.path(out_base, "stage5", "module_eigengenes.csv"), row.names = TRUE)

stage5_summary <- c(
  paste0("samples_used=", nrow(datExpr)),
  paste0("genes_used=", ncol(datExpr)),
  paste0("non_grey_modules=", length(setdiff(unique(net$colors), 0))),
  paste0("module_trait_tests=", nrow(assoc)),
  paste0("associations_p_lt_0.05=", sum(assoc$p_value < 0.05)),
  paste0("associations_fdr_lt_0.10=", sum(assoc$fdr_bh < 0.10)),
  paste0("associations_fdr_lt_0.05=", sum(assoc$fdr_bh < 0.05))
)
writeLines(stage5_summary, file.path(out_base, "stage5", "stage5_summary.txt"))

cat("[5/6] Stage 6: hub candidate preview\n")
# Approved Gate E decision
keep_trait_cols <- c("genotypeInland", grep("^development_stage", colnames(trait_mm), value = TRUE))
assoc2 <- subset(assoc, trait %in% keep_trait_cols & fdr_bh < 0.05 & abs(cor) >= 0.5)
if (nrow(assoc2) == 0) stop("No significant module-trait pairs under approved Gate E criteria")

assoc2$abs_cor <- abs(assoc2$cor)
assoc2 <- assoc2[order(assoc2$module, -assoc2$abs_cor, assoc2$fdr_bh), ]
module_best <- assoc2[!duplicated(assoc2$module), c("module", "trait", "cor", "p_value", "fdr_bh")]

MM <- as.data.frame(cor(datExpr, MEs, use = "p"))
MMP <- as.data.frame(corPvalueStudent(as.matrix(MM), nSamples = nrow(datExpr)))
GS <- as.data.frame(cor(datExpr, trait_mm[, keep_trait_cols, drop = FALSE], use = "p"))
GSP <- as.data.frame(corPvalueStudent(as.matrix(GS), nSamples = nrow(datExpr)))

hub_rows <- list()
idx <- 1
for (i in seq_len(nrow(module_best))) {
  mod <- module_best$module[i]
  trait <- module_best$trait[i]
  mod_num <- sub("^ME", "", mod)
  genes <- names(net$colors)[net$colors == as.numeric(mod_num)]
  if (length(genes) == 0 || !mod %in% colnames(MM) || !trait %in% colnames(GS)) next

  df <- data.frame(
    gene = genes,
    module = mod,
    trait = trait,
    MM = MM[genes, mod],
    MM_p = MMP[genes, mod],
    GS = GS[genes, trait],
    GS_p = GSP[genes, trait],
    stringsAsFactors = FALSE
  )
  df$absMM <- abs(df$MM)
  df$absGS <- abs(df$GS)
  hub_rows[[idx]] <- df
  idx <- idx + 1
}
hub_df <- do.call(rbind, hub_rows)
if (is.null(hub_df) || nrow(hub_df) == 0) stop("No genes available for hub scoring")

optA <- subset(hub_df, absMM >= 0.80 & absGS >= 0.40)
optB <- subset(hub_df, absMM >= 0.70 & absGS >= 0.30)

count_by_module <- function(df, label) {
  if (nrow(df) == 0) return(data.frame(option = label, module = character(), candidates = integer()))
  t <- as.data.frame(table(df$module), stringsAsFactors = FALSE)
  names(t) <- c("module", "candidates")
  t$option <- label
  t[, c("option", "module", "candidates")]
}
counts <- rbind(count_by_module(optA, "A_strict"), count_by_module(optB, "B_balanced"))

write.csv(module_best, file.path(out_base, "stage6", "module_best_trait_pairs.csv"), row.names = FALSE)
write.csv(hub_df, file.path(out_base, "stage6", "gene_mm_gs_table.csv"), row.names = FALSE)
write.csv(counts, file.path(out_base, "stage6", "hub_candidate_counts_by_option.csv"), row.names = FALSE)
write.csv(optA[order(-optA$absMM, -optA$absGS), ], file.path(out_base, "stage6", "hub_candidates_optionA_strict.csv"), row.names = FALSE)
write.csv(optB[order(-optB$absMM, -optB$absGS), ], file.path(out_base, "stage6", "hub_candidates_optionB_balanced.csv"), row.names = FALSE)

stage6_summary <- c(
  paste0("significant_module_trait_pairs_retained=", nrow(assoc2)),
  paste0("modules_with_best_trait=", nrow(module_best)),
  paste0("genes_evaluated_for_hub=", nrow(hub_df)),
  paste0("optionA_absMM_ge_0.80_absGS_ge_0.40_candidates=", nrow(optA)),
  paste0("optionB_absMM_ge_0.70_absGS_ge_0.30_candidates=", nrow(optB))
)
writeLines(stage6_summary, file.path(out_base, "stage6", "stage6_summary.txt"))

cat("[6/6] Final Option 1 exports\n")
# Approved Gate F decision: Option 1
if (nrow(optA) == 0) stop("Option A produced zero candidates for Option 1 export")

final_opt1 <- optA[order(optA$module, -optA$absMM, -optA$absGS, optA$gene), ]

counts_opt1 <- as.data.frame(table(final_opt1$module), stringsAsFactors = FALSE)
names(counts_opt1) <- c("module", "strict_candidates")

write.csv(final_opt1, file.path(out_base, "final", "hub_candidates_option1_all_strict.csv"), row.names = FALSE)
write.csv(counts_opt1, file.path(out_base, "final", "hub_option1_counts_by_module.csv"), row.names = FALSE)

# Enriched labels + ranking
mod_map <- module_best
mod_idx <- match(final_opt1$module, mod_map$module)
final_labeled <- final_opt1
final_labeled$module_best_trait <- mod_map$trait[mod_idx]
final_labeled$module_trait_cor <- mod_map$cor[mod_idx]
final_labeled$module_trait_p <- mod_map$p_value[mod_idx]
final_labeled$module_trait_fdr <- mod_map$fdr_bh[mod_idx]

# recompute within-module rank based on sorted order
final_labeled <- do.call(rbind, lapply(split(final_labeled, final_labeled$module), function(df) {
  df <- df[order(-df$absMM, -df$absGS, df$gene), ]
  df$rank_within_module <- seq_len(nrow(df))
  df
}))
final_labeled <- final_labeled[order(final_labeled$module, final_labeled$rank_within_module), ]
final_labeled$global_rank <- seq_len(nrow(final_labeled))

write.csv(final_labeled, file.path(out_base, "final", "hub_candidates_option1_all_strict_labeled.csv"), row.names = FALSE)

top10 <- do.call(rbind, lapply(split(final_labeled, final_labeled$module), function(df) head(df, 10)))
write.csv(top10, file.path(out_base, "final", "hub_candidates_option1_top10_per_module.csv"), row.names = FALSE)

# markdown report
md_lines <- c(
  "# Option 1 Hub Genes: Top 10 Per Module",
  "",
  paste0("- Total shortlisted genes: ", nrow(final_labeled)),
  paste0("- Modules represented: ", length(unique(final_labeled$module))),
  ""
)
for (m in unique(top10$module)) {
  subdf <- top10[top10$module == m, ]
  md_lines <- c(md_lines, paste0("## ", m))
  md_lines <- c(md_lines, paste0("- Best trait: `", subdf$module_best_trait[1], "` (cor=", signif(subdf$module_trait_cor[1], 4), ", FDR=", signif(subdf$module_trait_fdr[1], 4), ")"))
  md_lines <- c(md_lines, "", "| Rank | Gene | absMM | absGS |", "|---:|---|---:|---:|")
  for (i in seq_len(nrow(subdf))) {
    md_lines <- c(md_lines, paste0("| ", subdf$rank_within_module[i], " | ", subdf$gene[i], " | ", sprintf("%.4f", subdf$absMM[i]), " | ", sprintf("%.4f", subdf$absGS[i]), " |"))
  }
  md_lines <- c(md_lines, "")
}
writeLines(md_lines, file.path(out_base, "final", "hub_candidates_option1_top10_per_module.md"))

final_summary <- c(
  paste0("strict_candidates_option1=", nrow(optA)),
  paste0("final_option1_candidates=", nrow(final_labeled)),
  paste0("modules_with_candidates=", length(unique(final_labeled$module))),
  "gate_f_selection=option1_no_cap",
  paste0("expr_path=", expr_path),
  paste0("meta_path=", meta_path)
)
writeLines(final_summary, file.path(out_base, "final", "final_summary.txt"))

cat("DONE\n")
cat(paste(final_summary, collapse = "\n"), "\n")
