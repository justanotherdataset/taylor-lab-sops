## Document: SOP_CONCOMPRA_NeSI.md

**Capstone verdict: ready-with-listed-fixes.** This is the cleanest shippable
member I reviewed. Every prior fix landed (correctness F-01…F-10 and structure
S-01…S-15 are all in the file), no load-bearing content regressed (17/17 keep-list
anchors survive), every one of its 12 internal anchor links resolves, every
cross-document pointer resolves, it embeds no figures (so it carries none of EMU's
broken-image risk), and its README claims are all true. **S1 = 0, and that is a
real result, not an empty tier.** What remains is coherence-and-navigation debt
that makes the suite read as five files rather than one manual: the document wears
no "Part" number while leaning on "Part 2" shorthand (C-01), its roadmap numbers
the workflow "STAGE 1-6" against a "Section 1-10" body (C-02), and one internal
cross-reference points a reader at the wrong section (C-03). None blocks a new
student from running the pipeline; all three cost the "one voice, one scheme"
standard the Capstone is measured against.

Current facts (measured, not quoted): 765 lines, **v2.1**, last updated July 2026.

## Section ledger

| § | Heading | Lines | Treatment | Findings |
|---|---|---|---|---|
| — | Title + version + scope (front matter) | 1-11 | RELABEL | C-01 |
| — | Before you start | 13-23 | CLEAN | — |
| — | Quick Roadmap: What You'll Do | 27-51 | RENUMBER | C-02 |
| 1 | Understanding your data | 53-79 | CLEAN | — |
| 2 | Installation | 82-87 | CLEAN | — |
| 2 | ├ Locations | 88-95 | CLEAN | — |
| 2 | ├ Clone the repository | 96-104 | CLEAN | — |
| 2 | ├ Build the conda environment | 105-124 | CLEAN | — |
| 2 | ├ Verify the environment | 125-147 | CLEAN | — |
| 2 | └ SILVA SINTAX database | 148-161 | CLEAN | — |
| 3 | Pre-flight: Screen for Duplicate Reads | 164-167 | CLEAN | — |
| 3 | ├ Screen | 168-186 | CLEAN | — |
| 3 | ├ Deduplicate | 187-206 | CLEAN | — |
| 3 | └ Record run metadata | 207-216 | CLEAN | — |
| 4 | Run Configuration | 218-219 | CLEAN | — |
| 4 | ├ Directory layout | 220-237 | CLEAN | — |
| 4 | ├ Symlink the input fastqs | 238-250 | CLEAN | — |
| 4 | ├ Run configuration file | 251-274 | CLEAN | — |
| 4 | ├ Primer file | 275-292 | CLEAN | — |
| 4 | └ Threads | 293-298 | CLEAN | — |
| 5 | Submitting the Run | 301-364 | FIX-REF | C-03 |
| 6 | Verifying the Run | 366-369 | CLEAN | — |
| 6 | ├ Per-sample verification | 370-397 | CLEAN | — |
| 6 | ├ Output files | 398-425 | CLEAN | — |
| 6 | └ Cross-check against Emu | 426-429 | CLEAN | — |
| 7 | Post-processing: Taxonomy, Alignment, Phylogeny | 432-512 | CLEAN | — |
| 7 | ├ Notes on the steps | 513-522 | CLEAN | — |
| 7 | └ Verifying the outputs | 523-532 | CLEAN | — |
| 8 | Preparing for R / phyloseq | 535-538 | CLEAN | — |
| 8 | ├ The R-ready folder | 539-550 | CLEAN | — |
| 8 | ├ Building it | 551-583 | CLEAN | — |
| 8 | ├ Checking sample IDs | 584-593 | CLEAN | — |
| 8 | └ Building the phyloseq object | 594-636 | CLEAN | — |
| 9 | Troubleshooting | 639-640 | CLEAN | — |
| 9 | ├ Empty consensus output | 641-650 | CLEAN | — |
| 9 | ├ Empty sintax output | 651-654 | CLEAN | — |
| 9 | ├ medaka, racon, or samtools appear to be missing | 655-658 | CLEAN | — |
| 9 | └ A run is stuck or slow | 659-667 | CLEAN | — |
| 10 | Maintenance | 670-671 | CLEAN | — |
| 10 | ├ Updating CONCOMPRA | 672-684 | CLEAN | — |
| 10 | └ The temporary directory | 685-695 | CLEAN | (target of C-03) |
| A | Appendix A: SILVA SINTAX Database Build | 698-701 | CLEAN | — |
| A | ├ The reformatter | 702-713 | CLEAN | — |
| A | ├ Build | 714-743 | CLEAN | — |
| A | └ Refreshing for a new SILVA release | 744-747 | CLEAN | — |
| B | Appendix B: References | 750-765 | CLEAN | — |

