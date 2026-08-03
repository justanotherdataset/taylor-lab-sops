## Document: SOP_READBASED_NeSI.md

Capstone (product-integrity) review of `SOP_READBASED_NeSI.md` as a shippable
member of the five-document suite. Read against the COMMON BRIEF, the settled
rounds (`reviews/00_SYNTHESIS.md`, `reviews/00_ENVIRONMENT.md`,
`reviews/structure/00_PLAN.md`, `reviews/structure/00_REALITY.md`,
`reviews/READBASED.review.md`, `reviews/structure/READBASED.md`), and Agent 0's
facts (`reviews/capstone/00_FACTS.md`). All line numbers are my own current read
of the on-disk file (`wc -l` = **1028**, v3.0, last updated July 2026).

**Headline:** the document's *content* is in excellent shape — every load-bearing
"why this number", silent-failure warning, and governance passage the two prior
rounds protected is present and correct, and every correctness/structure fix
(header inlining with `--chdir`, `$DB` defined inline, `.profile`-strip relab
merge, chm13 gating, per-step runtimes, checkpoints, layer-1 openers) landed. But
the applied structure rewrite (commit `82e61b6`) **deleted the entire "Appendix A:
Submission Chain"** and relabeled the remaining appendices incompletely. That
single edit orphaned four cross-references, one of them to content that is now
gone, and left the back-matter lettered A, C. That is a regression the settled
rounds never saw (they reviewed the file *before* the deletion), and it is the
ship-blocker.

## Section ledger

Every heading in the file. Treatment: `CLEAN FIX-REF RELABEL ADD-NAV MERGE`.

| § | Heading | Lines | Treatment | Findings |
|---|---|---|---|---|
| — | Title + scope preamble | 1–13 | CLEAN | — |
| — | Quick Roadmap: What You'll Do | 17–42 | ADD-NAV | C-03 (no ToC) |
| 1 | Before You Generate Data | 46–99 | CLEAN | — (governance/depth — keep) |
| 1· | Governance | 50–54 | CLEAN | — (keep) |
| 1· | Controls | 56–67 | CLEAN | — |
| 1· | Depth | 69–99 | CLEAN | — (keep) |
| 2 | Preflight and Storage | 102–136 | CLEAN | — |
| 2· | Preflight | 104–122 | CLEAN | — |
| 2· | Storage | 124–136 | CLEAN | — |
| 3 | Setup | 139–140 | CLEAN | — |
| 3.1 | Directories and the Sample Manifest | 141–170 | CLEAN | — |
| 3.2 | Modules | 171–177 | CLEAN | — |
| 3.3 | References and Databases | 179–202 | CLEAN | — |
| 4 | The Standard Job Header | 205–212 | CLEAN | — (header inlining landed) |
| 5 | Quality Control | 215–276 | FIX-REF | **C-01** (L265, L275 → Appendix A) |
| 5· | Reading the Reports | 277–282 | CLEAN | — |
| 5· | Identify Your Chemistry Now | 283–292 | CLEAN | — |
| 6 | Trimming and PhiX Removal | 295–343 | CLEAN | — |
| 6· | Two-Colour Chemistry: Poly-G | 345–349 | CLEAN | — (BBMap 39.01 fix landed) |
| 6· | Alternative: fastp for Pass One | 351–389 | CLEAN | — |
| 7 | Host Depletion | 393–396 | CLEAN | — |
| 7· | Why T2T-CHM13v2.0 | 397–401 | CLEAN | — (keep) |
| 7· | Why the Reference Must Be Masked | 403–405 | CLEAN | — (keep) |
| 7· | Option A — Hostile (Recommended) | 407–456 | CLEAN | — |
| 7· | Option B — BBMap Unmasked T2T | 458–520 | FIX-REF | **C-01** (L462 → Appendix A) |
| 7· | Expected Host Fraction by Site | 522–531 | CLEAN | — |
| 8 | Read Accounting and Depth Gates | 535–576 | CLEAN | — |
| 8· | The Gates | 578–589 | CLEAN | — (keep) |
| 9 | Taxonomy with MetaPhlAn 4 | 593–644 | FIX-REF | **C-04** (L622 → Appendix B) |
| 9· | Why `--index` and `--offline` | 646–648 | CLEAN | — (keep) |
| 9· | Why There Are Two Passes | 650–656 | CLEAN | — (keep) |
| 10 | Function with HUMAnN | 660–664 | CLEAN | — |
| 10· | Install a Current Release | 666–686 | CLEAN | — (keep) |
| 10· | Running It | 688–737 | CLEAN | — (keep: trap) |
| 11 | Merging, Normalising and Splitting Tables | 741–751 | CLEAN | — |
| 11· | Taxonomy: Relative Abundance | 753–771 | CLEAN | — (F-01 fix landed) |
| 11· | Taxonomy: Estimated Counts | 773–799 | CLEAN | — |
| 11· | Function | 801–831 | CLEAN | — |
| 11· | What Section 13 Needs | 833–843 | CLEAN | — |
| 12 | Contamination Screening | 846–853 | CLEAN | — (F-06 fix landed) |
| 13 | Statistics: What Changes | 857–861 | CLEAN | — |
| 13· | Reshape Before You Open Part 2 | 863–886 | CLEAN | — (keep) |
| 13· | Beta Diversity | 899–907 | CLEAN | — |
| 13· | PERMANOVA | 909–919 | CLEAN | — |
| 13· | Differential Abundance | 921–934 | CLEAN | — (L932 tighten landed) |
| 13· | Functional Tables | 936–940 | CLEAN | — (keep) |
| 14 | Provenance | 944–980 | CLEAN | — (keep; F-05 branch landed) |
| — | (gap) blank lines before back-matter | 982–985 | MERGE | C-05 |
| A | Appendix A: Triage | 986–1008 | RELABEL | **C-01 / C-04** (should be B) |
| — | *(Appendix B: Submission Chain — DELETED)* | — | **restore** | **C-01** |
| C | Appendix C: Resources | 1010–1029 | RELABEL | **C-04** (lettering) |
| — | version line (suite coherence) | 5 | — | **C-02** |

