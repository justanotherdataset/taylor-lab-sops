## Document: SOP_R_Analysis.md

This is Part 2: a platform-agnostic R walkthrough from combined count tables to
publication figures and statistics (phyloseq, decontam, SRS, alpha/beta
diversity, PERMANOVA, differential abundance, indicator species). It is unusually
careful — the load-bearing warnings (raw vs SRS objects, pre-normalisation before
DA tools, relative-abundance guard, positional sample alignment, gate-before-
bracket for figures, FDR-before-filtering) are all present and correct, and the
statistical reasoning is sound. It is close to ready. The single change that would
most improve it is fixing the one path that silently reports **unadjusted**
pairwise-PERMANOVA p-values as BH-corrected (F-01): everything else the reader is
told to trust actually holds, which makes that one false claim the most dangerous
line in the file.

## Section ledger

| § | Heading | Lines | Verdict | Findings |
|---|---|---|---|---|
| — | Part 2: R Analysis (title) | 3 | CLEAN | — |
| — | Quick Roadmap: What You'll Do | 13-38 | TIGHTEN | F-05 |
| — | Key objects you'll work with | 40-59 | CLEAN | — |
| 1 | Analysis of Amplicon/Count Data in R | 61-63 | CLEAN | — |
| 1.x | Installing and loading libraries | 65-98 | TIGHTEN | F-03 |
| 1.x | Stage 1: Loading and preparing your data | 100-236 | CLEAN | — |
| 1.x | Stage 2: Decontamination and building phyloseq | 238-305 | TIGHTEN | F-04 |
| 1.x | Stage 3: Exploring your data before analysis | 307-374 | CLEAN | — |
| 1.x | Stage 4: Normalisation | 376-465 | CLEAN | — |
| 1.x | Alpha diversity | 467-572 | CLEAN | — |
| 1.x | Beta diversity | 574-578 | RESTRUCTURE | F-05 |
| — | Step 1: Distance matrices | 580-603 | CLEAN | — |
| — | Step 2: Ordination | 605-685 | REWRITE | F-02 |
| — | Step 3: Check dispersion | 687-784 | CLEAN | — |
| — | Step 4: PERMANOVA | 786-831 | CLEAN | — |
| — | Step 5: Pairwise PERMANOVA (for >2 groups) | 833-852 | REWRITE | F-01 |
| — | Step 6 (optional): Jaccard as a third lens | 854-885 | CLEAN | — |
| 1.x | Taxonomy barplots | 887-922 | CLEAN | — |
| 2 | Going Further in R | 924-926 | CLEAN | — |
| 2.x | Why you can't just test each taxon individually | 928-945 | CLEAN | — |
| 2.x | Differential abundance with ANCOM-BC2 | 947-1001 | CLEAN | — |
| 2.x | Differential abundance with MaAsLin2 | 1003-1078 | CLEAN | — |
| 2.x | A note on ALDEx2 | 1080-1082 | CLEAN | — |
| 2.x | Indicator species analysis | 1084-1134 | CLEAN | — |
| 2.x | Figures | 1136-1145 | CLEAN | — |
| 2.x | Reproducibility | 1147-1155 | CLEAN | — |
| — | Common Pitfalls to Avoid | 1157-1186 | CLEAN | — |

## Findings

### F-01 · S1 · pairwise.adonis2 silently discards p.adjust.m; unadjusted p reported as BH-corrected
- **Where:** SOP_R_Analysis.md:837-852, § Step 5 Pairwise PERMANOVA
- **Anchor:** `The output shows which pairs differ; you might find Takapourewa vs Zealandia`
- **Quote:**
  > pairwise.adonis2(dist_bray ~ Site,
  >                  data       = data.frame(sample_data(ps_srs)),
  >                  p.adjust.m = "BH")
  > …
  > `p.adjust.m = "BH"` applies Benjamini-Hochberg correction.
- **Defect:** `pairwise.adonis2()` has no `p.adjust.m` parameter. The argument
  falls into the function's `...` and is silently discarded; the function applies
  **no** multiple-testing correction of any kind. (`p.adjust.m` belongs to the
  older `pairwise.adonis()` — the "2" variant does not take it.) The reader is
  told this line "applies Benjamini-Hochberg correction"; it does not.
