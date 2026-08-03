# Capstone Review — `SOP_ASSEMBLY_NeSI.md` (Agent A, heavier Assembly pass)

Run 2026-08-04 on NeSI Mahuika, from `/nesi/project/uoa03769/taylor-lab-sops`.
Read in order first: COMMON BRIEF → `reviews/00_SYNTHESIS.md`, `reviews/00_ENVIRONMENT.md`,
`reviews/structure/00_PLAN.md`, `reviews/structure/00_REALITY.md` and the four
per-document reports (for method — none reviewed this file) → `TUTORIAL_SPEC.md` →
`reviews/capstone/00_FACTS.md` → then `SOP_ASSEMBLY_NeSI.md` in full (985 lines,
v0.1, August 2026). This is the first review the document has had.

## Document: SOP_ASSEMBLY_NeSI.md

A genuinely strong first draft: Section 1 defines the binning vocabulary
(contig, coverage, bin, MAG, completeness, contamination, MIMAG, dereplication,
ANI, GTDB, compositional) before any command; every job block is complete and
runnable with header, `set -euo pipefail` and the empty-`$SAMPLE` guard; the
load-bearing "why this number" content (depth budget, `--max-ref-number 0`,
`--pplacer_cpus 1`, `--genomeInfo`, `--min-covered-fraction`) is present and
correct; all 17 module strings and all three `/opt/nesi/db` databases resolve.
But it has **never been through the two dedicated review rounds its siblings had**,
and the sweep below found one silent-empty-output correctness bug that only a
source check catches (C-02), a co-assembly/metaSPAdes fork that strands the reader
(C-04), an unrunnable submission appendix (C-05), and the audience-contract
conflict the brief told me to look for (C-03). It is **not ready to ship as a peer.**

## Section ledger

`§` numbers are the document's own. Treatment ∈ {CLEAN, ADD-NAV, RENUMBER,
RELABEL, SPLIT, MERGE, FIX-REF, FIX-FIGURE, REWRITE-TIGHTER}.

| § | Heading | Lines | Treatment | Findings |
| --- | --- | --- | --- | --- |
| — | Title + version line | 1-9 | RELABEL (add draft banner) | **C-01** |
| — | Before you start | 11-16 | REWRITE-TIGHTER | **C-03** |
| — | Quick Roadmap: What You'll Do | 19-38 | CLEAN (matches READBASED roadmap) | — |
| 1 | Understanding Your Data (+7 concept subheads 46-81) | 42-82 | RELABEL (heading case) | C-09, C-10 |
| 2 | Before You Generate Data | 85-100 | CLEAN — governance/depth, keep | — |
| 3 | Setup (3.1-3.3) | 103-132 | CLEAN — input contract verified | — |
| 4 | Assemble the Reads (MEGAHIT default; metaSPAdes/co-assembly alts) | 135-257 | FIX-REF | **C-04** |
| 5 | Assess the Assembly (metaQUAST + min1500 filter) | 260-306 | FIX-REF | **C-04** |
| 6 | Map Reads for Coverage | 309-351 | CLEAN — combined load verified OK | — |
| 7 | Bin the Contigs (MetaBAT2/MaxBin2/CONCOCT) | 354-414 | CLEAN — CONCOCT+SAMtools load verified | — |
| 8 | Refine the Bins (DAS_Tool) | 417-477 | ADD-NAV (runtime) | **C-06** |
| 9 | Assess MAG Quality (CheckM2 + MIMAG) | 480-525 | CLEAN — awk cols correct | — |
| 10 | Dereplicate Across Samples (dRep) | 528-563 | ADD-NAV (runtime) | C-06 |
| 11 | Classify the MAGs (GTDB-Tk) + rank convert | 566-626 | FIX-REF | **C-02** |
| 12 | Annotate the MAGs (Bakta) | 629-669 | ADD-NAV (runtime) | C-06 |
| 13 | Deep Functional Annotation (eggNOG; DRAM) | 672-735 | RELABEL (name DRAM script) + ADD-NAV | **C-08**, C-06 |
| 14 | Build the MAG × Sample Abundance Table (CoverM) | 738-780 | ADD-NAV (runtime) | C-06 |
| 15 | Handoff to Part 2 (reshape + deltas) | 783-831 | FIX-REF | **C-07** |
| 16 | Provenance | 834-871 | CLEAN — keep | — |
| — | Troubleshooting (table) | 874-889 | CLEAN | — |
| A | Appendix A: Submission Chain | 892-916 | FIX-REF / REWRITE-TIGHTER | **C-05** |
| B | Appendix B: Tools and Resources | 918-958 | CLEAN — 17 modules + 3 DBs verified | — |
| C | Appendix C: References | 960-979 | CLEAN — keep | — |
| — | Closing verify paragraph | 983-985 | CLEAN | — |

