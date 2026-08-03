# Stage 2 — Set-level plan (structure & voice)

Reconciles the four Stage-1 reports (EMU, CONCOMPRA, READBASED, R_ANALYSIS — all
CLEAN) plus `00_REALITY.md` into one plan and one README. Written after reading
all five source files. Totals reconciled: **62 findings** — EMU 13, CONCOMPRA 15,
READBASED 13, R_ANALYSIS 21.

I use **no `### S-NN` contract blocks** in this plan; it reconciles findings the
four reports already raised under contract, so the six-field contract does not
re-apply here. All Stage-1 anchors are preserved verbatim in the reports.

---

## State of the set

Four documents, ~3,754 SOP lines plus a 115-line README. The prose is already
close to the form target (medians 24–34, one 101-word longest), so the work is
**not** trimming — it is adding the missing *layer-1* (concept-first) teaching
without losing the *layer-2* ("why this number") content, which is the strongest
material in the repository and must not thin.

**Distance from the specification** (worst → best), by the spec's own §2 heading
census plus finding load:

| Rank | Document | Layer-1 / Layer-2 headings | Findings (S1/S2/S3/S4) | Median para / over-80 | The gap in one line |
| --- | --- | --- | --- | --- | --- |
| 1 (furthest by workload) | `SOP_R_Analysis.md` | **1 / 1** across 1208 lines | 21 (3/4/6/8) | 30 / 6 | 1 concept heading in the longest doc; needs a full Stage→Section renumber, two new front sections, and back-matter. |
| 2 (furthest by purity) | `SOP_CONCOMPRA_NeSI.md` | **0 / 0** | 15 (2/7/2/4) | 24 / 2 | The only document missing **both** layers — a flawless runbook with no teaching at all. |
| 3 (highest-severity defect) | `SOP_READBASED_NeSI.md` | 2 / 5 | 13 (4/4/4/1) | 24 / 1 | Excellent layer-2, wrong shape; carries the set's single worst defect (8 headerless scripts → silent wrong results). |
| 4 (the exemplar) | `SOP_EMU_NeSI.md` | 12 / 1 | 13 (1/4/5/3) | 28 / 6 | The pattern the others copy; its own gaps are checkpoints/runtimes, two define-after-use terms, and house-style drift. |

`README.md` is separate (router, not tutorial): form-clean but structurally
off-spec (routing table not first, a Conventions block that restates the spec).
Owned here — see below.

**The single highest-value change in the whole set** is READBASED S-01: inline
the canonical job header into all eight scripts. It is the only defect that
produces a *silent wrong result* — copy `09.metaphlan.sl` as printed and `$SAMPLE`
expands empty, so MetaPhlAn profiles `clean/_R1.fastq.gz` and exits 0. The spec
singles it out. **Cost:** mechanical — prepend one header (values already tabulated
in READBASED Appendix C), ~+90 words. Do it regardless of document order.

**Is this more work than it looks? Yes.** Two things hide effort. (1) R_ANALYSIS's
Stage→Section renumber touches every internal cross-reference, the Key-objects
table, **and two references in other files** (CONCOMPRA L584, READBASED L686 both
say "Part 2's Stage 1"). (2) READBASED's header inlining must be byte-exact eight
times over, and the same pass must convert `cd "${SLURM_SUBMIT_DIR}"` to `--chdir`.
Net length grows ~+800–1,000 words, almost all in CONCOMPRA (+~400, a whole new
concepts section) and READBASED (+~370, three layer-1 openers); EMU and R_ANALYSIS
stay roughly flat because their additions are offset by relocation and F1
tightening.

---

## The target shape

One skeleton every document follows, with each document's earned deviations:

```
*Taylor Lab | <descriptor>*
# **<Title>**
**vN.N** | last updated <Month Year> | <environment> | <data type>
<one-paragraph scope: what it does, what it produces>
### **Before you start**            what you need · what it does NOT cover · where to go if you lack a prerequisite
## **Quick roadmap**                ASCII block, stages in run order + handoff
## **1. Understanding your data**   concepts only, NO commands (layer-1)
## **2..n. <performed steps>**      numbered in run order; each step: what · why · command · runtime · checkpoint
## **Troubleshooting**              symptom → cause → fix (optional where inline R10 notes already carry it)
## **Appendices**                   references, resource tables, provenance, lookup material
```

| Document | Conforms | Earned deviation | Verdict |
| --- | --- | --- | --- |
| EMU | Template + spine; §1 (cluster) then §2 (data) both concept-first | §1 "Getting started on NeSI" precedes "Understanding your data" — the cluster onboarding **is** its layer-1 and only lives here | Earned. Add `### Before you start`, ASCII roadmap, `## Appendices`. |
| CONCOMPRA | Numbered spine, roadmap, before-you-start all present | Currently **no** §1 concepts section | Not earned — grow `## 1. Understanding your data` (S-01). |
| READBASED | 14-section spine, roadmap, appendices | §4 "The Standard Job Header" occupies a step slot | Not earned — demote §4 to a stub (S-09); do **not** renumber §5–14 (script names depend on the numbers). |
| R_ANALYSIS | Has the content | Uses "Stage 1–5" and "Step 1–6" instead of one numbered spine; opens on an install block; no back-matter | Not earned — renumber to §1–12, add `## 1. Understanding your data`, `### Before you start`, `## Appendices` (S-08/09/10/11). |

A reader moving Part 1 → Part 2 then lands on the same furniture: a scope line, a
Before-you-start, a roadmap, a concepts section, numbered steps each ending in a
checkpoint.

**One heading-case decision to settle across all four (EMU S-11 flags it):** bold
title-case for every `##`/`###` (`## **1. Getting Started on NeSI**`,
`### **Filtering with Chopper**`). EMU's question-form §2 subsections
(`### What is 16S rRNA…`) may keep sentence case **but must be bold**. Recommended:
bold everywhere; keep the question form in EMU §2 (it reads well and is layer-1).

---

## The canonical job header

**Style decision — `--chdir` with an absolute path, space-separated directives.**
Two live styles exist: EMU and CONCOMPRA use `#SBATCH --chdir <abs path>`;
READBASED uses `cd "${SLURM_SUBMIT_DIR:?}"` + "submit from `$WORK`"; CONCOMPRA §7
uses `=`-separated directives (the outlier, S-12). I choose **`--chdir`** because:

