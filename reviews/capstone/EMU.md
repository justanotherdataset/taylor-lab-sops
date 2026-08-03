## Document: SOP_EMU_NeSI.md

**Capstone (product-integrity) review of Part 1.** Read against the COMMON BRIEF,
the two prior rounds (correctness `reviews/00_SYNTHESIS.md` + `reviews/00_ENVIRONMENT.md`;
structure `reviews/structure/00_PLAN.md` + `reviews/structure/00_REALITY.md`), the
per-document EMU reports (`reviews/EMU.review.md`, `reviews/structure/EMU.md`), and
Agent 0's facts (`reviews/capstone/00_FACTS.md`), then the current
`SOP_EMU_NeSI.md` (1,019 lines, v2.0, July 2026) in full. I did **not** open the
other SOPs; every cross-document fact below is either Agent 0's or a probe I ran.

The document itself is in excellent shape as a *teaching* artefact — every
structure-round rewrite (S-01…S-13) and correctness fix (F-01…F-06) landed, the
load-bearing "why this number" and silent-failure content is intact (15/15
keep-list anchors resolve), and every cross-reference resolves. It is **not**
shippable in this state for one product reason that outranks everything else:
**all four of its QC figures are off-repo GitHub links that return 404**, so the
single most instructive part of a QC document renders as four broken-image icons
for anyone who clones the repo. That is the ship-blocker. The rest are coherence
seams the suite carries as a set (a stale document count, five uncoordinated
version numbers) plus minor navigation and naming polish.

## Section ledger

Every markdown heading in the file. (Lines 155, 436, 662, 665, 681–682, 691, 695,
706, 901, 964 that `grep -nE '^#{1,4} '` also returns are `#`-prefixed **bash
comments inside code fences**, not headings, and are excluded.)

| § | Heading | Lines | Treatment | Findings |
| --- | --- | --- | --- | --- |
| — | `# Part 1: NeSI Pipeline (Sequencing to Count Tables)` | 3 | CLEAN | — |
| — | `### Before You Start` | 9-13 | CLEAN | — |
| — | `## Quick Roadmap` | 15-24 | ADD-NAV (add linked TOC) | C-04 |
| 1 | `## 1. Getting Started on NeSI` | 26 | CLEAN | — |
| 1 | `### What Is NeSI and Why We Use It` | 28-32 | CLEAN | — |
| 1 | `### Logging In` | 34-62 | CLEAN | — |
| 1 | `### Basic Bash Commands` | 64-120 | CLEAN | — |
| 1 | `### Using Modules` | 122-134 | CLEAN | — |
| 1 | `### SLURM: Running Jobs on the Cluster` | 136-184 | CLEAN | — |
| 1 | `### A Note on Array Jobs` | 186-190 | CLEAN | — |
| 2 | `## 2. Understanding Your Data` | 192-194 | CLEAN | — |
| 2 | `### What is 16S rRNA and why do we sequence it?` | 196-206 | RELABEL (case; blessed deviation) | Divergence |
| 2 | `### What is an amplicon?` | 208-216 | RELABEL (case; blessed deviation) | Divergence |
| 2 | `### How does Nanopore sequencing work?` | 218-226 | RELABEL (case; blessed deviation) | Divergence |
| 2 | `### What are quality scores?` | 228-237 | RELABEL (case; blessed deviation) | Divergence |
| 2 | `### What does a FASTQ file look like?` | 239-252 | RELABEL (case; blessed deviation) | Divergence |
| 2 | `### What does Nanopore data look like on disk?` | 254-269 | RELABEL (case; blessed deviation) | Divergence |
| 2 | `### Full-Length vs Short-Read: Why It Matters` | 271-283 | CLEAN | — |
| 3 | `## 3. Processing Nanopore Reads` | 285-287 | CLEAN | — |
| 3 | `### Step 1. Organise Your Raw Data` | 289-320 | CLEAN | — |
| 3 | `### Step 2. Quality Assessment of Raw Reads` | 322-407 | FIX-FIGURE | C-01 |
| 3 | `### Step 3. Filtering with Chopper` | 409-473 | CLEAN | — |
| 3 | `### Step 4. Quality Assessment of Filtered Reads` | 475-547 | FIX-FIGURE | C-01 |
| 4 | `## 4. Taxonomy and Community Profiling with Emu` | 549-551 | CLEAN | — |
| 4 | `### What Emu Does and Why We Use It` | 553-573 | CLEAN | — |
| 4 | `### Understanding the Reference Databases` | 575-598 | CLEAN | — |
| 4 | `### Setting Up the Databases` | 600-652 | CLEAN | — |
| 4 | `### Running Emu` | 654-776 | CLEAN | — |
| 4 | `### Combining Emu Outputs` | 778-957 | RELABEL (script-name seam) | C-05 |
| 4 | `#### Alternative: emu combine-outputs` | 959-969 | CLEAN | — |
| — | `## Troubleshooting` | 971-982 | CLEAN | — |
| — | `## Appendices` | 984 | CLEAN | — |
| — | `### A. NeSI Module Versions` | 986-994 | CLEAN | — |
| — | `### B. NanoPlot Plot Reference` | 996-1002 | CLEAN | — |
| — | `### C. Further Reading` | 1004-1013 | CLEAN | — |
| — | `### D. Primary References` | 1015-1019 | CLEAN | — |
| — | (title/version line) | 5 | RELABEL (no suite version) | C-02 |
| — | (intro paragraph) | 7 | FIX-REF (stale document count) | C-03 |

