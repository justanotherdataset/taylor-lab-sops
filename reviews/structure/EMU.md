## Document: SOP_EMU_NeSI.md

## Verdict against the specification

`SOP_EMU_NeSI.md` is the strongest document in the set and it earns that: §2 is ten
pure-concept subsections (R3), the silent-failure warnings are the best content in
the repository (R10), and every fork carries a default (R7). Being the exemplar,
its remaining gaps *are* the specification's gaps. Three recur. First, the **step
template is incomplete** (R5): several steps have no checkpoint and almost none give
a runtime — most damagingly the multi-GB database download, which the reader cannot
verify before the pipeline silently depends on it. Second, **two terms are used
before they are defined** (R2/R8): `chimera` (used in Step 2, defined in Step 3) and
the `EM algorithm` (leaned on in Step 3, defined in Section 4) — both named offenders
in the spec's own R2 list. Third, **house style has drifted from §8**: no heading is
bold, six V3 banned words survive, and one US spelling remains. Form is close — six
prose paragraphs and one bullet exceed 80 words, all fixable by splitting or tabling,
with net words flat. Nothing on the keep list is proposed for removal; every
over-length "why this number" paragraph is rewritten tighter, never cut.

| Rule | Pass / Partial / Fail | One-line evidence |
| --- | --- | --- |
| R1 Both layers, in order | Partial | Layer-1 strong (12 concept subsections); but `chimera`/`EM` carry layer-2 before their layer-1 (S-02, S-03). |
| R2 Nothing used before introduced | Fail | `chimera` used L374/L405, defined L423; `EM algorithm` used L421, defined L575. |
| R3 Concepts before commands | Pass | §2 is all concept; §4 opens with "What Emu does" and "Understanding the databases". |
| R4 Setup where needed | Pass | Module loads inside each script; storage layout in prose + list, not a shell block. |
| R5 Every step states outcome | Fail | DB setup, NanoPlot-raw and Emu-array have no checkpoint; runtimes absent from most SLURM steps (S-01, S-04, S-05, S-06). |
| R6 One numbered spine | Partial | Sections 1-4 run in order, but script names carry a step index, not the section number (`01_`/`02_`/`emu_array.sh`) (S-08). |
| R7 Every fork has a default | Pass | SILVA/RDP ("run both", `DB_PATH=silva`), `lr:hq` vs `map-ont`, `--min-abundance`, `--min-pid` all defaulted. |
| R8 Plain words first | Partial | `chimera` term appears (L374) before its plain-words definition (L423). |
| R9 One voice | Partial | Six V3 banned words; headings not bold; one US spelling (S-11, S-12, S-13). |
| R10 Explain the failure | Pass | Array-placeholder, `--keep-counts`, `grep "^@"`, `rm` on nobackup, basename-collision, else-branch — the strongest content in the set. |
| R11 Scripts complete/runnable | Pass | Every job block carries shebang, `--account`, `--time`, `set -euo pipefail`; the array assigns `FASTQ` (no bare `$SAMPLE`). |
| F1 No paragraph over 80 words | Fail | 6 prose paragraphs + 1 bullet over 80 (scan reports 12; 5 are bullet-merge artifacts) (S-10). |
| F2 Definition 1-2 sentences | Partial | Mostly; a few long definitional paragraphs (L36) sit at concept-section length. |
| F3 Enumerable → table/list | Pass | Most enumerables already lists; minor prose list of mail types (L187). |
| F4 Point comes first | Pass | Consistent bold run-ins carrying the operative fact; scannable. |
| F5 The "why" is separable | Partial | Mostly separable via run-ins; some reasoning woven into long bullets (thresholds, `--min-pid`). |

## Jargon table

Every term a beginner would not know, first use, where defined, verdict. `->` = defined-after-use.

