# 00 · Synthesis — Stage 2 (seams + cross-document re-ranking)

**Round 2, on-cluster.** Written after the four Stage 1 per-document reports and
the Stage 0 environment probe. Sources re-read in full by this agent; every
cross-document reference, URL and handoff below was checked on NeSI Mahuika
(`login03`, 2026-07-31) or against upstream source. Scratch under
a scratch directory, removed.

Line counts confirmed: EMU 955, CONCOMPRA 684, READBASED 858, R_Analysis 1185,
README 123.

---

## State of the repository

The technical core of all four SOPs is sound and, this round, **provably** so:
every pinned module and CLI flag exists at the version written (Stage 0), every
cross-document URL resolves (15/15 HTTP 200), and all three upstream→R handoffs
land on Part 2's exact input contract when run on a fixture. The load-bearing
"why" content — governance/re-identification, depth-budget arithmetic (the prior
round's inverted-multiply S1 is fixed and correct), the two-pass BBDuk rationale,
the `ps_raw`/`ps_srs` discipline, the relative-abundance guard, the
gate-before-bracket figure logic — is present and correct across the set.

What is weak is **operational safety at four specific points**, one per document,
each of which yields a wrong or empty result with no error:

1. **Part 2 (every reader reaches it)** reports **unadjusted** pairwise-PERMANOVA
   p-values as BH-corrected (`pairwise.adonis2` swallows `p.adjust.m`).
2. **CONCOMPRA** misunderstands its own two config files: `directory_list.txt`
   is a *sourced config file*, not a path list, and `primer_set.fa` headers must
   be named `head`/`tail`, not `27F`/`1492R`. Either mistake gives a faithful
   reader **empty output**, which the document's own troubleshooting then
   misdirects.
3. **Read-based** corrupts `merged_species.tsv` (grabs the `#mpa_` comment as the
   header, keeps a `.profile` sample-ID suffix) — the compositional table that
   feeds beta diversity and decontam.

None of these is irreversible (all are analysis-stage and re-runnable; the
genuinely irreversible content — ethics, controls, depth budget in READBASED §1 —
is correct this round). Do the four blocking fixes first; they are small,
independent across files, and every one is paste-ready in the source reports.

The seams *between* documents are in good shape. The one systemic cross-document
defect is that the **README mandates a canonical SLURM header "in Part 1 Section 1"
that Part 1 does not actually implement, and the four documents each use a
different header** — the umbrella under which EMU's concrete log-path blocker sits.

**Environment reconciliation, in one line:** Stage 0 marked **nothing** false, so
**zero** findings were struck and **zero** fixes rewritten on that basis; instead
Stage 0 *settled* three of the four S1s and pre-empted several would-be findings.

**Proposed cuts struck against the load-bearing list: 0.** No Stage 1 report
proposes cutting load-bearing content.

---

## Blocking defects

Every S1 across all five files, globally re-ranked (severity was assigned within
each document; here it is ranked across the set). Full finding blocks live in the
per-document reports under the IDs given.

Ranking rule applied: an S1 in Part 2 — which **every** reader reaches regardless
of platform — outranks an S1 in an optional branch; a **wrong-but-plausible**
result outranks a **detectably-empty** one; no defect here is irreversible, so
none is lifted above the rest on that ground.

| Rank | Finding | File | Anchor | One-line failure |
| --- | --- | --- | --- | --- |
| 1 | **R_ANALYSIS F-01** (S1) | SOP_R_Analysis.md:842-852 | `p.adjust.m = "BH"` applies Benjamini-Hochberg correction. | `pairwise.adonis2()` has no `p.adjust.m` arg; it is silently discarded and **no** correction is applied. Reader reports raw pairwise p-values as BH-corrected in the thesis — wrong-but-plausible, reached by every reader on every platform. Settled by Stage 0 Q7. |
| 2 | **READBASED F-01** (S1) | SOP_READBASED_NeSI.md:573-574 | `head -1 tables/merged_taxonomy_allranks.tsv > tables/merged_species.tsv` | `head -1` captures the `#mpa_…` version comment, not the `clade_name` header, and keeps a `.profile` sample-ID suffix. The §13 reshape then crashes; a naive fix leaves the relab table's IDs mis-aligned against the counts table → silent wrong-but-plausible compositional output. Settled by Stage 0 Q14. |
| 3 | **CONCOMPRA F-01** (S1) | SOP_CONCOMPRA_NeSI.md:221-229 | `ls *.fastq \| xargs -I{} realpath {} > directory_list.txt` | `directory_list.txt` is `source`d as a shell config (sets `MIN`/`MAX`/`TEMPLATE_DIR`/`PRIMER_SET`/`THREADS`), not a path list; input comes from a `*.fastq` glob. Built as paths → every variable unset → unset `MIN`/`MAX` discard **every** read → empty `otu_table.csv`, no error. Confirmed against upstream `main.sh:1,7`. |
| 4 | **CONCOMPRA F-02** (S1) | SOP_CONCOMPRA_NeSI.md:231-242 | `>1492R` | `primer-chop` decides the 5′ end from the primer **name** (`head`/`tail`); headers `>27F`/`>1492R` match neither, so no read is classified "good" → empty downstream funnel, no error. Confirmed against upstream `primer-chop-analyze:85,90` and the shipped `primer_set.fa` (`>head`/`>tail`). |

All four are **CONFIRMED/VERIFIED** and independent across files (ranks 1-4 touch
four different documents), so they can be fixed in parallel. Ranks 3 and 4 are
within one document and share the "empty output, misdirected troubleshooting"
class with CONCOMPRA F-03 and F-08.

---

## Seam findings

My own, in contract format. `**Where:**` names both files for cross-document
defects. These are defects that live *between* files and that no single-file
reviewer could own; each was flagged as a "check against the other file" by one or
more Stage 1 reports and is resolved here.

### F-01 · S3 · README mandates a canonical SLURM header Part 1 lacks; four docs use four headers
- **Where:** README.md:55 vs SOP_EMU_NeSI.md:145-153,664; SOP_CONCOMPRA_NeSI.md:282; SOP_READBASED_NeSI.md:200-218
- **Anchor:** `Arrays are 1-based and their real range is set at submission`
- **Quote:**
  > **One SLURM job header, in Part 1 Section 1.** … `#!/bin/bash` plus `set -euo pipefail`, `#SBATCH --chdir <absolute workspace path>`, log paths relative to it … Arrays are 1-based and their real range is set at submission (`sbatch --array=1-N%20`), never in the header.
- **Defect:** The README describes a single canonical header living "in Part 1
  Section 1." Part 1 does not contain it, and the four documents implement four
  different headers. Part 1 uses `#!/bin/bash -e` (not `set -euo pipefail`), an
  in-body `cd` (not `--chdir`), and **0-based** arrays hard-coded in the header
  (`--array=0-23`). CONCOMPRA's main-run wrapper uses `#!/bin/bash -e` + hardcoded
  `cd`; its post-process script uses `set -euo pipefail`. READBASED is closest
  (`#!/bin/bash` + `set -euo pipefail` + `cd "${SLURM_SUBMIT_DIR:?}"` + 1-based
  arrays set at submission) but still has no `--chdir`. The convention exists only
  in the README.
- **Failure:** A reader who learns the header in Part 1 meets a different one in
  every later document and cannot tell which is authoritative; concretely, Part
  1's relative log paths with no `--chdir` mean a job submitted from `~` fails at
  launch with an opaque "unable to open file" (the S2 instance already filed as
  EMU F-01), and the 0-based array a Part-1 reader internalises is off-by-one
  against READBASED's 1-based `sed -n "${SLURM_ARRAY_TASK_ID}p"`.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED
- **Evidence:** Internal contradiction across files: README:55 (`--chdir`,
  `set -euo pipefail`, 1-based, range at submission) vs EMU:146 (`#!/bin/bash -e`),
  EMU:343 (in-body `cd`), EMU:664 (`--array=0-23`, 0-based, range in header) vs
  READBASED:207-214 (1-based, `--array=1-1` placeholder overridden at submission).
  Stage 0 Q1 confirms the mechanism: `sbatch` resolves a relative `-o`/`-e` path
  against `--chdir` (absent it, the submit dir), never the in-body `cd`.
- **Fix:** Adopt one header as canonical and place it in Part 1 §1 exactly as the
  README §55 describes, then conform the other three. Concretely: (a) Part 1 gains
  `#SBATCH --chdir /nesi/nobackup/<your_nesi_project_code>/<your_project>` on every
  header, drops the in-body `cd`, switches to `#!/bin/bash` + `set -euo pipefail`,
  and moves the array range to submission time (`sbatch --array=1-N%20`) with
  1-based indexing and `sed -n "${SLURM_ARRAY_TASK_ID}p"`; (b) CONCOMPRA's main-run
  wrapper matches; (c) READBASED either adds `--chdir` or the README explicitly
  blesses the `SLURM_SUBMIT_DIR` + "submit from `$WORK`" variant as equivalent.
  This closes EMU F-01, EMU F-06 (array `=`/base), CONCOMPRA F-10, and the
  array-base half of EMU's cross-doc flag.

### F-02 · S3 · Part 2 hardcodes Emu Option-B filename; Option A offered co-equal but won't load
- **Where:** SOP_R_Analysis.md:126-130 vs SOP_EMU_NeSI.md:750-784 (Option A) and 786-943 (Option B)
- **Anchor:** `emu-combined-counts_silva.tsv`
- **Quote:**
  > emu_combined <- read.table("emu-combined-counts_silva.tsv", … sep = "\t")
- **Defect:** Part 2's loader opens a file named `emu-combined-counts_silva.tsv` —
  the **Option B** (custom-script) artefact, with its fixed 8-column
  `tax_id species…superkingdom` layout. Part 1 presents Option A
  (`emu combine-outputs`) and Option B as co-equal choices, but Option A writes
  `emu-combined-<rank>.tsv` / `emu-combined-<rank>-counts.tsv` with a different
  name *and* a different column layout (ranks-above-in-columns). A reader who picks
  Option A has no file Part 2 can open by that name.
- **Failure:** Reader follows Option A (equal visual weight, listed first), reaches
  Part 2, runs the loader, and hits `cannot open file 'emu-combined-counts_silva.tsv'`
  with no pointer back to which combine option Part 2 assumes.
- **Type:** CONSISTENCY
- **Confidence:** VERIFIED
- **Evidence:** The EMU reviewer ran both under `Emu/3.6.2`: Option A →
  `emu-combined-species.tsv` / `emu-combined-species-counts.tsv`; Option B →
  `emu-combined-counts_silva.tsv` (8-column `tax_id species genus family order
  class phylum superkingdom` + samples). Part 2's loader (R_Analysis:128) names only
  the Option B file. Part 2's split-by-name loader accepts the Option B shape (I ran
  the equivalent MetaPhlAn/CONCOMPRA reshapes into the same shape and Part 2's
  column-name split produced `taxcols=7` cleanly).