## Findings

### C-01 · S1 · Four QC figures are off-repo GitHub links that 404 — none render for a cloner
- **Where:** SOP_EMU_NeSI.md, § 3 Steps 2 & 4 (lines 399, 405, 537, 543)
- **Anchor:** `3caf1fec-5796-4595-becc-07a36e956379`
- **Quote:**
  > <img width="700" height="500" alt="Read length histogram, raw" src="https://github.com/user-attachments/assets/3caf1fec-5796-4595-becc-07a36e956379" />
- **Defect:** EMU's only four figures — the raw/filtered read-length histograms and length-vs-quality scatters, the visual heart of a QC document — are remote `<img>` tags pointing at `github.com/user-attachments/…`. All four return HTTP 404, and even a 200 would not survive a clone because the assets live outside the repository. The document has **zero** working figures.
- **Impact:** A student clones the repo cold, reaches Step 2 ("Two plots to check first when assessing run quality") and Step 4 (the caption calls the filtered scatter "the single most informative NanoPlot output"), and sees four broken-image icons. To this reader a figure that will not load is indistinguishable from their own mistake; they cannot see the length/quality distributions the step exists to teach, and they cannot calibrate their own NanoPlot output against the expected shape.
- **Type:** CONTENT
- **Confidence:** VERIFIED
- **Evidence:** `curl -sI --max-time 25` on 2026-08-04, all four URLs:
  ```
  https://github.com/user-attachments/assets/3caf1fec-…6e956379  -> HTTP/2 404  (server: github.com)
  https://github.com/user-attachments/assets/62050053-…c73f67ebcf7b -> HTTP/2 404
  https://github.com/user-attachments/assets/0fb8ff83-…9603d44d9   -> HTTP/2 404
  https://github.com/user-attachments/assets/939cc9ba-…8c258f      -> HTTP/2 404
  ```
  `ls examples/` shows `r_analysis/` only — there is **no `examples/emu/` directory**; EMU's figures were never committed. By contrast R_Analysis embeds 14 figures as local `examples/r_analysis/figures/*.png` (all PRESENT per Agent 0). Corroborates Agent 0 FACTS §"Figure and asset existence" (4 BROKEN, off-repo).
- **Fix:** Adopt the R-doc's in-repo strategy. Regenerate the four PNGs from the worked-example run (the raw/filtered NanoStats blocks at lines 377–393 and 517–533 are already the matching worked example), commit them under `examples/emu/figures/`, and replace the four remote `<img>` tags with local markdown references:
  - line 399 → `![Read length histogram, raw reads](examples/emu/figures/raw_read_length_histogram.png)`
  - line 405 → `![Read length vs mean quality, raw reads](examples/emu/figures/raw_length_vs_quality.png)`
  - line 537 → `![Read length histogram, filtered reads](examples/emu/figures/filtered_read_length_histogram.png)`
  - line 543 → `![Read length vs mean quality, filtered reads](examples/emu/figures/filtered_length_vs_quality.png)`
  This is a hard ship-gate: it requires the actual image files, which currently do not exist anywhere in the repo and 404 upstream, so someone must produce them before Part 1 can ship.

