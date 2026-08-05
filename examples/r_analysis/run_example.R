#!/usr/bin/env Rscript
# =============================================================================
# run_example.R  --  worked example for SOP_R_Analysis.md
# -----------------------------------------------------------------------------
# Runs the Part-2 R workflow end to end on the committed example inputs
# (counts.tsv, taxonomy.tsv, metadata.tsv) and writes every tutorial figure to
# figures/. Regenerate with:   Rscript run_example.R
#
# Dataset : GlobalPatterns (Caporaso et al. 2011); see README.md for provenance,
#           licence and the subsetting/relabelling applied by make_inputs.R.
# Object names and workflow follow SOP_R_Analysis.md exactly (ps_raw, ps_srs,
# dist_bray, dist_ait, SRS to Cmin, ...); only column/file names are adapted to
# the example data, and the tuatara `Site * Sex` model becomes a single-term
# `~ Environment` model because GlobalPatterns has one meaningful grouping.
#
# Optional packages (ANCOMBC, Maaslin2) are guarded: if absent, Section 10 is
# skipped with a message rather than crashing.
# =============================================================================

set.seed(42)   # ordinations, SRS, permutation tests reproduce

## ---- packages --------------------------------------------------------------
suppressMessages({
  library(phyloseq)
  library(vegan)
  library(SRS)
  library(decontam)
  library(indicspecies)
  library(permute)
  library(EnvStats)
  library(ggplot2)
  library(dplyr)
  library(tidyr)
  library(tibble)
  library(patchwork)
})
theme_set(theme_bw(base_size = 12))
HAVE_ANCOMBC    <- requireNamespace("ANCOMBC", quietly = TRUE)
HAVE_MICROBIOME <- requireNamespace("microbiome", quietly = TRUE)

## ---- paths -----------------------------------------------------------------
script_dir <- (function() {
  a <- commandArgs(trailingOnly = FALSE)
  f <- grep("^--file=", a, value = TRUE)
  if (length(f)) dirname(sub("^--file=", "", f[1])) else getwd()
})()
FIGDIR <- file.path(script_dir, "figures")
dir.create(FIGDIR, showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(FIGDIR, "svg"), showWarnings = FALSE, recursive = TRUE)  # vector twins kept here

## ---- colour-blind-safe palette (Okabe-Ito) ---------------------------------
env_cols <- c(Human = "#D55E00", Freshwater = "#0072B2", Saline = "#009E73")
pal11 <- c("#E69F00","#56B4E9","#009E73","#F0E442","#0072B2","#D55E00",
           "#CC79A7","#332288","#117733","#882255","#999999")

## ---- helpers ---------------------------------------------------------------
produced <- character(0)
save_gg <- function(p, name, w = 8, h = 5.5, dpi = 200) {
  ggsave(file.path(FIGDIR, paste0(name, ".png")), p, width = w, height = h, dpi = dpi)
  try(ggsave(file.path(FIGDIR, "svg", paste0(name, ".svg")), p, width = w, height = h), silent = TRUE)
  produced <<- c(produced, name)
}
save_base <- function(fn, name, w = 8, h = 5.5, dpi = 200) {
  png(file.path(FIGDIR, paste0(name, ".png")), width = w, height = h, units = "in", res = dpi)
  fn(); dev.off()
  svg(file.path(FIGDIR, "svg", paste0(name, ".svg")), width = w, height = h); fn(); dev.off()
  produced <<- c(produced, name)
}
step <- function(name, expr) {
  cat(sprintf("\n----- %s -----\n", name))
  ok <- tryCatch({ force(expr); TRUE },
                 error = function(e) { cat("  [FAIL] ", conditionMessage(e), "\n", sep = ""); FALSE })
  if (ok) cat("  [OK]\n")
  invisible(ok)
}

# =============================================================================
# Section 3 - load and prepare data (SOP object names)
# =============================================================================
counts_raw <- read.table(file.path(script_dir, "counts.tsv"), header = TRUE, sep = "\t",
                         row.names = 1, check.names = FALSE, comment.char = "")
taxonomy   <- as.matrix(read.table(file.path(script_dir, "taxonomy.tsv"), header = TRUE,
                         sep = "\t", row.names = 1, check.names = FALSE,
                         comment.char = "", na.strings = "NA"))
metadata   <- read.table(file.path(script_dir, "metadata.tsv"), header = TRUE, sep = "\t",
                         row.names = 1, check.names = FALSE, comment.char = "",
                         stringsAsFactors = FALSE)

# Refuse a relative-abundance table (SOP guard). GlobalPatterns counts are large
# integers, so this passes; a percentage table would stop here.
colsum <- colSums(counts_raw)
if (all(abs(colsum - 100) < 1) || all(abs(colsum - 1) < 0.01))
  stop("Column sums are 100 or 1: this is a relative-abundance table, not counts.")

counts_raw <- round(counts_raw)
counts_raw <- counts_raw[rowSums(counts_raw) > 0, ]
taxonomy   <- taxonomy[rownames(counts_raw), ]

# Align metadata to count columns (SOP: index them POSITIONALLY, so this matters)
metadata <- metadata[colnames(counts_raw), , drop = FALSE]
stopifnot(identical(rownames(metadata), colnames(counts_raw)))

