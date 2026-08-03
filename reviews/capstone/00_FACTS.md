# Agent Prompt 0 — Product-Integrity Probe (Capstone Review)

Run 2026-08-04 on NeSI Mahuika (Lmod 8.7.65), from
`/nesi/project/uoa03769/taylor-lab-sops`. This file establishes what resolves and
what does not. It files no findings and judges no quality — the later agents argue
from it. Verdict vocabulary: references `RESOLVES` / `BROKEN` / `MOVED`; modules
`HOLDS` / `DRIFTED` / `FALSE` / `UNREACHABLE`.

**Headline counts**

| Probe | Result |
| --- | --- |
| Cross-reference pointer instances swept | 157 `Section N` + 57 `Part 1/2` + 11 `Appendix X` + 39 `step N` + 69 by-filename mentions |
| Cross-references BROKEN | **1** — `SOP_READBASED_NeSI.md:622` → "Appendix B" (no such appendix; it has A and C only) |
| Cross-references MIS-TARGETED (resolve, but to the wrong section under a literal read) | **1** — `README.md:12` "that SOP's Section 13" |
| Embedded figures total | **18** (14 markdown `![]()`, 4 HTML `<img>`) |
| Figures local / remote | 14 local, 4 remote |
| Figures BROKEN | **4** — all four remote EMU `<img>` return HTTP 404 (and are outside the repo → dead on an offline clone). 0 local broken. |
| Orphan assets under `examples/` (referenced by no document) | **14** figure files (13 `.svg` + `14_core_microbiome.png`) |
| Shipped scripts referenced | 3 physical (`reformat_silva_for_sintax.py`, `run_example.R`, `make_inputs.R`) — all EXIST |
| Reader-created inline scripts | 30 named, all defined inline; **0 missing**; 2 naming defects (see below) |
| Assembly modules probed | **17** |
| Modules HOLDS / DRIFTED / FALSE / UNREACHABLE | **17 / 0 / 0 / 0** |

**Five suite facts (see full table below):** EMU 1019 ln / v2.0 / July 2026 ·
CONCOMPRA 764 ln / v2.1 / July 2026 · READBASED 1028 ln / v3.0 / July 2026 ·
R_Analysis 1411 ln / v2.1 / July 2026 · ASSEMBLY 985 ln / v0.1 / August 2026.
README footer says "**four** SOPs"; TUTORIAL_SPEC says "**four** documents" and
never names ASSEMBLY — but there are **five** SOPs on disk.

---

## What I loaded and ran

- `module` is a shell function under Lmod 8.7.65 (`module --version`). The module
  tree lives under a **sticky** `NeSI/zen3` meta-module. Caveat learned mid-run:
  `module --force purge` unloads `NeSI/zen3` and makes every application module
  fail with "exist but cannot be loaded as requested" — a false FALSE. Plain
  `module purge` retains the sticky base; **all 17 probes below use plain purge.**
  A successful load returns rc=0 with empty stderr; I confirmed the exact string
  in `module list` where a load emitted any output.
- Heading maps built with `grep -nE '^#{1,4} ' <file>` for all five SOPs.
- Cross-references extracted with `grep -noE 'Section[s]? +[0-9]+…'`,
  `grep -noE 'Part [12]…'`, `grep -noE 'Appendix [A-Z]…'`, `grep -noiE 'step [0-9]+'`,
  and by-filename `grep -oE 'SOP_…\.md'`; each target checked against its heading map.
- Figures: `grep -rnoE '!\[[^]]*\]\([^)]*\)'` and `grep -rnoiE '<img[^>]*>'`; local
  paths `ls`'d (byte sizes recorded), remotes `curl -sI --max-time 25`'d.
- Orphans: for every file under `examples/`, `grep -rl -F <basename>` across all
  `*.md`.
- Suite facts: `wc -l *.md`, `head`, `grep -niE 'version|last updated'`.
- Prior rounds read for framing: `reviews/00_SYNTHESIS.md`, `reviews/00_ENVIRONMENT.md`,
  `reviews/structure/00_PLAN.md`, `reviews/structure/00_REALITY.md`. Note: the
  structure round (dated 2026-08-03) lists **old** script names (`01_nanoplot_raw.sh`,
  `emu_array.sh`, `host_filter.sl`); the SOPs were renumbered afterward to
  `03a_nanoplot_raw.sh`, `04a_emu_array.sh`, `scripts/07b.host_filter.sl`. All facts
  below reflect the **current, post-renumber** state.