## Findings

### C-01 · S1 · Deleted Submission-Chain appendix leaves §5/§7 dependency pointers unreachable
- **Where:** SOP_READBASED_NeSI.md, §§ 5 & 7 and back-matter (lines 265, 275, 462; appendices 986–1029)
- **Anchor:** `must not start until this finishes — see Appendix A`
- **Quote:**
  > `scripts/07a.host_index.sl` (no array). The filter must not start until this finishes — see Appendix A:

  and, in Section 5:
  > **MultiQC must be a dependent job.** Submit it with `--dependency=afterok` (Appendix A). … leaving you a report that looks fine and is silently incomplete.
- **Defect:** Three references send the reader to "Appendix A" for the SLURM
  job-dependency chain (`--dependency=afterok`, `--parsable`, the 07a→07b
  ordering): line 265 and line 275 for making MultiQC wait on the FastQC array,
  and line 462 for making `07b.host_filter.sl` wait on `07a.host_index.sl`. But
  **Appendix A is now "Triage"** (line 986), and there is no "Submission Chain"
  appendix and no `afterok`/`--parsable` worked example anywhere in the document.
  The structure rewrite (commit `82e61b6`) deleted the "Appendix A: Submission
  Chain" appendix that these pointers were written against, relabeled the old
  "Appendix B: Triage" to "Appendix A", and left the reader with three pointers to
  content that no longer exists.
- **Impact:** A first-time reader at Section 5 is told to submit MultiQC "as a
  dependent job … (Appendix A)" — the document's own warning is that submitting it
  any other way yields a green-exit report that is silently incomplete. They open
  Appendix A to learn the syntax, find "Triage" (sacct/re-run), and have nowhere in
  the document that shows `sbatch --parsable … --dependency=afterok:$JOBID`. Worse
  at Section 7 Option B: line 462 says `07b` "must not start until this finishes —
  see Appendix A"; the reader who cannot find the ordering example submits `07b`
  against a half-built index and gets a corrupt or failed depletion. Promised
  content the reader cannot reach — the exact failure this review outranks.