## Findings

### C-01 · S1 · Unreviewed v0.1 document routed to new students as a peer of the reviewed SOPs
- **Where:** SOP_ASSEMBLY_NeSI.md, § Header/version (line 5); README.md, § Which SOP do I need? (line 14)
- **Anchor:** `**v0.1** | last updated August 2026`
- **Quote:**
  > **v0.1** | last updated August 2026 | NeSI (SLURM) | Illumina paired-end
- **Defect:** This document is v0.1 and has been through neither `SOP_REVIEW_PROMPT.md` nor `SOP_TUTORIAL_PROMPT.md` — the two rounds that produced the siblings' v2.0–v3.0 — yet the README routes a new student straight into it as an equal path, and nothing the reader sees flags it as a draft.
- **Impact:** A student with shotgun data reads the README, is sent to `SOP_ASSEMBLY_NeSI.md` (README line 14, no caveat), and follows it word-for-word trusting it like the others — including the defects this review is the first to find (e.g. C-02 hands Part 2 an empty taxonomy). To that reader `v0.1` in the header does not read as "not yet validated."
- **Type:** COHERENCE
- **Confidence:** CONFIRMED
- **Evidence:** Version spread from Agent 0's facts — EMU v2.0, CONCOMPRA v2.1, READBASED v3.0, R_Analysis v2.1 (all July 2026, both rounds), ASSEMBLY v0.1 (August 2026); ASSEMBLY appears in no prior review report and is outside `TUTORIAL_SPEC.md`'s "four documents" scope. README.md:14 routes shotgun-MAG readers here with no draft marker; README footer still reads "four SOPs" (Agent 0 fact #7 — a seam left open, credited to that round).
- **Fix:** Do not ship as a peer until the full review lands (see Release recommendation). Interim, make the draft state reader-facing and gate the routing.
  In `SOP_ASSEMBLY_NeSI.md`, insert after line 5:
  > **Draft (v0.1) — not yet through the lab's correctness and tutorial review rounds.** Treat every command as unverified end-to-end: run one sample first and check each checkpoint before you rely on results or scale to a cohort.

  In `README.md` line 14, mark the assembly cell `SOP_ASSEMBLY_NeSI.md (draft, v0.1)` and update the footer count from "four SOPs" to "five SOPs (one, assembly, in draft)".

### C-02 · S1 · §11 GTDB-Tk parser globs the wrong directory, so MAG taxonomy comes out empty
- **Where:** SOP_ASSEMBLY_NeSI.md, § 11 "Convert GTDB ranks to the repository vocabulary" (lines 605-623)
- **Anchor:** `glob.glob("gtdbtk/*.summary.tsv")`
- **Quote:**
  > for f in glob.glob("gtdbtk/*.summary.tsv"):          # bac120 and/or ar53
- **Defect:** GTDB-Tk 2.7.1 writes its per-domain summaries to `gtdbtk/classify/gtdbtk.bac120.summary.tsv` (and `…ar53…`), **not** the top level of `--out_dir`. The non-recursive glob `gtdbtk/*.summary.tsv` matches nothing, so the parser writes a header-only `tables/mag_taxonomy.tsv`.
- **Impact:** On the default path, the reader runs §11, sees `0 MAGs classified`, and — if they read past it — the §15 reshape merges the empty taxonomy `how="right"` onto abundances and hands Part 2 a table in which **every MAG has blank ranks**. The §11 checkpoint even primes them to read blank ranks as normal ("Empty `species` fields are normal"), so a novel-but-classified cohort is indistinguishable from a total parse miss. This is the silent-empty-output S1 the Assembly sweep exists to catch.
- **Type:** CONTENT
- **Confidence:** VERIFIED
- **Evidence:** From the installed module source: `gtdbtk/files/classify_summary.py:191,199` build the path as `os.path.join(out_dir, PATH_{AR53,BAC120}_SUMMARY_OUT.format(prefix=prefix))`, and `gtdbtk/config/output.py:44-45` define those as `join(DIR_CLASSIFY, '{prefix}.bac120.summary.tsv')` with `DIR_CLASSIFY = 'classify'`. Resolved live:
  ```
  $ python3 -c "from gtdbtk.config.output import PATH_BAC120_SUMMARY_OUT; print(PATH_BAC120_SUMMARY_OUT.format(prefix='gtdbtk'))"
  classify/gtdbtk.bac120.summary.tsv
  ```
  With the SOP's `--out_dir gtdbtk`, the file is at `gtdbtk/classify/…`, which `glob.glob("gtdbtk/*.summary.tsv")` does not reach.
- **Fix:** Point the glob into `classify/`:
  ```python
  for f in glob.glob("gtdbtk/classify/*.summary.tsv"):          # bac120 and/or ar53
  ```

### C-03 · S2 · Doc requires prior-pipeline experience the tutorial spec explicitly withdraws
- **Where:** SOP_ASSEMBLY_NeSI.md, § Before you start (line 14); TUTORIAL_SPEC.md, § 1 Who these are for (lines 14-21)
- **Anchor:** `You need to have run one NeSI pipeline before`
- **Quote:**
  > - **You need to have run one NeSI pipeline before.** Bash, `module`, `sbatch` and array jobs are taken as familiar. If they are not, work through `SOP_EMU_NeSI.md` Section 1 first — it is the only document that teaches the cluster.
- **Defect:** `TUTORIAL_SPEC.md` §1 sets one audience for the whole suite — "A graduate student who has never opened a terminal" — and states "This overrides what a document says about itself … that assumption is withdrawn," naming exactly the prior-pipeline assumption. ASSEMBLY reinstates it as a hard prerequisite. This is the same class of defect the structure round rewrote out of READBASED (its S-07), now live in the un-reviewed document.
- **Impact:** The suite's stated reader lands here from the README, reads that they must already have "run one NeSI pipeline," and either stops (believing they are unqualified) or is bounced to EMU "Section 1" — but the FASTQ/quality concepts a first-timer needs live in EMU **§2**, and the doc separately leans on `srun --pty`, `hugemem` and `nn_seff` (C-10) that a single Section-1 redirect does not cover.
- **Type:** COHERENCE
- **Confidence:** CONFIRMED
- **Evidence:** Direct contradiction, both sides quoted — ASSEMBLY:14 ("taken as familiar") vs TUTORIAL_SPEC:14-18 ("A graduate student who has never opened a terminal … that assumption is withdrawn").
- **Fix:** Reframe the prerequisite as a redirect, matching the READBASED rewrite:
  > - **This SOP does not re-teach the cluster.** Bash, `module`, `sbatch` and array jobs are used throughout; if they are new to you, work through `SOP_EMU_NeSI.md` **Sections 1–2** first — it is the only document that teaches the cluster, starting from `pwd`, and Section 2 covers FASTQ and quality scores. You do not need to have finished another pipeline, only that grounding.

### C-04 · S2 · metaSPAdes and co-assembly branches read files the given commands never create
- **Where:** SOP_ASSEMBLY_NeSI.md, § 4 metaSPAdes/co-assembly (lines 191-248) and § 5-6 (lines 301, 334)
- **Anchor:** `so downstream scripts must point at the right one`
- **Quote:**
  > metaSPAdes writes contigs to `assemblies/${SAMPLE}/contigs.fasta` — a different name and path from MEGAHIT, so downstream scripts must point at the right one.
- **Defect:** Every step from §5 on hard-codes the MEGAHIT per-sample artefact (`assemblies/${SAMPLE}/${SAMPLE}.contigs.fa`, then `…min1500.fa`). The doc *flags* that metaSPAdes writes a different name but never resolves it, and the co-assembly path it references in §6 (`coassembly/all/coassembly.min1500.fa`, line 334) is never produced — §5's metaQUAST and min1500 filter run per-sample only. Both non-default forks are offered with "choose when" guidance and wired into Appendix A, yet either one strands the reader at §5/§6.
- **Impact:** A reader who correctly picks metaSPAdes (line 191) or co-assembly (line 221) for their study finishes §4, then §5's filter/metaQUAST and §6's mapping fail on a missing `${SAMPLE}.contigs.fa` / `.min1500.fa`, with only a one-line prose warning and no command to bridge the gap.
- **Type:** CONTENT
- **Confidence:** CONFIRMED
- **Evidence:** §5 filter reads `assemblies/${S}/${S}.contigs.fa` (line 301); §6 sets `ASM="assemblies/${SAMPLE}/${SAMPLE}.min1500.fa"` with a co-assembly comment `coassembly/all/coassembly.min1500.fa` (line 334); metaSPAdes writes `contigs.fasta` (line 217); co-assembly writes `coassembly/all/coassembly.contigs.fa` (line 248) and no §5 step ever filters it.
- **Fix:** Normalise each alternative to the canonical MEGAHIT path so the rest of the SOP is untouched.
  (a) In `scripts/04b.assemble_metaspades.sl`, add after the `spades.py` command:
  ```bash
  ln -sf contigs.fasta "assemblies/${SAMPLE}/${SAMPLE}.contigs.fa"   # canonical name for §5–§8
  ```
  (b) For co-assembly, add a one-off block at the end of §5 (before §6), and state that `$ASM` for §6–§8 is then `coassembly/all/coassembly.min1500.fa` (the mapping array still runs `1-${NSAMP}`, mapping every sample to the one assembly):
  ```bash
  # Co-assembly only: QC and filter the single assembly to the canonical min1500 name.
  module purge; module load QUAST/5.2.0-gimkl-2022a
  metaquast.py coassembly/all/coassembly.contigs.fa -o qc_assembly/coassembly \
    --min-contig 1000 --max-ref-number 0 --threads 8
  module purge; module load SeqKit/2.4.0
  seqkit seq -m 1500 coassembly/all/coassembly.contigs.fa > coassembly/all/coassembly.min1500.fa
  ```

### C-05 · S2 · Appendix A says submit-at-once but wires jobs past three required manual steps
- **Where:** SOP_ASSEMBLY_NeSI.md, § Appendix A: Submission Chain (lines 893-916)
- **Anchor:** `submit the pipeline at once and let SLURM sequence it`
- **Quote:**
  > Each job waits on the one it depends on, so you can submit the pipeline at once and let SLURM sequence it.
- **Defect:** The appendix contradicts itself and cannot run as printed. It later says "The two interactive steps (contig filtering, bin collection) break the chain deliberately," yet the block wires `MAP` to `afterok:$ASM` (mapping auto-starts before the manual min1500 filter exists) and `CM2` to `afterok:$DAS` (CheckM2 auto-starts before the manual `mags/` collection). It also submits `12.bakta.sl --array=1-${NMAG}%10` while `$NMAG` is unset — `mags_derep.txt`, the file it counts, is not built until §12, after dRep — so that line errors at submit with an invalid array spec.
- **Impact:** A reader who does as told and pastes the block "at once" queues assembly and metaQUAST, then map_coverage and every later job fire on their dependencies before the human has run the filter/collect steps, cascading into missing-file failures; the bakta submission additionally rejects on an empty `--array=1-%10`. The reader believes the pipeline is sequencing when key stages never ran.
- **Type:** LAYOUT
- **Confidence:** CONFIRMED
- **Evidence:** Line 893 "submit the pipeline at once" vs line 916 "break the chain deliberately"; MAP/CM2 dependencies (lines 902/906) point at `$ASM`/`$DAS`, not the interactive steps commented at 901/905; `$NMAG` is never set in the block (only `NSAMP`, line 897) yet used at line 910.
- **Fix:** Present the chain in three submit-phases with the interactive steps between, and defer bakta's array until `mags_derep.txt` exists:
  ```bash
  cd "$WORK"; NSAMP=$(wc -l < samples.txt)

  # Phase 1 — assemble, then STOP: filter to min1500 (Section 5) interactively.
  ASM=$(sbatch --parsable --array=1-${NSAMP}%4 scripts/04a.assemble_megahit.sl)
  QC=$(sbatch  --parsable --dependency=afterok:$ASM --array=1-${NSAMP} scripts/05.metaquast.sl)

  # → wait for $ASM, run the Section 5 filter loop, THEN Phase 2:
  MAP=$(sbatch  --parsable --array=1-${NSAMP}%8 scripts/06.map_coverage.sl)
  BIN=$(sbatch  --parsable --dependency=afterok:$MAP --array=1-${NSAMP}%6 scripts/07.bin.sl)
  DAS=$(sbatch  --parsable --dependency=afterok:$BIN --array=1-${NSAMP}%6 scripts/08.dastool.sl)

  # → wait for $DAS, run the Section 8 collection loop, THEN Phase 3:
  CM2=$(sbatch  --parsable scripts/09.checkm2.sl)
  DREP=$(sbatch --parsable --dependency=afterok:$CM2 scripts/10.drep.sl)
  GTDB=$(sbatch --parsable --dependency=afterok:$DREP scripts/11.gtdbtk.sl)

  # → wait for $DREP, build mags_derep.txt (Section 12), THEN:
  NMAG=$(wc -l < mags_derep.txt)
  sbatch --dependency=afterok:$GTDB --array=1-${NMAG}%10 scripts/12.bakta.sl
  sbatch scripts/14.coverm.sl
  squeue --me
  ```

### C-06 · S3 · Heavy steps 8, 10, 12, 13, 14 omit the inline runtime the step template requires
- **Where:** SOP_ASSEMBLY_NeSI.md, §§ 8, 10, 12, 13, 14 (headings at lines 417, 528, 629, 672, 738)
- **Anchor:** `## **8. Refine the Bins**`
- **Quote:**
  > ## **8. Refine the Bins**
- **Defect:** `TUTORIAL_SPEC.md` §4 makes the "How long it takes" line non-optional for every action step ("Item 4 costs six words and stops the reader wondering whether the job has hung"). §§4, 5, 6, 7, 9 and 11 each carry a `**How long:**` line; §§8 (DAS_Tool), 10 (dRep), 12 (Bakta), 13 (eggNOG/DRAM) and 14 (CoverM) do not — several are multi-hour.
- **Impact:** A reader waiting on a dRep or CoverM job has no in-step order-of-magnitude and, by the spec's own reasoning, cannot tell a slow job from a hung one; the figures exist in Appendix B but require leaving the step to find them.
- **Type:** LAYOUT
- **Confidence:** CONFIRMED
- **Evidence:** `grep -n 'How long' SOP_ASSEMBLY_NeSI.md` → lines 189, 219, 291, 348, 411, 504, 597 (i.e. §4/5/6/7/9/11 only). Appendix B (lines 943-958) tabulates `08.dastool` 2 h, `10.drep` 6 h, `12.bakta` 2 h, `13a.eggnog` 4 h, `14.coverm` 8 h — the numbers exist but are not in the steps.
- **Fix:** Add a `**How long:**` line to each from Appendix B's figures, e.g. after DAS_Tool's bullets in §8: `**How long:** roughly 1–2 hours per sample.` — and `~6 hours (whole cohort)` (§10), `~1–2 hours per MAG` (§12), `~4 hours per MAG` (§13 eggNOG), `~4–8 hours (whole cohort)` (§14).

### C-07 · S3 · §15 UniFrac note points at gtdbtk/*.classify.tree; tree is under gtdbtk/classify/
- **Where:** SOP_ASSEMBLY_NeSI.md, § 15 "What changes in Part 2" (line 820)
- **Anchor:** `gtdbtk/*.classify.tree`
- **Quote:**
  > **Available, unlike the read-based path.** GTDB-Tk emits a placement tree (`gtdbtk/*.classify.tree`); with it you can compute UniFrac and Faith's PD in R.
- **Defect:** The same nesting error as C-02 — GTDB-Tk 2.7.1 writes its placement tree to `gtdbtk/classify/gtdbtk.bac120.classify.tree`, not the top level — so the path handed to the reader for the optional phylogenetic-diversity extension resolves to nothing.
- **Impact:** A reader who takes up the (correctly flagged) UniFrac/Faith's PD extension looks for `gtdbtk/*.classify.tree`, finds no such file, and — with no checkpoint on this optional path — assumes they broke something.
- **Type:** CONTENT
- **Confidence:** VERIFIED
- **Evidence:** `gtdbtk/config/output.py:42` `PATH_BAC120_TREE_FILE = join(DIR_CLASSIFY, '{prefix}.bac120.classify.tree')`, `DIR_CLASSIFY = 'classify'`; so with `--out_dir gtdbtk` the tree is `gtdbtk/classify/gtdbtk.bac120.classify.tree`.
- **Fix:** Point at the real location — change the path in the sentence to `` `gtdbtk/classify/*.classify.tree` ``.

### C-08 · S3 · DRAM job block lacks the scripts/ filename its Appendix B row and every sibling carry
- **Where:** SOP_ASSEMBLY_NeSI.md, § 13 DRAM (block at lines 716-732) and § Appendix B (line 957)
- **Anchor:** `13b.dram`
- **Quote:**
  > | `13b.dram` | 200 GB | 20 | 24 h | Optional; validate on 1–2 MAGs first |
- **Defect:** Every other job block in the SOP is introduced with a backtick `scripts/NN.name.sl` path the reader saves it under (e.g. `scripts/13a.eggnog.sl`), and Appendix B lists `13b.dram` as if such a file exists — but the §13 DRAM code block is printed with no `scripts/…` label, so there is no `13b.dram` definition anywhere in the body.
- **Impact:** A reader building from the resource table looks for the `13b.dram` script it lists, finds no heading to save it under, and cannot tell which body block is that script — a small navigation break that reads as an unfinished section.
- **Type:** LAYOUT
- **Confidence:** CONFIRMED
- **Evidence:** Agent 0 facts, "Two script-naming defects" #2; heading map shows the §13 DRAM block (716-732) with no `scripts/` intro line, while `13b.dram` appears only in the Appendix B table (`grep -cF '13b.dram'` → 1, at line 957).
- **Fix:** Introduce the block like its siblings — insert immediately before line 716: `` `scripts/13b.dram.sl` (single job): ``

### C-09 · S4 · Subsection headings use sentence case against the suite's title-case rule
- **Where:** SOP_ASSEMBLY_NeSI.md, § 1 and throughout (e.g. lines 46, 52, 63, 293)
- **Anchor:** `### **From reads to a MAG**`
- **Quote:**
  > ### **From reads to a MAG**
- **Defect:** `TUTORIAL_SPEC.md` §8 sets `### **Title**` as "Bold, title case"; most of this document's `###` subsections are bold but sentence case ("From reads to a MAG", "Why binning uses two signals", "Filter short contigs before binning"). The blessed exception (EMU §2's question-form heads) does not apply — these are not questions.
- **Impact:** Cosmetic — a reader scanning the suite meets a heading style that shifts between documents; no functional consequence.
- **Type:** COHERENCE
- **Confidence:** CONFIRMED
- **Evidence:** Spec §8 "Headings … Bold, title case"; ASSEMBLY subsection heads at 46/52/63/293 are sentence case.
- **Fix:** Title-case the `###` subsection heads (e.g. "From Reads to a MAG", "Why Binning Uses Two Signals", "Filter Short Contigs Before Binning"), leaving tool/flag tokens (`metaSPAdes`, `eggNOG-mapper`) in their own casing. Raw material for Agent B's house-style pass.