1. It is what the exemplar (EMU) and CONCOMPRA already use, and EMU §1 explains
   *why* it beats in-script `cd` ("that runs too late, after SLURM has already
   tried" to open the logs).
2. It removes READBASED's own footgun — L164 warns "submit every job from `$WORK`
   … or SLURM fails without telling you why," a failure mode that exists *only*
   because logs resolve against the submit directory under `SLURM_SUBMIT_DIR`.
3. The spec §8 asks for **one** header and one directive style; `--chdir` gives
   both across all four documents.

Consequence: READBASED's eight scripts convert from `cd "${SLURM_SUBMIT_DIR:?}"`
to `--chdir /nesi/nobackup/<your_nesi_project_code>/readbased` as part of S-01
(the report inlines with `SLURM_SUBMIT_DIR`; the seam upgrades it to `--chdir`).
The README's "accepted in place of `--chdir`" clause is dropped in the rewrite.

**The template — written once, exactly as it appears at the top of every script:**

```bash
#!/bin/bash
#SBATCH --account <your_nesi_project_code>
#SBATCH --job-name <name>
#SBATCH --chdir <absolute workspace path>     # logs below resolve here, whatever dir you sbatch from
#SBATCH --time <hh:mm:ss>                      # }
#SBATCH --mem <NN>G                            # }  per-script values: Per-script resources table
#SBATCH --cpus-per-task <N>                    # }
#SBATCH --output logs/%x_%j.out               # %x = job name, %j = job ID
#SBATCH --error  logs/%x_%j.err

set -euo pipefail

module purge
module load <tool>/<version>
# commands …
```

```bash
# ── OPTIONAL: array-job block ──────────────────────────────────────────────
# Do NOT put the range in the header. Set it at submission:
#     sbatch --array=1-${N}%20 <script>.sh          # %20 throttles to 20 at once
# Use per-task log names in place of the two %j lines above:
#     #SBATCH --output logs/%x_%A_%a.out            # %A = array job ID, %a = task index
#     #SBATCH --error  logs/%x_%A_%a.err
# Map the task index to a manifest line, and fail loudly on an empty entry:
#     TARGET=$(sed -n "${SLURM_ARRAY_TASK_ID}p" <manifest>.txt)
#     [[ -n "$TARGET" ]] || { echo "empty entry at ${SLURM_ARRAY_TASK_ID}"; exit 1; }
# ───────────────────────────────────────────────────────────────────────────
```

Rules baked in: `mkdir -p logs` under the `--chdir` directory before the first
`sbatch`; array range never hard-coded; 1-based, indexed with
`sed -n "${SLURM_ARRAY_TASK_ID}p"`. **Base header carries no `--array` line** — a
forgotten `--array` then fails loudly (unset `$SLURM_ARRAY_TASK_ID` under `set -u`)
instead of silently running task 1, which is safer than EMU/READBASED's current
`--array 1-1` placeholder (see Open questions).

---

## Per-script resources

Values taken from the existing text (EMU/CONCOMPRA headers and resource tables;
READBASED Appendix C). These are what get pasted into each header. No batch
job has an unstated walltime; the only `UNSTATED` is a phantom.

| Script | Document | Job name | Time | Mem | CPUs | Array? |
| --- | --- | --- | --- | --- | --- | --- |
| `03a_nanoplot_raw.sh` (was `01_`) | EMU | nanoplot_raw | 00:30:00 | 8G | 8 | no |
| `03b_chopper_filter.sh` (was `02_`) | EMU | chopper_filter | 01:00:00 | 8G | 8 | no |
| `03c_nanoplot_filtered.sh` (was `03_`) | EMU | nanoplot_filt | 00:30:00 | 8G | 8 | no |
| `04a_emu_array.sh` (was `emu_array.sh`) | EMU | emu_array | 00:50:00 | 10G | 8 | **yes** `%20` |
| `04b_emu_array_rdp.sh` (was `emu_array_rdp.sh`) | EMU | emu_array | 00:50:00 | 10G | 8 | **yes** `%20` |
| `combine_emu_results.py` | EMU | — login-node `python3`, not a batch job | — | — | — | N/A |
| `05_concompra.sh` | CONCOMPRA | concompra_\<your_project> | 48:00:00 | 80G | 16 | no |
| `07_concompra_postprocess.sh` | CONCOMPRA | concompra_postprocess | 02:00:00 | 16G | 16 | no |
| `03_dedup.sh` | CONCOMPRA | — phantom: dedup is an interactive loop (S-10) | UNSTATED | UNSTATED | UNSTATED | N/A |
| `05a.qc_fastqc.sl` | READBASED | qc_fastqc | 00:30:00 | 4G | 2 | **yes** `%20` |
| `05b.qc_multiqc.sl` | READBASED | qc_multiqc | 00:20:00 | 4G | 1 | no |
| `06.trim.sl` | READBASED | trim | 02:00:00 | 16G | 12 | **yes** `%20` |
| `07.host_hostile.sl` | READBASED | host_hostile | 01:00:00 | 24G | 16 | **yes** `%20` |
| `07a.host_index.sl` | READBASED | host_index | 01:00:00 | 36G | 12 | no |
| `07b.host_filter.sl` | READBASED | host_filter | 01:00:00 | 32G | 20 | **yes** `%20` |
| `08.read_counts.sl` | READBASED | read_counts | 02:00:00 | 4G | 1 | no |
| `09.metaphlan.sl` | READBASED | metaphlan | 04:00:00 | 32G | 16 | **yes** `%20` |
| `10.humann.sl` | READBASED | humann | 24:00:00 | 48G | 16 | **yes** `%10` |
| DB installs (§3.3, §10) | READBASED | — `srun` interactive | 2–4 h | 8G | 4 | N/A |
| §11 merge | READBASED | — `srun` interactive | 00:30:00 | 8G | 2 | N/A |
| (all R blocks) | R_ANALYSIS | — runs locally in R, no SLURM scripts | — | — | — | N/A |

**No self-disagreements found.** READBASED script bodies match Appendix C
(`06.trim.sl` `-Xmx6g`×2 with cpus 12 → `HALF=6`; `07b` `-Xmx26g` under 32G;
`07a` `-Xmx30g` under 36G). EMU and CONCOMPRA headers match their in-text resource
tables. The one gap — CONCOMPRA `03_dedup.sh` — is not a resource omission to
invent but a **phantom**: the tree names a script the workflow never writes
(S-10). Resolve by deleting the tree line, not by guessing resources.

---

## README: false claims found

`README.md` is owned here. Verified every SOP claim against the SOP it describes
and against `00_REALITY.md`. **Tool-version claims: all true** — REALITY confirms
all 14 module strings resolve verbatim today; the README does not repeat
READBASED's stale "newer BBMap 39.09/39.10" nudge (that lives inside READBASED,
fixed by its S-12), so no version claim in the README is false. Three content
issues and two structural ones:

| # | Claim (current README) | Check | Verdict |
| --- | --- | --- | --- |
| C1 | L52 "`ps_relab`, `ps_estcounts` … **All four are defined in Part 2's 'Key objects' table**." | `grep` of `SOP_R_Analysis.md`: its Key-objects table defines **only** `ps_raw`/`ps_srs`; `ps_relab`/`ps_estcounts` appear only in `TUTORIAL_SPEC.md` §8 and `SOP_READBASED_NeSI.md:716`. | **FALSE (N3).** Removed with the Conventions block (N2). |
| C2 | L47 "Script filenames carry the number of the section that defines them — `05_concompra.sh` for Section 5, `09.metaphlan.sl` for Section 9." | True of CONCOMPRA/READBASED; **false of EMU** (`01_`/`02_`/`emu_array.sh`, EMU S-08). | Stale-until-EMU-fixed. Removed with the Conventions block; the rule lives in spec §8. |
| C3 | Citing groups "Yang & Chen 2022, *Microbiome*" under **Part 2 (R)**. | `grep`: Yang & Chen is cited in `SOP_READBASED_NeSI.md:753`, not in `SOP_R_Analysis.md`. | **Misgrouped (minor N3).** Moved to the Read-based row. |
| C4 | READBASED description: "**Assumes one prior pipeline**; does not re-teach bash or SLURM." | Restates `SOP_READBASED_NeSI.md:11`, the assumption the **spec §1 withdraws** and READBASED S-07 rewrites. True now, false after that rewrite. | **Will rot (N3).** Reworded to "Does not re-teach the cluster — points first-timers back to Part 1 Section 1." Coordinate with READBASED S-07. |
| S1 | Structure (N1): the routing table is not first — a "What's here" section sits between the opener and "Which SOP do I need?". | Spec §10 N1. | **Off-spec.** Routing table promoted to first section. |
| S2 | Structure (N2): a `## Conventions` block (L42–57) restates spec §8 (placeholders, ranks, `ps_*`, job header, script names, version line). | Spec §10 N2 ("link, do not duplicate"); §10's section list contains no Conventions section. | **Off-spec.** Removed; replaced by a one-line link to `TUTORIAL_SPEC.md` under Contributing. Also disposes of C1 and C2. |