## Findings

### C-01 · S2 · No "Part" label while leaning on "Part 2" shorthand; unplaceable in the suite
- **Where:** SOP_CONCOMPRA_NeSI.md, § header + scope (lines 1-9), § 8 (lines 596-633); README.md, § What each document covers (line 26)
- **Anchor:** `*Taylor Lab | Consensus OTUs from Nanopore 16S*`
- **Quote:**
  > *Taylor Lab | Consensus OTUs from Nanopore 16S*
  >
  > # **CONCOMPRA Pipeline: Consensus OTUs on NeSI**
  >
  > **v2.1** | last updated July 2026 | NeSI (SLURM) | Oxford Nanopore full-length 16S
- **Defect:** The suite numbers exactly two of its five documents — EMU is titled "Part 1", R_Analysis "Part 2" — and CONCOMPRA carries no Part number anywhere in its header, yet it uses the bare shorthand "Part 2" seven times (lines 596, 619, 627, 629, 631, 633) and "Part 1" zero times, referring to its own upstream (EMU) only by filename. The reader cannot place CONCOMPRA in the numbered sequence from the document itself.
- **Impact:** A new student who reaches CONCOMPRA by a direct link (e.g. the README row "Runs after Part 1") looks at its header for a Part number to anchor where they are in the pipeline, finds none, then meets "Part 2 has no code for any of the three formats" (line 596) and "Part 2 indexes them positionally" (line 619) as if "Part 2" were already defined here — it is only derivable because line 596 happens to name `SOP_R_Analysis.md` in the same sentence. The suite reads as five separately-named files, not one manual with one numbering scheme.
- **Type:** COHERENCE
- **Confidence:** CONFIRMED
- **Evidence:** `grep -nE 'Part [12]' SOP_CONCOMPRA_NeSI.md` → "Part 2" ×7 (596-633), "Part 1" ×0; EMU is titled "Part 1" and R_Analysis "Part 2" (reviews/capstone/00_FACTS.md, suite-facts table); README.md:26 places CONCOMPRA as "**Runs after Part 1, same Nanopore data … hands off to Part 2**" — i.e. the README slots it into the Part scheme that its own header omits.
- **Fix:** The scheme decision (does the suite adopt "Part 1A / Part 1B", "Part 1 → optional branch → Part 2", or drop "Part N" for filenames throughout?) is a set-level call and belongs to the coherence-owner (Agent B). Paste-ready interim that removes the reader-hit without pre-empting that decision — (a) give the header a positional descriptor, replacing line 1:
  > *Taylor Lab | Consensus OTUs from Nanopore 16S — runs after Part 1 (Emu), feeds Part 2 (R)*

  and (b) name the target on first use, changing line 596's "Part 2 has no code" to "Part 2 (`SOP_R_Analysis.md`) has no code", so every later bare "Part 2" resolves. Apply the same "Part 2 (`SOP_R_Analysis.md`)" first-use expansion whichever way the suite decision lands.

### C-02 · S3 · Quick Roadmap numbers the workflow "STAGE 1-6"; the body numbers "Section 1-10"
- **Where:** SOP_CONCOMPRA_NeSI.md, § Quick Roadmap (lines 27-51)
- **Anchor:** `STAGE 1: Install (once per project)`
- **Quote:**
  > STAGE 1: Install (once per project)
  > …
  > STAGE 4: Run and verify
  >    Submit main.sh (SLURM) → check per-sample consensus on disk
  >                     ↓
  > STAGE 5: Post-process
