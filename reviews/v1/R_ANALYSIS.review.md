## Document: SOP_R_Analysis.md

This is meant to be the lab's single downstream tutorial: a reader arrives with three
files and leaves with defensible statistics, figures and a methods paragraph. The
explanatory writing is genuinely good — the compositionality worked example (L818-820),
the rarefaction/rarefying distinction (L331-336) and the `ps_raw`/`ps_srs` rule (L55) are
the best content in the repository. The code has not been held to the same standard.
Sample order between `counts_raw` and `metadata` is never enforced but is relied on
positionally in three places; the pairwise PERMANOVA claims a multiple-testing correction
it does not apply; the indicator-species FDR is computed on a pre-filtered subset; the two
differential abundance methods whose "consensus" is the headline recommendation are run at
different taxonomic ranks. Every one of those produces a plausible number and no error
message, which is exactly the failure mode this repository says it fears most. **The single
change that would most improve the document is to make sample identity explicit and
enforced once, in Stage 1, and then to derive every grouping vector from a phyloseq object
rather than from a free-standing `metadata` data frame.** That one discipline closes F-01,
F-02 and F-07 and removes the class of defect entirely.

## Section ledger

| § | Heading | Lines | Verdict | Findings |
|---|---|---|---|---|
| — | Front matter | 1-9 | REWRITE | F-09, F-25; also the known calibration defect at L5 (`SOP_NeSI_Pipeline.md`) |
| — | Quick Roadmap: What You'll Do | 11-36 | RESTRUCTURE | F-08, F-15 |
| — | Key objects you'll work with | 38-56 | TIGHTEN | F-34 |
| 5 | Analysis of Amplicon/Count Data in R (intro) | 59-61 | REWRITE | F-09 |
| 5.x | Installing and loading libraries | 63-96 | TIGHTEN | F-26, F-27 |
| 5.x | Stage 1: Loading and preparing your data | 98-192 | EXPAND | F-01 (fix lands here), F-16, F-28 |
| 5.x | Stage 2: Decontamination and building the phyloseq object | 194-261 | REWRITE | F-01, F-17, F-18, F-19, F-29 |
| 5.x | Stage 3: Exploring your data before analysis | 263-321 | REWRITE | F-10 |
| 5.x | Stage 4: Normalisation | 323-390 | REWRITE | F-02, F-11, F-31, F-32 |
| 5.x | Alpha diversity | 392-467 | REWRITE | F-03, F-12, F-33 |
| 5.x | Beta diversity (intro) | 469-473 | CLEAN | — |
| 5.x | Step 1: Distance matrices | 475-498 | CLEAN | — |
| 5.x | Step 2: Ordination | 500-571 | TIGHTEN | F-11, F-20 |
| 5.x | Step 3: Check dispersion | 573-670 | CLEAN | — |
| 5.x | Step 4: PERMANOVA | 672-717 | TIGHTEN | F-21, F-22, F-30 |
| 5.x | Step 5: Pairwise PERMANOVA (for >2 groups) | 719-738 | REWRITE | F-04 |
| 5.x | Step 6 (optional): Jaccard as a third lens | 740-771 | TIGHTEN | F-13 |
| 5.x | Taxonomy barplots | 773-808 | TIGHTEN | F-23 |
| 6 | Going Further in R (intro) | 810-812 | CLEAN | — |
| 6.x | Why you can't just test each taxon individually | 814-831 | TIGHTEN | F-14 |
| 6.x | Differential abundance with ANCOM-BC2 | 833-887 | REWRITE | F-05, F-16, F-24 |
| 6.x | Differential abundance with MaAsLin2 | 889-934 | REWRITE | F-06, F-35, F-36 |
| 6.x | A note on ALDEx2 | 936-938 | CLEAN | — |
| 6.x | Indicator species analysis | 940-976 | REWRITE | F-01, F-07 |
| 6.x | Figures | 978-987 | CLEAN | — |
| 6.x | Reproducibility | 989-997 | CLEAN | — |
| — | Common Pitfalls to Avoid | 999-1027 | CLEAN | — (target of F-08's broken pointer) |

## Findings

### F-01 · S1 · Metadata row order never matched to count-table column order
- **Where:** SOP_R_Analysis.md:202-222, § Stage 2; consumed again at SOP_R_Analysis.md:958, § Indicator species analysis
- **Quote:**
  > is_blank <- metadata$SampleType == "blank"
  > …
  > contam_df <- isContaminant(t(counts_raw), neg = is_blank, method = "prevalence")
  > …
  > counts_raw <- counts_raw[, !is_blank]
  > metadata   <- metadata[!is_blank, ]
- **Defect:** `is_blank` is built in `metadata` row order and then used to index `counts_raw`
  columns and to label rows of `t(counts_raw)`, but nothing anywhere before this point
  reorders `metadata` to match `colnames(counts_raw)`. The same positional assumption is
  made again at L958 (`groups <- metadata$Site`). The document knows the correct idiom —
  `metadata <- metadata[colnames(counts_raw), ]` appears at L381 — but only inside a
  commented-out block, in Stage 4, long after the damage is done.
- **Failure:** Reader's barcodes are not zero-padded, so `combine_emu_results.py` emits
  columns in lexicographic order (`barcode1, barcode10, barcode11, barcode12, barcode2, …`)
  while the metadata file was typed in numeric order (`barcode1, barcode2, …`). Both objects
  have 12 entries, so nothing errors. `neg = is_blank` marks the wrong column as the blank,
  decontam removes taxa that are abundant in a real sample, `counts_raw[, !is_blank]` drops
  a real sample and keeps the blank, and at L958 every sample is assigned another sample's
  Site. The reader gets a complete, plausible set of indicator species for the wrong sites
  and no warning at any stage.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — `metadata` is created at L139-140 by `read.table` and is never
  reordered against `counts_raw` anywhere between L140 and L202; the only reordering line in
  the document (L381) is commented out and sits 179 lines later.
- **Fix:** Insert immediately after the metadata `read.table` call at L140, before the
  factor-level block:

  ```r
  # Metadata rows and count-table columns must describe the same samples in the
  # same order. decontam's `neg` vector, the blank-removal step and the indicator
  # species grouping all index them POSITIONALLY, so a mismatch here produces a
  # complete set of wrong results with no error message.
  missing_meta <- setdiff(colnames(counts_raw), rownames(metadata))
  missing_cnts <- setdiff(rownames(metadata), colnames(counts_raw))
  if (length(missing_meta) > 0 || length(missing_cnts) > 0) {
      cat("In counts but not metadata:", paste(missing_meta, collapse = ", "), "\n")
      cat("In metadata but not counts:", paste(missing_cnts, collapse = ", "), "\n")
      stop("Sample names do not match. Fix the names before going any further.")
  }

  # Put metadata rows in the same order as the count-table columns.
  metadata <- metadata[colnames(counts_raw), , drop = FALSE]
  stopifnot(identical(rownames(metadata), colnames(counts_raw)))
  ```

  and change L958 to take the grouping from the phyloseq object, which cannot drift:

  ```r
  groups      <- as.character(sample_data(ps_srs)$Site)
  ```

### F-02 · S1 · Dropping a shallow sample in Stage 4 leaves `ps_raw` stale
- **Where:** SOP_R_Analysis.md:379-381, § Stage 4: Normalisation
- **Quote:**
  > # If Cmin is very low (<1,000), consider removing that sample and recalculating:
  > # counts_raw <- counts_raw[, colSums(counts_raw) > 1000]
  > # metadata   <- metadata[colnames(counts_raw), ]
- **Defect:** `ps_raw` was built in Stage 2 (L232-234) and is never rebuilt. This snippet —
  which the prose at L340 tells the reader to use ("consider removing it and recalculating")
  — updates `counts_raw` and `metadata` but not `ps_raw`, so from here on `ps_srs` holds
  n-1 samples while `ps_raw` holds n. The document itself names this exact hazard at L593:
  "will fail silently if you ever drop or reorder samples between the two."
- **Failure:** Reader has one sample at 400 reads, follows L340, uncomments L380-381, and
  continues. `dist_bray` (from `ps_srs`) covers 11 samples; `dist_ait` (from `ps_raw`, L492)
  covers 12. Both `adonis2` calls run without error. The reader writes "community
  composition differed by site under both Bray-Curtis (R² = 0.31, p = 0.03) and Aitchison
  (R² = 0.28, p = 0.04)" — two results computed on different datasets, presented as
  agreement. MaAsLin2 (on `counts_raw`, 11 samples) and ANCOM-BC2 (on `ps_raw`, 12 samples)
  diverge for the same reason.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — `ps_raw` is assigned once, at L232, and no later line
  reassigns it; `dist_ait` at L492 reads from `ps_raw` while `dist_bray` at L489 reads from
  `ps_srs`.
- **Fix:** Replace L376-390 with a block that gates on depth and rebuilds both objects:

  ```r
  # Depth gate. Apply this BEFORE normalising, and rebuild ps_raw from the
  # filtered tables — ps_raw and ps_srs must always hold the same samples.
  # 1,000 reads is the floor flagged in Stage 3: below that, richness estimates
  # are dominated by sampling effort rather than biology.
  depth_floor <- 1000
  keep <- colSums(counts_raw) >= depth_floor
  if (any(!keep)) {
      cat("Dropping", sum(!keep), "sample(s) below", depth_floor, "reads:",
          paste(colnames(counts_raw)[!keep], collapse = ", "), "\n")
  }
  counts_raw <- counts_raw[, keep, drop = FALSE]
  counts_raw <- counts_raw[rowSums(counts_raw) > 0, , drop = FALSE]
  taxonomy   <- taxonomy[rownames(counts_raw), , drop = FALSE]
  metadata   <- metadata[colnames(counts_raw), , drop = FALSE]

  # Rebuild ps_raw. Do not skip this line: every Aitchison and differential
  # abundance step below reads from ps_raw, and a stale ps_raw will run
  # without error on the samples you thought you had removed.
  ps_raw <- phyloseq(otu_table(counts_raw, taxa_are_rows = TRUE),
                     tax_table(taxonomy),
                     sample_data(metadata))

  Cmin <- min(colSums(counts_raw))
  cat("Normalising to:", Cmin, "reads\n")

  counts_srs <- SRS(counts_raw, Cmin = Cmin, set_seed = TRUE)
  counts_srs <- as.data.frame(counts_srs)
  rownames(counts_srs) <- rownames(counts_raw)
  colnames(counts_srs) <- colnames(counts_raw)

  ps_srs <- phyloseq(otu_table(counts_srs, taxa_are_rows = TRUE),
                     tax_table(taxonomy),
                     sample_data(metadata))

  # Both objects must now agree on samples. If this stops, do not continue.
  stopifnot(identical(sample_names(ps_raw), sample_names(ps_srs)))
  ```

### F-03 · S1 · Figure significance stars are ungated and uncorrected, unlike the reported test
- **Where:** SOP_R_Analysis.md:404-436, § Alpha diversity
- **Quote:**
  > For three or more groups, first run a **Kruskal-Wallis** omnibus test; only proceed to pairwise Wilcoxon comparisons if it is significant (p < 0.05).
  >
  > …
  >
  > pairwise.wilcox.test(alpha_div$Observed, alpha_div$Site,
  >                      p.adjust.method = "BH")
  >
  > …
  >     stat_compare_means(method      = "wilcox.test",
  >                        comparisons = site_comparisons,
  >                        label       = "p.signif",
  >                        symnum.args = symnum.args)
- **Defect:** The text states a two-stage, BH-corrected procedure, and the console code at
  L416-417 implements it. The plotting code then draws all three pairwise brackets
  unconditionally — no Kruskal-Wallis gate — and labels them from `stat_compare_means`,
  which runs its own pairwise Wilcoxon tests independent of the BH-adjusted matrix computed
  two blocks earlier. The figure and the reported statistic are two different analyses of the
  same data.
- **Failure:** Kruskal-Wallis returns p = 0.14. The reader follows L415 and does not report
  pairwise results in the text. They then run the plotting block, which prints a `*` over
  Takapourewa vs Zealandia (raw p = 0.04, BH-adjusted p = 0.12), and that figure goes into
  the thesis. The claim in the figure contradicts the claim in the text, both derived from
  the document as written, with no error at any point. (Whether `stat_compare_means`
  additionally leaves the bracket p-values unadjusted is worth confirming with
  `?ggpubr::stat_compare_means`; the gating contradiction stands regardless.)
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — L404 makes pairwise testing conditional on the omnibus result;
  L428-436 contains no conditional, and `stat_compare_means` is passed `comparisons` rather
  than the object returned at L416.
- **Fix:** Replace L406-448 with:

  ```r
  # Compute alpha diversity on the SRS-normalised object
  alpha_div      <- estimate_richness(ps_srs, measures = c("Observed", "Shannon"))
  alpha_div$Site <- sample_data(ps_srs)$Site
  alpha_div$Sex  <- sample_data(ps_srs)$Sex

  # Omnibus test for >2 groups
  kw_obs <- kruskal.test(Observed ~ Site, data = alpha_div)
  print(kw_obs)

  # BH-adjusted pairwise p-values. These are the numbers you report AND the
  # numbers the figure must show — do not let ggpubr compute a second,
  # unadjusted set behind your back.
  pw_obs <- pairwise.wilcox.test(alpha_div$Observed, alpha_div$Site,
                                 p.adjust.method = "BH")$p.value
  print(pw_obs)

  # Reshape the adjusted matrix into the form stat_pvalue_manual() expects
  stat_obs <- as.data.frame(as.table(pw_obs), stringsAsFactors = FALSE)
  names(stat_obs) <- c("group1", "group2", "p.adj")
  stat_obs <- stat_obs[!is.na(stat_obs$p.adj), , drop = FALSE]
  stat_obs$p.adj.signif <- as.character(
      symnum(stat_obs$p.adj, corr = FALSE,
             cutpoints = c(0, 0.0001, 0.001, 0.01, 0.05, 1),
             symbols   = c("****", "***", "**", "*", "ns")))
  ymax <- max(alpha_div$Observed)
  stat_obs$y.position <- ymax * (1.05 + 0.09 * seq_len(nrow(stat_obs)))

  p_obs <- plot_richness(ps_srs, x = "Site", measures = "Observed") +
      geom_boxplot() + stat_n_text() + theme_bw() +
      theme(legend.title = element_blank(), legend.position = "none",
            strip.background = element_blank(), strip.text.x = element_blank()) +
      xlab("Site") + ylab("Observed richness")

  # Brackets only if the omnibus test passed; labels from the BH-adjusted matrix.
  if (kw_obs$p.value < 0.05) {
      p_obs <- p_obs + stat_pvalue_manual(stat_obs, label = "p.adj.signif")
  } else {
      p_obs <- p_obs + labs(caption = sprintf(
          "Kruskal-Wallis p = %.3f; no pairwise comparisons shown", kw_obs$p.value))
  }
  p_obs

  # Shannon: identical pattern. Swap Observed -> Shannon in kruskal.test(),
  # pairwise.wilcox.test(), ymax and plot_richness(measures = "Shannon").
  ```

  Then change L450's sentence to read: "Asterisks mark BH-adjusted significance:
  \* p < 0.05, \*\* p < 0.01, \*\*\* p < 0.001, \*\*\*\* p < 0.0001, `ns` not significant.
  Brackets appear only when the Kruskal-Wallis omnibus test was significant, so the figure
  and the reported statistics always agree."

### F-04 · S1 · `p.adjust.m` is not an argument of `pairwise.adonis2`, so no correction happens
- **Where:** SOP_R_Analysis.md:728-738, § Step 5: Pairwise PERMANOVA
- **Quote:**
  > pairwise.adonis2(dist_bray ~ Site,
  >                  data       = data.frame(sample_data(ps_srs)),
  >                  p.adjust.m = "BH")
  > …
  > `p.adjust.m = "BH"` applies Benjamini-Hochberg correction.
- **Defect:** `pairwise.adonis2()` runs a separate `adonis2` per group pair and returns their
  raw permutation p-values; it has no `p.adjust.m` parameter. The name is absorbed by the
  `...` that `pairwise.adonis2` forwards to `adonis2`, which also has `...`, so the argument
  is silently discarded. (`p.adjust.m` belongs to the other function in the same package,
  `pairwise.adonis()`.) The call also drops `perm_free`, so it uses the package default
  permutation count rather than the 9,999 the document standardises on at L694-695.
- **Failure:** Three sites give three pairwise comparisons. Raw p-values 0.012, 0.031, 0.048
  come back; the reader, told at L738 that BH has been applied, reports all three as
  significant after correction. Under actual BH correction the third is p = 0.048 and the
  second p = 0.047 — but with six comparisons across two metrics the difference is larger,
  and with a marginal comparison the correction changes the conclusion. Nothing in the output
  is labelled "adjusted", so there is no cue that the correction never ran.
- **Type:** CORRECTNESS
- **Confidence:** NEEDS-BENCH-CHECK — run `args(pairwiseAdonis::pairwise.adonis2)` in the
  installed package; if `p.adjust.m` is not in the formal arguments, the correction is not
  applied. (`args(pairwiseAdonis::pairwise.adonis)` will show where the argument does exist.)
- **Fix:** Replace L723-738 with:

  ```r
  # devtools::install_github("pmartinezarbizu/pairwiseAdonis/pairwiseAdonis")
  library(pairwiseAdonis)

  # pairwise.adonis2() returns RAW p-values, one adonis2 fit per group pair, and
  # has no p-adjustment argument — anything passed as `p.adjust.m` is silently
  # swallowed. Correct the p-values yourself, or you will report uncorrected
  # pairwise tests as if they were corrected.
  adjust_pairwise <- function(pa) {
      pa  <- pa[names(pa) != "parent_call"]
      out <- data.frame(
          pair = names(pa),
          R2   = sapply(pa, function(x) x$R2[1]),
          F    = sapply(pa, function(x) x$F[1]),
          p    = sapply(pa, function(x) x$`Pr(>F)`[1]),
          row.names = NULL)
      out$p.adj <- p.adjust(out$p, method = "BH")
      out
  }

  # Bray-Curtis
  pa_bray <- pairwise.adonis2(dist_bray ~ Site,
                              data  = data.frame(sample_data(ps_srs)),
                              nperm = 9999)
  adjust_pairwise(pa_bray)

  # Aitchison
  pa_ait <- pairwise.adonis2(dist_ait ~ Site,
                             data  = data.frame(sample_data(ps_raw)),
                             nperm = 9999)
  adjust_pairwise(pa_ait)
  ```

  and replace the sentence at L738 with: "Report the `p.adj` column, not `p`. The output
  shows which pairs differ; you might find Takapourewa vs Zealandia significant
  (p.adj = 0.03) but Zealandia vs Young Nicks Head not (p.adj = 0.45). If `adjust_pairwise`
  errors on a column name, run `head(pa_bray[[1]])` — vegan has changed the `adonis2` result
  column labels between releases."

### F-05 · S1 · `neg_lb = TRUE` contradicts the sample-size caveat printed six lines below it
- **Where:** SOP_R_Analysis.md:854 and 872, § Differential abundance with ANCOM-BC2
- **Quote:**
  >     neg_lb       = TRUE,
  > …
  > - `neg_lb = TRUE` uses the negative lower bound for bias estimation. Recommended with ≥30 samples per group; with smaller groups the estimate may be unstable.
- **Defect:** The code block sets the non-default option, and the parameter list immediately
  afterwards says that option needs ≥30 samples per group. The document's own worked example
  has 12 samples (L242) across three sites (L421-423) — about four per group, an order of
  magnitude below the stated requirement. A reader copying the code block, which is what the
  tutorial format invites, gets the setting the text warns them off.
- **Failure:** With four samples per site, the asymptotic lower bound declares taxa
  "structurally zero" in a group on the strength of a handful of observations. Those taxa
  come back in `da_ancom$res` with large log fold changes and `diff_ = TRUE`. The reader
  reports "*Campylobacter* was absent from Zealandia" when it was present in one of the four
  Zealandia samples and simply not sampled in the other three. No warning is emitted.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — the code at L854 and the guidance at L872 are in direct
  conflict for the sample size the document itself works with at L242.
- **Fix:** Change L854 to:

  ```r
      neg_lb       = FALSE,              # see note below — do not flip this on small designs
  ```

  and replace the bullet at L872 with:

  "- `neg_lb = FALSE` is the default and what this workflow uses. It controls whether an
  asymptotic lower bound is used when deciding that a taxon is structurally zero in a group.
  The ANCOMBC documentation recommends `TRUE` only when each group holds roughly 30 or more
  samples; below that the bound is unstable and declares extra structural zeros, which then
  appear in your results as strong, highly significant differences that are really just
  under-sampling. Set it to `TRUE` only if every level of `group` has ≥30 samples, and check
  `?ancombc2` for the exact wording in your installed version."

### F-06 · S1 · ANCOM-BC2 runs at genus level, MaAsLin2 at species level, and the two are compared
- **Where:** SOP_R_Analysis.md:905, § Differential abundance with MaAsLin2 (against L847 and L831)
- **Quote:**
  > maaslin_counts <- as.data.frame(t(counts_raw))
- **Defect:** ANCOM-BC2 is given `tax_level = "genus"` (L847) and therefore aggregates before
  testing. MaAsLin2 is given `counts_raw`, which is the un-aggregated Emu table — one row per
  tax_id, i.e. species-level. The document's stated approach is "run ANCOM-BC2 and MaAsLin2
  and report the consensus" (L831, repeated at L1009), but a consensus requires the two
  methods to have tested the same features. They have not.
- **Failure:** ANCOM-BC2 returns significant genera (`Bacteroides`, `Prevotella`). MaAsLin2
  returns significant species-level rows (`Bacteroides fragilis`, `Bacteroides uniformis`,
  each individually below the prevalence filter's power). The reader tries to intersect the
  two lists, finds almost no overlap, and concludes either that the effect is not robust
  (false negative, real signal discarded) or picks whichever list supports the hypothesis.
  Both runs complete normally.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — L847 sets `tax_level = "genus"`; L905 passes the untransformed
  `counts_raw`, whose rows are the Emu tax_ids read in at L111-123.
- **Fix:** Replace L904-906 with:

  ```r
  # MaAsLin2 needs features (taxa) as COLUMNS, samples as ROWS — and it must test
  # the SAME taxonomic rank as ANCOM-BC2, or the two result lists cannot be
  # compared and "consensus" means nothing. ANCOM-BC2 above used tax_level =
  # "genus", so aggregate to genus here.
  ps_genus <- tax_glom(ps_raw, taxrank = "genus", NArm = FALSE)
  taxa_names(ps_genus) <- make.unique(as.character(tax_table(ps_genus)[, "genus"]))

  maaslin_counts <- as.data.frame(t(as(otu_table(ps_genus), "matrix")))
  maaslin_meta   <- as.data.frame(as(sample_data(ps_genus), "data.frame"))
  ```

  and add after the parameter list at L932: "If you change `tax_level` in the ANCOM-BC2 call,
  change `taxrank` here to match. Running the two methods at different ranks is the easiest
  way to manufacture a false disagreement between them."

### F-07 · S1 · Indicator-species FDR correction applied only to the already-significant subset
- **Where:** SOP_R_Analysis.md:969-975, § Indicator species analysis
- **Quote:**
  > `multipatt` does not correct for multiple testing internally, so apply FDR correction:
  >
  > sig_indicators            <- indval$sign[indval$sign$p.value < 0.05, ]
  > sig_indicators$p.adjusted <- p.adjust(sig_indicators$p.value, method = "fdr")
  > sig_indicators_fdr        <- sig_indicators[sig_indicators$p.adjusted < 0.05, ]
- **Defect:** Benjamini-Hochberg is applied to the p-values that already passed p < 0.05, not
  to all taxa tested. BH scales each p-value by the number of tests; filtering first shrinks
  that number to only the smallest p-values, so the correction is far weaker than the one the
  reader believes they applied. The line above the block explicitly promises multiple-testing
  correction, which makes the error harder to spot.
- **Failure:** 400 taxa are tested; 30 have raw p < 0.05. BH on those 30 multiplies the
  largest by 30/30 = 1 and the smallest by 30/1, so roughly 25 of the 30 survive at
  `p.adjusted < 0.05`. Correct BH across all 400 leaves perhaps 3. The reader reports 25
  FDR-corrected indicator species; about 20 of them are the ~20 false positives you expect
  from 400 tests at α = 0.05. The output is a clean table with a column headed `p.adjusted`.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — `sig_indicators` is created by the filter on L972 and is the
  input to `p.adjust` on L973; `indval$sign` (all tested taxa) is never passed to `p.adjust`.
- **Fix:** Replace L971-976 with:

  ```r
  # Correct across EVERY taxon tested, not just the ones that already passed
  # p < 0.05 — filtering before adjusting shrinks the number of tests BH divides
  # by and inflates the number of "significant" indicators several-fold.
  ind_res             <- indval$sign
  ind_res$p.adjusted  <- p.adjust(ind_res$p.value, method = "fdr")

  sig_indicators_fdr  <- ind_res[!is.na(ind_res$p.adjusted) &
                                 ind_res$p.adjusted < 0.05, ]
  cat("Taxa tested:", sum(!is.na(ind_res$p.value)),
      "| raw p < 0.05:", sum(ind_res$p.value < 0.05, na.rm = TRUE),
      "| FDR < 0.05:", nrow(sig_indicators_fdr), "\n")
  print(sig_indicators_fdr)
  ```

### F-08 · S2 · Non-independent designs are sent to a section that does not cover them
- **Where:** SOP_R_Analysis.md:36, § Quick Roadmap
- **Quote:**
  > If your samples are not independent (repeated measures, co-housed animals, nested designs), the diversity and PERMANOVA steps need restricted permutations and the differential abundance models need random effects; see the Common Pitfalls section for the key considerations.
- **Defect:** Common Pitfalls (L999-1027) mentions mixed models twice, in one clause each
  (L1001, L1027), and never mentions restricted permutations at all. The only treatment of
  restricted permutations is three prose bullets at L680-682 that name `permute::how()` with
  `blocks = Subject` but show no code, while the only permutation scheme actually defined in
  the document is `perm_free <- how(nperm = 9999)` (L695). The install block at L83 tells the
  reader to install `lme4`, `lmerTest`, `emmeans`, `broom` and `broom.mixed`; not one of them
  is used anywhere in the document.
- **Failure:** A student with three swabs per tuatara reads L36, goes to Common Pitfalls, is
  told to "use a mixed model with the grouping variable as a random effect" and nothing else,
  goes back to Step 4, finds only `perm_free`, and either runs the free-permutation PERMANOVA
  anyway (inflated false positive rate, exactly what L684 warns about) or stops. The document
  has raised the problem three times and solved it zero times.
- **Type:** GAP
- **Confidence:** CONFIRMED — searching the document for `blocks`, `lmer`, `random_effects`
  outside a comment returns only L681 (prose), L914 (a commented-out argument) and L1001/1027
  (prose); no runnable example exists.
- **Fix:** Change L36 to end "…see *Non-independent designs* at the end of Step 4." and add
  this subsection immediately after L717:

  ```
  **Non-independent designs.** Everything above assumes one sample per animal. If you have
  repeated measures, co-housed animals or a nested design, three things change. The identifier
  for the true experimental unit — call it `Individual` — must be a column in your metadata.

  ```r
  # PERMANOVA: permute within individuals, never across them. Free permutation
  # here would treat three swabs from one tuatara as three independent animals
  # and inflate your false positive rate.
  meta_srs     <- data.frame(sample_data(ps_srs))
  perm_blocked <- how(nperm = 9999, blocks = factor(meta_srs$Individual))

  adonis2(dist_bray ~ Timepoint,
          data         = meta_srs,
          permutations = perm_blocked,
          by           = "terms")

  # Alpha diversity: a mixed model replaces Kruskal-Wallis / Wilcoxon.
  library(lmerTest)
  alpha_div$Individual <- sample_data(ps_srs)$Individual
  alpha_div$Timepoint  <- sample_data(ps_srs)$Timepoint
  m_shannon <- lmer(Shannon ~ Timepoint + (1 | Individual), data = alpha_div)
  summary(m_shannon)     # lmerTest adds p-values for the fixed effects

  # Differential abundance: add the random effect to the Maaslin2() call below.
  #   random_effects = c("Individual")
  ```

  Your n is the number of individuals, not the number of samples. Report it that way.
  ```

### F-09 · S2 · Document is banner-labelled Nanopore-only yet claims any platform works unchanged
- **Where:** SOP_R_Analysis.md:1 and SOP_R_Analysis.md:61, § front matter and § 5 intro
- **Quote:**
  > *Taylor Lab | Full-Length 16S rRNA Nanopore SOP*
  >
  > …
  >
  > With your count table and taxonomy table from Emu, move to R for statistical analysis and visualisation. This section is the same regardless of whether your data came from Illumina or Nanopore; the input format is identical.
- **Defect:** Two contradictory scope statements twelve lines apart, and neither is accurate.
  The banner says Nanopore; L61 says any platform. But the entire loading block (L109-123)
  is Emu-specific — a hardcoded `emu-combined-counts_silva.tsv`, a `tax_id` row-name column,
  and a `superkingdom` rank name — and the whole workflow assumes integer counts (rounding at
  L126, SRS at L383, "raw counts" for all three DA tools at L357-359). "The input format is
  identical" is false for any profiler that reports relative abundance; the README's own
  conventions section (L52) names `ps_relab` for exactly that case.
- **Failure:** A reader arriving from shotgun profiling reads L61, takes it at face value,
  points the loading code at a relative-abundance table, and rounds it at L126. Values below
  0.5% become 0 and everything else becomes 0 or 1. `Cmin` is a handful of "reads", SRS runs,
  alpha diversity comes back as a small integer per sample, and ANCOM-BC2 fits a model to
  binary data. Every step completes. The reader has a full set of figures built from a table
  that has been destroyed.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — L1 and L61 make incompatible scope claims about the same
  document, and L111 hardcodes an Emu filename inside the block L61 introduces.
- **Fix:** Replace L1 with:

  `*Taylor Lab | Microbial community analysis in R*`

  and replace L61 with:

  "With a count table, a taxonomy table and a metadata file, move to R for statistical
  analysis and visualisation. The workflow is the same whichever platform and profiler
  produced those tables — what it assumes is that the count table holds **integer read
  counts**, one row per taxon and one column per sample. If your profiler reports relative
  abundances rather than counts, do not run the rounding step, SRS, or any of the
  differential abundance tools in Section 6 on them as written; follow the adjustments listed
  in your upstream SOP first. The loading code below is written for Emu's combined counts
  table; adapt the file name and the taxonomy-rank column names to whatever your profiler
  produced."

### F-10 · S2 · Stage 3 computes Bray-Curtis on un-normalised counts, against the document's own rule
- **Where:** SOP_R_Analysis.md:287-296 and 316, § Stage 3
- **Quote:**
  > quick_ord <- ordinate(ps_raw, "PCoA", "bray")
  > …
  > # adonis2(phyloseq::distance(ps_raw, "bray") ~ Batch,
  > …
  > dist_temp <- phyloseq::distance(ps_raw, method = "bray")
- **Defect:** Three Bray-Curtis computations on `ps_raw`. The document's one rule (L55), its
  normalisation table (L355: "Beta diversity (Bray-Curtis) | SRS | `ps_srs`") and its own
  Common Pitfalls entry (L1005) all say Bray-Curtis needs `ps_srs`. Nothing here says these
  three uses are a deliberate exception or why. Worse, this is the batch-effect check: Bray-
  Curtis on un-normalised counts is depth-sensitive, and depth is very often correlated with
  batch, so the check is prone to reporting a batch effect that is a depth effect.
- **Failure:** Run 2 was sequenced deeper than run 1. The reader runs the commented `adonis2`
  at L294-296, gets Batch R² = 0.22, p = 0.001, and follows L302: they add Batch as a
  covariate to every downstream model, or they conclude the study is confounded and report it
  as a limitation. The signal was library size, which they had already characterised
  correctly twelve lines earlier at L271-282. Separately, a reader who does notice the rule
  violation has no way to tell whether L55 or L287 is the mistake.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — L355 and L1005 require `ps_srs` for Bray-Curtis; L287, L294 and
  L316 pass `ps_raw`, and no text in Stage 3 acknowledges the exception.
- **Fix:** Insert before L286 and use `ps_rel_qc` in all three places:

  ```r
  # ps_srs does not exist yet, and Bray-Curtis on raw counts is depth-sensitive —
  # batch usually correlates with depth, so a raw-count batch test can report a
  # "batch effect" that is really a sequencing-depth effect. Build a
  # proportions-only object for these QC looks. It is used for QC ONLY and is
  # never referenced again after this stage.
  ps_rel_qc <- transform_sample_counts(ps_raw, function(x) x / sum(x))

  quick_ord <- ordinate(ps_rel_qc, "PCoA", "bray")

  plot_ordination(ps_rel_qc, quick_ord, color = "Batch") +
      geom_point(size = 3) + theme_bw() +
      ggtitle("Coloured by extraction batch")

  # Test batch with PERMANOVA if you have a batch variable
  # adonis2(phyloseq::distance(ps_rel_qc, "bray") ~ Batch,
  #         data = data.frame(sample_data(ps_rel_qc)),
  #         permutations = how(nperm = 9999), by = "terms")
  # Swap Batch for Plate to check plate effects the same way.
  ```

  and change L316 to `dist_temp <- phyloseq::distance(ps_rel_qc, method = "bray")`. Add after
  L297: "Proportions remove the gross depth effect but not the detection effect — a deeper
  sample still shows more rare taxa. If batch comes out significant here, check it against
  the depth boxplot above before concluding it is a batch effect."

### F-11 · S2 · Aitchison is called depth-sensitive in Stage 4 and depth-corrected in Step 2
- **Where:** SOP_R_Analysis.md:336 and SOP_R_Analysis.md:530, § Stage 4 and § Step 2
- **Quote:**
  > He also found that CLR/Aitchison distance, despite being theoretically compositionally correct, was strongly sensitive to sequencing depth on real, sparse data.
  >
  > …
  >
  > Aitchison distance is computed on raw counts; the rCLR transformation handles depth internally, so applying SRS first would double-normalise.
- **Defect:** Flat contradiction, 194 lines apart, about the metric the document uses as one
  of its two primary beta-diversity measures on data it describes as sparse (L496: "sparse
  data like Nanopore 16S"). The reader cannot tell whether running Aitchison on `ps_raw` is
  the right thing or the thing Schloss warned against, and the document gives no way to check.
- **Failure:** Reader has a 12-fold depth range (which L275 calls "common and manageable").
  They compute `dist_ait` on `ps_raw`, get a clean PCoA where Axis 1 separates their samples,
  and report a significant Aitchison PERMANOVA. Axis 1 is tracking library size — the effect
  L336 describes — and nothing in Step 1 or Step 2 asks them to check. They report a depth
  gradient as a site effect, corroborated (they believe) by a second, independent metric.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED — the two sentences make opposite claims about the same metric on
  the same kind of data.
- **Fix:** Replace the second sentence at L336 with:

  "He also found that the standard CLR/Aitchison distance, despite being theoretically
  compositionally correct, remained strongly sensitive to sequencing depth on real, sparse
  data. That is a caution about Aitchison, not a reason to drop it: we report it alongside
  Bray-Curtis rather than instead of it, we use the robust (rCLR) variant, and Step 2 includes
  an explicit check that the Aitchison ordination is not simply tracking library size."

  and replace L530 with:

  "Aitchison distance is computed on raw counts. rCLR is a per-sample log-ratio, so scaling a
  sample's counts by a constant leaves the transformed values unchanged and applying SRS first
  would throw reads away for no gain. What rCLR does *not* remove is depth-dependent
  *detection*: a deeper sample simply has more non-zero taxa, which is why Schloss (2024)
  found Aitchison distance still tracked depth on sparse data. Check for it before you
  interpret the ordination:

  ```r
  sample_data(ps_raw)$LibSize <- sample_sums(ps_raw)
  plot_ordination(ps_raw, pcoa_ait, color = "LibSize") +
      geom_point(size = 3) + theme_bw() +
      labs(title = "Aitchison PCoA coloured by library size")
  ```

  If Axis 1 grades smoothly with library size rather than separating your groups, the
  Aitchison result is depth-driven. Report Bray-Curtis on `ps_srs` as your primary metric,
  say so, and present the Aitchison ordination with the library-size colouring as a caveat."

### F-12 · S2 · `symnum.args` gives five p-value intervals but only four symbols
- **Where:** SOP_R_Analysis.md:424-425, § Alpha diversity
- **Quote:**
  > symnum.args      <- list(cutpoints = c(0, 0.0001, 0.001, 0.01, 0.05, 1),
  >                          symbols   = c("****", "***", "**", "*"))
- **Defect:** Six cutpoints define five intervals; four symbols are supplied. `symnum()`
  requires exactly one symbol per interval, so the object is malformed and the interval
  0.05–1 (every non-significant comparison) has no label. This object is used in three
  plotting blocks: L436, L447 and L465.
- **Failure:** Reader pastes the alpha diversity block. `stat_compare_means` calls `symnum`,
  which rejects the arguments, and the entire `plot_richness` call fails. The reader has a
  working `kruskal.test` result on screen, a red error naming an internal ggpubr call, and no
  figure. Nothing in the document mentions `symnum.args` again, so there is no way to work
  out that the symbol vector is one element short. Every alpha diversity figure in the SOP
  depends on this object.
- **Type:** CORRECTNESS
- **Confidence:** NEEDS-BENCH-CHECK — run `symnum(0.5, corr = FALSE, cutpoints = c(0, 1e-4,
  1e-3, 0.01, 0.05, 1), symbols = c("****","***","**","*"))`; it should stop with a message
  about `symbols` needing length `length(cutpoints) - 1`. If it does not error, the defect is
  instead that non-significant comparisons are labelled with whatever `symnum` falls back to.
- **Fix:** Replace L424-425 with:

  ```r
  # One symbol per interval: 5 cutpoint gaps, 5 symbols. Omitting "ns" leaves the
  # 0.05-1 interval unlabelled and symnum() rejects the whole argument.
  symnum.args      <- list(cutpoints = c(0, 0.0001, 0.001, 0.01, 0.05, 1),
                           symbols   = c("****", "***", "**", "*", "ns"))
  ```

### F-13 · S2 · Jaccard and binary Bray-Curtis claimed to give identical F-statistics and p-values
- **Where:** SOP_R_Analysis.md:762, § Step 6 (optional)
- **Quote:**
  > Jaccard and binary (presence/absence) Bray-Curtis are monotonic transformations of one another, so they give identical ordinations, F-statistics, and p-values. If you switch between them, do not be surprised when the numbers match exactly.
- **Defect:** The conclusion does not follow from the premise the sentence itself states. A
  monotonic transformation preserves the *rank order* of dissimilarities, so rank-based
  methods (NMDS, ANOSIM, rank Mantel) are invariant. PERMANOVA and PCoA are not rank-based:
  `adonis2` partitions sums of squares of the dissimilarity values themselves and PCoA
  eigendecomposes them, so a non-linear monotone map changes F, R², the eigenvalues and the
  p-value. The document uses PERMANOVA and PCoA throughout and NMDS only as a fallback, so
  the claim is wrong for every analysis it actually performs.
- **Failure:** Reader runs the Jaccard block, then out of curiosity re-runs it with
  `method = "bray", binary = TRUE`, and gets F = 2.41 instead of 2.28 and p = 0.021 instead
  of 0.018. Told to expect exact agreement, they assume they have made a coding error and
  spend an afternoon looking for it. The alternative reader takes the sentence at its word,
  reports "Jaccard" in the methods while having run binary Bray-Curtis, and has misdescribed
  their analysis in print.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — the sentence's own premise (monotonic transformation) supports
  invariance only for rank-based statistics; `adonis2` and PCoA, used at L756 and L514, are
  not rank-based.
- **Fix:** Replace L762 with:

  "Jaccard and binary (presence/absence) Bray-Curtis are monotonic transformations of one
  another, so rank-based methods — NMDS, ANOSIM, rank-correlation Mantel tests — give
  identical results from either. PERMANOVA and PCoA are not rank-based: they work on the
  dissimilarity values themselves, so F, R² and p will differ slightly between the two. Pick
  one, name it in your methods, and do not swap them mid-analysis. Jaccard is the more
  conventional choice for a membership question and is what most readers will expect."

### F-14 · S2 · "Report the consensus" is the headline recommendation and is never defined or coded
- **Where:** SOP_R_Analysis.md:831, § Why you can't just test each taxon individually
  (repeated at L938 and L1009)
- **Quote:**
  > **Our approach:** Bray-Curtis for continuity with the ecological literature plus Aitchison as the compositionally correct complement; for differential abundance, run ANCOM-BC2 and MaAsLin2 and report the consensus.
- **Defect:** "Consensus" is stated three times as the document's method and is never defined
  or implemented. The reader is left with two result objects filtered on different thresholds
  by different corrections — `da_ancom$res` at holm-adjusted `q` with `passed_ss` (L885-886)
  and `da_maaslin$results` at BH `qval < 0.05` (L922-923) — and no instruction on how to
  combine them, whether direction of effect must agree, or what to do with a taxon found by
  one method only.
- **Failure:** Reader finishes Section 6 with two tables of 40 and 60 rows, no overlap column,
  and a deadline. They eyeball the two lists, pick the taxa that appear in both by scanning
  names by eye, miss the ones MaAsLin2 has renamed, and never check whether the two methods
  agree on the direction of change — so a taxon that ANCOM-BC2 puts up in Zealandia and
  MaAsLin2 puts down enters the results as a consensus hit.
- **Type:** GAP
- **Confidence:** CONFIRMED — searching the document for "consensus" returns L831, L938 and
  L1009, all prose; no code block joins the two result sets.
- **Fix:** Add at the end of the MaAsLin2 section, after L934:

  ```
  **Taking the consensus.** A taxon is a consensus hit when both methods call it significant
  at their own thresholds **and** agree on the direction of change. A taxon found by one
  method only is a candidate, not a finding — report it as such, in supplementary material.

  ```r
  # Both methods must have been run at the same taxonomic rank for this to work.
  ancom_hits <- da_ancom$res %>%
      filter(diff_SiteZealandia, passed_ss_SiteZealandia) %>%
      transmute(feature = taxon, ancom_lfc = lfc_SiteZealandia)

  maaslin_hits <- da_maaslin$results %>%
      filter(metadata == "Site", value == "Zealandia", qval < 0.05) %>%
      transmute(feature, maaslin_coef = coef)

  consensus <- inner_join(ancom_hits, maaslin_hits, by = "feature") %>%
      filter(sign(ancom_lfc) == sign(maaslin_coef))

  cat("ANCOM-BC2:", nrow(ancom_hits), "| MaAsLin2:", nrow(maaslin_hits),
      "| consensus:", nrow(consensus), "\n")
  consensus
  ```

  If the join returns zero rows, compare `head(ancom_hits$feature)` with
  `head(maaslin_hits$feature)` before believing it: MaAsLin2 rewrites feature names containing
  spaces or punctuation, substituting dots, so the names may need harmonising first.
  ```

### F-15 · S3 · Three parallel numbering schemes; roadmap's STAGE 5 has no heading
- **Where:** SOP_R_Analysis.md:28, § Quick Roadmap
- **Quote:**
  > STAGE 5: Analysis
- **Defect:** The document runs Sections (5, 6), Stages (1-4 as headings, 1-5 in the roadmap)
  and Steps (1-6) simultaneously, and the Key objects table mixes them ("Stage 4", "Section 5
  Step 1"). "Stage 5" exists only in the roadmap; there is no heading by that name, and its
  five bullets are five sibling `###` headings. Steps 1-6 are also `###`, i.e. siblings of
  "Beta diversity" rather than children of it, so the outline shows no nesting. The README
  (L53) holds up the read-based SOP for aligning section numbers with the roadmap.
- **Failure:** Reader is told at L50 that `dist_bray` is built in "Section 5 Step 1", searches
  for a heading beginning "5.1", finds none, and scrolls. Reader finishes Stage 4 and looks
  for the Stage 5 heading the roadmap promised; it does not exist, so they cannot tell whether
  they have missed a step.
- **Type:** STRUCTURE
- **Confidence:** CONFIRMED — the heading list contains `Stage 1` through `Stage 4` and no
  `Stage 5`; `Step 1`-`Step 6` are all `###`, as is `Beta diversity`.
- **Fix:** Renumber to one scheme: make the roadmap stages 1-5 the `###` headings under
  Section 5 (`### 5.5 Analysis`), demote Steps 1-6 and Alpha diversity / Taxonomy barplots to
  `####` under it, and change the Key objects table's "Where it's built" column to the new
  numbers. Fold "Installing and loading libraries" into Stage 1, which the roadmap already
  says it belongs to.

### F-16 · S3 · Metadata example is space-aligned and its site name contains spaces
- **Where:** SOP_R_Analysis.md:154-160, § Stage 1
- **Quote:**
  > SampleID    Site            Sex     Species     Season      Batch    Plate     SampleType
  > barcode01   Takapourewa     Male    Tuatara     Summer      B1       plate1    sample
- **Defect:** The prose says tab-separated (L143) and the reader is told to read it with
  `sep = "\t"` (L140), but the example is rendered with aligned spaces, which is what a
  student will reproduce in a text editor. Separately, `Young Nicks Head` contains spaces, so
  ANCOM-BC2 produces the output column `` `lfc_SiteYoung Nicks Head` `` which cannot be
  referenced without backticks, and MaAsLin2 rewrites it again.
- **Failure:** Reader types the table with spaces, `read.table(sep = "\t")` sees one field per
  line, and `row.names = 1` fails. Or the file loads and, later, the reader adapts L886 to the
  third site, writes `filter(diff_SiteYoung Nicks Head == TRUE)`, and gets a parse error with
  no explanation.
- **Type:** CLARITY
- **Confidence:** CONFIRMED — L143 states the file is tab-separated and L140 reads it with
  `sep = "\t"`, while the example at L154-160 is rendered with aligned spaces. (The secondary
  claim, that ANCOM-BC2 pastes the level into the column name verbatim, is settled by
  `colnames(da_ancom$res)` on a factor level containing a space.)
- **Fix:** Change the caption at L151 to "Example `metadata_file.txt` — the columns below are
  separated by single tab characters; the alignment here is only for readability. If you build
  it in Excel, save as *Text (tab delimited)*." Change the third site to `YoungNicksHead` in
  the example and in the factor levels at L168, and add after L162: "Avoid spaces and
  punctuation in factor levels. ANCOM-BC2 builds output column names by pasting the variable
  and level together, so `Young Nicks Head` becomes `` `lfc_SiteYoung Nicks Head` `` and needs
  backticks everywhere you refer to it; MaAsLin2 rewrites the same name differently. Use a
  compact label in the data and relabel only at the figure stage."

### F-17 · S3 · decontam threshold and method choice undocumented; example ships one blank
- **Where:** SOP_R_Analysis.md:207, § Stage 2
- **Quote:**
  > contam_df <- isContaminant(t(counts_raw), neg = is_blank, method = "prevalence")
- **Defect:** `isContaminant` has a `threshold` argument that decides which taxa are deleted
  from every downstream analysis, and it is neither passed nor mentioned. The choice of the
  prevalence method over frequency or combined is stated but not justified. The example
  metadata (L159) contains a single blank, and nothing says how many are needed. This is the
  case the README singles out: "If you are documenting a threshold or a tool choice, write
  down the reasoning, not just the value."
- **Failure:** Reader runs decontam with one blank, gets four contaminants, removes them, and
  writes "contaminants were removed with decontam" in the methods. A reviewer asks which
  threshold; the reader does not know one exists and cannot reproduce the number.
- **Type:** GAP
- **Confidence:** CONFIRMED — the call at L207 passes no threshold, no line in the document
  states one, and no line justifies the prevalence method over the alternatives, against
  README L96's requirement to record the reasoning behind a threshold or tool choice. (The
  numeric default quoted in the fix is settled by `?decontam::isContaminant`.)
- **Fix:** Change L207 to `isContaminant(t(counts_raw), neg = is_blank, method =
  "prevalence", threshold = 0.1)` and insert after L198: "`threshold = 0.1` is decontam's
  default: the probability cutoff below which a taxon is called a contaminant. It is
  conservative — it removes only taxa clearly enriched in the blanks. `threshold = 0.5` is the
  other common setting, classifying as contaminant any taxon more prevalent in blanks than in
  samples; it removes considerably more and suits runs with several clean blanks. Record which
  you used. We use the prevalence method rather than the frequency method because frequency
  needs a DNA concentration for every sample; with quantification data, `method = "combined"`
  uses both. The prevalence method compares presence/absence across blanks and samples, so it
  needs several blanks to have any power — aim for three or four per extraction batch. With
  one blank the call is close to arbitrary: run it, but treat the output as a list to inspect
  by eye rather than a filter to trust." Add a second blank to the example at L159.

### F-18 · S3 · Expected output shows 5 sample variables where the worked metadata has 7
- **Where:** SOP_R_Analysis.md:244, § Stage 2
- **Quote:**
  > sample_data() Sample Data:       [ 12 samples by 5 sample variables ]
- **Defect:** The metadata example at L154 defines seven variables after the row-name column
  (Site, Sex, Species, Season, Batch, Plate, SampleType), and none is dropped before `ps_raw`
  is built. The expected output the reader is asked to check against therefore cannot arise
  from the document's own example.
- **Failure:** Reader builds `ps_raw`, sees "7 sample variables", compares it with the block
  they were told to expect, and starts looking for the two columns they think they have lost.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED — the example metadata header at L154 carries seven columns after
  `SampleID`, and no line between L154 and L234 drops any of them.
- **Fix:** Change to `[ 12 samples by 7 sample variables ]` and add after L245: "Your numbers
  will differ; what matters is that the sample count matches the samples you expect after
  blanks were removed, and the variable count matches your metadata columns."

### F-19 · S3 · Checkpoint save buried inside a block the reader only runs when something is wrong
- **Where:** SOP_R_Analysis.md:249-260, § Stage 2
- **Quote:**
  > # Diagnostic for name mismatches
  > …
  > # Save a checkpoint so you can reload without re-running everything
  > saveRDS(ps_raw, "checkpoint_ps_raw.rds")
- **Defect:** The `saveRDS` checkpoint is inside the code block introduced at L247 by "If the
  numbers look wrong (zero taxa, wrong sample count), check that row/column names match" — a
  block the reader is told to run only on failure. The reader whose object built correctly
  skips the block and never saves the checkpoint.
- **Failure:** Reader's `ps_raw` looks right, they skip the diagnostic, R crashes during the
  ANCOM-BC2 run four hours later, and they re-run Stages 1 and 2 from the raw files because no
  checkpoint was written.
- **Type:** STRUCTURE
- **Confidence:** CONFIRMED — L247 makes the block conditional ("If the numbers look wrong"),
  and the `saveRDS` call at L259 sits inside that same fenced block, which ends at L261.
- **Fix:** Split into two blocks: leave L250-256 under the "if the numbers look wrong"
  sentence, and move L258-260 into its own block under the heading sentence "Whether or not
  you needed the diagnostic, save a checkpoint before moving on:".

### F-20 · S3 · NMDS fallback recomputes the distance instead of using `dist_bray`
- **Where:** SOP_R_Analysis.md:566-567, § Step 2
- **Quote:**
  > nmds_bray <- ordinate(ps_srs, method = "NMDS", distance = "bray",
  >                       trymax = 999, autotransform = TRUE)
- **Defect:** Every other ordination and test in Steps 1-5 is driven by the `dist_bray` object
  built at L489. This one passes `distance = "bray"` as a string, so metaMDS recomputes it,
  and `autotransform = TRUE` applies a square-root and Wisconsin double standardisation on the
  way. The fallback therefore does not plot the matrix that PERMANOVA tested.
- **Failure:** Reader falls back to NMDS because of negative eigenvalues, and the picture
  disagrees with the PERMANOVA on `dist_bray` — different transformation, same label. They
  have no way to tell that the two are not the same distance.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED — L566 passes the string `"bray"` where L514, L533, L581 and L698
  all pass the prebuilt `dist_bray`/`dist_ait` objects, so this call alone recomputes its
  input. (The specific transformations `autotransform = TRUE` applies are settled by reading
  the transformation lines metaMDS prints to the console when the call runs.)
- **Fix:** Change to `nmds_bray <- ordinate(ps_srs, method = "NMDS", distance = dist_bray,
  trymax = 999)` and add "Passing the `dist_bray` object rather than the string `"bray"` keeps
  the NMDS on exactly the matrix PERMANOVA tests, and skips metaMDS's automatic square-root
  and Wisconsin standardisation, which would otherwise silently change the distance."

### F-21 · S3 · vegan version pinned to a behaviour change that is not verified
- **Where:** SOP_R_Analysis.md:691, § Step 4
- **Quote:**
  > **Note on the `adonis2` default:** in recent vegan versions (2.6-8 and later) the default is now an omnibus test (`by = NULL`), not sequential. Earlier versions defaulted to `by = "terms"`.
- **Defect:** A specific version number is attached to a specific default change. The
  actionable advice around it (always pass `by` explicitly) is correct regardless, but the
  version string will be quoted by readers into methods sections and may not be right.
- **Failure:** Reader on vegan 2.6-6 reads this, assumes their default is `by = "terms"`,
  omits the argument in an adapted call elsewhere, and gets a different partition than they
  expect.
- **Type:** CORRECTNESS
- **Confidence:** NEEDS-BENCH-CHECK — check `?adonis2` for the documented default of `by` in
  the installed version and the vegan NEWS entry that changed it.
- **Fix:** Replace the version-specific clause with "the default for `by` has changed between
  vegan releases — check `?adonis2` in your installed version rather than relying on it." Keep
  the rest of the paragraph unchanged.

### F-22 · S3 · No seed before any permutation test, though seeds are set elsewhere
- **Where:** SOP_R_Analysis.md:694-695, § Step 4 (also L582-590, L752, L962)
- **Quote:**
  > # Permutation scheme: free permutation, 9,999 permutations
  > perm_free <- how(nperm = 9999)
- **Defect:** `adonis2`, `permutest` and `multipatt` all draw random permutations, and no seed
  is set before any of them. The document sets `set.seed(42)` before NMDS (L565) and
  `set.seed(123)` before ANCOM-BC2 (L843) and devotes a section to reproducibility (L989-997),
  so the omission reads as an oversight rather than a decision.
- **Failure:** Reader runs PERMANOVA, writes p = 0.049 into the manuscript, re-runs the script
  for a revision six months later and gets p = 0.052. Neither number is wrong; they cannot
  reproduce the one they published.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED — `set.seed` occurs at exactly two places in the document, L565
  (before NMDS) and L843 (before ANCOM-BC2); neither precedes the `adonis2` calls at L698 and
  L704, the `permutest` calls at L582-590, or `multipatt` at L960. That these are randomised
  is the document's own description of them at L676 and L962.
- **Fix:** Add `set.seed(1)` immediately before L695, before the `permutest` block at L580,
  before the Jaccard `permutest` at L752, and before `multipatt` at L960, with the comment
  "permutation p-values move slightly between runs; fix the seed so your reported numbers are
  reproducible."

### F-23 · S3 · SILVA/RDP comparison recommended but never loaded or shown
- **Where:** SOP_R_Analysis.md:808, § Taxonomy barplots
- **Quote:**
  > Comparing SILVA and RDP results helps distinguish these.
- **Defect:** The loading block reads one file, `emu-combined-counts_silva.tsv` (L111), and no
  part of the document loads or compares a second database's table. The reader is told twice
  in the repository that both databases are run, and is here told the comparison resolves an
  ambiguity, with no procedure for making it.
- **Failure:** Reader sees 40% of genus assignments as "Unknown", reads L808, and has no idea
  what "comparing" means operationally — same object? Side-by-side barplots? Correlated
  abundances? They skip it and report the ambiguity unresolved.
- **Type:** GAP
- **Confidence:** CONFIRMED — L111 is the only `read.table` of a counts file in the document,
  and no later line loads a second database's table or compares two taxonomy objects.
- **Fix:** Add three lines after L808: "To make the comparison, run Stage 1 a second time on
  `emu-combined-counts_rdp.tsv` into `counts_raw_rdp` / `taxonomy_rdp`, then compare the
  proportion of reads unassigned at genus level in each: `mean(taxonomy[, "genus"] == "" |
  is.na(taxonomy[, "genus"]))`. If SILVA and RDP leave the same taxa unassigned, the reference
  databases genuinely lack them; if only one does, it is a database coverage difference, not
  novel biology. Keep the SILVA tables as your primary analysis and report the RDP comparison
  as a check."

### F-24 · S3 · No runtime given for the slowest step in the document
- **Where:** SOP_R_Analysis.md:856-859, § Differential abundance with ANCOM-BC2
- **Quote:**
  >     global       = TRUE,               # omnibus test across groups
  >     pairwise     = TRUE,
  >     pseudo_sens  = TRUE,               # sensitivity analysis
  >     verbose      = TRUE
- **Defect:** `global`, `pairwise` and `pseudo_sens` each add substantial computation, and all
  three are switched on with no indication of how long the call takes or how it scales with
  taxa and samples. The same is true of `rarecurve` (L367) and the 9,999-permutation
  `adonis2` calls. The read-based SOP is held up as the style exemplar precisely because it
  states walltimes.
- **Failure:** Reader starts `ancombc2`, sees no output for twenty minutes, assumes R has
  hung, kills the session, and either reruns it or turns off `pseudo_sens` — which is the
  option the document says at L882 must be TRUE for the results to be trustworthy.
- **Type:** GAP
- **Confidence:** NEEDS-BENCH-CHECK — time the call on a representative table (~250 taxa,
  ~12-40 samples) and record the wall time with and without `pseudo_sens`.
- **Fix:** Add after L860: "`verbose = TRUE` prints progress; with `global`, `pairwise` and
  `pseudo_sens` all on, expect minutes rather than seconds on a table of this size, and
  considerably longer with hundreds of samples. It has not hung — leave it. `rarecurve` at
  `step = 100` and the 9,999-permutation `adonis2` calls also take noticeably longer than the
  rest of the document." Replace "minutes rather than seconds" with the measured figure once
  benched.

### F-25 · S4 · Worked example attributed to a named individual
- **Where:** SOP_R_Analysis.md:7, § front matter
- **Quote:**
  > The examples use Cam's tuatara PhD data, so the variable names (Site, Sex, Species) and site names (Takapourewa, Zealandia, Young Nicks Head) are specific to that study.
- **Defect:** The README describes the same example impersonally as "a tuatara study" (L54).
  A first name is opaque to anyone joining the lab after that student leaves.
- **Failure:** New student reads "Cam's", does not know who Cam is, cannot tell whether the
  data is available to them or whether the conventions are house style or one person's.
- **Type:** CLARITY
- **Confidence:** CONFIRMED — L7 names an individual where README L54 describes the same
  worked example as "a tuatara study".
- **Fix:** Change to "The examples come from a tuatara gut microbiome study, so the variable
  names…".

### F-26 · S4 · `microbiome` and `mia` installed and loaded but never used
- **Where:** SOP_R_Analysis.md:72-73 and 94, § Installing and loading libraries
- **Quote:**
  > BiocManager::install(c("phyloseq", "decontam", "ANCOMBC", "Maaslin2",
  >                        "microbiome", "ALDEx2", "mia"))
- **Defect:** No function from `microbiome` or `mia` is called anywhere in the document.
  `library(microbiome)` at L94 loads one of them for nothing.
- **Failure:** Reader spends twenty minutes compiling two Bioconductor packages that nothing
  in the SOP needs, and hits an install failure on a dependency that was never required.
- **Type:** CLARITY
- **Confidence:** CONFIRMED — a search of the document for `microbiome::`, `mia::`,
  `abundances(`, `aggregate_taxa`, `meta(` and `makeTreeSE` returns no matches; the only
  `microbiome*` call anywhere is `microbiomeutilities::aggregate_top_taxa2` at L778, which
  belongs to a different package.
- **Fix:** Drop `mia` from the install vector and drop `library(microbiome)`; keep
  `microbiome` in the install list only if the ALDEx2 path needs it, and say so.

### F-27 · S4 · `devtools` install commented out, its use is not
- **Where:** SOP_R_Analysis.md:76-77, § Installing and loading libraries
- **Quote:**
  > # install.packages("devtools")
  > devtools::install_github("microsud/microbiomeutilities")
- **Defect:** The prerequisite is commented, the line that needs it is live.
- **Failure:** Reader without devtools runs the install block and gets
  `there is no package called 'devtools'` on the first uncommented line that matters.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — L76 is commented and L77, which calls `devtools::`, is not.
- **Fix:** Uncomment `install.packages("devtools")`, or wrap it:
  `if (!requireNamespace("devtools", quietly = TRUE)) install.packages("devtools")`.

### F-28 · S4 · Placeholder style does not match the repository convention
- **Where:** SOP_R_Analysis.md:107, § Stage 1
- **Quote:**
  > setwd("~/path/to/your/files")
- **Defect:** The README (L50) states that angle brackets mark placeholders throughout the
  SOPs. This one uses a prose path instead.
- **Failure:** Reader scanning for `<…>` to find every substitution point misses this one and
  runs the block from the wrong working directory, then cannot find their input file.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED — README L50 states that angle brackets mark every placeholder in
  these SOPs; L107 is a placeholder written in a different style.
- **Fix:** `setwd("<path_to_your_analysis_folder>")`, with a one-line note that an RStudio
  Project removes the need for `setwd()` entirely.

### F-29 · S4 · Contaminant selection propagates NA rows
- **Where:** SOP_R_Analysis.md:212, § Stage 2
- **Quote:**
  > contam_ids <- rownames(contam_df[contam_df$contaminant == TRUE, ])
- **Defect:** `contaminant` is NA wherever decontam could not compute a score, and logical
  indexing with NA returns NA rows, so `contam_ids` can contain NA entries.
- **Failure:** `print(taxonomy[contam_ids, , drop = FALSE])` at L214 prints rows of NAs into
  the reader's contaminant record for the lab notebook.
- **Type:** CORRECTNESS
- **Confidence:** NEEDS-BENCH-CHECK — run `sum(is.na(contam_df$contaminant))` after
  `isContaminant`; if any are NA, the logical index at L212 emits NA rows and `contam_ids`
  carries NA entries. (That NA logical subscripts produce NA rows is base R semantics; whether
  decontam ever returns NA in that column is what needs checking.)
- **Fix:** `contam_ids <- rownames(contam_df)[which(contam_df$contaminant)]`.

### F-30 · S4 · Two idioms for the same coercion
- **Where:** SOP_R_Analysis.md:295 and SOP_R_Analysis.md:699
- **Quote:**
  > #         data = as.data.frame(sample_data(ps_raw)),
  > …
  >         data         = data.frame(sample_data(ps_srs)),
- **Defect:** `as.data.frame(sample_data(x))` and `data.frame(sample_data(x))` are used for
  the same operation in different places.
- **Failure:** Reader copying between sections cannot tell whether the difference is
  meaningful and wastes time checking.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED — L295 and L699 apply two different coercions to the same
  `sample_data()` result for the same purpose (the `data` argument of `adonis2`).
- **Fix:** Use `data.frame(sample_data(x))` everywhere.

### F-31 · S4 · Shiny app shown without its required argument
- **Where:** SOP_R_Analysis.md:342, § Stage 4
- **Quote:**
  > It is also available as an interactive Shiny app (`SRS::SRS.shiny.app()`) for exploring how different Cmin values affect your data before committing.
- **Defect:** `SRS.shiny.app()` takes the count table as an argument; as written the reader
  will call it with none.
- **Failure:** Reader types the call verbatim, gets an argument error, and abandons a useful
  tool.
- **Type:** CORRECTNESS
- **Confidence:** NEEDS-BENCH-CHECK — confirm the argument name with
  `args(SRS::SRS.shiny.app)`.
- **Fix:** Write it as `SRS::SRS.shiny.app(counts_raw)`.

### F-32 · S4 · Double transpose where a direct call exists
- **Where:** SOP_R_Analysis.md:368 and 376, § Stage 4
- **Quote:**
  > Cmin <- min(rowSums(t(counts_raw)))
- **Defect:** `counts_raw` is taxa × samples, so per-sample totals are `colSums(counts_raw)`.
  Transposing to take row sums is the same number by a longer route, and it is the third
  different way the document expresses per-sample depth (`sample_sums(ps_raw)` at L270,
  `colSums(counts_raw)` at L380).
- **Failure:** Reader adapting the line for their own data transposes the wrong way round and
  gets per-taxon totals, then normalises to a nonsensical Cmin.
- **Type:** CLARITY
- **Confidence:** CONFIRMED — L102 and the Key objects table at L44 both establish that
  `counts_raw` is taxa × samples, so `rowSums(t(counts_raw))` and `colSums(counts_raw)` are
  the same vector; L380 already uses the direct form.
- **Fix:** `Cmin <- min(colSums(counts_raw))`, and use `colSums(counts_raw)` at L368's
  `abline` too.

### F-33 · S4 · Shannon is plotted but never given the omnibus/pairwise test code
- **Where:** SOP_R_Analysis.md:413-417 vs 439, § Alpha diversity
- **Quote:**
  > kruskal.test(Observed ~ Site, data = alpha_div)
- **Defect:** L402 instructs "Report at least Observed and Shannon", and a Shannon figure is
  produced at L439, but only Observed gets a Kruskal-Wallis and a pairwise test.
- **Failure:** Reader publishes a Shannon boxplot with significance brackets and no
  corresponding test in the text, or adapts the Observed code without noticing that
  `alpha_div$Shannon` also needs the omnibus gate.
- **Type:** GAP
- **Confidence:** CONFIRMED — L402 instructs the reader to report both metrics and L439 plots
  Shannon, but `Shannon` appears in no `kruskal.test` or `pairwise.wilcox.test` call anywhere
  in the document.
- **Fix:** Add the two-line Shannon equivalent under L417, or state explicitly "repeat both
  tests with `Shannon` in place of `Observed`".

### F-34 · S4 · Key objects table omits three objects that later sections depend on
- **Where:** SOP_R_Analysis.md:42-53, § Key objects you'll work with
- **Quote:**
  > | `da_ancom`, `da_maaslin` | varies | DA fit objects | Section 6 | Identifying differential taxa |
- **Defect:** `alpha_div` (L408), `dist_jaccard` (L748) and `indval` (L960) are all created
  and reused and none appears in the table the document presents as the naming contract.
- **Failure:** Reader returning to the table to check what `alpha_div` holds finds nothing and
  has to search the body text.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED — `alpha_div`, `dist_jaccard` and `indval` are assigned at L408,
  L748 and L960 and reused at L413, L751 and L964; none of the three appears in the table at
  L42-53.
- **Fix:** Add three rows for `alpha_div`, `dist_jaccard` and `indval`.

### F-35 · S4 · MaAsLin2 output folder silently overwritten on re-run
- **Where:** SOP_R_Analysis.md:911, § Differential abundance with MaAsLin2
- **Quote:**
  >     output          = "maaslin2_output",
- **Defect:** A fixed output directory is written on every run with no warning that a previous
  run's tables and figures are replaced.
- **Failure:** Reader re-runs with `Site + Sex + Season` to explore, and the `Site + Sex`
  results they had already started writing up are gone.
- **Type:** CORRECTNESS
- **Confidence:** NEEDS-BENCH-CHECK — run `Maaslin2()` twice into the same `output` folder
  with different `fixed_effects` and check whether the first run's `all_results.tsv` and
  `figures/` are replaced or preserved.
- **Fix:** `output = paste0("maaslin2_output_", format(Sys.Date(), "%Y%m%d"), "_site_sex")`,
  with a note that MaAsLin2 overwrites an existing folder.

### F-36 · S4 · `standardize = FALSE` set but absent from the parameter list
- **Where:** SOP_R_Analysis.md:916 vs 927-932, § Differential abundance with MaAsLin2
- **Quote:**
  >     standardize     = FALSE,
- **Defect:** Every other argument in the call gets a bullet explaining it; this one, which
  changes the scale of coefficients for continuous covariates, does not. The README requires
  reasoning for documented choices.
- **Failure:** Reader with a body-mass covariate reports a coefficient whose units they cannot
  state, because they do not know whether the predictor was standardised.
- **Type:** GAP
- **Confidence:** CONFIRMED — the bullet list at L927-932 explains `transform`,
  `normalization`, `reference` and `min_prevalence`, and no bullet mentions `standardize`,
  which is set at L916. (The claim in the fix that `TRUE` is the package default is settled by
  `args(Maaslin2::Maaslin2)`.)
- **Fix:** Add a bullet: "`standardize = FALSE` leaves continuous covariates on their original
  scale, so a coefficient is the change per unit of the predictor (per gram, per °C). Set it
  to `TRUE` (the package default) if you want coefficients comparable across covariates
  measured in different units."

## Keep list

1. **L55 and L1005 — the `ps_raw`/`ps_srs` rule, stated twice.** A tightening pass will read
   the Common Pitfalls copy as duplication and delete it. It is the document's single most
   important silent-failure warning and it belongs both where the objects are introduced and
   in the final checklist.
2. **L331-336 — the McMurdie & Holmes / Schloss rarefaction reasoning.** Four paragraphs to
   justify one normalisation choice, with the rarefying/rarefaction distinction that stops the
   reader misreading the literature. This is exactly the "why this number" content the README
   calls the main value of these documents.
3. **L818-820 — the 1,000-cells worked example of compositionality.** Concrete numbers
   (1,500 / 750 / 750) are the only thing in the document that makes compositionality land for
   a reader who has never met it. Do not compress it to a definition.
4. **L496 — why `robust.aitchison` rather than `aitchison`.** Two sentences that prevent a
   reader silently choosing the pseudocount version on sparse data.
5. **L362 — "Feeding pre-normalised data to ANCOM-BC2, MaAsLin2, or ALDEx2 produces incorrect
   results."** Bolded, unhedged, and correct. Keep the bolding.
6. **L593 — "will fail silently if you ever drop or reorder samples between the two."** The
   only place the document names the failure mode behind F-01 and F-02.
7. **L882 — "Trust results only where both `diff_` and `passed_ss_` are TRUE."** Without this
   the reader reports the `diff_` column alone, which is what the ANCOM-BC2 output invites.
8. **L145-149 — the three housekeeping metadata columns.** Reads like admin and is the first
   thing a simplifier cuts; without `SampleType` the entire decontam stage is impossible and
   without `Batch` the Stage 3 check cannot run at all.
9. **L1013 — "Choosing rarefaction depth after seeing results … is p-hacking."** The only
   research-integrity statement in the document.

## Gaps

- **SHOULD-ADD — failure branches.** Almost no code block says what failure looks like. The
  three worth adding explicitly: what `isContaminant` does when `sum(is_blank) == 0`; what
  happens if a sample survives to Stage 4 with near-zero reads (`Cmin` collapses, SRS returns
  near-empty samples, alpha diversity comes back as small integers for everyone — plausible
  and completely wrong); and what the `phyloseq()` constructor error looks like on a name
  mismatch. ~20-25 lines, distributed.
- **SHOULD-ADD — sanity-check decontam's output before deleting it.** The document records the
  contaminants (L211-214) but never asks whether a flagged taxon is one of the reader's most
  abundant. With few blanks, decontam can flag a genuinely dominant organism. Three lines:
  print each contaminant's mean relative abundance in the real samples, and a sentence saying
  investigate before removing anything above ~1%. ~6 lines.
- **SHOULD-ADD — nothing is written to disk.** Apart from the checkpoint (L259) and MaAsLin2's
  own folder, the document produces no saved figure and no exported table. A reader ends 1,027
  lines with everything in a session that will close. One block near § Figures with
  `ggsave()` and `write.csv()` for the alpha table, the PERMANOVA results and the DA
  consensus. ~12 lines.
- **SHOULD-ADD — how to use the mock community.** Common Pitfalls (L1011) says that without a
  mock community you cannot assess classification accuracy, and the document never shows how
  to use one. Given the species-level caution at L1017, this matters. ~8 lines, or an explicit
  statement that it is out of scope for Part 2 and where it lives instead.
- **CONSIDER — minimum group sizes.** The worked example has 12 samples across three sites and
  two sexes, and fits `Site * Sex` (six cells, two samples each). Nothing warns that an
  interaction term at that size is barely estimable, or that PERMANOVA's smallest attainable
  p-value is bounded by the design. ~5 lines in Step 4.
- **CONSIDER — taxa unassigned at the tested rank.** `tax_level = "genus"` (L847) and
  `tax_glom` both have to decide what to do with rows whose genus is empty — a real fraction
  of Emu output, as L808 acknowledges. Currently unaddressed at either end. ~5 lines.
- **CONSIDER — `renv`.** L997 recommends `renv::snapshot()` without `renv::init()`, which must
  come first and requires a project. ~2 lines.

## Cross-document flags

Each is a claim this document makes about something outside itself. I can see only this file.

| Line | Claim to check |
|---|---|
| 5 | "For the NeSI pipeline (Sections 1-4), see `SOP_NeSI_Pipeline.md`." — the known calibration defect; no such file. Also singular where Part 2 now serves three upstream SOPs. |
| 5 | "starting from the combined count tables produced by Part 1" — is `SOP_EMU_NeSI.md` still "Part 1", and does it end with combined count tables? |
| 1 | Banner "Full-Length 16S rRNA Nanopore SOP" contradicts README L18's "Part 2 is platform-agnostic". |
| 7 | "Cam's tuatara PhD data" vs README L54's impersonal "a tuatara study". |
| 13 | "from a combined Emu count table" — README L14 describes this document as serving three upstream pipelines. |
| 36 | "see the Common Pitfalls section" — an internal pointer, but check whether the upstream SOPs also point readers here for non-independent designs. |
| 61 | "the same regardless of whether your data came from Illumina or Nanopore; the input format is identical" vs README L28, which says shotgun input needs the read-based SOP's Section 13 deltas. |
| 109 | "(from `combine_emu_results.py`)" — does Part 1 create a script of that exact name? |
| 111 | `emu-combined-counts_silva.tsv` — is that the exact filename Part 1 writes? |
| 110 | Column order `tax_id \| species \| genus \| … \| superkingdom` and the lowercase rank names at L117 — do they match Part 1's output header exactly? Case matters: L116 says a mismatch errors. |
| 808 | "Comparing SILVA and RDP results" — does Part 1 produce an RDP counts table, and under what filename? |
| 949 | Dufrêne & Legendre 1997 is cited here but is not in the README's citation list at README L100. |
| — | README L52 defines `ps_relab` and `ps_estcounts` for read-based data. This document never mentions either, so a reader arriving from the shotgun SOP will not find the objects the README told them to expect. |

## Rewrite plan

1. **Sample-identity discipline (F-01, F-02).** Add the Stage 1 alignment guard, move the
   name-mismatch diagnostic up to sit beside it, and rewrite the Stage 4 block so the depth
   gate runs before normalisation and rebuilds both phyloseq objects with a `stopifnot` at the
   end. Derive every grouping vector from `sample_data()`, never from `metadata`. ~50 lines
   changed. Independent of the other documents. Do this first: it is the root cause of the
   largest class of defect and F-06's fix touches the same objects.
2. **Statistics corrections (F-03, F-04, F-07, F-05, F-12).** Alpha diversity gate and
   adjusted labels; pairwise PERMANOVA p-adjustment; indicator-species FDR across all taxa;
   `neg_lb = FALSE`; the `symnum.args` symbol vector. Five independent edits, ~90 lines
   changed in total. Independent of the other documents. F-04 and F-12 carry
   NEEDS-BENCH-CHECK items — run both checks in one R session before applying.
3. **Differential abundance coherence (F-06, F-14).** Aggregate MaAsLin2 to the same rank as
   ANCOM-BC2, then add the consensus block that the document has promised three times. Must
   follow item 2 so that `neg_lb` is settled before the consensus code is written against
   `da_ancom$res`. ~40 lines added. Independent of the other documents.
4. **Resolve the three scope and method contradictions (F-09, F-10, F-11, F-13).** Banner and
   Section 5 intro; the Stage 3 QC object; the Aitchison depth paragraphs; the Jaccard
   equivalence sentence. ~45 lines changed. **F-09 needs a cross-document decision** — the
   sentence should name what the read-based SOP requires, so agree the wording with whoever
   owns that document's Section 13.
5. **Non-independent designs subsection (F-08).** Add the worked block after Step 4 and repoint
   L36. This is the largest single addition, ~35 lines, and it is what makes the packages at
   L83 earn their place. Independent of the other documents.
6. **Documentation debt (F-16, F-17, F-21, F-22, F-23, F-24).** Metadata file format and factor
   level naming; decontam threshold and blank count; the vegan version claim; seeds; the
   SILVA/RDP procedure; runtimes. ~45 lines. F-24 and F-21 are blocked on bench checks;
   everything else can proceed now.
7. **Structure (F-15, F-18, F-19).** Collapse Stage/Section/Step into one numbering scheme,
   demote Steps 1-6 under Beta diversity, fix the expected-output block, lift the checkpoint
   out of the diagnostic block. Do this last — it moves headings that items 1-6 edit, and the
   README (L53) holds the read-based SOP up as the alignment exemplar, so **check the target
   numbering against that document before renumbering.** ~30 lines of heading and pointer
   changes, plus the Key objects table's "Where it's built" column.
8. **Polish (F-25 through F-36, excluding those already closed above).** One pass, ~30 lines.
   Independent of everything. Three of these carry NEEDS-BENCH-CHECK items — F-29, F-31 and
   F-35 — which can be settled in the same R session as item 2's.

### Self-check

- [x] Ledger accounts for every heading in the file — 27 rows, matching all 27 `#`/`##`/`###`
      headings plus the front matter block
- [x] Every finding has a line-anchored verbatim quote
- [x] Every finding has a concrete Failure line — verified mechanically across all 36 blocks,
      not by impression
- [x] Every S1 and S2 has paste-ready replacement text
- [x] Every `NEEDS-BENCH-CHECK` names the one check that settles it — F-04, F-12, F-21, F-24,
      F-29, F-31, F-35 (seven, all carrying the check in the Confidence field so a mechanical
      scan finds them)
- [x] No proposed cut touches load-bearing content — the only removals proposed are two unused
      package installs (F-26) and one unused `library()` call
- [x] S4 count = 12, ≤ 15
- [x] Sections match the required skeleton exactly, in order — all 36 finding blocks run
      `Where → Quote → Defect → Failure → Type → Confidence → Fix`

**Correction history.** The first version of this report asserted `CONTRACT: PASS` while
violating the finding-block skeleton: 19 findings had no `Confidence` field, 12 of those also
had no `Type` field, 10 findings ran `Defect → Type → Failure` against the contract's order,
and F-31 carried its bench check inside the `Fix` line where no field scan would find it. All
four are repaired above. Grading the previously missing fields honestly moved F-29 and F-35
to `NEEDS-BENCH-CHECK`, taking the bench-check roster from five to seven; the two places that
enumerated it (Rewrite plan items 2 and 8) were corrected to match. No finding was added,
removed, re-severitied, or re-worded in its Defect, Failure or Fix text.

CONTRACT: PASS
