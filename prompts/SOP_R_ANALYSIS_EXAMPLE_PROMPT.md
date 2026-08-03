# SOP_R_Analysis — Worked-Example Rebuild (real dataset, real figures)

**To run this:** open a fresh session on NeSI, `cd` into a clone of this
repository, check out the working branch, and say

> Read `prompts/SOP_R_ANALYSIS_EXAMPLE_PROMPT.md` and run it. It is
> self-contained.

**What this is.** `SOP_R_Analysis.md` teaches the R half of the workflow but
shows only code — no output. This task gives it **worked-example figures**: pick a
small, publicly available dataset that reduces to a count table, run the SOP's own
workflow on it end to end, and embed each resulting figure into the tutorial at the
step that produces it, with the example data and a re-runnable script committed so
anyone can reproduce or regenerate it.

**What this is not.** You are **not** rewriting the tutorial's instructions and
**not** changing its policy that Part 2 runs locally on the reader's own machine.
You are adding real *expected output* (figures + short captions) beside the
existing steps, plus a linked `examples/` folder. The prose, code, object names and
guidance stay as they are.

---

## Configure (defaults chosen; override any line if you prefer)

| Choice | Default | Alternative |
| --- | --- | --- |
| Data type | **16S amplicon, integer counts** — exercises the SOP's full path (SRS + count-based ANCOM-BC2) | Shotgun MetaPhlAn (relative abundance): then **skip SRS** and use the compositional path (`SOP_READBASED_NeSI.md` §13). Only do this if you specifically want to demo that path. |
| Dataset | **Your call — apply the criteria below and pick the best-fitting one you can obtain cheaply.** `phyloseq::GlobalPatterns` is the zero-friction fallback (integer 16S counts, taxonomy, `SampleType` grouping, no download) | A 16S set with real negative controls (for a genuine `decontam` demo), or a shotgun table (compositional path) — see **Dataset selection** |
| Figure placement | **Inline, at each producing step** | A single "Worked example" appendix (less useful — the reader wants output where they are) |
| Commit example data + script | **Yes**, under `examples/r_analysis/` | Keep external and link (worse for reproducibility) |
| Group labels | **Keep the dataset's real labels** (authenticity) | Subset/relabel for a cleaner 2–3-group comparison — allowed, but keep it truthful; do not invent biology |

---

## Environment

R sits behind a module on NeSI and is not on `PATH` in a bare login shell — load it
yourself. The reader is told to run Part 2 locally; that guidance is unchanged. You
are only *generating the example*, so running on NeSI's R is fine.

- `module load R/<version>` (use `module spider R` to pick one), then install the
  packages the SOP's install block names into a user/project library. The R
  environment the reviews used already has them — see `reviews/00_ENVIRONMENT.md`.
- Package set (from the SOP, do not substitute): CRAN — `tidyverse, vegan, ggpubr,
  EnvStats, SRS, ape, permute, phangorn, indicspecies, lme4, lmerTest, emmeans,
  broom, broom.mixed`; Bioconductor — `phyloseq, decontam, ANCOMBC, Maaslin2,
  microbiome`; GitHub — `microbiomeutilities, pairwiseAdonis`.
- Set a fixed `set.seed()` at the top of the script so ordinations, SRS and
  permutation tests reproduce.

---

## Dataset selection

**Criteria.** (a) Publicly available and redistributable (the *derived* count table
may be shared — check the license). (b) Reduces to an **integer count table**, a
**taxonomy table** (or ranks inside the count table), and a **metadata table**.
(c) A categorical grouping variable with **≥2 groups, ideally ≥5 samples/group**, so
PERMANOVA / differential-abundance / indicator figures are meaningful rather than
degenerate. (d) *Bonus:* negative controls, so the `decontam` prevalence step has
real blanks. Keep it small — subset if the OTU count is huge (GlobalPatterns has
~19k OTUs; prune to prevalent taxa).

**You pick the dataset** — apply the criteria above and choose the best-fitting one
you can obtain without much effort; a thematically apt or negative-control-bearing
set is a bonus, not a requirement. If nothing better is readily to hand, the
zero-friction fallback is `data(GlobalPatterns, package = "phyloseq")` — integer
counts, taxonomy to genus, `SampleType` grouping. Prune low-prevalence OTUs and
optionally collapse to a clean 2–3-group comparison so the DA/PERMANOVA figures read
well. GlobalPatterns has **no negative controls**, so for `decontam` either (i) use a
dataset that has blanks, or (ii) run `decontam` on a labelled subset and mark that
one figure "illustrative — this dataset has no true blanks." **Do not fabricate
blanks silently** — whichever dataset you choose, be honest about what it can and
cannot demonstrate.