- **Defect:** The roadmap runs a second, non-matching numbering scheme over the same workflow: six "STAGE" numbers against the body's ten "Section" numbers. They do not align — STAGE 1 (Install) is Section 2, STAGE 4 (Run and verify) is Sections 5 **and** 6, STAGE 5 (Post-process) is Section 7 — and Section 1 ("Understanding your data") has no stage at all. This is the "Stage" labelling the set retired when R_Analysis was renumbered Stage→Section to give the suite one spine.
- **Impact:** A reader who takes the roadmap as their map internalises "STAGE 5 = post-processing", scrolls to Section 5, and lands on "Submitting the Run" — the stage and section numbers collide within one document. Recoverable (the roadmap names each operation, so they navigate by name), but every reader pays the reconciliation, and it makes CONCOMPRA the one document still carrying "Stage" after the set decided against it.
- **Type:** COHERENCE
- **Confidence:** CONFIRMED
- **Evidence:** `grep -niE 'stage' SOP_CONCOMPRA_NeSI.md` → six hits, all in the roadmap (lines 30-45); `grep -nE '^## \*\*[0-9]'` → ten "Section N" headings. Set decision that eliminated "Stage": reviews/structure/00_PLAN.md, "Section and script renumbering map" (R_ANALYSIS Stage 1-5 → §1-12) and Consistency matrix ("one numbered spine").
- **Fix:** Relabel the roadmap so its steps carry the section numbers they describe, dropping the parallel "STAGE" scheme. Replace the six `STAGE N:` headers with the matching section numbers and merge the run/verify pair:
  > ```
  > SECTION 2 — Install (once per project)
  >    CONCOMPRA repo + conda env + SILVA SINTAX database
  >                     ↓
  > SECTION 3 — Pre-flight: screen for duplicate reads → deduplicate if present
  >                     ↓
  > SECTION 4 — Configure the run: symlink fastqs → directory_list.txt → primer_set.fa
  >                     ↓
  > SECTIONS 5-6 — Submit main.sh (SLURM) → verify per-sample consensus on disk
  >                     ↓
  > SECTION 7 — Post-process: sintax taxonomy → MAFFT alignment → FastTree phylogeny
  >                     ↓
  > SECTION 8 — Hand off to R: build concompra_for_R/ → phyloseq (Part 2, SOP_R_Analysis.md)
  > ```
  (Section 1 is concepts, correctly not a workflow step; leaving it out of the roadmap is fine once the labels read "Section", not "Stage".)

### C-03 · S3 · "Delete temporary/ … (Section 9)" points at Troubleshooting; the step is in Section 10
- **Where:** SOP_CONCOMPRA_NeSI.md, § 5 Submitting the Run (line 322)
- **Anchor:** `once the analysis is final (Section 9)`
- **Quote:**
  > Delete `temporary/` yourself once the analysis is final (Section 9).