---

## Cross-reference resolution

### The two exceptions (highest value)

| Source | Pointer text | Target | Verdict | Evidence |
| --- | --- | --- | --- | --- |
| `SOP_READBASED_NeSI.md:622` | `# re-running a failed array index (Appendix B) safe.` | READBASED Appendix B | **BROKEN** | `grep -nE '^#+ .*Appendix' SOP_READBASED_NeSI.md` → only `986: Appendix A: Triage` and `1010: Appendix C: Resources`. **There is no Appendix B** (lettering skips A→C). The referenced topic — re-running a failed array index — is a Triage matter, i.e. Appendix A. |
| `README.md:12` | "…`SOP_R_Analysis.md`, with the deltas in **that SOP's Section 13**" | intended: READBASED §13; literal: R_Analysis §13 | **MIS-TARGETED (resolves to wrong section)** | The delta section is **READBASED §13** ("Statistics: What Changes from `SOP_R_Analysis.md`", line 857) — exists, correct content. But "that SOP" names `SOP_R_Analysis.md`; **R_Analysis §13 also exists** (line 1318, "Figures and Reproducibility") — wrong content. Sibling rows disambiguate: `README:14/28` say "`SOP_ASSEMBLY_NeSI.md` Section 15" and `README:30` says "the read-based SOP's Section 13". Line 12 is the outlier. |

### Everything else RESOLVES. Cross-document pointers (all verified against target heading maps):

