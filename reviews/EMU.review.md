## Document: SOP_EMU_NeSI.md

This is Part 1 of the lab's pipeline set: it takes a student who has never opened
a terminal from `pwd` through NeSI onboarding (bash, modules, SLURM), 16S/Nanopore
background, NanoPlot QC, chopper filtering, Emu profiling, and combining per-sample
outputs into count tables. It is close to doing that job well — the technical
core is sound. I built fixtures and ran the actual chopper command, the actual
`emu combine-outputs` subcommand, and the SOP's own custom combiner on both
taxonomy formats; every core command works exactly as written, every module and
flag exists at the pinned version, and both OSF archive paths resolve. The
worked-example arithmetic checks out and the Phred/ASCII reasoning (including
"`@` is Q31") is correct. The findings are not in the biology or the commands;
they are in **operational safety and consistency**: SLURM log paths that break if
the reader submits from the wrong directory, a per-barcode QC section that runs a
pooled report, a verify step wired only to one of two documented combine paths,
and a placeholder that fights the README. The single change that would most
improve it: add `#SBATCH --chdir <workspace>` to every job header (the README
already mandates this) so the scripts are actually location-independent.

## Section ledger

| § | Heading | Lines | Verdict | Findings |
|---|---|---|---|---|
| — | (title) Part 1: NeSI Pipeline | 3-19 | CLEAN | — |
| — | Analysis steps | 21-28 | CLEAN | — |
| 1 | Getting Started on NeSI | 30-33 | CLEAN | — |
| 1.x | What is NeSI and why we use it | 34-37 | CLEAN | — |
| 1.x | Logging in | 38-64 | CLEAN | — |
| 1.x | Basic bash commands | 66-122 | CLEAN | — |
| 1.x | Using modules | 124-136 | CLEAN | — |
| 1.x | SLURM: running jobs on the cluster | 138-180 | TIGHTEN | F-02, F-06 |
| 1.x | A note on array jobs | 182-184 | CLEAN | — |
| 1.x | Further reading | 186-195 | CLEAN | — |
| 2 | Understanding Your Data | 197-199 | CLEAN | — |
| 2.x | What is 16S rRNA and why do we sequence it? | 201-211 | CLEAN | — |
| 2.x | What is an amplicon? | 213-221 | CLEAN | — |
| 2.x | How does Nanopore sequencing work? | 223-231 | CLEAN | — |
| 2.x | What are quality scores? | 233-242 | CLEAN | — |
| 2.x | What does a FASTQ file look like? | 244-257 | CLEAN | — |
| 2.x | What does Nanopore data look like on disk? | 259-274 | CLEAN | — |
| 2.x | Full-length vs short-read: why it matters | 276-288 | CLEAN | — |
| 3 | Processing Nanopore Reads | 290-292 | CLEAN | — |
| 3.1 | Step 1. Organise your raw data | 294-325 | CLEAN | — |
| 3.2 | Step 2. Quality assessment of raw reads | 327-399 | REWRITE | F-01, F-03 |
| 3.3 | Step 3. Filtering with chopper | 401-464 | TIGHTEN | F-04 |
| 3.4 | Step 4. Quality assessment of filtered reads | 466-523 | TIGHTEN | F-04 |
| 3.x | Interpreting NanoPlot output | 525-543 | CLEAN | — |
| 4 | Taxonomy and Community Profiling with Emu | 545-547 | CLEAN | — |
| 4.x | What Emu does and why we use it | 549-569 | CLEAN | — |
| 4.x | Understanding the reference databases | 571-594 | CLEAN | — |
| 4.x | Setting up the databases | 596-638 | EXPAND | (Gaps: db-path check) |
| 4.x | Running Emu | 640-744 | TIGHTEN | F-06 |
| 4.x | Combining Emu outputs | 746-748 | CLEAN | — |
| 4.x | Option A: emu combine-outputs | 750-784 | TIGHTEN | F-05 |
| 4.x | Option B: Custom combiner script | 786-955 | CLEAN | F-05 (verify block) |

Every markdown heading in the file is accounted for above. (Lines 155, 427, 648,
651, 673, 677, 688, 775, 778, 905 are `#`-prefixed *bash comments inside code
fences*, not headings, and are excluded.)

