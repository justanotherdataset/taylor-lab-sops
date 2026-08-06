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
| **Generic labels only** | Samples are renamed `Sample001`, `Sample002`, … The `label ↔ participant` key is written to a **private, backed-up path on project** (`/nesi/project/uoa03769/dada2_example_private/key.tsv`), outside the repo, and is never committed — treat it like the clinical sheet. |
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
| Published basis | **⚠ Fill in before public release.** The de-identified release rests on the cohort's shotgun metagenome already being public under BioProject **`<PRJNA/PRJEB — fill in>`** (same Ethnicity/Gender framing). Until this accession is confirmed, the ethics basis is unverifiable — do not merge this example to a public release branch. |
| Raw 16S reads | Held in the lab **project directory** (access-controlled); **not** publicly deposited. Lab members reproduce via `run_example.sh`; external readers see the committed illustrative figures. |
| Samples used | The **157** cleanly read↔metadata-matched, non-control samples (controls and non-standard IDs excluded — see below). |

**Read ↔ metadata linkage.** A FASTQ sample name like `AB41273` maps to the
metadata `ID` by its numeric core (strip the 2-letter prefix → `41273` → match
`ID`). Of 192 FASTQ pairs: 13 are controls (`AMP-Control`, `NAT-*`, `CHUNG`,
`*POS`/`*NEG`), 22 have non-standard or typo IDs that do not match, and the
remaining 157 match cleanly. `select_subset.R` keeps only the clean, non-control
matches.

**Raw-read integrity / repair.** Some of the cohort's raw FASTQs are **truncated
gzip streams** (interrupted copies): `gzip -t` fails, and cutadapt/DADA2 abort
with *"Compressed file ended before the end-of-stream marker was reached."* R1 and
R2 truncate at different points, so they also fall out of sync.

`run_example.sh` repairs each sample before use: it salvages the complete 4-line
records from each mate, re-compresses to a valid gzip, and trims R1/R2 to equal
length (Illumina keeps mates in cluster order, so the first *K* records are
paired). This cannot recover reads lost past the truncation — the durable fix is
to re-copy the raw files from source (`gzip -t *.fastq.gz` finds them).

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

For **UniFrac / Faith's PD**, `asv.fasta` holds the ASV sequences; `asv_tree.nwk`
is a phylogenetic tree built from them (MAFFT + FastTree, the SOP's optional
Appendix D). Its tips are the `tax_id` values, so it attaches to the phyloseq
object directly.

## Files

| File | What it is |
| --- | --- |
| `run_example.sh` | SLURM build script: select → de-identify → cutadapt → DADA2 → figures. |
| `select_subset.R` | De-identification + k-anonymity selection. Writes the public `metadata.tsv` and the **private** key. |
| `example_dada2.R` | The DADA2 run and the three figures (mirrors SOP Sections 3–6). |
| `metadata.tsv` | De-identified metadata (`SampleID`, `Ethnicity`, `Gender`, `SampleType`). |
| `counts_dada2.tsv` | De-identified ASV count table in the R-analysis contract. |
| `asv.fasta` | ASV sequences (`ASV0001`…), keyed to `counts_dada2.tsv`. |
| `asv_tree.nwk` | Phylogenetic tree of the ASVs (MAFFT + FastTree) — for UniFrac / Faith's PD. |
| `track.tsv` | Per-sample read tracking (the data behind figure 2). |
| `figures/*.png` | The three illustrative figures embedded in the SOP. |