cat(sprintf("Loaded %d taxa x %d samples\n", nrow(counts_raw), ncol(counts_raw)))
print(table(metadata$Environment, metadata$SampleType))

# =============================================================================
# Section 4 - decontam (ILLUSTRATIVE) and build ps_raw
# -----------------------------------------------------------------------------
# GlobalPatterns has NO extraction blanks. The 3 Mock samples are marked
# SampleType = "blank" ONLY to exercise decontam's prevalence code path and
# produce a representative diagnostic figure. Because Mock is a positive control
# (not a true blank), the flagged taxa are NOT removed from the downstream
# analysis; only the Mock columns are dropped so the biology stays clean.
# =============================================================================
is_blank  <- metadata$SampleType == "blank"
contam_df <- isContaminant(t(counts_raw), neg = is_blank, method = "prevalence")
n_contam  <- sum(contam_df$contaminant, na.rm = TRUE)
cat(sprintf("decontam (illustrative) flagged %d taxa; NOT removed (Mock is not a true blank)\n",
            n_contam))

step("Fig 02 decontam prevalence (illustrative)", {
  df <- data.frame(score = contam_df$p)
  df <- df[!is.na(df$score), , drop = FALSE]
  p <- ggplot(df, aes(score)) +
    geom_histogram(breaks = seq(0, 1, 0.05), fill = "#0072B2", colour = "white") +
    geom_vline(xintercept = 0.1, linetype = 2, colour = "#D55E00") +
    labs(x = "decontam prevalence score P",
         y = "Number of taxa",
         title = "ILLUSTRATIVE decontam diagnostic - GlobalPatterns has no true blanks",
         subtitle = "Mock (positive control) used as stand-in negatives; flagged taxa NOT removed downstream") +
    annotate("text", x = 0.1, y = Inf, label = "  P < 0.1 -> contaminant", hjust = 0, vjust = 1.5,
             colour = "#D55E00", size = 3.2)
  save_gg(p, "02_decontam_prevalence", h = 5)
})

# Drop the Mock/illustrative-blank columns; keep all taxa.
counts_raw <- counts_raw[, !is_blank]
metadata   <- metadata[!is_blank, , drop = FALSE]
keep_tx    <- rowSums(counts_raw) > 0
counts_raw <- counts_raw[keep_tx, ]
taxonomy   <- taxonomy[rownames(counts_raw), ]
metadata$Environment <- factor(metadata$Environment,
                               levels = c("Human", "Freshwater", "Saline"))

ps_raw <- phyloseq(otu_table(as.matrix(counts_raw), taxa_are_rows = TRUE),
                   tax_table(taxonomy),
                   sample_data(metadata))
cat(sprintf("ps_raw: %d taxa x %d samples\n", ntaxa(ps_raw), nsamples(ps_raw)))

step("Fig 01 input sanity (library sizes)", {
  df <- data.frame(SampleID = sample_names(ps_raw),
                   reads = sample_sums(ps_raw),
                   Environment = sample_data(ps_raw)$Environment)
  df$SampleID <- factor(df$SampleID, levels = df$SampleID[order(df$reads)])
  p <- ggplot(df, aes(SampleID, reads, fill = Environment)) +
    geom_col() +
    scale_fill_manual(values = env_cols) +
    scale_y_continuous(labels = scales::label_number(scale_cut = scales::cut_short_scale())) +
    labs(x = NULL, y = "Total reads", title = "Library sizes per sample (input sanity)") +
    theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1))
  save_gg(p, "01_input_sanity")
})

# =============================================================================
# Section 5 - explore
# =============================================================================
step("Fig 03 read depth by group", {
  df <- data.frame(reads = sample_sums(ps_raw),
                   Environment = sample_data(ps_raw)$Environment)
  p <- ggplot(df, aes(Environment, reads, colour = Environment, fill = Environment)) +
    geom_boxplot(alpha = 0.25, outlier.shape = NA) +
    geom_jitter(width = 0.15, height = 0, size = 2) +
    scale_colour_manual(values = env_cols) + scale_fill_manual(values = env_cols) +
    scale_y_log10(labels = scales::label_number(scale_cut = scales::cut_short_scale())) +
    labs(x = NULL, y = "Total reads (log scale)", title = "Read depth by group") +
    theme(legend.position = "none")
  save_gg(p, "03_read_depth_by_group", w = 6.5, h = 5)
})

ps_rel_qc <- transform_sample_counts(ps_raw, function(x) x / sum(x))
quick_ord <- ordinate(ps_rel_qc, "PCoA", "bray")
step("Fig 05 exploratory PCoA (proportions)", {
  p <- plot_ordination(ps_rel_qc, quick_ord, color = "Environment") +
    geom_point(size = 3) +
    scale_colour_manual(values = env_cols) +
    stat_ellipse(type = "norm", linetype = 2) +
    labs(title = "Exploratory PCoA (Bray-Curtis on proportions)", colour = "Environment")
  save_gg(p, "05_explore_pcoa", w = 7, h = 5.5)
})

Cmin_preview <- min(colSums(counts_raw))
step("Fig 04 rarefaction curve", {
  cols <- env_cols[as.character(sample_data(ps_raw)$Environment)]
  save_base(function() {
    vegan::rarecurve(t(as.matrix(counts_raw)), step = 200, label = FALSE,
                     col = cols, lwd = 2, ylab = "Observed taxa", xlab = "Reads sampled")
    abline(v = Cmin_preview, lty = 2)
    legend("bottomright", legend = names(env_cols), col = env_cols, lwd = 2, bty = "n")
    title("Rarefaction curves (vertical line = Cmin)")
  }, "04_rarefaction")
})

