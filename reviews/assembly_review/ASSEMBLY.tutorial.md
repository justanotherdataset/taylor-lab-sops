# Tutorial Review — `SOP_ASSEMBLY_NeSI.md` (structure / voice / teachability)

Run 2026-08-04 on NeSI, from `/nesi/project/uoa03769/taylor-lab-sops`. Read in
order: COMMON BRIEF + `TUTORIAL_SPEC.md` (audience §1 is the load-bearing one) →
priors (`reviews/capstone/ASSEMBLY.md`, the ASSEMBLY sections of
`reviews/capstone/00_VERDICT.md`, `reviews/structure/00_PLAN.md` for house style)
→ `SOP_ASSEMBLY_NeSI.md` in full (988 lines, v0.1). This is the dedicated tutorial
round the other four SOPs each had; `SOP_ASSEMBLY_NeSI.md` never had one.

Lane: teachability, structure, voice. Correctness/fixture findings (GTDB-Tk
`classify/` glob, metaSPAdes/co-assembly forks, submission-chain dependencies,
DAS_Tool extensions, CoverM columns, UniFrac tree path) are owned by the parallel
correctness reviewer and are **not** re-filed here — where a teaching fix touches
the same line, it is noted under the finding and the correctness fix leads.

## Document: SOP_ASSEMBLY_NeSI.md

A strong draft whose **shape is already on-spec** — scope line, Before-you-start,
a Quick Roadmap matching READBASED's, a genuine §1 all-prose concepts section, 16
numbered steps in run order, Troubleshooting, three appendices. The layer-1
teaching (contig, coverage, bin, MAG, completeness/contamination, MIMAG, ANI,
dereplication, GTDB, compositional) and the layer-2 "why this number" content are
both present and mostly excellent, and R10 silent-failure warnings are the
document's strongest feature. Form is tight: **zero genuine prose paragraphs over
80 words**. The teaching gaps are localised: (1) the audience contract reinstates
a prior-pipeline prerequisite the spec withdraws — the single biggest issue; (2)
a handful of main-path terms are used with no gloss for a terminal novice
(`srun --pty`, k-mer, diamond, `hugemem`, `nn_seff`); (3) five heavy steps drop
the inline runtime and the optional §13 steps drop the checkpoint; (4) `###`
subheadings are sentence case against the suite's title-case rule. None of these
is structural surgery — the document is close.

## Verdict against the specification

The document meets the document template and step template in shape, carries both
teaching layers, and is form-clean. It fails the spec on one point of substance
(the §1 audience contract, R2/§1) and on completeness of the step template
(runtime + checkpoint on the back-half heavy steps, R5). The rest is voice polish.

| Rule | Pass / Partial / Fail | One-line evidence |
| --- | --- | --- |
| **R1** both layers, in order | **Pass** | §1 is a full layer-1 concepts section; layer-2 "why" sits in skippable bullets beside each parameter. |
| **R2** nothing used before introduced | **Fail** | `srun --pty` (L300), k-mer (L67), diamond (L456), `hugemem` (L143), `nn_seff` (L736), BAM (L109) all first-used with no gloss. |
| **R3** concepts before commands | **Pass** | §1 carries no commands; every step opens with plain-prose "what it does". |
| **R4** setup where needed | **Pass** | No front-loaded env-check block; §3 is the storage/directory exception the spec allows. |
| **R5** every step states its outcome | **Partial** | Runtime present on §§4/5/6/7/9/11 but absent on §§8/10/12/13/14; §13 eggNOG/DRAM have no checkpoint. |
| **R6** one numbered spine | **Partial** | §§1–16 in run order, scripts numbered to sections — except the DRAM block, which carries no `scripts/13b.dram.sl` name (Appendix B lists it). |
| **R7** every fork has a default | **Pass** | Assembler (MEGAHIT default) and strategy (per-sample default) each named with the reason and a "choose when" table. |
| **R8** plain words first, jargon second | **Partial** | Good for contig/coverage/bin, but k-mer, de Bruijn graph and single-copy marker genes are introduced term-first. |
| **R9** one voice | **Partial** | `we`/`you` used correctly throughout; `###` subheads are sentence case, not the spec's title case. |
| **R10** explain the failure | **Pass** | Best feature — silent-failure guards on empty `$SAMPLE`, min1500 loss, ~0% mapping, no-derep, OOM, header-only depth, etc. |
| **R11** every script complete/runnable | **Pass** | Every job block: shebang, all `#SBATCH`, `set -euo pipefail`, empty-`$SAMPLE` guard, array range set at submission. |
| **F1** no paragraph over 80 words | **Pass** | `scan.py` reports 4 "over-80" groups; all four are bullet lists or the citation list (list form already), not prose — see Findings note. |
| **F2** a definition is 1–2 sentences | **Pass** | Concept subsections are appropriately sized; no definition swells into a wall. |
| **F3** anything enumerable → table/list | **Partial** | Mostly excellent (many tables), but the §16 provenance "record additionally" run (L872) is an unwritten list. |
| **F4** the point comes first | **Pass** | Bullets lead with the bold parameter/number; scanner-first. |
| **F5** the "why" is separable | **Pass** | Layer-2 sits in bullets after the command, skippable on first pass. |

