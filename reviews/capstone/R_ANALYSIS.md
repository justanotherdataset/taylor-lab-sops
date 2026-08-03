## Document: SOP_R_Analysis.md

Part 2 of the suite: a platform-agnostic R walkthrough from combined count tables
to publication figures and statistics. Measured now: **1411 lines, v2.1, "last
updated July 2026," self-labelled "Part 2"** — the longest document in the suite.

Read as a shippable deliverable, the technical body is in excellent shape. **All
five prior-round fixes landed** (F-01 pairwise.adonis2, F-02 pcoa_ait ordering,
F-03 devtools, F-04 "7 sample variables", F-05 Stage-5 heading) and **the whole
structure-round rewrite landed** (Stage→Section 1–13 renumber, "Before You Start",
"Understanding Your Data", Appendices A/B/C, runtimes, the prevalence-method and
phyloseq glosses). No keep-list content was lost — every load-bearing guard is
present (verified below). **No S1.** Every cross-reference resolves, every embedded
figure is on disk, the version and appendices are internally consistent.

What treating it as *finished* exposes is at the seams and in the parts no round
has seen: the **"Part 2" label** no longer describes a four-upstream/one-downstream
suite (S2); a **whole worked-example apparatus** — Section 12 (SPIEC-EASI) plus 14
figures on the public GlobalPatterns dataset — **was added after every review and
ships uncleared**, and it introduces a **tuatara-code / GlobalPatterns-figure split**
the reader must reconcile unaided; there is **no table of contents** in a 1411-line
file; and **14 orphan assets** sit under `examples/` with the embed numbering
skipping 14 and jumping to 15.

## Section ledger

| § | Heading | Lines | Treatment | Findings |
|---|---|---|---|---|
| — | Title + version + intro (Part 2 / tuatara vs figures) | 1–9 | RELABEL | C-01, C-02 |
| ### | Before You Start (+ Worked-example note L18) | 11–20 | REWRITE-TIGHTER | C-02, C-04 |
| ## | Quick Roadmap: What You'll Do | 22–49 | ADD-NAV | C-04 |
| ## | 1. Understanding Your Data | 52–82 | CLEAN | — |
| ## | 2. Install and Load Packages | 85–127 | CLEAN | C-06 |
| ## | 3. Load and Prepare Your Data | 129–273 | FIX-REF | C-07 |
| ## | 4. Remove Contaminants and Build ps_raw | 275–350 | FIX-FIGURE | C-02 |
| ## | 5. Explore Your Data Before Analysis | 352–431 | FIX-FIGURE | C-02 |
| ## | 6. Normalise to ps_srs | 433–526 | FIX-FIGURE | C-02 |
| ## | 7. Alpha Diversity | 528–637 | FIX-FIGURE | C-02 |
| ## | 8. Beta Diversity | 639–643 | CLEAN | — |
| ### | Step 1: Distance Matrices | 645–670 | CLEAN | — |
| ### | Step 2: Ordination | 672–759 | FIX-FIGURE | C-02 |
| ### | Step 3: Check Dispersion | 761–864 | FIX-FIGURE | C-02 |
| ### | Step 4: PERMANOVA | 866–917 | FIX-FIGURE | C-02 |
| ### | Step 5: Pairwise PERMANOVA (for >2 Groups) | 919–954 | CLEAN | — |
| ### | Step 6 (Optional): Jaccard as a Third Lens | 956–987 | CLEAN | — |
| ## | 9. Taxonomy Barplots | 989–1028 | FIX-FIGURE | C-02 |
| ## | 10. Differential Abundance | 1030–1033 | CLEAN | — |
| ### | Why You Can't Test Each Taxon on Its Own | 1034–1053 | CLEAN | — |
| ### | Differential Abundance with ANCOM-BC2 | 1055–1115 | FIX-FIGURE | C-02 |
| ### | Differential Abundance with MaAsLin2 | 1117–1194 | CLEAN | — |
| ## | 11. Indicator Species | 1196–1250 | FIX-FIGURE | C-02 |
| ## | 12. Co-occurrence Networks (optional) | 1252–1316 | REWRITE-TIGHTER | C-03, C-05, C-08 |
| ## | 13. Figures and Reproducibility | 1318–1319 | CLEAN | — |
| ### | Figures | 1320–1333 | FIX-FIGURE | C-02 |
| ### | Reproducibility | 1335–1343 | CLEAN | — |
| ## | Troubleshooting and Common Pitfalls | 1345–1373 | CLEAN | — |
| ## | Appendices | 1375–1376 | CLEAN | — |
| ### | Appendix A: References | 1377–1387 | CLEAN | — |
| ### | Appendix B: Normalisation Methods | 1389–1397 | CLEAN | — |
| ### | Appendix C: Thresholds and Resource Figures | 1399–1411 | CLEAN | — |