# =============================================================================
# Section 6 - normalise to ps_srs
# =============================================================================
depth_floor <- 1000
keep <- colSums(counts_raw) >= depth_floor
counts_raw <- counts_raw[, keep, drop = FALSE]
counts_raw <- counts_raw[rowSums(counts_raw) > 0, , drop = FALSE]
taxonomy   <- taxonomy[rownames(counts_raw), , drop = FALSE]
metadata   <- metadata[colnames(counts_raw), , drop = FALSE]
ps_raw     <- phyloseq(otu_table(as.matrix(counts_raw), taxa_are_rows = TRUE),
                       tax_table(taxonomy), sample_data(metadata))

Cmin <- min(colSums(counts_raw))
cat(sprintf("Normalising to Cmin = %d reads\n", Cmin))
counts_srs <- SRS(as.data.frame(counts_raw), Cmin = Cmin, set_seed = TRUE)
counts_srs <- as.data.frame(counts_srs)
rownames(counts_srs) <- rownames(counts_raw)
colnames(counts_srs) <- colnames(counts_raw)
ps_srs <- phyloseq(otu_table(as.matrix(counts_srs), taxa_are_rows = TRUE),
                   tax_table(taxonomy), sample_data(metadata))
stopifnot(identical(sample_names(ps_raw), sample_names(ps_srs)))

step("Fig 06 library sizes before vs after SRS", {
  df <- data.frame(SampleID = colnames(counts_raw),
                   before = colSums(counts_raw), after = colSums(counts_srs),
                   Environment = metadata$Environment)
  dl <- pivot_longer(df, c(before, after), names_to = "stage", values_to = "reads")
  dl$stage <- factor(dl$stage, levels = c("before", "after"))
  dl$SampleID <- factor(dl$SampleID, levels = df$SampleID[order(df$before)])
  p <- ggplot(dl, aes(reads, SampleID)) +
    geom_line(aes(group = SampleID), colour = "grey70") +
    geom_point(aes(colour = Environment, shape = stage), size = 2.6) +
    geom_vline(xintercept = Cmin, linetype = 2, colour = "grey40") +
    scale_colour_manual(values = env_cols) +
    scale_shape_manual(values = c(before = 16, after = 1)) +
    scale_x_log10(labels = scales::label_number(scale_cut = scales::cut_short_scale())) +
    labs(x = "Total reads (log scale)", y = NULL,
         title = "Library sizes before vs after SRS",
         subtitle = paste0("open circles = after SRS, all scaled to Cmin = ",
                           format(Cmin, big.mark = ",")))
  save_gg(p, "06_srs_before_after", w = 8, h = 6)
})

# =============================================================================
# Section 7 - alpha diversity (Wilcoxon / Kruskal-Wallis, BH; brackets by hand)
# =============================================================================
alpha_div <- estimate_richness(ps_srs, measures = c("Observed", "Shannon"))
alpha_div$Environment <- sample_data(ps_srs)$Environment

brackets_for <- function(values, group, metric) {
  kw <- kruskal.test(values ~ group)
  out <- list(kw = kw, br = NULL)
  if (is.na(kw$p.value) || kw$p.value >= 0.05) return(out)
  pw <- pairwise.wilcox.test(values, group, p.adjust.method = "BH")$p.value
  st <- as.data.frame(as.table(pw)); names(st) <- c("group1", "group2", "p.adj")
  st <- st[!is.na(st$p.adj) & st$p.adj < 0.05, , drop = FALSE]
  if (nrow(st) == 0) return(out)
  lev <- levels(group)
  st$metric <- metric
  st$label  <- as.character(symnum(st$p.adj, corr = FALSE,
                  cutpoints = c(0, 0.0001, 0.001, 0.01, 0.05, 1),
                  symbols = c("****", "***", "**", "*", "ns")))
  ymax <- max(values, na.rm = TRUE); rng <- diff(range(values, na.rm = TRUE))
  st$y  <- ymax + rng * (0.10 + 0.12 * seq_len(nrow(st)))
  st$x1 <- match(as.character(st$group1), lev)
  st$x2 <- match(as.character(st$group2), lev)
  out$br <- st; out
}
b_obs <- brackets_for(alpha_div$Observed, alpha_div$Environment, "Observed")
b_sha <- brackets_for(alpha_div$Shannon,  alpha_div$Environment, "Shannon")
br <- bind_rows(b_obs$br, b_sha$br)
kw_lab <- data.frame(
  metric = c("Observed", "Shannon"),
  lab = c(sprintf("Kruskal-Wallis p = %.3g", b_obs$kw$p.value),
          sprintf("Kruskal-Wallis p = %.3g", b_sha$kw$p.value)))

# Write the alpha-diversity stats to disk so every caption number is checkable.
sink(file.path(script_dir, "alpha_stats.txt"))
cat("Alpha diversity tests, by Environment (SRS-normalised ps_srs)\n")
cat("\nGroup medians:\n")
print(aggregate(cbind(Observed, Shannon) ~ Environment, data = alpha_div, FUN = median))
cat("\n== Observed richness ==\nKruskal-Wallis:\n"); print(b_obs$kw)
cat("Pairwise Wilcoxon (BH-adjusted):\n")
print(pairwise.wilcox.test(alpha_div$Observed, alpha_div$Environment,
                           p.adjust.method = "BH")$p.value)
