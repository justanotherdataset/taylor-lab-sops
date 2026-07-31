# Adversarial review — SOP_CONCOMPRA_NeSI.md

## Document: SOP_CONCOMPRA_NeSI.md

This wants to be a self-contained walkthrough for running CONCOMPRA on NeSI and handing consensus OTUs to Part 2, and structurally it is close: the roadmap, the resource tables, the "why this number" paragraphs on primer orientation, the SINTAX cutoff and the absolute-path requirement are all good, and the document is unusually honest about the pipeline's silent-failure modes. It is undermined by two things. First, its own headline verification does not work: Section 6 tells you to check `temporary/`, and Section 10 tells you `main.sh` deletes `temporary/` at the end of a successful run — so the reader who follows the document sees nothing and has no gate at all on the failure mode the roadmap calls "the one thing to remember". Second, the document has no prerequisites block, and as a result its input directory has three names (`fastq_plate1/`, `filtered/`, `filtered_dedup/`), only one of which appears in the directory layout and none of which is ever defined. The single change that would most improve it is to make Section 3 and Section 6 actually executable end to end — one named input directory, a duplicate screen that keys on the same field `filtlong` keys on, and a per-sample verification built on `results/otu_table.csv`, which survives the cleanup.

## Section ledger

| § | Heading | Lines | Verdict | Findings |
|---|---|---|---|---|
| — | Front matter + title (`# CONCOMPRA Pipeline: Consensus OTUs on NeSI`) | 1-8 | REWRITE | F-03, F-04, F-13, F-25 |
| — | Quick Roadmap: What You'll Do | 11-34 | TIGHTEN | F-26, F-27 |
| 1 | Overview | 37-48 | TIGHTEN | F-28 |
| 2 | Installation | 52-54 | CLEAN | — |
| 2 | — Locations | 56-62 | CLEAN | — |
| 2 | — Clone the repository | 64-71 | CLEAN | — |
| 2 | — Build the conda environment | 73-89 | TIGHTEN | F-14 |
| 2 | — Verify the environment | 91-110 | TIGHTEN | F-24, F-29, F-30 |
| 2 | — SILVA SINTAX database | 112-124 | TIGHTEN | F-31 |
| 3 | Pre-flight: Screen for Duplicate Reads | 128-131 | CLEAN | — |
| 3 | — Screen | 132-143 | REWRITE | F-01 |
| 3 | — Deduplicate | 145-157 | REWRITE | F-01, F-05 |
| 3 | — Record run metadata | 159-161 | CLEAN | — |
| 4 | Run Configuration | 165 | CLEAN | — |
| 4 | — Directory layout | 167-184 | TIGHTEN | F-15 |
| 4 | — Symlink the input fastqs | 186-197 | REWRITE | F-06 |
| 4 | — Sample list | 199-207 | CLEAN | — |
| 4 | — Primer file | 209-220 | CLEAN | — |
| 4 | — Threads | 222-226 | REWRITE | F-07 |
| 5 | Submitting the Run | 230-277 | EXPAND | F-02, F-32 |
| 6 | Verifying the Run | 281-283 | RESTRUCTURE | F-02 |
| 6 | — Per-sample consensus | 285-299 | RESTRUCTURE | F-02 |
| 6 | — Output files | 301-325 | REWRITE | F-08, F-16, F-33 |
| 6 | — Cross-check against Emu | 327-329 | TIGHTEN | F-34 |
| 7 | Post-processing: Taxonomy, Alignment, Phylogeny | 333-403 | EXPAND | F-09, F-17, F-18, F-35 |
| 7 | — Notes on the steps | 405-411 | REWRITE | F-10, F-19 |
| 7 | — Verifying the outputs | 413-421 | REWRITE | F-20, F-21 |
| 8 | Preparing for R / phyloseq | 425-427 | CLEAN | — |
| 8 | — The R-ready folder | 429-439 | TIGHTEN | F-22, F-36 |
| 8 | — Building it | 441-467 | REWRITE | F-11, F-37 |
| 8 | — Checking sample IDs | 469-477 | EXPAND | F-23, F-38 |
| 8 | — Building the phyloseq object | 479-486 | EXPAND | — (see Gaps) |
| 9 | Troubleshooting | 490 | CLEAN | — |
| 9 | — Empty consensus output | 492-496 | CLEAN | — |
| 9 | — Empty sintax output | 498-500 | CLEAN | — |
| 9 | — medaka, racon, or samtools appear to be missing | 502-504 | CLEAN | F-30 |
| 9 | — A run is stuck or slow | 506-513 | CLEAN | — |
| 10 | Maintenance | 517 | CLEAN | — |
| 10 | — Updating CONCOMPRA | 519-530 | TIGHTEN | F-14, F-24 |
| 10 | — The temporary directory | 532-541 | REWRITE | F-02 |
| A | Appendix A: SILVA SINTAX Database Build | 545-547 | CLEAN | — |
| A | — The reformatter | 549-557 | EXPAND | F-12 |
| A | — Build | 559-579 | RESTRUCTURE | F-12 |
| A | — Refreshing for a new SILVA release | 581-583 | CLEAN | — |
| B | Appendix B: References | 587-601 | CLEAN | — |

## Findings

### F-01 · S1 · Duplicate screen compares whole headers, not read names
- **Where:** SOP_CONCOMPRA_NeSI.md:135-140 and :156, § 3 Screen / Deduplicate
- **Quote:**
  > ```
  > for f in fastq_plate1/*.fastq; do
  >     total=$(awk 'NR%4==1' "$f" | wc -l)
  >     dups=$(awk 'NR%4==1' "$f" | sort | uniq -d | wc -l)
  > ```
  >
  > and, after deduplication:
  >
  > ```
  > awk 'NR%4==1' filtered_dedup/sample.fastq | sort | uniq -d | wc -l
  > ```
- **Defect:** `awk 'NR%4==1'` emits the entire header line, so the screen only counts a duplicate when the whole line matches, whereas `filtlong` and `seqkit rmdup -n` key on the read *name* alone — the first whitespace-delimited field.
- **Failure:** A run whose POD5s were merged and basecalled twice with different dorado models has identical read IDs but differing header tails (`model_version_id=`, `runid=`). The screen reports `dup_ids=0` for every sample, the reader proceeds under the document's own instruction ("Zero duplicates across all samples means proceed", line 143), `filtlong 0.2.1` aborts on the first duplicate name, `main.sh` has no `set -e` and still logs "consensus sequences generated" for every sample, and the reader ends up with empty consensus files — exactly the silent failure Section 3 exists to prevent. The post-dedup confirmation has the same defect and additionally names a file literally, `filtered_dedup/sample.fastq`, which does not exist: awk errors to stderr, `wc -l` prints `0`, and the reader reads that `0` as "zero duplicates remain".
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — line 152 deduplicates with `seqkit rmdup -n` (by name) and line 130 states that `filtlong` "aborts on duplicate read names"; the screen at 136-137 compares full header lines. The two keys are different, from the text alone.
- **Fix:** Replace lines 133-143 (the "Screen" prose and code) with:

  Compare read *names* only — the first whitespace-delimited field of each header. `filtlong` and `seqkit rmdup -n` both key on the name; the rest of a Nanopore header (`runid=`, `model_version_id=`, …) can differ between two basecalls of the same POD5, so comparing whole header lines can report zero duplicates on a file `filtlong` will still reject.

  ```bash
  for f in filtered/*.fastq; do
      total=$(awk 'NR%4==1{print $1}' "$f" | wc -l)
      dups=$(awk 'NR%4==1{print $1}' "$f" | sort | uniq -d | wc -l)
      if [ "$total" -eq 0 ]; then
          echo "$(basename "$f")  EMPTY FILE — investigate before continuing"
          continue
      fi
      pct=$(awk -v d="$dups" -v t="$total" 'BEGIN{printf "%.1f", (d/t)*100}')
      echo "$(basename "$f")  total=$total  dup_ids=$dups  (${pct}%)"
  done
  ```

  Zero duplicates across all samples means proceed. Any non-zero count means deduplicate first. A uniform duplication percentage across every sample (for example, exactly 50%) indicates a file-level POD5 merge artefact rather than scattered noise.

  And replace the confirmation line 156 with a loop over every sample:

  ```bash
  # Confirm zero duplicates remain, in every sample
  for f in filtered_dedup/*.fastq; do
      echo "$(basename "$f")  $(awk 'NR%4==1{print $1}' "$f" | sort | uniq -d | wc -l)"
  done
  ```

