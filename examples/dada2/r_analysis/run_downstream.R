#!/usr/bin/env Rscript
# =============================================================================
# run_downstream.R  --  DADA2 -> R hand-off worked example for SOP_DADA2_NeSI.md
# -----------------------------------------------------------------------------
# Takes the DADA2 example outputs one directory up (../counts_dada2.tsv,
# ../metadata.tsv, ../asv_tree.nwk) straight into the SOP_R_Analysis.md workflow,
# grouped by the TOFI cohort's Ethnicity x Gender design. It demonstrates that
# the DADA2 count table drops into Part 2 with no reshaping.
#
# Object names and steps follow SOP_R_Analysis.md (ps_raw, ps_srs, dist_bray,
# SRS to Cmin, adonis2, ANCOM-BC2); grouping is two-factor (Ethnicity * Gender)
# and weighted UniFrac is added because the DADA2 example ships an ASV tree.
# All outputs are DE-IDENTIFIED and ILLUSTRATIVE. Regenerate: Rscript run_downstream.R
# =============================================================================
set.seed(42)
suppressMessages({
  library(phyloseq); library(vegan); library(SRS); library(ape); library(phangorn)
  library(ggplot2); library(dplyr); library(tidyr); library(tibble); library(patchwork)
})
theme_set(theme_bw(base_size = 12))
HAVE_ANCOMBC <- requireNamespace("ANCOMBC", quietly = TRUE)

script_dir <- (function() { a <- commandArgs(trailingOnly = FALSE)
  f <- grep("^--file=", a, value = TRUE)
  if (length(f)) dirname(sub("^--file=", "", f[1])) else getwd() })()
IN  <- dirname(script_dir)                                   # the DADA2 example dir
FIG <- file.path(script_dir, "figures"); dir.create(FIG, showWarnings = FALSE, recursive = TRUE)
eth_cols <- c(Caucasian = "#0072B2", Chinese = "#D55E00")    # Okabe-Ito, colour-blind safe
save_gg <- function(p, name, w = 8, h = 5.5, dpi = 200)
  ggsave(file.path(FIG, paste0(name, ".png")), p, width = w, height = h, dpi = dpi)

## ---- Section 3: load, splitting the combined counts_dada2.tsv (SOP §3) ------
comb <- read.table(file.path(IN, "counts_dada2.tsv"), header = TRUE, sep = "\t",
                   row.names = 1, check.names = FALSE, comment.char = "")
ranks     <- c("species","genus","family","order","class","phylum","superkingdom")
taxonomy   <- as.matrix(comb[, colnames(comb) %in% ranks])
counts_raw <- comb[, !colnames(comb) %in% ranks]
colsum <- colSums(counts_raw)
if (all(abs(colsum - 100) < 1) || all(abs(colsum - 1) < 0.01))
  stop("relative-abundance table, not counts")
counts_raw <- round(counts_raw); counts_raw <- counts_raw[rowSums(counts_raw) > 0, ]
taxonomy   <- taxonomy[rownames(counts_raw), ]
metadata   <- read.table(file.path(IN, "metadata.tsv"), header = TRUE, sep = "\t",
                         row.names = 1, check.names = FALSE, stringsAsFactors = FALSE)
metadata   <- metadata[colnames(counts_raw), , drop = FALSE]
stopifnot(identical(rownames(metadata), colnames(counts_raw)))
metadata$Ethnicity <- factor(metadata$Ethnicity, levels = c("Caucasian", "Chinese"))
metadata$Gender    <- factor(metadata$Gender,    levels = c("Female", "Male"))
tree <- phangorn::midpoint(ape::read.tree(file.path(IN, "asv_tree.nwk")))  # root once (Appendix D)
cat(sprintf("Loaded %d ASVs x %d samples\n", nrow(counts_raw), ncol(counts_raw)))
print(table(metadata$Ethnicity, metadata$Gender))

## ---- Section 4: no decontam -- the de-identified subset ships no blanks -----
cat("decontam skipped: this example carries no negative controls (SampleType all 'sample')\n")

## ---- prevalence + depth filter, then ps_raw (with the ASV tree) -------------
counts_raw <- counts_raw[rowSums(counts_raw > 0) >= 0.05 * ncol(counts_raw), ]  # ASVs in >=5% of samples
keep <- colSums(counts_raw) >= 3000                                            # drop very shallow samples
counts_raw <- counts_raw[, keep, drop = FALSE]; counts_raw <- counts_raw[rowSums(counts_raw) > 0, , drop = FALSE]
taxonomy   <- taxonomy[rownames(counts_raw), , drop = FALSE]
metadata   <- metadata[colnames(counts_raw), , drop = FALSE]
ps_raw <- phyloseq(otu_table(as.matrix(counts_raw), taxa_are_rows = TRUE),
                   tax_table(taxonomy), sample_data(metadata), phy_tree(tree))
