# DADA2 → R downstream worked example

The full chain end-to-end: the DADA2 example's outputs one directory up
(`../counts_dada2.tsv`, `../metadata.tsv`, `../asv_tree.nwk`) run **straight
through the `SOP_R_Analysis.md` workflow**, with no reshaping — grouped by the
TOFI cohort's **Ethnicity × Gender** design. This is the point of the hand-off:
the DADA2 count table is already in the shape Part 2 opens on. Reproduce with:

```bash
module load R-bundle-Bioconductor/3.23-foss-2026-R-4.6.0
Rscript run_downstream.R          # or submit as a short SLURM job
```

> **Illustrative, de-identified example output — not from your own run.** It
> shows the *shape* of the DADA2 → R analysis on real community data. Every
> figure carries `Sample###` labels and only Ethnicity/Gender, exactly as the
> upstream example ships.

## What it runs (mirroring `SOP_R_Analysis.md`)

```
load & split counts_dada2.tsv (tax_id + ranks + samples)   Section 3
  -> no decontam (this subset has no blanks)               Section 4
  -> prevalence + depth filter -> ps_raw (+ ASV tree)
  -> SRS normalise to Cmin -> ps_srs                       Section 6
  -> alpha diversity by Ethnicity / Gender                 Section 7
  -> Bray-Curtis + weighted UniFrac PCoA;                  Section 8
     PERMANOVA ~ Ethnicity * Gender (9999 perms)
  -> genus taxonomy barplot by group                       Section 9
  -> ANCOM-BC2 differential genera by Ethnicity            Section 10
```

Two-factor design (`~ Ethnicity * Gender`) replaces the single-grouping model in
`examples/r_analysis/`, and **weighted UniFrac** is added because the DADA2
example ships an ASV tree (`../asv_tree.nwk`, midpoint-rooted here — SOP
Appendix D). Object names follow the SOP (`ps_raw`, `ps_srs`, `dist_bray`).

## Headline results

On the 157-sample cohort (9,652 ASVs → **484** after a 5%-prevalence and
3,000-read filter; SRS-normalised to Cmin = 4,998):

| Test | Ethnicity | Gender | Ethnicity × Gender |
| --- | --- | --- | --- |
| PERMANOVA, Bray-Curtis | R²=0.007, p=0.31 | R²=0.008, p=0.070 | p=0.27 |
| PERMANOVA, weighted UniFrac | R²=0.007, p=0.29 | **R²=0.012, p=0.039** | p=0.24 |
| Alpha diversity (Shannon, Observed) | ns (p ≥ 0.7) | ns (p ≥ 0.5) | — |

**Gender** shows a modest community-level shift — significant on weighted
UniFrac (phylogenetic; p=0.039), a trend on Bray-Curtis (p=0.070) — while
**Ethnicity** does not (p≈0.30), with no interaction. ANCOM-BC2 (genus, by
Ethnicity) found **0** differentially abundant genera. Effect sizes are small
(~1% of variance each), as is typical for a gut cohort; note that the
phylogenetic distance resolves the Gender signal the taxonomic one only hints
at. **These numbers illustrate the workflow — they are not a finding about the cohort.**

## Figures

| File | Shows |
| --- | --- |
| `figures/01_read_depth_by_group.png` | Library sizes per Ethnicity × Gender cell (sanity + the SRS floor). |
| `figures/02_alpha_diversity.png` | Observed richness and Shannon by Ethnicity (shape = Gender), with Wilcoxon tests in `alpha_stats.txt`. |
| `figures/03_beta_pcoa.png` | Bray-Curtis and **weighted UniFrac** PCoA, coloured by Ethnicity / shaped by Gender, titled with the PERMANOVA terms. |
| `figures/04_taxonomy_barplot.png` | Top-11 genera, relative abundance, faceted by Ethnicity × Gender. |
| *(no `05_ancombc2_lfc.png`)* | ANCOM-BC2 by Ethnicity found **0** significant genera on this subset, so the log-fold-change figure is only drawn when there are hits; see `ancombc2_full_res.tsv` for the full table. |

## Files

| File | What it is |
| --- | --- |
| `run_downstream.R` | The R script: DADA2 outputs → the SOP_R_Analysis.md workflow. |
| `alpha_stats.txt` | Alpha-diversity medians and Wilcoxon tests by Ethnicity and Gender. |
| `permanova_results.txt` | Verbatim `adonis2` tables — Bray-Curtis and weighted UniFrac, `~ Ethnicity * Gender`. |
| `ancombc2_significant.tsv` / `ancombc2_full_res.tsv` | Significant and full ANCOM-BC2 results. |
| `sessionInfo.txt` | Package versions, for reproducibility. |
| `figures/*.png` | The five figures above. |

Inputs are read from the parent `examples/dada2/` directory; nothing here
re-derives them. To run this on your own data, point `../counts_dada2.tsv`,
`../metadata.tsv` and `../asv_tree.nwk` at your Section 5 outputs.