- **Type:** CONTENT
- **Confidence:** CONFIRMED
- **Evidence:** The file contradicts itself, corroborated by git:
  ```
  $ grep -nE 'Appendix|afterok|dependency|Submission Chain' SOP_READBASED_NeSI.md
  265:… Submit it with `--dependency=afterok` (Appendix A).      # pointer
  275:… resubmit it with `--dependency=afterok` (Appendix A).     # pointer
  462:… must not start until this finishes — see Appendix A:      # pointer
  986:## **Appendix A: Triage**                                   # target = Triage, not the chain
  1010:## **Appendix C: Resources**
  # no "Submission Chain" heading; no afterok/--parsable example anywhere
  $ git show a9a6336:SOP_READBASED_NeSI.md | grep -nE '^#+ .*Appendix'
  805:## **Appendix A: Submission Chain**     # present in the original …
  836:## **Appendix B: Triage**
  860:## **Appendix C: Resources**
  # … and gone as of commit 82e61b6 (the P3 rewrite). Regression.
  ```
  The structure round explicitly marked it KEEP: `reviews/structure/READBASED.md`
  target outline "## Appendix A: Submission Chain … KEEP" and its ledger row
  "Appendix A: Submission Chain … reference at back — correct place." Both settled
  rounds reviewed the file *before* the deletion, so neither could have caught it.
- **Fix:** Restore the deleted appendix (recovered verbatim from commit `a9a6336`;
  every script name in it matches the current doc) as **Appendix A**, re-letter the
  current "Appendix A: Triage" to **Appendix B**, and re-letter "Appendix C:
  Resources" — it stays **C**. Insert immediately before the current
  `## **Appendix A: Triage**` (line 986), replacing the stray blank lines at
  982–985 with a single blank line:

  ```
  ## **Appendix A: Submission Chain**

  Run this from `$WORK`. Each job waits on the one it depends on, so you can submit the whole thing at once and let SLURM sequence it.

  ```bash
  cd "$WORK"; NSAMP=$(wc -l < samples.txt); T=20

  FQR=$(sbatch --parsable --array=1-${NSAMP}%${T} scripts/05a.qc_fastqc.sl raw qc/raw)
         sbatch --dependency=afterok:$FQR         scripts/05b.qc_multiqc.sl qc/raw

  # two-colour chemistry? add trimpolygright=8 to pass 1, or use the fastp variant - Section 6
  TRIM=$(sbatch --parsable --array=1-${NSAMP}%${T} scripts/06.trim.sl)

  FQT=$(sbatch --parsable --dependency=afterok:$TRIM --array=1-${NSAMP}%${T} \
               scripts/05a.qc_fastqc.sl trim qc/trim)
         sbatch --dependency=afterok:$FQT         scripts/05b.qc_multiqc.sl qc/trim

  HOST=$(sbatch --parsable --dependency=afterok:$TRIM --array=1-${NSAMP}%${T} scripts/07.host_hostile.sl)
  # Option B instead:
  # IDX=$(sbatch --parsable scripts/07a.host_index.sl)
  # HOST=$(sbatch --parsable --dependency=afterok:$IDX:$TRIM --array=1-${NSAMP}%${T} scripts/07b.host_filter.sl)

         sbatch --dependency=afterok:$HOST        scripts/08.read_counts.sl
  MPA=$(sbatch --parsable --dependency=afterok:$HOST --array=1-${NSAMP}%${T} scripts/09.metaphlan.sl)
         sbatch --dependency=afterok:$MPA --array=1-${NSAMP}%10 scripts/10.humann.sl

  squeue --me
  ```

  `afterok:$IDX:$TRIM` waits on both jobs. Section 11 is deliberately left out of the chain, because you should look at Section 8's output before building final tables.
  ```

  Then change `## **Appendix A: Triage**` → `## **Appendix B: Triage**`. This one
  edit also makes the line-622 "(Appendix B)" pointer correct and closes C-04's
  lettering gap; if you apply this fix, do not also apply C-04's minimal
  re-letter.

### C-02 · S2 · Suite carries five version numbers and README says four SOPs; no suite version
- **Where:** SOP_READBASED_NeSI.md, § version line (line 5); README.md, § footer (line 120); and the header of each SOP
- **Anchor:** `NeSI (SLURM) | Illumina paired-end`
- **Quote:**
  > **v3.0** | last updated July 2026 | NeSI (SLURM) | Illumina paired-end | human-associated samples
- **Defect:** The five SOPs are versioned independently (EMU v2.0, CONCOMPRA v2.1,
  READBASED v3.0, R_Analysis v2.1, ASSEMBLY v0.1) with no single suite version
  anywhere, and the README footer describes a state that is now false — "All
  **four** SOPs and this README were … reviewed" when five SOPs ship, one of them
  (ASSEMBLY v0.1) never reviewed. A reader holding READBASED v3.0 cannot tell which
  release of the *suite* it belongs to, or whether the neighbour documents it
  cross-references (Part 2, EMU §1–2) are the versions it was written against.