## Findings

### C-01 · S2 · "Part 2" title assumes a linear two-part suite, not four upstreams into one
- **Where:** SOP_R_Analysis.md, § Title (line 3); and every SOP header + README.md
- **Anchor:** `Part 2: R Analysis (Count Tables to Results)`
- **Quote:**
  > # **Part 2: R Analysis (Count Tables to Results)**
  > …
  > This document starts from the combined count tables produced upstream. For the Nanopore amplicon pipeline see `SOP_EMU_NeSI.md`, or `SOP_CONCOMPRA_NeSI.md` for consensus OTUs; for Illumina shotgun see `SOP_READBASED_NeSI.md`…
- **Defect:** The document is titled "Part 2" and EMU is "Part 1", but the suite now
  has **five** SOPs and this one is the single R endpoint that **four** upstream
  cluster documents (EMU, CONCOMPRA, READBASED, ASSEMBLY) feed into. Only EMU and
  this file carry a "Part N" label; CONCOMPRA, READBASED and ASSEMBLY carry none.
  "Part 2" describes a linear Part 1 → Part 2, which stopped being the shape of the
  suite once there were multiple upstreams.
- **Impact:** A student doing Illumina shotgun follows the README to
  `SOP_READBASED_NeSI.md` (no "Part" label), finishes it, is sent here, and opens a
  document headed "Part 2" — Part 2 of what? They never did a "Part 1"; theirs was
  the read-based SOP. Same for a CONCOMPRA or ASSEMBLY reader. The label reads as a
  broken sequence for three of the four upstream paths, and the suite reads as
  loose files rather than one manual.
- **Type:** COHERENCE
- **Confidence:** CONFIRMED
- **Evidence:** Title line 3 ("Part 2") and intro line 7 (four upstream documents
  feed here). `reviews/capstone/00_FACTS.md` (suite-facts table): EMU self-labels
  "Part 1", R_Analysis "Part 2", CONCOMPRA/READBASED/ASSEMBLY "(no Part label)";
  the README's "Which SOP do I need?" table enumerates all five. The prior rounds
  treated the set as four documents (`00_FACTS.md`: README footer "four SOPs",
  TUTORIAL_SPEC "four documents", ASSEMBLY unmentioned), so this seam is not closed.
- **Fix:** Decide one scheme suite-wide (Agent B / README owner to ratify), then
  make headers consistent. Recommended: **drop the bare "Part 1/Part 2" numbering**
  and let each document's descriptor line carry the role. On this file, replace the
  title and add a one-line locator:
  > # **R Analysis: Count Tables to Results**
  >
  > **v2.1** | last updated August 2026 | runs locally in R, not on NeSI | platform-agnostic
  >
  > This is the shared downstream step for every pipeline in this suite: whichever
  > upstream SOP produced your count table (Emu, CONCOMPRA, read-based shotgun, or
  > assembly), the analysis continues here.
  Files the fix edits: `SOP_R_Analysis.md` (title), `SOP_EMU_NeSI.md` (drop "Part 1"),
  `README.md` (drop "Part 1"/"Part 2" prose in the routing and coverage tables), and
  — if any survive — the "Part 2 …" pointers in `SOP_CONCOMPRA_NeSI.md` and
  `SOP_READBASED_NeSI.md`.

### C-02 · S3 · Worked example splits identity: tuatara code and prose vs GlobalPatterns figures
- **Where:** SOP_R_Analysis.md, § intro + Before You Start (lines 9, 18); figures throughout
- **Anchor:** `The examples use Cam's tuatara PhD data`
- **Quote:**
  > The examples use Cam's tuatara PhD data, so the variable names (Site, Sex, Species) and site names (Takapourewa, Zealandia, YoungNicksHead) are specific to that study. Adapt all variable names to your own metadata.
  > …
  > **Worked example.** Every figure below is real output from running this workflow on the public **GlobalPatterns** 16S dataset (Caporaso et al. 2011), grouped into three environments (Human, Freshwater, Saline).