| Term | First used | Defined at | Verdict |
| --- | --- | --- | --- |
| `pwd` | L9 | L73 | OK (defined in §1 bash block) |
| NeSI | L5 | L36 | OK (defined at start of §1) |
| SLURM | L5 | L140 | OK (defined in §1) |
| module | L36 | L126 | OK (§1) |
| `sbatch` | L40 | L173 (implicit) | Minor -> used before SLURM/module defined |
| GUI | L40 | never | Minor (abbreviation unexpanded) |
| symlink / symbolic link | L52 | L52 | OK (plain-first, R8) |
| `rm` | L50 | L90 | Minor -> strong `rm -r` warning L64 precedes definition L90 |
| bash | L66 | never (as term) | Minor (used as heading, never glossed) |
| `$USER` | L174 | never | Minor (env var unexplained) |
| wall time | L149 | L149 | OK |
| array job / `$SLURM_ARRAY_TASK_ID` | L168 | L193 | OK (§1 "A note on array jobs") |
| `nn_seff` / `nn_storage_quota` | L120 | L120/L177 | OK (commented) |
| **16S rRNA / rRNA / ribosome** | L5 | L212 | OK (concept §2, R3) |
| bp (base pairs) | L214 | never | Minor (never spelled out) |
| conserved / variable regions, V1-V9 | L216 | L216 | OK |
| PCR | L216 | L226 | Minor -> used L216, defined L226 (both §2) |
| primers / 27F / 1492R / 341F / 785R | L216 | L226/L228/L230 | OK |
| Nanopore / flow cell / basecaller | L5 | L234 | OK (§2) |
| R10.4.1 / R9.4.1 | L239 | never | Minor (chemistry versions unexplained) |
| SUP / HAC / fast | L239 | L283 | OK (defined §2 "on disk") |
| Illumina | L239 | L285 (contrast) | OK (contrasted throughout) |
| FASTQ | L242 | L253 | OK (§2) |
| quality score / Phred / Q10-Q30 | L244 | L244 | OK |
| **N50** | L338 | L377 | Minor -> used L338/L389, defined L377 (same step) |
| NanoPlot / NanoPack | L16 | L338 | OK (layer-1 at first use) |
| `--loglength` / `--plots dot` | L363 | never | Minor S2 (flags unexplained) (S-04) |
| chopper / NanoFilt / NanoLyse | L17 | L415 | OK |
| **chimera** | **L374** | **L423** | **FAIL -> used L374/L405, defined L423 (S-02)** |
| **EM / Expectation-Maximization** | **L421** | **L575** | **FAIL -> leaned on L421, defined L575 (S-03)** |
| minimap2 / multi-mapping | L567 | L571 | OK |
| EPI2ME / Kraken2 / Centrifuge / NanoCLUST | L567 | never | Minor (named as alternatives only) |
| SILVA / RDP | L589 | L591/L604 | OK |
| OSF / osfclient | L614 | L614 | OK |
| `pip` / `export` | L621/L627 | never | Minor (Python/shell basics unglossed) |
| DB_PATH / EMU_PREBUILT_DB | L624 | L624/L648 | OK |
| rrnDB | L599 | never | Minor (version-note aside) |
| manifest | L658 | L658 | OK |
| NM tag | L755 | never | Minor (SAM tag) |
| tax_id / NCBI | L759 | L759 | OK (NCBI unexpanded, common) |
| ASV / DADA2 / denoise | L291 | L291 | OK (ASV glossed; DADA2 named) |
| alpha diversity | L295 | Part 2 | Minor (forward-ref to R) |
| phyloseq / SRS / ANCOM-BC2 / MaAsLin2 | L745 | Part 2 | OK (forward-ref, flagged "downstream R") |
| MinKNOW / multiplex / barcode | L270 | L270 | OK |
| BaseSpace / Globus | L305 | never | Minor (data sources named) |

## Section ledger

| § | Heading | Lines | Treatment | Findings |
| --- | --- | --- | --- | --- |
| — | `## Analysis steps` (roadmap) | 21-28 | REWRITE (ASCII block; relabel "Quick roadmap") | S-09 |
| — | (no `### Before you start`) | 7-9,32 | ADD (new section) | S-09 |
| 1 | `## 1. Getting Started on NeSI` | 30 | REWRITE-VOICE (bold) | S-11 |
| 1 | `### What is NeSI and why we use it` | 34 | REWRITE-VOICE + TIGHTEN (L36) | S-10, S-11 |
| 1 | `### Logging in` | 38 | REWRITE-VOICE + TIGHTEN (L42) | S-10, S-11 |
| 1 | `### Basic bash commands` | 66 | REWRITE-VOICE (bold) | S-11 |
| 1 | `### Using modules` | 124 | REWRITE-VOICE (bold) | S-11 |
| 1 | `### SLURM: running jobs on the cluster` | 138 | REWRITE-VOICE (bold) | S-11 |
| 1 | `### A note on array jobs` | 191 | REWRITE-VOICE + TIGHTEN (L193) | S-10, S-11 |
| 1 | `### Further reading` | 195 | MOVE (-> Appendix) + REWRITE-VOICE | S-09, S-11 |
| 1 | (bold run-in `Choosing resources` L189) | 189 | TIGHTEN | S-10 |
| 2 | `## 2. Understanding Your Data` | 206 | REWRITE-VOICE (bold) | S-11 |
| 2 | `### What is 16S rRNA…` | 210 | REWRITE-VOICE (bold) | S-11 |
| 2 | `### What is an amplicon?` | 222 | REWRITE-VOICE (bold) | S-11 |
| 2 | `### How does Nanopore sequencing work?` | 232 | REWRITE-VOICE (bold) | S-11 |
| 2 | `### What are quality scores?` | 242 | REWRITE-VOICE (bold) | S-11 |
| 2 | `### What does a FASTQ file look like?` | 253 | REWRITE-VOICE (bold) | S-11 |
| 2 | `### What does Nanopore data look like on disk?` | 268 | REWRITE-VOICE (bold) | S-11 |
| 2 | `### Full-length vs short-read: why it matters` | 285 | REWRITE-VOICE (bold) | S-11 |
| 3 | `## 3. Processing Nanopore Reads` | 299 | REWRITE-VOICE (bold) | S-11 |
| 3 | `### Step 1. Organise your raw data` | 303 | CLEAN (rename script -> S-08) | S-08 |
| 3 | `### Step 2. Quality assessment of raw reads` | 336 | ADD-OUTCOME + ADD-LAYER-1 (chimera) + TIGHTEN | S-02, S-04, S-06, S-10 |
| 3 | `### Step 3. Filtering with chopper` | 413 | ADD-OUTCOME (runtime) + ADD-LAYER-1 (EM) + TIGHTEN | S-03, S-06 |
| 3 | `### Step 4. Quality assessment of filtered reads` | 479 | ADD-OUTCOME (runtime) | S-06 |
| 3 | `### Interpreting NanoPlot output` | 539 | MERGE into Steps 2/4 or MOVE -> Appendix | S-07 |
| 4 | `## 4. Taxonomy and Community Profiling with Emu` | 559 | REWRITE-VOICE (bold) | S-11 |
| 4 | `### What Emu does and why we use it` | 563 | REWRITE-VOICE (bold) | S-11 |
| 4 | `### Understanding the reference databases` | 586 | REWRITE-VOICE (bold) | S-11 |
| 4 | `### Setting up the databases` | 610 | ADD-OUTCOME (runtime + checkpoint) | S-01 |
| 4 | `### Running Emu` | 654 | ADD-OUTCOME (checkpoint) + TIGHTEN (L755) | S-05, S-10 |
| 4 | `### Combining Emu outputs` | 763 | CLEAN | — |
| 4 | `#### Alternative: emu combine-outputs` | 944 | CLEAN | — |
| — | (no `## Troubleshooting` / `## Appendices`) | — | ADD (Appendices; Troubleshooting optional) | S-09 |