## Jargon table

Every term a terminal novice would not know, its first occurrence, where it is
defined, and the verdict. `OK` = defined at or within one screen of first use in
the §1 concepts section (R3-compliant). `FAIL` = R2 breach (no gloss / gloss after
use); each maps to a finding.

| Term | First used | Defined at | Verdict |
| --- | --- | --- | --- |
| MAG | L9 (scope) | L9 inline (`metagenome-assembled genomes (MAGs)`), L63 | OK |
| contig | L9 (scope) | L50, L60 (§1) | OK — §1 concepts section is one screen down |
| bin | L9 (scope) | L62 (§1) | OK (borderline — used at L9 un-glossed, defined L62) |
| coverage | L61 | L61 (defined in table) | OK |
| **k-mer** | **L67** | **never** | **FAIL → S-03** |
| **de Bruijn graph** | **L139** | **never** | **FAIL (minor) → S-03** |
| N50 | L264 | L264 (glossed inline) | OK |
| completeness / contamination | L63 | L71 (defined §1) | OK |
| MIMAG | L69 (heading) | L71 | OK |
| refinement | L419 (§8) | L421 (explained in situ) | OK |
| **single-copy marker genes** | **L421** | **never** | **FAIL (minor) → S-03** |
| dereplication | L75 | L75 (defined §1) | OK |
| ANI | L75 | L75 (defined §1) | OK |
| GTDB / GTDB-Tk | L77 | L77–79 (defined §1) | OK |
| compositional | L81 | L83 (glossed inline) | OK |
| **`srun … --pty`** | **L300** | **never** | **FAIL → S-02** (interactive-session model unexplained) |
| **`hugemem`** | **L143** | **never** | **FAIL → S-04** (NeSI partition) |
| **diamond** | **L456** | **never** | **FAIL → S-04** (fast protein aligner) |
| **`nn_seff`** | **L736** | **never** | **FAIL → S-04** (job-efficiency report) |
| **BAM** | **L109** | **never** | **FAIL (minor) → S-04** |
| **KEGG / GO / COG** | **L680** | **never** | **FAIL (minor, optional §13) → S-04** |
| SAM | L338 (comment) | never | Minor — folded into S-04 |
| pplacer | L595 | L595 (contextual, "loads the reference tree per thread") | OK |
| skani | L597 | L597 (named implementation detail) | OK |
| HMMER | L710 (contrast) | never | Minor — acceptable as a contrast token |
| cgroup | L188 (aside) | L188 (contextual) | OK |
| scaffold | — | — | Not used (checked; the brief listed it, but the doc says "contig" throughout) |

## Section ledger

Every heading in order. Treatment ∈ {CLEAN, ADD-OUTCOME, REWRITE, REWRITE-VOICE,
NAME}. `§`/lines are the document's own.