| Source (line) | Pointer | Target document + heading | Verdict |
| --- | --- | --- | --- |
| README 8–14, 24–32, 40, 87, 109–114 | Part 1 / Part 2 / EMU §1 / READBASED §13 / ASSEMBLY §15 / Appendix B (of README's own tool table) | EMU=Part 1, R_Analysis=Part 2; EMU §1 "Getting Started"; READBASED §13; ASSEMBLY §15 "Handoff to Part 2" | RESOLVES (except line 12 above) |
| EMU 12, 23, 782, 784, 961 | "Part 2 / `SOP_R_Analysis.md`" | R_Analysis exists | RESOLVES |
| CONCOMPRA 17 | "Section 1 of `SOP_EMU_NeSI.md`" | EMU §1 "Getting Started on NeSI" | RESOLVES |
| CONCOMPRA 596, 619, 627, 629–633 | "Part 2 / Part 2's data-loading step (Section 3)" | R_Analysis §3 "Load and Prepare Your Data" | RESOLVES |
| CONCOMPRA 150 | anchor `#appendix-a-silva-sintax-database-build` | own heading "Appendix A: SILVA SINTAX Database Build" (line 698) | RESOLVES (GitHub slug matches) |
| CONCOMPRA 424 | anchor `#threads` | own heading "### Threads" (line 293) | RESOLVES |
| READBASED 7, 39, 652, 833, 851 | "Section 13 below" (self) | READBASED §13 (line 857) | RESOLVES |
| READBASED 865, 890, 894, 896, 901 | "Part 2 / Part 2's data-loading step, Section 3" | R_Analysis §3 | RESOLVES |
| R_Analysis 7, 148 | "`SOP_READBASED_NeSI.md`, whose Section 13…" | READBASED §13 | RESOLVES |
| R_Analysis 78–79 | "see `SOP_READBASED_NeSI.md` Section 13" | READBASED §13 | RESOLVES |
| R_Analysis 15, 16 | "Part 1 for Nanopore" | EMU=Part 1 | RESOLVES |
| R_Analysis 147 | "`SOP_CONCOMPRA_NeSI.md` Section 8" | CONCOMPRA §8 "Preparing for R / phyloseq" (line 535) | RESOLVES |
| R_Analysis 14 | "'Get your files onto this machine' in Section 3" | bold para inside R_Analysis §3 (line 152) | RESOLVES |
| ASSEMBLY 81, 87, 91, 601, 777, 785, 789, 810–828 | "Part 2 / `SOP_READBASED_NeSI.md` Section 1 / Section 7 / its Section 13 / Section 15" | R_Analysis; READBASED §1 "Before You Generate Data", §7 "Host Depletion", §13; ASSEMBLY §15 | RESOLVES |

### Internal (same-document) section pointers — verified against heading maps, all RESOLVE

- **EMU** (§refs at 13,163,299,417,459,977–982; Steps 1–4): §1 Getting Started,
  §2 Understanding Your Data, §3 Processing Reads (Steps 1–4), §4 Emu. All present.
- **CONCOMPRA** (§refs at 69,191,224,225,232,318,322,354,390,424,687): §§1–10 all
  present; Steps 1–4 in §7 present. All resolve.
- **READBASED** (§refs at 42,58,65,86,94,96,98,118,122,144,177,181,194,201,285,343,
  389,460,478,502,516,574,589,664,668,735,852,890,893,1001–1028): §§1–14 all present;
  §3.3 "References and Databases" present. All resolve **except the Appendix B
  code-comment at 622 (BROKEN, above).**
- **R_Analysis** (§refs at 13,28,58,68–79,110,226,227,446,454,1032,1051,1260,1391,
  1405–1411): §§1–13 all present; Appendix B "Normalisation Methods" (line 1389)
  present, and 446/454's "TSS and CSS … in Appendix B" content is there. All resolve.
- **ASSEMBLY** (§refs at 38,65,69,73,77,81,185,248,295,305,346,356,408,521,631,674,
  789,814,882 and Appendix-A submission chain at 901,905,909): §§1–16 all present.
  Notable check — Appendix A line 909 "Build `mags_derep.txt` (Section 12) after dRep":
  `mags_derep.txt` **is** built at line 636, which falls inside §12 "Annotate the MAGs"
  (629–672). RESOLVES. Lines 901 (§5) and 905 (§8) likewise resolve.

---

## Figure and asset existence

### Local markdown figures — all PRESENT (`ls`, byte sizes)

| Source (line) | Path | Present? |
| --- | --- | --- |
| R_Analysis 364 | `examples/r_analysis/figures/01_input_sanity.png` | PRESENT (60436 B) |
| R_Analysis 314 | `…/02_decontam_prevalence.png` | PRESENT (60137 B) |
| R_Analysis 377 | `…/03_read_depth_by_group.png` | PRESENT (38952 B) |
| R_Analysis 479 | `…/04_rarefaction.png` | PRESENT (173757 B) |
| R_Analysis 404 | `…/05_explore_pcoa.png` | PRESENT (75428 B) |
| R_Analysis 524 | `…/06_srs_before_after.png` | PRESENT (117228 B) |
| R_Analysis 611 | `…/07_alpha_diversity.png` | PRESENT (63439 B) |
| R_Analysis 743 | `…/08_beta_pcoa.png` | PRESENT (139791 B) |
| R_Analysis 856 | `…/09_beta_dispersion.png` | PRESENT (139497 B) |
| R_Analysis 1024 | `…/10_taxonomy_barplot.png` | PRESENT (84709 B) |
| R_Analysis 1113 | `…/11_ancombc2_lfc.png` | PRESENT (72943 B) |
| R_Analysis 1248 | `…/12_indicator_species.png` | PRESENT (113000 B) |
| R_Analysis 1331 | `…/13_publication_figure.png` | PRESENT (149895 B) |
| R_Analysis 1314 | `…/15_spieceasi_network.png` | PRESENT (227961 B) |

### Remote HTML figures — all BROKEN and all off-repo

`curl -sI --max-time 25` on 2026-08-04; every one returned `HTTP/2 404` from
`server: github.com`. These are external assets (`github.com/user-attachments/…`):
they do not live in the repository and **will not render in an offline clone**
regardless of the 404. Both problems apply.

| Source (line) | URL | curl status | Off-repo? |
| --- | --- | --- | --- |
| EMU 399 | `github.com/user-attachments/assets/3caf1fec-…6e956379` (Read length histogram, raw) | **404** | YES — external, dies offline |
| EMU 405 | `…/62050053-…c73f67ebcf7b` (Length vs quality, raw) | **404** | YES |
| EMU 537 | `…/0fb8ff83-…9603d44d9` (Read length histogram, filtered) | **404** | YES |
| EMU 543 | `…/939cc9ba-…8c258f` (Length vs quality, filtered) | **404** | YES |

### Orphan assets under `examples/` (on disk, referenced by NO document)

- `examples/r_analysis/figures/14_core_microbiome.png` (108030 B) — the example
  produces `core_microbiome.txt` and this figure, but R_Analysis embeds figures
  01–13 and 15 and has **no core-microbiome section**; nothing references it.
- **All 13 `.svg` files**: `01,02,03,05,06,07,08,09,11,12,13,14,15_*.svg`. The SOP
  embeds only `.png`; no document references any `.svg`. (Asymmetry: `04_rarefaction`
  and `10_taxonomy_barplot` have a `.png` but no `.svg`; every other index has both.)
- Not orphans (referenced by `examples/r_analysis/README.md`, the worked-example
  data ledger): `alpha_stats.txt`, `ancombc2_*.tsv`, `core_microbiome.txt`,
  `counts.tsv`, `indicator_*.{tsv,txt}`, `metadata.tsv`, `permanova_results.txt`,
  `sessionInfo.txt`, `spieceasi_*.{tsv,txt}`, `taxonomy.tsv`. The 14 embedded PNGs
  are referenced only by `SOP_R_Analysis.md`, not by the example README.

---

## Referenced scripts

There is **no `scripts/` directory** in the repo (`ls scripts` → No such file). By
design, every `.sl`/`.sh`/combine-`.py` script is **authored inline** in its SOP —
introduced by a backtick-quoted path (e.g. `` `scripts/06.trim.sl` (array job): ``)
followed by the full code block the reader saves. I confirmed each referenced
script has such a definition point (not sbatch-only), and that its numeric prefix
matches the section that defines it.

### Physical files that must ship — all EXIST

| Script | Claimed path | `ls` | Referenced by |
| --- | --- | --- | --- |
| `reformat_silva_for_sintax.py` | repo root | EXISTS (4991 B) | CONCOMPRA Appendix A (reader copies it into the DB dir) |
| `run_example.R` | `examples/r_analysis/` | EXISTS | R_Analysis ("`Rscript run_example.R`") |
| `make_inputs.R` | `examples/r_analysis/` | EXISTS | `examples/r_analysis/README.md` |

### Reader-created inline scripts — all DEFINED; section/prefix aligned

| Doc | Scripts (prefix → defining section) | Alignment |
| --- | --- | --- |
| EMU | `03a_nanoplot_raw.sh`, `03b_chopper_filter.sh`, `03c_nanoplot_filtered.sh` (§3 Steps 2–4); `04a_emu_array.sh`, `04b_emu_array_rdp.sh`, `04_combine_emu_results.py` (§4) | Matches |
| CONCOMPRA | `05_concompra.sh` (§5 Submitting), `07_concompra_postprocess.sh` (§7 Post-processing) | Matches |
| READBASED | `05a.qc_fastqc.sl`, `05b.qc_multiqc.sl` (§5); `06.trim.sl` (§6); `07.host_hostile.sl`, `07a.host_index.sl`, `07b.host_filter.sl` (§7); `08.read_counts.sl` (§8); `09.metaphlan.sl` (§9); `10.humann.sl` (§10) | Matches |
| ASSEMBLY | `04a/04b/04c` (§4); `05.metaquast` (§5); `06.map_coverage` (§6); `07.bin` (§7); `08.dastool` (§8); `09.checkm2` (§9); `10.drep` (§10); `11.gtdbtk` (§11); `12.bakta` (§12); `13a.eggnog` (§13); `14.coverm` (§14) | Matches |

### Two script-naming defects (facts, not judgments)

1. **Combine-script name drifts across documents.** EMU authors and calls it
   `04_combine_emu_results.py` (EMU:782,790,…). R_Analysis:163 refers to the same
   file as `combine_emu_results.py` — **without the `04_` prefix**. README does not
   name it. A reader who saved it per EMU has `04_combine_emu_results.py`; the R doc
   points at a different name.
2. **DRAM's script is shown but never named.** ASSEMBLY §13 presents a full DRAM
   SLURM code block (lines 717–732) but, unlike every sibling, does **not** introduce
   it with a `` `scripts/…` `` path. Yet Appendix B's resource table (line 957) lists
   a script `13b.dram`. There is no `scripts/13b.dram.sl` definition line anywhere in
   the body (`grep '13b' / 'dram.sl'` → only the Appendix-B table row).

---

## Assembly modules

Every unique string from `grep 'module load' SOP_ASSEMBLY_NeSI.md` (16 from the
body + `SAMtools`, loaded alongside minimap2/CONCOCT = 17). Method per string:
`module purge; module load <exact>` (rc + stderr), confirmed in `module list`;
misses would be re-checked with `module avail <base>` (tree intact). Appendix B's
tool table (lines 923–943) lists these same 17 strings verbatim — consistent.

| # | Module string (exact) | rc | Verdict |
| --- | --- | --- | --- |
| 1 | `MEGAHIT/1.2.9-gimkl-2022a-Python-3.10.5` | 0 | HOLDS |
| 2 | `SPAdes/4.0.0-foss-2023a-Python-3.11.6` | 0 | HOLDS |
| 3 | `QUAST/5.2.0-gimkl-2022a` | 0 | HOLDS |
| 4 | `SeqKit/2.4.0` | 0 | HOLDS |
| 5 | `minimap2/2.30-GCC-12.3.0` | 0 | HOLDS |
| 6 | `SAMtools/1.23.1-GCC-12.3.0` | 0 | HOLDS (default `(D)` on the cluster) |
| 7 | `MetaBAT/2.17-GCC-12.3.0` | 0 | HOLDS |
| 8 | `MaxBin/2.2.7-GCC-11.3.0-Perl-5.34.1` | 0 | HOLDS |
| 9 | `CONCOCT/1.1.0-gimkl-2020a-Python-3.8.2` | 0 | HOLDS |
| 10 | `DAS_Tool/1.1.5-gimkl-2022a-R-4.2.1` | 0 | HOLDS |
| 11 | `CheckM2/1.0.1-Miniconda3` | 0 | HOLDS |
| 12 | `drep/3.4.2-gimkl-2022a-Python-3.10.5` | 0 | HOLDS — loaded as `list` #49; emits a benign `For Help : $ dRep --help` message on load (not an error); `module avail drep` shows this exact string plus older `2.3.2`. |
| 13 | `GTDB-Tk/2.7.1-foss-2023a-Python-3.11.6` | 0 | HOLDS |
| 14 | `bakta/1.10.1-foss-2023a` | 0 | HOLDS |
| 15 | `eggnog-mapper/2.1.12-gimkl-2022a` | 0 | HOLDS |
| 16 | `DRAM/1.3.5-Miniconda3` | 0 | HOLDS |
| 17 | `CoverM/0.7.0-GCC-12.3.0` | 0 | HOLDS |

**Tally: 17 HOLDS, 0 DRIFTED, 0 FALSE, 0 UNREACHABLE.** Every assembly module
string resolves verbatim on Mahuika today. (Database presence claims in the SOP —
`/opt/nesi/db/bakta/v5.1/db`, `/opt/nesi/db/eggnog_db/data`, `/opt/nesi/db/DRAM_1.3.5`,
`CHECKM2DB`, `GTDBTK_DATA_PATH` → GTDB R232 — were **not** filesystem-checked here;
that needs a compute-node/db-tree check the SOP itself flags at line 983. Cost: one
`ls -d /opt/nesi/db/...` per path, ~1 min, best on a node with the db tree mounted.)

---

## Suite facts — counts, versions, dates

Measured, not quoted. `wc -l` and the `**vN.N** | last updated …` header line of each.

| File | Lines (`wc -l`) | Version | Date stamp | Title/self-label |
| --- | --- | --- | --- | --- |
| `SOP_EMU_NeSI.md` | **1019** | **v2.0** | last updated **July 2026** | "Part 1" |
| `SOP_CONCOMPRA_NeSI.md` | **764** | **v2.1** | last updated **July 2026** | (no Part label) |
| `SOP_READBASED_NeSI.md` | **1028** | **v3.0** | last updated **July 2026** | (no Part label) |
| `SOP_R_Analysis.md` | **1411** | **v2.1** | last updated **July 2026** | "Part 2" |
| `SOP_ASSEMBLY_NeSI.md` | **985** | **v0.1** | last updated **August 2026** | (no Part label; v0.1, never reviewed) |
| `README.md` | 120 | — | footer "July 2026 — second review round" (line 120) | router |
| `TUTORIAL_SPEC.md` | 333 | — | (no version line) | the contract |

**Stated document counts vs reality (inputs to the coherence findings):**

- **Actual SOPs on disk: 5** (EMU, CONCOMPRA, READBASED, R_Analysis, ASSEMBLY).
- **README** — the "Which SOP do I need?" table (lines 8–14) and "What each document
  covers" table (lines 24–28) both enumerate **all 5** SOPs, ASSEMBLY included. But
  the footer (line 120) reads *"All **four** SOPs and this README were probed…"* —
  a count of **4**, stale relative to the 5-SOP repo (written for the July review
  round, before ASSEMBLY v0.1 was added in August 2026).
- **TUTORIAL_SPEC** — says *"One reader, **all four** documents"* (14–15), *"Measured
  across the **four** documents"* (40), *"across all **four** files"* (234). It
  **never mentions ASSEMBLY** — `grep -niE 'assembly|MAG|binning|five'` → nothing.
  Its F1 heading census (line 176: "EMU 6, R_Analysis 6, CONCOMPRA 2, READBASED 1,
  README 0") omits ASSEMBLY entirely. The spec's stated count is **4**; ASSEMBLY is
  outside its scope.

---

## Absent, drifted or unreachable

Consolidated list of everything that does not cleanly resolve. None are findings;
they are the resolved/unresolved facts the later agents will weigh.

1. **BROKEN reference — `SOP_READBASED_NeSI.md:622` → "Appendix B".** No Appendix B
   exists (appendices are A "Triage" and C "Resources"); lettering skips B. The topic
   (re-running a failed array index) belongs to Appendix A. *(Also a structural
   oddity in its own right: appendix lettering A→C with no B.)*
2. **MIS-TARGETED reference — `README.md:12` "that SOP's Section 13".** Resolves to a
   real section either way, but a literal read lands on R_Analysis §13 ("Figures and
   Reproducibility" — wrong), not the intended READBASED §13 (the deltas). Sibling
   rows (14/28/30) name the owning SOP explicitly; this one does not.
3. **4 BROKEN + off-repo figures — EMU 399/405/537/543.** All four
   `github.com/user-attachments/…` `<img>` return HTTP 404 and live outside the repo;
   dead on an offline clone. To the target reader an EMU QC figure that will not load
   is indistinguishable from their own mistake.
4. **14 orphan assets** under `examples/r_analysis/figures/`: `14_core_microbiome.png`
   plus all 13 `.svg` files — on disk, embedded by no document.
5. **Script-name drift — `combine_emu_results.py` vs `04_combine_emu_results.py`.**
   R_Analysis:163 omits the `04_` prefix EMU uses everywhere.
6. **Unnamed DRAM script.** ASSEMBLY §13 shows the DRAM job but never gives it the
   `scripts/13b.dram.sl` path its Appendix B table (line 957) assumes.
7. **Self-count drift.** README footer ("four SOPs") and TUTORIAL_SPEC ("four
   documents", ASSEMBLY unmentioned) both describe a 4-SOP suite; there are 5. The
   spec's mechanical scans (F1 census) do not cover ASSEMBLY at all.

**No module drift/absence.** All 17 assembly module strings HOLD verbatim; 0
DRIFTED, 0 FALSE, 0 UNREACHABLE. No referenced script is missing. The
`/opt/nesi/db/*` database-presence claims were not filesystem-verified in this
session (noted in Assembly modules; cost ~1 min of `ls` on a db-mounted node).