cat(sprintf("ps_raw: %d ASVs x %d samples after filtering\n", ntaxa(ps_raw), nsamples(ps_raw)))

## ---- Section 6: SRS normalise -> ps_srs -------------------------------------
Cmin <- min(colSums(counts_raw)); cat(sprintf("SRS to Cmin = %d\n", Cmin))
counts_srs <- as.data.frame(SRS(as.data.frame(counts_raw), Cmin = Cmin, set_seed = TRUE))
rownames(counts_srs) <- rownames(counts_raw); colnames(counts_srs) <- colnames(counts_raw)
ps_srs <- phyloseq(otu_table(as.matrix(counts_srs), taxa_are_rows = TRUE),
                   tax_table(taxonomy), sample_data(metadata), phy_tree(tree))

## ---- Fig 1: read depth by group --------------------------------------------
df1 <- data.frame(reads = sample_sums(ps_raw), Ethnicity = sample_data(ps_raw)$Ethnicity,
                  Gender = sample_data(ps_raw)$Gender)
p1 <- ggplot(df1, aes(interaction(Ethnicity, Gender, sep = "\n"), reads, colour = Ethnicity)) +
  geom_boxplot(outlier.shape = NA, alpha = 0.2) +
  geom_jitter(aes(shape = Gender), width = 0.15, size = 1.6) +
  scale_colour_manual(values = eth_cols) + scale_y_log10() +
  labs(x = NULL, y = "reads (log)", title = "Read depth by Ethnicity x Gender (illustrative example)")
save_gg(p1, "01_read_depth_by_group", w = 7, h = 5)

## ---- Section 7: alpha diversity by Ethnicity and Gender ---------------------
alpha <- estimate_richness(ps_srs, measures = c("Observed", "Shannon"))
alpha$Ethnicity <- sample_data(ps_srs)$Ethnicity; alpha$Gender <- sample_data(ps_srs)$Gender
sink(file.path(script_dir, "alpha_stats.txt"))
cat("Alpha diversity (SRS-normalised ps_srs), by Ethnicity and Gender\n\nGroup medians:\n")
print(aggregate(cbind(Observed, Shannon) ~ Ethnicity + Gender, data = alpha, FUN = median))
for (m in c("Observed", "Shannon")) { cat(sprintf("\n== %s ==\n", m))
  cat("Wilcoxon by Ethnicity: p =", format.pval(wilcox.test(alpha[[m]] ~ alpha$Ethnicity)$p.value), "\n")
  cat("Wilcoxon by Gender   : p =", format.pval(wilcox.test(alpha[[m]] ~ alpha$Gender)$p.value), "\n") }
sink()
ad <- pivot_longer(alpha, c(Observed, Shannon), names_to = "metric", values_to = "value")
p2 <- ggplot(ad, aes(Ethnicity, value, colour = Ethnicity)) +
  geom_boxplot(outlier.shape = NA, alpha = 0.2) +
  geom_jitter(aes(shape = Gender), width = 0.15, size = 1.6) +
  scale_colour_manual(values = eth_cols) + facet_wrap(~metric, scales = "free_y") +
  labs(x = NULL, y = "diversity", title = "Alpha diversity by Ethnicity (shape = Gender; illustrative)") +
  theme(legend.position = "bottom")
save_gg(p2, "02_alpha_diversity", w = 8, h = 5)

## ---- Section 8: beta diversity + PERMANOVA ~ Ethnicity * Gender -------------
dist_bray <- phyloseq::distance(ps_srs, "bray")
dist_wuf  <- UniFrac(ps_srs, weighted = TRUE)          # rooted tree -> reproducible
meta_df <- data.frame(sample_data(ps_srs)); perm <- how(nperm = 9999)
pm_bray <- adonis2(dist_bray ~ Ethnicity * Gender, data = meta_df, permutations = perm, by = "terms")
pm_wuf  <- adonis2(dist_wuf  ~ Ethnicity * Gender, data = meta_df, permutations = perm, by = "terms")
sink(file.path(script_dir, "permanova_results.txt"))
cat("PERMANOVA ~ Ethnicity * Gender (9999 permutations)\n\n-- Bray-Curtis (SRS) --\n"); print(pm_bray)
cat("\n-- Weighted UniFrac (SRS, rooted tree) --\n"); print(pm_wuf); sink()
mkord <- function(dist, lbl, pm) {
  ord <- ordinate(ps_srs, "PCoA", distance = dist)
  ev  <- round(100 * ord$values$Relative_eig[1:2], 1)
  plot_ordination(ps_srs, ord, color = "Ethnicity", shape = "Gender") + geom_point(size = 2.4) +
    scale_colour_manual(values = eth_cols) +
    stat_ellipse(aes(group = Ethnicity), type = "norm", linetype = 2) +
    labs(x = paste0("Axis 1 (", ev[1], "%)"), y = paste0("Axis 2 (", ev[2], "%)"),
         title = lbl,
         subtitle = sprintf("PERMANOVA: Ethnicity p=%.2g, Gender p=%.2g, ExG p=%.2g",
                            pm$`Pr(>F)`[1], pm$`Pr(>F)`[2], pm$`Pr(>F)`[3])) +
    theme(plot.subtitle = element_text(size = 8.5))
}
p3 <- (mkord(dist_bray, "Bray-Curtis", pm_bray) + mkord(dist_wuf, "Weighted UniFrac", pm_wuf)) +
  plot_layout(guides = "collect") & theme(legend.position = "bottom")