- **Defect:** The document runs two example identities at once. All **code and
  prose** use tuatara names (`~ Site`, levels Takapourewa/Zealandia/YoungNicksHead;
  `diff_SiteZealandia`; the Reporting sentence at L917), but every **figure and its
  caption** is from GlobalPatterns (Human/Freshwater/Saline). Line 9 flatly says
  "The examples use … tuatara PhD data"; the figures are not tuatara. The split is
  disclosed only in one clause at L18 ("only the grouping variable is adapted"), and
  the two identities give conflicting numbers for the same step — e.g. the Section 8
  Reporting template says "PERMANOVA: R² = 0.38 … Aitchison R² = 0.35" (L917) while
  the adjacent figure caption says "R² = 0.28 and 0.48, both p = 0.0001" (L745).
- **Impact:** A student reads the Reporting box ("R² = 0.38, p = 0.02"), looks at
  the PCoA figure caption directly below the code ("R² = 0.28 and 0.48, p = 0.0001"),
  and cannot tell which is the exemplar for their own output — two different "worked"
  answers for one analysis. The same reader runs the shown ANCOM-BC2 code (which
  filters `diff_SiteZealandia`) and then reads its figure caption about "marine taxa
  higher in Saline, human commensals lower" (L1115): the code's levels and the
  figure's groups don't exist in the same dataset. It resolves, but costs orientation
  at every figure.
- **Type:** CONTENT
- **Confidence:** CONFIRMED
- **Evidence:** L9 (tuatara) vs L18 (GlobalPatterns figures) in the same file; the
  number contradiction L917 (`R² = 0.38 … 0.35`) vs L745 caption (`R² = 0.28 and
  0.48`); tuatara-level code at L1110 (`diff_SiteZealandia`) vs GlobalPatterns
  caption at L1115 (`Saline`, `human commensals`). This worked-example apparatus
  postdates the structure round (its R_ANALYSIS ledger lists no figures; its target
  outline made §12 "Figures and reproducibility"), so no round vetted the split.