cat("\n== Shannon ==\nKruskal-Wallis:\n"); print(b_sha$kw)
cat("Pairwise Wilcoxon (BH-adjusted):\n")
print(pairwise.wilcox.test(alpha_div$Shannon, alpha_div$Environment,
                           p.adjust.method = "BH")$p.value)
sink()
cat(sprintf("alpha KW p: Observed=%.4g Shannon=%.4g\n", b_obs$kw$p.value, b_sha$kw$p.value))

step("Fig 07 alpha diversity", {
  ns    <- table(alpha_div$Environment)
  xlabs <- setNames(sprintf("%s\n(n=%d)", names(ns), as.integer(ns)), names(ns))
  ad <- pivot_longer(alpha_div, c(Observed, Shannon), names_to = "metric", values_to = "value")
  p <- ggplot(ad, aes(Environment, value)) +
    geom_boxplot(aes(colour = Environment, fill = Environment), alpha = 0.25, outlier.shape = NA) +
    geom_jitter(aes(colour = Environment), width = 0.15, height = 0, size = 2) +
    scale_colour_manual(values = env_cols) + scale_fill_manual(values = env_cols) +
    scale_x_discrete(labels = xlabs) +
    scale_y_continuous(expand = expansion(mult = c(0.05, 0.42))) +
    facet_wrap(~metric, scales = "free_y") +
    geom_text(data = kw_lab, aes(x = 0.5, y = Inf, label = lab), hjust = 0, vjust = 1.5,
              inherit.aes = FALSE, size = 3.2) +
    labs(x = NULL, y = "Diversity", title = "Alpha diversity by environment") +
    theme(legend.position = "none")
  if (nrow(br)) {
    p <- p +
      geom_segment(data = br, aes(x = x1, xend = x2, y = y, yend = y), inherit.aes = FALSE) +
      geom_text(data = br, aes(x = (x1 + x2) / 2, y = y, label = label),
                inherit.aes = FALSE, vjust = -0.2, size = 4)
  }
  save_gg(p, "07_alpha_diversity", w = 8, h = 5.5)
})

# =============================================================================
# Section 8 - beta diversity
# =============================================================================
dist_bray <- phyloseq::distance(ps_srs, method = "bray")
counts_raw_t <- t(as(otu_table(ps_raw), "matrix"))
dist_ait  <- vegdist(counts_raw_t, method = "robust.aitchison")

pcoa_bray <- ordinate(ps_srs, method = "PCoA", distance = dist_bray)
pcoa_ait  <- ordinate(ps_raw, method = "PCoA", distance = dist_ait)
pc_bray <- round(100 * pcoa_bray$values$Relative_eig[1:2], 1)
pc_ait  <- round(100 * pcoa_ait$values$Relative_eig[1:2], 1)

ord_plot <- function(ps, ord, pcs, title) {
  plot_ordination(ps, ord, color = "Environment") +
    geom_point(size = 3) +
    scale_colour_manual(values = env_cols) +
    stat_ellipse(type = "norm", linetype = 2) +
    labs(x = paste0("PCoA Axis 1 (", pcs[1], "%)"),
         y = paste0("PCoA Axis 2 (", pcs[2], "%)"), title = title, colour = "Environment")
}
p_bray <- ord_plot(ps_srs, pcoa_bray, pc_bray, "Bray-Curtis (SRS-normalised)")
p_ait  <- ord_plot(ps_raw,  pcoa_ait,  pc_ait,  "Aitchison (robust CLR, raw)")

# PERMANOVA (single-term ~ Environment; example has one grouping variable)
perm_free <- how(nperm = 9999)
pm_bray <- adonis2(dist_bray ~ Environment, data = data.frame(sample_data(ps_srs)),
                   permutations = perm_free, by = "terms")
pm_ait  <- adonis2(dist_ait ~ Environment, data = data.frame(sample_data(ps_raw)),
                   permutations = perm_free, by = "terms")
sink(file.path(script_dir, "permanova_results.txt"))
cat("PERMANOVA - Bray-Curtis (~ Environment)\n"); print(pm_bray)
cat("\nPERMANOVA - Aitchison (~ Environment)\n"); print(pm_ait)
sink()
r2b <- round(pm_bray$R2[1], 2); pb <- pm_bray$`Pr(>F)`[1]
r2a <- round(pm_ait$R2[1], 2);  pa <- pm_ait$`Pr(>F)`[1]
cat(sprintf("PERMANOVA Bray R2=%.2f p=%.4g | Aitchison R2=%.2f p=%.4g\n", r2b, pb, r2a, pa))

step("Fig 08 beta diversity PCoA", {
  p <- (p_bray + p_ait) +
    plot_layout(guides = "collect") +
    plot_annotation(title = sprintf(
      "PERMANOVA: Bray R2=%.2f p=%.3g ; Aitchison R2=%.2f p=%.3g", r2b, pb, r2a, pa)) &
    theme(legend.position = "bottom")
  save_gg(p, "08_beta_pcoa", w = 10, h = 5.5)
})