### C-10 · S4 · Cluster/tool jargon (k-mer, hugemem, nn_seff, diamond) used before introduction
- **Where:** SOP_ASSEMBLY_NeSI.md, §§ 1/4/8/13/App B (first uses at lines 65, 141, 454, 734)
- **Anchor:** `k-mer frequencies, which are genome-characteristic`
- **Quote:**
  > A binner groups contigs by **sequence composition** (k-mer frequencies, which are genome-characteristic)
- **Defect:** For the suite's terminal-novice reader (and given C-03), several terms appear with no first-use gloss: **k-mer** (line 65), **hugemem** (line 141, a NeSI partition), **nn_seff** (lines 734, 941), **diamond** (lines 454, 708). `TUTORIAL_SPEC.md` R2 requires the definition at first appearance.
- **Impact:** Minor — a beginner meets `nn_seff` or `hugemem` with no idea what to run or request; each is a short lookup, not a wall, but they accumulate on a reader the suite says has never opened a terminal.
- **Type:** CONTENT
- **Confidence:** CONFIRMED
- **Evidence:** First uses at 65 (k-mer), 141 (hugemem), 454 (diamond), 734 (nn_seff); none carries a gloss.
- **Fix:** One-clause glosses at first use — "k-mers (short sub-sequences of fixed length)"; "`hugemem` (NeSI's large-memory partition)"; "`nn_seff <jobid>` (NeSI's job-efficiency report — peak memory and CPU used)"; "diamond (a fast protein aligner)".