- **Failure:** Reader runs the block on three sites, reads the per-pair p-values
  believing they are BH-adjusted, and reports e.g. "Takapourewa vs Zealandia
  p = 0.01 (BH-corrected)" in the thesis. The p-values are raw. With three or more
  pairwise comparisons the corrected values are larger, so the reader over-states
  significance — a wrong-but-plausible result with no error message.
- **Type:** CORRECTNESS
- **Confidence:** VERIFIED
- **Evidence:** Settled by the environment probe (reviews/00_ENVIRONMENT.md, Q7)
  against the canonical upstream source
  `pmartinezarbizu/pairwiseAdonis/R/pairwise.adonis2.R`:
  `pairwise.adonis2 <- function(x, data, strata = NULL, nperm=999, ... )` — no
  `p.adjust.m`, and the body performs no p-value adjustment. `pairwiseAdonis` is
  not installed on this cluster (00_ENVIRONMENT.md R-package table), so a local
  `args(pairwiseAdonis::pairwise.adonis2)` reconfirms it in seconds. The claim at
  :852 directly contradicts the function's actual behaviour.
- **Fix:**
  ```r
  # devtools::install_github("pmartinezarbizu/pairwiseAdonis/pairwiseAdonis")
  library(pairwiseAdonis)

  # NOTE: pairwise.adonis2() does NOT adjust p-values. It has no p.adjust.m
  # argument — anything passed there is silently ignored (that argument belongs
  # to the older pairwise.adonis(), a different function). Extract the per-pair
  # p-values and apply the correction yourself.

  # Bray-Curtis
  pw_bray <- pairwise.adonis2(dist_bray ~ Site,
                              data = data.frame(sample_data(ps_srs)))

  # Aitchison
  pw_ait  <- pairwise.adonis2(dist_ait ~ Site,
                              data = data.frame(sample_data(ps_raw)))

  # Pull each pair's p-value (drop the 'parent_call' entry) and BH-adjust.
  adjust_pairwise <- function(pw) {
      pairs  <- pw[names(pw) != "parent_call"]
      p_raw  <- sapply(pairs, function(res) res[["Pr(>F)"]][1])
      data.frame(pair  = names(p_raw),
                 p_raw = p_raw,
                 p_BH  = p.adjust(p_raw, method = "BH"),
                 row.names = NULL)
  }

  adjust_pairwise(pw_bray)
  adjust_pairwise(pw_ait)
  ```
  Replace the closing sentence with: "`pairwise.adonis2()` performs no
  multiple-testing correction itself; `adjust_pairwise()` above extracts the raw
  per-pair p-values and applies Benjamini-Hochberg. Report the `p_BH` column. The
  output might show Takapourewa vs Zealandia significant (p_BH = 0.03) but
  Zealandia vs YoungNicksHead not (p_BH = 0.45)."

### F-02 · S2 · pcoa_ait plotted before it is created — reader hits "object not found"
- **Where:** SOP_R_Analysis.md:637-659, § Step 2 Ordination (PCoA with Aitchison)
- **Anchor:** `plot_ordination(ps_raw, pcoa_ait, color = "LibSize")`
- **Quote:**
  > sample_data(ps_raw)$LibSize <- sample_sums(ps_raw)
  > plot_ordination(ps_raw, pcoa_ait, color = "LibSize") +
  >     geom_point(size = 3) + theme_bw() +
  >     labs(title = "Aitchison PCoA coloured by library size")
- **Defect:** This library-size check block uses `pcoa_ait`, but `pcoa_ait` is not
  created until the *next* code block (`pcoa_ait <- ordinate(...)`, line 647). A
  reader running top-to-bottom evaluates the check block first and errors.
- **Failure:** Reader runs the section in order → R aborts the block with
  `Error: object 'pcoa_ait' not found` → the reader is blocked at the Aitchison
  diagnostic and the document offers no hint that the two blocks are out of order.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED
- **Evidence:** `grep -n` shows first use at line 639
  (`plot_ordination(ps_raw, pcoa_ait, color = "LibSize")`) and the only assignment
  at line 647 (`pcoa_ait  <- ordinate(ps_raw, method = "PCoA", distance = dist_ait)`).
  Use precedes definition; there is no earlier assignment of `pcoa_ait` anywhere in
  the file.
