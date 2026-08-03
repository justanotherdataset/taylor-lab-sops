# 00 · Capstone Verdict — the five-document SOP suite as one product

**Agent B, on-cluster, 2026-08-04, from `/nesi/project/uoa03769/taylor-lab-sops`.**
Written after reading the COMMON BRIEF, both prior rounds
(`reviews/00_SYNTHESIS.md`, `reviews/00_ENVIRONMENT.md`,
`reviews/structure/00_PLAN.md`, `reviews/structure/00_REALITY.md`), Agent 0's
facts (`reviews/capstone/00_FACTS.md`), all five Agent A reports
(`EMU.md`, `CONCOMPRA.md`, `READBASED.md`, `R_ANALYSIS.md`, `ASSEMBLY.md`), and
all five source SOPs plus `README.md` and `TUTORIAL_SPEC.md` in the parts each
finding touches. Every A-report claim ranked below was re-checked against the
source or the cluster before it was carried; the probes are in *Verified this
round*. Line numbers are my own current read.

I am the only agent that saw the whole repository. This file de-duplicates the
five reports, re-ranks severity **globally**, resolves the two open cross-document
seams (CONCOMPRA↔EMU SILVA path; README §13 mis-route), and produces one plan and
one verdict — the artefact Stage 4 executes.

---

## State of the suite

Measured, not quoted (`wc -l`, header line, `git log`). "Reviewed by" is which of
the three rounds has actually read the file: **C** = correctness
(`reviews/*.review.md`), **S** = structure/voice (`reviews/structure/*`), **★** =
this capstone.

| File | Lines | Version | Date | Reviewed by | Note |
| --- | --- | --- | --- | --- | --- |
| `SOP_EMU_NeSI.md` | 1019 | v2.0 | Jul 2026 | C · S · ★ | "Part 1". Strongest teaching doc; four QC figures 404/off-repo (C-01). |
| `SOP_CONCOMPRA_NeSI.md` | 764 | v2.1 | Jul 2026 | C · S · ★ | No Part label. Cleanest member; S1 = 0. |
| `SOP_READBASED_NeSI.md` | 1028 | v3.0 | Jul 2026 | C · S · ★ | No Part label. Structure rewrite **deleted an appendix** the round marked KEEP (C-02, regression). |
| `SOP_R_Analysis.md` | 1411 | v2.1 | Jul 2026 | C · S · ★ | "Part 2". Longest doc. §12 + 14 figures added **after** C and S; ship uncleared (C-10). |
| `SOP_ASSEMBLY_NeSI.md` | 985 | v0.1 | Aug 2026 | **★ only** | No Part label. **Never through C or S.** Carries a silent empty-taxonomy bug (C-04). |
| `README.md` | 120 | — | footer "Jul 2026 · four SOPs" | — | Router. Footer count stale (C-06); one routing cell mis-targets §13 (C-08). |
| `TUTORIAL_SPEC.md` | 333 | — | — | — | The contract. Scoped to "four documents"; never names ASSEMBLY; audience clause ASSEMBLY violates (C-11). |

Five SOPs on disk; five uncoordinated version numbers; no suite version anywhere.
Two of the five documents carry content no correctness round has seen: all of
ASSEMBLY, and R_Analysis §12 + its 14-figure worked example.

---

## The ship verdict

**SHIP-WITH-FIXES — conditional, with `SOP_ASSEMBLY_NeSI.md` held as NOT-READY.**

The four reviewed documents (EMU, CONCOMPRA, READBASED, R_Analysis) become
shippable once the four S1 blockers below and the S2 coherence pass land — every
blocker has a concrete, paste-ready fix and the technical core is sound (both
prior rounds proved it). But the suite **cannot ship as five equal peers today**:

- One member (`SOP_ASSEMBLY_NeSI.md`, v0.1) has been through **neither** dedicated
  review round, is routed to new students by the README with no draft marker, and
  carries at least one silent-wrong-output bug this capstone is the first to find.
  Per the brief, an unreviewed member caps the suite at **SHIP-WITH-FIXES** and its
  status must be named: **ASSEMBLY is NOT-READY.** It must be either (a) removed
  from the README routing table, or (b) explicitly marked *draft* and gated, and
  then run through `prompts/SOP_REVIEW_PROMPT.md` **and** a tutorial round before it
  ships as a peer. A capstone pass is not a substitute (Assembly agent's call,
  which I uphold — I re-verified its ship-blocker C-04 against the installed
  module).

So: **ship the four reviewed docs with the listed fixes; hold ASSEMBLY.**

### The S1 findings that justify the verdict

- **C-01** — EMU's four QC figures are off-repo `github.com/user-attachments/…`
  `<img>` links, all HTTP 404; render as broken images for every cloner.
- **C-02** — READBASED's structure rewrite **deleted** "Appendix A: Submission
  Chain" (marked KEEP), orphaning three `--dependency=afterok` cross-refs and
  dangling one code-comment pointer. **Regression.**
- **C-03** — ASSEMBLY (unreviewed v0.1) is routed to new students as a peer with no
  draft marker.
- **C-04** — ASSEMBLY §11 globs the wrong GTDB-Tk directory, so every MAG's
  taxonomy ships blank into Part 2. **Silent empty output.**

---

## Ship-blockers

Globally ranked, then document order. Full nine-field blocks.

### C-01 · S1 · EMU's four QC figures are off-repo GitHub links that 404 for every cloner
- **Where:** SOP_EMU_NeSI.md, § 3 Steps 2 & 4 (lines 399, 405, 537, 543); examples/
- **Anchor:** `3caf1fec-5796-4595-becc-07a36e956379`
- **Quote:**
  > <img width="700" height="500" alt="Read length histogram, raw" src="https://github.com/user-attachments/assets/3caf1fec-5796-4595-becc-07a36e956379" />
- **Defect:** EMU's only four figures — the raw/filtered read-length histograms and length-vs-quality scatters, the visual heart of a QC document — are remote `<img>` tags to `github.com/user-attachments/…`. All four 404, and even a 200 would not survive a clone: the assets live outside the repository. The document has zero working figures.
- **Impact:** A student clones the repo cold, reaches Step 2 ("Two plots to check first") and Step 4 (caption: "the single most informative NanoPlot output"), and sees four broken-image icons. To this reader a figure that will not load is indistinguishable from their own mistake; they cannot calibrate their own NanoPlot output against the expected shape.
- **Type:** CONTENT
- **Confidence:** VERIFIED
- **Evidence:** `curl -sI --max-time 25` on the first URL 2026-08-04 → `HTTP/2 404` (`server: github.com`); Agent 0 recorded 404 on all four. `find examples -iname '*emu*'` → nothing; `find examples -maxdepth 2 -type d` → only `examples/r_analysis/`. EMU has no in-repo figures; R_Analysis embeds 14 local PNGs. So the assets exist nowhere retrievable.
- **Fix:** Adopt R_Analysis's in-repo strategy (the suite figure standard, *Convention decisions* below). Regenerate the four PNGs from the worked-example run (the NanoStats blocks already in EMU §3 lines 377–393, 517–533), commit them under `examples/emu/figures/`, and replace the four remote `<img>` tags with local markdown:
  - line 399 → `![Read length histogram, raw reads](examples/emu/figures/raw_read_length_histogram.png)`
  - line 405 → `![Read length vs mean quality, raw reads](examples/emu/figures/raw_length_vs_quality.png)`
  - line 537 → `![Read length histogram, filtered reads](examples/emu/figures/filtered_read_length_histogram.png)`
  - line 543 → `![Read length vs mean quality, filtered reads](examples/emu/figures/filtered_length_vs_quality.png)`
  Hard ship-gate: it requires producing image files that do not exist anywhere today.

### C-02 · S1 · READBASED rewrite deleted the Submission-Chain appendix, orphaning three afterok pointers
- **Where:** SOP_READBASED_NeSI.md, §§ 5 & 7 and back-matter (lines 265, 275, 462, 622; appendices 986, 1010)
- **Anchor:** `must not start until this finishes — see Appendix A`
- **Quote:**
  > `scripts/07a.host_index.sl` (no array). The filter must not start until this finishes — see Appendix A:
- **Defect:** Three references (lines 265, 275 for MultiQC waiting on the FastQC array; line 462 for `07b.host_filter.sl` waiting on `07a.host_index.sl`) send the reader to "Appendix A" for the `--dependency=afterok` / `--parsable` job-dependency chain. But Appendix A is now "Triage" (line 986); the appendices run A, then C (1010) — no B — and there is no Submission-Chain appendix or `afterok` example anywhere. The P3 rewrite (commit `82e61b6`) deleted "Appendix A: Submission Chain", relabelled the old "Appendix B: Triage" to A, and left Resources at C. Line 622's code comment still points to "Appendix B", which no longer exists.
- **Impact:** A first-time reader at §5 is told to submit MultiQC "as a dependent job … (Appendix A)" — the doc's own warning is that any other way yields a green-exit report that is silently incomplete. They open Appendix A to learn the syntax, find "Triage", and have nowhere that shows `sbatch --parsable … --dependency=afterok:$JOBID`. Worse at §7 Option B: line 462 says `07b` "must not start until this finishes"; a reader who cannot find the ordering submits `07b` against a half-built index and gets corrupt or failed depletion. Promised content the reader cannot reach — the exact failure this review outranks.
- **Type:** CONTENT
- **Confidence:** CONFIRMED
- **Evidence:** File contradicts itself, corroborated by git. Current: `grep -nE '^#+ .*Appendix'` → `986:## **Appendix A: Triage**`, `1010:## **Appendix C: Resources**`; `grep -c 'Submission Chain'` → 0; pointers live at 265/275/462 ("Appendix A") and 622 ("Appendix B"). Original: `git show a9a6336:SOP_READBASED_NeSI.md | grep -nE '^#+ .*Appendix'` → `805:## **Appendix A: Submission Chain**`, `836:## **Appendix B: Triage**`, `860:## **Appendix C: Resources**`. The structure round marked it **KEEP** (`reviews/structure/READBASED.md`). Both settled rounds reviewed the file *before* the deletion.
- **Fix:** Restore the appendix (recovered verbatim from `a9a6336` by the READBASED agent; all nine script names `05a`…`10` match the current doc) as **Appendix A: Submission Chain**, re-letter the current "Appendix A: Triage" → **Appendix B: Triage**, leave "Appendix C: Resources" as C. Insert immediately before line 986, replacing the stray blank lines 983–985 with a single blank line. This makes the 265/275/462 "(Appendix A)" pointers land on the chain, and the line-622 "(Appendix B)" pointer land on Triage — closing both the regression and the A→C lettering gap in one edit. (The full restored block is in `reviews/capstone/READBASED.md` §C-01 Fix.)

### C-03 · S1 · Unreviewed v0.1 ASSEMBLY is routed to new students as a reviewed peer
- **Where:** SOP_ASSEMBLY_NeSI.md, § header (line 5); README.md, § Which SOP do I need? (line 14) and footer (line 120)
- **Anchor:** `**v0.1** | last updated August 2026`
- **Quote:**
  > **v0.1** | last updated August 2026 | NeSI (SLURM) | Illumina paired-end
- **Defect:** This document has been through neither `SOP_REVIEW_PROMPT.md` nor a tutorial round — the two that produced the siblings' v2.0–v3.0 — yet the README routes a shotgun-MAG reader straight into it as an equal path (line 14, no caveat) and nothing the reader sees flags it as draft. The suite's own footer still says "four SOPs" reviewed, silently excluding it.
- **Impact:** A student with shotgun data reads the README, is sent to `SOP_ASSEMBLY_NeSI.md`, and follows it word-for-word trusting it like the others — including defects this capstone is the first to find (C-04 hands Part 2 an empty taxonomy). To that reader `v0.1` does not read as "not yet validated." Shipping an unreviewed member in front of the exact reader who cannot tell a wrong answer from a right one is the failure the suite standard exists to prevent.
- **Type:** COHERENCE
- **Confidence:** CONFIRMED
- **Evidence:** Version spread (Agent 0 + my probe): EMU v2.0, CONCOMPRA v2.1, READBASED v3.0, R_Analysis v2.1 (all July, both rounds); ASSEMBLY v0.1 (August). ASSEMBLY appears in no prior review report and is outside `TUTORIAL_SPEC.md`'s "four documents" scope. `README.md:14` routes MAG readers here with no marker; `README.md:120` footer reads "All four SOPs … reviewed adversarially".
- **Fix:** Do not ship ASSEMBLY as a peer until the two prompts run (see *Assembly SOP — release gate*). Interim, make the draft state reader-facing and gate the router. In `SOP_ASSEMBLY_NeSI.md`, insert after line 5:
  > **Draft (v0.1) — not yet through the lab's correctness and tutorial review rounds.** Treat every command as unverified end-to-end: run one sample first and check each checkpoint before you rely on results or scale to a cohort.

  In `README.md` line 14, mark the assembly cell `` `SOP_ASSEMBLY_NeSI.md` (draft, v0.1) `` and replace the footer's "All four SOPs" with "The four Nanopore/Illumina/R SOPs were reviewed in the July 2026 round; `SOP_ASSEMBLY_NeSI.md` (v0.1, August 2026) is a draft not yet reviewed."

### C-04 · S1 · ASSEMBLY §11 globs wrong GTDB-Tk dir; every MAG ships blank taxonomy to Part 2
- **Where:** SOP_ASSEMBLY_NeSI.md, § 11 rank parser (line 609) and § 15 UniFrac note (line 820)
- **Anchor:** `glob.glob("gtdbtk/*.summary.tsv")`
- **Quote:**
  > for f in glob.glob("gtdbtk/*.summary.tsv"):          # bac120 and/or ar53
- **Defect:** GTDB-Tk 2.7.1 writes its per-domain summaries to `gtdbtk/classify/gtdbtk.bac120.summary.tsv` (and `…ar53…`) — under `--out_dir/classify/`, not the top level. The non-recursive glob `gtdbtk/*.summary.tsv` matches nothing, so the parser writes a header-only `tables/mag_taxonomy.tsv`. The §15 UniFrac note (line 820) makes the same nesting error for the placement tree (`gtdbtk/*.classify.tree`, actually `gtdbtk/classify/…classify.tree`).
- **Impact:** On the default path the reader runs §11, sees `0 MAGs classified`, and — if they read past it — the §15 reshape merges the empty taxonomy `how="right"` onto abundances and hands Part 2 a table where **every MAG has blank ranks**. The §11 checkpoint even primes them to read blank ranks as normal ("Empty `species` fields are normal"), so a total parse miss is indistinguishable from a classified cohort. Silent wrong output reaching every downstream reader.
- **Type:** CONTENT
- **Confidence:** VERIFIED
- **Evidence:** I loaded the installed module and resolved the paths from source:
  ```
  $ module load GTDB-Tk/2.7.1-foss-2023a-Python-3.11.6
  $ python3 -c "from gtdbtk.config.output import PATH_BAC120_SUMMARY_OUT, PATH_BAC120_TREE_FILE; \
      print(PATH_BAC120_SUMMARY_OUT.format(prefix='gtdbtk')); print(PATH_BAC120_TREE_FILE.format(prefix='gtdbtk'))"
  classify/gtdbtk.bac120.summary.tsv
  classify/gtdbtk.bac120.classify.tree
  ```
  With ASSEMBLY's `--out_dir gtdbtk` (line 590), the summary is at `gtdbtk/classify/…`, which `glob.glob("gtdbtk/*.summary.tsv")` does not reach; the tree is at `gtdbtk/classify/…classify.tree`, not `gtdbtk/*.classify.tree`.