- **Impact:** The new student clones the repo, reads the README footer ("four
  SOPs, second review round, July 2026"), then finds five `SOP_*.md` files —
  including an August-2026 v0.1 ASSEMBLY the footer's "reviewed adversarially"
  claim does not cover. They cannot answer "what version of this manual do I have?"
  and a maintainer cannot cite "the suite as of date X." The count is simply wrong
  the moment the fifth SOP exists.
- **Type:** COHERENCE
- **Confidence:** CONFIRMED
- **Evidence:** Five distinct version strings and the false footer count, measured:
  ```
  $ ls -1 SOP_*.md | wc -l
  5
  $ for f in SOP_*.md; do grep -m1 -E '\*\*v[0-9]' "$f"; done
  **v0.1** … August 2026   (ASSEMBLY)     **v2.1** … July 2026 (CONCOMPRA)
  **v2.0** … July 2026     (EMU)          **v2.1** … July 2026 (R_Analysis)
  **v3.0** … July 2026     (READBASED)
  $ grep -n 'four SOPs' README.md
  120:*Last updated: July 2026 — second review round. All four SOPs and this README were probed …*
  ```
  Agent 0 records the same (`reviews/capstone/00_FACTS.md`: "Actual SOPs on disk:
  5 … footer … a count of 4"). Modeled on the brief's calibration finding C-00,
  which is still open.
- **Fix:** Add a single suite version and date to the README header (e.g. "**Taylor
  Lab SOPs — suite v1.1, August 2026**") plus a one-line suite changelog, and keep
  the per-document `**vN.N**` lines as document versions beneath it. Replace the
  README footer's "All four SOPs and this README were probed against NeSI Mahuika …
  reviewed adversarially" with "The four Nanopore/Illumina/R SOPs were reviewed in
  the July 2026 round; `SOP_ASSEMBLY_NeSI.md` (v0.1, August 2026) is a draft not yet
  reviewed." Touches README.md and is the single edit that makes every SOP header's
  bare `vN.N` resolvable to a suite state.

### C-03 · S3 · 1028-line document has no table of contents or clickable section index
- **Where:** SOP_READBASED_NeSI.md, § Quick Roadmap (lines 17–42)
- **Anchor:** `Quick Roadmap: What You'll Do`
- **Quote:**
  > ## **Quick Roadmap: What You'll Do**
- **Defect:** The document is 1028 lines across 14 numbered sections, subsections
  and three appendices, and its only navigational furniture is the Quick Roadmap —
  an ASCII *workflow* diagram (Stage 1→7) with no links and no listing of the
  sections or appendices. There is no table of contents. A reader cannot jump to
  "Section 13" (which every cross-reference in the suite points at), to "Appendix C:
  Resources", or back to a section they half-remember, without scrolling ~1000
  lines or Ctrl-F-guessing the heading text.
- **Impact:** The new student following a cross-reference from the README or from
  Part 2 ("the read-based SOP's Section 13") lands at the top of a 1028-line file
  and must scroll to find §13; the roadmap tells them the pipeline stages but not
  where §13 lives. Recoverable, but it costs the reader time on every jump, in the
  one document every shotgun reader is routed into for the compositional deltas.
- **Type:** LAYOUT
- **Confidence:** VERIFIED
- **Evidence:**
  ```
  $ wc -l SOP_READBASED_NeSI.md
  1028 SOP_READBASED_NeSI.md
  $ grep -nE '^\s*[-*] \[.*\]\(#' SOP_READBASED_NeSI.md   # markdown ToC links
  (no output — there is no linked contents list)
  ```
  The Quick Roadmap (lines 19–40) is a fenced ASCII diagram of pipeline stages, not
  a section index.
- **Fix:** Add a linked contents list immediately after the version line (line 5)
  and before the Quick Roadmap, using GitHub's heading-slug anchors, e.g.:

  ```markdown
  ## Contents
  1. [Before You Generate Data](#1-before-you-generate-data) · 2. [Preflight and Storage](#2-preflight-and-storage) · 3. [Setup](#3-setup) · 4. [The Standard Job Header](#4-the-standard-job-header) · 5. [Quality Control](#5-quality-control) · 6. [Trimming and PhiX Removal](#6-trimming-and-phix-removal) · 7. [Host Depletion](#7-host-depletion) · 8. [Read Accounting and Depth Gates](#8-read-accounting-and-depth-gates) · 9. [Taxonomy with MetaPhlAn 4](#9-taxonomy-with-metaphlan-4) · 10. [Function with HUMAnN](#10-function-with-humann) · 11. [Merging, Normalising and Splitting Tables](#11-merging-normalising-and-splitting-tables) · 12. [Contamination Screening](#12-contamination-screening) · 13. [Statistics: What Changes](#13-statistics-what-changes-from-sop_r_analysismd) · 14. [Provenance](#14-provenance) · [Appendix A](#appendix-a-submission-chain) · [Appendix B](#appendix-b-triage) · [Appendix C](#appendix-c-resources)
  ```

  This is a suite-wide house-style question (see Divergence): apply the same
  contents block to every 1000-plus-line SOP so navigation is uniform, not just
  here.

### C-04 · S3 · Back-matter lettering skips B; code comment points to nonexistent Appendix B
- **Where:** SOP_READBASED_NeSI.md, § 9 and back-matter (lines 622, 986, 1010)
- **Anchor:** `re-running a failed array index (Appendix B) safe.`
- **Quote:**
  > \# re-running a failed array index (Appendix B) safe.
- **Defect:** The appendices are lettered **A** ("Triage", line 986) then **C**
  ("Resources", line 1010) — no B. Separately, the §9 script comment at line 622
  points to "Appendix B" for re-running a failed array index; that topic is real
  (Appendix A "Triage" holds the `sbatch --array=3,17,42` re-run at line 992) but
  it is under **A**, not B, so the pointer names an appendix that does not exist.
- **Impact:** A reader who hits the MetaPhlAn `BowTie2 output file detected …
  Exiting` failure sees the code comment's "(Appendix B)", flips to the back matter
  to find the triage guidance, finds Appendix A then Appendix C and no B, and is
  briefly unsure whether an appendix is missing from their clone. Recoverable — the
  content is one letter over — but a self-inflicted moment of "did I break the
  download?" in exactly the reader this review protects.
- **Type:** LAYOUT
- **Confidence:** CONFIRMED
- **Evidence:**
  ```
  $ grep -nE '^#+ .*Appendix' SOP_READBASED_NeSI.md
  986:## **Appendix A: Triage**
  1010:## **Appendix C: Resources**      # A → C, no B
  $ grep -n 'Appendix B' SOP_READBASED_NeSI.md
  622:# re-running a failed array index (Appendix B) safe.   # points to a letter that does not exist
  ```
  Agent 0 flagged this as the suite's one BROKEN reference
  (`reviews/capstone/00_FACTS.md`).
- **Fix:** Restoring the Submission-Chain appendix per **C-01** (Submission Chain
  = A, Triage = B, Resources = C) closes this automatically and is the preferred
  route. If the lab declines to restore the appendix, apply the minimal standalone
  fix instead: change line 622 `(Appendix B)` → `(Appendix A)`, and re-letter
  `## **Appendix C: Resources**` → `## **Appendix B: Resources**` so the lettering
  is contiguous A, B. Apply exactly one of these two routes, never both.

### C-05 · S4 · Three blank lines separate Section 14 from Appendix A
- **Where:** SOP_READBASED_NeSI.md, between § 14 and Appendix A (lines 982–986)
- **Anchor:** `## **Appendix A: Triage**`
- **Quote:**
  > ## **Appendix A: Triage**
- **Defect:** The transition from Section 14 into the back matter carries a `---`
  rule followed by three consecutive blank lines (983–985) before the Appendix A
  heading, where every other section break in the document uses a single blank
  line. A cosmetic inconsistency with no reader consequence.
- **Impact:** None functional; a maintainer diffing or a strict markdown linter
  notices the ragged whitespace. Included for completeness under the S4 cap.
- **Type:** LAYOUT
- **Confidence:** VERIFIED
- **Evidence:**
  ```
  $ sed -n '980,986p' SOP_READBASED_NeSI.md | cat -A
  - Every model formula$
  $
  ---$
  $
  $
  $
  ## **Appendix A: Triage**$
  ```
- **Fix:** Collapse lines 983–985 to a single blank line after the `---` rule
  (the C-01 fix, which inserts the restored appendix here, already does this).

## Verified against the suite

Probes I ran on NeSI (`login03`-class environment), from the repo root:

- **Line count / version / date (first-hand, not quoted):** `wc -l
  SOP_READBASED_NeSI.md` → **1028**; header line 5 → **v3.0 | July 2026**.
- **Appendix references vs. headings:** `grep -nE 'Appendix|afterok|dependency'` →
  pointers at 265, 275, 462 ("Appendix A" for the dependency chain) and 622
  ("Appendix B"); headings only "Appendix A: Triage" (986) and "Appendix C:
  Resources" (1010). No "Submission Chain" heading; no `afterok`/`--parsable`
  example anywhere. → C-01, C-04.
- **Git regression trace:** `git show a9a6336:… | grep Appendix` → original had
  "Appendix A: Submission Chain / B: Triage / C: Resources"; `git log --oneline`
  shows the deletion entered in `82e61b6` ("P3: READBASED rewrite"). The full
  Submission-Chain block was recovered verbatim from `a9a6336` and its nine script
  names (`05a`…`10`) all match the current doc. → C-01 fix is paste-ready.
- **Suite version/count:** `ls -1 SOP_*.md | wc -l` → 5; five distinct `**vN.N**`
  strings; `grep 'four SOPs' README.md` → line 120. → C-02.
- **Anchor uniqueness:** `grep -cF` on all five anchors → each prints `1` in
  `SOP_READBASED_NeSI.md`.
- **No-ToC:** `grep -nE '^\s*[-*] \[.*\]\(#'` → no output (no linked contents). →
  C-03.
- **README→READBASED mis-route (not re-filed here; README-owned):** Agent 0's
  `README.md:12` "that SOP's Section 13" resolves literally to R_Analysis §13
  ("Figures and Reproducibility") but intends READBASED §13 (the deltas). Confirmed
  against heading maps; the fix edits README, so I leave it to the README owner /
  Agent B and record it here as corroborated.

## Regressions — prior fixes that did not land

- **The "Appendix A: Submission Chain" appendix was deleted (C-01).** The structure
  round marked it **KEEP** in two places — `reviews/structure/READBASED.md` target
  outline ("## Appendix A: Submission Chain … KEEP") and section ledger ("reference
  at back — correct place"). The applied P3 rewrite (`82e61b6`) removed it and
  relabeled Triage B→A without re-lettering Resources. This is the one regression,
  and it is the S1.
- **Everything else the settled rounds owned landed correctly** (verified by
  anchor grep on the current file, so no re-file):
  - Header inlined into all script blocks with `--chdir` (structure S-01); the old
    `cd "${SLURM_SUBMIT_DIR:?}"` footgun is gone.
  - `$DB` defined inline in `07a`/`07b` (correctness F-02) — lines 478, 502.
  - Relative-abundance merge takes the header from `clade_name` and strips
    `.profile` (correctness F-01) — lines 768–770.
  - chm13 gated to Option B (F-04) — lines 181, 190; provenance branches on
    Option A/B (F-05) — lines 959–964; decontam points at `part2_relab.tsv` (F-06)
    — line 851; `rm -f …bt2.bz2` re-run guard (F-03) — line 623.
  - Per-step runtimes and §5/§9/§10 checkpoints (S-02, S-04); layer-1 openers for
    §6/§10 and the PhiX gloss (S-05, S-06, S-03); line-11 reframe (S-07); L932
    tightened to 78 words (S-11); BBMap 39.01 nudge fixed (S-12) — all present.

## Keep list

Load-bearing passages a tightening pass must not lose (each `grep -Fc` = 1):

1. `re-identify individuals against matched genotype data at 93.3%` — governance / re-identification (§1).
2. `Divide, do not multiply.` — depth-budget arithmetic + the worked table (§1).
3. `they cannot be combined into one` — two-pass BBDuk `ktrim=r` rationale (§6).
4. `parameters come from JGI's recipe and assume a masked reference` — masked-reference reasoning (§7).
5. `depend on when someone last ran the tool with internet access` — `--index`/`--offline` reproducibility (§9).
6. `a column sums to roughly 8x the classified fraction` — all-ranks 8× misuse warning (§11).
7. `any cleanup placed after the command would never run` — HUMAnN temp-dir `trap` rationale (§10).
8. `Each job waits on the one it depends on` — the Submission-Chain dependency logic **being restored** by C-01; must survive as the reader's only source for `afterok` job ordering.

## Divergence from the set

Raw material for Agent B (I supply evidence; Agent B sets the standard):

- **Version scheme (C-02).** Five independent document versions, no suite version;
  README footer counts "four SOPs" for a five-SOP repo. READBASED's `**v3.0**`
  participates in the incoherence.
- **"Part N" labelling.** READBASED carries **no** "Part" label yet repeatedly
  routes the reader to "Part 2" (§13 title, line 863 "before you open Part 2").
  EMU is "Part 1", R_Analysis "Part 2"; CONCOMPRA, READBASED and ASSEMBLY are
  unlabeled upstreams. The "Part 1 / Part 2" scheme no longer describes the real
  shape (three cluster upstreams feeding one R document) — a set-level decision.
- **Figure strategy.** READBASED embeds **zero** figures; per Agent 0, EMU embeds
  four remote QC figures (all 404 / off-repo) and R_Analysis embeds 14 local PNGs.
  A cluster runbook whose visible output is MultiQC HTML and tables can defensibly
  carry no static figures, but the suite has three different figure strategies and
  should pick one deliberately.
- **Table of contents (C-03).** No linked contents in a 1028-line doc. Whether every
  1000-plus-line SOP gets one is a house-style call; the reader cost is real here
  regardless.
- **Troubleshooting placement.** READBASED keeps triage in a back-matter appendix
  ("Triage") plus inline "How long"/checkpoint notes at each step. Confirm this
  matches where the sibling documents put their troubleshooting so the suite has
  one home and one name for it.
- **Suite ship-gate (credited, not re-filed):** the repo still has **no `LICENSE`**
  (README flags it; structure round Open Q7). READBASED is the governance-heavy,
  human-data document, so shipping it with no reuse terms is a genuine ship-gate
  for the lab to close — but the fix is a repo-root `LICENSE`, not READBASED text.

## Release recommendation

**Ready-with-listed-fixes.** The document's substance — the governance and
re-identification content, the depth-budget arithmetic, the two-pass BBDuk and
masked-reference reasoning, the `--index`/`--offline` and `trap` warnings, and
every correctness/structure fix from the prior rounds — is present, correct, and
landed. It is **not** shippable as-is because of one regression introduced by the
applied rewrite: the "Appendix A: Submission Chain" appendix was deleted, leaving
three cross-references (Sections 5 and 7) pointing at a job-dependency chain that
no longer exists (C-01, S1) and the back matter lettered A, C with a code comment
aimed at a non-existent "Appendix B" (C-04). Restore the appendix from git and
re-letter (the fix is paste-ready and closes both), settle the suite-version /
"four SOPs" coherence gap (C-02) and add a contents list (C-03), and this document
ships as a coherent member of the suite.

## Self-check

Run from the repo root with `OUTPUT=reviews/capstone/READBASED.md` (so the anchor
`grep -cF … SOP_READBASED_NeSI.md` resolves against the target file):

```
$ cd /nesi/project/uoa03769/taylor-lab-sops
$ OUTPUT=reviews/capstone/READBASED.md && python3 - "$OUTPUT" <<'PY'
  … (brief's self-check script, verbatim) …
PY
findings=5 S1=1 S2=1 S4=1
CLEAN
```

By hand, the three the script cannot check:

- [x] **Ledger accounts for every heading in the file** — the Section ledger lists
  the title/preamble, Quick Roadmap, all 14 numbered sections and their
  subsections, the deleted Appendix (as a `restore` row), Appendices A/C, the
  blank-line gap, and the version line; cross-checked against
  `grep -nE '^#{1,4} ' SOP_READBASED_NeSI.md`.
- [x] **No proposed cut touches load-bearing content** — zero cuts. C-01 *restores*
  deleted content; C-02/C-03 add; C-04/C-05 re-letter/whitespace. The Keep list is
  the regression guard.
- [x] **Every finding is CONFIRMED or VERIFIED** — no `NOT-VERIFIABLE-HERE` blocks;
  each anchor, appendix reference, version count and blank-line span was run here.

CONTRACT: PASS