# Dispersion (betadisper) - SOP's ggplot centroid helper
plot_betadisper_centroids <- function(bd, title = "") {
  scrs <- as.data.frame(bd$vectors[, 1:2]) %>% rownames_to_column("sample") %>%
    mutate(group = bd$group); colnames(scrs)[2:3] <- c("Axis1", "Axis2")
  cents <- as.data.frame(bd$centroids[, 1:2]) %>% rownames_to_column("group")
  colnames(cents)[2:3] <- c("Axis1", "Axis2")
  rays <- scrs %>% left_join(cents, by = "group", suffix = c("", ".cent"))
  eig <- 100 * bd$eig / sum(bd$eig)
  ggplot() +
    geom_segment(data = rays, aes(x = Axis1, y = Axis2, xend = Axis1.cent, yend = Axis2.cent,
                                  colour = group), alpha = 0.5, linewidth = 0.3) +
    geom_point(data = scrs, aes(Axis1, Axis2, colour = group), size = 2, alpha = 0.85) +
    geom_point(data = cents, aes(Axis1, Axis2, fill = group), shape = 23, size = 4.5,
               colour = "black", stroke = 0.7) +
    scale_colour_manual(values = env_cols) + scale_fill_manual(values = env_cols) +
    labs(x = paste0("PCoA Axis 1 (", round(eig[1], 1), "%)"),
         y = paste0("PCoA Axis 2 (", round(eig[2], 1), "%)"),
         title = title, colour = NULL, fill = NULL) +
    theme(legend.position = "bottom")
}
disp_bray <- betadisper(dist_bray, sample_data(ps_srs)$Environment)
disp_ait  <- betadisper(dist_ait,  sample_data(ps_raw)$Environment)
pt_bray <- permutest(disp_bray); pt_ait <- permutest(disp_ait)
cat(sprintf("betadisper p: Bray=%.3g Aitchison=%.3g\n",
            pt_bray$tab$`Pr(>F)`[1], pt_ait$tab$`Pr(>F)`[1]))
# append the verbatim betadisper permutest tables to the raw stats file
sink(file.path(script_dir, "permanova_results.txt"), append = TRUE)
cat("\n\nbetadisper permutest - Bray-Curtis (~ Environment)\n"); print(pt_bray)
cat("\nbetadisper permutest - Aitchison (~ Environment)\n"); print(pt_ait)
sink()

step("Fig 09 dispersion (betadisper centroids)", {
  p <- (plot_betadisper_centroids(disp_bray, "Bray-Curtis dispersion") +
        plot_betadisper_centroids(disp_ait,  "Aitchison dispersion")) +
    plot_layout(guides = "collect") & theme(legend.position = "bottom")
  save_gg(p, "09_beta_dispersion", w = 10, h = 5.5)
})

# =============================================================================
# Section 9 - taxonomy barplot (top phyla by group)
# =============================================================================
step("Fig 10 taxonomy barplot", {
  ps_phy <- tax_glom(ps_srs, taxrank = "phylum", NArm = FALSE)
  ps_phy <- transform_sample_counts(ps_phy, function(x) x / sum(x))
  m <- psmelt(ps_phy)
  m$phylum <- as.character(m$phylum); m$phylum[is.na(m$phylum)] <- "Unassigned"
  top <- m %>% group_by(phylum) %>% summarise(a = sum(Abundance)) %>%
    arrange(desc(a)) %>% slice_head(n = 10) %>% pull(phylum)
  m$Phylum <- factor(ifelse(m$phylum %in% top, m$phylum, "Other"), levels = c(top, "Other"))
  cols <- setNames(pal11[seq_along(levels(m$Phylum))], levels(m$Phylum))
  cols["Other"] <- "#999999"
  p <- ggplot(m, aes(Sample, Abundance, fill = Phylum)) +
    geom_col(position = "fill", width = 1) +
    facet_grid(~Environment, scales = "free_x", space = "free_x") +
    scale_fill_manual(values = cols) +
    labs(x = NULL, y = "Relative abundance", title = "Phylum composition by environment") +
    theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1, size = 6),
          panel.grid = element_blank())
  save_gg(p, "10_taxonomy_barplot", w = 10, h = 6)
})