## Findings

### S-01 · S1 · Database download has no runtime and no success checkpoint
- **Where:** SOP_EMU_NeSI.md:610-652, § 4 "Setting up the databases"
- **Anchor:** `**Step 1: Create your database directory and install the download tool.**`
- **Quote:**
  > osf -p 56uf7 fetch osfstorage/emu-prebuilt/${EMU_PREBUILT_DB}.tar
  > tar -xvf ${EMU_PREBUILT_DB}.tar
- **Breaks:** R5 (no outcome/checkpoint, no runtime), R4 (the storage exception still needs a legible success signal)
- **Reader impact:** The reader fetches two multi-GB archives with no idea how long it should take or how to tell it worked. `osf fetch` can run many minutes; a beginner may kill it thinking it hung, or proceed after a half-extracted tar. Nothing here confirms the database is complete, so the failure surfaces two sections later as an opaque minimap2 / "file not found" error inside the Emu array, where it is far harder to diagnose.
- **Fix:** Insert after the RDP block (after L646), before "**Note your database path.**":
  > **How long it takes.** Each archive is a few GB; fetch and extract together take roughly 10-30 minutes per database, depending on network load. `osf fetch` prints a progress bar — if it sits at 0% for more than a minute, the problem is your connection, not the command.
  >
  > **Checkpoint.** After extracting each database, confirm the directory holds the two files Emu needs:
  > ```bash
  > ls ${EMU_DATABASE_DIR}
  > ```
  > > **Expect** `species_taxid.fasta` and `taxonomy.tsv` (plus a few smaller files). **If either is missing**, the tar did not extract fully — re-run the `osf fetch` and `tar -xvf` steps. Emu fails later with a minimap2 or "file not found" error if this directory is incomplete.

### S-02 · S2 · "chimera" is used to judge data before it is defined
- **Where:** SOP_EMU_NeSI.md:374, 405 (used) vs 423 (defined), § 3 Step 2/3
- **Anchor:** `Reads above 1,800 bp are likely chimeras.`
- **Quote:**
  > Every dot is one read... Reads above 1,800 bp are likely chimeras. Both tails are removed by chopper in the next step.