### C-02 · S2 · EMU header carries a standalone v2.0 with no suite version among five schemes
- **Where:** SOP_EMU_NeSI.md, § header (line 5); and every SOP header + README.md
- **Anchor:** `**v2.0** | last updated July 2026`
- **Quote:**
  > **v2.0** | last updated July 2026 | NeSI (SLURM) | Oxford Nanopore full-length 16S
- **Defect:** Part 1 is versioned `v2.0` on its own. The five SOPs carry five uncoordinated version numbers (EMU v2.0, CONCOMPRA v2.1, READBASED v3.0, R_Analysis v2.1, ASSEMBLY v0.1) and there is no suite-level version or release date anywhere. A reader holding "Part 1 v2.0" cannot tell which release of the *manual* it belongs to, or whether the neighbour documents are the matching editions.
- **Impact:** A student clones the repo, sees `v2.0` on Part 1 and (following the README) `v0.1` on ASSEMBLY, and has no way to know whether they hold one coherent, current set or a mix of editions frozen at different times. A maintainer cannot cite "the Taylor Lab SOP suite as of date X" because no such number exists.
- **Type:** COHERENCE
- **Confidence:** CONFIRMED
- **Evidence:** Five distinct `**vN.N**` header strings across the five SOPs (Agent 0 FACTS suite table: EMU 2.0, CONCOMPRA 2.1, READBASED 3.0, R_Analysis 2.1, ASSEMBLY 0.1). `grep -niE 'version' README.md` returns no suite-version line — only a footer date. This is the same defect the brief flags in calibration C-00, still open, seen here from the EMU side.
- **Fix:** This is Agent B's convention to set suite-wide; EMU conforms once it exists. Recommended shape, pasteable into line 5 once the suite number is chosen: keep the document version but add the suite tag, e.g. `**Part 1 · v2.0** | Taylor Lab SOP suite v1.0 (August 2026) | NeSI (SLURM) | Oxford Nanopore full-length 16S`, and add the same `suite v1.0 (August 2026)` token to the header line of `SOP_CONCOMPRA_NeSI.md`, `SOP_READBASED_NeSI.md`, `SOP_R_Analysis.md`, `SOP_ASSEMBLY_NeSI.md`, plus a one-line suite-version banner in `README.md`.

### C-03 · S2 · EMU calls the suite four documents ("the other three") but five SOPs ship
- **Where:** SOP_EMU_NeSI.md, § intro (line 7); README.md (routing table 9-14, "what each covers" 24-28, footer 120)
- **Anchor:** `the other three assume it`
- **Quote:**
  > It assumes no prior command-line experience and starts from `pwd` — it is the only document in this set that teaches the cluster itself; the other three assume it.