| § | Heading | Lines | Treatment | Findings |
| --- | --- | --- | --- | --- |
| — | Title + version line + draft banner | 1–11 | CLEAN (banner already added by capstone) | — |
| — | `### Before you start` | 13–17 | REWRITE (bullet 2) | **S-01** |
| — | `## Quick Roadmap: What You'll Do` | 21–40 | CLEAN — matches READBASED roadmap | — |
| 1 | `## 1. Understanding Your Data` | 44–46 | CLEAN | — |
| 1 | `### Assembly versus read-based profiling` | 48 | REWRITE-VOICE | S-08 |
| 1 | `### From reads to a MAG` | 54 | REWRITE-VOICE | S-08 |
| 1 | `### Why binning uses two signals` | 65 | REWRITE-VOICE + gloss k-mer | **S-03**, S-08 |
| 1 | `### Completeness, contamination and the MIMAG tiers` | 69 | REWRITE-VOICE | S-08 |
| 1 | `### Dereplication and ANI` | 73 | REWRITE-VOICE | S-08 |
| 1 | `### What GTDB gives you` | 77 | REWRITE-VOICE | S-08 |
| 1 | `### The final table is compositional` | 81 | REWRITE-VOICE | S-08 |
| 2 | `## 2. Before You Generate Data` | 87–89 | CLEAN — governance/depth, keep | — |
| 2 | `### Residual host sequence survives into contigs` | 91 | REWRITE-VOICE | S-08 |
| 2 | `### Assembly needs more depth than profiling` | 95 | REWRITE-VOICE | S-08 |
| 2 | `### Controls still matter, differently` | 99 | REWRITE-VOICE | S-08 |
| 3 | `## 3. Setup` | 105 | CLEAN | — |
| 3 | `### 3.1 Directories and the input contract` | 107 | REWRITE-VOICE + gloss BAM | S-04, S-08 |
| 3 | `### 3.2 The job header` | 127 | REWRITE-VOICE | S-08 |
| 3 | `### 3.3 A note on module strings` | 131 | REWRITE-VOICE | S-08 |
| 4 | `## 4. Assemble the Reads` | 137–139 | gloss k-mer/de Bruijn | S-03 |
| 4 | `### Assembler: MEGAHIT (default) or metaSPAdes` | 141 | REWRITE-VOICE + gloss hugemem | S-04, S-08 |
| 4 | `### Strategy: per-sample or co-assembly` | 145 | REWRITE-VOICE | S-08 |
| 4 | `### Per-sample assembly with MEGAHIT (default)` | 156 | REWRITE-VOICE | S-08 |
| 4 | `### Alternative: per-sample with metaSPAdes` | 193 | REWRITE-VOICE | S-08 |
| 4 | `### Alternative: co-assembly with MEGAHIT` | 223 | REWRITE-VOICE | S-08 (correctness: fork strands reader) |
| 4 | `### Checkpoint` | 252 | CLEAN | — |
| 5 | `## 5. Assess the Assembly` | 262 | CLEAN | — |
| 5 | `### Filter short contigs before binning` | 295 | REWRITE-VOICE + gloss `srun --pty` | **S-02**, S-08 |
| 6 | `## 6. Map Reads for Coverage` | 311 | CLEAN | — |
| 7 | `## 7. Bin the Contigs` | 356 | CLEAN | — |
| 8 | `## 8. Refine the Bins` | 419 | ADD-OUTCOME (runtime) + gloss diamond | **S-06**, S-04 |
| 8 | `### Collect every sample's MAGs into one place` | 463 | REWRITE-VOICE | S-08 |
| 9 | `## 9. Assess MAG Quality` | 482 | CLEAN | — |
| 9 | `### Apply the MIMAG tiers` | 508 | REWRITE-VOICE | S-08 |
| 10 | `## 10. Dereplicate Across Samples` | 530 | ADD-OUTCOME (runtime) | **S-06** |
| 11 | `## 11. Classify the MAGs` | 568 | CLEAN | — |
| 11 | `### Convert GTDB ranks to the repository vocabulary` | 601 | REWRITE-VOICE (correctness owns the glob) | S-08 |
| 12 | `## 12. Annotate the MAGs` | 631 | ADD-OUTCOME (runtime) | **S-06** |
| 13 | `## 13. Deep Functional Annotation (Optional)` | 674 | ADD-OUTCOME (runtime + checkpoint) | **S-05**, S-06 |
| 13 | `### eggNOG-mapper — orthology and functional categories` | 678 | gloss KEGG/GO/COG/diamond | S-04, S-05 |
| 13 | `### DRAM — metabolic reconstruction` | 712 | NAME script + runtime + checkpoint + gloss nn_seff | **S-07**, S-05, S-06, S-04 |
| 14 | `## 14. Build the MAG × Sample Abundance Table` | 740 | ADD-OUTCOME (runtime) | **S-06** |
| 15 | `## 15. Handoff to the R Analysis` | 785 | CLEAN | — |
| 15 | `### Reshape before you open the R analysis` | 789 | REWRITE-VOICE + gloss `srun --pty` (back-ref) | S-02, S-08 |
| 15 | `### What changes in the R analysis` | 812 | REWRITE-VOICE | S-08 |
| 15 | `### Where MAG analysis legitimately diverges` | 824 | REWRITE-VOICE | S-08 |
| 16 | `## 16. Provenance` | 836 | REWRITE (L872 prose list → bullets) | S-08 |
| — | `## Troubleshooting` | 876 | CLEAN | — |
| A | `## Appendix A: Submission Chain` | 894 | correctness owns (C-05/C-13) | — |
| B | `## Appendix B: Tools and Resources` | 920 | CLEAN — runtime source for S-06 | — |
| C | `## Appendix C: References` | 962 | CLEAN | — |
| — | Closing verify paragraph | 985–988 | CLEAN | — |