- **Fix:** Make Option B (`combine_emu_results.py`) the canonical handoff artefact
  the SOP set standardises on: in Part 1 demote Option A to a short "Emu also ships
  a built-in `combine-outputs`; we use the custom script because it produces one
  fixed layout Part 2 reads directly" note, and keep the closing verify block
  option-independent (`ls emu_results/*/emu-combined-*.tsv`). Part 2 then always
  opens `emu-combined-counts_silva.tsv`. Closes EMU F-05 and settles the "two
  formats to Part 2" cross-doc flag.

### F-03 · S4 · README index and prose do not match the SOPs in three small ways
- **Where:** README.md:20,77 vs SOP_CONCOMPRA_NeSI.md:149-176 and SOP_R_Analysis.md:1-9; and SOP_CONCOMPRA_NeSI.md:562 vs SOP_READBASED_NeSI.md:665
- **Anchor:** `post-processing uses`
- **Quote:**
  > **Consensus OTUs (CONCOMPRA):** the pipeline itself runs from a conda environment built via `Miniforge3/25.3.1-0`; post-processing uses `VSEARCH/2.21.1-GCC-11.3.0`, `MAFFT/7.505-gimkl-2022a-with-extensions`, `FastTree/2.1.11-GCC-11.3.0` and `seqtk/1.4-GCC-11.3.0`.