## Findings

### F-01 · S2 · SLURM logs use a relative path; job fails if submitted outside the workspace
- **Where:** SOP_EMU_NeSI.md:340, § 3 Step 2 (and every later SLURM script: 341, 422-423, 479-480, 665-666)
- **Anchor:** `#SBATCH --output logs/nanoplot_raw_%j.out`
- **Quote:**
  > #SBATCH --output logs/nanoplot_raw_%j.out
  > #SBATCH --error logs/nanoplot_raw_%j.err
  >
  > cd /nesi/nobackup/<your_nesi_project_code>/<your_project>/
- **Defect:** SLURM opens the `--output`/`--error` files *before* the script body
  runs, resolving a relative path against the **submission** directory, not the
  `cd` target inside the script. `logs/` exists only in the workspace. There is no
  `#SBATCH --chdir` and no instruction to submit from the workspace, yet the
  in-body `cd` makes the script look location-independent.
- **Failure:** A reader with no terminal experience opens a fresh shell (lands in
  `~`), runs `sbatch 01_nanoplot_raw.sh` from there. SLURM cannot create
  `~/logs/nanoplot_raw_%j.out` (no `~/logs`), the job fails at launch with an
  opaque "unable to open file" error and produces no output, and the reader has no
  way to see why the QC step "did nothing."
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED
- **Evidence:** `reviews/00_ENVIRONMENT.md` Q1 settles the mechanism: `sbatch`
  resolves a relative `-o`/`-e` path relative to `--chdir` (and, absent `--chdir`,
  the submit directory), *not* the submit-time working directory changed by a
  later in-script `cd`. The script's `cd` appears after the `#SBATCH` lines, so it
  cannot affect log creation. README:55 mandates exactly the fix this omits
  (`#SBATCH --chdir <absolute workspace path>`, "log paths relative to it").
- **Fix:** Add `--chdir` to every job header and drop the in-body `cd`. For
  `01_nanoplot_raw.sh`:
  ```bash
  #!/bin/bash -e
  #SBATCH --account <your_nesi_project_code>
  #SBATCH --job-name nanoplot_raw
  #SBATCH --chdir /nesi/nobackup/<your_nesi_project_code>/<your_project>
  #SBATCH --time 00:30:00
  #SBATCH --mem 8G
  #SBATCH --cpus-per-task 8
  #SBATCH --output logs/nanoplot_raw_%j.out
  #SBATCH --error logs/nanoplot_raw_%j.err

  module purge
  module load NanoPlot/1.43.0-foss-2023a-Python-3.11.6
  # ... (no `cd` needed; --chdir has already put you in the workspace)
  ```
  Apply the same `--chdir` line to `02_chopper_filter.sh`, `03_nanoplot_filtered.sh`
  and `emu_array.sh`, removing their in-body `cd`. `logs/` is created in § 3 Step 1,
  which already precedes every submission.

### F-02 · S3 · Email placeholder appends a domain, contradicting README's whole-address rule
- **Where:** SOP_EMU_NeSI.md:174, § 1 SLURM email notifications
- **Anchor:** `#SBATCH --mail-user <your_email>@auckland.ac.nz`
- **Quote:**
  > #SBATCH --mail-user <your_email>@auckland.ac.nz   # where notifications go
- **Defect:** README:51 defines the placeholder as "`<your_email>` (the whole
  address, domain included)". Here it is written as a local part with
  `@auckland.ac.nz` appended, the opposite convention.
- **Failure:** A reader who learned the placeholder set from the README substitutes
  their full address, producing `alice@auckland.ac.nz@auckland.ac.nz`. Job-state
  emails silently go nowhere, so the `TIME_LIMIT_80` warning the SOP calls "the
  most useful" never arrives.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED
- **Evidence:** README:51 ("the whole address, domain included") directly
  contradicts SOP:174, which treats `<your_email>` as the local part.
- **Fix:**
  ```bash
  #SBATCH --mail-user <your_email>            # your full email, e.g. alice@auckland.ac.nz
  ```

