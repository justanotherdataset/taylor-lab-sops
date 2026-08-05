# Worked example for `SOP_R_Analysis.md`

Real figures for the R half of the Taylor Lab microbial-community workflow,
produced by running the SOP's own code on a small public dataset. Everything
here is reproducible from three committed input files with one command.

```bash
Rscript run_example.R      # regenerates every figure in figures/
```

## Dataset provenance

| Field | Value |
| --- | --- |
| Dataset | **GlobalPatterns** |
| How to obtain | `data(GlobalPatterns, package = "phyloseq")` — no download |
| Primary citation | Caporaso JG *et al.* (2011) *Global patterns of 16S rRNA diversity at a depth of millions of sequences per sample.* PNAS 108(Suppl 1):4516–4522. |
| Redistribution | Ships with **phyloseq** (McMurdie & Holmes 2013, *PLoS ONE* 8(4):e61217). |
| Licence | phyloseq and its bundled example data are distributed under **AGPL‑3**. GlobalPatterns derives from an openly published study; the small derived count/taxonomy/metadata tables here are shared under the same AGPL‑3 terms, for reproducibility. |

The raw GlobalPatterns object is 19,216 taxa × 26 samples of integer 16S counts
with a genus-level taxonomy and a `SampleType` grouping — it meets the SOP's
input requirements (integer count table + taxonomy + metadata) with no download.

## What was subset or relabelled (kept truthful — no invented biology)

`make_inputs.R` derives the three TSVs from GlobalPatterns:

- **Grouping.** The 9 `SampleType` values are collapsed into one variable
  `Environment` with three levels: **Human** (Feces + Skin + Tongue, n = 9),
  **Freshwater** (Freshwater + Freshwater (creek), n = 5) and **Saline**
  (Ocean + Sediment (estuary), n = 6). **Soil** (n = 3) is dropped (< 5 samples).
  The original label is kept in `OriginalSampleType`.
- **Single grouping variable.** The SOP's tuatara example uses two variables
  (`Site * Sex`); GlobalPatterns has only one meaningful categorical variable,
  so the example uses a single-term `~ Environment` model. Object names, SRS,
  distances and every default are otherwise the SOP's.
- **Taxa pruned** to those present in ≥ 3 samples with total count ≥ 100 across
  the 23-sample subset (4,193 taxa), to keep the committed table small.

### The `decontam` figure is ILLUSTRATIVE

GlobalPatterns has **no extraction blanks**. To exercise the `decontam`
prevalence code path and show the reader the *shape* of its diagnostic, the 3
**Mock** community samples (a positive control of known composition) are marked
`SampleType = "blank"` as stand-in negatives. This is **not a real
contamination screen**: the flagged taxa are an artefact of the illustration and
are **not removed** from the downstream analysis — only the Mock columns are
dropped so the biological comparison stays clean. A dataset with true blanks
would give a meaningful decontam result here.

## Files

| File | What it is |
| --- | --- |
| `counts.tsv` | Integer count table, taxa × samples (first column `tax_id`). |
| `taxonomy.tsv` | Taxonomy table, `tax_id` + ranks (species … superkingdom). |
| `metadata.tsv` | `SampleID`, `Environment`, `OriginalSampleType`, `SampleType`. |
| `make_inputs.R` | Derives the three TSVs from GlobalPatterns (run to regenerate inputs). |
| `run_example.R` | Runs the workflow and writes every figure. `set.seed(42)`. |
| `figures/` | Exported PNG (200 dpi), numbered 01–14; vector SVG twins in `figures/svg/`. |
| `alpha_stats.txt` | Alpha-diversity tests: Kruskal-Wallis + pairwise Wilcoxon (BH), per metric. |
| `permanova_results.txt` | Full PERMANOVA tables (Bray-Curtis and Aitchison). |
| `ancombc2_full_res.tsv` | Full ANCOM-BC2 result table (all genera, all columns). |
| `ancombc2_significant.tsv` | ANCOM-BC2 significant genus × contrast results. |
| `ancombc2_raw.txt` | Verbatim print of the ANCOM-BC2 `res` head + global test. |
| `indicator_all.tsv` | Full `multipatt` sign table with FDR-adjusted p-values. |
| `indicator_species.tsv` | Indicator taxa passing FDR < 0.05. |
| `indicator_summary.txt` | Verbatim `summary(multipatt)` output. |
| `core_microbiome.txt` | Core genera per environment (supplementary). |
| `spieceasi_network_stats.txt` | SPIEC-EASI network summary: nodes, edges (±), density, hubs (supplementary). |
| `spieceasi_edges.tsv` | SPIEC-EASI edge list with signed weights (supplementary). |
| `sessionInfo.txt` | R and package versions captured at the end of the run. |

## Environment

Generated under **R 4.6.0** with the packages named in the SOP's install block
(`phyloseq`, `vegan`, `SRS`, `decontam`, `indicspecies`, `ANCOMBC`, `Maaslin2`,
`ggplot2`, `patchwork`, …). Exact versions are in `sessionInfo.txt`. The SOP's
policy is unchanged: readers run Part 2 locally on their own machine; these
figures were generated only to show expected output. `ggpubr` is not required —
significance brackets are drawn with base ggplot2.

The supplementary network figure needs extra packages, guarded so the script
skips it cleanly if absent: `14_spieceasi_network` needs `igraph`, `ggraph` and
**`SpiecEasi`**, which is GitHub-only — `remotes::install_github("zdk123/SpiecEasi")`.

## Figure inventory

| File | SOP section | Shows |
| --- | --- | --- |
| `01_input_sanity` | §3–4 | Library sizes per sample, coloured by group. |
| `02_decontam_prevalence` | §4 | decontam prevalence-score histogram (**illustrative**). |
| `03_read_depth_by_group` | §5 | Read depth by environment (confounding check). |
| `04_rarefaction` | §5/6 | Rarefaction curves with the Cmin line. |
| `05_explore_pcoa` | §5 | First exploratory PCoA (Bray-Curtis on proportions). |
| `06_srs_before_after` | §6 | Library sizes before vs after SRS. |
| `07_alpha_diversity` | §7 | Observed + Shannon by group, Kruskal-Wallis + BH brackets. |
| `08_beta_pcoa` | §8 | PCoA, Bray-Curtis and Aitchison, with PERMANOVA. |
| `09_beta_dispersion` | §8 | betadisper centroid plots (dispersion check). |
| `10_taxonomy_barplot` | §9 | Phylum composition by environment. |
| `11_ancombc2_lfc` | §10 | ANCOM-BC2 log fold changes (significant genera). |
| `12_indicator_species` | §11 | Top indicator taxa (IndVal.g, FDR < 0.05). |
| `13_publication_figure` | §12 | Publication-style composite of the key panels. |
| `14_spieceasi_network` | §12 | SPIEC-EASI co-occurrence network on prevalent genera (nodes = genera by phylum, edges = sign of association). Optional (§12); illustrative — n=20 is modest and cross-environment edges partly reflect shared habitat. |