- **Fix:** Two edits, both paste-ready. Line 609 → `for f in glob.glob("gtdbtk/classify/*.summary.tsv"):          # bac120 and/or ar53`; line 820 path token → `` `gtdbtk/classify/*.classify.tree` ``. (These land inside ASSEMBLY's full review round, but both are confirmed now.)

---

## Suite-coherence findings

Globally ranked S2 → S3 → S4. Cross-cutting suite items first within each tier,
then document order.

### C-05 · S2 · Five uncoordinated document versions and no suite version anywhere
- **Where:** SOP_EMU_NeSI.md, § header (line 5); every SOP header + README.md
- **Anchor:** `**v2.0** | last updated July 2026`
- **Quote:**
  > **v2.0** | last updated July 2026 | NeSI (SLURM) | Oxford Nanopore full-length 16S
- **Defect:** The five SOPs carry five independent version numbers (EMU v2.0, CONCOMPRA v2.1, READBASED v3.0, R_Analysis v2.1, ASSEMBLY v0.1) and there is no suite-level version or release date in any file, including the README. A reader holding "Part 1 v2.0" cannot tell which edition of the *manual* it belongs to, or whether the neighbours it cross-references are the matching editions.
- **Impact:** A student clones the repo, sees v2.0 on EMU and v0.1 on ASSEMBLY, and has no way to know whether they hold one coherent current set or a mix frozen at different times. A maintainer cannot cite "the Taylor Lab SOP suite as of date X" because no such number exists.
- **Type:** COHERENCE
- **Confidence:** CONFIRMED
- **Evidence:** `for f in SOP_*.md; do grep -m1 -E '\*\*v[0-9]' "$f"; done` → five distinct strings (2.0, 2.1, 3.0, 2.1, 0.1). `grep -niE 'suite|version' README.md` → no suite-version line, only a footer date. This is the brief's still-open calibration item C-00.
- **Fix:** Add one suite version + date + a one-line changelog to the README header, keeping the per-document `**vN.N**` lines beneath it as document versions. Paste into `README.md` under the H1: `**Taylor Lab SOP suite — v1.1 (August 2026).** Per-document versions are in each file's header; this line is the release the set was cut as one.` Add the same `suite v1.1 (August 2026)` token to each SOP header line so a bare `vN.N` always resolves to a suite state.

### C-06 · S2 · README, EMU and the spec all call a five-document suite "four"
- **Where:** README.md, § footer (line 120); SOP_EMU_NeSI.md (line 7); TUTORIAL_SPEC.md (lines 14, 40, 234)
- **Anchor:** `All four SOPs`
- **Quote:**
  > *Last updated: July 2026 — second review round. All four SOPs and this README were probed against NeSI Mahuika …*
- **Defect:** Five SOPs ship, but three places still count four. README's footer says "All four SOPs … reviewed". EMU's intro (line 7) says it "is the only document in this set that teaches the cluster itself; **the other three** assume it" — a count of four, and it also mis-states that Part 2 "assumes" the cluster (the README itself says Part 2 runs locally). `TUTORIAL_SPEC.md` says "One reader, **all four** documents" (14), "Measured across the **four** documents" (40) and "across all **four** files" (234), never mentions ASSEMBLY, and omits it from its F1 heading census.
- **Impact:** A first-time student takes the README and Part 1's own words as the map of the suite, expects a four-document set, and instead finds five — including the unreviewed ASSEMBLY — at exactly the moment they are building their mental model. The contract every SOP is written against does not describe the suite that exists.
- **Type:** COHERENCE
- **Confidence:** CONFIRMED
- **Evidence:** `ls SOP_*.md | wc -l` → 5; README routing/coverage tables enumerate all five (lines 8–14, 24–28) yet the footer says four; `grep -nE 'four (SOPs|documents)|all four' README.md TUTORIAL_SPEC.md` → README:120, SPEC:14,40,234; `grep -niE 'assembly|MAG|binning' TUTORIAL_SPEC.md` → nothing.
- **Fix:** Three edits. README footer: change "All four SOPs" per C-03's fix text. EMU line 7: replace the clause after "starts from `pwd`" with — "it is the only document in this set that teaches the cluster itself. The other cluster SOPs (`SOP_CONCOMPRA_NeSI.md`, `SOP_READBASED_NeSI.md`, `SOP_ASSEMBLY_NeSI.md`) point back here for the bash/SLURM groundwork; `SOP_R_Analysis.md` (Part 2) runs locally and stands on its own." TUTORIAL_SPEC lines 14/40/234: change "four" → "five" and add an ASSEMBLY row to the §2 heading-census table (or state the spec was written for the four amplicon/shotgun/R documents and ASSEMBLY is being brought to spec), so the contract names every document it governs.

### C-07 · S2 · "Part 1 / Part 2" no longer describes four upstreams feeding one downstream
- **Where:** SOP_R_Analysis.md, § title (line 3); SOP_EMU_NeSI.md, SOP_CONCOMPRA_NeSI.md, SOP_READBASED_NeSI.md, SOP_ASSEMBLY_NeSI.md, README.md
- **Anchor:** `Part 2: R Analysis (Count Tables to Results)`
- **Quote:**
  > # **Part 2: R Analysis (Count Tables to Results)**
- **Defect:** Only EMU ("Part 1") and R_Analysis ("Part 2") carry a Part label; CONCOMPRA, READBASED and ASSEMBLY carry none yet all three lean on the bare shorthand "Part 2" (CONCOMPRA ×7, READBASED §13 title + line 863, ASSEMBLY §15). "Part 2" describes a linear Part 1 → Part 2, which stopped being the shape once four cluster documents (Emu, CONCOMPRA, read-based, assembly) all feed the one R endpoint.
- **Impact:** A student doing Illumina shotgun follows the README to `SOP_READBASED_NeSI.md` (no Part label), finishes it, is sent here, and opens a document headed "Part 2" — Part 2 of what? They never did a "Part 1". Same for a CONCOMPRA or ASSEMBLY reader. The label reads as a broken sequence for three of the four upstream paths, and the suite reads as loose files rather than one manual.
- **Type:** COHERENCE
- **Confidence:** CONFIRMED
- **Evidence:** R_Analysis title line 3 "Part 2"; EMU title "Part 1"; `grep -nE 'Part [12]' SOP_CONCOMPRA_NeSI.md` → "Part 2" ×7, "Part 1" ×0; READBASED/ASSEMBLY carry no Part label (Agent 0 suite table) but route to "Part 2". README enumerates five documents into one R downstream.
- **Fix:** Adopt the README's upstream/downstream framing and drop the bare "Part N" numbering suite-wide (recommended in *Convention decisions*). On R_Analysis, replace the title and add a locator:
  > # **R Analysis: Count Tables to Results**
  >
  > This is the shared downstream step for every pipeline in this suite: whichever upstream SOP produced your count table (Emu, CONCOMPRA, read-based shotgun, or assembly), the analysis continues here.
  Then drop "Part 1" from EMU's title, and in every doc expand the first bare "Part 2" to "the R analysis (`SOP_R_Analysis.md`)". Files edited: all five SOPs + README (routing/coverage prose).

### C-08 · S2 · README's read-based routing cell points at the wrong SOP's Section 13
- **Where:** README.md, § Which SOP do I need? (line 12)
- **Anchor:** `that SOP's Section 13`
- **Quote:**
  > | Shotgun metagenomes, read-based profiling, human-associated samples | `SOP_READBASED_NeSI.md` | `SOP_R_Analysis.md`, with the deltas in that SOP's Section 13 |
- **Defect:** In this cell "that SOP" reads, literally, as the just-named `SOP_R_Analysis.md`, so "that SOP's Section 13" resolves to **R_Analysis §13** — which is "Figures and Reproducibility" (wrong content). The intended target is **READBASED §13**, "Statistics: What Changes from `SOP_R_Analysis.md`". The sibling assembly row (line 14) names the owning SOP explicitly ("the deltas in `SOP_ASSEMBLY_NeSI.md` Section 15"), and README:30 gets it right ("the read-based SOP's Section 13"); this one cell is the outlier.
- **Impact:** A human-associated shotgun reader — the exact audience of the row — follows the router to R_Analysis §13 looking for the compositional deltas, lands on the figures section, and cannot find them. The router, the single most-read file, sends its own reader to the wrong place; to a trusting reader that reads as their own mistake.
- **Type:** CONTENT
- **Confidence:** CONFIRMED
- **Evidence:** `SOP_R_Analysis.md:1318` → "## **13. Figures and Reproducibility**"; `SOP_READBASED_NeSI.md:857` → "## **13. Statistics: What Changes from `SOP_R_Analysis.md`**". README:14 disambiguates by naming the SOP; README:12 does not. Agent 0 flagged this as the suite's one MIS-TARGETED reference.
- **Fix:** Name the owning SOP, matching line 14. Change line 12's downstream cell to:
  > `SOP_R_Analysis.md`, with the read-based deltas in `SOP_READBASED_NeSI.md` Section 13

### C-09 · S2 · CONCOMPRA sends the reader to a SILVA path EMU never creates
- **Where:** SOP_CONCOMPRA_NeSI.md, § Appendix A (line 723); SOP_EMU_NeSI.md, § 4 Setting Up the Databases (lines 607–618, 651)
- **Anchor:** `databases/emu/silva/`
- **Quote:**
  > cd /nesi/project/<your_nesi_project_code>/databases/emu/silva/   # the Emu SILVA bundle
- **Defect:** CONCOMPRA Appendix A tells the reader to `cd` into "the SILVA bundle `SOP_EMU_NeSI.md` installed — the directory that holds Emu's `species_taxid.fasta`", giving `/nesi/project/<code>/databases/emu/silva/`. EMU installs that bundle to `/nesi/nobackup/<code>/<project>/emu_databases/silva` (`EMU_DATABASE_DIR=…/emu_databases/silva`, line 618; `DB_PATH=…/emu_databases/silva`, line 651). Two mismatches: the **filesystem** (`project` vs `nobackup`) and the **directory name** (`databases/emu/silva` vs `emu_databases/silva`). The seam the CONCOMPRA agent could not resolve without reading EMU; I read both — it is a genuine contradiction.
- **Impact:** A reader who installed the Emu SILVA DB exactly per EMU §4, then reaches CONCOMPRA Appendix A to build the once-per-project SINTAX database that §7 taxonomy needs, `cd`s to a directory that does not exist and gets "No such file". CONCOMPRA's own checkpoint (line 740) then tells them it "means you are in the wrong directory or the Emu SILVA database was never downloaded" — actively misleading, since they *did* download it, just to the path EMU actually uses.
- **Type:** CONTENT
- **Confidence:** CONFIRMED
- **Evidence:** Cross-document contradiction, both sides quoted. CONCOMPRA:723 `cd /nesi/project/<code>/databases/emu/silva/` vs EMU:618 `export EMU_DATABASE_DIR=/nesi/nobackup/<code>/<project>/emu_databases/silva` and EMU:651 `DB_PATH=/nesi/nobackup/<code>/<project>/emu_databases/silva`. `grep -nF 'databases/emu/silva' SOP_CONCOMPRA_NeSI.md` → 723 only; `grep -nE 'emu_databases/silva' SOP_EMU_NeSI.md` → 618, 651, 692.
- **Fix:** Point CONCOMPRA at EMU's real install location and stop asserting a `project` path EMU never wrote. Change line 723 to:
  > cd /nesi/nobackup/<your_nesi_project_code>/<your_project>/emu_databases/silva   # where SOP_EMU_NeSI.md Section 4 installed the Emu SILVA bundle (holds species_taxid.fasta)

  and adjust the checkpoint prose at line 740 to "…means you are not in the directory where EMU Section 4 installed the bundle (`emu_databases/silva` on nobackup), or it was never downloaded." (The reformatter copy/output paths at lines 722/726/731 use a separate `databases/silva_emu_sintax/` dir the reader creates; those are internally consistent — only the *input* `cd` is wrong.)

### C-10 · S2 · R_Analysis §12 and the 14-figure worked example ship uncleared under a stale July header
- **Where:** SOP_R_Analysis.md, § 12 + figures + header (lines 1252–1316; line 5)
- **Anchor:** `## **12. Co-occurrence Networks (optional)**`
- **Quote:**
  > ## **12. Co-occurrence Networks (optional)**
- **Defect:** Section 12 (SPIEC-EASI, ~65 lines) and the entire 14-figure GlobalPatterns worked example were added *after* both prior rounds (git: commits `7beef09`, `909c6d0`, `02e5521`, `b5fb49e`, all after the structure rewrite `8f6dda1`) and have been read by no correctness or tutorial reviewer. The structure round's target outline placed "Figures and reproducibility" at §12 and named no network section and zero figures. Yet the header still reads "v2.1 | last updated July 2026" with no changelog, presenting newer-than-reviewed content under the same July sign-off as the rest.
- **Impact:** The target reader trusts every word equally and cannot tell reviewed from unreviewed content. §12 already ships with a visible slip (its package count, C-21); no correctness reviewer checked its `spiec.easi()` parameters, StARS claim or embedded figure. A section going to a new student labelled ready that no round has read is the same class of failure as ASSEMBLY (C-03), smaller in scope.
- **Type:** CONTENT
- **Confidence:** CONFIRMED
- **Evidence:** `git log --oneline` shows §12 (`b5fb49e`) and the worked-example figures (`7beef09`/`909c6d0`) added after the P4 R_Analysis rewrite (`8f6dda1`). `reviews/structure/R_ANALYSIS.md` target outline names no §12 network section and no figures. Header line 5 still says July 2026.
- **Fix:** Have a correctness reviewer read §12 and the 14 figures against this SOP's own guards (compositionality, `ps_raw`/`ps_srs` rule, expected-output discipline) and the environment probe. Then update the header to record it:
  > **v2.1** | last updated August 2026 | runs locally in R, not on NeSI | platform-agnostic
  >
  > *Changelog: Aug 2026 — added Section 12 (co-occurrence networks, SPIEC-EASI) and the GlobalPatterns worked example (Sections 3–13 figures); reviewed <date>.*

### C-11 · S2 · ASSEMBLY reinstates the prior-pipeline prerequisite the spec explicitly withdraws
- **Where:** SOP_ASSEMBLY_NeSI.md, § Before you start (line 14); TUTORIAL_SPEC.md, § 1 (lines 14–21)
- **Anchor:** `You need to have run one NeSI pipeline before`
- **Quote:**
  > - **You need to have run one NeSI pipeline before.** Bash, `module`, `sbatch` and array jobs are taken as familiar. If they are not, work through `SOP_EMU_NeSI.md` Section 1 first — it is the only document that teaches the cluster.
- **Defect:** `TUTORIAL_SPEC.md` §1 sets one audience for the whole suite — "A graduate student who has never opened a terminal" — and states "This overrides what a document says about itself … that assumption is withdrawn," naming exactly the prior-pipeline assumption. ASSEMBLY reinstates it as a hard prerequisite. It is the same class of defect the structure round rewrote out of READBASED (S-07), now live in the unreviewed document.
- **Impact:** The suite's stated reader lands here from the README, reads that they must already have "run one NeSI pipeline," and either stops (believing they are unqualified) or is bounced to EMU "Section 1" — but the FASTQ/quality concepts a first-timer needs live in EMU **§2**, not §1, and ASSEMBLY separately leans on `srun --pty`, `hugemem`, `nn_seff` that a single §1 redirect does not cover.
- **Type:** COHERENCE
- **Confidence:** CONFIRMED
- **Evidence:** Direct contradiction, both sides quoted — ASSEMBLY:14 ("taken as familiar") vs TUTORIAL_SPEC:14–18 ("A graduate student who has never opened a terminal … that assumption is withdrawn").
- **Fix:** Reframe as a redirect, matching the READBASED rewrite. Replace ASSEMBLY line 14 with:
  > - **This SOP does not re-teach the cluster.** Bash, `module`, `sbatch` and array jobs are used throughout; if they are new to you, work through `SOP_EMU_NeSI.md` **Sections 1–2** first — it is the only document that teaches the cluster, starting from `pwd`, and Section 2 covers FASTQ and quality scores. You do not need to have finished another pipeline, only that grounding.

### C-12 · S2 · ASSEMBLY's metaSPAdes and co-assembly forks read files the given commands never create
- **Where:** SOP_ASSEMBLY_NeSI.md, § 4 (lines 191–248) and §§ 5–6 (lines 301, 334)
- **Anchor:** `so downstream scripts must point at the right one`
- **Quote:**
  > metaSPAdes writes contigs to `assemblies/${SAMPLE}/contigs.fasta` — a different name and path from MEGAHIT, so downstream scripts must point at the right one.
- **Defect:** Every step from §5 on hard-codes the MEGAHIT artefact (`assemblies/${SAMPLE}/${SAMPLE}.contigs.fa` → `…min1500.fa`). The doc *flags* that metaSPAdes writes a different name (`contigs.fasta`) but never resolves it, and the co-assembly path referenced in §6 (`coassembly/all/coassembly.min1500.fa`, line 334) is never produced — §5's metaQUAST and min1500 filter run per-sample only. Both non-default forks are offered with "choose when" guidance and wired into Appendix A, yet either strands the reader at §5/§6.
- **Impact:** A reader who correctly picks metaSPAdes (line 191) or co-assembly (line 221) for their study finishes §4, then §5's filter/metaQUAST and §6's mapping fail on a missing `${SAMPLE}.contigs.fa` / `.min1500.fa`, with only a one-line prose warning and no command to bridge the gap.
- **Type:** CONTENT
- **Confidence:** CONFIRMED
- **Evidence:** §5 filter reads `assemblies/${S}/${S}.contigs.fa` (line 301); §6 sets `ASM="assemblies/${SAMPLE}/${SAMPLE}.min1500.fa"` with a co-assembly comment `coassembly/all/coassembly.min1500.fa` (line 334); metaSPAdes writes `contigs.fasta` (line 217); co-assembly writes `coassembly/all/coassembly.contigs.fa` (line 248) and no §5 step filters it.
- **Fix:** Normalise each alternative to the canonical MEGAHIT path so the rest of the SOP is untouched. (a) In `scripts/04b.assemble_metaspades.sl`, after `spades.py`, add `ln -sf contigs.fasta "assemblies/${SAMPLE}/${SAMPLE}.contigs.fa"`. (b) For co-assembly, add a one-off QC+filter block at the end of §5 producing `coassembly/all/coassembly.min1500.fa`, and state that `$ASM` for §6–§8 is then that file (the mapping array still runs `1-${NSAMP}`, mapping every sample to the one assembly). Full block in `reviews/capstone/ASSEMBLY.md` §C-04 Fix. (Lands inside the ASSEMBLY review round.)

### C-13 · S2 · ASSEMBLY submission appendix says submit-at-once but wires jobs past manual steps
- **Where:** SOP_ASSEMBLY_NeSI.md, § Appendix A: Submission Chain (lines 893–916)
- **Anchor:** `submit the pipeline at once and let SLURM sequence it`
- **Quote:**
  > Each job waits on the one it depends on, so you can submit the pipeline at once and let SLURM sequence it.
- **Defect:** The appendix contradicts itself and cannot run as printed. It later says "The two interactive steps (contig filtering, bin collection) break the chain deliberately," yet the block wires `MAP` to `afterok:$ASM` (mapping auto-starts before the manual min1500 filter exists) and `CM2` to `afterok:$DAS` (CheckM2 auto-starts before the manual `mags/` collection). It also submits `12.bakta.sl --array=1-${NMAG}%10` while `$NMAG` is unset — `mags_derep.txt`, the file it counts, is not built until §12, after dRep — so that line errors at submit with an invalid array spec.
- **Impact:** A reader who does as told and pastes the block "at once" queues assembly and metaQUAST, then map_coverage and every later job fire on their dependencies before the human has run the filter/collect steps, cascading into missing-file failures; the bakta line additionally rejects on an empty `--array=1-%10`. The reader believes the pipeline is sequencing when key stages never ran.
- **Type:** LAYOUT
- **Confidence:** CONFIRMED
- **Evidence:** Line 893 "submit the pipeline at once" vs line 916 "break the chain deliberately"; MAP/CM2 dependencies (902/906) point at `$ASM`/`$DAS`, not the interactive steps commented at 901/905; `$NMAG` never set in the block (only `NSAMP`, line 897) yet used at line 910.
- **Fix:** Present the chain in three submit-phases with the interactive steps between, and defer bakta's array until `mags_derep.txt` exists. Full three-phase block in `reviews/capstone/ASSEMBLY.md` §C-05 Fix. (Lands inside the ASSEMBLY review round.)

### C-14 · S3 · The three 1000-plus-line documents have no table of contents
- **Where:** SOP_R_Analysis.md (1411 ln), SOP_READBASED_NeSI.md (1028 ln), SOP_EMU_NeSI.md (1019 ln); CONCOMPRA/ASSEMBLY
- **Anchor:** `## **Quick Roadmap: What You'll Do**`
- **Quote:**
  > ## **Quick Roadmap: What You'll Do**
- **Defect:** None of the long documents carries a clickable table of contents. Their only navigation is the Quick Roadmap — a fenced ASCII *workflow* diagram with no links, that omits front/back matter (§1, §13, Troubleshooting, Appendices in R_Analysis). A reader cannot jump to a numbered section or an appendix without scrolling ~1000–1400 lines or Ctrl-F-guessing the heading.
- **Impact:** A student following a cross-reference ("the read-based SOP's Section 13", "in Appendix B") lands at the top of a 1000-plus-line file and must scroll to the target — repeatedly, since these docs cross-reference their own sections a dozen times. Recoverable, but it costs the reader on every jump into the docs they consult most.
- **Type:** LAYOUT
- **Confidence:** VERIFIED
- **Evidence:** `wc -l` → R_Analysis 1411, READBASED 1028, EMU 1019; `grep -nE '^\s*[-*0-9.]+ ?\[.*\]\(#' <file>` → no linked contents list in any of the three.
- **Fix:** Set a suite TOC policy (*Presentation and navigation decisions*): a one-line `## Contents` block of GitHub heading-slug anchors immediately after the version line in every SOP over ~600 lines (R_Analysis, READBASED, EMU, ASSEMBLY; CONCOMPRA optional at 764). Paste-ready per-doc blocks are in the EMU (§C-04), READBASED (§C-03) and R_Analysis (§C-04) reports.

### C-15 · S3 · R_Analysis leaves 14 orphan figure assets and its embed numbering skips 14
- **Where:** SOP_R_Analysis.md, § 12 (line 1314); examples/r_analysis/figures/
- **Anchor:** `15_spieceasi_network.png`
- **Quote:**
  > ![SPIEC-EASI co-occurrence network](examples/r_analysis/figures/15_spieceasi_network.png)
- **Defect:** `examples/r_analysis/figures/` holds 28 files; the document embeds only 14 (PNGs 01–13 and 15). Fourteen are orphans referenced by no document: `14_core_microbiome.png` (the SOP has no core-microbiome section) and all 13 `.svg` twins. The embed numbering is discontinuous — 01–13 then **skips 14, uses 15** for the SPIEC-EASI figure.
- **Impact:** A student who clones the repo and opens the figures directory finds a `14_core_microbiome` figure with no section that uses it and 13 SVGs the SOP never shows, and cannot tell whether they are meant to appear somewhere (did I miss a section? is a figure failing to render?) or are dead weight. An asset present but unreferenced is indistinguishable from a broken embed.
- **Type:** LAYOUT
- **Confidence:** VERIFIED
- **Evidence:** `ls examples/r_analysis/figures/` → 15 PNG (01–15) + 13 SVG (all but 04 and 10); embedded in SOP: PNG 01–13 and 15 (14). Orphans: `14_core_microbiome.png` + 13 `.svg` = 14. Matches Agent 0.
- **Fix:** Renumber `15_spieceasi_network.*` → `14_*` and update the embed at line 1314 and `examples/r_analysis/run_example.R`, so the embedded set is contiguous 01–14. Delete `14_core_microbiome.*` (no section uses it) or add a core-microbiome section. Either delete the 13 orphan SVGs or move them to `figures/svg/` referenced from `examples/r_analysis/README.md`.

### C-16 · S3 · CONCOMPRA's roadmap numbers the workflow "STAGE 1–6" against a "Section 1–10" body
- **Where:** SOP_CONCOMPRA_NeSI.md, § Quick Roadmap (lines 27–51)
- **Anchor:** `STAGE 1: Install (once per project)`
- **Quote:**
  > STAGE 1: Install (once per project)
- **Defect:** The roadmap runs a second, non-matching numbering over the same workflow: six "STAGE" numbers against the body's ten "Section" numbers. They do not align — STAGE 1 (Install) is Section 2, STAGE 4 (Run and verify) is Sections 5 and 6, STAGE 5 (Post-process) is Section 7 — and CONCOMPRA is the one document still using "Stage" after the set retired it in the R_Analysis renumber.
- **Impact:** A reader who takes the roadmap as their map internalises "STAGE 5 = post-processing", scrolls to Section 5, and lands on "Submitting the Run" — stage and section numbers collide within one document. Recoverable by name, but every reader pays the reconciliation.
- **Type:** COHERENCE
- **Confidence:** CONFIRMED
- **Evidence:** `grep -niE 'stage' SOP_CONCOMPRA_NeSI.md` → six hits, all in the roadmap (30–45); `grep -nE '^## \*\*[0-9]'` → ten "Section N" headings. Set decision retiring "Stage": `reviews/structure/00_PLAN.md` renumber map.
- **Fix:** Relabel the six `STAGE N:` headers with the section numbers they describe (SECTION 2 Install, SECTION 3 Pre-flight, SECTION 4 Configure, SECTIONS 5–6 Submit+verify, SECTION 7 Post-process, SECTION 8 Hand off to R). Full replacement roadmap in `reviews/capstone/CONCOMPRA.md` §C-02 Fix.

### C-17 · S3 · CONCOMPRA "delete temporary/ (Section 9)" points at Troubleshooting; step is §10
- **Where:** SOP_CONCOMPRA_NeSI.md, § 5 Submitting the Run (line 322)
- **Anchor:** `once the analysis is final (Section 9)`
- **Quote:**
  > Delete `temporary/` yourself once the analysis is final (Section 9).
- **Defect:** The cross-reference names the wrong section. Deleting `temporary/` is documented in **Section 10** ("The temporary directory", lines 685–695). **Section 9** is Troubleshooting; none of its subsections tells the reader to delete `temporary/`.
- **Impact:** A reader who wants to know when to clear the kept-for-debugging `temporary/` follows "(Section 9)", reaches Troubleshooting, and finds nothing about deletion — the pointer resolves to a real section with the wrong content. Not blocked (the inline sentence still says to delete it), but the elaboration is not where they were sent.
- **Type:** CONTENT
- **Confidence:** CONFIRMED
- **Evidence:** Internal contradiction: line 322 "(Section 9)" vs the deletion step at 685–695 under "## **10. Maintenance**". `grep -nE 'rm -rf temporary/' SOP_CONCOMPRA_NeSI.md` → inside §10.
- **Fix:** Change line 322 `(Section 9)` → `(Section 10)`.

### C-18 · S3 · R_Analysis runs two example identities: tuatara code and prose vs GlobalPatterns figures
- **Where:** SOP_R_Analysis.md, § intro + Before You Start (lines 9, 18); figures throughout
- **Anchor:** `The examples use Cam's tuatara PhD data`
- **Quote:**
  > The examples use Cam's tuatara PhD data, so the variable names (Site, Sex, Species) and site names (Takapourewa, Zealandia, YoungNicksHead) are specific to that study.
- **Defect:** All code and prose use tuatara names (`~ Site`; levels Takapourewa/Zealandia/YoungNicksHead; the Reporting sentence at L917), but every figure and caption is GlobalPatterns (Human/Freshwater/Saline). Line 9 flatly says "The examples use … tuatara PhD data"; the figures are not tuatara. The two identities give conflicting numbers for the same step — L917 says "R² = 0.38 … Aitchison R² = 0.35" while the L745 figure caption says "R² = 0.28 and 0.48, p = 0.0001".
- **Impact:** A student reads the Reporting box, looks at the PCoA caption directly below the code, and cannot tell which is the exemplar for their own output — two "worked" answers for one analysis, at every figure.
- **Type:** CONTENT
- **Confidence:** CONFIRMED
- **Evidence:** L9 (tuatara) vs L18 (GlobalPatterns figures); number contradiction L917 vs L745 caption; tuatara-level code L1110 (`diff_SiteZealandia`) vs GlobalPatterns caption L1115 (`Saline`). Apparatus postdates the structure round (part of C-10's uncleared additions).
- **Fix:** State the split once at L9 and mark the prose numbers as templates: "The **code** examples use tuatara variable/site names (adapt to your metadata); the **figures** are real output from a different public dataset (Worked example below), so captions name that dataset's groups and any prose numbers — e.g. the Section 8 Reporting template — are illustrative placeholders that will not match the captions." Then at L917 prefix the Reporting sentence "*Report in this form (numbers illustrative):*". Full text in `reviews/capstone/R_ANALYSIS.md` §C-02.

### C-19 · S4 · R_Analysis names the combine helper without EMU's `04_` section prefix
- **Where:** SOP_R_Analysis.md, § 3 loader (line 163); SOP_EMU_NeSI.md
- **Anchor:** `from combine_emu_results.py`
- **Quote:**
  > # Read in the combined counts table (from combine_emu_results.py)
- **Defect:** EMU authors and calls the helper `04_combine_emu_results.py` (8 mentions), honouring the "script filename carries its section number" rule; R_Analysis:163 names it without the `04_` prefix. Two documents, one file, two names across the handoff.
- **Impact:** Minor — a student who saved `04_combine_emu_results.py` per Part 1 meets `combine_emu_results.py` here and briefly wonders if it is a different script. It is a comment, not a command, so nothing errors.
- **Type:** COHERENCE
- **Confidence:** CONFIRMED
- **Evidence:** `grep -cF '04_combine_emu_results.py' SOP_EMU_NeSI.md` → 8; `grep -nF 'combine_emu_results.py' SOP_R_Analysis.md` → 163 only, no prefix.
- **Fix:** Change line 163 to `# Read in the combined counts table (from 04_combine_emu_results.py)`.

### C-20 · S4 · R_Analysis leaves pairwiseAdonis install commented while its library() call runs live
- **Where:** SOP_R_Analysis.md, § 2 Install (line 104); § 8 Step 5 (lines 924–925)
- **Anchor:** `pairwiseAdonis for post-hoc PERMANOVA comparisons`
- **Quote:**
  > # pairwiseAdonis for post-hoc PERMANOVA comparisons
- **Defect:** `pairwiseAdonis`'s install is commented out at L104 and again at the point of use (L924), but `library(pairwiseAdonis)` at L925 is live. The equally optional `SpiecEasi` two lines away (L112) has a live install — the house style for "optional GitHub package" is applied inconsistently.
- **Impact:** A reader who ran the §2 block never installed `pairwiseAdonis`; at §8 Step 5 they run `library(pairwiseAdonis)` and hit "there is no package called 'pairwiseAdonis'". The same trap the structure round fixed for `devtools`, reintroduced for a different package.
- **Type:** LAYOUT
- **Confidence:** CONFIRMED
- **Evidence:** L104 and L924 commented vs L925 `library(pairwiseAdonis)` live; contrast L112 `devtools::install_github("zdk123/SpiecEasi")` live.
- **Fix:** Uncomment the §2 install — change L104 to `devtools::install_github("pmartinezarbizu/pairwiseAdonis/pairwiseAdonis")`.

### C-21 · S4 · R_Analysis §12 says "three extra packages" but four network packages install and load
- **Where:** SOP_R_Analysis.md, § 12 (line 1260); install block (110–112); library call (1263)
- **Anchor:** `needs three extra packages from Section 2, one GitHub-only`
- **Quote:**
  > This step is optional and needs three extra packages from Section 2, one GitHub-only (`SpiecEasi`).
- **Defect:** The network step installs and loads **four** extra packages — `igraph`, `ggraph`, `tidygraph` (CRAN) and `SpiecEasi` (GitHub) — not three. The visible slip in the section no round has cleared (C-10).
- **Impact:** A reader counting dependencies prepares three, then meets four `library()` calls and a four-package install block. Trivial, but a wrong count in a freshly added section undermines confidence in it.
- **Type:** CONTENT
- **Confidence:** CONFIRMED
- **Evidence:** Install block L110–112 lists four; `library()` at L1263 loads four; L1260 says "three".
- **Fix:** Change L1260 to "…needs four extra packages from Section 2 — `igraph`, `ggraph`, `tidygraph`, and the GitHub-only `SpiecEasi`."

### C-22 · S4 · ASSEMBLY cosmetics — DRAM block unnamed, sentence-case subheads, un-glossed jargon
- **Where:** SOP_ASSEMBLY_NeSI.md, § 13 (block 716–732, table row 957); §§ 1/4/8/13 subheads and first-use terms
- **Anchor:** `13b.dram`
- **Quote:**
  > | `13b.dram` | 200 GB | 20 | 24 h | Optional; validate on 1–2 MAGs first |
- **Defect:** Omnibus of ASSEMBLY-local polish the full review round will also sweep: (a) the §13 DRAM code block is the only reader-created block with no `scripts/…` intro line, though Appendix B (line 957) lists `13b.dram`; (b) `###` subheads are bold sentence case ("From reads to a MAG") against the spec's title-case rule; (c) `k-mer`, `hugemem`, `nn_seff`, `diamond` appear before any first-use gloss for a terminal-novice reader.
- **Impact:** Cosmetic/navigation — a reader building from the resource table cannot find the `13b.dram` script's save point; heading style shifts between docs; a beginner meets `nn_seff`/`hugemem` with no idea what to run. Each small, none blocking.
- **Type:** LAYOUT
- **Confidence:** CONFIRMED
- **Evidence:** `grep -cF '13b.dram' SOP_ASSEMBLY_NeSI.md` → 1 (table only), no `scripts/13b` intro; subheads at 46/52/63/293 sentence case vs spec §8 title-case; first uses of k-mer/hugemem/nn_seff/diamond ungloss ed at 65/141/734/454.
- **Fix:** (a) Insert before line 716 `` `scripts/13b.dram.sl` (single job): ``. (b) Title-case `###` subheads, leaving tool tokens (`metaSPAdes`, `eggNOG-mapper`) as-is. (c) One-clause glosses at first use. Details in `reviews/capstone/ASSEMBLY.md` §§C-08/C-09/C-10. Folds into the ASSEMBLY review round.

---

## Cross-reference integrity table

Every inter-document / section / appendix / script pointer swept by Agent 0
(157 `Section N` + 57 `Part 1/2` + 11 `Appendix X` + 39 `step N` + 69 by-filename)
plus the A-report and my own checks. All RESOLVE except the four flagged rows.

| Source | Pointer | Target | Verdict | Finding |
| --- | --- | --- | --- | --- |
| README:8–14, 24–28 | routing/coverage rows → all 5 SOPs | each SOP exists | RESOLVES | — |
| **README:12** | "that SOP's Section 13" (read-based row) | literal → R_Analysis §13 (Figures); intended → READBASED §13 (deltas) | **MIS-TARGETED** | **C-08** |
| README:14 | "`SOP_ASSEMBLY_NeSI.md` Section 15" | ASSEMBLY §15 "Handoff to Part 2" | RESOLVES | — |
| README:30 | "the read-based SOP's Section 13" | READBASED §13 | RESOLVES | — |
| README:37 | "Section 1 of the read-based SOP" | READBASED §1 | RESOLVES | — |
| EMU:7 | "the other three assume it" | miscounts suite as 4 | RESOLVES but false count | **C-06** |
| EMU:7,23,782,961 | `SOP_R_Analysis.md` / Part 2 | R_Analysis | RESOLVES | — |
| CONCOMPRA:17 | "Section 1 of `SOP_EMU_NeSI.md`" | EMU §1 | RESOLVES | — |
| CONCOMPRA:596–633 | "Part 2" ×7 / §3 data-loading | R_Analysis §3 | RESOLVES (label unplaced) | C-07 |
| **CONCOMPRA:322** | "once the analysis is final (Section 9)" | deletion step is §10, not §9 | **WRONG SECTION** | **C-17** |
| **CONCOMPRA:723** | `cd …/databases/emu/silva/` "the bundle EMU installed" | EMU installs `…/emu_databases/silva` on nobackup | **BROKEN PATH** | **C-09** |
| CONCOMPRA:150,424 | `#appendix-a-…`, `#threads` | own headings | RESOLVES | — |
| **READBASED:265,275,462** | "(Appendix A)" for the afterok chain | Appendix A is now "Triage"; chain deleted | **BROKEN (regression)** | **C-02** |
| **READBASED:622** | "(Appendix B)" re-run array index | no Appendix B (A→C) | **BROKEN** | **C-02** |
| READBASED:7,39,652,833,851 | "Section 13 below" (self) | READBASED §13 (857) | RESOLVES | — |
| READBASED:865–901 | "Part 2 / §3 data-loading" | R_Analysis §3 | RESOLVES (label) | C-07 |
| R_Analysis:7,78,148 | "`SOP_READBASED_NeSI.md` … Section 13" | READBASED §13 | RESOLVES | — |
| R_Analysis:147 | "`SOP_CONCOMPRA_NeSI.md` Section 8" | CONCOMPRA §8 | RESOLVES | — |
| R_Analysis:15,16 | "Part 1 for Nanopore" | EMU | RESOLVES (label) | C-07 |
| R_Analysis:163 | "(from combine_emu_results.py)" | EMU's `04_combine_emu_results.py` | RESOLVES, name drift | C-19 |
| R_Analysis internal | §§2–13, Appendix A/B/C, Beta Steps 1–6 | all present | RESOLVES | — |
| ASSEMBLY:14 | "`SOP_EMU_NeSI.md` Section 1" | EMU §1 (but concepts in §2) | RESOLVES, redirect too narrow | C-11 |
| ASSEMBLY:13,81,777,810 | "`SOP_READBASED_NeSI.md` §1/§7/§13; Part 2; §15" | targets exist | RESOLVES | — |
| ASSEMBLY:590→609 | parser globs `gtdbtk/*.summary.tsv` | GTDB-Tk writes `gtdbtk/classify/…` | **BROKEN PATH** | **C-04** |
| ASSEMBLY:820 | UniFrac tree `gtdbtk/*.classify.tree` | tree at `gtdbtk/classify/…classify.tree` | **BROKEN PATH** | **C-04** |
| ASSEMBLY:957 vs §13 block | Appendix B lists `13b.dram`; block unnamed | no `scripts/13b.dram.sl` intro | UNNAMED | C-22 |
| ASSEMBLY:909 | Appendix A "`mags_derep.txt` (Section 12)" | built at line 636 inside §12 | RESOLVES | — |

---

## Figure and asset audit

Every `![` and `<img` in the suite, plus orphans. `curl -sI` and `ls` 2026-08-04.

| Source | Reference | Kind | Verdict | Finding |
| --- | --- | --- | --- | --- |
| EMU:399 | `…/assets/3caf1fec-…6e956379` | remote `<img>` | **404 · off-repo · dies on clone** | **C-01** |
| EMU:405 | `…/assets/62050053-…c73f67ebcf7b` | remote `<img>` | **404 · off-repo** | **C-01** |
| EMU:537 | `…/assets/0fb8ff83-…9603d44d9` | remote `<img>` | **404 · off-repo** | **C-01** |
| EMU:543 | `…/assets/939cc9ba-…8c258f` | remote `<img>` | **404 · off-repo** | **C-01** |
| R_Analysis:314–1331 | `examples/r_analysis/figures/{01–13}_*.png` | local `![]` | PRESENT (13, `ls`-confirmed) | — |
| R_Analysis:1314 | `…/15_spieceasi_network.png` | local `![]` | PRESENT; **numbering skips 14** | C-15 |
| CONCOMPRA, READBASED, ASSEMBLY | — | none | 0 figures (defensible for runbooks) | — |
| examples/…/figures/14_core_microbiome.png | — | on disk | **ORPHAN** (no section embeds it) | C-15 |
| examples/…/figures/*.svg (13 files) | — | on disk | **ORPHAN** (SOP embeds only PNG) | C-15 |

Totals: 18 embeds (14 markdown, 4 HTML). 4 broken (all remote EMU), 14 local
present. 14 orphan assets on disk. The one figure strategy the suite should keep is
R_Analysis's — local, in-repo, relative-path, offline-safe.

---

## Presentation and navigation decisions

- **Table of contents.** The suite has none anywhere. **Decision:** a one-line
  `## Contents` block of GitHub slug anchors after the version line in every SOP
  over ~600 lines — R_Analysis (1411), READBASED (1028), EMU (1019), ASSEMBLY (985);
  CONCOMPRA (764) optional. The Quick Roadmap stays as the *workflow* view; the TOC
  is the *navigation* view. (C-14.)
- **Heading granularity.** Top-level section counts run 4 (EMU) to 16 (ASSEMBLY).
  A reader moving between documents should be able to assume: a scope line, a
  Before-you-start, a Quick Roadmap, a `## 1. Understanding Your Data` concepts
  section, numbered action steps each ending in a checkpoint, then Troubleshooting +
  Appendices. EMU (four broad numbered sections with `###` steps) and ASSEMBLY
  (sixteen) are the granularity outliers; both are *earned* (EMU folds QC into one
  §3; ASSEMBLY genuinely has 16 tool stages) and neither needs renumbering — the TOC
  closes the navigation cost.
- **Figure captions/numbering.** Figures currently carry alt-text + prose but no
  "Figure N" labels. If the lab wants numbered captions, R_Analysis's 14 QC/result
  figures and EMU's four (once regenerated) are the set; not required to ship.
- **Troubleshooting home.** Three homes today: CONCOMPRA "## 9. Troubleshooting"
  (numbered body section), READBASED "Appendix A/B: Triage" (back-matter),
  R_Analysis "Troubleshooting and Common Pitfalls" (before Appendices), EMU a
  pointer table. **Decision:** one name, "Troubleshooting", one position — a
  `##`-level section immediately before Appendices (R_Analysis's placement); keep
  READBASED's Triage material but under that name/position.

---

## Convention decisions

Options, a recommendation, then the lab decides.

1. **Suite version.** *Options:* (a) one suite version + changelog in the README,
   per-doc `vN.N` beneath; (b) bump every doc to a shared number. **Recommend (a)** —
   documents legitimately revise at different rates; the suite tag gives a citable
   release. (C-05.)
2. **Part-N scheme.** *Options:* (a) drop bare "Part 1/Part 2", let each descriptor
   line carry the role (upstream cluster SOP / shared R downstream); (b) renumber
   Part 1A/1B/1C/1D → Part 2. **Recommend (a)** — four upstreams into one downstream
   is a hub, not a line; "Part 2" has no coherent "Part 1" for three of four paths.
   (C-07.)
3. **Figure strategy.** *Options:* (a) local in-repo PNGs under `examples/<doc>/figures/`
   (R_Analysis's model); (b) remote hosting; (c) none. **Recommend (a)** everywhere —
   it is the only one that renders on an offline clone; forces EMU's four to be
   regenerated and committed (C-01).
4. **Troubleshooting + TOC** — as under *Presentation and navigation decisions*.

---

## Reconciliation with reviews 1 and 2

**Deliberately not re-filed** (settled and correct on disk — I verified each landed):
the four correctness S1s (pairwise.adonis2 `p.adjust.m`; CONCOMPRA config/primer;
READBASED `head -1` relab; module/re-run guards) all present; the canonical SLURM
header, Emu Option-B handoff, retention numbers, placeholder/naming conventions
all applied across the four reviewed docs (per each A report's regression check,
which I spot-confirmed). Pedagogy/teaching-order and voice/scannability are owned by
those rounds. None re-raised.

**Left open/deferred by prior rounds that bears on shipping, now closed here:**
- **Image hosting on github user-attachments** (SYNTHESIS reference table listed the
  four EMU images "not fetched") → resolved as a ship-blocker: they 404 and are
  off-repo (**C-01**). Credit: the seam was noted (not ranked) in round 2.
- **Missing `LICENSE`** (structure round Open Q7; README:114 points readers at reuse
  terms) → still absent; a repo-root ship item (Open questions, below). Credit:
  structure round.
- **Emu Option A vs B billing** → landed correctly (EMU now standardises on Option B;
  not re-filed).
- **CONCOMPRA Appendix A Emu-SILVA path** (structure round chose `databases/emu/silva/`)
  → resolved against EMU: it is **wrong** (**C-09**). Credit: structure round S-02
  chose the path; CONCOMPRA capstone agent flagged it for me to settle.
- **"Four documents" language** (README + spec) → now a false count against five
  SOPs (**C-06**).

**Regression the prior rounds could not have seen** (they reviewed the file before
the edit): READBASED's deleted Submission-Chain appendix (**C-02**) — introduced by
the applied P3 rewrite `82e61b6`, after both rounds signed off.

---

## Assembly SOP — release gate

**Status: NOT READY. Do not ship `SOP_ASSEMBLY_NeSI.md` as a peer.** It needs a full
run of `prompts/SOP_REVIEW_PROMPT.md` **and** a tutorial round before release — a
capstone pass is not a substitute (Assembly agent's recommendation, which I uphold).
Concretely:

1. **It has had neither dedicated round.** Its siblings each had correctness +
   structure/voice; this one had only this capstone. The README already routes new
   students into it (C-03).
2. **The correctness round is what catches C-04.** The empty-taxonomy handoff is
   invisible from the text — it took reading the GTDB-Tk module source to see the
   `--out_dir/classify/` nesting defeats the glob; I re-verified it against the
   installed `GTDB-Tk/2.7.1` module (both summary and tree paths). The same nesting
   defeats the §15 UniFrac tree path. Items only a fixture run can close remain open:
   DAS_Tool `--write_bins` output extension (§8 collector), CoverM genome-mode column
   headers (§15 reshape), and an end-to-end GTDB-Tk/Bakta/CoverM run on ≥2 real MAGs
   (the doc itself admits "a full cohort run on real data was not timed here").
3. **The tutorial round owns C-11 (audience contract) and the un-glossed jargon** —
   structural, not sentence-level.
4. **C-12/C-13** (broken metaSPAdes/co-assembly forks; unrunnable submission
   appendix) are what a second reader catches by trying a non-default path.

The draft is close and worth finishing — its teaching layer, "why this number"
content and all 17 module strings / 3 `/opt/nesi/db` databases are at suite standard.
But shipping it now puts an unreviewed member, with a silent-wrong-output bug, in
front of the reader who cannot tell it from a right one. **Interim (C-03):** mark it
draft in-header and gate the README routing cell + footer.

---

## Consolidated keep list

Merged and de-duplicated across the five A reports — the regression test for Stage 4.
Every anchor `grep -Fc`s to exactly 1 in its source file; if a rewrite loses any,
the rewrite failed. All are load-bearing "why this number" / silent-failure /
governance content: **KEEP or rewrite-tighter, never cut.**

**EMU** — `essential, do not omit` · `a 1,500 bp floor would discard many legitimate full-length reads` · `Emu reads that as 0.9% identity` · `raise it or reads are discarded without warning` · `silently inflates the count` · `only the first sample is processed` · `write the other's into two identically named columns` · `EM uses **community context** to resolve ambiguous reads` · `has not yet been tested or validated with Emu`

**CONCOMPRA** — `never from the` · `does not stop the script or change its exit code` · `the filter drops **every** read, silently` · `not the reverse-complement` · `silently corrupts taxonomy at low-confidence ranks` · `standard SINTAX bootstrap threshold` · `Do not replace or downgrade filtlong` · `one metadata sheet cannot serve both pipelines` · `often genuine rare taxa`

**READBASED** — `re-identify individuals against matched genotype data at 93.3%` · `Divide, do not multiply.` · `they cannot be combined into one` · `parameters come from JGI's recipe and assume a masked reference` · `depend on when someone last ran the tool with internet access` · `a column sums to roughly 8x the classified fraction` · `any cleanup placed after the command would never run` · `Each job waits on the one it depends on` (**being restored by C-02** — the reader's only afterok source)

**R_ANALYSIS** — `The one rule to remember` · `this is a relative-abundance table, not counts` · `index them POSITIONALLY` · `a stale ps_raw will run` · `the figure is what goes into the thesis` · `the true total is 4,000 cells but the instrument still returns` · `filtering before adjusting shrinks the number of tests` · `roughly 30 or more samples`

**ASSEMBLY** — `≥5 Gb of clean sequence per sample` · `Treat a MAG carrying human contigs as controlled data` · `Zero turns off reference downloading` · `caps MEGAHIT at 90% of the memory it detects` · `The unsplit bacterial tree needs more than 320 GB` · ``Providing `--genomeInfo` is what stops dRep running CheckM itself`` · `CheckM2 does not check rRNA/tRNA genes` · `suppresses spurious low-level cross-mapping` · `never round it or pass it through SRS`

---

## Work plan

`∥` = parallel. Ship-blockers first. Each item edits distinct files/lines once the
conventions in W0 are frozen, so nothing collides.

| # | Item | Files | Closes | Size | Depends on |
| --- | --- | --- | --- | --- | --- |
| **W0** | Freeze conventions: suite version tag, drop Part-N for role labels, in-repo figure strategy, one Troubleshooting name/position, TOC policy | (this file) | baseline for C-05/07, C-14 | — | — |
| **W1** ∥ | **EMU figures**: regenerate 4 PNGs from the worked-example run, commit under `examples/emu/figures/`, swap the 4 `<img>` → local `![]` | SOP_EMU_NeSI.md, examples/emu/ | **C-01 (S1)** | M (needs asset creation) | — |
| **W2** ∥ | **READBASED appendix restore**: paste "Appendix A: Submission Chain" from `a9a6336`, re-letter Triage→B, collapse blank lines 983–985 | SOP_READBASED_NeSI.md | **C-02 (S1)**, C-02-lettering | S | — |
| **W3** | **ASSEMBLY draft-gate**: header draft banner; README cell `(draft, v0.1)` + footer count | SOP_ASSEMBLY_NeSI.md, README.md | **C-03 (S1)** | S | W6 (README count) |
| **W4** ∥ | **ASSEMBLY GTDB paths**: line 609 glob → `gtdbtk/classify/*.summary.tsv`; line 820 tree → `gtdbtk/classify/*.classify.tree` | SOP_ASSEMBLY_NeSI.md | **C-04 (S1)** | S | (inside W11) |
| **W5** ∥ | **Suite version**: README suite-version line + changelog; `suite v1.1` token in 5 SOP headers | README.md, all 5 SOPs | C-05 | S | W0 |
| **W6** | **Document count**: README footer; EMU:7 clause; TUTORIAL_SPEC "four"→"five" + ASSEMBLY row | README.md, SOP_EMU_NeSI.md, TUTORIAL_SPEC.md | C-06 | S | W0 |
| **W7** | **Part-N scheme**: retitle R_Analysis, drop EMU "Part 1", expand bare "Part 2" refs | all 5 SOPs, README.md | C-07 | M | W0 |
| **W8** ∥ | **README §13 mis-route**: line 12 cell → name READBASED | README.md | C-08 | S | — |
| **W9** ∥ | **CONCOMPRA SILVA path**: line 723 → EMU's `emu_databases/silva` nobackup path; adjust checkpoint 740 | SOP_CONCOMPRA_NeSI.md | C-09 | S | — |
| **W10** | **R_Analysis §12 clearance**: correctness reviewer reads §12 + 14 figures; then header/changelog + tuatara-split note + §12 count | SOP_R_Analysis.md | C-10, C-18, C-21 | M | needs a reviewer pass |
| **W11** | **ASSEMBLY full review**: run `SOP_REVIEW_PROMPT.md` + tutorial round; closes C-04, C-11, C-12, C-13, C-22 | SOP_ASSEMBLY_NeSI.md | C-04/11/12/13/22 | L | W0 |
| **W12** ∥ | **Suite TOC**: `## Contents` block in EMU, READBASED, R_Analysis (+ASSEMBLY in W11) | 3 SOPs | C-14 | S | W0 (TOC policy) |
| **W13** ∥ | **R_Analysis assets**: renumber 15→14, delete/relocate orphans, fix embed + `run_example.R` | SOP_R_Analysis.md, examples/ | C-15 | S | — |
| **W14** ∥ | **CONCOMPRA nav**: roadmap STAGE→SECTION (C-16); line 322 §9→§10 (C-17) | SOP_CONCOMPRA_NeSI.md | C-16, C-17 | S | — |
| **W15** ∥ | **R_Analysis polish**: line 163 `04_` prefix; uncomment pairwiseAdonis install | SOP_R_Analysis.md | C-19, C-20 | S | — |
| **W16** | **LICENSE**: add repo-root `LICENSE` (lab decides which) | LICENSE | Open-Q seam | S | lab decision |

**Sequence:** W0 first. Ship-blockers W1–W4 run in parallel (distinct files) and are
the gate for the four reviewed docs (W2/W4's ASSEMBLY item is inside the W11 round,
but both edits are confirmed now). W5–W9 are the S2 coherence pass; W7 touches all
five headers so run it as one atomic edit before W12's per-doc TOCs. W10 and W11 each
need a reviewer/round, not just an edit — they are the two "content no one cleared"
gates. W12–W15 are parallel polish. W16 is a lab governance call.

---

## Open questions for the lab

1. **Ship ASSEMBLY, or hold it out of the router?** *Options:* (a) mark draft + gate
   the routing cell now, run both prompts, promote when it passes; (b) remove it from
   the README entirely until reviewed. **Recommend (a)** — the draft is close and the
   banner protects the reader. (C-03/W3/W11.)
2. **`LICENSE`.** README:114 already tells readers about reuse terms; the repo has
   none, which by default grants no rights. *Options:* CC BY 4.0 (protocols), MIT
   (scripts). No recommendation — a governance call. (W16.)
3. **Part-N vs role labels** — recommend dropping Part-N (Convention 2); the lab
   confirms it is content to lose "Part 1/Part 2" branding in any cited methods.
4. **Numbered figure captions** — adopt suite-wide or leave as alt-text + prose?
   Recommend leave as-is for now; not a ship item.
5. **CONCOMPRA `prv_cut` and the SINTAX-DB provenance** — carried open from round 2;
   scientific tuning calls the lab owns, unaffected by this round.

---

## Self-check

```
findings=22 S1=4 S2=9 S4=4
CLEAN
```

By hand, the three the script cannot check:
- [x] **Every cross-document reference and URL is accounted for** — the
  Cross-reference integrity table represents every `Part [12]`, `Section N`,
  `Appendix [A-Z]`, `see the … SOP` and by-filename hit from Agent 0's sweep; the
  Figure/asset audit lists all four remote EMU `<img>` and every local/orphan asset.
- [x] **No proposed cut touches load-bearing content** — zero cuts. C-01 regenerates,
  C-02 restores deleted content, the rest add/relabel/repoint. The Consolidated keep
  list is the regression guard (45 anchors, all `grep -Fc` = 1).
- [x] **Every finding is CONFIRMED or VERIFIED** — no NOT-VERIFIABLE-HERE blocks; the
  GTDB-Tk nesting (C-04), the four 404s (C-01), the git regression (C-02) and the
  CONCOMPRA/EMU path contradiction (C-09) were each run on the cluster this round.

CONTRACT: PASS