- **Fix:** Move the `pcoa_ait <- ordinate(...)` / `evals_ait` / group-coloured plot
  block to run **before** the library-size diagnostic. Concretely, order the
  Aitchison subsection as:
  ```r
  # 1. Compute the ordination first.
  pcoa_ait  <- ordinate(ps_raw, method = "PCoA", distance = dist_ait)
  evals_ait <- pcoa_ait$values$Relative_eig
  pc1_ait   <- round(100 * evals_ait[1], 1)
  pc2_ait   <- round(100 * evals_ait[2], 1)

  # 2. Group-coloured ordination.
  plot_ordination(ps_raw, pcoa_ait, color = "Site") +
      geom_point(size = 3) + theme_bw() +
      stat_ellipse(type = "norm", linetype = 2) +
      labs(x = paste0("PCoA Axis 1 (", pc1_ait, "%)"),
           y = paste0("PCoA Axis 2 (", pc2_ait, "%)"),
           title = "Aitchison (robust CLR, raw counts)") +
      theme(text = element_text(size = 15))

  # 3. Library-size diagnostic (needs pcoa_ait to exist).
  sample_data(ps_raw)$LibSize <- sample_sums(ps_raw)
  plot_ordination(ps_raw, pcoa_ait, color = "LibSize") +
      geom_point(size = 3) + theme_bw() +
      labs(title = "Aitchison PCoA coloured by library size")
  ```

### F-03 · S3 · devtools used to install microbiomeutilities, but its own install is commented out
- **Where:** SOP_R_Analysis.md:77-79, § Installing and loading libraries
- **Anchor:** `devtools::install_github("microsud/microbiomeutilities")`
- **Quote:**
  > # microbiomeutilities for aggregate_top_taxa2
  > # install.packages("devtools")
  > devtools::install_github("microsud/microbiomeutilities")
- **Defect:** The `install.packages("devtools")` line is commented, but the
  `devtools::install_github(...)` line below it is live and depends on devtools.
- **Failure:** A reader without `devtools` runs the install block and gets
  `Error: there is no package called 'devtools'`, blocking installation of
  `microbiomeutilities` (needed for `aggregate_top_taxa2` in the taxonomy
  barplots). Recoverable once they read the commented line above, but it costs
  time and confidence on the very first block.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED
- **Evidence:** Line 78 `# install.packages("devtools")` is commented while line 79
  `devtools::install_github("microsud/microbiomeutilities")` is live and calls
  `devtools::`.
- **Fix:** Uncomment the dependency: change `# install.packages("devtools")` to
  `install.packages("devtools")`.

### F-04 · S4 · Example phyloseq printout says "5 sample variables" but the example metadata defines 7
- **Where:** SOP_R_Analysis.md:284-289, § Stage 2 (expected output)
- **Anchor:** `12 samples by 5 sample variables`
- **Quote:**
  > sample_data() Sample Data:       [ 12 samples by 5 sample variables ]
- **Defect:** The worked metadata example (line 196) has seven variables after the
  SampleID key — Site, Sex, Species, Season, Batch, Plate, SampleType — so the
  printout for that example would read "7 sample variables", not 5.