**Alternatives worth a look:** `curatedMetagenomicData` (Bioconductor — real shotgun
species tables with rich metadata, for the compositional path); `microbiome::dietswap`
or `microbiome::atlas1006`; a `mia` example dataset; or a small Qiita / ENA study that
ships a BIOM/count table *with* negative controls. Whatever you pick, record its
accession, citation and license in the example `README.md`.

---

## What to run — map the example to the SOP's sections

Run the SOP **end to end using its own code and object names** (`ps_raw`, `ps_srs`,
`ps_relab`, `ps_estcounts`; SRS for normalisation; the SOP's ranks and defaults),
adapting only the column/file names to the example data. Capture one figure at each
step that produces one. Target set (skip any the data cannot support and **say so in
the caption and the report**):

| SOP section | Figure to capture |
| --- | --- |
| §3–§4 Load / decontaminate | input sanity + the `decontam` prevalence diagnostic |
| §5 Explore | library-size distribution; observed-richness / rarefaction; a first ordination |
| §6 Normalise (SRS) | library sizes before vs after SRS |
| §7 Alpha diversity | alpha metrics by group, with the test result |
| §8 Beta diversity | PCoA/NMDS (Bray–Curtis **and** Aitchison), dispersion check, PERMANOVA result |
| §9 Taxonomy barplots | relative-abundance barplot by group |
| §10 Differential abundance | ANCOM-BC2 (and/or MaAsLin2) LFC / effect-size plot |
| §11 Indicator species | IndVal table or plot |
| §12 Figures & reproducibility | a final publication-style figure; capture `sessionInfo()` |

**Figure craft.** Save each as PNG (≥150 dpi, legible at tutorial width; SVG too if
cheap). Axis labels, legend and units present; **colour-blind-safe palette**
(see the `dataviz` skill / `references/palette.md` if available). Titles short. The
figure must be produced by the SOP's actual code so it matches what a reader's own
run would produce.

---

## Deliverables

1. **`examples/r_analysis/`** containing:
   - `counts.tsv`, `taxonomy.tsv`, `metadata.tsv` — the example inputs (small).
   - `run_example.R` — a single script that regenerates **every** figure from those
     three files, with `set.seed()` and the package loads. No manual steps.
   - `figures/` — the exported PNGs (and SVGs).
   - `sessionInfo.txt` — captured at the end of the run.
   - `README.md` — dataset provenance (accession, citation, license), one line on any
     subsetting/relabelling, and `Rscript run_example.R` to regenerate.
2. **`SOP_R_Analysis.md`** edited to:
   - Embed each figure at its producing step: `![alt text](examples/r_analysis/figures/NN_name.png)` plus a **one–two-sentence caption** stating what the reader should see (this is expected-output / layer-1 content — keep it short).
   - Add a short **"Worked example"** note near the top (after Before-you-start) naming the dataset and pointing at `examples/r_analysis/` — so a reader knows the figures are real and reproducible.
3. **Commits**, per logical unit (e.g. one commit for `examples/` data+script+figures, one for the SOP embeds), on the working branch. **Do not push.**

---

## Acceptance checks (run as scripts, not by eye)

1. **The example runs clean.** `Rscript examples/r_analysis/run_example.R` completes
   without error from the committed inputs on a fresh R; capture the log. Any step the
   dataset cannot support must be handled explicitly (skipped with a message), not
   crash.
2. **Every embedded figure exists.** For each `![...](path)` in `SOP_R_Analysis.md`,
   the file exists on disk and is non-empty. No dead image links.
3. **The tutorial did not regress.** Re-run the three `TUTORIAL_SPEC.md` §11 scans on
   `SOP_R_Analysis.md`: the layer-1 heading count has **not dropped**, the
   over-80-word (genuine-prose) count has **not risen** (captions are short), and no
   V3 banned words were introduced. The consolidated keep-list anchors for R_Analysis
   still `grep -F` to exactly one hit each (regression contract — see
   `reviews/structure/00_PLAN.md`).
4. **Figures are legible and honest.** Axis labels/legend present, colour-blind-safe,
   and the caption matches what the figure shows. The `decontam` figure is flagged if
   the dataset lacks true blanks. Provenance + license recorded and permit sharing the
   derived table.

---

## Stop and report

Report: the dataset chosen (accession + license), which figures were produced vs
skipped and why, the acceptance-check outputs (run log, dead-link check, §11 scans,
keep-list grep), and the commit hashes. **Do not push** — leave that for the lab.

*Optional stretch (only if asked):* a second, tiny shotgun / relative-abundance
example to illustrate the compositional path (`SOP_READBASED_NeSI.md` §13) — same
structure under `examples/r_analysis_shotgun/`. Keep the core deliverable to the one
16S example unless told otherwise.