- **Defect:** Three small README/cross-doc fidelity drifts, none result-changing:
  (a) the CONCOMPRA tool-versions row omits **`seqkit`**, which the dedup step
  (§3.2) requires and which is a distinct module (`SeqKit/…`) from the `seqtk`
  listed; (b) README:20 says "The other three assume it. All three say so at the
  top and point back to Part 1 Section 1," but only CONCOMPRA and READBASED point
  back — Part 2 (the third) runs locally and legitimately does not; (c) CONCOMPRA:562
  tells the reader to "keep `tree_concompra.rds` for any phylogenetic diversity
  work," implying Part 2 does it, while READBASED:665 and Part 2 both state Part 2
  covers no phylogenetic diversity at all — and READBASED:665's reasoning ("Emu
  output carries no tree and MetaPhlAn's does") overlooks that CONCOMPRA output
  carries a tree too.
- **Failure:** A reader planning installs from the README misses `seqkit` and hits
  `command not found` at dedup (already surfaced in-doc by CONCOMPRA F-04); a reader
  takes README:20 literally and looks for a Part-1 pointer in Part 2; a reader keeps
  a CONCOMPRA tree expecting a Part-2 step that does not exist.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED
- **Evidence:** README:77 lists `seqtk` but no `seqkit`; CONCOMPRA:170 calls
  `seqkit rmdup` and `module spider seqkit` → `SeqKit/…` (a real, separate module,
  per CONCOMPRA F-04). README:20 "All three … point back to Part 1 Section 1" vs
  R_Analysis:5 ("runs locally in R, not on NeSI", no Part-1 pointer). CONCOMPRA:562
  vs READBASED:665.