- **Fix:** State the split once, unambiguously, and stop implying the prose numbers
  are the figure numbers. Replace L9 with:
  > The **code** examples use variable and site names from Cam's tuatara PhD study
  > (Site, Sex, Species; Takapourewa, Zealandia, YoungNicksHead) — adapt these to
  > your own metadata. The **figures** are real output from a different public
  > dataset (see Worked example below), so their captions name that dataset's groups
  > (Human, Freshwater, Saline), and any illustrative numbers in the prose — such as
  > the Reporting template in Section 8 — are placeholders that will not match the
  > figure captions.
  Then, at L917, mark the Reporting sentence explicitly as a template ("*Report in
  this form (numbers illustrative):*") so it is not read as the worked result.

### C-03 · S3 · Section 12 SPIEC-EASI and the 14 worked-example figures postdate every review
- **Where:** SOP_R_Analysis.md, § 12 Co-occurrence Networks + all figures + header (lines 1252–1316; 5; 18)
- **Anchor:** `## **12. Co-occurrence Networks (optional)**`
- **Quote:**
  > ## **12. Co-occurrence Networks (optional)**
- **Defect:** Section 12 (SPIEC-EASI, ~65 lines) and the entire 14-figure worked
  example were added **after** every prior round and have been reviewed by no one.
  The structure round's target outline placed "Figures and reproducibility" at §12
  and named no §12 network section; its R_ANALYSIS ledger lists zero figures. Yet
  the header still reads **"v2.1 | last updated July 2026"** with no changelog line
  recording the August additions, so the document presents newer-than-reviewed
  content as if it carried the same July sign-off as the rest.
- **Impact:** The target reader trusts every word equally and cannot tell reviewed
  content from unreviewed. Section 12 already ships with at least one visible slip
  (its package count, C-08), which is exactly what an unreviewed section is expected
  to carry; a correctness reviewer never checked its `spiec.easi()` parameters,
  StARS claim, or the figure it embeds. A section going to a new student labelled
  "ready" that no round has read is the failure this review exists to catch.
- **Type:** CONTENT
- **Confidence:** CONFIRMED
- **Evidence:** `reviews/structure/R_ANALYSIS.md` target outline (§12 = "Figures and
  reproducibility"; no SPIEC-EASI; Keep-list and ledger name no figures) vs the
  current file where §12 is "Co-occurrence Networks" (line 1252) and 14 figures are
  embedded. `reviews/capstone/00_FACTS.md` records the figures and the SPIEC-EASI
  embed as current-state additions. Header line 5 still says "July 2026".
- **Fix:** Before release: have a reviewer read §12 and the 14 figures against this
  SOP's own guards (compositionality, raw-vs-normalised object rule, expected-output
  discipline) and against the environment probe. Then update the header and record
  the addition:
  > **v2.1** | last updated August 2026 | runs locally in R, not on NeSI | platform-agnostic
  >
  > *Changelog: Aug 2026 — added Section 12 (co-occurrence networks, SPIEC-EASI) and
  > the GlobalPatterns worked example (Sections 3–13 figures); reviewed <date>.*

### C-04 · S3 · No table of contents in the suite's longest document (1411 lines)
- **Where:** SOP_R_Analysis.md, § Quick Roadmap + whole document (lines 22–49)
- **Anchor:** `## **Quick Roadmap: What You'll Do**`
- **Quote:**
  > ## **Quick Roadmap: What You'll Do**
- **Defect:** At 1411 lines this is the longest document in the suite and has no
  table of contents and no in-page anchor links. The "Quick Roadmap" is a workflow
  diagram (it covers only §§2–12, omits §1, §13, Troubleshooting and the three
  Appendices, and carries no links), not a navigable index.
- **Impact:** A student who reads "see Troubleshooting" (L15, L48), "in Appendix B"
  (L446), or "Section 12 demonstrates SPIEC-EASI" (L1051) has no way to jump there
  and must scroll a 1400-line file hunting the heading — repeatedly, since the
  document cross-references its own sections a dozen times. Recoverable, but it costs
  the reader on every internal pointer.
- **Type:** LAYOUT
- **Confidence:** VERIFIED
- **Evidence:** `grep -niE "table of contents|^\s*-\s*\[.*\]\(#|contents" SOP_R_Analysis.md`
  → no match (no TOC, no anchor-link list). `wc -l` = 1411.
- **Fix:** Add a linked contents block immediately after the version line, before
  "Before You Start" (GitHub renders `[text](#slug)` against heading slugs):
  > ## Contents
  > 1. [Understanding Your Data](#1-understanding-your-data) · 2. [Install and Load Packages](#2-install-and-load-packages) · 3. [Load and Prepare Your Data](#3-load-and-prepare-your-data) · 4. [Remove Contaminants and Build ps_raw](#4-remove-contaminants-and-build-ps_raw) · 5. [Explore Your Data](#5-explore-your-data-before-analysis) · 6. [Normalise to ps_srs](#6-normalise-to-ps_srs) · 7. [Alpha Diversity](#7-alpha-diversity) · 8. [Beta Diversity](#8-beta-diversity) · 9. [Taxonomy Barplots](#9-taxonomy-barplots) · 10. [Differential Abundance](#10-differential-abundance) · 11. [Indicator Species](#11-indicator-species) · 12. [Co-occurrence Networks](#12-co-occurrence-networks-optional) · 13. [Figures and Reproducibility](#13-figures-and-reproducibility) · [Troubleshooting](#troubleshooting-and-common-pitfalls) · [Appendices](#appendices)

### C-05 · S3 · 14 orphan figure assets on disk; embed numbering skips 14 and jumps to 15
- **Where:** SOP_R_Analysis.md, § 12 (line 1314); and examples/r_analysis/figures/
- **Anchor:** `15_spieceasi_network.png`
- **Quote:**
  > ![SPIEC-EASI co-occurrence network](examples/r_analysis/figures/15_spieceasi_network.png)
- **Defect:** `examples/r_analysis/figures/` holds 29 files but the document embeds
  only 14 of them. Fourteen are orphans referenced by no document: `14_core_microbiome.png`
  (the SOP has no core-microbiome section) and all 13 `.svg` twins. The embed
  numbering is also discontinuous — it runs 01–13 then **skips 14 and uses 15** for
  the SPIEC-EASI figure — and the file numbers do not follow reading order (02 is
  embedded before 01, 05 before 04, 15 before 13).
- **Impact:** A student who clones the repo and opens the figures directory finds a
  `14_core_microbiome` figure (both PNG and SVG) with no section that uses it and 13
  SVGs the SOP never shows, and cannot tell whether they are meant to appear
  somewhere (did I miss a section? is a figure failing to render?) or are dead
  weight. To this reader an asset present but unreferenced is indistinguishable from
  a broken embed.
- **Type:** LAYOUT
- **Confidence:** VERIFIED
- **Evidence:** `ls examples/r_analysis/figures/` = 15 PNG + 13 SVG (29 files). Embedded
  in the SOP: PNG 01,02,03,04,05,06,07,08,09,10,11,12,13,15 (14). Orphans:
  `14_core_microbiome.png` + all 13 `.svg`. Matches `reviews/capstone/00_FACTS.md`
  ("14 orphan assets"). All 14 embedded PNGs `ls`-confirmed present (0 broken).
- **Fix:** Delete the 14 orphan assets, or, if the SVGs are the print masters, move
  them to a clearly-labelled subfolder (`figures/svg/`) referenced in
  `examples/r_analysis/README.md`. Either add a core-microbiome section that uses
  `14_core_microbiome.png` or delete it. Renumber `15_spieceasi_network.*` → `14_*`
  so the embedded set is contiguous (01–14) and update the embed at L1314 and
  `run_example.R`.

### C-06 · S4 · pairwiseAdonis install stays commented while its library() call runs live
- **Where:** SOP_R_Analysis.md, § 2 Install (lines 103–104); § 8 Step 5 (lines 924–925)
- **Anchor:** `pairwiseAdonis for post-hoc PERMANOVA comparisons`
- **Quote:**
  > # pairwiseAdonis for post-hoc PERMANOVA comparisons
  > # devtools::install_github("pmartinezarbizu/pairwiseAdonis/pairwiseAdonis")
- **Defect:** In the Section 2 install block `pairwiseAdonis`'s install is commented
  out (L104), and it is commented again at the point of use (L924), but the
  `library(pairwiseAdonis)` call at L925 is live. The optional-network package
  `SpiecEasi` two lines away (L112) has a **live** install, so the house style for
  "optional GitHub package" is applied inconsistently.
- **Impact:** A reader who ran the Section 2 block never installed `pairwiseAdonis`;
  reaching Section 8 Step 5 they run `library(pairwiseAdonis)` and hit "there is no
  package called 'pairwiseAdonis'". Recoverable (the commented install is on the
  line above), but it is the same trap the structure round fixed for `devtools`
  (F-03), reintroduced for a different package.
- **Type:** LAYOUT
- **Confidence:** CONFIRMED
- **Evidence:** L104 `# devtools::install_github("…/pairwiseAdonis")` (commented) and
  L924 (commented) vs L925 `library(pairwiseAdonis)` (live); contrast L112
  `devtools::install_github("zdk123/SpiecEasi")` (live) for an equally optional
  package.
- **Fix:** Match SpiecEasi — uncomment the Section 2 install so post-hoc PERMANOVA
  works without an extra step: change L104 to
  `devtools::install_github("pmartinezarbizu/pairwiseAdonis/pairwiseAdonis")`.

### C-07 · S4 · Loader comment names combine_emu_results.py without EMU's 04_ prefix
- **Where:** SOP_R_Analysis.md, § 3 (line 163); and SOP_EMU_NeSI.md
- **Anchor:** `Read in the combined counts table (from combine_emu_results.py)`
- **Quote:**
  > # Read in the combined counts table (from combine_emu_results.py)
- **Defect:** The loader comment attributes the input table to `combine_emu_results.py`,
  but Part 1 authors and calls that script as `04_combine_emu_results.py` (numeric
  prefix = defining section, the suite's own script-naming rule). The two documents
  name the same script differently.
- **Impact:** A student who saved the script per Part 1 has `04_combine_emu_results.py`
  on disk; this comment points at a file by a name they do not have. It is a comment,
  not a command, so nothing errors — but the naming inconsistency is exactly the kind
  of drift that makes a suite read as separate files.
- **Type:** COHERENCE
- **Confidence:** CONFIRMED
- **Evidence:** L163 uses `combine_emu_results.py`. `reviews/capstone/00_FACTS.md`
  ("Two script-naming defects"): EMU authors/calls it `04_combine_emu_results.py`
  everywhere; R_Analysis:163 omits the `04_` prefix.
- **Fix:** Change the comment at L163 to
  `# Read in the combined counts table (from 04_combine_emu_results.py)`.

### C-08 · S4 · Section 12 says "three extra packages" but four network packages load
- **Where:** SOP_R_Analysis.md, § 12 (line 1260); install block (110–112); library call (1263)
- **Anchor:** `needs three extra packages from Section 2, one GitHub-only`
- **Quote:**
  > This step is optional and needs three extra packages from Section 2, one GitHub-only (`SpiecEasi`).
- **Defect:** The network step installs and loads **four** extra packages —
  `igraph`, `ggraph`, `tidygraph` (CRAN) and `SpiecEasi` (GitHub) — not three. The
  sentence undercounts by one.
- **Impact:** A reader counting dependencies from this line prepares three packages,
  then meets `library(SpiecEasi); library(igraph); library(ggraph); library(tidygraph)`
  (four) and a four-package install block. Trivial, but a wrong count in a
  freshly-added section undermines confidence in the section.
- **Type:** CONTENT
- **Confidence:** CONFIRMED
- **Evidence:** Install block L110–112 lists `igraph, ggraph, tidygraph` + `SpiecEasi`
  (four); the `library()` call at L1263 loads four; the sentence at L1260 says
  "three … one GitHub-only".
- **Fix:** Change L1260 to: "This step is optional and needs four extra packages from
  Section 2 — `igraph`, `ggraph`, `tidygraph`, and the GitHub-only `SpiecEasi`."

## Verified against the suite

Probes run from the repo root on NeSI (2026-08-04). This document runs locally in R
by design, so package/runtime claims are unverifiable here (correctly — the reader
uses their own machine); everything checkable in the text and on disk was checked.

- **Line count / header:** `wc -l SOP_R_Analysis.md` → **1411**. Header (line 5):
  `**v2.1** | last updated July 2026 | runs locally in R, not on NeSI | platform-agnostic`.
- **Heading map** (`grep -nE '^#{1,6} '`): title, Before You Start, Quick Roadmap,
  **§§1–13**, Troubleshooting, Appendices A/B/C. Matches the ledger above.
- **Internal cross-references all RESOLVE.** `grep -noE "Section[s]? [0-9]+|Appendix [A-Z]|Step [0-9]+"`
  → every target exists: Sections 2,3,4,5,6,8,10,11,12,13 all present; Appendices A/B/C
  all present; Beta-diversity Steps 1–6 all present. `grep -nE "Section 1[4-9]|Section [2-9][0-9]|Appendix [D-Z]"`
  → **no dangling high-number reference.**
- **External cross-references RESOLVE** (`SOP_EMU_NeSI.md`; `SOP_CONCOMPRA_NeSI.md`
  Section 8, L147; `SOP_READBASED_NeSI.md` Section 13, L7/78/148) — confirmed against
  target heading maps in `reviews/capstone/00_FACTS.md` (CONCOMPRA §8 exists;
  READBASED §13 "Statistics: What Changes" exists).
- **All 14 embedded figures PRESENT on disk** (my `ls` of each
  `examples/r_analysis/figures/NN_*.png`): 01–13 and 15. **0 broken.** No remote/
  `<img>` figures in this document (`grep -niE '<img'` → none), so nothing dies on an
  offline clone.
- **14 orphan assets** confirmed by `ls examples/r_analysis/figures/`:
  `14_core_microbiome.png` + 13 `.svg` (C-05).
- **No TOC / no in-page anchor links** (`grep` for TOC markers → none) — C-04.
- **All five prior-round fixes landed:** F-01 pairwise.adonis2 (now L924–954 with the
  "does NOT adjust p-values" note + `adjust_pairwise` helper); F-02 pcoa_ait computed
  at L705 before the library-size diagnostic at L722; F-03 `install.packages("devtools")`
  live at L100; F-04 "7 sample variables" at L333; F-05 renumber to §§1–13 with Steps
  as `###`. **The structure-round rewrite landed** (Before You Start L11, Understanding
  Your Data §1, runtimes L127/753/896/1067, prevalence gloss L281, phyloseq gloss L60,
  Appendices A/B/C, ALDEx2 demoted to a run-in L1194). See Regressions (none).
- **Cross-document facts surfaced for the coherence owner** (not filed as findings
  against this file, since the corrective edit lives in README):
  `reviews/capstone/00_FACTS.md` records **README.md:12 as MIS-TARGETED** — "that
  SOP's Section 13" resolves under a literal read to *this* document's §13 ("Figures
  and Reproducibility"), not the intended READBASED §13. Raw material for Agent B /
  the README owner; credit Agent 0.

## Regressions — prior fixes that did not land

**None.** Every fix the correctness round (`reviews/R_ANALYSIS.review.md`, F-01…F-05)
and the structure round (`reviews/structure/R_ANALYSIS.md`, S-01…S-21) marked for
this file is present in the current text, verified by re-finding the anchor (above).
No keep-list item was dropped or thinned in the renumber — see Keep list.

## Keep list

The load-bearing passages a rewrite must not lose. All eight `grep -Fc` to exactly
one hit and are present in the current file.

1. `The one rule to remember` (L62) — the `ps_raw`/`ps_srs` object-discipline rule.
2. `this is a relative-abundance table, not counts` (L184) — the relative-abundance guard.
3. `index them POSITIONALLY` (L207) — positional-alignment warning + `stopifnot`.
4. `a stale ps_raw will run` (L502) — rebuild-`ps_raw`-after-depth-gate note.
5. `the figure is what goes into the thesis` (L559) — figure-vs-text p-value trap + `bracket_frame`.
6. `the true total is 4,000 cells but the instrument still returns` (L1040) — compositionality worked arithmetic.
7. `filtering before adjusting shrinks the number of tests` (L1233) — FDR-before-filtering warning (indicators).
8. `roughly 30 or more samples` (L1096) — `neg_lb`/structural-zero small-sample caution.

## Divergence from the set

Raw material for Agent B, who sets the house standard; I supply the evidence.

- **Version scheme.** This file is v2.1 / "July 2026". Across the set: EMU v2.0,
  CONCOMPRA v2.1, READBASED v3.0, R_Analysis v2.1, ASSEMBLY v0.1 (per `00_FACTS.md`) —
  five independent version numbers, no suite version, and the July date now predates
  this file's own August content (C-03). A single suite version/date would fix both.
- **Part-numbering scheme.** Only this file ("Part 2") and EMU ("Part 1") carry Part
  labels; three siblings carry none (C-01). Either all upstreams get a role label or
  none do.
- **Figure strategy.** This is the only document with a local worked-example figure
  set (14 PNGs). EMU uses remote `github.com/user-attachments` `<img>` (all 404,
  off-repo, per `00_FACTS.md`); the cluster docs largely have none. Three figure
  strategies across the suite; this one (local, in-repo, renders offline) is the
  right model — but it needs the orphan/numbering cleanup (C-05) and captions carry
  no figure numbers, unlike a numbered-figure convention Agent B may choose to set.
- **Troubleshooting placement.** This file ends on "Troubleshooting and Common
  Pitfalls" before the Appendices — a clean, discoverable home. Whether every sibling
  uses that exact name and position is Agent B's call; this document is a good
  template for it.
- **Script naming.** The `combine_emu_results.py` vs `04_combine_emu_results.py`
  drift (C-07) is a one-file symptom of a suite-wide "number = section" rule that not
  every reference honours.

## Release recommendation

**Ready with the listed fixes — no ship-blocker, but not clean.** The technical body
is the strongest in the suite, every prior fix and rewrite landed, no keep-list
content was lost, there is no S1, and every cross-reference and embedded figure
resolves for someone who clones the repo cold. What stops a clean pass is that the
document's *finished-product* surface has moved ahead of its last review: a whole
Section 12 and a 14-figure worked example were added after every round and ship
uncleared under a stale "July 2026 / v2.1" header (C-03), carrying a tuatara-code /
GlobalPatterns-figure split the reader must reconcile alone (C-02) and at least one
visible slip (C-08); the file is labelled "Part 2" of a scheme the five-document
suite outgrew (C-01, S2); and for the longest document in the set there is no way to
navigate it (C-04) while 14 orphan assets and a broken figure-number sequence sit in
the example folder (C-05). Have a reviewer read Section 12 and the figures, fix the
S2/S3 items, and it ships.

## Self-check

```
findings=8 S1=0 S2=1 S4=3
CLEAN
```
(run output pasted below)

CONTRACT: PASS