# =============================================================================
# Section 10 - differential abundance (ANCOM-BC2) - guarded
# =============================================================================
p_ancom <- NULL
if (HAVE_ANCOMBC) {
  step("Fig 11 ANCOM-BC2 log fold changes", {
    library(ANCOMBC)
    set.seed(123)
    da_ancom <- ancombc2(
      data = ps_raw, tax_level = "genus", fix_formula = "Environment",
      p_adj_method = "holm", prv_cut = 0.10, lib_cut = 1000, group = "Environment",
      struc_zero = TRUE, neg_lb = FALSE, alpha = 0.05,
      global = TRUE, pairwise = TRUE, pseudo_sens = TRUE, verbose = FALSE)
    res <- da_ancom$res
    contrasts <- grep("^lfc_Environment", names(res), value = TRUE)
    contrasts <- sub("^lfc_", "", contrasts)
    long <- bind_rows(lapply(contrasts, function(cn) data.frame(
      taxon = res$taxon, lfc = res[[paste0("lfc_", cn)]], se = res[[paste0("se_", cn)]],
      diff = res[[paste0("diff_", cn)]], pass = res[[paste0("passed_ss_", cn)]],
      contrast = sub("Environment", "", cn), stringsAsFactors = FALSE)))
    sig <- long %>% filter(diff == TRUE & pass == TRUE)
    write.table(sig, file.path(script_dir, "ancombc2_significant.tsv"),
                sep = "\t", quote = FALSE, row.names = FALSE)
    # full, unfiltered ANCOM-BC2 result table + a verbatim print of its head
    write.table(res, file.path(script_dir, "ancombc2_full_res.tsv"),
                sep = "\t", quote = FALSE, row.names = FALSE)
    sink(file.path(script_dir, "ancombc2_raw.txt"))
    cat("ANCOM-BC2 res (verbatim, first 30 rows of", nrow(res), "):\n"); print(head(res, 30))
    if (!is.null(da_ancom$res_global)) { cat("\nGlobal test (verbatim):\n"); print(da_ancom$res_global) }
    sink()
    cat(sprintf("ANCOM-BC2 significant (diff & passed_ss): %d taxon-contrasts\n", nrow(sig)))
    # keep the plot legible: top 12 by |lfc| within each contrast
    sig <- sig %>% group_by(contrast) %>% slice_max(abs(lfc), n = 12) %>% ungroup()
    sig$dir <- ifelse(sig$lfc > 0, "higher", "lower")
    sig$taxon <- factor(sig$taxon, levels = sig$taxon[order(sig$lfc)])
    p_ancom <<- ggplot(sig, aes(lfc, taxon, colour = dir)) +
      geom_vline(xintercept = 0, colour = "grey60") +
      geom_errorbarh(aes(xmin = lfc - se, xmax = lfc + se), height = 0) +
      geom_point(size = 2.4) +
      facet_wrap(~contrast, scales = "free_y") +
      scale_colour_manual(values = c(higher = "#D55E00", lower = "#0072B2")) +
      labs(x = "log fold change vs Human (reference)", y = NULL,
           title = "ANCOM-BC2 differential abundance (genus)",
           subtitle = "significant genera (diff & passed sensitivity); vs Human reference",
           colour = "vs Human") +
      theme(axis.text.y = element_text(size = 7))
    save_gg(p_ancom, "11_ancombc2_lfc", w = 10, h = 7)
  })
} else {
  cat("\n----- Section 10 SKIPPED: ANCOMBC not installed -----\n")
}

# =============================================================================
# Section 11 - indicator species (IndVal.g, FDR)
# =============================================================================
p_indic <- NULL
step("Fig 12 indicator species", {
  abund_indic <- as.data.frame(t(counts_srs))
  groups <- as.character(sample_data(ps_srs)$Environment)
  indval <- multipatt(abund_indic, groups, func = "IndVal.g", control = how(nperm = 9999))
  ind_res <- indval$sign
  ind_res$p.adjusted <- p.adjust(ind_res$p.value, method = "fdr")
  scol <- grep("^s\\.", names(ind_res), value = TRUE)
  grp_of <- apply(ind_res[, scol, drop = FALSE], 1, function(r)
    paste(sub("^s\\.", "", scol[r == 1]), collapse = "+"))
  ind_res$assoc <- grp_of
  ind_res$tax_id <- rownames(ind_res)
  sig <- ind_res[!is.na(ind_res$p.adjusted) & ind_res$p.adjusted < 0.05, ]
  cat(sprintf("Indicators: tested=%d, raw p<0.05=%d, FDR<0.05=%d\n",
              sum(!is.na(ind_res$p.value)), sum(ind_res$p.value < 0.05, na.rm = TRUE), nrow(sig)))
  # verbatim multipatt summary + full sign table with FDR
  sink(file.path(script_dir, "indicator_summary.txt"))
  cat("multipatt IndVal.g summary (verbatim):\n"); print(summary(indval))
  sink()
  write.table(data.frame(tax_id = rownames(ind_res), ind_res),
              file.path(script_dir, "indicator_all.tsv"),
              sep = "\t", quote = FALSE, row.names = FALSE)
  # label with best available rank
  lab_of <- function(id) {
    tx <- taxonomy[id, ]
    nm <- tx[["genus"]]; if (is.na(nm)) nm <- tx[["family"]]
    if (is.na(nm)) nm <- tx[["phylum"]]; if (is.na(nm)) nm <- "unclassified"
    paste0(nm, " (", id, ")")
  }
  sig$label <- vapply(sig$tax_id, lab_of, character(1))
  write.table(sig[, c("tax_id", "assoc", "stat", "p.value", "p.adjusted", "label")],
              file.path(script_dir, "indicator_species.tsv"),
              sep = "\t", quote = FALSE, row.names = FALSE)
  top <- sig[order(-sig$stat), ][seq_len(min(20, nrow(sig))), ]
  top$label <- factor(top$label, levels = rev(top$label))
  # colour by single-group associations; combos get grey
  top$assoc_col <- ifelse(top$assoc %in% names(env_cols), top$assoc, "combination")
  acols <- c(env_cols, combination = "#999999")
  p_indic <<- ggplot(top, aes(stat, label, fill = assoc_col)) +
    geom_col() +
    scale_fill_manual(values = acols) +
    labs(x = "IndVal.g statistic", y = NULL, fill = "Associated with",
         title = "Top indicator taxa (FDR < 0.05)") +
    theme(axis.text.y = element_text(size = 7))
  save_gg(p_indic, "12_indicator_species", w = 9, h = 7)
})