### F-03 · S3 · NanoPlot pools all barcodes into one report; per-barcode interpretation impossible
- **Where:** SOP_EMU_NeSI.md:349 (command) and 364 (guidance), § 3 Step 2
- **Anchor:** `--fastq raw_files/*.fastq`
- **Quote:**
  > --fastq raw_files/*.fastq
  > …
  > **Total yield and read count.** For 16S you generally want at least
  > 10,000-50,000 reads per barcode.
- **Defect:** `--fastq` takes multiple files and **pools them into one dataset**,
  so this produces a single run-level report. The interpretation bullets are
  per-barcode ("at least 10,000-50,000 reads *per barcode*"; "A median below Q10
  means poor run quality"), but a pooled report cannot attribute quality or counts
  to any one sample. The SOP's own worked `raw_NanoStats.txt` confirms pooling:
  "Number of reads: 21,019,028" is the whole run, not one barcode.
- **Failure:** A reader with 24 barcodes, one of which was degraded (normal read
  count, median Q8), sees a healthy pooled median (~Q18-Q24 in the example) and
  concludes per-barcode QC passed. The bad barcode is invisible here; its junk
  taxa later read as biology.
- **Type:** CLARITY
- **Confidence:** VERIFIED
- **Evidence:** `NanoPlot --help` (module `NanoPlot/1.43.0-foss-2023a-Python-3.11.6`):
  ```
  --fastq file [file ...]
  ```
  and its own example `NanoPlot -t 2 --fastq reads1.fastq.gz reads2.fastq.gz …`
  — multiple files, one report. The SOP's example NanoStats (`:375`) reports one
  pooled read count for the entire run.
- **Fix:** State plainly that this is a **pooled, run-level** report and route
  per-barcode checks to steps that are per-barcode:
  > This report pools every barcode into one dataset, so use it to judge whether
  > the **run** succeeded (overall length peak, overall median quality, N50).
  > **Per-barcode** signals come from elsewhere: read counts from the Step 1 loop
  > (compare against your barcode sheet), and per-barcode retention from the
  > Step 3 chopper log (a barcode retaining <~30% is flagged there). To QC a
  > single suspect barcode on its own, run NanoPlot on just that file:
  > `NanoPlot --fastq raw_files/barcode07.fastq --outdir qc_raw/barcode07 --prefix barcode07_ --threads 8`.

### F-04 · S3 · Stated retention range (60-80%) is contradicted by the SOP's own worked example (~85%)
- **Where:** SOP_EMU_NeSI.md:464 (and 503, 505), § 3 Steps 3-4
- **Anchor:** `typically retain 60-80% of reads`
- **Quote:**
  > You should typically retain 60-80% of reads.
  > …
  > **Read count.** A drop of 20-40% is typical.
  > …
  > we retained about 17.8M of 21M reads (~85%)
- **Defect:** Two places state the expected retention as 60-80% (equivalently a
  20-40% drop), but the worked filtered example reports ~85% retained (~15% drop)
  — above both stated ranges. The numbers that describe a "typical" result and the
  numbers in the exemplar of a good result disagree.
- **Failure:** A reader whose clean library retains 84% checks the guidance, reads
  "60-80% typical / 20-40% drop," and worries their filter under-performed or the
  thresholds are wrong — chasing a non-problem, or distrusting a correct result.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED
- **Evidence:** Internal contradiction: SOP:464 "typically retain 60-80%" and
  SOP:503 "drop of 20-40% is typical" vs SOP:505 "~85%".
- **Fix:** Reconcile the range with the example, e.g. at :464:
  > You should typically retain **60-85%** of reads; a clean library (like the
  > worked example below, ~85%) sits at the top of that band. Retaining under
  > ~50% overall, or under ~30% for a single barcode, suggests quality or
  > fragmentation problems — check that barcode's NanoPlot output.
  And at :503 change "A drop of 20-40% is typical" to "A drop of **15-40%** is
  typical."

### F-05 · S3 · Final verify block matches only Option B's filename; Option A user gets no output
- **Where:** SOP_EMU_NeSI.md:950 (verify block) with 770 (Option A output), § 4 Combining
- **Anchor:** `f="emu_results/${db}/emu-combined-counts_${db}.tsv"`
- **Quote:**
  > f="emu_results/${db}/emu-combined-counts_${db}.tsv"
  > [ -f "$f" ] && echo "$(head -1 $f | tr '\t' '\n' | tail -n +9 | wc -l) samples, …"
- **Defect:** The verify loop looks for `emu-combined-counts_<db>.tsv`, which is the
  **Option B** (custom-script) name. Option A (`emu combine-outputs`) writes
  `emu-combined-<rank>.tsv` and `emu-combined-<rank>-counts.tsv` instead, so the
  `[ -f "$f" ]` guard silently skips and the block prints an empty section. The SOP
  also documents Option A's output only as `emu-combined-<rank>.tsv` (:770) and
  never gives the `--counts` filename, so an Option A reader cannot even predict
  what to look for.
- **Failure:** A reader picks Option A (presented as a full, equal option), runs the
  verify block, sees no lines and no error, and cannot tell whether the combine
  step worked or silently failed.
- **Type:** CONSISTENCY
- **Confidence:** VERIFIED
- **Evidence:** Ran both under `Emu/3.6.2` on a two-sample fixture:
  ```
  $ emu combine-outputs silva species
  Combined table generated: silva/emu-combined-species.tsv
  $ emu combine-outputs silva species --counts
  Combined table generated: silva/emu-combined-species-counts.tsv
  ```
  Neither matches `emu-combined-counts_silva.tsv`; the verify block found the file
  only when Option B (`combine_emu_results.py`) had produced it.
- **Fix:** State Option A's filenames at :770 —
  > **Output:** `emu-combined-<rank>.tsv` (abundance) and, with `--counts`,
  > `emu-combined-<rank>-counts.tsv`.
  — and make the closing verification independent of which option was used:
  ```bash
  # Works for either combine option: lists whatever combined tables exist
  for db in silva rdp; do
      echo "=== ${db} ==="
      ls -1 emu_results/${db}/emu-combined-*.tsv 2>/dev/null || echo "  (no combined tables — did the combine step run?)"
  done
  ```

### F-06 · S4 · Polish: SBATCH option style, a taught-but-unused flag, asymmetric NanoPlot walltimes
- **Where:** SOP_EMU_NeSI.md:664 (and 150, 340, 479), §§ 1, 3, 4
- **Anchor:** `#SBATCH --array=0-23                  # CHANGE to match your sample count (0 to N-1)`
- **Quote:**
  > #SBATCH --array=0-23                  # CHANGE to match your sample count (0 to N-1)
- **Defect:** Three small inconsistencies: (a) this line uses `--array=0-23` with an
  `=`, while every other `#SBATCH` line in the document and the README convention
  (README:55, "space-separated options") use a space; (b) the teaching template
  (:150) introduces `--mem-per-cpu 4G` and `--ntasks 1`, but all four real scripts
  use `--mem` and omit `--ntasks`, so the memory form the reader is taught is never
  reused; (c) the raw NanoPlot job gets `--time 00:30:00` (:340) but the filtered
  NanoPlot job — fewer reads — gets `--time 01:00:00` (:479).
- **Failure:** A reader copies the template's `--mem-per-cpu`/`--ntasks` forms into
  a new script, or puzzles over why the smaller filtered job needs double the
  walltime, losing a little time and confidence. None of it changes results.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED
- **Evidence:** SOP:150 (`--mem-per-cpu 4G`, `--ntasks 1`) vs :338/:420/:477/:662
  (all `--mem`, no `--ntasks`); SOP:340 (`--time 00:30:00`) vs :479 (`--time 01:00:00`).
- **Fix:** Change `--array=0-23` to `--array 0-23`; use `--mem` in the template so
  it matches the real scripts; set both NanoPlot jobs to the same walltime
  (`00:30:00` is ample for both).

## Verified against the cluster

Every check I ran, including the ones that **held** (a held check tells the next
reader not to re-run it). Probes on NeSI Mahuika, `2026-07-31`, modules loaded per
row.

- **chopper `--input`, `--threads`, stdin/stdout** (SOP :405, :442-447) — HOLDS.
  `chopper --help` (`chopper/0.12.0b`): header "Reads on stdin and writes to
  stdout"; `-i, --input <INPUT> [default: read from stdin]`; `-t, --threads <THREADS>
  [default: 4]`. The SOP's `--input … --threads … > out` form is valid.
- **Exact chopper filter command** (SOP :441-447) — HOLDS. Built a 5-read fixture
  (good 1500/Q20, short 800, long 1900, low-Q 1500/Q5, boundary 1200/Q10) and ran
  `chopper --input … --quality 10 --minlength 1200 --maxlength 1800 --threads 2`:
  "Kept 2 reads out of 5" — the good and boundary reads survived; short, long and
  low-quality were removed. Boundaries are inclusive (1200 bp and Q10 kept).
- **NanoPlot flags** `--fastq` (multi-file), `--outdir`, `--prefix`, `--threads`,
  `--loglength`, `--plots dot`, `--title` (SOP :348-355) — HOLDS. All present in
  `NanoPlot --help` (`NanoPlot/1.43.0`); `--fastq file [file ...]` pools multiple
  files (basis for F-03).
- **emu abundance flags** `--type lr:hq`, `--keep-counts`, `--keep-read-assignments`,
  `--output-unclassified`, `--min-abundance`, `--min-pid`, `--min-align-len`,
  `--max-align-len`, `--N`, `--db`, `--threads`, `--output-dir`, `--output-basename`
  (SOP :691-740) — HOLDS. `emu abundance --help` (`Emu/3.6.2`) confirms every one,
  with defaults matching the SOP's prose exactly: `--min-pid [0%]`,
  `--min-align-len [0]`, `--max-align-len [2000]`, `--N [50]`,
  `--min-abundance [0.0001]`, `--type … [map-ont]`. The "percent out of 100"
  warning for `--min-pid` (:738) is consistent with the `[0%]` default.
- **Emu database file layout** (SOP :727, "contains `species_taxid.fasta` and
  `taxonomy.tsv`") — HOLDS. The installed default DB
  `/opt/nesi/zen3/Emu/3.6.2/database/` contains exactly `species_taxid.fasta` and
  `taxonomy.tsv` (the older two-file format), matching the SOP; the newer
  `names_df.tsv/nodes_df.tsv` layout in `--db` help text is not what this build or
  the OSF prebuilts use.
- **OSF archive paths** (SOP :617, :629) — HOLDS. `osf -p 56uf7 ls` lists
  `osfstorage/emu-prebuilt/silva.tar` and `osfstorage/emu-prebuilt/rdp.tar` at
  exactly the fetch paths; `silva-138.2.tar` also exists, confirming the version
  note at :585. The `emu-silva/` OSF folder holds flat `species_taxid.fasta` +
  `taxonomy.tsv` (evidence the tar extracts flat — see Gaps).
- **osfclient install path** (SOP :607) — HOLDS (confirmed by env Q6 and re-checked):
  `osf` resolves to `~/.local/bin/osf`, on PATH; not bundled in the Emu module, so
  `pip install osfclient` is required, not redundant.
- **`emu combine-outputs` syntax and output names** (SOP :757, :770-780) — HOLDS
  for syntax, drives F-05 for names. `emu combine-outputs --help`:
  `[--split-tables] [--counts] dir_path rank`. Ran it: abundance →
  `emu-combined-species.tsv`, `--counts` → `emu-combined-species-counts.tsv`.
- **Custom combiner `combine_emu_results.py`** (SOP :796-923) — HOLDS. Extracted
  verbatim and ran on a fixture with a split-column `silva/` and a
  semicolon-lineage `rdp/`. Both produced identical 8-column layouts
  (`tax_id species genus family order class phylum superkingdom` + samples) with
  correct fractional counts preserved; the duplicate-basename guard (:845-851)
  fired correctly when `plate1/barcode01` and `plate2/barcode01` collided; runs
  clean on system `python3` (3.9 here) as the SOP claims.
- **Closing verify block** (SOP :948-952) against Option B output — HOLDS: printed
  "2 samples, 2 taxa" correctly (`tail -n +9` matches the 8 taxonomy columns).
  Its failure for Option A output is F-05.
- **Read-count arithmetic and Phred/ASCII table** (SOP :235-257, :318, :449-456) —
  HOLDS by inspection: `Q = -10·log10(P)`; `!`=Q0, `+`=Q10, `5`=Q20, `?`=Q30,
  `I`=Q40 (ASCII 33/43/53/63/73); `@`=ASCII 64 = Q31 (the SOP's own note);
  `wc -l/4` is the correct FASTQ read count and the grep caveat is right.

## Keep list

Content the rewrite must not lose (anchored):

- **`--keep-counts` "essential, do not omit"** (`--keep-counts` — **essential, do not omit.**) — the counts-vs-abundance warning with the "re-run Emu from scratch" consequence. Load-bearing silent-failure warning.
- **The three why-these-numbers paragraphs** (`--quality 10`, `--minlength 1200`, `--maxlength 1800`) — threshold justifications (16S 1400-1540 bp; chimera ceiling; Q10 rationale). Repo policy load-bearing.
- **`--min-pid` "Do not write 0.9 expecting 90%"** (Do not write `0.9` expecting 90%) — the percent-scale silent-failure warning.
- **`--max-align-len` default-2000 caveat** (raise it or reads are discarded without warning) — silent-truncation warning for long fragments.
- **The `grep -c "^@"` / `@` is Q31 note** (`@` is Q31) — corrects a specific plausible-but-wrong read count.
- **Duplicate-basename guard rationale** (write the other's into two identically named columns) — explains a silent sample-swap the guard prevents.
- **Version note on SILVA v138.1 vs 138.2** (has not yet been tested or validated with Emu) — tool-choice justification.
- **Why Emu over best-hit / EM explanation** (the central challenge of 16S classification) — concept the stated audience lacks.

## Gaps

*If I ran this end to end and something went wrong, what would I not know?*

- **No post-extraction check that `--db` resolves to the real database files**
  (§ Setting up the databases, :610-638). SHOULD-ADD (~2 lines). The SOP extracts
  the tar inside `…/emu_databases/silva` and later points `--db` at that same
  directory. If a prebuilt tar ever unpacks into a top-level `silva/` subdir,
  `--db` would be one level too shallow and Emu would abort with a database-not-found
  error the reader can't diagnose. I could not settle the tar's internal structure
  without the multi-GB download (`osf … fetch …/silva.tar && tar -tf silva.tar | head`;
  cost: one large download) — **NOT-VERIFIABLE-HERE** — but the evidence points to
  flat extraction (the installed default DB and the `emu-silva/` OSF folder are both
  flat). A cheap always-correct guard closes it either way:
  ```bash
  # After extracting, confirm the DB files are where --db will look:
  ls "${EMU_DATABASE_DIR}/species_taxid.fasta" "${EMU_DATABASE_DIR}/taxonomy.tsv" \
    || echo "DB files not at ${EMU_DATABASE_DIR} — check whether the tar made a subdirectory"
  ```
- **The combiner silently drops the unassigned fraction** (`tax_id == "unassigned": continue`, :861).
  CONSIDER (~2 lines). Reads Emu could not classify are excluded from the combined
  counts, so per-sample library sizes downstream are classified-reads-only. That is
  a defensible choice, but it is undocumented and the SOP elsewhere tells the reader
  to investigate the unassigned fraction. Note it, so a reader isn't surprised the
  table's column sums don't match Emu's total classified reads.
- **No check that the array range matched the sample count after the run**
  (§ Running Emu, :655-707). CONSIDER (~2 lines). If the reader leaves `--array=0-23`
  but has more samples, the extras are silently never processed. A one-line
  post-run check would catch it: `echo "manifest=$(wc -l < emu_manifest.txt) results=$(ls emu_results/silva/*_rel-abundance.tsv | wc -l)"` — the two numbers must match.
- **No statement of expected Emu runtime/scale per sample beyond "~10 min"**
  (:642). CONSIDER (~1 line). Fine as is, but a note that the first task's `nn_seff`
  is the thing to size from would help a beginner not over-request.

## Cross-document flags

Claims that touch another file or a shared convention; I can see only this file,
so I flag rather than resolve.

- **SLURM header vs README convention (README:55).** README says the one canonical
  header lives "in Part 1 Section 1" and uses `#!/bin/bash` + `set -euo pipefail`,
  `#SBATCH --chdir <absolute workspace path>`, and **1-based arrays whose range is
  set at submission** (`sbatch --array=1-N%20`, never in the header). This SOP uses
  `#!/bin/bash -e`, an in-body `cd` instead of `--chdir` (F-01), and a **0-based
  array with the range hard-coded in the header** (`--array=0-23`, :664). Either
  Part 1 or the README needs to move; whoever reconciles README owns this.
- **`<your_email>` placemat (README:51).** README = whole address; this SOP appends
  `@auckland.ac.nz` (F-02).
- **Fractional counts → Part 2's integer-count contract (README:57-58).** This SOP
  hands off fractional Emu counts and says "We round to whole numbers **in R**"
  (:744), but README:58 says Part 2's input is "integer counts" and README:57 says
  the *upstream* document "owns the conversion." Confirm Part 2 (SOP_R_Analysis.md)
  actually rounds on read-in; if it assumes integers, fractional counts flow in
  unrounded.
- **Two combined-table formats handed to Part 2.** Option A
  (`emu-combined-<rank>.tsv`, all-ranks-above-in-columns) and Option B
  (`emu-combined-{counts,abundance}_<db>.tsv`, fixed 8-column layout) have different
  names *and* column structures. Part 2's read-in code can only expect one. Confirm
  which, and whether Option A's output satisfies it (F-05).
- **Sample-ID suffix stripping (README:57).** This SOP strips `_filtered` where it
  is created (`basename … _filtered.fastq`, :685), so column headers are clean
  barcode IDs — consistent with the convention; flagged only so Agent B can confirm
  the same IDs reach the metadata file.

## Rewrite plan

Ordered; each item names the findings it closes, rough size, and whether it can
proceed alone.

1. **Add `#SBATCH --chdir <workspace>` to all four job headers, remove in-body
   `cd`.** Closes F-01. ~4 small header edits. Independent. Highest priority — it
   is the one change that turns "looks location-independent, isn't" into "is." Also
   resolves half of the SLURM cross-doc flag.
2. **Fix the `<your_email>` placeholder** (:174). Closes F-02. One line. Independent.
3. **Reframe § 3 Step 2 as a pooled run-level report and route per-barcode QC to
   the Step 1 loop and Step 3 retention log** (add the single-barcode NanoPlot
   one-liner). Closes F-03. ~1 short paragraph replaced + 1 command. Independent.
4. **Reconcile the retention numbers** at :464/:503 with the ~85% example. Closes
   F-04. Two line-edits. Independent.
5. **State Option A's filenames at :770 and make the closing verify block
   option-independent** (`ls emu_results/*/emu-combined-*.tsv`). Closes F-05.
   ~2 line-edits + one code-block swap. Independent; do together with a decision on
   whether to keep Option A at all (it competes with the "preferred" Option B for
   equal visual weight — consider demoting it to a short note, which would also
   simplify the section).
6. **Add the DB-path sanity check** after extraction and **note the dropped
   unassigned fraction** in the combiner section. Closes the two SHOULD-ADD/CONSIDER
   gaps. ~4 lines total. Independent.
7. **Polish pass (F-06):** `--array 0-23`, `--mem` in the template, equal NanoPlot
   walltimes. Trivial. Do last so earlier edits don't reshuffle it.

## Self-check

```
findings=6 S1=0 S2=1 S3=4 S4=1
CLEAN
```

By hand, the three the script cannot check:
- [x] Ledger accounts for every heading in the file (verified against `grep -nE '^#{1,4} '`, code-comment false positives excluded and noted).
- [x] No proposed cut touches load-bearing content (the only structural suggestion — optionally demoting Option A — removes a *duplicated path*, not any why-this-number, warning, expected-output, citation, scope, governance, or concept content; Keep list preserved).
- [x] Every `NOT-VERIFIABLE-HERE` is genuinely not verifiable here (one item, the tar internal structure in Gaps, needs a multi-GB download the brief bars; the settling command and its cost are named).

CONTRACT: PASS
