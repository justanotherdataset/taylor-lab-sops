# Worked example for `SOP_DADA2_NeSI.md`

The three illustrative figures embedded in **Sections 4–6** of the DADA2 SOP,
produced by running the SOP's own workflow (cutadapt → quality profile → DADA2
denoising → SILVA taxonomy) on a **de-identified** subset of the Taylor Lab
**TOFI FU** Illumina V3–V4 16S cohort, grouped by **Ethnicity × Gender** — the
cohort's actual study design, and the same framing as its already-public shotgun
metagenome. Reproducible (lab members, project access) with one submission:

```bash
cd examples/dada2 && sbatch run_example.sh     # ~157 samples, full depth; a batch job
```

> **These are illustrative example outputs from a real cohort — not from your own
> run.** They show the *shape* of good DADA2 output (quality profile, read
> tracking, rarefaction) so you know what to expect. Your ASV counts, merge
> fraction and retention will differ.

## Governance — read this first

This example ships from a **public** repository, so only **de-identified derived
outputs** are committed, and only on the lab's confirmation that ethics/consent
covers public release of a de-identified 16S dataset (established by the cohort's
already-public shotgun metagenome).

| Rule | How it is enforced |
| --- | --- |
| **No raw reads committed** | Reads stay in the access-controlled lab project directory; `run_example.sh` reads them there and commits only figures + tables. |
| **Generic labels only** | Samples are renamed `Sample001`, `Sample002`, … The `label ↔ participant` key is written to a **private** scratch path (`$WORKDIR/private/key.tsv`) and is never committed. |
| **Only two columns published** | `metadata.tsv` carries `Ethnicity`, `Gender`, `SampleType` — nothing else. No participant IDs, dates, or any other clinical field. |
| **k-anonymity** | `select_subset.R` refuses to publish any `Ethnicity × Gender` cell with fewer than 3 samples; rare ethnicity labels are collapsed into a broad label. |

The published cross-tabulation (aggregate counts only) — every cell is well above
the k-anonymity floor:

| | Female | Male |
| --- | --- | --- |
| **Caucasian** | 40 | 26 |
| **Chinese** | 54 | 37 |

## Dataset provenance

| Field | Value |
| --- | --- |
| Cohort | Taylor Lab **TOFI FU** microbiome study |
| Assay | Illumina paired-end **2×300 bp**, 16S **V3–V4** (341F / 785R) |
| Published basis | The cohort's shotgun metagenome is already public under **`<BioProject — fill in>`**, with the same Ethnicity/Gender framing; this de-identified 16S teaching subset is consistent with it. |
| Raw 16S reads | Held in the lab **project directory** (access-controlled); **not** publicly deposited. Lab members reproduce via `run_example.sh`; external readers see the committed illustrative figures. |
| Samples used | The **157** cleanly read↔metadata-matched, non-control samples (controls and non-standard IDs excluded — see below). |

**Read ↔ metadata linkage.** A FASTQ sample name like `AB41273` maps to the
metadata `ID` by its numeric core (strip the 2-letter prefix → `41273` → match
`ID`). Of 192 FASTQ pairs: 13 are controls (`AMP-Control`, `NAT-*`, `CHUNG`,
`*POS`/`*NEG`), 22 have non-standard or typo IDs that do not match, and the
remaining 157 match cleanly. `select_subset.R` keeps only the clean, non-control
matches.

## What was run (mirroring the SOP)

```
1. select_subset.R   de-identify + k-anonymity + write metadata.tsv (+ private key)
2. cutadapt          remove 341F/785R primers          (SOP Section 3)
3. plotQualityProfile aggregate quality -> truncLen     (SOP Section 4)
4. DADA2             filterAndTrim -> learnErrors -> dada -> mergePairs
                     -> removeBimeraDenovo -> assignTaxonomy(SILVA 138.1)
                                                        (SOP Section 5)
5. figures + counts_dada2.tsv in the R-analysis contract (SOP Sections 5g, 6)
```

Modules: `R-bundle-Bioconductor/3.23-foss-2026-R-4.6.0` (dada2, ggplot2, vegan),
`cutadapt/5.2-foss-2023a-Python-3.11.6`. `truncLen = 280/220` (2×300 reads).

## What the figures show

| File | Shows |
| --- | --- |
| `figures/01_quality_profile.png` | Aggregate quality of the primer-trimmed forward and reverse reads; where quality falls off sets `truncLen` (Section 4). |
| `figures/02_read_tracking.png` | Reads surviving each step (input → filtered → denoised → merged → nonchim), one line per sample, median in red — the Section 6 QC checkpoint. |
| `figures/03_asv_rarefaction.png` | ASV richness against sequencing depth, coloured by Ethnicity; whether curves plateau shows if depth is sufficient. |

## Hand-off to the R analysis

`counts_dada2.tsv` is written in the exact shape `SOP_R_Analysis.md` Section 3
loads (tab-separated: `tax_id` + `species … superkingdom` + one integer column
per sample). With `metadata.tsv` it drops straight into that document — and into
`examples/r_analysis/` — to test community differences by Ethnicity, Gender and
their interaction (PERMANOVA, diversity, differential abundance).

## Files

| File | What it is |
| --- | --- |
| `run_example.sh` | SLURM build script: select → de-identify → cutadapt → DADA2 → figures. |
| `select_subset.R` | De-identification + k-anonymity selection. Writes the public `metadata.tsv` and the **private** key. |
| `example_dada2.R` | The DADA2 run and the three figures (mirrors SOP Sections 3–6). |
| `metadata.tsv` | De-identified metadata (`SampleID`, `Ethnicity`, `Gender`, `SampleType`). |
| `counts_dada2.tsv` | De-identified ASV count table in the R-analysis contract. |
| `track.tsv` | Per-sample read tracking (the data behind figure 2). |
| `figures/*.png` | The three illustrative figures embedded in the SOP. |