- **Defect:** The cross-reference names the wrong section. Deleting `temporary/` once the analysis is final is documented in **Section 10** ("The temporary directory", lines 685-695: "Once your analysis is final, delete the directory yourself: `rm -rf temporary/`"). **Section 9** is Troubleshooting; its four subsections cover empty output, empty sintax, missing tools and a stuck run — none tells the reader to delete `temporary/`. (§9's "A run is stuck or slow" only *inspects* `temporary/` with `ls`/`du`.)
- **Impact:** A reader who wants to know when and how to clear the kept-for-debugging `temporary/` follows "(Section 9)", reaches Troubleshooting, and finds nothing about deletion — the pointer resolves to a real section with the wrong content, so the promise reads as either a doc error or their own misreading. The inline sentence still tells them to delete it, so they are not blocked, but the elaboration they were sent to is not where they were sent.
- **Type:** CONTENT
- **Confidence:** CONFIRMED
- **Evidence:** Internal contradiction: line 322 "(Section 9)" vs the deletion step at lines 685-695 under "## **10. Maintenance**" → "### **The temporary directory**". `grep -nE 'delete the directory yourself|rm -rf temporary/' SOP_CONCOMPRA_NeSI.md` → 687, 691 (both inside §10). §9 headings (grep) carry no deletion step.
- **Fix:** Change the parenthetical on line 322 from `(Section 9)` to `(Section 10)`:
  > Delete `temporary/` yourself once the analysis is final (Section 10).

## Verified against the suite

Probes run 2026-08-04 from the repo root, `SOP_CONCOMPRA_NeSI.md` at 765 lines.

- **All 12 internal anchor links resolve** (`grep -noE '\]\(#[^)]*\)'` → 12; each slug matched to a heading): `#6-verifying-the-run` (→ "## 6. Verifying the Run", L366), `#appendix-a-silva-sintax-database-build` (→ L698), `#empty-consensus-output` (→ L641), `#threads` ×3 (→ "### Threads", L293), `#9-troubleshooting` (→ L639), `#screen` (→ L168), `#deduplicate` (→ L187), `#run-configuration-file` (→ L251), `#primer-file` (→ L275). **0 broken** (00_FACTS independently confirmed `#threads` and `#appendix-a-…`).
- **Every cross-document pointer resolves.** CONCOMPRA:17 "Section 1 of `SOP_EMU_NeSI.md`" → EMU §1; the "Part 2 / data-loading step (Section 3)" pointers (596, 627) → R_Analysis §3 (both per 00_FACTS cross-reference sweep, RESOLVES).
- **README ↔ CONCOMPRA agree.** README:54 CONCOMPRA tool row (`Miniforge3/25.3.1-0`, `SeqKit/2.4.0`, `VSEARCH/2.21.1-GCC-11.3.0`, `MAFFT/7.505-…`, `FastTree/2.1.11-…`, `seqtk/1.4-…`) matches every `module load` in the document (L111, L191, L477-480, L732). README:26 description ("reference-free consensus OTUs … install, dedup, run configuration, submission, verification, then SINTAX, MAFFT, FastTree … Takes Part 1's filtered reads … hands off to Part 2") is true of the body. The old seqkit-omission seam (synthesis F-03) is closed.
- **No figures at all** (`grep -nE '!\[|<img'` → none), so CONCOMPRA carries none of the four broken `github.com/user-attachments` images that afflict EMU (00_FACTS). Its plottable output (`cluster_plots.pdf`, the tree) is a diagnostic and a Part-2 input, not an SOP figure — appropriately unembedded (see Divergence).
- **Shipped-script promise kept.** Appendix A links `reformat_silva_for_sintax.py` (L711) as repo-committed; `ls` → present (4991 B, per 00_FACTS). The old "described but never provided" open question (synthesis) is resolved.
- **Appendix lettering is clean** (A then B; no skipped letter), unlike READBASED's A→C.
- **NOT-VERIFIABLE-HERE seam (cross-document, cannot open EMU per brief):** Appendix A tells the reader to `cd /nesi/project/<code>/databases/emu/silva/` (L723) — "the directory that holds Emu's `species_taxid.fasta`". Whether that literal path matches where `SOP_EMU_NeSI.md` actually installs its SILVA bundle is unverifiable from this file (the path is asserted only here; CONCOMPRA's own Locations table, L88-95, never establishes it). Settles in ~10 s for anyone allowed to read EMU: `grep -nE 'databases/emu/silva|species_taxid.fasta' SOP_EMU_NeSI.md`. Credit structure round S-02, which chose this path; flag to the orchestrator to confirm it against EMU.

## Regressions — prior fixes that did not land

**None.** I checked the two prior rounds' fix sets against the current file:

- **Correctness round (reviews/CONCOMPRA.review.md), F-01…F-10 — all landed.** F-01 §4.3 is now "Run configuration file" with the `source`/glob explanation and the `MIN`/`MAX` config table (L251-273); F-02 primer headers are `>head_27F`/`>tail_1492R` with the write step (L275-291); F-03 submitted-count is `ls *.fastq | wc -l` (L385); F-04 seqkit availability note present (L191); F-05 Threads wording corrected (L295); F-06 wrapper runs `bash ./main.sh` (L349); F-07 label is "OTU × sample count matrix (rows = OTUs, columns = samples)" (L408); F-08 troubleshooting causes corrected + relinked to `#run-configuration-file` (L645-649); F-09 main-run script is `05_concompra.sh` for Section 5 and the phantom dedup script is gone; F-10 main-run header is `#!/bin/bash` + `set -euo pipefail` (L331, L341).
- **Structure round (reviews/structure/CONCOMPRA.md), S-01…S-15 — all landed.** §1 "Understanding your data" concepts section (L53-79); conda gloss (L86); build runtime + verify-mismatch clauses (L123, L134); §7 conceptual lead-in (L434-440); GTR/bootstrap gloss (L521); ASV gloss + `prv_cut=0.05` default (L633); chimera-pointer made actionable (L424); phantom `03_dedup.sh` removed from the tree; §5↔§10 `temporary/` de-duplicated (L685-695 now cross-refs §5); §7 header space-separated + `--chdir` (L460-467); opening paragraph and wrapper paragraph split (L7-9, L352-354); "Optional —" alias (L136).
- **Keep-list regression test — 17/17 survive.** Every load-bearing anchor from both rounds' keep lists still `grep -Fc`s to exactly 1 (see Keep list). No "why this number" or silent-failure passage was thinned by the rewrites. Zero load-bearing content struck.

## Keep list

The load-bearing passages a future rewrite must not lose (each verified `grep -Fc` = 1 today):

1. `never from the` — verify consensus on disk, not the `.out` log (the document's silent-failure spine).
2. `does not stop the script or change its exit code` — §6 "main.sh has no set -e" framing.
3. `the filter drops **every** read, silently` — unset `MIN`/`MAX` discards every read.
4. `not the reverse-complement` — 1492R must be the forward-strand sequence.
5. `silently corrupts taxonomy at low-confidence ranks` — SINTAX take column 4, not column 2.
6. `standard SINTAX bootstrap threshold` — the 0.8 cutoff rationale.
7. `Do not replace or downgrade filtlong` — pinned-version lock reasoning.
8. `one metadata sheet cannot serve both pipelines` — strip `.CONCOMPRA`/`_filtered` or Emu/CONCOMPRA cannot be compared.
9. `often genuine rare taxa` — `prv_cut` may discard real signal for consensus OTUs.

## Divergence from the set

Raw material for the coherence owner (Agent B); each is a convention CONCOMPRA sets that a single manual would reconcile across all five.

- **Part-numbering scheme (see C-01).** Two docs numbered (Part 1/Part 2), three unnumbered (CONCOMPRA, READBASED, ASSEMBLY all "hand off to Part 2" with no number of their own). The scheme does not scale to four-upstream-into-one; CONCOMPRA is one instance. A suite-wide decision is needed.
- **Version scheme.** CONCOMPRA is v2.1; the five headers carry five independent versions (EMU v2.0, CONCOMPRA v2.1, READBASED v3.0, R_Analysis v2.1, ASSEMBLY v0.1) and there is no suite version. README's footer still says "**four** SOPs" (README.md:120) against five on disk. This is the settled calibration item **C-00** and 00_FACTS "self-count drift" — owned at the set level, not re-filed here.
- **Roadmap numbering (see C-02).** CONCOMPRA is the one document still using "Stage" labels (in its roadmap) after the set retired them in the R_Analysis renumber.
- **Troubleshooting home and name.** CONCOMPRA puts troubleshooting in a numbered body section, "## 9. Troubleshooting", before Maintenance and the appendices. The set is inconsistent about this (R_Analysis "Troubleshooting and common pitfalls"; READBASED's triage lives in an appendix). One home, one name is a set decision.
- **Figure strategy.** CONCOMPRA embeds zero figures; R_Analysis embeds 14 local PNGs; EMU embeds four remote PNGs that 404. Three strategies across the suite. CONCOMPRA's "none" is the safe one for a cluster runbook (its plots are diagnostics / Part-2 inputs), so no finding — but the set should pick one policy.
- **No table of contents.** 765 lines with a 6-step ASCII roadmap but no linked TOC. Under the 1000-line bar and GitHub auto-generates a heading menu, so not filed; flagged only so Agent B can decide one TOC policy for the set.
- **Heading case.** CONCOMPRA is internally consistent (## sections Title Case except the spec-template §1 "Understanding your data"; ### subsections sentence case), but the structure plan's stated decision was "bold title-case everywhere." The set standard is itself unsettled (the spec template and R_Analysis's new §1 use sentence case), so this is a set decision, not a CONCOMPRA defect.

## Release recommendation

**Ready-with-listed-fixes.** CONCOMPRA is shippable on its own terms: it has no ship-blocker (S1 = 0), every promise it makes to the reader resolves, no load-bearing content regressed across two rewrite rounds, and its one shipped-script and all cross-references land. A new student cloning the repo can run this pipeline end-to-end and hand off to Part 2. The three listed fixes are coherence-and-navigation debt, not correctness: C-03 (one wrong section number) is a one-word edit and should ship; C-02 (roadmap Stage→Section) is a paste-in roadmap replacement; C-01 (no Part label) is real but its resolution is a suite-level scheme decision the coherence owner must make — the paste-ready interim removes the reader-hit meanwhile. One residual seam is outside my reach: the Appendix A Emu-SILVA path (`databases/emu/silva/`) must be confirmed against `SOP_EMU_NeSI.md`'s actual install location before ship. The suite-level items CONCOMPRA merely embodies — the Part scheme, the missing suite version, the "four SOPs" footer, the missing `LICENSE` the README points at — are the coherence owner's to close, credited to the calibration finding, 00_FACTS, and the structure round respectively.

---

### Self-check

```
findings=3 S1=0 S2=1 S4=0
CLEAN
```

By hand, the three the script cannot check:
- [x] Ledger accounts for every heading in the file — every `##`/`###` heading has a row (front-matter title/roadmap grouped with their blocks); verified against `grep -nE '^#{1,4} '`.
- [x] No proposed cut touches load-bearing content — the three fixes add/relabel/repoint; nothing on the Keep list is removed (17/17 anchors intact).
- [x] Every NOT-VERIFIABLE-HERE is genuinely not verifiable here — the sole one (Emu SILVA path) requires reading `SOP_EMU_NeSI.md`, which the brief forbids; the settling command and its ~10 s cost are given.

CONTRACT: PASS