## Verified against the suite

Probes run this round (2026-08-04, `login03`, plain `module purge`, unpiped `module load`):

| Probe | Command / method | Result | Bears on |
| --- | --- | --- | --- |
| GTDB-Tk summary output path | read installed source `gtdbtk/config/output.py`, `files/classify_summary.py`; `python3 -c "…PATH_BAC120_SUMMARY_OUT.format(prefix='gtdbtk')"` | `classify/gtdbtk.bac120.summary.tsv` (under `classify/`) | **C-02, C-07 (VERIFIED)** |
| §7 CONCOCT + SAMtools combined load (different toolchains) | `module purge; module load CONCOCT/1.1.0-gimkl-2020a-Python-3.8.2 SAMtools/1.23.1-GCC-12.3.0` | rc=0; both `concoct` and `samtools 1.23.1` resolve — no conflict | §7 CLEAN |
| §6 minimap2 + SAMtools + MetaBAT load | staged load | rc=0; MetaBAT silently reloads SAMtools 1.23.1→1.19, but the `samtools sort`/`index` calls run *before* the MetaBAT load, so no functional impact — not filed | §6 CLEAN |
| §8 DAS_Tool helper path | `module load DAS_Tool/1.1.5…`; `ls "$(dirname "$(command -v DAS_Tool)")/src/Fasta_to_Contig2Bin.sh"` | file EXISTS, executable; not on `PATH` (as the doc says) — the `src/` resolution is correct | §8 CLEAN (strength) |
| Input contract from READBASED | `grep` READBASED for `clean/` output naming + `samples.txt` | READBASED normalises to `clean/${SAMPLE}_R1.fastq.gz` / `_R2` (lines 446-447, 508) and builds `samples.txt` (line 152) — exactly what §3.1 expects | §3 CLEAN |
| ASSEMBLY:13 → READBASED "Section 8" | `grep '^## ' SOP_READBASED_NeSI.md` | §8 = "Read Accounting and Depth Gates" — the depth-gate pointer resolves | Before-you-start CLEAN |
| `/opt/nesi/db` databases | `ls` each path | `/opt/nesi/db/bakta/v5.1/db/bakta.db`, `/opt/nesi/db/eggnog_db/data/eggnog.db`, `/opt/nesi/db/DRAM_1.3.5` all PRESENT | §12/§13 DB claims hold |
| CheckM2 / GTDB-Tk env vars | `module load …; echo $CHECKM2DB / $GTDBTK_DATA_PATH` | `CHECKM2DB` auto-set; `GTDBTK_DATA_PATH=/opt/nesi/db/GTDBTk/R232/` (matches "GTDB R232") | §9/§11 CLEAN |
| 17 assembly modules | re-loaded DAS_Tool, CONCOCT, SAMtools, minimap2, MetaBAT, GTDB-Tk, CheckM2 (rc=0 each) | consistent with Agent 0's 17/17 HOLDS | Appendix B CLEAN |
| Finding-anchor uniqueness | `grep -cF <anchor> SOP_ASSEMBLY_NeSI.md` ×10 | all = 1 | contract |