The brief's note that "a previous round already removed the conventions block" is
**not** true of the file on disk — the Conventions block is present at L42–57 and
does restate §8. Ground truth wins; it is removed here.

Opening paragraph is ~85 words (>60, spec §10 table). Tightened to 43. Form is
otherwise clean (median 34, nothing over 80). So verification did turn up work:
this is **not** a reproduce-unchanged case — N1, N2 and the three claim fixes all
require change, which is exactly what the self-check demands.

---

## README: the replacement

Full README, ready to paste over `README.md`. Passes the Pass-3 scan (25
paragraphs, 0 over 80, median 30), every bullet ≤30 words (N4), opens with a
43-word paragraph immediately followed by the routing table (N1), and links to
`TUTORIAL_SPEC.md` for conventions rather than restating them (N2). Every SOP
claim is quote-backed (N3) — see the verification table under the replacement.

<!-- BEGIN REPLACEMENT README -->

# Taylor Lab Bioinformatic SOPs

Standard operating procedures for microbial community analysis on [NeSI](https://www.nesi.org.nz/) (New Zealand eScience Infrastructure) and in R, written for someone running their first analysis. Each SOP is a complete walkthrough — what a step does, the exact commands, and what correct output looks like.

## Which SOP do I need?

| Your data | Upstream (cluster) | Downstream (R) |
| --- | --- | --- |
| Full-length 16S rRNA amplicons, Oxford Nanopore (27F–1492R) | `SOP_EMU_NeSI.md` | `SOP_R_Analysis.md` |
| The same data, where you also need consensus sequences, a tree, or resolution for taxa the reference databases miss | `SOP_EMU_NeSI.md` first, then `SOP_CONCOMPRA_NeSI.md` | `SOP_R_Analysis.md` |
| Short-read 16S amplicons, Illumina (V3–V4, 341F–785R) | Not yet covered — you need a DADA2 or similar ASV workflow | `SOP_R_Analysis.md` applies once you have a count table |
| Shotgun metagenomes, read-based profiling, human-associated samples | `SOP_READBASED_NeSI.md` | `SOP_R_Analysis.md`, with the deltas in that SOP's Section 13 |
| Shotgun metagenomes, read-based profiling, animal or environmental samples | Not covered — MetaPhlAn's marker genes are built for human-associated taxa | — |
| Shotgun metagenomes, assembly and binning into MAGs | Not covered — see the [Genomics Aotearoa Metagenomics Summer School](https://genomicsaotearoa.github.io/metagenomics_summer_school/) | — |

**Amplicon** means you PCR-amplified one gene (16S) and sequenced only that; **shotgun** means you sequenced all DNA without targeting a gene. **Read-based** profiles reads directly against reference databases with no assembly step — faster and works on lower-coverage data, but it finds only organisms and genes already in the databases and recovers no novel genomes (for those, you want assembly and binning).

**Settle two things before you generate shotgun data**, because neither can be fixed afterwards: whether your ethics approval covers host-depleted human sequence (depletion reduces identifiability but does not remove it), and whether you have enough negative and positive controls to run contamination screening. Both are Section 1 of the read-based SOP — read it before sequencing, not after.

## What each document covers

| File | Covers |
| --- | --- |
| [`SOP_EMU_NeSI.md`](SOP_EMU_NeSI.md) | **Part 1 — sequencing → count tables.** Nanopore full-length 16S: NeSI onboarding (bash, modules, SLURM), read QC, filtering, Emu profiling against SILVA and RDP, combined count tables. The only document that teaches the cluster itself, starting from `pwd`. |
| [`SOP_R_Analysis.md`](SOP_R_Analysis.md) | **Part 2 — count tables → results.** phyloseq, decontam, SRS normalisation, alpha/beta diversity, PERMANOVA, differential abundance (ANCOM-BC2 and MaAsLin2, ALDEx2 noted), indicator species, common pitfalls. Platform-agnostic; runs locally in R. |
| [`SOP_CONCOMPRA_NeSI.md`](SOP_CONCOMPRA_NeSI.md) | **Runs after Part 1, same Nanopore data.** Reference-free consensus OTUs alongside Emu's assignments: install, dedup, run configuration, submission, verification, then SINTAX taxonomy, MAFFT alignment, FastTree phylogeny. Takes Part 1's filtered reads as input and hands off to Part 2. |
| [`SOP_READBASED_NeSI.md`](SOP_READBASED_NeSI.md) | **Illumina shotgun, read-based.** Governance and controls, trimming and PhiX removal, host depletion against T2T-CHM13, depth gates, taxonomy (MetaPhlAn 4), function (HUMAnN), contamination screening, and what changes in Part 2 for compositional input. Does not re-teach the cluster — it points first-timers back to Part 1 Section 1. |

**Part 2 is platform-agnostic** — one R document, not one per platform. Once you have a count table, a taxonomy table and a metadata file, the R workflow is identical whether the reads were profiled with Emu, CONCOMPRA or MetaPhlAn; only the interpretation differs (Part 1 covers this under "Full-length vs short-read"; the read-based SOP's Section 13 lists what changes when the input is relative abundance rather than counts).

**Start with Part 1 if this is your first pipeline** — it is the only document that teaches the cluster (bash, modules, SLURM, array jobs). The two cluster documents downstream of it (CONCOMPRA, read-based) say so at the top and point back to Part 1 Section 1; Part 2 runs locally and legitimately does not.

## Before you start

- **A NeSI account and project code** — the allocation code (e.g. `uoa03068`, written `<your_nesi_project_code>` in the SOPs) that every SLURM script needs.

- **Storage planned on day one** — databases on `/nesi/nobackup/`, scripts and final tables on the backed-up `/nesi/project/`; the read-based database set alone runs to ~85–95 GB.

- **R on your own machine** — Part 2 runs locally, so install a current R and the Part 2 packages before you need them, not on NeSI.

## Tool versions

The NeSI modules these SOPs were written against, confirmed present on Mahuika in July 2026. Every one will drift — confirm with `module spider <tool>` (capitalisation included) before you rely on a string.

**Amplicon, Nanopore (Part 1):**

| Tool | Module string | Purpose |
| --- | --- | --- |
| Emu | `Emu/3.6.2` | Taxonomic profiling and abundance estimation |
| NanoPlot | `NanoPlot/1.43.0-foss-2023a-Python-3.11.6` | Read QC plots and statistics |
| chopper | `chopper/0.12.0b-GCC-12.3.0` | Quality and length filtering |

**Consensus OTUs (CONCOMPRA):** the pipeline runs from a conda environment built via `Miniforge3/25.3.1-0`; the deduplication step uses `SeqKit/2.4.0`; post-processing uses `VSEARCH/2.21.1-GCC-11.3.0`, `MAFFT/7.505-gimkl-2022a-with-extensions`, `FastTree/2.1.11-GCC-11.3.0` and `seqtk/1.4-GCC-11.3.0`.

**Shotgun, read-based:**

| Tool | Module string | Purpose |
| --- | --- | --- |
| FastQC | `FastQC/0.12.1` | Per-sample read QC |
| BBMap / BBDuk | `BBMap/39.01-GCC-11.3.0` | Adapter and quality trimming, PhiX removal, optional host mapping |
| MultiQC | `MultiQC/1.24.1-foss-2023a-Python-3.11.6` | Aggregated QC report |
| fastp | `fastp/0.23.4-GCC-11.3.0` | Alternative trimmer; two-colour poly-G handling |
| MetaPhlAn | `MetaPhlAn/4.1.0-gimkl-2022a-Python-3.10.5` | Marker-gene taxonomic profiling |
| HUMAnN | conda, via `Miniforge3/25.3.1-0` | Gene families and pathways |
| Hostile | conda, via `Miniforge3/25.3.1-0` | Host depletion against a masked human index |

HUMAnN is deliberately **not** taken from a module — NeSI's `Humann/3.0.0.alpha.3` module is a 2020 pre-release that predates every MetaPhlAn 4 database and must not be used with this workflow.

Reference databases: SILVA v138.1 and RDP for the amplicon work, via Emu's prebuilt OSF archives. Part 1 explains why we use the validated v138.1 build rather than the newer SILVA 138.2 archive, and why we run both databases and compare. The read-based SOP pins the MetaPhlAn index explicitly (`mpa_vJun23_CHOCOPhlAnSGB_202403`) and explains why an unpinned index makes results depend on when the database was last refreshed.

## Contributing

These are living documents. If something did not work, or needed explaining and did not get it, that is worth fixing for the next person.

- **Small corrections** (typos, broken links, a changed module version): edit and commit directly, with a message saying what changed and why.

- **Substantive changes** (a different tool, a changed threshold, a new step): open a pull request or discuss with the lab first, since methods sections may cite the current version.

- **New SOPs**: write them against [`TUTORIAL_SPEC.md`](TUTORIAL_SPEC.md), follow the `SOP_<Topic>_<Environment>.md` naming, and add a row to the routing table above.

- **Conventions live in the spec** — placeholders, headings, the job header, ranks, object names, voice — so link to it rather than copying them here.

The spec carries three scans — heading census, paragraph length, and script-header completeness — that tell you in seconds whether an edit made a document worse. If you document a threshold or a tool choice, write down the reasoning, not just the value: most of the useful content in these SOPs is in the "why this number" paragraphs.

## Citing and reusing

If these SOPs shaped your methods, cite the underlying tools rather than this repository — that is what reviewers need. The SOPs give primary references where the choice of tool or method needs justifying:

| Document | Primary references |
| --- | --- |
| **Part 1 (Emu)** | Emu — Curry et al. 2022, *Nature Methods*; chopper — De Coster & Rademakers 2023, *Bioinformatics*; SILVA — Quast et al. 2013, *Nucleic Acids Research*. |
| **CONCOMPRA** | the pipeline — Stock et al. 2025; SINTAX — Edgar 2016; MAFFT — Katoh & Standley 2013; FastTree — Price et al. 2010 (all in that SOP's Appendix B). |
| **Read-based shotgun** | MetaPhlAn 4 — Blanco-Míguez et al. 2023, *Nature Biotechnology*; re-identification from residual human reads — Tomofuji et al. 2023, *Nature Microbiology*; DA-method benchmarking — Yang & Chen 2022, *Microbiome*. |
| **Part 2 (R)** | rarefaction debate — McMurdie & Holmes 2014, *PLoS Computational Biology*, and Schloss 2024, *mSphere*; DA-method comparison — Nearing et al. 2022, *Nature Communications*; indicator species — Dufrêne & Legendre 1997, *Ecological Monographs*. |

For the remaining R packages, look up the citation with `citation("phyloseq")` and equivalents. Record your package versions with `sessionInfo()` and keep the output alongside your results. For shotgun work, the read-based SOP's Section 14 lists what a methods section needs — the MetaPhlAn index tag, the HUMAnN and ChocoPhlAn/UniRef versions, whether the host reference was masked, the depth gates, which samples were excluded and why, and every model formula.

You are welcome to adapt these for your own lab. **Note that no licence has been added to this repository yet**, which by default means no reuse rights are granted. If sharing outside the lab is intended, adding a `LICENSE` file (CC BY 4.0 is common for protocols, MIT for scripts) would make that explicit.

---

*Last updated: July 2026 — second review round. All four SOPs and this README were probed against NeSI Mahuika and its R installation ([`reviews/00_ENVIRONMENT.md`](reviews/00_ENVIRONMENT.md)), reviewed adversarially, and rewritten against the findings; the first round is archived in [`reviews/v1/`](reviews/v1/). The sixteen questions the first round could not answer without cluster access are now settled in this round's reports. The review harness is [`prompts/SOP_REVIEW_PROMPT.md`](prompts/SOP_REVIEW_PROMPT.md).*

<!-- END REPLACEMENT README -->

**N3 claim-verification (both sides quoted):**

| README claim | Backed by |
| --- | --- |
| EMU "teaches the cluster … starting from `pwd`" | EMU:9 "It assumes no prior command-line experience and starts from `pwd`. It is the only document in this set that teaches the cluster itself". |
| Nanopore = 27F–1492R; Illumina 16S = V3–V4, 341F–785R | EMU:228 "27F … 1492R … approximately 1,500 bp"; EMU:230 "341F and 785R, targeting the V3-V4 regions". |
| CONCOMPRA "runs after Part 1 … reference-free consensus OTUs" | CONCOMPRA:7 "runs after `SOP_EMU_NeSI.md`, not instead of it … builds reference-free consensus OTUs". |
| READBASED = human-associated; animal/environmental not covered | READBASED:9 "This SOP is for human-associated samples … the workflow does not transfer to animal or environmental samples". |
| "Part 2 is platform-agnostic … only the interpretation differs" | R_ANALYSIS:5 "runs locally in R, not on NeSI … platform-agnostic"; READBASED:7 "Section 13 below listing what changes". |
| Storage: read-based DBs ~85–95 GB, won't fit default `project` quota | READBASED:133 "85–95 GB, which exceeds a default `project` quota on its own". |
| All 14 module strings | `00_REALITY.md` — every string "EXISTS (exact)". |
| Do not use `Humann/3.0.0.alpha.3` (2020 pre-release) | READBASED:516 "It is a June 2020 pre-release"; REALITY confirms the module exists (warning targets a real module). |
| SILVA v138.1 validated vs 138.2; MetaPhlAn index pinned | EMU:599 "the validated v138.1 (`silva`)"; READBASED:182 "`mpa_vJun23_CHOCOPhlAnSGB_202403`". |
| "Settle two things before shotgun": ethics + controls, Section 1 | READBASED:50 "used to re-identify individuals"; READBASED:56 governance/controls are §1. |

---

## Assumed but taught nowhere

The give-up list: knowledge a document leans on that EMU (owner of the cluster
layer) does not cover and no one else supplies. This is what makes a beginner
stop.

| Concept | Assumed by | Taught by today | Verdict & owner |
| --- | --- | --- | --- |
| **conda / conda environment** | CONCOMPRA §2 (env create/activate), **READBASED §7 Hostile, §10 HUMAnN** | CONCOMPRA gains a gloss via S-05; **READBASED: nobody** | **GAP.** EMU teaches `module load`, never conda. CONCOMPRA S-05 fixes itself. **READBASED has no conda finding and needs the same one-line gloss** at first use (§7 Option A). New seam action, folded into item 3. |
| **FASTQ / quality scores / 16S concepts** | CONCOMPRA, READBASED (redirect to "EMU Section 1") | EMU **§2**, not §1 | **PARTIAL GAP.** The redirects (CONCOMPRA:15, READBASED:11) send readers to "Section 1", but FASTQ/Phred/16S live in EMU **§2**. A reader who does only §1 misses them. Fix: redirects say "Sections 1–2", or EMU's Before-you-start states §1 = cluster, §2 = data. |
| **compositional data** | R_ANALYSIS (defines at L954, late), READBASED §13 (uses "compositional" undefined) | R_ANALYSIS (late) | **OWNERSHIP.** Make R_ANALYSIS the single owner via its new §1 concepts (S-09, two sentences from L954); READBASED §13 keeps a one-line gloss (S-08) and cites Part 2. |
| **paired-end / `_R1`/`_R2` / mates** | READBASED only (Illumina) | nobody | READBASED S-08 adds it. EMU is single-read Nanopore, correctly silent. Covered. |
| **OTU** | CONCOMPRA (title), R_ANALYSIS (minor) | nobody (EMU uses "taxa"/ASV) | CONCOMPRA S-01 defines it as owner. Covered. |
| **array jobs, SLURM, sbatch, modules, `--chdir`** | READBASED (redirect), CONCOMPRA (redirect) | EMU §1 | Covered by redirect, once READBASED L11 is reframed (S-07) so the redirect reads as "learn here", not "you should already know this". |
| **count table / sample manifest** | all | EMU §4 (manifest, produces count table) + R_ANALYSIS §1 (defines count table) | Covered; each self-contained. |

**The two live give-up points are conda-in-READBASED and the §1-vs-§2 redirect
target.** Both are cheap to close and both are currently no one's job — flagged
here because neither is in any Stage-1 report's finding set for the document that
needs it.

---

## Shared teaching layer and ownership

For each shared concept: who teaches it, who links, and does the linking document
survive read on its own?

| Concept | Owner (teaches) | Links / assumes | Survives alone? |
| --- | --- | --- | --- |
| NeSI, filesystems, symlinks, bash, modules, SLURM, sbatch | **EMU §1** | CONCOMPRA, READBASED (redirect) | Yes, via redirect. |
| Canonical job header + `--chdir` | **EMU §1** (defines) | CONCOMPRA, READBASED inline their own copies | Yes — each script self-contained once READBASED inlines (S-01). |
| Array jobs / `$SLURM_ARRAY_TASK_ID` | **EMU §1** | READBASED (redirect) | Yes, once L11 reframed (S-07). |
| conda / conda env | **CONCOMPRA §2** (S-05) | READBASED §7/§10 | **No for READBASED** until it gets its own gloss (see gap list). |
| FASTQ / quality scores | **EMU §2** | CONCOMPRA, READBASED | Partial — redirect points at §1, concept is in §2. |
| Sample manifest (`samples.txt` / `emu_manifest.txt`) | **EMU §4** + READBASED §3 (each inline) | — | Yes — each builds its own. |
| count table (what it is) | **R_ANALYSIS §1** (defines); EMU §4 produces it | CONCOMPRA, READBASED (produce variants) | Yes. |
| compositional data | **R_ANALYSIS §1** (after S-09) | READBASED §13 | Yes, once owned in R_ANALYSIS §1. |
| OTU | **CONCOMPRA §1** (after S-01) | R_ANALYSIS (minor) | Yes. |
| Taxonomic-rank vocabulary | spec §8 + every doc converts to it | all | Consistency item, not teaching. |

---

## Merged jargon table

Merged from the four Stage-1 jargon tables. Full per-document tables live in the
reports; here I reconcile only (a) terms in ≥2 documents, (b) the S1/S2
define-after-use offenders, and (c) definitions that must agree.

**No term is used in three or more documents yet defined in none** — so the spec's
"3 docs / defined nowhere = automatic S1" rule fires for nobody. The two that come
closest are two-document cases, both handled: **conda** (CONCOMPRA + READBASED,
defined in CONCOMPRA only → gap for READBASED) and **compositional** (R_ANALYSIS +
READBASED, defined late in R_ANALYSIS → ownership moved to R_ANALYSIS §1).

| Term | Documents | Owner / first real definition | Agreement / action |
| --- | --- | --- | --- |
| chimera | EMU (S-02), CONCOMPRA (S-01) | each glosses at first use | **Must agree — they do:** both "artificial hybrid formed during PCR when an incomplete amplicon primes another species' template". Keep wording parallel. |
| ASV | EMU §2 (defines), CONCOMPRA (S-07) | EMU "Amplicon Sequence Variants, unique sequences differing by even one base" | Agrees; CONCOMPRA S-07 adds the OTU contrast. |
| OTU | CONCOMPRA (S-01), R_ANALYSIS (minor) | CONCOMPRA "operational taxonomic units, groups of near-identical sequences" | Single owner CONCOMPRA. |
| compositional / compositionality | R_ANALYSIS, READBASED §13 | R_ANALYSIS §1 (S-09) | Owner R_ANALYSIS; READBASED §13 one-line gloss (S-08). Must agree ("fixed total; one taxon rising forces others down"). |
| conda / conda environment | CONCOMPRA §2, READBASED §7/§10 | CONCOMPRA §2 (S-05) | **Gap:** add matching gloss to READBASED (item 3). |
| FASTQ | EMU §2 (defines), CONCOMPRA, READBASED | EMU §2 | Redirect-target caveat (point at §1–2). |
| count table | EMU, CONCOMPRA, READBASED, R_ANALYSIS | R_ANALYSIS §1 defines; EMU §4 produces | Consistent. |
| SLURM / array job / manifest | EMU §1/§4 | EMU | Redirected from CONCOMPRA/READBASED. |
| chimera-vs-EM, SINTAX, MAFFT, FastTree, GTR, bootstrap | CONCOMPRA only | CONCOMPRA (S-01/S-03/S-04) | Single-doc; not cross-doc. |
| PhiX, adapter, ktrim, SGB, CPM, RPK, BAL, rclr, paired-end | READBASED only | READBASED (S-03/S-05/S-08) | Single-doc; `CPM`/`stratified` do **not** appear in R_ANALYSIS (confirmed by grep — they are READBASED terms). |
| SRS, Cmin, PCoA, PERMANOVA, Aitchison, rCLR, lfc, prevalence method | R_ANALYSIS owns; READBASED §13 references | R_ANALYSIS (S-02/S-06/S-07) | Cross-doc references acceptable; R_ANALYSIS is the canonical owner. |

---

## Preflight distribution map

Where each front-loaded environment check belongs, which step actually needs it,
and what to do on failure. Only READBASED front-loads a real check block (its §2);
the other three pass R4. Do **not** simply delete — the module-drift and
compute-node internet checks are load-bearing and must land somewhere actionable.

| Check (READBASED §2, L102–120) | Actually needed at | On failure | Disposition |
| --- | --- | --- | --- |
| `hostname; sinfo -s` (platform after 2025 refresh) | one-time, before any submit | platform name changed → update `--chdir`/module strings | **Keep in §2** as a one-time gate. |
| `module -t spider` loop (FastQC…Bowtie2) | each module's first `module load` step | a string drifted → `module spider <tool>` for the new one | **Keep in §2** as the "does my environment still match" gate (earns its place; REALITY shows none drifted, but it is the right guard). |
| `srun … curl pypi` internet check | §9 MetaPhlAn (`--index`/`--offline`), §10 HUMAnN DB resolve | `NO_INTERNET` → you must pin `--index --offline` and pre-download DBs | **Keep in §2**, cross-referenced from §9 (already at L120). Load-bearing. |
| `ls -d /opt/nesi/db` (shared DB tree) | §3.3 references and databases | absent → install your own (§3.3) | **Keep in §2** (one line); it feeds §3.3. |
| `nn_check_quota` (storage) | day-one storage planning | over quota → move DBs to `nobackup` | **Keep up front** (R4 exception for quota). |
| **Closing paragraph L882** (restates all of the above) | — | — | **CUT (S-10).** Pure duplication of §2; the one deletion in the set, not on any keep list. |
| R_ANALYSIS install block (L65–98) front-loads all packages incl. mixed-model set | §2 (install), used through the doc | slow/hung → runtime note (S-01) | Split the rarely-used mixed-model installs (`lme4`/`lmerTest`/`emmeans`) into a labelled "only for non-independent designs" block; add the runtime note. |

CONCOMPRA §3 "Pre-flight" is a genuine per-dataset duplicate-read screen, not an
environment block — it stays. EMU has no front-loaded block (R4 pass).

---

## Section and script renumbering map

**EMU** (internal only — no other file names EMU's scripts):

| Old | New | References to update (same file) |
| --- | --- | --- |
| `01_nanoplot_raw.sh` | `03a_nanoplot_raw.sh` | create-line L340, `sbatch` L368, log prefix `nanoplot_raw_%j` |
| `02_chopper_filter.sh` | `03b_chopper_filter.sh` | L425, `sbatch` L475, log `chopper_%j` |
| `03_nanoplot_filtered.sh` | `03c_nanoplot_filtered.sh` | L483, `sbatch` L511, log `nanoplot_filt_%j` |
| `emu_array.sh` | `04a_emu_array.sh` | L669, `sbatch` L718/L725, log `emu_%A_%a` |
| `emu_array_rdp.sh` | `04b_emu_array_rdp.sh` | L729 (copy), `sbatch` L735 |
| `combine_emu_results.py` | `04_combine_emu_results.py` (optional; helper may keep its name) | L775, L910, L916 |

**CONCOMPRA:** no section renumber. `## 1. Overview` → `## 1. Understanding your
data` (rename). Delete the phantom `03_dedup.sh` tree line (S-10). Update the
external cross-ref to Part 2 (see below).

**READBASED:** **no section renumber** (S-09) — script names and every internal
cross-reference depend on §5–14; §4 becomes a short stub in place. Update the
external cross-ref to Part 2 (see below).

**R_ANALYSIS** — the one real renumber (S-11), Stage/loose labels → one 1–12 spine:

| Old label | New section |
| --- | --- |
| (new) | **1. Understanding your data** (concepts, no commands) |
| §1 "Installing and loading libraries" | **2. Install and load packages** |
| Stage 1 "Loading and preparing" | **3. Load and prepare your data** |
| Stage 2 "Decontamination + build ps_raw" | **4. Remove contaminants and build ps_raw** |
| Stage 3 "Exploring" | **5. Explore your data before analysis** |
| Stage 4 "Normalisation" | **6. Normalise to ps_srs** |
| Stage 5 → Alpha | **7. Alpha diversity** |
| Beta diversity (Steps 1–6) | **8. Beta diversity** (Steps 1–6 → `###` subsections) |
| Taxonomy barplots | **9. Taxonomy barplots** |
| §2 "Going Further" (DA) | **10. Differential abundance** |
| Indicator species | **11. Indicator species** |
| Figures + Reproducibility | **12. Figures and reproducibility** |
| Common Pitfalls | **Troubleshooting and common pitfalls** |
| (new) | **Appendices** A references · B normalisation methods · C thresholds |

Cross-references that must move with the R_ANALYSIS renumber:

- **Internal:** Key-objects table "Section 1 Step 1/2/3" (L52–54) → real headings
  ("§8, Step 1" etc.); every internal "Stage N" mention (roadmap, L38, L332,
  L336, L429–449) → "Section N"; "the Common Pitfalls section" (L38) →
  "Troubleshooting".
- **External (other files — the collision risk):** `SOP_CONCOMPRA_NeSI.md:584`
  ("Part 2's **Stage 1** describes") and `SOP_READBASED_NeSI.md:686` ("its
  **Stage 1** loader will round"). These are edited **in their own files** by
  items 2 and 3 using the frozen new number ("Part 2's data-loading step,
  Section 3"), so no file is touched by two work items. L686 is also keep-list
  content — preserve the silent-rounding warning while renaming.

---

## Consistency matrix

One row per item that varies, with the decision (spec §8 is authoritative).

| Item | Canonical decision | Who changes |
| --- | --- | --- |
| Placeholders | `<your_nesi_project_code>`, `<your_project>`, `<username>`, `<your_email>`, `<sample>`, `<job_id>`. `$WORK`/`$DB`/`$ACCOUNT` allowed in interactive blocks, never in a `#SBATCH` line. | READBASED — ensure SLURM bodies carry the placeholder (or define the var in-script), not a bare login-shell `$ACCOUNT`. |
| SLURM directive style | Space-separated (`#SBATCH --time 02:00:00`). | CONCOMPRA §7 postprocess (`=` → space), S-12. |
| Job header / working dir | `--chdir <abs path>`; drop `cd "${SLURM_SUBMIT_DIR:?}"`. | READBASED (8 scripts → `--chdir /nesi/nobackup/<your_nesi_project_code>/readbased`). |
| Array range | Never in the header; set at submission `%20` (`%10` for HUMAnN); base header has no `--array`. | All array scripts. |
| Script names | `NN.name.sl` / `NN_name.sh`, number = section, suffix `a`/`b`. | EMU `03a/03b/03c/04a/04b` (S-08). |
| Log paths | `logs/%x_%j` (non-array) / `logs/%x_%A_%a` (array), relative to `--chdir`. | EMU uses fixed names (`nanoplot_raw_%j`) — align to `%x_%j` when renaming. |
| Taxonomic ranks | `superkingdom … species`, lowercase. | Already converted: CONCOMPRA SINTAX `d/p/c/…` → ranks in §8 R block; MetaPhlAn `k__…s__` → ranks in §13. Emu native. No change. |
| phyloseq objects | `ps_raw`, `ps_srs`, `ps_relab`, `ps_estcounts`. | **R_ANALYSIS Key-objects table defines only the first two** — add a two-row note for `ps_relab`/`ps_estcounts` pointing to READBASED §13, so the README's four-object claim (now removed) becomes true somewhere. |
| Sample IDs | one ID, set upstream, strip `_filtered`, `.CONCOMPRA`, `.profile`, `_Abundance-RPKs` where created. | CONCOMPRA §8 strips `.CONCOMPRA`/`_filtered` (present); READBASED §11 strips `.profile` (present). No change. |
| Voice `we`/`you` | `we` = a lab decision (layer-2); `you` = a reader action. | READBASED uses `we` 0× (S-13) → mark lab choices; EMU 19×, others consistent. |
| Version line | `**vN.N** \| last updated <Month Year> \| …`. | Bump CONCOMPRA→v2.1, R_ANALYSIS→v2.1 on rewrite. |

---

## Work plan

`∥` = runs in parallel. Every P-item edits a **single distinct file** once the
renumber map and header canon are frozen in P0, so nothing collides in the same
lines.

| # | Item | Files | Closes | Size | Depends on |
| --- | --- | --- | --- | --- | --- |
| **P0** | Freeze: `--chdir` header canon, consistency matrix, teaching-ownership, renumber map, heading-case call | (this plan) | consistency baseline | — | — |
| **PR** | Apply README replacement (paste from §"README: the replacement") | README.md | N1, N2, N3 (C1–C4), N4 | −13 lines | P0 (writes READBASED desc to post-rewrite state) |
| **P1** ∥ | EMU rewrite: voice sweep → chimera/EM glosses → checkpoints+runtimes → F1 splits → structural moves + script renumber `03a/03b/03c/04a/04b` | SOP_EMU_NeSI.md | EMU S-01…S-13 | ~flat | P0 (header canon) |
| **P2** ∥ | CONCOMPRA rewrite: §1 concepts (S-01) → §7 lead-in + GTR/bootstrap glosses → conda intro + runtimes → ASV/`prv_cut` → Appendix A Emu path → shape fixes → form pass + §7 header→space + `--chdir`; update its "Part 2 Stage 1" xref | SOP_CONCOMPRA_NeSI.md | CONCOMPRA S-01…S-15 | **+~400w** | P0; reads (not edits) EMU SILVA path |
| **P3** ∥ | READBASED rewrite: inline header ×8 + `--chdir` → runtimes+checkpoints → 3 layer-1 openers + PhiX → reframe L11 + first-use glosses + **conda gloss (gap)** → tighten L753 + cut closing dup → BBMap fix → `we`/V3; update its "Stage 1" xref | SOP_READBASED_NeSI.md | READBASED S-01…S-13 + conda gap | **+~370w** | P0 (header canon) |
| **P4** ∥ | R_ANALYSIS rewrite: add Before-you-start + §1 concepts + move Key-objects → **renumber Stage→§1–12** → definitions (prevalence/phyloseq/CLR/lfc) → runtimes → move refs to Appendices → tighten 7 blocks → V3 | SOP_R_Analysis.md | R_ANALYSIS S-01…S-21 | ~flat | P0 (frozen renumber map) |

Sequencing rationale: **P0 first** (freezes the shared decisions every rewrite
depends on). Then all rewrites run in parallel — each is internal to one file,
and the two external "Part 2 Stage 1" cross-refs are updated by P2/P3 *in their
own files* against the frozen new numbering, so P4 never edits another document.
**Worst-first** is satisfied within the parallel batch by priority: P4
(R_ANALYSIS, 21 findings + renumber) and P2 (CONCOMPRA, missing whole layer) are
the heaviest; P3 carries the single highest-value fix (headers). PR (README) can
land any time after P0. EMU (P1) is lightest but should not be deprioritised —
it defines the header and cluster layer the others cite, so freezing its renumbered
script names early keeps the redirects honest.

---

## Consolidated keep list

Merged and deduplicated across the four reports. Every anchor below `grep -Fc`s to
**exactly one** hit in its source file (verified — see self-check). If a rewritten
document loses any of these, the rewrite failed. All are layer-2 "why this number"
or silent-failure content; the verdict for every one is **KEEP or rewrite-tighter**,
never cut.

**EMU (`SOP_EMU_NeSI.md`):**
1. Q10/1200/1800 threshold reasoning — `a 1,500 bp floor would discard many legitimate full-length reads`
2. Array `1-1` placeholder silent-failure — `only the first sample is processed`
3. `--keep-counts` do-not-omit — `essential, do not omit`
4. `grep "^@"` count-inflation — `silently inflates the count`
5. `--min-pid` `0.9` vs `90` trap — `Emu reads that as 0.9% identity`
6. EM / community-context — `EM uses **community context** to resolve ambiguous reads`
7. SILVA v138.1 vs 138.2 — `has not yet been tested or validated with Emu`
8. Run-both-databases rationale — `A taxon appearing in both SILVA and RDP results is more likely genuinely present`
9. `rm` on nobackup is irreversible — `If you `rm` something on nobackup, it is gone`
10. combine basename-collision exit — `write the other's into two identically named columns`
11. verify-output else-branch — `which reads like success`
12. Full-length vs short-read interpretation — `overall alpha diversity may appear lower with Nanopore`
13. `--chdir` runs-too-late — `that runs too late, after SLURM has already tried`
14. Primary citation (Curry 2022; De Coster & Rademakers L415; Quast L591) — `Curry et al., *Nature Methods* 2022`

**CONCOMPRA (`SOP_CONCOMPRA_NeSI.md`):**
15. Verify on disk, not `.out` — `never from the`
16. `MIN`/`MAX` unset drops every read — `the filter drops **every** read, silently`
17. filtlong duplicate-abort / do not downgrade — `Do not replace or downgrade filtlong`
18. Screen read *names* only — `Compare read *names*`
19. Primer forward-strand, not reverse-complement — `not the reverse-complement`
20. `THREADS` outer+inner parallelism — `both outer parallelism`
21. Retention ~45%/80% → 80k→~29k — `enters clustering with roughly 29,000`
22. Keep `temporary/` (comment out `rm -rf`) — `kept for Section 6`
23. SINTAX column 4 not 2 — `silently corrupts taxonomy at low-confidence ranks`
24. 0.8 SINTAX cutoff rationale — `standard SINTAX bootstrap threshold`
25. Strip `.CONCOMPRA`/`_filtered` or joins break — `one metadata sheet cannot serve both pipelines`
26. Integer counts / `prv_cut` may drop rare taxa — `often genuine rare taxa`
27. Project-dir UDB, not purged nobackup — `not a copy under`
28. Strip `defaults` channel / use Miniforge — `re-adds the `defaults` channel and fails the solve`

**READBASED (`SOP_READBASED_NeSI.md`):**
29. Backwards depth arithmetic — `Divide, do not multiply`
30. Governance / re-identification (Tomofuji) — `re-identify individuals against matched genotype data at 93.3%`
31. Mock community = only over-removal check — `the only way to detect over-removal`
32. Why T2T-CHM13 (false positives) — `roughly 200 Mb of centromeric, segmental and satellite sequence`
33. `--index`/`--offline` reproducibility — `triggers an HTTP lookup at runtime`
34. Estimated counts not for alpha diversity — `do not use them for alpha diversity`
35. `Humann/3.0.0.alpha.3` warning — `It is a June 2020 pre-release`
36. `ktrim=r` two-pass reasoning — `Listing PhiX alongside the adapters would therefore`
37. Reshape-before-Part-2 silent rounding — `its Stage 1 loader will round your percentages into small integers`
38. §8 depth gates — `Not enough for defensible taxonomy`
39. zcat-pipefail trap — `does NOT trip -e/pipefail`
40. §13 deltas + UniFrac addition — `Available here, though Part 2 does not cover it`
41. Provenance-as-you-go — `Generate this as part of the run, not afterwards from memory`
42. High-host: bench beats bioinformatics — `far more than any amount of extra sequencing`

**R_ANALYSIS (`SOP_R_Analysis.md`):**
43. Relative-abundance guard — `this is a relative-abundance table, not counts`
44. Positional-index match guard — `index them POSITIONALLY`
45. Stale-`ps_raw` rebuild after depth gate — `a stale ps_raw will run`
46. Figure-vs-text p-value trap — `the figure is what goes into the thesis`
47. `neg_lb` ≥30-samples rule — `each group holds roughly 30 or more samples`
48. rarefaction vs rarefying + Schloss/McMurdie — `the practice that was criticised`
49. Which-normalisation decision table — `Feeding pre-normalised data to ANCOM-BC2`
50. `ps_raw` vs `ps_srs` one rule — `The one rule to remember`
51. Aitchison depth-tracking caveat + libsize check — `whether depth is driving Axis 1`
52. `pairwise.adonis2` swallows `p.adjust.m` — `falls into `...` and is silently ignored`
53. FDR across every taxon (indicators) — `filtering before adjusting shrinks the number of tests`
54. Compositionality worked example (the arithmetic) — `the true total is 4,000 cells but the instrument still returns 3,000 reads`
55. Factor-level naming warning — `a column you cannot reference without backticks`
56. Common Pitfalls (pseudoreplication … independence) — `Independence matters more than sample size`

**Cut audit:** across all four reports, **one** removal is proposed — READBASED's
closing paragraph (L882), which duplicates §2 Preflight and is on **no** keep
list. **Zero keep-list / load-bearing items struck.** Every "why this number" and
silent-failure block is KEEP, rewrite-tighter, or relocate. Cross-report overlaps
(compositional, chimera, conda, NeSI→local file transfer) are reconciled by
assigning a single owner above, not by deletion — **0 findings struck as
duplicates.**

---

## Open questions for the lab

Each is a lab decision, not mine. Options then a recommendation.

1. **R_ANALYSIS renumber vs keep "Stage" labels.** Renumbering Stage→Section
   (S-11) is cleaner but touches two other files (CONCOMPRA L584, READBASED L686).
   *Options:* (a) renumber and update those two external refs; (b) keep "Stage"
   labels as aliases, touching nothing outside R_ANALYSIS. **Recommend (a)** — one
   spine is worth two one-word edits — but (b) is the low-risk fallback if the
   rewrites are done by separate hands.

2. **Array header: omit `--array` vs `1-1` placeholder.** EMU and READBASED keep
   a `#SBATCH --array 1-1` placeholder with a loud warning. Omitting `--array`
   entirely makes a forgotten range fail *loudly* (unset `$SLURM_ARRAY_TASK_ID`
   under `set -u`) instead of silently running task 1. **Recommend omit** from the
   base header; array scripts add the block at submission. Keep the warning
   either way.

3. **conda ownership.** *Options:* (a) each downstream doc glosses conda at first
   use (CONCOMPRA S-05 pattern; add the same to READBASED); (b) EMU adds a shared
   one-line "conda is an alternative to modules" note. **Recommend (a)** — readers
   may reach READBASED without CONCOMPRA, so the gloss must be local to each.

4. **Redirect target.** CONCOMPRA:15 and READBASED:11 send first-timers to "EMU
   Section 1", but FASTQ/quality/16S are in EMU §2. *Options:* (a) redirects say
   "Sections 1–2"; (b) EMU's new Before-you-start states the §1/§2 split.
   **Recommend both** — cheap, and closes a real give-up point.

5. **Heading case for EMU §2 question-form subsections.** Bold title-case
   everywhere vs keep the question form (`### What is 16S rRNA…`) in bold.
   **Recommend keep the question form, bolded** — it reads as layer-1 and is a
   strength; title-case every other heading.

6. **`ps_relab`/`ps_estcounts` in R_ANALYSIS.** The four object names are canonical
   (spec §8) but R_ANALYSIS's Key-objects table defines only two. *Options:* (a)
   add a two-row note pointing to READBASED §13; (b) leave them READBASED-only.
   **Recommend (a)** so the object-naming discipline is complete in the doc that
   owns objects.

7. **Licence.** The repo has no `LICENSE` (README already flags it). Lab decision:
   CC BY 4.0 (protocols) or MIT (scripts). No recommendation — a governance call.

---

## Self-check

**1. Keep-list anchors resolve (each tagged with its source file; `grep -Fc` must
be exactly 1).** Verified by script over all 56 rows against the four SOPs:

```
EMU 14/14 unique · CONCOMPRA 14/14 unique · READBASED 14/14 unique · R_ANALYSIS 14/14 unique
=> 56/56 anchors resolve to exactly one hit in their tagged source file.
```

(The one initial collision — "wet-lab depletion at the bench achieves far more",
2 hits — was replaced with `far more than any amount of extra sequencing`, 1 hit.)

**2. README replacement is complete and true.** The block between the
`REPLACEMENT README` markers is the full page ready to paste, not a change list.
It opens with a 43-word paragraph (≤60) immediately followed by the `## Which SOP
do I need?` routing table (N1). Conventions are linked to `TUTORIAL_SPEC.md`, not
restated (N2) — the old §8-duplicating block is gone. Every SOP claim is
quote-backed in the verification table (N3). Pass-3 scan on the replacement text:

```
25 paragraphs, 0 over 80 words, median 30      (median < 35 ✓)
bullets over 30 real words: 0                   (N4 ✓; Citing is a §10 table, not bullets)
```

**3. Contract blocks.** **None used** in this plan — it reconciles findings the
Stage-1 reports already raised under contract, so no `### S-NN` blocks appear and
the six-field contract does not re-apply.