save_gg(p3, "03_beta_pcoa", w = 11, h = 5.8)

## ---- Section 9: taxonomy barplot (top genera by group) ----------------------
ps_gen <- transform_sample_counts(tax_glom(ps_srs, taxrank = "genus", NArm = FALSE),
                                  function(x) x / sum(x))
mm <- psmelt(ps_gen); mm$genus <- as.character(mm$genus); mm$genus[is.na(mm$genus)] <- "Unassigned"
top <- mm %>% group_by(genus) %>% summarise(a = sum(Abundance)) %>% arrange(desc(a)) %>%
  slice_head(n = 11) %>% pull(genus)
pal <- c("#E69F00","#56B4E9","#009E73","#F0E442","#0072B2","#D55E00","#CC79A7",
         "#332288","#117733","#882255","#44AA99","#999999")
mm$Genus <- factor(ifelse(mm$genus %in% top, mm$genus, "Other"), levels = c(top, "Other"))
cols <- setNames(pal[seq_along(levels(mm$Genus))], levels(mm$Genus)); cols["Other"] <- "#999999"
p4 <- ggplot(mm, aes(Sample, Abundance, fill = Genus)) + geom_col(position = "fill", width = 1) +
  facet_grid(~ Ethnicity + Gender, scales = "free_x", space = "free_x") +
  scale_fill_manual(values = cols) +
  labs(x = NULL, y = "relative abundance", title = "Genus composition by Ethnicity x Gender (illustrative)") +
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank(), panel.grid = element_blank())
save_gg(p4, "04_taxonomy_barplot", w = 11, h = 6)

## ---- Section 10: ANCOM-BC2 differential genera by Ethnicity (guarded) -------
if (HAVE_ANCOMBC) {
  suppressMessages(library(ANCOMBC)); set.seed(123)
  da <- ancombc2(data = ps_raw, tax_level = "genus", fix_formula = "Ethnicity + Gender",
                 p_adj_method = "holm", prv_cut = 0.10, lib_cut = 1000, group = "Ethnicity",
                 struc_zero = TRUE, alpha = 0.05, global = FALSE, pairwise = FALSE, verbose = FALSE)
  res <- da$res
  lc <- grep("^lfc_Ethnicity", names(res), value = TRUE)[1]
  sig <- data.frame(taxon = res$taxon, lfc = res[[lc]], se = res[[sub("^lfc_", "se_", lc)]],
                    diff = res[[sub("^lfc_", "diff_", lc)]], pass = res[[sub("^lfc_", "passed_ss_", lc)]])
  write.table(res, file.path(script_dir, "ancombc2_full_res.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)
  sig <- sig[sig$diff & sig$pass, ]
  write.table(sig, file.path(script_dir, "ancombc2_significant.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)
  cat(sprintf("ANCOM-BC2: %d significant genera (Chinese vs Caucasian)\n", nrow(sig)))
  if (nrow(sig) > 0) {
    sig <- head(sig[order(-abs(sig$lfc)), ], 20)
    sig$taxon <- factor(sig$taxon, levels = sig$taxon[order(sig$lfc)])
    sig$dir <- ifelse(sig$lfc > 0, "higher in Chinese", "higher in Caucasian")
    p5 <- ggplot(sig, aes(lfc, taxon, colour = dir)) + geom_vline(xintercept = 0, colour = "grey60") +
      geom_errorbarh(aes(xmin = lfc - se, xmax = lfc + se), height = 0) + geom_point(size = 2.4) +
      scale_colour_manual(values = c("higher in Chinese" = "#D55E00", "higher in Caucasian" = "#0072B2")) +
      labs(x = "log fold change (Chinese vs Caucasian)", y = NULL, colour = NULL,
           title = "ANCOM-BC2 differential genera by Ethnicity (illustrative)")
    save_gg(p5, "05_ancombc2_lfc", w = 9, h = 6)
  }
} else cat("ANCOM-BC2 skipped (package absent)\n")

writeLines(capture.output(sessionInfo()), file.path(script_dir, "sessionInfo.txt"))
cat("\nDONE — figures in", FIG, "\n")