- **Defect:** EMU counts the set as four ("the other three"). Five SOPs ship, and the README's own routing table enumerates all five (ASSEMBLY added at README:14 and :28). The clause is also inaccurate on its face: Part 2 (`SOP_R_Analysis.md`) does **not** assume the cluster — the README itself says it "runs locally and legitimately does not" point back.
- **Impact:** A first-time student takes Part 1's own words as the map of the suite, expects three sibling documents, and instead finds four — including ASSEMBLY, an unreviewed v0.1. The very first paragraph mis-states how many documents exist and mis-describes what one of them assumes, at exactly the moment the reader is building their mental model of the set.
- **Type:** COHERENCE
- **Confidence:** CONFIRMED
- **Evidence:** `ls SOP_*.md` → 5 files. README:14 routes MAG work to `SOP_ASSEMBLY_NeSI.md`; README:28 describes it as a peer document; so the set is five, not four. EMU:7 says "the other three." (The README footer at :120 carries the identical stale count — "All four SOPs" — but that is README's to fix; EMU:7 is the EMU-side instance.)
- **Fix:** Drop the hard count and the Part-2 mischaracterisation. Replace the clause after "starts from `pwd`" on line 7 with:
  > it is the only document in this set that teaches the cluster itself. The other cluster SOPs (`SOP_CONCOMPRA_NeSI.md`, `SOP_READBASED_NeSI.md`, `SOP_ASSEMBLY_NeSI.md`) point back here for the bash/SLURM groundwork; `SOP_R_Analysis.md` (Part 2) runs locally and stands on its own.

### C-04 · S3 · A 1,019-line teaching document has no table of contents
- **Where:** SOP_EMU_NeSI.md, § Quick Roadmap (lines 15-24)
- **Anchor:** `## **Quick Roadmap**`
- **Quote:**
  > ## **Quick Roadmap**
  > ```
  > [1] Getting started on NeSI   ->  login, bash, modules, SLURM, arrays
  > [2] Understanding your data   ->  16S, amplicons, Nanopore, quality, FASTQ
  > [3] Processing reads          ->  NanoPlot QC -> chopper filter -> NanoPlot QC
  > [4] Emu profiling             ->  databases -> array run -> combined tables
  > ```
- **Defect:** The document is 1,019 lines across 36 headings (4 top-level sections, 4 numbered steps, 4 appendices) and offers only a 4-line ASCII stage roadmap. The roadmap names the stages but is not a linked index — there is no way to jump to "Setting Up the Databases", Step 3, or Appendix B.
- **Impact:** A student who has run Step 1 and comes back a day later to run Step 3, or who needs to re-find the database-setup block, must scroll a thousand lines or fall back to the browser's find. The roadmap tells them the stage exists but not where it is. Recoverable, but it costs the reader on every return visit to a document they will consult many times.
- **Type:** LAYOUT
- **Confidence:** CONFIRMED
- **Evidence:** `wc -l SOP_EMU_NeSI.md` = 1019; `grep -cE '^#{1,4} '` = 47 heading-like lines (36 real headings after excluding in-fence bash comments). The only navigation aid in the file is the unlinked ASCII roadmap above.
- **Fix:** Agent B should set whether the suite standardises on a TOC and in what form; EMU should carry one either way. Paste-ready, immediately after the roadmap fence (line 24):
  > **Contents:** [1. Getting Started on NeSI](#1-getting-started-on-nesi) · [2. Understanding Your Data](#2-understanding-your-data) · [3. Processing Nanopore Reads](#3-processing-nanopore-reads) · [4. Taxonomy and Community Profiling with Emu](#4-taxonomy-and-community-profiling-with-emu) · [Troubleshooting](#troubleshooting) · [Appendices](#appendices)

### C-05 · S4 · Combine helper is `04_`-prefixed in Part 1 but unprefixed where Part 2 names it
- **Where:** SOP_EMU_NeSI.md, § Combining Emu Outputs (line 790); and SOP_R_Analysis.md (line 163)
- **Anchor:** `Save this as`
- **Quote:**
  > Save this as `04_combine_emu_results.py` in your project directory:
- **Defect:** EMU authors and calls the helper `04_combine_emu_results.py` consistently (8 mentions), honouring the section-number-prefix convention (README: "script filenames carry the number of the section that defines them"). Part 2 refers to the same script without the `04_` prefix, so the two documents name one file two ways across the handoff.
- **Impact:** Minor. A student who saved `04_combine_emu_results.py` following Part 1 meets `combine_emu_results.py` in Part 2 and briefly wonders whether it is a different script. No functional break — the actual handoff artefact is the `.tsv`, which both documents name identically (`emu-combined-counts_<db>.tsv`).
- **Type:** COHERENCE
- **Confidence:** CONFIRMED
- **Evidence:** Agent 0 FACTS §"Two script-naming defects" #1: EMU:782,790,… use `04_combine_emu_results.py` (I re-confirmed `grep -cF '04_combine_emu_results.py' SOP_EMU_NeSI.md` = 8); "R_Analysis:163 refers to the same file as `combine_emu_results.py` — without the `04_` prefix." (I did not open R_Analysis; this is Agent 0's probe.)
- **Fix:** EMU is already correct; edit the reference in `SOP_R_Analysis.md` (line 163) to `04_combine_emu_results.py` so both sides of the seam use the section-numbered name.

## Verified against the suite

Probes I ran from the repo root on 2026-08-04, with output:

- **Remote figures (C-01)** — `curl -sI --max-time 25` on all four `github.com/user-attachments/assets/…` URLs at EMU lines 399/405/537/543 → **HTTP/2 404** every time (`server: github.com`).
- **Local figure directory** — `ls examples/` → only `r_analysis/`; `find examples -iname '*emu*'` → nothing. EMU has **no** in-repo figures; R_Analysis has 14 local PNGs (`examples/r_analysis/figures/*.png`). Confirms the figure-strategy split behind C-01.
- **Document count (C-03)** — `ls SOP_*.md` → 5 files; `grep -niE 'assembly|SOP_' README.md` shows the routing table lists all five (ASSEMBLY at README:14,:28); README footer:120 still reads "All four SOPs".
- **Version scheme (C-02)** — EMU line 5 `**v2.0**`; `grep -niE 'version' README.md` → no suite-version line.
- **Banned-word sweep (structure S-12 regression)** — `grep -niE '\b(just|easily|clearly|simply|obviously)\b' SOP_EMU_NeSI.md` → **0 hits**. The six banned words the structure round targeted are gone.
- **Keep-list regression** — all 15 load-bearing anchors (below) `grep -cF` to exactly 1. None dropped.
- **Anchor uniqueness** — every anchor in this report `grep -cF`s to exactly 1 in `SOP_EMU_NeSI.md`.
- **Heading census** — `grep -cE '^#{1,4} '` = 47 (36 real headings + 11 in-fence bash comments), across `wc -l` = 1019 lines (basis for C-04).

Not re-verifiable here (unchanged from prior rounds, and not blocking ship): the
`silva.tar` internal layout (needs a multi-GB OSF download; the SOP's post-extract
checkpoint at lines 640–646 guards it either way), and the four PNGs' *content*
(they must be regenerated for C-01, so there is nothing on disk to inspect).

## Regressions — prior fixes that did not land

**None.** I checked every applied rewrite from both prior rounds and all are present in the current file:

- Structure S-01 (DB runtime + checkpoint) → lines 638–646. S-02 (chimera glossed at first use) → line 370. S-03 (EM glossed in Step 3) → line 417 "the EM algorithm, detailed in Section 4". S-04/S-05 (NanoPlot-raw + Emu-array checkpoints) → lines 356–362, 734–740. S-06 (runtimes) → lines 354, 471, 507. S-07 (NanoPlot reference → Appendix B) → lines 996–1002. S-08 (script renumber `03a/03b/03c/04a/04b/04_`) → applied throughout. S-09 (Before You Start, ASCII roadmap, Troubleshooting, Appendices) → lines 9, 15, 971, 984. S-11 (bold headings) → all headings bold. S-12 (banned words) → 0 hits (probe above). S-13 ("capitalisations") → line 128.
- Correctness F-01 (`--chdir` on every header, no in-body `cd`) → lines 146, 332, 427, 485, 677. F-02 (`<your_email>` = whole address) → line 178. F-03 (NanoPlot pooled-report framing) → lines 364–366. F-04 (retention 60–85% / 15–40%) → lines 473, 513. F-05 (Option B is the standard handoff; verify block + else-branch) → lines 782–784, 944–955. F-06 (`--array` set at submission; `--mem` template; equal NanoPlot walltimes 00:30:00) → lines 148, 333, 486, 681–682.

The one item that *looks* like an un-applied fix but is not: correctness F-05's
verify block (lines 944–952) still hard-codes the Option-B filename
`emu-combined-counts_${db}.tsv`. That is now **correct**, because the seam decision
(SYNTHESIS convention 3) standardised the handoff on Option B and demoted the
built-in `combine-outputs` to a labelled "Alternative" (line 959); the block's
else-branch (line 955) handles the "produced nothing" case. Not a regression.

## Keep list

Load-bearing passages a rewrite must not lose (all `grep -cF` = 1 today; this is the regression test for any Stage-4 edit):

1. `essential, do not omit` — `--keep-counts` silent-failure warning ("re-run Emu from scratch").
2. `a 1,500 bp floor would discard many legitimate full-length reads` — the `--minlength 1200` why-this-number.
3. `Emu reads that as 0.9% identity` — `--min-pid` percent-scale silent-failure trap.
4. `raise it or reads are discarded without warning` — `--max-align-len` default-2000 silent-truncation caveat.
5. `silently inflates the count` — the `grep -c "^@"` / `@`-is-Q31 read-count correction.
6. `only the first sample is processed` — the array-range silent-failure warning.
7. `write the other's into two identically named columns` — combine-script duplicate-basename guard rationale.
8. `EM uses **community context** to resolve ambiguous reads` — the EM / why-not-best-hit concept the audience lacks.
9. `has not yet been tested or validated with Emu` — SILVA v138.1-vs-138.2 tool-choice justification.

## Divergence from the set

Where EMU's conventions differ from what one manual would use — raw material for Agent B, not re-filed as defects except where noted:

- **Figure strategy (the root of C-01).** EMU embeds figures as remote HTML `<img>` tags pointing off-repo (`github.com/user-attachments/…`); R_Analysis embeds local repo PNGs via markdown `![]()` (14 of them, all present). The suite needs one figure strategy, and the survivable one is R_Analysis's (in-repo, relative-path, offline-safe). Fixing C-01 by adopting it also settles the divergence.
- **Figure caption/numbering discipline.** EMU's figures carry `alt` text and a descriptive prose paragraph but no figure numbers or formal captions; R_Analysis's do likewise. Consistent between the two, so no change needed — but if Agent B introduces numbered captions suite-wide, EMU's four QC plots are the obvious candidates.
- **"Part N" labelling does not scale to five documents.** EMU is titled "Part 1", R_Analysis "Part 2"; CONCOMPRA, READBASED and ASSEMBLY carry no Part label (Agent 0 suite table). The Part-1→Part-2 scheme described a two-document pipeline; it no longer describes four upstream documents feeding one downstream. Agent B should decide whether "Part N" survives or is replaced by the README's upstream/downstream framing.
- **Version scheme (C-02).** EMU's independent `v2.0` is one of five uncoordinated document versions with no suite version — filed above.
- **Heading case in §2 (blessed deviation, not a defect).** §2's subsections are sentence-case questions ("What is 16S rRNA and why do we sequence it?") while every other heading is bold title case. The structure round explicitly blessed this (Open question 5: keep the question form, bolded, because it reads as layer-1). Flagged only so Agent B settles it once across the set rather than "fixing" it here.
- **Troubleshooting placement.** EMU keeps its failure notes inline (per-step Checkpoints) and adds a short pointer table under `## Troubleshooting` (lines 971–982) that routes back to those inline notes rather than duplicating them. If the suite adopts one canonical Troubleshooting home/format, EMU's pointer-table pattern is a reasonable candidate for the house style.

## Release recommendation

**Ready with the listed fixes — one is a hard ship-gate.** As a teaching document
Part 1 is the strongest in the set and is otherwise clean: all prior rewrites
landed, every cross-reference resolves, the load-bearing content is intact, and
there are no un-reviewed sections. But it **must not** ship with **C-01**: a QC
document whose four figures all 404 and live off-repo will render as four broken
images for every student who clones the repository, and to that reader a broken
figure reads as their own error — the exact failure this review outranks
everything to prevent. C-01 requires regenerating and committing the four PNGs
in-repo, which is real work because the images exist nowhere retrievable today.
The two S2 coherence items (C-02 version scheme, C-03 document count) are
suite-wide and belong to Agent B's convention pass but should land before the set
goes to a new student; C-04 (TOC) and C-05 (script-name drift) are cheap polish.
Fix C-01, apply the coherence decisions, and Part 1 is ready.

## Self-check

```
findings=5 S1=1 S2=1 S3=2 S4=1
CLEAN
```

CONTRACT: PASS