- **Fix:** Add `seqkit` to the README CONCOMPRA tool row; reword README:20 to "The
  two cluster documents downstream of Part 1 point back to Part 1 Section 1" (Part 2
  is local); and either drop "for any phylogenetic diversity work" from CONCOMPRA:562
  or add a one-line Part-2 note that CONCOMPRA/MetaPhlAn trees enable optional
  UniFrac/Faith's PD not otherwise covered.

---

## Reference integrity table

Every cross-document pointer and every URL. Sections verified to exist under the
named file's own numbering. URLs checked live (HTTP 200).

| Source | Anchor | Points at | Exists? | Correct? | Action |
| --- | --- | --- | --- | --- | --- |
| README:13-16 | table rows | `SOP_EMU_NeSI.md`, `SOP_R_Analysis.md`, `SOP_CONCOMPRA_NeSI.md`, `SOP_READBASED_NeSI.md` | Yes (all 4) | Yes | none |
| README:18,29 | `read-based … Section 13` | READBASED §13 "Statistics: What Changes" | Yes | Yes | none |
| README:37 | `Both are Section 1 of the read-based SOP` | READBASED §1 "Before You Generate Data" | Yes | Yes | none |
| README:55 | `One SLURM job header, in Part 1 Section 1` | EMU §1 | Yes (§1) | **No** — header there does not match the spec | **F-01** |
| README:117 | `read-based SOP's Section 14` | READBASED §14 "Provenance" | Yes | Yes | none |
| README:123 | `reviews/v1/…`, `prompts/SOP_REVIEW_PROMPT.md` | those paths | Yes | Yes | none |
| EMU:7,28 | `SOP_R_Analysis.md` | Part 2 | Yes | Yes | none |
| CONCOMPRA:15 | `Section 1 of SOP_EMU_NeSI.md` | EMU §1 | Yes | Yes | none |
| CONCOMPRA:7,42,531 | `SOP_R_Analysis.md` | Part 2 | Yes | Yes | none |
| CONCOMPRA:562 | `emu-combined-counts_silva.tsv` (Part 2's name) | Part 2 loader | Yes | Yes (Option B) | F-02 (ownership) |
| READBASED:11 | `SOP_EMU_NeSI.md Section 1` | EMU §1 | Yes | Yes | none |
| READBASED:7,37,663 | `SOP_R_Analysis.md … Section 13` | Part 2 §13 (own) | Yes | Yes | none |
| R_Analysis:7,119 | `SOP_READBASED_NeSI.md … Section 13` | READBASED §13 | Yes | Yes | none |
| R_Analysis:118 | `SOP_CONCOMPRA_NeSI.md Section 8` | CONCOMPRA §8 "Preparing for R" | Yes | Yes | none |
| R_Analysis:7,126 | `SOP_EMU_NeSI.md` / Emu combined table | EMU §4 | Yes | Yes (Option B) | F-02 |
| EMU:190-193 | 4× Genomics Aotearoa deep links | summer-school pages | Yes | **200** | none |
| EMU:551 | github.com/treangenlab/emu | Emu repo | Yes | 200 | none |
| EMU:577 | arb-silva.de | SILVA | Yes | 200 | none |
| EMU:391,397,531,537 | github user-attachments images | run figures | n/a | not fetched (image assets) | none |
| CONCOMPRA:80,672 | github.com/willem-stock/CONCOMPRA | repo | Yes | 200 | none |
| CONCOMPRA:674,682,684 | vsearch repo, POD5 spec, docs.nesi.org.nz | — | Yes | 200 | none |
| READBASED:9 | genomicsaotearoa summer school | — | Yes | 200 | none |
| READBASED:181 | s3 …/chm13v2.0.fa.gz | download | Yes | 200 | none |
| READBASED:115 | pypi.org | internet check | Yes | 200 | none |
| README:3,110-113 | primary-literature citations | (bibliographic, not URLs) | — | consistent with SOP citations | none |

No dangling cross-document reference. One internal anchor breaks *after* a fix:
CONCOMPRA F-08's `#sample-list` link dangles once F-01 renames that heading —
sequence F-01 before F-08 (already in the CONCOMPRA rewrite plan).

---

## Consistency matrix

`Target` is the decision, not a description of the variance.

| Item | EMU | CONCOMPRA | READBASED | R_Analysis | README | Target |
| --- | --- | --- | --- | --- | --- | --- |
| SLURM shebang/`set` | `#!/bin/bash -e` | `-e` (main), `set -euo` (post) | `#!/bin/bash`+`set -euo` | n/a (local) | `#!/bin/bash`+`set -euo` | `#!/bin/bash`+`set -euo pipefail` everywhere (**F-01**) |
| Working dir in jobs | in-body `cd` | hardcoded `cd` | `cd $SLURM_SUBMIT_DIR`+submit-from-`$WORK` | n/a | `--chdir <abs path>` | `--chdir` canonical; SUBMIT_DIR variant blessed if kept (**F-01**) |
| Array base | 0-based, range in header | n/a (not array) | 1-based, range at submission | n/a | 1-based, range at submission | 1-based, range at submission (**F-01**) |
| `<your_email>` placeholder | `<your_email>@auckland.ac.nz` | n/a | n/a | n/a | whole address, domain included | whole address (EMU F-02) |
| `$DB`/`$WORK` in batch scripts | n/a | n/a | Option B uses `$DB` **unset** in batch | n/a | never in a SLURM script | define inline in-script (READBASED F-02) |
| Combined-count filename to Part 2 | Option A `emu-combined-<rank>*` / Option B `emu-combined-counts_silva.tsv` | writes `counts_concompra.tsv` (sub for the Emu name) | writes `part2_counts.tsv` | reads `emu-combined-counts_silva.tsv` | "upstream owns the conversion" | standardise on Option B artefact (**F-02**) |
| Rank vocabulary | superkingdom…species | maps `d/p/c…`→ same | maps `k__/p__…`→ same | expects superkingdom…species | superkingdom…species lowercase | already consistent — keep |
| Rank column order | species-first (loads by name) | superkingdom-first | superkingdom-first | split by **name** (order-agnostic) | "rank columns before sample columns" | consistent (name-split); no action |
| Sample-ID suffix strip | strips `_filtered` | strips `.CONCOMPRA`+`_filtered` | strips `.profile` (broken in relab path) | positional; documents `gsub` cleanup | one ID, suffixes stripped where created | fix READBASED relab strip (READBASED F-01) |
| Counts integer vs float | fractional; rounded in Part 2 | integer already | float; rounded in Part 2 | `round()` on read-in + relab guard | "integer counts … upstream owns conversion" | Part 2 rounds floats; wording nuance (Deferred) |
| nobackup purge window | "rolling basis" | (n/a) | "90 days, flagged day 76" | n/a | "90 days" | harmonise wording to "90 days" (S4, Deferred) |
| Script filename ↔ section № | matches | `05b`/`06` for §3/§5 (off) | matches | matches | "carries the section number" | renumber CONCOMPRA scripts (CONCOMPRA F-09) |

---

## Ownership map

For each topic appearing in more than one document: who owns it, who links.

| Topic | Owner | Others | What each must change |
| --- | --- | --- | --- |
| Cluster basics (bash, modules, SLURM, arrays) | **EMU §1** | CONCOMPRA, READBASED link to EMU §1 | Keep; both already point back (README:20 wording fix, F-03) |
| Canonical SLURM header | **EMU §1** (per README) | CONCOMPRA, READBASED | Make EMU §1 actually hold it; others conform (**F-01**) |
| Storage / filesystems | **EMU §1** (three filesystems in full) | READBASED gives a 2-row recap; README summarises | Keep local recaps (reader unlikely to have EMU open); ensure figures agree (they do) |
| Combined count-table format + `combine_emu_results.py` | **EMU §4** | Part 2 reads it; CONCOMPRA/READBASED emit the same shape | Standardise on Option B as the artefact Part 2 names (**F-02**) |
| Part 2 input contract (integer counts, named ranks, `SampleType`) | **R_Analysis / README:56-59** | EMU, CONCOMPRA §8, READBASED §13 each convert to it | Keep the per-upstream reshape blocks; they are the owned conversions |
| Reshape to Part 2 shape | **each upstream doc** (EMU native, CONCOMPRA §8, READBASED §13) | Part 2 documents which upstream owns which | Keep; verified all three land on the contract |
| decontam (prevalence method) | **R_Analysis Stage 2** | READBASED §12 links to it | READBASED §12 must name `part2_relab.tsv`, not `merged_species.tsv` (READBASED F-06) |
| Functional tables (gene families, pathways) | **READBASED §11/§13** (Part 2 does not cover) | — | Keep; correctly owned and stated |
| Phylogenetic diversity / trees | **nobody** (Part 2 covers none) | CONCOMPRA and MetaPhlAn both emit a tree | Decide: add a short Part-2 note or state clearly it is out of scope (F-03 / Open questions) |
| SINTAX column-4 rule | **CONCOMPRA §7/§8** | (self-contained) | Keep; verified correct |
| Sample-ID discipline | **README:57** | all four honour it | READBASED relab path is the one break (F-01) |

Local repetition of storage and "point back to Part 1" is **justified** — the
reader of a downstream SOP is unlikely to have Part 1 open — provided the numbers
agree, which they do.

---

## Environment reconciliation

Stage 0 (`reviews/00_ENVIRONMENT.md`) probed the actual cluster and R install.

**What Stage 0 falsified: nothing.** "Every pinned software module in every SOP
exists at exactly the version written, and every command-line tool and flag on the
main path is real." Consequently:

- **Findings struck because their confidence rested on a Stage-0 `FALSE` claim: 0.**
- **Fixes rewritten because they assumed a module string or flag Stage 0 could not
  find: 0.** (Every module string in every fix — `Emu/3.6.2`, `MetaPhlAn/4.1.0-…`,
  `VSEARCH/2.21.1-…`, `SeqKit/…`, `chopper/0.12.0b-…`, `R/4.6.0-foss-2026` — was
  confirmed present.)

**What Stage 0 settled (strengthening, not changing, existing findings):**

| Stage 0 item | Effect on the reports |
| --- | --- |
| **Q7** — `pairwise.adonis2` has no `p.adjust.m`; performs no adjustment | Settles **R_ANALYSIS F-01** (the repo's #1 S1) from upstream source; VERIFIED confidence upheld. |
| **Q14** — MetaPhlAn merged table: line 1 is `#mpa_` comment, header on line 2, `.profile` suffix | Settles **READBASED F-01** (fixture-confirmed here too). |
| **Q16** — MetaPhlAn exits 1 on an existing `--bowtie2out` unless `--force` | Settles **READBASED F-03** (re-run guard). |
| Q2 — `nn_check_quota` ≡ `nn_storage_quota` (symlink) | Pre-empts a false "wrong quota command" finding; both SOP spellings are correct. |
| Q4/Q8/Q9/Q12/Q13/Q15 — `--type lr:hq`, `symnum` n+1 rule, `adonis2 by=NULL` default, FastTree `-boot`, minimap2 pin, pandas present | Each **confirms the SOP text is correct**, pre-empting would-be findings a reviewer might otherwise have filed. |

Stage 0 could not settle (still `NOT-VERIFIABLE-HERE`, needing a large download or a
real run): the `silva.tar` internal structure (EMU Gaps; evidence points to flat
extraction — a cheap DB-path guard closes it either way), the CONCOMPRA
`otu_table.csv` first-column *label* (Q3; the SOP's own consumption is internally
consistent), and `ancombc2` runtime (Q11). None of these blocks a fix.

---

## Work plan

Sequenced so shared conventions land before the per-document rewrites that depend
on them, and so no two items collide in the same lines of the same file. "‖" marks
items that can run in parallel.

| # | Item | Files | Closes | Size | Depends on |
| --- | --- | --- | --- | --- | --- |
| 1 | **Convention: canonical SLURM header + 1-based arrays** — write into README §55's target and Part 1 §1; conform CONCOMPRA main-run wrapper; bless/patch READBASED variant | EMU, CONCOMPRA, READBASED, (README) | Seam F-01, EMU F-01, EMU F-06, CONCOMPRA F-10 | M | — |
| 2 | **Convention: standardise Emu handoff on Option B** — demote Option A to a note, option-independent verify block; Part 2 name unchanged | EMU, (R_Analysis) | Seam F-02, EMU F-05 | S | — |
| 3 ‖ | **R_ANALYSIS F-01** — replace `p.adjust.m` calls + "applies BH" sentence with extract-then-`p.adjust` block | R_Analysis | Rank-1 S1 | S | — |
| 4 ‖ | **READBASED F-01** — header-from-`clade_name` + `.profile` strip in the §11 relab merge | READBASED | Rank-2 S1 | S | — |
| 5 ‖ | **CONCOMPRA F-01** — rewrite §4.3 "Sample list" → "Run configuration file" (config vars, `MIN`/`MAX` gate) | CONCOMPRA | Rank-3 S1 | M | — |
| 6 | **CONCOMPRA F-02** — rewrite §4.4 primer file to `head`/`tail` headers + write step, keep orientation prose | CONCOMPRA | Rank-4 S1 | S | after 5 (same section cluster) |
| 7 | **CONCOMPRA F-03, F-06, F-08** — fix "submitted" count, run `./main.sh`, correct §9 causes + relink | CONCOMPRA | F-03/F-06/F-08 | S | after 5 (F-08 links to renamed §4.3) |
| 8 ‖ | **READBASED F-02** — define `$DB` inline in Option B `07a`/`07b` | READBASED | F-02 | S | — |
| 9 ‖ | **READBASED F-03/F-04/F-05/F-06** — bt2 re-run guard; gate chm13 to Option B; conditional provenance; decontam→`part2_relab.tsv` | READBASED | those | S | 4-way, small; F-05 after F-04 |
| 10 ‖ | **EMU F-02, F-03, F-04** — email placeholder; pooled-report framing; retention numbers | EMU | those | S | — |
| 11 ‖ | **R_ANALYSIS F-02/F-03/F-04/F-05** — reorder `pcoa_ait`; uncomment devtools; "7 variables"; Stage-5 heading | R_Analysis | those | S | independent of 3 (different lines) |
| 12 ‖ | **CONCOMPRA F-04, F-05, F-07, F-09** — seqkit note; Threads wording; OTU×sample label; script renumber | CONCOMPRA | those | S | after 5-7 |
| 13 | **README fidelity** — add `seqkit`; reword "all three point back"; phylo-tree note | README | Seam F-03 | S | after 1, 2 (so conventions are settled) |

Items 1 and 2 are pure convention decisions and unblock the per-doc header/handoff
edits; do them first. Items 3, 4, 8, 10, 11 touch independent files/lines and run
fully in parallel. The CONCOMPRA cluster (5→6→7→12) is internally sequenced because
they share sections and one heading rename.

---

## Convention decisions

Stated once, pasteable into the README:

1. **One SLURM header, and Part 1 §1 is where it lives — for real.** `#!/bin/bash`
   + `set -euo pipefail`; `#SBATCH --chdir <absolute workspace path>` on every job;
   log paths relative to `--chdir`; `mkdir -p logs` before the first submission;
   arrays **1-based**, real range set at submission (`sbatch --array=1-N%20`),
   `sed -n "${SLURM_ARRAY_TASK_ID}p"`. READBASED's `cd "${SLURM_SUBMIT_DIR:?}"` +
   "submit from `$WORK`" is an accepted equivalent *only if the README names it as
   such*; otherwise conform it. (Seam F-01.)

2. **Shell variables never appear in a SLURM script body without being defined in
   that body.** `$DB`, `$WORK`, `$ACCOUNT` are fine interactively; inside a batch
   script, set them on the first lines (as READBASED §9 already does; Option B does
   not — READBASED F-02).

3. **The Emu→Part 2 handoff artefact is `combine_emu_results.py`'s
   `emu-combined-counts_silva.tsv`** (fixed 8-column layout). Emu's built-in
   `combine-outputs` is mentioned as an alternative, not offered as a co-equal path
   Part 2 must guess between. (Seam F-02.)

4. **Every upstream document owns its reshape to the Part 2 contract**
   (`tax_id` + `superkingdom…species` named rank columns + integer-count sample
   columns, tab-separated). Verified this round: EMU native, CONCOMPRA §8, READBASED
   §13 all land on it; the relative-abundance guard correctly stops a relab table
   fed to the counts loader.

5. **README tool-version rows list every tool the SOP runs** — add `seqkit`
   (CONCOMPRA dedup) to the CONCOMPRA row. (Seam F-03.)

---

## Consolidated keep list

Merged across all four reports — the regression test for the rewrite. If a
rewritten SOP loses any of these, the rewrite failed. Grep the anchor.

**EMU**
- `--keep-counts` — **essential, do not omit.** (counts-vs-abundance silent-failure warning)
- `--quality 10` / `--minlength 1200` / `--maxlength 1800` — the three why-this-number threshold paragraphs
- `Do not write ` `0.9` ` expecting 90%` — `--min-pid` percent-scale silent-failure warning
- `raise it or reads are discarded without warning` — `--max-align-len` default-2000 silent-truncation caveat
- ``@`` ` is Q31` — corrects the `grep -c "^@"` plausible-but-wrong read count
- `write the other's into two identically named columns` — duplicate-basename guard rationale
- `has not yet been tested or validated with Emu` — SILVA v138.1 vs 138.2 tool-choice justification
- `the central challenge of 16S classification` — EM/why-not-best-hit concept the audience lacks

**CONCOMPRA**
- `never from the` — roadmap headline silent-failure warning (verify on disk, not the `.out` log)
- `does not stop the script or change its exit code` — §6 no-`set -e` framing
- `silently corrupts taxonomy at low-confidence ranks` — SINTAX column-4-not-2 warning
- `not the reverse-complement` — 1492R sense-strand orientation (carry into F-02 rewrite)
- `the same physical sample is called barcode01_filtered` — `.CONCOMPRA`/`_filtered` suffix reasoning
- `may discard real signal` — `prv_cut = 0.10` caveat for consensus OTUs
- `its version is pinned for compatibility` — filtlong/minimap2 version-lock reasoning

**READBASED**
- `re-identify individuals against matched genotype data at 93.3% sensitivity` — governance/re-identification
- `Divide, do not multiply.` — depth-budget arithmetic (prior round's fixed S1) + the worked table
- `they cannot be combined into one` — two-pass BBDuk `ktrim=r` rationale
- `biases against GC-extreme and low-coverage genomes` — `trimq=10 not 20` why-this-number
- `parameters come from JGI's recipe and assume a masked reference` — masked-reference reasoning
- `depend on when someone last ran the tool with internet access` — `--index`/`--offline` reproducibility
- `a column sums to roughly 8x the classified fraction` — all-ranks 8× misuse warning
- `any cleanup placed after the command would never run` — HUMAnN temp-dir `trap` rationale

**R_Analysis**
- `The one rule to remember` — `ps_raw` vs `ps_srs` object discipline + the which-normalisation table
- `Column sums are 100 or 1` — the relative-abundance guard
- `index them POSITIONALLY` — positional sample-alignment warning + `stopifnot`
- `a stale ps_raw will run without error` — rebuild-`ps_raw`-after-depth-gate note
- `bracket_frame` — gate-before-bracket figure logic (stops figure disagreeing with reported stats)
- `Correcting on the filtered subset` — FDR-before-filtering warning for indicator species
- `roughly 30 or more samples` — `neg_lb`/structural-zero small-sample caution

---

## Deferred

Findings not worth acting on (or already handled), one line each:

- **README "upstream owns the conversion" vs Part 2 rounding Emu/MetaPhlAn floats** —
  no reader harm; Part 2 explicitly rounds floats and the README statement is about
  *shape*, not integer-casting. Wording nuance only.
- **nobackup purge wording ("rolling basis" vs "90 days")** — EMU is vaguer but not
  contradictory; harmonise to "90 days" opportunistically (S4).
- **Rank column order (EMU species-first vs others superkingdom-first)** — Part 2
  splits by column *name*, so order is immaterial; cosmetic only.
- **`silva.tar` flat-vs-subdir extraction (EMU Gaps)** — NOT-VERIFIABLE-HERE without a
  multi-GB download; evidence points to flat; the proposed 2-line DB-path guard is
  correct regardless, so add it but do not block on verifying.
- **`ancombc2` / `Maaslin2` runtime note (R Gaps)** — NOT-VERIFIABLE-HERE (needs real
  data + `ANCOMBC`, not installed); a local `system.time()` settles it.

---

## Open questions for the lab

Decisions that are not the reviewer's to make. Options, a recommendation, then stop.

1. **CONCOMPRA `reformat_silva_for_sintax.py` is described (Appendix A) but never
   provided.** The first person to build the SILVA SINTAX database in a project
   cannot, unless a labmate already placed the script. This blocks a
   documented-as-once-per-project step. *Options:* (a) inline the ~30-line script as
   Section 8 already does for `assemble_R_inputs.py`; (b) commit it to the repo and
   link it; (c) leave it as a lab-internal artefact and say so explicitly.
   **Recommend (a) or (b)** — a self-contained SOP should not depend on an unshared
   script.

2. **CONCOMPRA `prv_cut = 0.10` for consensus OTUs (CHALLENGE, CONCOMPRA §8).** The
   0.10 prevalence filter is tuned for Illumina ASV data; per-sample consensus OTUs
   are often genuine rare taxa, so it may discard real signal. *Options:* keep 0.10
   for consistency with Part 2; or lower it for CONCOMPRA input and document the
   value. **Recommend** lowering and stating what was used; this is a scientific
   tuning call the lab owns.

3. **Emu Option A vs Option B (convention 3 above).** Recommend standardising on
   Option B as the handoff artefact and demoting Option A to a note. Confirm the lab
   is content to lose Option A's co-equal billing.

4. **Should Part 2 gain a short phylogenetic-diversity section?** CONCOMPRA and
   MetaPhlAn both emit a tree; Part 2 currently covers no UniFrac/Faith's PD, and
   READBASED §13 adds UniFrac inline for its own readers. *Options:* leave out of
   scope (status quo) and fix the two prose implications (F-03); or add a brief
   optional Part-2 note. **Recommend** the former unless phylogenetic diversity is a
   common lab need.

---

## Self-check

Seam findings only (Agent B: SOURCE=None; per-document S1s are ranked in
*Blocking defects*, not re-filed as `### F-` blocks):

```
findings=3 S1=0 S2=0 S3=2 S4=1
CLEAN
```

By hand, the three the script cannot check:

- [x] Ledger accounts for every heading in the file — *N/A for Agent B* (no
  single source file); every cross-document reference and URL is instead accounted
  for in the Reference integrity table.
- [x] No proposed cut touches load-bearing content — **0 cuts struck**; no Stage 1
  report proposes cutting load-bearing content, and the one structural suggestion
  carried forward (demote Emu Option A, seam F-02) removes a *duplicated path*, not
  any why-this-number, warning, expected-output, citation, scope, governance or
  concept content. The Consolidated keep list is the regression guard.
- [x] Every `NOT-VERIFIABLE-HERE` is genuinely not verifiable here — this synthesis
  files no NOT-VERIFIABLE-HERE findings; the three carried from Stage 1
  (`silva.tar` structure, CONCOMPRA `otu_table.csv` label, `ancombc2` runtime) are
  in Deferred with the exact check and its cost, each needing a large download or a
  real run the brief bars.

CONTRACT: PASS