# =============================================================================
# Section 12 - a publication-style composite + sessionInfo
# =============================================================================
step("Fig 13 publication figure", {
  ad <- pivot_longer(alpha_div[, c("Shannon", "Environment")], "Shannon",
                     names_to = "metric", values_to = "value")
  p_sh <- ggplot(ad, aes(Environment, value, colour = Environment, fill = Environment)) +
    geom_boxplot(alpha = 0.25, outlier.shape = NA) +
    geom_jitter(width = 0.15, height = 0, size = 2) +
    scale_colour_manual(values = env_cols) + scale_fill_manual(values = env_cols) +
    labs(x = NULL, y = "Shannon", title = "Alpha diversity") +
    theme(legend.position = "none")
  panels  <- list(p_sh, p_bray + labs(title = "Beta diversity (Bray-Curtis)"))
  widths  <- c(1, 1)
  if (!is.null(p_ancom)) {
    p_ancom_c <- p_ancom +
      labs(title = "ANCOM-BC2 (genus)", subtitle = NULL, x = "LFC vs Human") +
      theme(axis.text.y = element_text(size = 6), strip.text = element_text(size = 8))
    panels <- c(panels, list(p_ancom_c)); widths <- c(1, 1, 1.3)
  }
  comp <- wrap_plots(panels, ncol = length(panels), widths = widths) +
    plot_annotation(tag_levels = "A",
      title = "GlobalPatterns worked example - key results") &
    theme(legend.position = "bottom")
  save_gg(comp, "13_publication_figure", w = 15, h = 5.8)
})

# =============================================================================
# SUPPLEMENTARY - core microbiome analysis (NOT a SOP_R_Analysis.md step)
# -----------------------------------------------------------------------------
# Extra worked example: the "core" microbiome is the set of taxa detected above
# an abundance threshold in a high fraction of samples. plot_core() shows, per
# genus, the prevalence reached across a sweep of detection thresholds. Uses the
# microbiome package. This lives only in examples/ - it is not embedded in the
# SOP, which has no core-microbiome step.
# =============================================================================
if (HAVE_MICROBIOME) {
  step("core microbiome (supplementary, no figure)", {
    library(microbiome)
    ps_gen  <- tax_glom(ps_srs, taxrank = "genus", NArm = TRUE)
    taxa_names(ps_gen) <- make.unique(as.character(tax_table(ps_gen)[, "genus"]))
    ps_comp <- microbiome::transform(ps_gen, "compositional")
    envs <- levels(sample_data(ps_comp)$Environment)
    dets <- 10^seq(log10(1e-4), log10(0.1), length = 12)
    # core size vs detection threshold, per environment (prevalence fixed at 50%)
    core_curve <- do.call(rbind, lapply(envs, function(g) {
      sub <- prune_samples(sample_data(ps_comp)$Environment == g, ps_comp)
      data.frame(Environment = g, detection = dets,
                 n_core = vapply(dets, function(d)
                   length(core_members(sub, detection = d, prevalence = 0.5)), integer(1)))
    }))
    core_curve$Environment <- factor(core_curve$Environment, levels = envs)
    core_tab <- sapply(envs, function(g) {
      sub <- prune_samples(sample_data(ps_comp)$Environment == g, ps_comp)
      length(core_members(sub, detection = 0.001, prevalence = 0.5))
    })
    cat("Core genera per environment (det 0.1%, prev 50%):\n"); print(core_tab)
    writeLines(capture.output(print(core_tab)),
               file.path(script_dir, "core_microbiome.txt"))
    # Core-microbiome figure removed: it was an orphan (no SOP section embeds it).
    # The core_microbiome.txt summary above is kept as a supplementary output.
  })
} else {
  cat("\n----- core microbiome SKIPPED: microbiome not installed -----\n")
}