**Correctness sanity-sweep (in scope, findings above or CLEAN):** empty-`$SAMPLE` guard present on every array script (CLEAN); `rm -rf "assemblies/${SAMPLE}"` and `rm -rf coassembly/all` are guarded by the `[[ -n "$SAMPLE" ]]` check and relative to `--chdir` (not destructive); CheckM2 MIMAG `awk '$2>=50 && $3<10'` matches CheckM2's `Name/Completeness/Contamination` column order (CLEAN); dRep `genomeInfo.csv` reconstructs `${Name}.fa` to match `-g mags/*.fa` basenames (CLEAN); MaxBin `cut -f1,3` of the jgi depth is the correct contig/mean-depth pair (CLEAN); GTDB `d/p/c/o/f/g/s` → seven ranks parse is correct (CLEAN); CoverM `-x fa` and the §15 column-tidy reshape are internally consistent (CLEAN); CheckM2 `--force` / MEGAHIT `rm -rf` give clean re-run guards (CLEAN).

## Regressions — prior fixes that did not land

**N/A.** No prior round reviewed `SOP_ASSEMBLY_NeSI.md`, so there is no earlier
finding to have regressed. (C-03 is not a regression — it is the *same class* of
defect the structure round fixed in READBASED, now appearing in the un-reviewed
document, which the brief scopes to me.)