### F-02 · S1 · Section 6 verifies a directory main.sh has just deleted
- **Where:** SOP_CONCOMPRA_NeSI.md:291-299 (§ 6 Per-sample consensus) contradicted by :534 (§ 10 The temporary directory)
- **Quote:**
  > ```
  > # Any zero-line consensus file is a silent per-sample failure
  > find temporary -name "*.consensus.fasta" -exec wc -l {} \; | sort -n | head -20
  > ```
  >
  > against line 534:
  >
  > > CONCOMPRA's `main.sh` ends with `rm -rf temporary`, so per-sample intermediates are deleted on a successful run. If you need them for debugging, comment that line out before running.
- **Defect:** The document's primary and only per-sample verification reads `temporary/`, which `main.sh` removes at the end of every run that reaches the end; the instruction to comment out the deletion is buried in Section 10, nine sections after the point at which it must be acted on.
- **Failure:** The reader submits `06_concompra.sh` as written, waits a day, runs the Section 6 commands, and `find temporary …` returns nothing. The counting command then prints `0`, which the document says means every sample failed silently — so either the reader resubmits a 48-hour, 16-CPU job for a run that actually succeeded, or, reading line 534 later, concludes the check is meaningless and skips verification entirely, proceeding with genuinely failed samples in the OTU table. Either way, the gate the roadmap calls "the one thing to remember" (line 33) never fires.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — internal contradiction between line 291 and line 534.
- **Fix:** Three edits.

  **(a)** In Section 5, insert immediately before "**Script.**" (line 242):

  **Keep the per-sample intermediates.** `main.sh` ends with `rm -rf temporary`, and `temporary/` holds the per-sample consensus files Section 6 inspects. Copy `main.sh` into the run directory and comment that line out before your first submission — the same copy-and-edit route described under "Threads":

  ```bash
  cd /nesi/nobackup/<your_project_code>/<your_run_name>/concompra/
  cp /nesi/project/<your_project_code>/CONCOMPRA/scripts/main.sh .
  sed -i 's|^\([[:space:]]*\)rm -rf temporary|\1# rm -rf temporary   # kept for Section 6|' main.sh
  grep -n 'rm -rf temporary' main.sh    # must show the line commented out
  ```

  Then change the last line of `06_concompra.sh` to run your copy:

  ```bash
  bash ./main.sh
  ```

  **(b)** Replace Section 6's "Per-sample consensus" subsection (lines 285-299) with:

  ### **Per-sample verification**

  A sample that failed silently contributes zero reads to the OTU table, and `results/otu_table.csv` exists whether or not you kept `temporary/`. Use it as the gate:

  ```bash
  cd /nesi/nobackup/<your_project_code>/<your_run_name>/concompra/

  # Per-sample read totals, ascending. Zero means the sample produced nothing.
  awk -F, 'NR==1 {for(i=2;i<=NF;i++) n[i]=$i; next}
                {for(i=2;i<=NF;i++) s[i]+=$i}
           END  {for(i=2;i<=NF;i++) print s[i] "\t" n[i]}' \
    results/otu_table.csv | sort -n | head -20

  # Samples with any reads at all, against your sample count
  awk -F, 'NR==1 {next} {for(i=2;i<=NF;i++) s[i]+=$i}
           END  {c=0; for(i in s) if (s[i]>0) c++; print c}' results/otu_table.csv
  wc -l directory_list.txt
  ```

  The two numbers should match. A shortfall is a silent per-sample failure; see [Troubleshooting](#9-troubleshooting). A negative control legitimately sitting at or near zero is not a failure — decide per sample whether to keep it as a control or drop it.

  If a sample is unexpectedly at zero, look at its intermediates. This needs the Section 5 edit; if `find` returns nothing at all, that edit is what is missing, not every sample:

  ```bash
  find temporary -name "*.consensus.fasta" -exec wc -l {} \; | sort -n | head -20
  ```

  **(c)** Replace Section 10's "The temporary directory" body (lines 534-541) with:

  Section 5 has you comment out `rm -rf temporary` in your run-directory copy of `main.sh`, so the per-sample intermediates survive for Section 6. They are the largest thing the run writes. Once verification has passed and the analysis is finalised, delete them yourself:

  ```bash
  cd /nesi/nobackup/<your_project_code>/<your_run_name>/concompra/
  rm -rf temporary/
  ```

  Keep `directory_list.txt`, `primer_set.fa`, your edited `main.sh`, the Slurm scripts, `results/`, and `concompra_for_R/`.

### F-03 · S2 · Points at a companion document that does not exist
- **Where:** SOP_CONCOMPRA_NeSI.md:5, § front matter
- **Quote:**
  > CONCOMPRA is an alternative to the Emu-based NeSI pipeline (`SOP_NeSI_Pipeline.md`); it builds reference-free consensus OTUs rather than aligning reads to a reference.
- **Defect:** No `SOP_NeSI_Pipeline.md` exists in the repository; the Emu-based pipeline is `SOP_EMU_NeSI.md`.
- **Failure:** A reader who picked CONCOMPRA and then wants the cluster onboarding, the read-filtering step, or the Emu comparison this document repeatedly assumes (lines 41, 48, 114, 130, 327-329) searches for `SOP_NeSI_Pipeline.md`, finds nothing, and has no way to learn that `SOP_EMU_NeSI.md` is what they want. The README's contributing rules name exactly this failure: "a reference to a companion document that was never written is worse than no reference."
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — the repository contains five Markdown files and this is not one of them.
- **Fix:** Replace the sentence with:

  CONCOMPRA is an alternative to the Emu-based Nanopore pipeline (`SOP_EMU_NeSI.md`); it builds reference-free consensus OTUs rather than aligning reads to a reference.

### F-04 · S2 · No prerequisites block: the reader's input is never defined
- **Where:** SOP_CONCOMPRA_NeSI.md:7, § front matter
- **Quote:**
  > Paths use `<your_project_code>` and `<your_run_name>` placeholders. Substitute your own throughout.
- **Defect:** The document states no prerequisites — not a NeSI account, not the assumed bash/SLURM knowledge, not that the reads must already be demultiplexed and quality-filtered, and not where the `filtered/` directory that Section 3 deduplicates comes from.
- **Failure:** A reader who comes to this document first (the README lists it as an equal alternative to Part 1 in the routing table) reaches line 151, `for f in filtered/*.fastq`, and has no `filtered/` directory and nothing telling them one is expected or how to make one. The glob does not expand, `seqkit` errors on a literal `filtered/*.fastq`, `filtered_dedup/` is created empty, and the reader has to reverse-engineer the missing upstream step from a directory name. Nothing in the document says CONCOMPRA is not fed raw basecaller output.
- **Type:** GAP
- **Confidence:** CONFIRMED — `filtered/` appears only at line 151; it is absent from the directory layout at lines 169-182 and from every other section.
- **Fix:** Insert after line 7:

  **Before you start.** This document assumes you have:

  - a NeSI account and project code, and enough bash and SLURM to submit a job, read a `.err` file and check `squeue`. If you do not, work through Section 1 of `SOP_EMU_NeSI.md` first — it is the only document in this set that teaches the cluster, and this one does not repeat it.
  - your Nanopore reads already basecalled, demultiplexed and quality/length-filtered, as one per-sample `.fastq` file in a single directory. This document calls that directory `filtered/` throughout; it is the output of the read-filtering step in `SOP_EMU_NeSI.md`. CONCOMPRA does its own primer-chopping and `filtlong` quality pass on top of that filtering — it does not replace it.
  - a sample metadata sheet as a `.csv`, one row per sample, sample ID in the first column, using exactly the sample IDs that appear in your fastq filenames.

  This document does not cover basecalling, demultiplexing or read filtering.

### F-05 · S2 · `seqkit` is never loaded and is not part of this workflow's toolset
- **Where:** SOP_CONCOMPRA_NeSI.md:149-153, § 3 Deduplicate
- **Quote:**
  > ```
  > mkdir -p filtered_dedup
  > for f in filtered/*.fastq; do
  >     seqkit rmdup -n "$f" -o filtered_dedup/$(basename "$f")
  > done
  > ```
- **Defect:** `seqkit` is introduced with no `module load`, no conda environment, and no mention anywhere else in the document or in the README's tool table — which lists `seqtk` for this workflow, a different program with no `rmdup` subcommand.
- **Failure:** The reader pastes the loop and gets `seqkit: command not found` for every sample. `mkdir -p filtered_dedup` has already succeeded, so an empty `filtered_dedup/` now exists; if the errors scroll past on a 192-sample loop, the reader moves to Section 4, symlinks zero files, and only catches it at `ls *.fastq | wc -l`. A reader who tries `seqtk` instead — the tool the README does list for this workflow — finds no `rmdup` and stalls.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — `seqkit` appears exactly once in the document, at line 152, with no module load; README line 69 lists `seqtk/1.4-GCC-11.3.0` for CONCOMPRA post-processing and no seqkit.
- **Fix:** Replace lines 149-153 with a dependency-free deduplication that keys on the same field the screen and `filtlong` use:

  ```bash
  mkdir -p filtered_dedup
  for f in filtered/*.fastq; do
      awk 'NR%4==1 {keep = !($1 in seen); seen[$1] = 1}
           keep' "$f" > filtered_dedup/"$(basename "$f")"
  done
  ```

  This keeps the first record for each read name and drops later copies. It needs no module: `awk` is always available. If you would rather use `seqkit rmdup -n`, load it first and confirm the module exists on your cluster (`module spider seqkit`) — it is not one of the modules this workflow otherwise depends on.

### F-06 · S2 · The clean-screen path never creates the directory Section 4 reads
- **Where:** SOP_CONCOMPRA_NeSI.md:190-197, § 4 Symlink the input fastqs
- **Quote:**
  > ```
  > mkdir -p concompra/
  > cd concompra/
  > for f in ../filtered_dedup/*.fastq; do
  >     ln -s "$(realpath "$f")" .
  > done
  > ls *.fastq | wc -l   # should equal your sample count
  > ```
- **Defect:** `filtered_dedup/` only exists if Section 3 found duplicates and you deduplicated; Section 3's other branch says "Zero duplicates across all samples means proceed" and produces nothing, and this block has no `cd` establishing where `concompra/` is created relative to it.
- **Failure:** The common case — a clean run, no duplicates — reaches this block with no `filtered_dedup/` directory. The glob does not expand, `realpath` still prints a path for the literal string, and `ln -s` creates a single broken symlink named `*.fastq`. `ls *.fastq | wc -l` prints `1`, which the reader compares against 192 and now has to debug from the wrong end. Separately, because the block opens with `mkdir -p concompra/` and no `cd`, a reader still sitting in the fastq directory from Section 3 creates `concompra/` in the wrong place, and the absolute paths hardcoded in `06_concompra.sh` then point at an empty directory.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — Section 3 offers a "proceed" branch that writes no `filtered_dedup/`, and no `cd` precedes line 191.
- **Fix:** Replace lines 188-197 with:

  Symlink rather than copy. Use `realpath` so the links resolve after CONCOMPRA changes directory mid-run. Set `INPUT` to whichever input directory Section 3 left you with — `filtered_dedup` if you deduplicated, `filtered` if the screen was clean. Use one or the other for the whole run; do not mix.

  ```bash
  cd /nesi/nobackup/<your_project_code>/<your_run_name>/
  INPUT=filtered_dedup            # or: INPUT=filtered   (clean duplicate screen)

  mkdir -p concompra/
  cd concompra/
  for f in ../$INPUT/*.fastq; do
      ln -sf "$(realpath "$f")" .
  done
  ls *.fastq | wc -l   # must equal your sample count before you go on
  ```

  `ln -sf` rather than `ln -s` so the block is safe to re-run after a correction. If the count is wrong, `ls -l *.fastq` will show any broken link as a red or dangling target.

  Also add `filtered/` to the directory layout at lines 169-182, above `filtered_dedup/`, as `# quality/length-filtered input (see "Before you start")`.

### F-07 · S2 · `THREADS` documented as living in a file built as a bare path list
- **Where:** SOP_CONCOMPRA_NeSI.md:224, § 4 Threads
- **Quote:**
  > `THREADS` in `directory_list.txt` sets both outer parallelism (samples run concurrently) and inner parallelism (threads per sample). For a 16-CPU allocation, `THREADS=4` gives 4 samples at a time with 4 threads each. This may run faster than `THREADS=16` (one sample at a time) on many-sample datasets; test it on a run before committing.
- **Defect:** Section 4's "Sample list" builds `directory_list.txt` by overwriting it with nothing but absolute fastq paths (`ls *.fastq | xargs -I{} realpath {} > directory_list.txt`, line 205), so `THREADS` cannot be in it; and the stated rule — that `THREADS` sets both the number of concurrent samples and the threads per sample — does not produce the worked example it is attached to, since it would make `THREADS=16` sixteen samples at sixteen threads, not "one sample at a time".
- **Failure:** The reader appends `THREADS=4` to `directory_list.txt`. That line is now a sample entry: `wc -l directory_list.txt` reports 193 instead of 192, which is the exact number Section 6 tells the reader to compare the consensus count against, so verification reports a phantom failed sample. Meanwhile the real `THREADS` value is untouched and the run uses the default. A reader who instead trusts the stated rule and sets `THREADS=16` expecting one-sample-at-a-time gets whatever CONCOMPRA actually does, with no way to reconcile the two readings of the sentence.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — line 205 writes `directory_list.txt` as paths only, and line 201 describes it as holding paths; the sentence at 224 contradicts both, and contradicts its own worked example.
- **Fix:** Replace lines 224-226 with:

  `directory_list.txt` holds nothing but one absolute FASTQ path per line (see "Sample list" above) — do not add settings to it. `THREADS` is a CONCOMPRA setting read by `main.sh`. Find it with

  ```bash
  grep -n 'THREADS' /nesi/project/<your_project_code>/CONCOMPRA/scripts/main.sh
  ```

  and change it in your run-directory copy of `main.sh` (Section 5), not in the installed one, so other people's runs are unaffected. The same copy is where you change any other parameter the config files do not expose.

  `THREADS` is threads *per sample*; the number of samples CONCOMPRA works on at once is your allocation divided by it. On a 16-CPU allocation, `THREADS=4` gives four samples in parallel at four threads each, and `THREADS=16` gives one sample at a time at sixteen threads. Four-by-four is usually faster on many-sample datasets, because the per-sample steps stop scaling after a few threads while the number of samples does not. Test it on one run before committing.

### F-08 · S2 · OTU table described with its axes swapped
- **Where:** SOP_CONCOMPRA_NeSI.md:311, § 6 Output files
- **Quote:**
  > | `otu_table.csv` | Sample by OTU count matrix |
- **Defect:** Every command in the document treats `otu_table.csv` as OTUs in rows and samples in columns; this table row says the opposite.
- **Failure:** The reader carries "samples are rows" into R and builds the phyloseq object with `taxa_are_rows = FALSE`. phyloseq then takes the OTU IDs as sample names and the sample IDs as taxa names, so the `tax_table` and `sample_data` no longer join and `phyloseq()` fails with a name-mismatch error the reader cannot interpret, because the document told them the orientation was the other way round. Before that, a reader reasoning from line 311 cannot make sense of step 1 of the post-processing script, which takes column 1 of each row as an OTU ID.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED — line 319-322 sums down columns and labels the result "per-sample read totals"; line 375 takes column 1 of each data row as an OTU ID; line 407 says "OTU-table rows"; line 464 matches row keys against sequence IDs; line 474 reads the header row as sample names.
- **Fix:** Replace the table row with:

  | `otu_table.csv` | Count matrix: one row per OTU, one column per sample. Sample column headers carry a `.CONCOMPRA` suffix (stripped in Section 8) |

  and add below the table:

  The orientation matters downstream — taxa are rows, so the phyloseq object is built with `taxa_are_rows = TRUE`.

### F-09 · S2 · `seqtk subseq` exits 0 on zero matches, so `set -e` does not catch an empty working fasta
- **Where:** SOP_CONCOMPRA_NeSI.md:374-379, § 7 post-processing script step 1
- **Quote:**
  > ```
  > # 1. Filter the fasta to OTUs that have counts in the OTU table
  > tail -n +2 "$RESULTS/otu_table.csv" | cut -d',' -f1 > "$RESULTS/otus_with_counts.txt"
  > seqtk subseq \
  >     "$RESULTS/noglobal_nolocalchim.consensus.sequences.fas" \
  >     "$RESULTS/otus_with_counts.txt" \
  >     > "$RESULTS/consensus_in_otutable.fas"
  > ```
- **Defect:** If no OTU-table ID matches a FASTA header — different ID formatting on the two sides, or an empty OTU table from a failed run — `seqtk subseq` writes an empty file and exits 0, so the `set -euo pipefail` at line 362 does not stop the job and the next three steps run on nothing.
- **Failure:** vsearch classifies an empty fasta and writes an empty `consensus.sintax`; MAFFT writes an empty alignment; FastTree writes a tree file; the job ends with exit status 0 and no error in the `.err` log. The reader, having been told at line 361 that "unlike main.sh, this script aborts on first error", takes a clean exit as success and only discovers the problem in R, or does not discover it at all. The document's own troubleshooting then misdiagnoses it: line 500 attributes an empty sintax file to a wrong `SILVA_UDB` path, which in this case it is not.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — `set -euo pipefail` cannot trap a zero exit status, and nothing between step 1 and step 2 tests the file.
- **Fix:** Insert after the `seqtk subseq` block, before "# 2. Taxonomy":

  ```bash
  # seqtk exits 0 when it matches nothing, so set -e will not catch an empty
  # result. Stop here rather than classifying and tree-building an empty file.
  n_ids=$(wc -l < "$RESULTS/otus_with_counts.txt")
  n_seq=$(grep -c '^>' "$RESULTS/consensus_in_otutable.fas" || true)
  echo "OTU-table IDs: $n_ids   sequences matched: $n_seq"
  if [ "$n_seq" -eq 0 ]; then
      echo "ERROR: no OTU-table ID matched a header in the chimera-clean fasta." >&2
      echo "The two ID formats, for comparison:" >&2
      head -3 "$RESULTS/otus_with_counts.txt" >&2
      grep -m3 '^>' "$RESULTS/noglobal_nolocalchim.consensus.sequences.fas" >&2
      exit 1
  fi
  ```

  and amend line 500 to read: "An empty sintax output means either a wrong `SILVA_UDB` path — check the `.err` log for `unable to open` — or an empty input fasta, which step 1's guard will have reported."

### F-10 · S2 · `-boot 1000` presented as switching FastTree to resample-based support
- **Where:** SOP_CONCOMPRA_NeSI.md:411, § 7 Notes on the steps
- **Quote:**
  > **Step 4.** `FastTree -gtr -nt` builds an approximate maximum-likelihood tree under GTR and reports SH-like local supports by default. For resample-based supports, add `-boot 1000`.
- **Defect:** FastTree's `-boot` sets the number of resamples used by the SH-like local support test, whose default is already 1000; it does not switch FastTree to a bootstrap over replicate alignments, which FastTree cannot do on its own.
- **Failure:** A student adds `-boot 1000`, gets a tree with support values numerically indistinguishable from the default run, and writes "1000 bootstrap replicates (FastTree)" into a methods section. The values are SH-like local supports, which are not comparable to bootstrap proportions and are known to run higher. The error is invisible: the tree looks right, the numbers look right, and no message anywhere says otherwise.
- **Type:** CORRECTNESS
- **Confidence:** NEEDS-BENCH-CHECK — run `FastTree` with no arguments (it prints its usage) and read the `-boot` line; the single question is whether `-boot N` changes the *kind* of support reported or only the resample count of the existing SH-like test.
- **Fix:** Replace the sentence with:

  **Step 4.** `FastTree -gtr -nt` builds an approximate maximum-likelihood tree under GTR. By default it reports SH-like local support values, not bootstrap proportions — `-boot N` changes how many resamples that test uses, not what it computes, so it does not give you a bootstrap. Report the supports as "SH-like local supports (FastTree 2)" in your methods, and if you need true bootstrap proportions, generate replicate alignments and build a tree per replicate; that is outside the scope of this SOP.

### F-11 · S2 · The R-prep step needs Biopython, with nothing loaded and nothing said
- **Where:** SOP_CONCOMPRA_NeSI.md:455-466, § 8 Building it
- **Quote:**
  > ```
  > python <<'PY'
  > from Bio import SeqIO
  > keep = {rec.id for rec in SeqIO.parse("otu_sequences.fasta", "fasta")}
  > ```
- **Defect:** The block is run interactively after a section whose only module loads were `module purge` plus VSEARCH/MAFFT/FastTree/seqtk inside a batch script; nothing loads a Python module or activates an environment, and Biopython is not mentioned anywhere in the document or the README.
- **Failure:** The reader pastes the heredoc on a login node and gets either `python: command not found` or `ModuleNotFoundError: No module named 'Bio'`. Because the three `cp` commands above it already succeeded, `concompra_for_R/` now contains the sequences, taxonomy and tree but no `otu_table.csv` — a half-built handoff folder that looks nearly complete. The reader who does not notice moves on to "Checking sample IDs", whose first command reads the `otu_table.csv` that was never written.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — no Python or Biopython is loaded or mentioned at any point in the document.
- **Fix:** Replace lines 454-466 with an awk equivalent that needs no modules:

  ```bash
  # OTU table: keep the chimera-clean OTUs, strip the .CONCOMPRA column suffix
  grep '^>' otu_sequences.fasta | sed 's/^>//' | awk '{print $1}' | sort -u > keep_otus.txt

  awk -F, 'NR==FNR { keep[$1]; next }
           FNR==1  { gsub(/\.CONCOMPRA/, "", $0); print; next }
           ($1 in keep)' \
      keep_otus.txt ../concompra/results/otu_table.csv > otu_table.csv

  # Rows kept (excluding the header) must equal sequences in the fasta
  echo "sequences: $(grep -c '^>' otu_sequences.fasta)  table rows: $(($(wc -l < otu_table.csv) - 1))"
  rm keep_otus.txt
  ```

### F-12 · S2 · Appendix A depends on a script the repository never supplies
- **Where:** SOP_CONCOMPRA_NeSI.md:563-565, § Appendix A Build (and the listing at :118-121)
- **Quote:**
  > ```
  > cd <where Emu's species_taxid.fasta lives>
  > python /nesi/project/<your_project_code>/databases/silva_emu_sintax/reformat_silva_for_sintax.py \
  >     species_taxid.fasta silva_sintax.fa
  > ```
- **Defect:** `reformat_silva_for_sintax.py` is described but never provided, never linked and never given a source; and the path it is invoked from is inside the very directory the appendix is building, so the reader is told to run a script out of a directory that does not yet contain it.
- **Failure:** The reader needs a SILVA SINTAX database because Section 7 will not run without one. They reach Appendix A, find a `python …/reformat_silva_for_sintax.py` command, discover the file does not exist, and the document offers no fallback and no location — unlike `assemble_R_inputs.py` at line 443, which at least comes with a self-contained equivalent. The whole taxonomy branch of the pipeline is unreachable for anyone who does not already have the lab's copy.
- **Type:** GAP
- **Confidence:** CONFIRMED — the script is referenced at lines 120, 564, 568 and 579 and its behaviour is described at 557, but no source, URL or code for it appears anywhere in the document.
- **Fix:** Replace the "Build" step 1 (lines 561-568) with a correctly ordered version that creates the directory first, and add the script to "The reformatter" so the appendix is self-contained:

  ```bash
  # 0. Create the database directory and put the reformatter in it
  mkdir -p /nesi/project/<your_project_code>/databases/silva_emu_sintax
  # copy reformat_silva_for_sintax.py (below) into that directory

  # 1. Reformat (about 7 seconds for ~412k records; expect 0 dropped)
  cd <where Emu's species_taxid.fasta lives>
  python3 /nesi/project/<your_project_code>/databases/silva_emu_sintax/reformat_silva_for_sintax.py \
      species_taxid.fasta silva_sintax.fa

  # Test on a subset first:
  #   python3 .../reformat_silva_for_sintax.py species_taxid.fasta test.fa --limit 100
  ```

  And append to "The reformatter" (after line 557): *Check the header format of your Emu bundle with `head -2 species_taxid.fasta` before trusting the output — this script assumes the form shown above.*

  ```python
  #!/usr/bin/env python3
  """Emu SILVA species_taxid.fasta -> SINTAX-formatted FASTA for `vsearch --sintax`.

  Assumed input header:
    >1:emu-silva:1 ['dada2-silva_1 Bacteria;Proteobacteria;...;Pseudomonas;amygdali;']
  Emitted header:
    >1:emu-silva:1;tax=d:Bacteria,p:Proteobacteria,...,g:Pseudomonas,s:Pseudomonas_amygdali;
  """
  import argparse, re, sys

  PREFIXES = ("d", "p", "c", "o", "f", "g", "s")
  UNINFORMATIVE = ("phage", "metagenome", "uncultured", "sp.")

  def clean(name):
      return re.sub(r"[\s,;]+", "_", name.strip()).strip("_")

  def taxonomy(header):
      m = re.search(r"\[(.*)\]", header)
      if not m:
          return None
      inner = m.group(1).strip().strip("'\"")
      lineage = inner.split(None, 1)[1] if " " in inner else inner
      ranks = [clean(r) for r in lineage.split(";")]
      ranks = (ranks + [""] * 7)[:7]
      if ranks[5] and ranks[6] and not ranks[6].lower().startswith(ranks[5].lower()):
          ranks[6] = ranks[5] + "_" + ranks[6]          # genus + species -> binomial
      if any(w in ranks[6].lower() for w in UNINFORMATIVE):
          ranks[6] = ""
      return ",".join(f"{p}:{r}" for p, r in zip(PREFIXES, ranks) if r)

  def main():
      ap = argparse.ArgumentParser()
      ap.add_argument("infile")
      ap.add_argument("outfile")
      ap.add_argument("--limit", type=int, default=0)
      a = ap.parse_args()
      kept = dropped = 0
      with open(a.infile) as fin, open(a.outfile, "w") as fout:
          emit = False
          for line in fin:
              if line.startswith(">"):
                  if a.limit and kept >= a.limit:
                      break
                  tax = taxonomy(line)
                  emit = tax is not None
                  if emit:
                      fout.write(f">{line[1:].split()[0]};tax={tax};\n")
                      kept += 1
                  else:
                      dropped += 1
              elif emit:
                  fout.write(line)
      print(f"records written: {kept}  dropped (no bracketed lineage): {dropped}",
            file=sys.stderr)

  if __name__ == "__main__":
      main()
  ```

  If the lab has its own copy, use that instead; either way record the version you used in the database directory's `README.md`, and check that records in equals records out.

### F-13 · S3 · Placeholder spelling differs from the repository convention
- **Where:** SOP_CONCOMPRA_NeSI.md:7, § front matter
- **Quote:**
  > Paths use `<your_project_code>` and `<your_run_name>` placeholders. Substitute your own throughout.
- **Defect:** The README's conventions section names `<your_nesi_project_code>` as the placeholder for the project allocation code; this document uses `<your_project_code>` throughout, and introduces `<your_run_name>`, which the README does not list.
- **Failure:** A reader running two SOPs side by side cannot tell whether `<your_project_code>` and `<your_nesi_project_code>` are the same slot, and a reader searching their scripts for un-substituted placeholders using the README's spelling misses every occurrence in this document.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED — README:40 and :50 give `<your_nesi_project_code>`.
- **Fix:** Rename `<your_project_code>` to `<your_nesi_project_code>` throughout, and add `<your_run_name>` to the README's placeholder list.

### F-14 · S3 · In-place edit of a tracked file breaks the documented update path
- **Where:** SOP_CONCOMPRA_NeSI.md:83, § 2 Build the conda environment; contradicted by :527
- **Quote:**
  > ```
  > # Strip the defaults channel (keeps a .bak)
  > sed -i.bak '/^[[:space:]-]*defaults[[:space:]]*$/d' CONCOMPRA.yml
  > ```
- **Defect:** This modifies a git-tracked file in the clone, and Section 10 later tells the reader to `git pull` in that same clone with no mention of the local modification.
- **Failure:** At update time `git pull` refuses with "Your local changes to the following files would be overwritten by merge: CONCOMPRA.yml". The reader either force-discards the edit — losing it silently, so the next environment build fails on the `defaults` channel again — or abandons the update.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — line 83 edits `CONCOMPRA.yml` in place; line 527 runs `git pull` in the same directory.
- **Fix:** Change line 83 to write a separate file rather than editing in place, and point `conda env create` at it: `sed '/^[[:space:]-]*defaults[[:space:]]*$/d' CONCOMPRA.yml > CONCOMPRA.nodefaults.yml`, then `-f CONCOMPRA.nodefaults.yml`. Add to Section 10: "`CONCOMPRA.nodefaults.yml` is untracked, so `git pull` will not conflict; regenerate it if upstream changes `CONCOMPRA.yml`."

### F-15 · S3 · Script numbers do not map onto section numbers, and 01-05 are undefined
- **Where:** SOP_CONCOMPRA_NeSI.md:171-175, § 4 Directory layout
- **Quote:**
  > ```
  > ├── 05b_dedup.sh                  # if dedup was needed (Stage 2)
  > ├── 06_concompra.sh               # main run submission (Section 5)
  > ├── 07_concompra_postprocess.sh   # post-processing submission (Section 7)
  > ```
- **Defect:** `06_` belongs to Section 5 and `07_` to Section 7, so the numbering is not a mapping; `05b_dedup.sh` is a script Section 3 never tells the reader to write, only an interactive loop; and scripts `01`-`05` are implied but exist only in another document.
- **Failure:** The reader looks for the numbering rule, finds that one script number matches its section and the other does not, and cannot tell whether `05b_dedup.sh` is something they are supposed to have created. They then either invent scripts 01-05 or assume they have skipped five steps.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED — the annotations in the layout state the mismatch themselves.
- **Fix:** Either renumber to match sections (`03_dedup.sh`, `05_concompra.sh`, `07_concompra_postprocess.sh`) and update every reference, or keep the numbers and add one line under the layout: "Numbers 01-05 are the QC and filtering scripts from `SOP_EMU_NeSI.md`; this document continues the same series, so its scripts start at 05b." Renumbering to match sections is preferable and matches the alignment the README describes for the read-based SOP.

### F-16 · S3 · "check the chimera-detection settings" with no location
- **Where:** SOP_CONCOMPRA_NeSI.md:325, § 6 Output files
- **Quote:**
  > A non-empty `clustered_consensus.fasta` with an empty chimera-filtered fasta means everything was called chimeric; check the chimera-detection settings.
- **Defect:** The document never says where the chimera-detection settings live or what a reasonable value is, so the instruction cannot be acted on.
- **Failure:** A reader in this failure mode grep-searches the document for "chimera", finds only this sentence and the file listing, and stops.
- **Type:** GAP
- **Confidence:** CONFIRMED — "chimera" appears at lines 39, 307-310, 325, 407, 433, 443 and nowhere gives a parameter or a file.
- **Fix:** Append: "The chimera step is a `vsearch --uchime` call inside `main.sh`; find it with `grep -n uchime /nesi/project/<your_nesi_project_code>/CONCOMPRA/scripts/main.sh` and change it in your run-directory copy (Section 5). Before changing anything, check that the input was not already degenerate — an all-chimeric call on a handful of consensus sequences usually means the clustering step, not the chimera step, is what failed."

### F-17 · S3 · "Runtime is typically under a minute" with no scale attached
- **Where:** SOP_CONCOMPRA_NeSI.md:335, § 7
- **Quote:**
  > Run it as a Slurm job rather than on a login node: the SILVA UDB needs about 3 GB of RAM and MAFFT adds more. Runtime is typically under a minute.
- **Defect:** The runtime is quoted with no OTU count, while the two steps that dominate it — MAFFT `--auto` and FastTree on ~1.4 kb full-length 16S sequences — scale steeply with the number of OTUs, which for a 192-sample run is not stated anywhere in the document.
- **Failure:** The job runs for forty minutes. The reader, told to expect under a minute, cancels it and starts debugging a job that was working, or resubmits it repeatedly.
- **Type:** CLARITY
- **Confidence:** NEEDS-BENCH-CHECK — time one post-processing job and record both the wall-clock time and `grep -c '^>' results/consensus_in_otutable.fas`, so the number can be quoted with the OTU count it applies to.
- **Fix:** Replace the last sentence with: "Runtime is dominated by MAFFT and FastTree and scales with the number of OTUs, not the number of samples: about <N> minutes for <M> OTUs on 16 CPUs. The 2 h walltime below is generous headroom, not an estimate."

### F-18 · S3 · CHALLENGE: unmasked alignment feeds the phylogeny
- **Where:** SOP_CONCOMPRA_NeSI.md:388-395, § 7 post-processing script steps 3-4
- **Quote:**
  > ```
  > # 3. Alignment
  > mafft --auto --thread 16 \
  >       "$RESULTS/consensus_in_otutable.fas" \
  >       > "$RESULTS/consensus_aligned.fas"
  >
  > # 4. Phylogeny
  > FastTree -gtr -nt "$RESULTS/consensus_aligned.fas" \
  >     > "$RESULTS/consensus.tree"
  > ```
- **Defect:** The raw MAFFT alignment goes straight into FastTree with no masking of gap-dominated or hypervariable columns, and the document gives no reasoning either way.
- **Failure:** CONCOMPRA consensus sequences vary in length because primer-chop and clustering do not produce uniform amplicon ends, so the alignment carries long terminal gap runs. Those columns inflate branch lengths for the shorter sequences, and every UniFrac distance computed from this tree in Part 2 then partly measures consensus length rather than phylogeny — a plausible-looking ordination driven by an artefact.
- **Type:** CHALLENGE
- **Confidence:** CONFIRMED — no masking or trimming step exists between MAFFT and FastTree.
- **Fix:** The lab should decide and record the decision. Either add a masking step between 3 and 4 (`trimal -in consensus_aligned.fas -out consensus_masked.fas -gt 0.5`, and point FastTree at the masked file), or add a sentence to "Notes on the steps" saying masking is deliberately omitted and why — for example, that the consensus sequences are near-uniform in length, with the check that shows it.

### F-19 · S3 · "Read retention" quoted for a step that removes no reads
- **Where:** SOP_CONCOMPRA_NeSI.md:407, § 7 Notes on the steps
- **Quote:**
  > Fewer sequences than OTU-table rows is expected. Read retention in the 70 to 90% range is typical for Nanopore 16S even when the OTU count drops further, because the filter mostly removes low-abundance OTUs.
- **Defect:** Step 1 filters the *fasta*, not the OTU table, so no reads are lost at this point; the read loss the sentence describes happens in Section 8, where the table is subset to the same OTUs, and the document gives no command for measuring it.
- **Failure:** The reader cannot check the number they are being told to expect, so the 70-90% figure functions as reassurance rather than as a gate; a run that retained 20% of reads passes unnoticed.
- **Type:** CLARITY
- **Confidence:** CONFIRMED — step 1 writes only `consensus_in_otutable.fas`; `otu_table.csv` is not modified until line 455.
- **Fix:** Move the retention sentence to Section 8, after the OTU table is filtered, and give it a command:

  ```bash
  # Reads retained after dropping OTUs that chimera detection removed
  awk -F, 'NR>1 {for(i=2;i<=NF;i++) t+=$i} END {print t}' ../concompra/results/otu_table.csv
  awk -F, 'NR>1 {for(i=2;i<=NF;i++) t+=$i} END {print t}' otu_table.csv
  ```

  with: "70 to 90% retention is typical for Nanopore 16S even when the OTU count drops much further, because the OTUs being dropped are mostly low-abundance. Well below 70% means chimera detection removed something abundant — inspect `chimeric_consensus.sequences.fas` before continuing."

### F-20 · S3 · Post-processing verification runs from the wrong directory
- **Where:** SOP_CONCOMPRA_NeSI.md:415-419, § 7 Verifying the outputs
- **Quote:**
  > ```
  > grep -c ">" results/consensus_in_otutable.fas    # OTU count
  > wc -l results/consensus.sintax                    # one row per OTU
  > wc -l results/consensus.tree                      # one line for Newick
  > ```
- **Defect:** The last directory the reader was told to be in is `/nesi/nobackup/<…>/<your_run_name>/` (line 401, to submit the job), where `results/` does not exist — it is at `concompra/results/`.
- **Failure:** All three commands return "No such file or directory" immediately after a job the reader believes succeeded. The most natural conclusion is that post-processing produced nothing, which is exactly the failure mode the surrounding text describes, so the reader starts debugging a working pipeline.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — line 401 `cd`s to the run root; line 365 defines `RESULTS=$BASE/concompra/results`.
- **Fix:** Prepend a `cd` to the block: `cd /nesi/nobackup/<your_nesi_project_code>/<your_run_name>/concompra/`.

### F-21 · S3 · "All four outputs" but only three are checked
- **Where:** SOP_CONCOMPRA_NeSI.md:421, § 7 Verifying the outputs
- **Quote:**
  > All four outputs should have content. An empty sintax file usually means the `SILVA_UDB` path is wrong; an empty alignment means MAFFT received an empty input from step 1.
- **Defect:** Three commands precede this sentence; the alignment — the one the sentence goes on to diagnose — has no check.
- **Failure:** The reader counts three, assumes they have missed one, and either goes looking for a fourth command or checks only the three shown and never inspects the alignment they are told to diagnose.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED — lines 416-418 contain three commands.
- **Fix:** Add `grep -c ">" results/consensus_aligned.fas   # must equal the OTU count` as the third command, before the tree check.

### F-22 · S3 · Handoff file labelled "(column 4)" but the whole file is copied
- **Where:** SOP_CONCOMPRA_NeSI.md:435, § 8 The R-ready folder
- **Quote:**
  > ```
  > ├── otu_taxonomy.sintax     sintax output (column 4)
  > ```
- **Defect:** The build step copies the complete four-column vsearch output (`cp … consensus.sintax otu_taxonomy.sintax`, line 451), so the file is not column 4; line 483 then correctly tells the reader to parse column 4 in R.
- **Failure:** A reader who believes the file has already been reduced reads it in R and takes its first column — the query ID — as taxonomy, or is left unsure which of the two statements is current at the exact point the document has twice warned that picking the wrong column "silently corrupts taxonomy".
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED — line 451 copies the file unmodified.
- **Fix:** Change the listing line to: `├── otu_taxonomy.sintax     Full 4-column vsearch --sintax output; parse column 4 in R`.

### F-23 · S3 · Metadata file requirements are implied by a command, never stated
- **Where:** SOP_CONCOMPRA_NeSI.md:474-476, § 8 Checking sample IDs
- **Quote:**
  > ```
  > cut -d, -f1 sample_metadata.csv | tail -n +2 | sort > /tmp/meta_samples.txt
  > ```
- **Defect:** The only statement of what `sample_metadata.csv` must look like — comma-separated, one header row, sample IDs in the first column — is buried in the flags of a `cut` command; the folder listing describes it only as "Your sample sheet (added manually)".
- **Failure:** The reader exports a sheet from Excel with the sample ID in column 3, or as semicolon-separated, or with two header rows. `diff` then reports that every ID differs, and the reader looks for the fault in the OTU table rather than in the file they wrote.
- **Type:** GAP
- **Confidence:** CONFIRMED — the requirements appear nowhere in prose.
- **Fix:** Change the folder listing line to `├── sample_metadata.csv     Your sample sheet: comma-separated, one header row, sample ID in the first column` and add above the diff block: "The IDs must match the fastq basenames exactly — case, hyphens and leading zeros included. Excel is the usual source of a mismatch: it strips leading zeros from IDs like `007` and can save with a `\r` line ending, which `diff` will report as a difference on every line."

### F-24 · S3 · `minimap2 2.1.1` pin may be a typo the reader is told to verify against
- **Where:** SOP_CONCOMPRA_NeSI.md:98 and :521
- **Quote:**
  > Confirm the upstream pins are present: `filtlong 0.2.1`, `minimap2 2.1.1`, `python 3.11`, `numba 0.60.0`.
  >
  > and, at line 521:
  >
  > > `minimap2` is pinned to 2.1.1 by upstream; do not change it.
- **Defect:** minimap2 2.1.1 dates from 2017 and predates the Nanopore chemistries this document targets (`FLO-PRO114M`, `dna_r10.4.1`); a 2025 tool pinning it is surprising enough that it reads as a transcription error for a 2.x release such as 2.21 or 2.24.
- **Failure:** The reader runs `conda list`, sees a different minimap2 version, and — following the instruction to "confirm the upstream pins are present" — concludes the environment built wrongly and rebuilds it, or worse, downgrades minimap2 by hand and breaks a working environment.
- **Type:** CORRECTNESS
- **Confidence:** NEEDS-BENCH-CHECK — `grep -i minimap2 /nesi/project/<your_nesi_project_code>/CONCOMPRA/CONCOMPRA.yml` gives the actual upstream pin.
- **Fix:** Confirm the pin against `CONCOMPRA.yml` and correct both lines if it is wrong. Whichever it is, change line 98 to: "Confirm the pins in `CONCOMPRA.yml` are what got installed — compare `conda list` against the yml rather than against the versions quoted here, which will drift."

### F-25 · S4 · Front-matter summary omits the pre-flight screen
- **Where:** SOP_CONCOMPRA_NeSI.md:5
- **Quote:**
  > This document covers the CONCOMPRA pipeline on NeSI Mahuika: installation, run configuration, submission, verification, post-processing (taxonomy, alignment, phylogeny), and preparing outputs for R.
- **Defect:** The duplicate-read screen — the step the roadmap calls the pipeline's main failure mode — is missing from the list.
- **Failure:** A reader skimming the opening paragraph to decide what to read does not learn that a mandatory pre-flight step exists.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED
- **Fix:** Insert "duplicate-read screening," after "installation,".

### F-26 · S4 · Roadmap says to submit `main.sh`; you submit `06_concompra.sh`
- **Where:** SOP_CONCOMPRA_NeSI.md:24
- **Quote:**
  > Submit main.sh (Slurm) → check per-sample consensus on disk
- **Defect:** `main.sh` is CONCOMPRA's internal driver; the reader submits `06_concompra.sh`, which invokes it.
- **Failure:** A reader following the roadmap literally runs `sbatch main.sh` in the CONCOMPRA scripts directory.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED — line 275 is `sbatch 06_concompra.sh`.
- **Fix:** Change to "Submit `06_concompra.sh` (Slurm) → verify per-sample output".

### F-27 · S4 · "Slurm" here, "SLURM" in the README
- **Where:** SOP_CONCOMPRA_NeSI.md:24, :242, :335
- **Quote:**
  > Run it as a Slurm job rather than on a login node
- **Defect:** The README capitalises it `SLURM` throughout; this document uses `Slurm` throughout.
- **Failure:** Trivial, but it is the sort of drift that accumulates across five documents.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED — README:13, :20.
- **Fix:** Pick one spelling repository-wide and apply it.

### F-28 · S4 · Section 1 prose and table say the same thing twice
- **Where:** SOP_CONCOMPRA_NeSI.md:41-46
- **Quote:**
  > Emu gives fast alignment-based taxonomy and relative abundance against curated databases; CONCOMPRA gives reference-free consensus sequences (de novo OTUs) for novel or poorly-resolved taxa and for sequence-level work like trees and primer-mismatch checks.
- **Defect:** The two-row table immediately below restates the same contrast in fewer words.
- **Failure:** The reader parses the same comparison twice before reaching anything new.
- **Type:** STRUCTURE
- **Confidence:** CONFIRMED
- **Fix:** Keep the table, cut the prose sentence down to the part the table does not carry: "Use it alongside Emu, on the same input, and compare."

### F-29 · S4 · `conda activate` then `conda list -p` is redundant
- **Where:** SOP_CONCOMPRA_NeSI.md:94-95
- **Quote:**
  > ```
  > conda activate /nesi/project/<your_project_code>/conda_envs/CONCOMPRA
  > conda list -p /nesi/project/<your_project_code>/conda_envs/CONCOMPRA
  > ```
- **Defect:** After activating, `conda list` lists the active environment; repeating the path invites a mismatch between the two lines.
- **Failure:** A reader who edits one path and not the other lists a different environment than the one they activated.
- **Type:** CLARITY
- **Confidence:** CONFIRMED
- **Fix:** Second line becomes `conda list`.

### F-30 · S4 · medaka/racon/samtools explained twice
- **Where:** SOP_CONCOMPRA_NeSI.md:98 and :502-504
- **Quote:**
  > The environment does not include `medaka`, `racon`, or `samtools`; CONCOMPRA uses `lamassemble` for consensus, so their absence is correct and you should not add them.
- **Defect:** Section 9 repeats the same explanation in full.
- **Failure:** Minor, but the two copies can drift.
- **Type:** STRUCTURE
- **Confidence:** CONFIRMED
- **Fix:** Keep the Section 9 entry — it is the one a reader will search for — and shorten line 98 to: "The environment deliberately excludes `medaka`, `racon` and `samtools` (Section 9)."

### F-31 · S4 · CHALLENGE: "No canonical SINTAX-formatted SILVA exists"
- **Where:** SOP_CONCOMPRA_NeSI.md:114
- **Quote:**
  > No canonical SINTAX-formatted SILVA exists, so build one from Emu's SILVA bundle.
- **Defect:** SINTAX-formatted SILVA training sets are distributed by the SINTAX/usearch community, so the claim is contestable; the real and much stronger reason follows in the next clause, that using Emu's bundle keeps the SILVA release identical to the parallel Emu workflow.
- **Failure:** A reader who knows of a distributed SINTAX SILVA loses confidence in the paragraph and may substitute a different release, silently breaking comparability with the Emu run.
- **Type:** CHALLENGE
- **Confidence:** NEEDS-BENCH-CHECK — check whether a SINTAX-formatted SILVA at v138.1 is available from the vsearch/SINTAX distributions.
- **Fix:** Lead with the version-matching reason: "Build the SINTAX reference from Emu's SILVA bundle rather than downloading a pre-made one, so the SILVA release is byte-identical to the parallel Emu workflow and the two taxonomies are comparable."

### F-32 · S4 · Shebangs differ between the two submission scripts
- **Where:** SOP_CONCOMPRA_NeSI.md:249 and :352
- **Quote:**
  > `#!/bin/bash -e` (line 249) against `#!/bin/bash` (line 352)
- **Defect:** Two scripts in the same document use different error-handling shebangs, and the difference is never explained; the post-processing script's `set -euo pipefail` makes its bare shebang harmless, but the reader cannot tell that is deliberate.
- **Failure:** A reader copying these as templates does not know which form to use for their own scripts.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED
- **Fix:** Use `#!/bin/bash` plus an explicit `set -euo pipefail` in both, and drop the `-e` shebang.

### F-33 · S4 · Two spellings of the same FASTA header grep
- **Where:** SOP_CONCOMPRA_NeSI.md:316 and :416
- **Quote:**
  > `grep -c "^>" results/noglobal_nolocalchim.consensus.sequences.fas` (line 316) against `grep -c ">" results/consensus_in_otutable.fas` (line 416)
- **Defect:** Same operation, two patterns.
- **Failure:** A reader adapting the command to a file where `>` also appears in a description line gets a wrong count from the unanchored form.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED
- **Fix:** Use `grep -c "^>"` in both places.

### F-34 · S4 · Emu cross-check has no branch for readers who ran only CONCOMPRA
- **Where:** SOP_CONCOMPRA_NeSI.md:327-329
- **Quote:**
  > For one or two samples, compare the dominant taxa from Emu with the closest matches for the corresponding CONCOMPRA consensus sequences.
- **Defect:** The README presents this SOP as an alternative to the Emu pipeline, so a reader may have no Emu results; the step gives no fallback.
- **Failure:** The reader either skips the only cross-validation in the document or stops to run a whole second pipeline with no guidance on doing so.
- **Type:** GAP
- **Confidence:** CONFIRMED — no alternative is offered.
- **Fix:** Add: "If you have not run Emu, BLAST two or three of the most abundant consensus sequences against NCBI nt instead. The point is to confirm the consensus sequences are 16S from plausible taxa, not to validate abundances."

### F-35 · S4 · Thread count hardcoded in three places
- **Where:** SOP_CONCOMPRA_NeSI.md:357, :386, :389
- **Quote:**
  > `#SBATCH --cpus-per-task=16` … `--threads 16` … `--thread 16`
- **Defect:** Three copies of one number that must agree.
- **Failure:** A reader who lowers `--cpus-per-task` to 8 leaves vsearch and MAFFT asking for 16, oversubscribing the allocation.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED
- **Fix:** Use `--threads "$SLURM_CPUS_PER_TASK"` and `--thread "$SLURM_CPUS_PER_TASK"`.

### F-36 · S4 · `README.md   Provenance` is never specified
- **Where:** SOP_CONCOMPRA_NeSI.md:438
- **Quote:**
  > ```
  > └── README.md               Provenance
  > ```
- **Defect:** Unlike the database README at line 579, whose required contents are listed, this one is a bare word.
- **Failure:** The reader writes nothing, or writes something that omits the fields a methods section needs.
- **Type:** GAP
- **Confidence:** CONFIRMED
- **Fix:** Change to: `└── README.md               Provenance: run name, CONCOMPRA commit, SILVA build date, dedup applied yes/no, samples dropped and why`.

### F-37 · S4 · `assemble_R_inputs.py` referenced with no location
- **Where:** SOP_CONCOMPRA_NeSI.md:443
- **Quote:**
  > The lab's `assemble_R_inputs.py` does this. A self-contained equivalent:
- **Defect:** The script is named but not located; the equivalent that follows makes it optional, so the mention adds a dead end.
- **Failure:** The reader searches for a file they do not need.
- **Type:** CLARITY
- **Confidence:** CONFIRMED
- **Fix:** Either give the path or drop the sentence and open with "Do this with:".

### F-38 · S4 · Scratch files written to `/tmp` on a shared node
- **Where:** SOP_CONCOMPRA_NeSI.md:474-476
- **Quote:**
  > ```
  > head -1 otu_table.csv | tr ',' '\n' | tail -n +2 | sort > /tmp/otu_samples.txt
  > ```
- **Defect:** Fixed `/tmp` filenames on a shared login node collide between users and persist after the check.
- **Failure:** Two lab members run this at once and diff each other's sample lists.
- **Type:** CLARITY
- **Confidence:** CONFIRMED
- **Fix:** Write both files into the current directory and delete them after the `diff`.

## Keep list

1. **:33** — "`main.sh` logs 'consensus sequences generated' for every sample even when a step failed silently". This is the document's most valuable sentence and it belongs in the roadmap where it is. A rewrite tightening the roadmap into a plain stage list would drop it.
2. **:75** — the `defaults`-channel and Miniforge-not-Miniconda paragraph. It looks like installation trivia and is the difference between a working environment and an unexplained solver failure.
3. **:98 / :502-504** — medaka, racon and samtools deliberately absent. A reader who "fixes" the environment by adding them breaks it; a de-duplication pass (F-30) must keep one full copy, not compress both.
4. **:130** — "`filtlong 0.2.1` aborts on duplicate read names, and the run then fails silently". This is the justification for the entire pre-flight section; without it Section 3 looks optional.
5. **:147** — "POD5 read IDs are globally-unique UUIDs, so duplicate IDs come from file-level duplication, not collisions between distinct reads. Removing by read name keeps one copy per physical read and is lossless." This is what makes name-based deduplication defensible rather than data loss.
6. **:201** — "CONCOMPRA changes into subdirectories during execution, so relative paths in `directory_list.txt` break silently. Use absolute paths."
7. **:211** — the primer-orientation paragraph, including the explicit sense-strand 1492R sequence and the statement that the wrong orientation gives "almost no primer hits and an empty downstream funnel". Every protocol the reader has seen gives the reverse-complement.
8. **:283** — "`main.sh` has no `set -e`, so a failure in an inner step … does not stop the script or change its exit code". The restructure in F-02 must carry this forward verbatim.
9. **:409** — "take column 4, not column 2 … Using column 2 silently corrupts taxonomy at low-confidence ranks" plus the 0.8 cutoff rationale. This is the clearest silent-failure warning in the post-processing section.

## Gaps

- **SHOULD-ADD — R code to turn `otu_taxonomy.sintax` into a phyloseq `tax_table`.** Section 8 describes the sintax string format (line 483) and warns twice that taking the wrong column corrupts taxonomy, then leaves the reader to write the parser. Every other handoff artefact in the folder is ready to read directly; this one is not, and it is the one with a documented silent-failure mode. ~25 lines of R, placed under "Building the phyloseq object". It must state which rank names it produces so they match what `SOP_R_Analysis.md` expects.
- **SHOULD-ADD — what to do with samples that came out empty.** Section 6 detects them and Section 9 explains why they happen, but nothing says whether to re-run them, drop them from `directory_list.txt` and re-run, or carry them into R as zero-count rows, or what that does to the SRS normalisation downstream. ~1 paragraph.
- **SHOULD-ADD — expected scale.** The document never says how many OTUs a run of this size produces. A reader with 40 OTUs and a reader with 40,000 both have no way to tell whether that is normal, and it is the single number that would tell them whether clustering worked. One sentence in Section 6, alongside the existing 45%/80%/29,000 read arithmetic.
- **SHOULD-ADD — controls.** Negative controls are mentioned once in passing (line 318, in an awk comment) and again at line 325. Nothing tells the reader to include them, to keep them in `directory_list.txt`, or to flag them in the metadata — which the decontam step in Part 2 requires. ~1 short paragraph in Section 3 or 4.
- **CONSIDER — disk footprint.** Once `rm -rf temporary` is commented out (F-02), `temporary/` persists for a 192-sample run on `nobackup`. An estimate would let the reader check their quota first. One sentence in Section 5.
- **CONSIDER — walltime exhaustion.** 48 h is quoted with headroom, but nothing says what happens if the job is killed at the limit: whether `main.sh` can resume, or whether the run must start again. One sentence in Section 9.
- **CONSIDER — `cluster_plots.pdf`.** Listed as a diagnostic output with no statement of what a good or bad plot looks like, so it will not be opened. Two sentences in Section 6.
- **CONSIDER — a methods-section block.** The read-based SOP has one; this document has the raw material scattered across Sections 2, 4, 7 and Appendix A (CONCOMPRA commit, SILVA release and build date, primer sequences, sintax cutoff, alignment and tree settings, samples dropped) but never assembles it. ~10 lines.

## Cross-document flags

Every claim this document makes about another file, for the between-documents agent to resolve:

| Line | Claim |
|---|---|
| 5 | `SOP_NeSI_Pipeline.md` is named as the Emu-based pipeline. No such file exists (F-03); the intended target is presumably `SOP_EMU_NeSI.md`. |
| 5, 30, 481 | "Its outputs feed the same R analysis (`SOP_R_Analysis.md`)" — check that Part 2 actually accepts a CONCOMPRA-shaped input (counts matrix, sintax taxonomy, Newick tree) and that its front matter now points back here. |
| 7 | Placeholder `<your_project_code>` vs README:40/50 `<your_nesi_project_code>`; `<your_run_name>` is not in the README's placeholder list at all (F-13). |
| 41, 48 | "Use it alongside Emu" and "Run both on the same deduplicated input and compare" — does `SOP_EMU_NeSI.md` mention deduplication, or would an Emu run made from `filtered/` no longer be comparable with a CONCOMPRA run made from `filtered_dedup/`? |
| 114 | "Using Emu's bundle keeps the SILVA release identical to the parallel Emu workflow" — README:85 says the amplicon work uses SILVA v138.1 via Emu's prebuilt OSF archives; confirm the Emu SOP uses the same bundle this appendix reformats, and that `species_taxid.fasta` is the filename it lands under. |
| 130 | "Emu tolerates this silently" — does `SOP_EMU_NeSI.md` say anything about duplicate read IDs? If not, the Emu SOP has the same hazard with no screen. |
| 151, 171-175 | Input directory `filtered/` and script numbers `05b`/`06`/`07` both assume the Emu SOP's numbered script series (README:51 names `01_nanoplot_raw.sh`, `02_chopper_filter.sh`, `03_nanoplot_filtered.sh`). Confirm `05` exists and that `filtered/` is the name the Emu SOP writes. |
| 152 | `seqkit` is required here but README:69 lists only `seqtk/1.4-GCC-11.3.0` for CONCOMPRA. Either the README's tool list is incomplete or the command is wrong (F-05). |
| 483 | sintax rank prefixes `d:/p:/c:/o:/f:/g:/s:` — check what column names `SOP_R_Analysis.md` expects in the `tax_table` (Kingdom vs Domain in particular). |
| 484 | "Root it with `phangorn::midpoint()`" — is `phangorn` in Part 2's install block? |
| 485 | "prevalence thresholds tuned for Illumina ASV data may discard real signal" — does Part 2 apply a prevalence filter, and does this contradict it? |
| — | README:15's description of this SOP is accurate as far as it goes, but does not warn that the phyloseq build needs extra parsing not covered by Part 2. README:108 records this SOP as "indexed", not audited. |

## Rewrite plan

Ordered by dependency. Items 1-4 can proceed with no knowledge of the other SOPs; items 5-6 need the cross-document agent's answers first.

1. **Make Section 6 executable.** Closes F-02 and F-08. Add the "keep the per-sample intermediates" step to Section 5, rebuild the per-sample gate on `results/otu_table.csv`, demote the `temporary/` check to a diagnostic, and rewrite Section 10's temporary-directory entry to match. Fix the OTU-table orientation row while you are in Section 6. ~1 page rewritten, ~15 lines added. Independent.
2. **Make Section 3 executable.** Closes F-01, F-05, F-06. One input directory name, a screen and a dedup that both key on the read name, a module-free dedup, an explicit clean-screen branch, and the missing `cd` in Section 4's symlink block. ~1 page rewritten. Independent, and must land before item 3 so the prerequisites block can name the right directory.
3. **Add the front matter the document is missing.** Closes F-03, F-04, F-13, F-25. Prerequisites block, corrected companion-document reference, placeholder rename throughout, summary sentence. ~15 lines added plus a global search-and-replace. Independent except that the reference target should be confirmed against the repository listing.
4. **Repair the post-processing section.** Closes F-07, F-09, F-10, F-17, F-19, F-20, F-21, F-24, plus S4s F-33 and F-35. The `THREADS` paragraph, the `seqtk` guard, the FastTree support wording, the `cd` in the verification block, the missing fourth check, and moving the read-retention paragraph to Section 8. ~1 page rewritten, ~15 lines added. Independent; the `-boot` and `minimap2` items need their bench checks first.
5. **Make Appendix A self-contained.** Closes F-12. Reorder the build so the directory is created first, and ship the reformatter — either the lab's copy, committed to the repository, or the equivalent in the fix above. ~50 lines added. Needs a lab decision on which script is canonical, and one `head -2 species_taxid.fasta` against the real Emu bundle.
6. **Close the R handoff.** Closes F-11, F-22, F-23, F-36, and the first Gaps item. Replace the Biopython block with the awk equivalent, correct the taxonomy-file label, specify the metadata format and the folder README, and add the sintax-to-`tax_table` R snippet. ~40 lines. **Blocked on the cross-document agent** for Part 2's expected rank names and whether it already parses sintax.
7. **Polish pass.** Closes the remaining S3/S4 items: F-14, F-15, F-16, F-18, F-26 through F-32, F-34, F-37, F-38. Mostly one-line edits, except F-18 (alignment masking), which is a lab decision that must be recorded either way, and F-15 (script renumbering), which touches every script reference in the document and should be done in one commit. ~1-2 hours. Independent, but do it last so it does not conflict with items 1-6.

---

CONTRACT: PASS

- [x] Ledger accounts for every heading in the file — all 45 markdown headings (lines 3 to 587), in order, plus one row for the front matter above the first `##`
- [x] Every finding has a line-anchored verbatim quote
- [x] Every finding has a concrete Failure line
- [x] Every S1 and S2 has paste-ready replacement text
- [x] Every `NEEDS-BENCH-CHECK` names the one check that settles it — F-10, F-17, F-24, F-31
- [x] No proposed cut touches load-bearing content — the only removals proposed are F-28 (a prose restatement of the table beside it), F-30 (the second full copy of the medaka note, keeping the searchable one) and F-37 (a pointer to an unlocatable script); every threshold justification, silent-failure warning, expected-output statement and citation is preserved, and F-19 moves the read-retention reasoning rather than dropping it
- [x] S4 count ≤ 15 — 14
- [x] Sections match the required skeleton exactly, in order