- **Breaks:** R2 (term used before definition — a named offender in the spec's R2 list), R8 (plain words first), R1 (layer-2 interpretation without layer-1)
- **Reader impact:** In Step 2 the reader is asked to interpret their own NanoPlot output — "reads above 1,800 bp are likely chimeras" — using a word that is not defined until Step 3 (L423). They cannot judge whether their long tail is a problem, because they do not know what a chimera is or why it matters. The reader who "cannot tell a wrong answer from a right one" is exactly who this blocks.
- **Fix:** At first use (L374 bullet), gloss the term inline, plain words first:
  > - **Read length distribution.** Expect a sharp peak around 1,400-1,500 bp (full-length amplicons), a small peak below ~200 bp (primer dimers or failed amplifications), a tail above 1,800 bp (possible **chimeras** — artificial hybrids formed when one species' amplicon primes another's template during PCR, which cause false species calls), or a broad messy distribution (library-prep problems).

  Then at L405 and L423 the term is already introduced, so L423 can drop "artificial hybrids formed during PCR when an incomplete amplicon from one species primes a different species' template" down to "chimeras (defined in Step 2)" — keeping the reason, removing the duplicate definition.

### S-03 · S2 · Emu's EM algorithm is relied on in Step 3, defined only in Section 4
- **Where:** SOP_EMU_NeSI.md:421 (used) vs 575-581 (defined), § 3 Step 3
- **Anchor:** `its EM algorithm works on the statistical pattern across thousands of reads`
- **Quote:**
  > Emu does not need each read to be perfect; its EM algorithm works on the statistical pattern across thousands of reads, and as long as errors are roughly random... the true composition emerges from the aggregate.
- **Breaks:** R2 (used before defined), R1 (layer-2 justification leaning on a concept not yet introduced)
- **Reader impact:** The whole justification for filtering at Q10 rather than something stricter rests on "the EM algorithm works on the statistical pattern" — but EM is not explained until Section 4 (L575). The reader accepts the threshold on faith, unable to see why per-read imperfection is tolerable, which is precisely the "why this number" content the parameter is supposed to teach.
- **Fix:** Add a one-clause forward-glossed gloss at L421 so the reasoning stands on its own:
  > - **`--quality 10` (minimum average quality Q10).** Removes reads whose average per-base accuracy is below 90%. Emu does not need each read to be perfect: it estimates abundances statistically across thousands of reads (the EM algorithm, detailed in Section 4), so as long as errors are roughly random — which they are in Nanopore data — the true composition emerges from the aggregate. Q10 is the widely used standard for Nanopore 16S.

### S-04 · S2 · NanoPlot-raw step has no job-success checkpoint and two undefined flags
- **Where:** SOP_EMU_NeSI.md:358-370, § 3 Step 2
- **Anchor:** `Once finished, open the HTML report in`
- **Quote:**
  > Submit with `sbatch 01_nanoplot_raw.sh`. No need to array this; it is lightweight and fast. Once finished, open the HTML report in `qc_raw/`.
- **Breaks:** R5 (no checkpoint: "open the report" is not a success test), R2 (`--loglength`, `--plots dot` used in the script, never explained)
- **Reader impact:** If the job fails silently (a mistyped module string is the usual cause), the reader opens `qc_raw/` and finds nothing, with no instruction on what "worked" looks like or where to look. Two script flags (`--loglength`, `--plots dot`) also appear with no explanation, so the reader cannot tell whether to keep or change them.
- **Fix:** Replace "No need to array this; it is lightweight and fast. Once finished, open the HTML report in `qc_raw/`." with:
  > No need to array this — it is lightweight and finishes in a few minutes. `--loglength` plots read length on a log scale (useful when lengths span orders of magnitude) and `--plots dot` draws the length-vs-quality scatter.
  >
  > **Checkpoint.**
  > ```bash
  > ls qc_raw/raw_NanoPlot-report.html
  > ```
  > > **Expect** the report to exist. **If it is missing**, the job failed — read `logs/nanoplot_raw_*.err` (a wrong module string is the usual cause). Once it exists, open it in `qc_raw/`.

### S-05 · S2 · Emu array has no completion checkpoint; manifest check lacks its third part
- **Where:** SOP_EMU_NeSI.md:664-727, § 4 "Running Emu"
- **Anchor:** `Verify: line count should equal your number of samples`
- **Quote:**
  > wc -l emu_manifest.txt
  > ...
  > Monitor with `squeue -u $USER`. Each task writes its own log in `logs/`, so if a sample fails you can check its `.err` file directly.
- **Breaks:** R5 (no success criterion after the array completes; the manifest check states an expected value but not what a mismatch means)
- **Reader impact:** After the array finishes, the reader has no single test that every sample produced output. A task can fail mid-array (out of memory, missing FASTQ) and the reader will not notice until a sample is silently absent from the combined table two steps later. The manifest check (L666) says "should equal your number of samples" but never says what to do if it does not.
- **Fix:** (a) Extend the manifest check at L666:
  > ```bash
  > wc -l emu_manifest.txt
  > ```
  > > **Expect** the same number as your barcode/sample count. **Fewer** means a filtered FASTQ is missing — re-check that Step 3 finished for every sample before submitting the array.

  (b) After "Monitor with `squeue -u $USER`..." (L727), add:
  > **Checkpoint.** When the array finishes, confirm every task produced a result:
  > ```bash
  > ls -1 emu_results/silva/*_rel-abundance.tsv | wc -l
  > ```
  > > **Expect** the same number as `wc -l emu_manifest.txt`. **Fewer** means some tasks failed — list them with `sacct -j <job_id> --format=JobID,State,ExitCode` and read the matching `logs/emu_<A>_<task>.err`.

### S-06 · S3 · Runtimes absent from the NanoPlot and chopper steps
- **Where:** SOP_EMU_NeSI.md:368, 475, 511, § 3 Steps 2-4
- **Anchor:** `No need to array this; it is lightweight and fast.`
- **Quote:**
  > Submit with `sbatch 01_nanoplot_raw.sh`. No need to array this; it is lightweight and fast.
- **Breaks:** R5 (step template item 4 — an order-of-magnitude runtime, "six words that stop a reader wondering whether the job has hung")
- **Reader impact:** "Lightweight and fast" and "chopper is fast" are not runtimes. A beginner with no sense of scale cannot tell a job that is working from one that has hung, and may cancel a running job. (Emu's ~10 min/task at L656 is the one step that does state a magnitude.)
- **Fix:** Add one clause per step. Step 2 (L368): "…finishes in a few minutes" (folded into S-04). Step 3 (L475): change "No array needed; chopper is fast." to "No array needed — chopper filters a typical run in a few minutes (roughly 7x faster than NanoFilt)." Step 4 (L511): change "Submit with `sbatch 03_nanoplot_filtered.sh`." to "Submit with `sbatch 03_nanoplot_filtered.sh`; it finishes in a few minutes, like the raw run."

### S-07 · S3 · "Interpreting NanoPlot output" repeats per-step interpretation mid-walkthrough
- **Where:** SOP_EMU_NeSI.md:539-557, § 3 (between Step 4 and § 4)
- **Anchor:** `NanoPlot produces several plots. You do not need all of them`
- **Quote:**
  > NanoPlot produces several plots. You do not need all of them; these are the key ones.
- **Breaks:** R3 / §3 (reference material — "which plots exist and what each shows" — sitting in the walkthrough, after the two steps that already interpret the same plots at L372-377 and L513-517)
- **Reader impact:** The reader has already read how to read the length histogram and the length-vs-quality scatter twice (raw in Step 2, filtered in Step 4). This third pass is lookup material, not a performed step, and it breaks the run-order momentum before Section 4. It is not wrong, but it is in the wrong place and partly duplicated.
- **Fix:** Move the plot-by-plot reference (the "Read length histogram (filtered)", "Read length vs quality scatter (filtered)", "Other plots", "For your thesis" blocks) into a new `## Appendices` -> "NanoPlot plot reference" at the back. Leave the two images in place inside Step 4, and keep one line at L539 pointing there: "For a plot-by-plot reference (including the log-scaled, weighted and cumulative-yield plots), see the NanoPlot appendix." No prose is lost; it is relocated.

### S-08 · S3 · Script filenames carry a step index, not their section number
- **Where:** SOP_EMU_NeSI.md:340, 425, 483, 669, § 3 and § 4
- **Anchor:** `Test your resources first: submit a small range`
- **Quote:**
  > Create a SLURM script called `01_nanoplot_raw.sh`
- **Breaks:** R6 (script filenames must carry the number of the section that defines them; §8 "number matching the section")
- **Reader impact:** Section 3's scripts are named `01_`, `02_`, `03_` and Section 4's is `emu_array.sh` (no number). The convention (README:47, spec R6/§8) is that a Section-3 script is `03…` and a Section-4 script is `04…`, so a reader who lands mid-document cannot map a filename back to its section, and the numbering "fights the run order" the spine promises. This is the exemplar's own drift from the rule the other SOPs are told to follow.
- **Fix:** Rename with section-numbered, suffixed names and update every reference: `01_nanoplot_raw.sh` -> `03a_nanoplot_raw.sh`; `02_chopper_filter.sh` -> `03b_chopper_filter.sh`; `03_nanoplot_filtered.sh` -> `03c_nanoplot_filtered.sh`; `emu_array.sh` -> `04a_emu_array.sh`; `emu_array_rdp.sh` -> `04b_emu_array_rdp.sh`; `combine_emu_results.py` may stay (it is a helper, not a numbered job, but `04_combine_emu_results.py` is more consistent). Update the `#SBATCH --output/--error` log prefixes to match.

### S-09 · S3 · Template deviations: roadmap, "Before you start", Troubleshooting, Appendices
- **Where:** SOP_EMU_NeSI.md:21-28 and document-wide, § front matter
- **Anchor:** `## Analysis steps`
- **Quote:**
  > ## Analysis steps
- **Breaks:** R3 / §3 (document template: ASCII roadmap, `### Before you start`, `## Troubleshooting`, `## Appendices`), §9.5 (scope limits belong in a stated Before-you-start)
- **Reader impact:** The roadmap is a numbered prose list, not the ASCII block the template (and README:46) prescribe, so a scanner gets no at-a-glance stage map. There is no `### Before you start` gathering prerequisites (the NeSI account/project code is buried in a blockquote at L32), what the document does *not* cover, and where to go if a prerequisite is missing. There is no Troubleshooting or Appendices section, so references and reference tables sit mid-walkthrough. A never-touched-terminal reader has no single "am I ready / is this the right document" block before the commands begin.
- **Fix:** (a) Relabel L21 `## Quick roadmap` and convert the list to an ASCII block, e.g.:
  > ```
  > [1] Getting started on NeSI   ->  login, bash, modules, SLURM, arrays
  > [2] Understanding your data   ->  16S, amplicons, Nanopore, quality, FASTQ
  > [3] Processing reads          ->  NanoPlot QC -> chopper filter -> NanoPlot QC
  > [4] Emu profiling             ->  databases -> array run -> combined tables
  >          |
  >          v  count + taxonomy tables  ->  SOP_R_Analysis.md (Part 2)
  > ```
  > (b) Add `### **Before you start**` after the intro paragraph, ~40 words / 3 bullets, pulling the account/project-code line up from L32:
  > - **You need** a NeSI account and project code (`<your_nesi_project_code>`), your raw Nanopore FASTQs, and about a day of wall-clock time across the queue.
  > - **This does not cover** the R statistics (that is Part 2, `SOP_R_Analysis.md`) or short-read Illumina 16S (no ASV workflow here yet).
  > - **No prior terminal experience needed** — this document starts at `pwd`. For more grounding first, see the Genomics Aotearoa links in the appendix.
  > (c) Add `## Appendices` at the back holding: the module-versions table (currently L11-19), the "Further reading" links (L195-204), the citations, and the NanoPlot plot reference moved by S-07. A `## Troubleshooting` section is optional — the inline R10 failure notes are a strength and should not be pulled out; a short "where failures show up" pointer table is enough if one is wanted.

### S-10 · S3 · Seven paragraphs/bullets exceed the 80-word limit (F1)
- **Where:** SOP_EMU_NeSI.md:36, 42, 189, 193, 370, 761, 755
- **Anchor:** `A typical laptop has 8-16 GB of RAM and 2-4 CPU cores`
- **Quote:**
  > NeSI... is a national high-performance computing platform, a very powerful shared computer that researchers across New Zealand use... A typical laptop has 8-16 GB of RAM and 2-4 CPU cores; NeSI nodes can have 256+ GB and 64+ cores...
- **Breaks:** F1 (over 80 words), F2/R3 (a definition long enough to be a concept section), F5 (reasoning woven into a long bullet at L755)
- **Reader impact:** Six prose paragraphs (L36 96w, L189 87w, L370 84w, L761 83w, L42 82w, L193 81w) and one bullet (L755 111w) exceed the limit and read as walls of text to a scanning reader. (The scan reports 12; five — L752, L421, L374, L743, L238, L165 — are the script merging adjacent bullets, whose individual bullets measure 64-73w and pass.) All carry load-bearing content, so each is split or tightened, not cut; net words stay flat.
- **Fix:** Paste-ready replacements:

  **L36 (split in two):**
  > NeSI (New Zealand eScience Infrastructure) is a national high-performance computing platform — a powerful shared computer researchers across New Zealand use. Bioinformatic analyses need more memory, CPU and storage than a laptop provides: a laptop has 8-16 GB of RAM and 2-4 cores; NeSI nodes have 256+ GB and 64+ cores.
  >
  > It also pre-installs most bioinformatics tools as modules, so you skip installation and dependency management, and it runs long jobs in the background — submit a job, close your laptop, do labwork, come back for the results.

  **L42 (split):**
  > One gotcha with Jupyter Lab: the terminal and file-explorer panes work independently. `cd`-ing in the terminal does not move the explorer, and clicking folders in the explorer does not change the terminal's working directory.
  >
  > If your scripts seem to be missing, check the explorer is pointing at your working directory, not the landing folder. Right-click a folder and choose **Open in Terminal** to launch a terminal already pointed there.

  **L189 (split):**
  > **Choosing resources.** Start modest (1 hour, 4 GB, 2 CPUs) and raise a setting if the job runs out of time or memory — the `.err` file's "OUT OF MEMORY" or "TIMEOUT" tells you which.
  >
  > **Do not over-request.** Bigger requests queue longer, because SLURM must find a larger slot, and NeSI staff flag persistent over-requesting. After a job or test batch finishes, run `nn_seff <job_id>` to see the time and memory it actually used, and right-size the next submission.

  **L193 (split):**
  > To process many files in parallel (e.g., hundreds of samples), SLURM supports **array jobs**: one script, with the range set at submission — `sbatch --array=1-N%20 myjob.sh` runs N copies (throttled to 20), each with a different `$SLURM_ARRAY_TASK_ID` counting from 1.
  >
  > Keeping the range out of the header means the same script works for any sample count, and this is far faster than a loop for heavy steps like Emu classification.

  **L370 (split):**
  > `--fastq raw_files/*.fastq` passes every barcode at once, so this report **pools all barcodes into one dataset** — use it to judge whether the *run* succeeded (length peak, median quality, N50), not any single sample.
  >
  > Per-barcode signals come from elsewhere: read counts from the Step 1 loop, and per-barcode retention from the Step 3 chopper log. To QC one suspect barcode alone, run NanoPlot on just that file (`NanoPlot --fastq raw_files/barcode07.fastq --outdir qc_raw/barcode07 --prefix barcode07_ --threads 8`).

  **L761 (split; why-this-number kept whole):**
  > **About estimated counts.** Emu's counts are not always whole numbers — you might see 4.6 instead of 5. The EM algorithm distributes ambiguous reads probabilistically, so a read mapping equally well to two species contributes 0.5 to each; per the Emu docs, the count is relative abundance x total classified reads, which is why it is fractional.
  >
  > We round to whole numbers in R before analysis. This adds a little imprecision but is necessary for count-based methods.

  **L755 (tighten to 80w; every fact kept):**
  > - `--min-pid 90` — minimum percent identity, from the NM tag (default `0`, no filter). The value is a **percent out of 100**: `90` means 90%; writing `0.9` reads as 0.9% and filters nothing. Setting `90` drops very poor matches — fewer false positives, but risks missing divergent taxa. The default (no filter, letting EM resolve ambiguities statistically) is usually better for noisy long reads, so raise it only when chasing false positives, and compare against your unfiltered run rather than replacing it.

### S-11 · S4 · Headings are not bold and not consistently title case (§8)
- **Where:** SOP_EMU_NeSI.md:30 and every `##`/`###` heading, document-wide
- **Anchor:** `## 1. Getting Started on NeSI`
- **Quote:**
  > ## 1. Getting Started on NeSI
- **Breaks:** R9 (one house style/voice), §8 (Headings: `## **N. Title**` and `### **Title**`, bold, title case)
- **Reader impact:** No heading in the document is bold, and subsection headings are sentence case ("What is NeSI and why we use it"), where the spec mandates `## **N. Title**` / `### **Title**` in bold title case. This is the exemplar drifting from the rule the other three SOPs are measured against, so it propagates as "the pattern".
- **Fix:** Wrap every section and subsection heading in `**…**` and title-case them, e.g. `## **1. Getting Started on NeSI**`, `### **What Is NeSI and Why We Use It**`, `### **Filtering with Chopper**`. Apply to all 30 headings. (Question-form subsection titles in §2 may keep sentence case if the lab prefers, but must still be bold — flag for the seam agent to settle one way across all four documents.)

### S-12 · S4 · Six V3 banned words survive
- **Where:** SOP_EMU_NeSI.md:64, 287, 422, 573, 581, 636
- **Anchor:** `Same pattern, just change the two`
- **Quote:**
  > **Step 3: Download RDP.** Same pattern, just change the two `export` lines:
- **Breaks:** R9 (one voice), V3 (banned: `just`, `easily`, `clearly`)
- **Reader impact:** Six of the spec's banned words remain (the set target is "twelve, to beat"): L64 "Just `rm`", L287 "sequence just the V3-V4 region", L422 "clearly truncated reads", L573 "could easily be sequencing error", L581 "clearly map to A", L636 "just change the two". Each quietly signals "this is obvious", which the spec bans because if it were obvious the sentence would not be there.
- **Fix:** L64 "Just `rm`." -> "Use plain `rm`." · L287 "we typically sequence just the V3-V4 region" -> "we typically sequence only the V3-V4 region" · L422 "Removes clearly truncated reads" -> "Removes truncated reads" · L573 "that 0.5% could easily be sequencing error" -> "that 0.5% may be sequencing error" · L581 "thousands of other reads clearly map to A" -> "thousands of other reads map cleanly to A" · L636 "Same pattern, just change the two `export` lines" -> "Same pattern; change only the two `export` lines".

### S-13 · S4 · US spelling "capitalizations"
- **Where:** SOP_EMU_NeSI.md:130, § 1 "Using modules"
- **Anchor:** `case-sensitive, try different capitalizations`
- **Quote:**
  > module spider NanoPlot             # case-sensitive, try different capitalizations
- **Breaks:** R9 (one voice), V5 (UK spelling)
- **Reader impact:** Minor, but the document is otherwise consistently UK-spelled (normalise, optimised, organised, labelled), so this single US form is a house-style slip. ("Expectation-Maximization" at L575 is the algorithm's proper name and is left as-is per V5.)
- **Fix:** Change "try different capitalizations" to "try different capitalisations".

## Target outline

The heading structure the document should have when finished, in order. Build from this plus the findings without re-reading the original.

```
*Taylor Lab | Full-Length 16S rRNA Nanopore SOP*                     KEEP
# **Part 1: NeSI Pipeline (Sequencing to Count Tables)**             KEEP
**v2.0** | last updated July 2026 | NeSI (SLURM) | ...               KEEP
<intro paragraph, tightened>                                         REWRITE (tighten, keep scope + "starts at pwd")
### **Before you start**                                             NEW — 3 bullets: prerequisites (NeSI account+project code, raw FASTQs); what this does NOT cover (stats=Part 2, Illumina=not yet); no terminal experience needed, pointer to appendix links. ~40 words. [S-09]
## **Quick roadmap**                                                 REWRITE — ASCII block, 4 stages in run order + handoff to Part 2. [S-09]
## **1. Getting Started on NeSI**                                    KEEP (bold) [S-11]
  ### **What Is NeSI and Why We Use It**                             KEEP + tighten L36 [S-10]
  ### **Logging In**                                                 KEEP + tighten L42 [S-10]
  ### **Basic Bash Commands**                                        KEEP
  ### **Using Modules**                                              KEEP (fix "capitalisations") [S-13]
  ### **SLURM: Running Jobs on the Cluster**                         KEEP (canonical header defined here) + tighten L189 [S-10]
  ### **A Note on Array Jobs**                                       KEEP + tighten L193 [S-10]
## **2. Understanding Your Data**                                    KEEP (bold)
  ### **What Is 16S rRNA…**                                          KEEP
  ### **What Is an Amplicon?**                                       KEEP
  ### **How Does Nanopore Sequencing Work?**                         KEEP
  ### **What Are Quality Scores?**                                   KEEP
  ### **What Does a FASTQ File Look Like?**                          KEEP
  ### **What Does Nanopore Data Look Like on Disk?**                 KEEP
  ### **Full-Length vs Short-Read: Why It Matters**                  KEEP
## **3. Processing Nanopore Reads**                                  KEEP (bold)
  ### **Step 1. Organise Your Raw Data**                             KEEP (script -> 03a) [S-08]
  ### **Step 2. Quality Assessment of Raw Reads**                    REWRITE — add chimera gloss [S-02], job checkpoint + flag note [S-04], runtime [S-06], tighten L370 [S-10]; script -> 03a
  ### **Step 3. Filtering with Chopper**                             REWRITE — add EM gloss [S-03], runtime [S-06]; script -> 03b
  ### **Step 4. Quality Assessment of Filtered Reads**              REWRITE — add runtime [S-06]; script -> 03c
## **4. Taxonomy and Community Profiling with Emu**                  KEEP (bold)
  ### **What Emu Does and Why We Use It**                            KEEP
  ### **Understanding the Reference Databases**                      KEEP
  ### **Setting Up the Databases**                                   REWRITE — add runtime + checkpoint [S-01]; scripts -> 04
  ### **Running Emu**                                                REWRITE — completion checkpoint [S-05], tighten L755 [S-10]; script -> 04a/04b
  ### **Combining Emu Outputs**                                      KEEP
    #### **Alternative: emu combine-outputs**                        KEEP
## **Troubleshooting**                                               NEW (optional) — short pointer table only; do NOT move the inline R10 failure notes out. [S-09]
## **Appendices**                                                    NEW — holds: module-versions table (from front matter), Further-reading links (from §1), NanoPlot plot reference (moved from §3 "Interpreting NanoPlot output" [S-07]), citations (Curry 2022, De Coster & Rademakers 2023, Quast 2013). [S-07, S-09]
```

## Keep list

Content that must survive a restructure. A move is where these get dropped.

1. **Threshold justifications** — L419-423, "Why these thresholds" (Q10 / 1200 / 1800, with the 1,400-1,540 bp gene-length reason). Layer-2 crown jewels; tempting to compress when splitting the over-long bullets. Anchor: `a 1,500 bp floor would discard many legitimate full-length reads`.
2. **Array `1-1` placeholder silent-failure warning** — L725, "the job succeeds with no error, and every other sample is silently missing." Anchor: `only the first sample is processed`.
3. **`--keep-counts` "do not omit / re-run from scratch"** — L745. Expected-output + silent-failure. Anchor: `essential, do not omit`.
4. **`grep "^@"` count-inflation warning** — L462-464. Silent failure (why lines/4, not grep). Anchor: `silently inflates the count`.
5. **min-pid `0.9` vs `90` trap** — L755. Silent failure; survives inside the S-10 tightened bullet. Anchor: `Emu reads that as 0.9% identity`.
6. **EM / why-not-best-hit** — L571-583. The concept the reader genuinely lacks + why Emu over alternatives. Anchor: `EM uses **community context** to resolve ambiguous reads`.
7. **SILVA v138.1 vs 138.2 version note** — L599. Why this (validated) build. Anchor: `has not yet been tested or validated with Emu`.
8. **Run-both-databases rationale** — L608. Why this choice. Anchor: `A taxon appearing in both SILVA and RDP results is more likely genuinely present`.
9. **nobackup "if you `rm`... it is gone"** — L50/L64. Irreversible-failure warning. Anchor: `If you `rm` something on nobackup, it is gone`.
10. **basename-collision exit in combine script** — L826-832. Silent failure (two samples -> one column). Anchor: `write the other's into two identically named columns`.
11. **Verify-output else-branch rationale** — L940. How to tell the combine step silently produced nothing. Anchor: `which reads like success`.
12. **Full-length vs short-read interpretation caveat** — L295-297. Concept + scope of cross-platform interpretation. Anchor: `overall alpha diversity may appear lower with Nanopore`.
13. **`--chdir` runs-too-late reasoning** — L165. Why the canonical header uses `--chdir`, not in-script `cd`. Anchor: `that runs too late, after SLURM has already tried`.
14. **Primary citations** — Curry et al. 2022 (L567), De Coster & Rademakers 2023 (L415), Quast et al. 2013 (L591). Move to Appendix, never drop.

## Rewrite plan

Ordered, dependency-aware. The whole document can be rewritten independently of the other three files — it references only itself and Part 2 by filename; no cross-file content depends on this pass, and this pass depends on none.

1. **Voice sweep (S-11, S-12, S-13)** — mechanical, no restructure. Bold + title-case all 30 headings, fix six banned words and "capitalisations". Do first; it touches every heading and is safe. Closes S-11, S-12, S-13. ~0 net words.
2. **In-place content fixes (S-02, S-03)** — add the chimera gloss at L374 and the EM gloss at L421; trim the duplicate chimera definition at L423. No lines move. Closes S-02, S-03; protects keep-list items 1 and 6. +~25 words.
3. **Checkpoints and runtimes (S-01, S-04, S-05, S-06)** — insert the checkpoint blocks and one-line runtimes at each step. Local insertions, no reordering. Closes S-01 (the one S1), S-04, S-05, S-06. +~120 words.
4. **F1 tightening (S-10)** — apply the seven paste-ready splits/rewrites. Do after step 2 so the chimera/EM edits are already in the affected bullets. Closes S-10; keeps net words roughly flat (offsets the additions in step 3). ~-40 words.
5. **Structural moves (S-07, S-08, S-09)** — the restructure, done last because it relocates blocks the earlier steps edited in place: add `### Before you start`, convert the roadmap to ASCII, rename scripts `03a/03b/03c/04a/04b` and update every reference and log prefix, create `## Appendices` and move Further-reading + module table + the NanoPlot plot reference into it. Highest regression risk — check the keep list (items 1, 11, 14 especially) survives the moves. Closes S-07, S-08, S-09. Net words flat (relocation, not addition).

Expected end state: layer-1 heading count unchanged and high (§2/§4 concept subsections all retained), over-80 paragraph count 0, all job scripts still complete (R11 untouched). Net word change roughly +100 (checkpoints/glosses) minus the F1 tightening — close to flat, as the brief requires.

---

### Self-check

```
findings=13 S1=1 S2=4 S3=5 S4=3
CLEAN
```

Confirmed by hand: the section ledger accounts for every `##`/`###`/`####` heading in the document (30 headings plus the two missing template sections); the target outline covers every section in the ledger; nothing on the keep list is proposed for removal (all keep-list items are KEEP or relocate-only).

CONTRACT: PASS