- **Failure:** A reader who matches this "you should see something like" block
  against their own object (having just been told to check when "the numbers look
  wrong") sees 7 where the doc shows 5 and wastes time hunting a non-problem.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED
- **Evidence:** Metadata header at line 196 lists 8 tab-separated columns
  (`SampleID Site Sex Species Season Batch Plate SampleType`); one is the row key,
  leaving 7 sample variables, contradicting the "5" in the printout.
- **Fix:** Change `[ 12 samples by 5 sample variables ]` to
  `[ 12 samples by 7 sample variables ]` (matching the 7-column example metadata).

### F-05 · S4 · Roadmap's Stage 5 has no heading; Beta-diversity Steps sit at their parent's level
- **Where:** SOP_R_Analysis.md:30, § Quick Roadmap; and §§ 574-885
- **Anchor:** `STAGE 5: Analysis`
- **Quote:**
  > STAGE 5: Analysis
  >    • Alpha diversity
  >    • Beta diversity
- **Defect:** The body has `Stage 1`–`Stage 4` headings but no `Stage 5`; the
  analysis subsections (Alpha diversity, Beta diversity, Taxonomy barplots) appear
  as bare `###` headings, and the six Beta-diversity "Step" subsections are also
  `###` — the same level as their parent "Beta diversity", so in a table of
  contents "Step 1: Distance matrices" reads as a sibling of "Beta diversity", not
  a child.
- **Failure:** A reader navigating by the roadmap looks for "Stage 5" and cannot
  find it; a reader skimming the TOC cannot tell the six Steps belong under Beta
  diversity. Costs orientation, not correctness.
- **Type:** STRUCTURE
- **Confidence:** CONFIRMED
- **Evidence:** `grep -nE '^#{1,4} '` shows `### **Beta diversity**` (:574) and
  `### **Step 1: Distance matrices**` (:580) at identical `###` depth, and no
  `Stage 5` heading anywhere in the file, while the roadmap (:30) advertises
  "STAGE 5: Analysis".
- **Fix:** Add a `### **Stage 5: Analysis**` heading before "Alpha diversity", demote
  "Alpha diversity", "Beta diversity" and "Taxonomy barplots" to `####`, and demote
  the six "Step" headings to `#####` so the hierarchy matches the roadmap.

## Verified against the cluster

Instrument: `module load R/4.6.0-foss-2026 R-bundle-Bioconductor/3.23-foss-2026-R-4.6.0`
(R 4.6.0), fixtures under a scratch directory, cleaned up. All claims below HELD.

- **`ordinate(ps, method="PCoA", distance=<dist object>)` accepts a precomputed
  dist and exposes `$values$Relative_eig`** (used at :619-622 and :647-650). Built
  an 8-taxa × 6-sample phyloseq, `db <- phyloseq::distance(ps,"bray")`,
  `o <- ordinate(ps,"PCoA",distance=db)` → `class: pcoa`,
  `head(o$values$Relative_eig)` = `0.449 0.267 0.202 …`. HOLDS — the `pcoa_bray$values$Relative_eig`
  and `pcoa_ait$values$Relative_eig` extractions are valid.
- **`plot_ordination(ps, o, color="Site")` on that PCoA** → returns a ggplot
  object (only a benign phyloseq `aes_string` deprecation warning). HOLDS.
- **`SRS(counts_raw, Cmin = Cmin, set_seed = TRUE)`** (:454). `args(SRS)` =
  `function (data, Cmin, set_seed = TRUE, seed = 1)`; ran on a count data.frame with
  `Cmin = min(colSums)` → every output column sums to exactly Cmin. HOLDS — the
  argument name and the "scales every sample to Cmin" claim (:391-393) are correct.
- **`adonis2(d ~ Site * Sex, permutations = how(nperm=...), by="terms")`** (:809-821).
  Ran with `perm_free <- how(nperm=99)` → returns a valid adonis2 table; `how()`
  object accepted as `permutations`, `by="terms"` accepted. HOLDS.
- **`vegdist(counts_raw_t, method = "robust.aitchison")`** (:598) — valid vegan
  method, returned a dist. HOLDS.
- **(From reviews/00_ENVIRONMENT.md, treated as fact)** `symnum` n+1 cutpoints/
  symbols rule → the SOP's 6-cutpoint/5-symbol calls (:510,:560) are correct (Q8);
  `adonis2` default is `by = NULL` in vegan 2.7-3, confirming the SOP's warning at
  :805 (Q9); `permute::how` takes `nperm` (Q-table); `multipatt(control=how())`
  signature valid (Q-table). All HOLD.

## Keep list

- **The `_raw` vs `_srs` object rule** (:57, `The one rule to remember`) and the
  which-normalisation-for-which-analysis table (:405-413). Load-bearing; a rewrite
  tempted to "de-duplicate" against the Common Pitfalls copy must keep both.
- **The relative-abundance guard** (:145-149, `Column sums are 100 or 1`). Prevents
  a silent wrong-result path; never cut as "defensive boilerplate".
- **The positional-alignment warning + stopifnot** (:168-182,
  `index them POSITIONALLY`). This is the class of silent failure the whole SOP
  guards against.
- **The depth-gate "rebuild ps_raw" note** (:444-449, `a stale ps_raw will run
  without error`). Removing the rebuild reintroduces a silent object-mismatch bug.
- **The gate-before-bracket figure logic** (:498-517, `bracket_frame`) and the
  warning that `stat_compare_means()` runs its own unadjusted tests. Prevents a
  figure disagreeing with the reported statistics.
- **The FDR-before-filtering warning for indicator species** (:1120-1134,
  `Correcting on the filtered subset`). Correct and easy to "simplify" wrongly.
- **The `neg_lb`/structural-zero small-sample caution** (:986, `roughly 30 or more
  samples`). A why-this-setting paragraph; keep the reasoning.

## Gaps

- **How to read the `pairwise.adonis2` result object — SHOULD-ADD (~3 lines).**
  Even after F-01's fix, the SOP never shows the shape of the returned list or that
  the p-value lives at `res[["Pr(>F)"]][1]` per pair. The F-01 fix supplies an
  extraction helper; keep it. Without it the reader cannot locate the numbers to
  report.
- **Expected runtime / scale for `ancombc2` and `Maaslin2` — CONSIDER (~2 lines).**
  Neither step states how long it should take or what "still running" looks like on
  a real dataset, so a reader cannot tell a slow fit from a hung session.
  NOT-VERIFIABLE-HERE (needs a real dataset and `ANCOMBC`, which is not installed on
  this cluster — reviews/00_ENVIRONMENT.md Q11); settle locally with
  `system.time(ancombc2(...))` on the actual object.
- **What "no contaminants found" or "most taxa removed" means at the decontam step
  — CONSIDER (~2 lines).** The step reports counts but gives no expected range or
  what to do if decontam flags an implausible number of taxa.

## Cross-document flags

- **:7 / :118-119** — claims `SOP_CONCOMPRA_NeSI.md` Section 8 and
  `SOP_READBASED_NeSI.md` Section 13 each contain a reshaping block that converts
  their output to this SOP's input contract, and that READBASED §13 "lists what
  changes here when the input is relative abundance." Cannot verify from this file;
  a later cross-document agent should confirm those sections exist and produce the
  stated shape.
- **:126-130** — assumes the upstream combined table is
  `emu-combined-counts_silva.tsv` from `combine_emu_results.py` with columns
  `tax_id | species | … | superkingdom | sample1 …`. Confirm this matches what
  `SOP_EMU_NeSI.md` actually writes (name, separator, column order).
- **:114 / input contract** — the required `SampleType` column and integer-count
  contract should match the README's stated Part-2 input contract
  (README.md:58). Reads consistent from here; cross-agent should confirm.

## Rewrite plan

1. **F-01 (S1) — Step 5 Pairwise PERMANOVA.** Replace the `p.adjust.m = "BH"`
   calls and the "applies Benjamini-Hochberg correction" sentence with the
   extract-then-`p.adjust` block. Closes F-01 and the first Gap. Independent;
   do first. Small (one code block + one sentence).
2. **F-02 (S2) — Step 2 Ordination.** Reorder the Aitchison subsection so
   `pcoa_ait <- ordinate(...)` and the group-coloured plot precede the library-size
   diagnostic. Closes F-02. Independent. Small (move two code blocks).
3. **F-03 (S3) — install block.** Uncomment `install.packages("devtools")`.
   Closes F-03. Independent. Trivial.
4. **F-04 (S4) — Stage 2 expected output.** Change "5 sample variables" to "7".
   Closes F-04. Independent. Trivial.
5. **F-05 (S4) — analysis-section headings.** Introduce `Stage 5: Analysis` and fix
   the Alpha/Beta/Step heading levels to match the roadmap. Closes F-05.
   Independent of 1-4; touches only headings. Small.

## Self-check

```
$ python3 <contract self-check> reviews/R_ANALYSIS.review.md SOP_R_Analysis.md
findings=5 S1=1 S2=1 S3=1 S4=2
CLEAN
```

By-hand checks the script cannot do:
- [x] Ledger accounts for every heading in the file (all 27 `#`–`####` headings from
      `grep -nE '^#{1,4} '` are in the Section ledger, in order).
- [x] No proposed cut touches load-bearing content (no finding proposes a CUT; the
      verdicts are TIGHTEN/REWRITE/RESTRUCTURE, and the Keep list is explicit).
- [x] Every finding is CONFIRMED or VERIFIED — no NOT-VERIFIABLE-HERE among the
      findings; the two NOT-VERIFIABLE items (ancombc2 runtime, downstream sections)
      live in Gaps/Cross-document flags with the check that would settle each.

CONTRACT: PASS