# =============================================================================
# SOP Section 12 - SPIEC-EASI co-occurrence network
# -----------------------------------------------------------------------------
# SOP_R_Analysis.md Section 12 presents SPIEC-EASI as the compositionally correct
# way to infer taxon-taxon associations (vs Pearson/Spearman on proportions) and
# embeds this figure (figures/14_spieceasi_network.png) as its expected output.
# Worked network on the most prevalent genera. Illustrative: n = 20 samples is
# modest for network inference, and because samples span three very different
# environments, many associations partly reflect shared habitat rather than
# direct ecological interaction.
# =============================================================================
if (requireNamespace("SpiecEasi", quietly = TRUE) &&
    requireNamespace("igraph", quietly = TRUE) &&
    requireNamespace("ggraph", quietly = TRUE)) {
  step("Fig 14 SPIEC-EASI network", {
    library(SpiecEasi); library(igraph); library(ggraph); library(tidygraph)
    set.seed(42)
    # genus level; keep the most prevalent genera for a tractable, readable network
    ps_g <- tax_glom(ps_raw, taxrank = "genus", NArm = TRUE)
    taxa_names(ps_g) <- make.unique(as.character(tax_table(ps_g)[, "genus"]))
    prev <- rowSums(as(otu_table(ps_g), "matrix") > 0)
    keep <- names(sort(prev, decreasing = TRUE))[seq_len(min(50, ntaxa(ps_g)))]
    ps_net <- prune_taxa(keep, ps_g)
    otu <- t(as(otu_table(ps_net), "matrix"))          # samples x taxa; SpiecEasi clr's internally
    se  <- spiec.easi(otu, method = "mb", lambda.min.ratio = 1e-2, nlambda = 20,
                      pulsar.params = list(rep.num = 20, seed = 42))
    beta <- as.matrix(SpiecEasi::symBeta(SpiecEasi::getOptBeta(se), mode = "maxabs"))
    rownames(beta) <- colnames(beta) <- colnames(otu)
    g <- graph_from_adjacency_matrix(beta, mode = "undirected", weighted = TRUE, diag = FALSE)
    g <- delete_vertices(g, igraph::degree(g) == 0)    # drop isolated nodes
    if (vcount(g) < 2 || ecount(g) < 1) stop("network has no edges at this sparsity")
    # tax_glom NAs ranks below the glom rank; with a finest-first (Emu) taxonomy
    # that includes phylum, so map each genus back to its phylum from ps_raw.
    orig <- as(tax_table(ps_raw), "matrix")
    g2p  <- tapply(orig[, "phylum"], orig[, "genus"],
                   function(x) { x <- x[!is.na(x)]; if (length(x)) names(sort(table(x), decreasing = TRUE))[1] else NA })
    ph <- unname(g2p[sub("\\.[0-9]+$", "", V(g)$name)]); ph[is.na(ph)] <- "Unassigned"
    V(g)$phylum <- ph
    V(g)$deg    <- igraph::degree(g)
    E(g)$sign   <- ifelse(E(g)$weight > 0, "positive", "negative")
    E(g)$weight <- abs(E(g)$weight)                    # FR layout needs positive weights (strength)
    # label only the hub genera (top degree) to keep the plot readable
    hub_n  <- names(sort(igraph::degree(g), decreasing = TRUE))[seq_len(min(10, vcount(g)))]
    V(g)$lab <- ifelse(V(g)$name %in% hub_n, V(g)$name, "")
    # collapse rare phyla to Other for a colour-blind-safe legend
    topph <- names(sort(table(ph), decreasing = TRUE))[seq_len(min(9, length(unique(ph))))]
    V(g)$phy_lab <- ifelse(ph %in% topph, ph, "Other")
    lvls <- c(setdiff(sort(unique(V(g)$phy_lab)), "Other"),
              if ("Other" %in% V(g)$phy_lab) "Other")
    ncol <- setNames(pal11[seq_along(lvls)], lvls)
    if ("Other" %in% names(ncol)) ncol["Other"] <- "#999999"
    # stats + edge list to disk
    npos <- sum(E(g)$sign == "positive"); nneg <- sum(E(g)$sign == "negative")
    sink(file.path(script_dir, "spieceasi_network_stats.txt"))
    cat(sprintf("SPIEC-EASI (mb) network on %d prevalent genera, %d samples\n",
                length(keep), nrow(otu)))
    cat(sprintf("nodes (non-isolated): %d | edges: %d (%d positive, %d negative)\n",
                vcount(g), ecount(g), npos, nneg))
    cat(sprintf("edge density: %.3f | mean degree: %.2f\n",
                edge_density(g), mean(igraph::degree(g))))
    cat("hub genera (by degree):\n"); print(sort(igraph::degree(g), decreasing = TRUE)[seq_len(min(10, vcount(g)))])
    sink()
    el <- igraph::as_data_frame(g, what = "edges")
    write.table(el, file.path(script_dir, "spieceasi_edges.tsv"),
                sep = "\t", quote = FALSE, row.names = FALSE)
    cat(sprintf("SPIEC-EASI network: %d nodes, %d edges (%d+/%d-)\n",
                vcount(g), ecount(g), npos, nneg))
    tg <- as_tbl_graph(g)
    p_net <- ggraph(tg, layout = "fr") +
      geom_edge_link(aes(colour = sign), width = 0.4, alpha = 0.6) +
      geom_node_point(aes(fill = factor(phy_lab, levels = lvls), size = deg),
                      shape = 21, colour = "grey20") +
      geom_node_text(aes(label = lab), size = 2.4, colour = "black") +
      scale_edge_colour_manual(values = c(positive = "#0072B2", negative = "#D55E00")) +
      scale_fill_manual(values = ncol, drop = FALSE) +
      scale_size(range = c(2, 7)) +
      labs(title = "SPIEC-EASI co-occurrence network (Section 12) — GlobalPatterns worked example",
           subtitle = "top prevalent genera; n=20 across 3 environments — illustrative, associations partly reflect habitat",
           fill = "Phylum", edge_colour = "Association", size = "Degree") +
      theme_void() + theme(legend.position = "right")
    save_gg(p_net, "14_spieceasi_network", w = 11, h = 8)
  })
} else {
  cat("\n----- Fig 14 SPIEC-EASI SKIPPED: SpiecEasi/igraph/ggraph not all installed -----\n")
}

writeLines(capture.output(sessionInfo()), file.path(script_dir, "sessionInfo.txt"))

cat("\n=============================================================\n")
cat(sprintf("Figures produced (%d):\n  %s\n", length(produced), paste(produced, collapse = "\n  ")))
cat("Done.\n")