## Keep list

Load-bearing passages a rewrite (Stage 4) must not lose. Each `grep -F`s in this file.

1. Depth-budget floor / scope — `≥5 Gb of clean sequence per sample`
2. Governance, host-in-contigs — `Treat a MAG carrying human contigs as controlled data`
3. metaQUAST silent-download warning — `Zero turns off reference downloading`
4. MEGAHIT memory headroom "why" — `caps MEGAHIT at 90% of the memory it detects`
5. GTDB-Tk OOM guard — `The unsplit bacterial tree needs more than 320 GB`
6. dRep silent-disagreement guard — ``Providing `--genomeInfo` is what stops dRep running CheckM itself``
7. CheckM2 expected-output caveat — `CheckM2 does not check rRNA/tRNA genes`
8. CoverM presence threshold "why" — `suppresses spurious low-level cross-mapping`
9. Compositional handoff guard — `never round it or pass it through SRS`

## Divergence from the set

Raw material for Agent B (set-level coherence):

- **Version scheme.** v0.1 while siblings are v2.0–v3.0; no suite-level version (the calibration C-00 territory). See C-01. This is the sharpest divergence and the ship-gate.
- **Figure strategy.** ASSEMBLY has **zero figures**, while R_Analysis embeds 14 PNGs and EMU embeds (broken) QC images. The document has obviously plottable output — QUAST N50/length, a CheckM2 completeness-vs-contamination scatter with MIMAG tier lines, per-sample coverage. Not filed as a blocker (the suite's figure strategy is itself inconsistent, and figures are an enhancement, not a broken promise), but a candidate for the set-level figure decision.
- **Heading case.** Sentence-case `###` subheads vs the spec's title-case rule (C-09).
- **Script naming.** Every reader-created block carries `scripts/NN.name.sl` except DRAM's (C-08).
- **Navigation.** No table of contents in a 985-line, 16-section document — but this is *consistent* with the suite (R_Analysis is 1411 lines with no TOC; the template has none), so it is a set-wide question, not an ASSEMBLY defect. The "Quick Roadmap: What You'll Do" heading and STAGE-grouping match READBASED's exactly.
- **Runtime discipline.** Inline `**How long:**` present on 6 of 11 heavy steps (C-06); the reviewed siblings carry it more consistently.

## Release recommendation

**NOT READY. This document needs a full run of `SOP_REVIEW_PROMPT.md` AND
`SOP_TUTORIAL_PROMPT.md` before it ships — a capstone pass is not a substitute.**

Reasons, concretely:

1. **It has had neither round.** Its v2–v3 siblings each had a correctness round and a structure/voice round; this one had none, and the README already routes new students into it (C-01).
2. **The correctness round is exactly what catches C-02.** The empty-taxonomy handoff is invisible from the text — it took reading the GTDB-Tk source to see that `--out_dir/classify/` nesting defeats the glob. C-07 is the same bug in the tree path. That class (a tool nests its real output one directory deeper than the SOP's parser assumes) is precisely what a fixture-run correctness pass surfaces, and I could only reach two instances by source-reading; **items I could not close without a real cohort run remain open** and a dedicated round should:
   - confirm DAS_Tool `--write_bins` writes `.fa` so the §8 `cp "$d"/*.fa` collector is non-empty;
   - confirm CoverM's genome-mode column headers so the §15 `split(" ")[0]` reshape yields clean sample IDs;
   - run GTDB-Tk, Bakta and CoverM end-to-end on ≥2 real MAGs (the doc's own closing paragraph admits "a full cohort run on real data was not timed here").
3. **The tutorial round owns C-03 and C-10** — the audience-contract reinstatement and the un-glossed jargon are structural, not sentence-level, and are what `SOP_TUTORIAL_PROMPT.md`'s heading census and R2 scan are for.
4. **C-04 and C-05** (broken alternative forks; unrunnable submission appendix) are the kind of thing a second reader catches by trying to follow a non-default path — again a dedicated-round job.

The document is close and worth finishing — its teaching layer and its "why this
number" content are already at suite standard. But shipping it now would put an
unreviewed member, with at least one silent-wrong-output bug, in front of the
exact reader who cannot tell it from a right one.

## Self-check

```
findings=10 S1=2 S2=3 S4=2
CLEAN
```

CONTRACT: PASS