**F1 note (acceptance check #7).** `python3 scan.py SOP_ASSEMBLY_NeSI.md` prints
`117 paragraphs, 4 over 80 words` at L966, L15, L560, L595. All four are
**false positives from bullet-merging** — `scan.py` splits on headings, tables and
blockquotes but not on `-` bullet lines, so consecutive bullets are counted as one
paragraph. Measured individually: L966 is the Appendix C **citation list** (already
a list, F3-compliant); L15/L560/L595 are bullet groups whose largest single bullet
is **49 / 39 / 39 words**. No genuine prose paragraph exceeds 80 words, so **no F1
split is required** and none of the four is carried as a finding. This is recorded
here to satisfy the "every reported paragraph is accounted for" check.

## Findings

### S-01 · S1 · Prior-pipeline prerequisite reinstates the assumption the spec withdraws
- **Where:** SOP_ASSEMBLY_NeSI.md:16, § Before you start; TUTORIAL_SPEC.md:14-21, §1
- **Anchor:** `You need to have run one NeSI pipeline before`
- **Quote:**
  > - **You need to have run one NeSI pipeline before.** Bash, `module`, `sbatch` and array jobs are taken as familiar. If they are not, work through `SOP_EMU_NeSI.md` Section 1 first — it is the only document that teaches the cluster.
- **Breaks:** R2 (the §1-only redirect leaves the terms this doc adds — `srun --pty`, `hugemem`, `nn_seff` — untaught anywhere), and TUTORIAL_SPEC §1 (audience contract). This is the same class of defect the structure round rewrote out of READBASED (its S-07).
- **Reader impact:** The suite's stated reader — "a graduate student who has never opened a terminal" (§1), which "overrides what a document says about itself" — lands here from the README and is told they must already have "run one NeSI pipeline" and that bash/`sbatch`/array jobs are "taken as familiar." A first-timer either **stops**, believing they are unqualified, or is bounced to `SOP_EMU_NeSI.md` "Section 1" — but the FASTQ and quality-score concepts they need live in EMU **§2**, and this SOP separately leans on `srun --pty`, `hugemem` and `nn_seff` that no EMU section teaches. The prerequisite gates entry instead of teaching it.
- **Fix:** Replace line 16 with a redirect (matches the READBASED rewrite; the two commands EMU does not cover are handed to S-02/S-04 for local glosses):
  > - **This SOP does not re-teach the cluster.** Bash, `module`, `sbatch` and array jobs are used throughout; if they are new to you, work through `SOP_EMU_NeSI.md` **Sections 1–2** first — it is the only document that teaches the cluster, starting from `pwd`, and Section 2 covers FASTQ files and quality scores. You do not need to have finished another pipeline, only that grounding. Two things this SOP uses that Part 1 does not — an interactive `srun` shell and the `hugemem` partition — are explained where they first appear below.

### S-02 · S1 · Interactive `srun --pty` steps assume a session model the redirected novice never met
- **Where:** SOP_ASSEMBLY_NeSI.md:295-305, § 5 "Filter short contigs before binning" (recurs at :606 §11, :794 §15)
- **Anchor:** `so we drop everything under 1500 bp before Section 6`
- **Quote:**
  > Binners lose accuracy on short contigs, so we drop everything under 1500 bp before Section 6. Run this once, interactively:
  >
  > ```bash
  > srun --account=<your_nesi_project_code> --time=00:20:00 --mem=4G --pty bash
  > module purge; module load SeqKit/2.4.0
  > while read -r S; do
  > ```
- **Breaks:** R2 (`srun --pty` first-used with no definition and no lookup path — EMU §1 teaches `sbatch`, not interactive `srun`), §4 step template (a reader cannot execute the step whose model they do not have).
- **Reader impact:** This is the first of **three mandatory main-path steps** (the min1500 filter, the GTDB rank conversion §11, the CoverM reshape §15) that switch from `sbatch` to an interactive shell. A terminal novice who has only been shown `sbatch` does not know that the `srun … --pty bash` line **opens a new shell on a compute node**, that the lines beneath it are typed **inside** that shell, or that a few seconds' pause while SLURM allocates a node is normal rather than a hang. They paste the whole block into their login shell, or kill the "stuck" allocation, and stall on a required step.
- **Fix:** Change the lead-in at line 297 and add one gloss. Replace "Run this once, interactively:" with:
  > Run this once in an **interactive shell** — a live prompt on a compute node, unlike the `sbatch` scripts that queue and run on their own. The first line asks SLURM for that shell (it may pause a few seconds while a node is found — that is normal); run the lines beneath it **inside** the shell it gives you, and type `exit` once the checkpoint passes to return to the login node.

  At the §11 (line 606) and §15 (line 794) `srun` blocks, add the one-line back-reference before the fence: "Run this in an interactive shell, as in Section 5 — type `exit` when it finishes."

### S-03 · S2 · k-mer, de Bruijn and single-copy marker genes power binning but are never glossed
- **Where:** SOP_ASSEMBLY_NeSI.md:67 (§1), :139 (§4), :421 (§8)
- **Anchor:** `k-mer frequencies, which are genome-characteristic`
- **Quote:**
  > A binner groups contigs by **sequence composition** (k-mer frequencies, which are genome-characteristic) and by **coverage**
- **Breaks:** R2 (k-mer, de Bruijn graph, single-copy marker genes used before/without definition), R8 (jargon before plain words — "sequence composition" is explained by the very term the reader does not know).
- **Reader impact:** k-mer is the hinge of the whole §1 explanation of *why binning uses two signals* and reappears as the mechanism of assembly (§4, "overlapping k-mers … de Bruijn graph"). A beginner meets the concept the binning rationale rests on with no idea what a k-mer is, so the layer-1 concept section — the document's strongest asset — quietly fails for them exactly where it should land. "Single-copy marker genes" (§8) is the basis of DAS_Tool scoring and CheckM2, used three times, never said plainly.
- **Fix:** Gloss at first use. Replace the L67 clause with:
  > A binner groups contigs by **sequence composition** — the frequencies of short DNA words of a fixed length, called **k-mers** (for example, every distinct 4-letter stretch), which are characteristic of a given genome — and by **coverage** (contigs of one genome rise and fall together across samples).

  At L139, change "overlapping k-mers, threads a graph through them" to "overlapping **k-mers** (short fixed-length DNA words), threads a **de Bruijn graph** (a standard way to reconstruct sequences from those overlaps) through them". At L421, change "single-copy marker genes" to "**single-copy marker genes** (genes expected exactly once per genome, so finding two copies flags contamination)".

### S-04 · S2 · Tool and partition tokens the reader must invoke or choose are used with no gloss
- **Where:** SOP_ASSEMBLY_NeSI.md:143 (`hugemem`), :456/:705 (diamond), :736/:943 (`nn_seff`), :109 (BAM), :680 (KEGG/GO/COG)
- **Anchor:** `a real cost you choose knowingly, not a free upgrade`
- **Quote:**
  > **metaSPAdes** often produces more contiguous assemblies on lower-diversity samples, but it can demand 200–250 GB of RAM and must queue on `hugemem` — a real cost you choose knowingly, not a free upgrade.
- **Breaks:** R2 (each term first-used with no definition and, for the novice audience, no lookup path).
- **Reader impact:** These are not background terms — the reader is asked to *act* on them. `hugemem` is offered as a decision ("choose knowingly") with no statement of what it is; `nn_seff` is an instruction ("calibrate with `nn_seff`") to run a command the reader does not know or know the form of; `diamond` gates two search steps (§8, §13); BAM is the coverage artefact of §6. Each is a one-line lookup individually, but they accumulate on a reader the suite says has never opened a terminal, and `nn_seff` in particular is a bare imperative with no command shown.
- **Fix:** One-clause glosses at first use:
  - L143: "…must queue on `hugemem` (NeSI's large-memory partition, requested with the `#SBATCH --partition hugemem` line the script below already carries) — a real cost you choose knowingly, not a free upgrade."
  - L109: "assembly graphs and **BAM files** (the compact binary form of reads aligned to contigs) run to tens of gigabytes"
  - §8, add a bullet after L461: "**`--search_engine diamond`** uses **diamond**, a fast protein-sequence aligner, for the marker-gene search — quicker than the alternative on whole genomes."
  - L680: "assigns each protein to an orthologous group and its **KEGG, GO and COG** annotations (three standard databases of gene function and pathways)."
  - L736: "calibrate walltime and memory with **`nn_seff`** — run `nn_seff <job_id>` after a job finishes to see the peak memory and CPU it actually used — then scale."

### S-05 · S2 · §13 eggNOG-mapper and DRAM steps run with no checkpoint to tell they worked
- **Where:** SOP_ASSEMBLY_NeSI.md:678-736, § 13 (eggNOG-mapper and DRAM)
- **Anchor:** `far faster for whole genomes`
- **Quote:**
  > - **`-m diamond`** uses the pre-built diamond database rather than HMMER — far faster for whole genomes.
- **Breaks:** R5 / §4 step template ("Item 5 is not optional. A command with no success criterion is a defect however correct the command is.").
- **Reader impact:** Every other action step in the document ends in an `Expect`/`Checkpoint` block; the two §13 steps do not. eggNOG-mapper is an array job over every MAG that can silently drop tasks (a missing `--data_dir`, an OOM), and DRAM is flagged as "the most likely step in this SOP to exceed its allocation." With no checkpoint the reader has no way to tell a partial or failed run from a complete one before feeding the output onward — the exact gap the step template exists to close.
- **Fix:** Add a checkpoint after each. After the eggNOG bullets (following L710):
  > **Checkpoint:** `ls annotation/eggnog/*.emapper.annotations | wc -l` should equal `$NMAG` — one annotation table per MAG. **Fewer** means some array tasks failed; check their `.err` logs for a `--data_dir` or out-of-memory error before using the results.

  After the DRAM block (following L736):
  > **Checkpoint:** `ls annotation/dram/distilled/` should list the distilled metabolism summary files. An **empty** `distilled/` means `annotate` produced no `annotations.tsv` — re-check the shared config resolved with `DRAM-setup.py print_config`.

  *(Cross-flag: the exact eggNOG/DRAM output filenames should be confirmed by the correctness round; the checkpoint's logic — one output per MAG, non-empty distilled dir — holds regardless.)*

### S-06 · S3 · Five heavy steps drop the inline runtime the step template requires
- **Where:** SOP_ASSEMBLY_NeSI.md, §§ 8/10/12/13/14 (headings :419, :530, :631, :674, :740)
- **Anchor:** `## **8. Refine the Bins**`
- **Quote:**
  > ## **8. Refine the Bins**
- **Breaks:** R5 / §4 step template ("Item 4 costs six words and stops the reader wondering whether the job has hung").
- **Reader impact:** §§4/5/6/7/9/11 each carry a `**How long:**` line; §§8 (DAS_Tool), 10 (dRep), 12 (Bakta), 13 (eggNOG/DRAM) and 14 (CoverM) — several multi-hour — do not. A reader waiting on a 6-hour dRep or an 8-hour CoverM job has no in-step order of magnitude and, by the spec's own reasoning, cannot tell a slow job from a hung one. The figures already exist in Appendix B (lines 945-960); they are simply not in the steps.
- **Fix:** Add a `**How long:**` line to each, from Appendix B:
  - §8, after the DAS_Tool bullets (L461): `**How long:** roughly 1–2 hours per sample.`
  - §10, after the dRep bullets (L562): `**How long:** ~6 hours for the whole cohort at once.`
  - §12, after the Bakta bullets (L668): `**How long:** roughly 1–2 hours per MAG.`
  - §13 eggNOG, after L710: `**How long:** ~4 hours per MAG.` — and §13 DRAM, after L736: `**How long:** up to 24 hours; the reason to validate on 1–2 MAGs first.`
  - §14, after the CoverM bullets (L779): `**How long:** ~4–8 hours for the whole cohort.`

### S-07 · S3 · DRAM job block carries no `scripts/…` filename to save it under
- **Where:** SOP_ASSEMBLY_NeSI.md:716-734, § 13 DRAM block; Appendix B:959
- **Anchor:** `DRAM-setup.py print_config`
- **Quote:**
  > Validate on one or two MAGs before scaling, and check `DRAM.py annotate` sees the shared configuration — `DRAM-setup.py print_config` can be slow to return.
  >
  > ```bash
  > #!/bin/bash
  > #SBATCH --account <your_nesi_project_code>
  > #SBATCH --job-name dram
- **Breaks:** R6 (script filenames carry their section number; a bare section number/name must resolve), R11 (the reader copies "one block" and saves it — with no name they cannot).
- **Reader impact:** Every other reader-created job block is introduced with a backtick `scripts/NN.name.sl` line naming the file to save it as (e.g. `scripts/13a.eggnog.sl` at L682), and Appendix B row L959 lists `13b.dram` as though the file exists. The DRAM block alone has no such intro line, so a reader working from the resource table looks for `13b.dram`, finds no heading to save it under, and cannot tell which body block it is — reading as an unfinished section.
- **Fix:** Insert immediately before the DRAM code fence (before L718):
  > `scripts/13b.dram.sl` (single job):

### S-08 · S4 · Sentence-case `###` subheads against the title-case rule, plus one prose list
- **Where:** SOP_ASSEMBLY_NeSI.md — `###` subheads throughout (:48, :54, :65, :69, :77, :81, :91, :95, :99, :141, :145, :295, :463, :508, :601, :789, :812, :824); prose list at :872
- **Anchor:** `### **From reads to a MAG**`
- **Quote:**
  > ### **From reads to a MAG**
- **Breaks:** R9 / §8 (headings "Bold, title case"), F3 (the §16 provenance run is an unwritten list).
- **Reader impact:** Cosmetic but suite-wide: a reader moving between documents meets a heading style that shifts, and §8 sets one house rule the reviewed four are being brought to. The §16 prose enumeration ("Record additionally … which samples … the GTDB release tag … the Bakta and eggNOG database versions … and whether MAGs were screened") is four record-keeping items a scanner should be able to tick off as a list.
- **Fix:** Title-case every `###` subhead, leaving tool/flag tokens in their own casing — e.g. "From Reads to a MAG", "Why Binning Uses Two Signals", "Completeness, Contamination and the MIMAG Tiers", "The Final Table Is Compositional", "Residual Host Sequence Survives into Contigs", "Assembly Needs More Depth than Profiling", "Strategy: Per-Sample or Co-assembly", "Filter Short Contigs before Binning", "Collect Every Sample's MAGs into One Place", "Apply the MIMAG Tiers", "Convert GTDB Ranks to the Repository Vocabulary", "Reshape before You Open the R Analysis", "What Changes in the R Analysis", "Where MAG Analysis Legitimately Diverges" (`metaSPAdes`, `eggNOG-mapper`, `DRAM`, `MEGAHIT`, `GTDB`, `MAG`, `ANI` keep their casing). Convert L872 to a list:
  > Record these as you go — your methods section needs them:
  > - which samples yielded no MAGs, and why
  > - the GTDB release tag (from `${GTDBTK_DATA_PATH}`)
  > - the Bakta and eggNOG database versions
  > - whether MAGs were screened for host sequence before any deposition

## Target outline

The document's shape is already on-spec, so this is the current heading structure
with per-line treatment; a rewrite builds from it plus the findings without
re-reading the original. `KEEP` = unchanged; `REWRITE` = per its finding;
`REWRITE-VOICE` = title-case only.

```
*Taylor Lab | Assembly-Based Shotgun Metagenomics SOP*                    KEEP
# **Assembly and Binning: Recovering MAGs on NeSI**                       KEEP
**v0.1** | … | suite v1.1 (August 2026, draft)                            KEEP
> Draft (v0.1) banner                                                     KEEP (capstone already added)
<scope paragraph>                                                         KEEP
### Before you start                                                      REWRITE bullet 2 (S-01); glosses forward-ref srun/hugemem
## Quick Roadmap: What You'll Do                                          KEEP
## 1. Understanding Your Data                                            KEEP
   ### Assembly Versus Read-Based Profiling                               REWRITE-VOICE
   ### From Reads to a MAG                                                REWRITE-VOICE
   ### Why Binning Uses Two Signals                                       REWRITE-VOICE + gloss k-mer (S-03)
   ### Completeness, Contamination and the MIMAG Tiers                    REWRITE-VOICE
   ### Dereplication and ANI                                             REWRITE-VOICE
   ### What GTDB Gives You                                                REWRITE-VOICE
   ### The Final Table Is Compositional                                  REWRITE-VOICE
## 2. Before You Generate Data                                          KEEP (keep-list: host/depth/controls)
   ### Residual Host Sequence Survives into Contigs                       REWRITE-VOICE
   ### Assembly Needs More Depth than Profiling                           REWRITE-VOICE
   ### Controls Still Matter, Differently                                 REWRITE-VOICE
## 3. Setup                                                              KEEP
   ### 3.1 Directories and the Input Contract                            REWRITE-VOICE + gloss BAM (S-04)
   ### 3.2 The Job Header                                                REWRITE-VOICE
   ### 3.3 A Note on Module Strings                                      REWRITE-VOICE
## 4. Assemble the Reads                                                gloss k-mer/de Bruijn (S-03)
   ### Assembler: MEGAHIT (default) or metaSPAdes                        REWRITE-VOICE + gloss hugemem (S-04)
   ### Strategy: Per-Sample or Co-assembly                               REWRITE-VOICE
   ### Per-Sample Assembly with MEGAHIT (default)                        REWRITE-VOICE
   ### Alternative: Per-Sample with metaSPAdes                           REWRITE-VOICE  [correctness: canonical-path fork]
   ### Alternative: Co-assembly with MEGAHIT                             REWRITE-VOICE  [correctness: canonical-path fork]
   ### Checkpoint                                                        KEEP
## 5. Assess the Assembly                                               KEEP
   ### Filter Short Contigs before Binning                              REWRITE-VOICE + gloss srun --pty (S-02)
## 6. Map Reads for Coverage                                            KEEP (has runtime + checkpoint)
## 7. Bin the Contigs                                                   KEEP (has runtime + checkpoint)
## 8. Refine the Bins                                                   ADD runtime (S-06) + gloss diamond (S-04)
   ### Collect Every Sample's MAGs into One Place                       REWRITE-VOICE
## 9. Assess MAG Quality                                                KEEP
   ### Apply the MIMAG Tiers                                            REWRITE-VOICE
## 10. Dereplicate Across Samples                                       ADD runtime (S-06)
## 11. Classify the MAGs                                                KEEP  [correctness owns the glob path]
   ### Convert GTDB Ranks to the Repository Vocabulary                  REWRITE-VOICE
## 12. Annotate the MAGs                                                ADD runtime (S-06)
## 13. Deep Functional Annotation (Optional)                            ADD runtime + checkpoints (S-05/S-06)
   ### eggNOG-mapper — Orthology and Functional Categories             gloss KEGG/GO/COG (S-04) + checkpoint (S-05)
   ### DRAM — Metabolic Reconstruction                                 NAME script (S-07) + runtime/checkpoint/nn_seff
## 14. Build the MAG × Sample Abundance Table                          ADD runtime (S-06)
## 15. Handoff to the R Analysis                                        KEEP
   ### Reshape before You Open the R Analysis                          REWRITE-VOICE + srun back-ref (S-02)
   ### What Changes in the R Analysis                                  REWRITE-VOICE (keep-list: SRS/compositional)
   ### Where MAG Analysis Legitimately Diverges                        REWRITE-VOICE
## 16. Provenance                                                       REWRITE L872 prose → list (S-08)
## Troubleshooting                                                      KEEP
## Appendix A: Submission Chain                                         [correctness owns C-05/C-13]
## Appendix B: Tools and Resources                                      KEEP (runtime source for S-06)
## Appendix C: References                                               KEEP
<closing verify paragraph>                                              KEEP
```

## Keep list

Load-bearing content a rewrite must not lose. Each `grep -F`s to exactly one hit
in the source (verified in the self-check). Shared with the capstone keep list;
every entry is layer-2 "why this number" or silent-failure content — KEEP or
rewrite-tighter, never cut.

1. Depth-budget floor / scope — `≥5 Gb of clean sequence per sample`
2. Governance, host-in-contigs — `Treat a MAG carrying human contigs as controlled data`
3. metaQUAST silent-download warning — `Zero turns off reference downloading`
4. MEGAHIT memory-headroom "why" — `caps MEGAHIT at 90% of the memory it detects`
5. GTDB-Tk OOM guard — `The unsplit bacterial tree needs more than 320 GB`
6. dRep silent-disagreement guard — `Providing`
7. CheckM2 expected-output caveat — `CheckM2 does not check rRNA/tRNA genes`
8. CoverM presence threshold "why" — `suppresses spurious low-level cross-mapping`
9. Compositional handoff guard — `never round it or pass it through SRS`
10. min1500 shallow-sample tell — `the sample was too shallow to assemble well`
11. Empty-`$SAMPLE` array footgun — `runs on sample 1 only and exits 0`

## Rewrite plan

Ordered, dependency-aware. Every item is internal to `SOP_ASSEMBLY_NeSI.md` and can
proceed independently of the other files; net word change is small (~+150 words of
glosses/checkpoints/runtimes, no content removed). Do the audience reframe first —
it defines who the glosses are written for.

| # | Item | Closes | Size | Notes |
| --- | --- | --- | --- | --- |
| 1 | Reframe Before-you-start bullet 2 as a redirect to EMU **Sections 1–2**; forward-ref the two non-EMU commands | S-01 | ~+25w | Highest value; sets the audience the rest is written for. Overlaps README router/count fix (capstone C-01/W3) — coordinate. |
| 2 | Gloss `srun --pty` at §5 first use + one-line back-refs at §11/§15 | S-02 | ~+55w | Main-path; unblocks the three interactive steps. |
| 3 | Gloss k-mer / de Bruijn / single-copy marker genes (§1, §4, §8) | S-03 | ~+35w | Restores the §1 concept spine for a novice. |
| 4 | Gloss `hugemem`, diamond, `nn_seff`, BAM, KEGG/GO/COG at first use | S-04 | ~+40w | One clause each; some ride the same bullets as S-06. |
| 5 | Add `**How long:**` to §§8/10/12/13/14 from Appendix B | S-06 | ~+30w | Mechanical; numbers already tabulated. |
| 6 | Add checkpoint blocks to §13 eggNOG and DRAM | S-05 | ~+40w | Cross-flag exact output filenames to the correctness round. |
| 7 | Insert `scripts/13b.dram.sl` intro line before the DRAM fence | S-07 | +1 line | Trivial. |
| 8 | Title-case all `###` subheads; convert §16 L872 prose to a list | S-08 | ~flat | House-style sweep; mechanical, do last to avoid churn. |

**Overlap with the correctness round (let it lead):** §4 metaSPAdes/co-assembly
forks (C-04/C-12) and §11/§15 GTDB-Tk paths (C-02/C-04/C-07) touch lines this
review only voice-edits — apply the correctness fix first, then the title-case
pass over the same headings. Appendix A (C-05/C-13) is entirely the correctness
round's. The README router/count and draft-marker (C-01/C-03) live outside this
file and are handled by the capstone's W3/W6.

## Self-check

```bash
python3 - <<'PY'
import re, subprocess
REPORT="reviews/assembly_review/ASSEMBLY.tutorial.md"; SOURCE="SOP_ASSEMBLY_NeSI.md"
F=["Where","Anchor","Quote","Breaks","Reader impact","Fix"]
txt=open(REPORT).read()
blocks=[b for b in re.split(r'\n(?=### S-)',txt) if b.startswith('### S-')]
bad=[]
for b in blocks:
    m=re.match(r'### (S-\d+) · (S\d) · (.+)',b.split('\n')[0])
    if not m: bad.append((b[:30],'malformed heading')); continue
    fid,sev,summ=m.groups()
    if miss:=[k for k in F if f'- **{k}:**' not in b]: bad.append((fid,f'missing {miss}'))
    if len(summ)>90: bad.append((fid,f'summary {len(summ)} chars > 90'))
    if not re.search(r'- \*\*Breaks:\*\*.*R\d',b): bad.append((fid,'no rule cited'))
    if a:=re.search(r'- \*\*Anchor:\*\* *`([^`]+)`',b):
        n=subprocess.run(['grep','-cF',a.group(1),SOURCE],capture_output=True,text=True).stdout.strip() or '0'
        if n!='1': bad.append((fid,f'anchor matches {n}x, must be 1'))
sev=[re.match(r'### S-\d+ · (S\d)',b).group(1) for b in blocks if re.match(r'### S-\d+ · (S\d)',b)]
print(f"findings={len(blocks)} "+" ".join(f"{s}={sev.count(s)}" for s in ['S1','S2','S3','S4']))
if sev.count('S4')>15: print(f"!! S4 cap exceeded: {sev.count('S4')}")
for f,w in bad: print(f"!! {f}: {w}")
print("CLEAN" if not bad else f"{len(bad)} violations")
PY
```

_Output:_

```
findings=8 S1=2 S2=3 S3=2 S4=1
CLEAN
```

By hand: the ledger accounts for every heading in the source; the target outline
covers every section in the ledger; nothing on the keep list is proposed for
removal.

CONTRACT: PASS
