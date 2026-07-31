## Document: SOP_CONCOMPRA_NeSI.md

This SOP walks a Part-1 graduate through running the CONCOMPRA consensus-OTU
pipeline on NeSI and handing its outputs to Part 2. Its post-processing half
(SINTAX taxonomy, MAFFT, FastTree) and its R-prep half are accurate and
carefully reasoned — I ran the vsearch/seqtk/R steps and they hold. The run
half is broken at the point that matters most: the SOP fundamentally
misunderstands `directory_list.txt` (it is a *sourced config file*, not a list
of fastq paths) and gives the primer file the wrong header names, and either
mistake makes a faithful reader's run produce **empty output with no error** —
exactly the failure the document warns about elsewhere but then misattributes in
its own troubleshooting. The single change that would most improve it: replace
the "Sample list" and "Primer file" subsections with instructions that configure
CONCOMPRA the way its own `main.sh` actually consumes these files.

## Section ledger

| § | Heading | Lines | Verdict | Findings |
|---|---|---|---|---|
| — | Title + scope + Before you start | 1-20 | CLEAN | — |
| — | Quick Roadmap | 23-46 | CLEAN | — |
| 1 | Overview | 49-61 | CLEAN | — |
| 2 | Installation | 64-67 | CLEAN | — |
| 2.1 | Locations | 68-75 | CLEAN | — |
| 2.2 | Clone the repository | 76-83 | CLEAN | — |
| 2.3 | Build the conda environment | 85-101 | CLEAN | — |
| 2.4 | Verify the environment | 103-122 | CLEAN | — |
| 2.5 | SILVA SINTAX database | 124-137 | CLEAN | — |
| 3 | Pre-flight: Screen for Duplicate Reads | 140-142 | CLEAN | — |
| 3.1 | Screen | 144-161 | CLEAN | — |
| 3.2 | Deduplicate | 163-179 | EXPAND | F-04 |
| 3.3 | Record run metadata | 181-183 | CLEAN | — |
| 4 | Run Configuration | 187 | CLEAN | — |
| 4.1 | Directory layout | 189-206 | TIGHTEN | F-09 |
| 4.2 | Symlink the input fastqs | 208-219 | CLEAN | — |
| 4.3 | Sample list | 221-229 | REWRITE | F-01 |
| 4.4 | Primer file | 231-242 | REWRITE | F-02 |
| 4.5 | Threads | 244-248 | TIGHTEN | F-05 |
| 5 | Submitting the Run | 252-311 | REWRITE | F-06, F-10 |
| 6 | Verifying the Run | 314-316 | CLEAN | — |
| 6.1 | Per-sample verification | 318-344 | REWRITE | F-03 |
| 6.2 | Output files | 346-370 | TIGHTEN | F-07 |
| 6.3 | Cross-check against Emu | 372-374 | CLEAN | — |
| 7 | Post-processing | 378-448 | CLEAN | — |
| 7.1 | Notes on the steps | 450-456 | CLEAN | — |
| 7.2 | Verifying the outputs | 458-466 | CLEAN | — |
| 8 | Preparing for R / phyloseq | 470-472 | CLEAN | — |
| 8.1 | The R-ready folder | 474-484 | CLEAN | — |
| 8.2 | Building it | 486-517 | CLEAN | — |
| 8.3 | Checking sample IDs | 519-527 | CLEAN | — |
| 8.4 | Building the phyloseq object | 529-569 | CLEAN | — |
| 9 | Troubleshooting | 573 | CLEAN | — |
| 9.1 | Empty consensus output | 575-579 | TIGHTEN | F-08 |
| 9.2 | Empty sintax output | 581-583 | CLEAN | — |
| 9.3 | medaka, racon, or samtools missing | 585-587 | CLEAN | — |
| 9.4 | A run is stuck or slow | 589-596 | CLEAN | — |
| 10 | Maintenance | 600 | CLEAN | — |
| 10.1 | Updating CONCOMPRA | 602-613 | CLEAN | — |
| 10.2 | The temporary directory | 615-624 | CLEAN | — |
| A | Appendix A: SILVA SINTAX Database Build | 628-630 | CLEAN | — |
| A.1 | The reformatter | 632-640 | CLEAN | — |
| A.2 | Build | 642-662 | CLEAN | — |
| A.3 | Refreshing for a new SILVA release | 664-666 | CLEAN | — |
| B | Appendix B: References | 670-684 | CLEAN | — |

## Findings

### F-01 · S1 · directory_list.txt built as a path list, but CONCOMPRA sources it as a config file
- **Where:** SOP_CONCOMPRA_NeSI.md:221-229, § 4 Sample list
- **Anchor:** `ls *.fastq | xargs -I{} realpath {} > directory_list.txt`
- **Quote:**
  > CONCOMPRA changes into subdirectories during execution, so relative paths in `directory_list.txt` break silently. Use absolute paths.
  > …
  > ls *.fastq | xargs -I{} realpath {} > directory_list.txt
  > wc -l directory_list.txt   # should equal your sample count
- **Defect:** `directory_list.txt` is not a list of fastq paths. CONCOMPRA's `main.sh` runs `source directory_list.txt` and reads its input reads by globbing `*.fastq` in the run directory (the symlinks), *not* from this file. The template file is a shell fragment that sets `TEMPLATE_DIR`, `PRIMER_SET`, `MIN`, `MAX`, `MERGE_CONSENSUS`, `READS_CONSENSUS` and `THREADS`. The SOP's own "Threads" subsection (`:245`) even says "`THREADS` in `directory_list.txt`", contradicting this one.
- **Failure:** The reader builds a `directory_list.txt` containing only absolute paths. `main.sh` sources it: no config variable is set. With `MIN`/`MAX` empty the length filter `length(seq) >= min && length(seq) <= max` becomes `>= 0 && <= 0`, so **every read is discarded**; with `TEMPLATE_DIR`/`PRIMER_SET` empty the sub-scripts and primer file are not found. `main.sh` has no `set -e`, so it runs to completion, prints "consensus sequences generated for …" for every sample, and leaves an empty/near-empty `otu_table.csv`. The reader gets no error and a wrong result.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED
- **Evidence:** Cloned upstream `willem-stock/CONCOMPRA` (commit `7a957d1`). `scripts/main.sh:1` is `source directory_list.txt`; `scripts/main.sh:7` is `for file in  *.{fastq,fastq.gz}; do` (reads come from the glob, not the file). The shipped `directory_list.txt` contains `TEMPLATE_DIR=…`, `PRIMER_SET=…`, `MIN=1400`, `MAX=1700`, `MERGE_CONSENSUS=1`, `READS_CONSENSUS=40`, `THREADS=8` — no paths.
- **Fix:** Replace the subsection (heading and body) with:

  ```
  ### **Run configuration file**

  Despite its name, `directory_list.txt` is **not** a list of fastq paths — it is
  a shell fragment that `main.sh` runs with `source directory_list.txt`, and it
  holds every parameter the run needs. `main.sh` finds the input reads by globbing
  `*.fastq` in the run directory (the symlinks you just made), not from this file.
  Copy the template out of the repo and edit it in place:

  ```bash
  cd /nesi/nobackup/<your_nesi_project_code>/<your_project>/concompra/
  cp /nesi/project/<your_nesi_project_code>/CONCOMPRA/directory_list.txt .
  ```

  Set these; leave the rest at their defaults:

  | Variable | Set to | Why |
  |---|---|---|
  | `TEMPLATE_DIR` | `/nesi/project/<your_nesi_project_code>/CONCOMPRA/scripts` | Where `main.sh` finds `consensus_generation.sh` and `primer-chop`. Empty → sub-scripts not found. |
  | `PRIMER_SET` | `/nesi/nobackup/<your_nesi_project_code>/<your_project>/concompra/primer_set.fa` | Absolute path to your primer file (next subsection). Absolute because the run `cd`s into subdirectories. |
  | `MIN` / `MAX` | `1400` / `1700` | Length window (bp) kept before clustering; the defaults suit full-length 16S. Leave `MIN`/`MAX` unset and the filter drops **every** read, silently. |
  | `THREADS` | `4` | See [Threads](#threads). |

  One `directory_list.txt` serves the whole run; there are no per-sample entries.
  Confirm the edits took:

  ```bash
  grep -E '^(TEMPLATE_DIR|PRIMER_SET|MIN|MAX|THREADS)=' directory_list.txt
  ```
  ```

### F-02 · S1 · primer_set.fa headers 27F/1492R are ignored; primer-chop keys on head/tail in names
- **Where:** SOP_CONCOMPRA_NeSI.md:231-242, § 4 Primer file
- **Anchor:** `>1492R`
- **Quote:**
  > ```
  > >27F
  > AGAGTTTGATCCTGGCTCAG
  > >1492R
  > AAGTCGTAACAAGGTAACC
  > ```
- **Defect:** `primer-chop` decides which end of a read is the 5' end from the **name** of each primer: the forward primer's header must contain `head` and the reverse primer's `tail` (case-insensitive, substring). Headers `>27F` and `>1492R` contain neither, so `primer-chop` classifies no reads as "good", produces an empty `good-fwd.fq`, and the run funnels to nothing. The orientation guidance in the same subsection is correct and must be kept; only the header names (and the missing "write it to `primer_set.fa`" step) are wrong.
- **Failure:** The reader writes `primer_set.fa` with `>27F`/`>1492R`. `primer-chop` finds no head/tail primer on any read, every read lands in `no_head`/`no_tail`, `filtlong` receives an empty file, no consensus is built, and `otu_table.csv` is empty — with no error, because `main.sh` has no `set -e`. Section 9 then sends the reader chasing duplicate reads or read counts instead.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED
- **Evidence:** `scripts/primer-chop/bin/primer-chop-analyze:85` is `if "head" in primerName …`, `:90` is `elif "tail" in primerName:`; the tool's `README.md` states "The head primer should have 'head' in its name (case-insensitive). Likewise for the tail primer." The shipped `primer_set.fa` uses `>head` / `>tail`.
- **Fix:** Replace the code block and add the write step (keep the surrounding orientation prose):

  ```
  `primer-chop` decides which end of each read is the 5' end from the **names** of
  the two primers: the forward (head) primer's header must contain `head`, and the
  reverse (tail) primer's header `tail` (case-insensitive). Headers like `>27F` /
  `>1492R` are silently ignored — `primer-chop` then detects no primers, every read
  is discarded, and the run produces empty output.

  Give both sequences as they appear on the forward (sense) strand, 5' to 3'. For
  1492R that is `AAGTCGTAACAAGGTAACC`, not the reverse-complement
  `GGTTACCTTGTTACGACTT` printed in most protocols; the wrong orientation gives
  almost no primer hits and an empty downstream funnel. Write the file into the run
  directory as `primer_set.fa` (the path you set as `PRIMER_SET`):

  ```bash
  cd /nesi/nobackup/<your_nesi_project_code>/<your_project>/concompra/
  cat > primer_set.fa <<'EOF'
  >head_27F
  AGAGTTTGATCCTGGCTCAG
  >tail_1492R
  AAGTCGTAACAAGGTAACC
  EOF
  ```

  For other primer sets, apply the same two rules: name the forward primer `head…`
  and the reverse `tail…`, both as they appear on the forward strand.
  ```

### F-03 · S2 · Run-verify "submitted" count reads config-file line count, not the sample count
- **Where:** SOP_CONCOMPRA_NeSI.md:331-334, § 6 Per-sample verification
- **Anchor:** `echo "submitted:    $(wc -l < directory_list.txt)"`
- **Quote:**
  > echo "in otu_table: $(head -1 results/otu_table.csv | awk -F, '{print NF-1}')"
  > echo "submitted:    $(wc -l < directory_list.txt)"
- **Defect:** `directory_list.txt` is a config file of ~12 lines (F-01), not one line per sample, so `wc -l < directory_list.txt` is not the number of samples submitted. The gate ("Both counts must agree", `:336`) will report a spurious mismatch on a perfectly healthy run.
- **Failure:** The reader runs the verification, sees `in otu_table: 192` vs `submitted: 12`, concludes from the SOP that "Any shortfall is a silent failure", and either discards good results or burns time debugging a run that worked.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED
- **Evidence:** Same cloned source as F-01: the shipped `directory_list.txt` is variable assignments; `main.sh` never appends sample paths to it. The correct submitted count is the number of symlinked fastqs, which `:218` already computes with `ls *.fastq | wc -l`.
- **Fix:** Replace the two lines with (cwd is `…/concompra/`, so the glob is the symlinks):

  ```bash
  echo "in otu_table: $(head -1 results/otu_table.csv | awk -F, '{print NF-1}')"
  echo "submitted:    $(ls *.fastq | wc -l)"
  ```

### F-04 · S3 · Deduplicate step calls seqkit with no module load or env activation stated
- **Where:** SOP_CONCOMPRA_NeSI.md:167-176, § 3 Deduplicate
- **Anchor:** `seqkit rmdup -n "$f" -o filtered_dedup/`
- **Quote:**
  > for f in filtered/*.fastq; do
  >     seqkit rmdup -n "$f" -o filtered_dedup/$(basename "$f")
  > done
- **Defect:** `seqkit` (note: not `seqtk`, used later) is never made available for this step. It is not on a bare login shell; it comes from the CONCOMPRA conda env (`seqkit==2.8.2`) or the `SeqKit` module. A reader who reaches Section 3 in a fresh shell hits `seqkit: command not found`.
- **Failure:** Reader opens a new session the next day, runs the dedup loop, gets `command not found` on every sample, and stalls until they discover where `seqkit` lives.
- **Type:** GAP
- **Confidence:** VERIFIED
- **Evidence:** `module spider seqkit` → `SeqKit/0.15.0 … 2.12.0` (capitalised `SeqKit`), not loaded anywhere in the SOP; the cloned `CONCOMPRA.yml` lists `- seqkit==2.8.2`, so the conda env provides it.
- **Fix:** Add before the loop: "This step needs `seqkit`. It is in the CONCOMPRA conda env you built in Section 2 (`conda activate …/conda_envs/CONCOMPRA`); if you are in a fresh shell instead, `module load SeqKit/2.4.0`."

### F-05 · S3 · THREADS=16 runs 16 samples at once, not "one sample at a time" as stated
- **Where:** SOP_CONCOMPRA_NeSI.md:245-246, § 4 Threads
- **Anchor:** `(one sample at a time)`
- **Quote:**
  > For a 16-CPU allocation, `THREADS=4` gives 4 samples at a time with 4 threads each. This may run faster than `THREADS=16` (one sample at a time) on many-sample datasets; test it on a run before committing.
- **Defect:** In `main.sh`, `THREADS` is the *outer* concurrency width as well as the per-sample thread count. `THREADS=16` runs 16 samples concurrently, each requesting 16 threads (256-way oversubscription on 16 CPUs) — not "one sample at a time". The recommendation to prefer `THREADS=4` is right; the stated reason is inverted.
- **Failure:** A reader who reads "`THREADS=16` (one sample at a time)" as the safe/conservative setting picks 16, massively oversubscribes the node, and the 48h run crawls or times out.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED
- **Evidence:** `scripts/main.sh` outer loop `((i=i%THREADS)); ((i++==0)) && wait` launches `THREADS` samples before waiting; the inner `minimap2 -t $THREADS` and `consensus_generation.sh`'s `((j=j%THREADS))` both reuse `THREADS`. So `THREADS=N` = N samples × N threads.
- **Fix:** Replace the parenthetical with "(`THREADS=16` would instead run 16 samples at once, 16 threads each — heavy oversubscription on a 16-CPU node)".

### F-06 · S3 · 06_concompra.sh runs repo main.sh, ignoring the edited copy that keeps temporary/
- **Where:** SOP_CONCOMPRA_NeSI.md:264-302, § 5 Submitting the Run
- **Anchor:** `bash $CONCOMPRA_dir/scripts/main.sh`
- **Quote:**
  > cd /nesi/nobackup/<your_nesi_project_code>/<your_project>/concompra
  > bash $CONCOMPRA_dir/scripts/main.sh
- **Defect:** The prose (`:273`) tells the reader to copy `main.sh` into the run directory, comment out `rm -rf temporary`, and "have `06_concompra.sh` run your copy — `bash ./main.sh`". But the provided script runs the pristine repo copy, whose `rm -rf temporary` still fires. The reader's edit is silently ignored and `temporary/` is deleted anyway.
- **Failure:** Reader does the `sed`, `grep` confirms their local copy is commented out, they submit the script as written, the repo `main.sh` deletes `temporary/`, and when a sample later fails silently the per-sample diagnosis they went to trouble to preserve is gone.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED
- **Evidence:** Internal contradiction: `:273` "`bash ./main.sh`" vs `:299` `bash $CONCOMPRA_dir/scripts/main.sh`. The cloned `main.sh:124` is `rm -rf temporary` (last step).
- **Fix:** Change the last line of the script to `bash ./main.sh` (both `directory_list.txt` and the edited `main.sh` are in the `cd`-ed run directory).

### F-07 · S3 · otu_table.csv called "Sample by OTU" but rows are OTUs and columns are samples
- **Where:** SOP_CONCOMPRA_NeSI.md:356, § 6 Output files
- **Anchor:** `Sample by OTU count matrix`
- **Quote:**
  > | `otu_table.csv` | Sample by OTU count matrix |
- **Defect:** The orientation is reversed. CONCOMPRA writes one **row per OTU** and one **column per sample** (header `#OTU ID,<sample>.CONCOMPRA,…`). Every command in the SOP treats it that way (summing columns for per-sample totals, `NF-1` = sample count), so the label alone is wrong — but it mislabels the central data object.
- **Failure:** A reader who writes their own summary trusting "Sample by OTU" transposes the table and reads OTUs as samples.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED
- **Evidence:** Cloned `scripts/merfePAF.py`: `header = ["#OTU ID"]`, one appended column per `.paf` file (sample), and one printed row per `taxID` (OTU) — i.e. OTU × sample.
- **Fix:** Change the cell to "OTU × sample count matrix (rows = OTUs, columns = samples)".

### F-08 · S3 · Troubleshooting lists "relative paths in directory_list.txt", a non-existent cause
- **Where:** SOP_CONCOMPRA_NeSI.md:579, § 9 Empty consensus output
- **Anchor:** `too few reads per sample for clustering`
- **Quote:**
  > Other causes: wrong primer orientation ([Primer file](#primer-file)), which leaves almost no reads after primer-chop; relative paths in `directory_list.txt` ([Sample list](#sample-list)); or too few reads per sample for clustering.
- **Defect:** "Relative paths in `directory_list.txt`" is not a real cause — that file holds config variables, not paths (F-01). The genuine top causes of empty output are a mis-built `directory_list.txt` (unset `MIN`/`MAX`/`PRIMER_SET`/`TEMPLATE_DIR`) and primer headers not named `head`/`tail` (F-02); neither is listed. The `#sample-list` link also dangles once F-01 renames that heading.
- **Failure:** Reader with empty output reads this line, inspects their path list for "relative paths", finds none, and never checks the actual fault.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED
- **Evidence:** Same source as F-01/F-02; the SOP's own workflow never puts paths in `directory_list.txt`.
- **Fix:** Replace the "relative paths…" clause with: "a mis-configured `directory_list.txt` ([Run configuration file](#run-configuration-file)) — an unset `MIN`/`MAX` discards every read; primer headers not named `head`/`tail` ([Primer file](#primer-file)); or too few reads per sample for clustering."

### F-09 · S4 · Script filenames don't match their defining section numbers (README convention)
- **Where:** SOP_CONCOMPRA_NeSI.md:193-195, § 4 Directory layout
- **Anchor:** `06_concompra.sh               # main run submission (Section 5)`
- **Quote:**
  > ├── 05b_dedup.sh                  # if dedup was needed (Stage 2)
  > ├── 06_concompra.sh               # main run submission (Section 5)
  > ├── 07_concompra_postprocess.sh   # post-processing submission (Section 7)
- **Defect:** README convention: "Script filenames carry the number of the section that defines them … Numbers do not run across documents." Dedup is Section 3 but the script is `05b_dedup.sh`; the main run is Section 5 but the script is `06_concompra.sh` (the comment itself pairs "06" with "Section 5"). Only the postprocess script matches.
- **Failure:** A reader navigating by section number, or a maintainer, is momentarily misled; results are unaffected.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED
- **Evidence:** README.md:54 states the convention; SOP uses `05b`/`06` for Sections 3/5.
- **Fix:** Renumber to `03_dedup.sh` and `05_concompra.sh` (and their `Save as` references at `:264`, `:275`, `:308`), or state explicitly that numbering continues from `SOP_EMU_NeSI.md`.

### F-10 · S4 · Main-run SLURM script uses "#!/bin/bash -e" not the conventional set -euo pipefail
- **Where:** SOP_CONCOMPRA_NeSI.md:282, § 5 Submitting the Run
- **Anchor:** `#!/bin/bash -e`
- **Quote:**
  > #!/bin/bash -e
- **Defect:** README convention for SLURM headers is `#!/bin/bash` plus `set -euo pipefail`; the postprocess script (`:397,407`) follows it, this one uses only `-e`. Harmless here (the wrapper only loads modules and calls `main.sh` as a separate process), but inconsistent within the same document.
- **Failure:** None to results; a copy-pasting reader propagates the weaker wrapper to scripts where `-u`/`pipefail` would have caught an error.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED
- **Evidence:** README.md:55 convention; SOP:407 uses `set -euo pipefail` in the sibling script.
- **Fix:** Change to `#!/bin/bash` and add `set -euo pipefail` after the `#SBATCH` block.

## Verified against the cluster

- **Post-processing modules exist** at the exact strings: `VSEARCH/2.21.1-GCC-11.3.0`, `MAFFT/7.505-gimkl-2022a-with-extensions`, `FastTree/2.1.11-GCC-11.3.0`, `seqtk/1.4-GCC-11.3.0` — loaded them; all resolved (also per 00_ENVIRONMENT.md). HOLDS.
- **vsearch options** `--makeudb_usearch --sintax --sintax_cutoff --tabbedout --uchime_denovo --cluster_fast` — `vsearch --help | grep` under VSEARCH/2.21.1: all present. The Appendix A build and Section 7 commands use only valid flags. HOLDS.
- **SINTAX `--tabbedout` layout (Section 7 step 2 / Section 8 R).** Built a tiny SINTAX udb and queried it: classified rows are 4 tab fields — query, all-ranks-with-bootstrap, strand, cutoff-filtered assignment; unclassified rows carry a trailing empty field. Ran the SOP's exact R (`read.delim(header=FALSE,row.names=1,sep="\t")[,3]`) on a mixed classified/unclassified file, incl. the case where the unclassified row is last: `[,3]` yields the cutoff-filtered (column-4) assignment for classified OTUs and empty for unclassified. The SOP's "take column 4, not column 2" and its R indexing are correct and robust. HOLDS.
- **`read.csv` on the real header.** `read.csv(row.names=1, check.names=FALSE)` on `#OTU ID,s1.CONCOMPRA,…`: default `comment.char=""`, so the `#OTU ID` label is read normally, OTU ids become row names, `.CONCOMPRA` sample names preserved. Section 8's R opens the actual CONCOMPRA table correctly. HOLDS.
- **`seqtk subseq` with absent names.** Fed a names list with one present and one absent id: it prints only the present sequence and exits 0 (no error). This is why "Fewer sequences than OTU-table rows is expected" (`:452`) after Section 7 step 1 is correct — chimera-removed OTU ids in the table are silently skipped. HOLDS (and flags that an *id-format* mismatch would fail silently too — see NOT-VERIFIABLE).
- **CONCOMPRA source (cloned `willem-stock/CONCOMPRA`, commit `7a957d1`).** `main.sh` has no `set -e`; ends with `rm -rf temporary` (`:124`); globs `*.fastq` for input; `source`s `directory_list.txt`. `consensus_generation.sh:65` echoes `"consensus sequences generated for $CLEAN_NAME"` unconditionally after the consensus loop — so the roadmap's "logs it even when a step failed silently" warning (`:45,316`) is accurate. `filtlong --keep_percent 80` confirmed (`consensus_generation.sh:35`), matching "keeps the top 80% by quality" and the 80000→~29000 arithmetic (`:262`). CONFIRMED.
- **`CONCOMPRA.yml` pins.** `minimap2==2.1.1`, `python==3.11`, `numba==0.60.0`, `filtlong==0.2.1`, `lamassemble==1.7.2` present; no `medaka`/`racon`/`samtools`. Matches the SOP's verify list (`:110`) and the "their absence is correct" note (`:585-587`). The yml also carries `seqkit==2.8.2` (relevant to F-04). CONFIRMED.
- **Module names.** `module spider` shows `SeqKit/*` (capital S, for F-04) and `seqtk/1.4-GCC-11.3.0`. VERIFIED.

## Keep list

- **Roadmap line 45** ("`main.sh` logs 'consensus sequences generated' … Verify … on disk, never from the `.out` log"): the document's headline silent-failure warning, and I confirmed it against the source. Anchor `never from the`.
- **Section 6 framing** "`main.sh` has no `set -e` … Do not trust the `.out` log; check the outputs on disk." Load-bearing; keep whole. Anchor `does not stop the script or change its exit code`.
- **SINTAX column-4-not-2 warning** (`:454` and the R comment `:538`): using column 2 silently corrupts genus/species. Verified correct. Anchor `silently corrupts taxonomy at low-confidence ranks`.
- **1492R sense-strand orientation** paragraph (`:233`): correct and carried into the F-02 rewrite. Anchor `not the reverse-complement`.
- **`.CONCOMPRA` / `_filtered` suffix rationale** (`:507-511`, `:521`): why the same sample must not be `barcode01_filtered` here and `barcode01` in Emu. Load-bearing sample-ID reasoning. Anchor `the same physical sample is called barcode01_filtered`.
- **Prevalence-filter caveat** for ANCOM-BC2 (`:567`): per-sample consensus OTUs are often genuine rare taxa, so `prv_cut = 0.10` may discard signal — a why-this-number note. Anchor `may discard real signal`.
- **filtlong / minimap2 pins** ("do not downgrade", `:577`,`:604`): version-lock reasoning. Anchor `its version is pinned for compatibility`.

## Gaps

- **CONCOMPRA run parameters (`MIN`, `MAX`, `MERGE_CONSENSUS`, `READS_CONSENSUS`).** The SOP never mentions the length window or clustering parameters, yet `MIN`/`MAX` silently gate every read. `SHOULD-ADD` — folded into the F-01 rewrite (the config table already covers `MIN`/`MAX`; ~2 more table rows would cover the clustering knobs).
- **filtlong duplicate-name abort is asserted but not shown.** The dedup screen (Section 3) rests on "`filtlong 0.2.1` aborts on duplicate read names". `CONSIDER` a one-line reproduction; ~3 lines. (Not verifiable here without building the conda env — see below.)
- **Where `filtered/` comes from / its filenames.** Section 3 assumes a `filtered/` directory of `<sample>_filtered.fastq` in the cwd, but never says which directory the reader should be in or restates the Emu naming. `CONSIDER` one sentence.
- **`reformat_silva_for_sintax.py` is described but never provided.** Appendix A invokes it (`:647`) and its output feeds all of post-processing, but unlike Section 8's `assemble_R_inputs.py` (which has an inline self-contained equivalent) no source, link, or code is given. The first reader to build the SILVA SINTAX database in a project cannot, unless a labmate already placed the script. `SHOULD-ADD` — either link the lab script or inline it (~30 lines, matching the Section 8 pattern).

## Cross-document flags

- Input `filtered/` directory and the `_filtered` filename suffix are produced by `SOP_EMU_NeSI.md`; the suffix-strip logic (`:508-511`, `:521`) assumes Emu names files `<sample>_filtered.fastq`. Verify against the Emu SOP.
- Section 8 asserts several `SOP_R_Analysis.md` internals: "substitute `counts_concompra.tsv` for `emu-combined-counts_silva.tsv`" (`:562`), rank names `superkingdom…` and `tax_level = "genus"` (`:562`), the `round()` step (`:566`), and `prv_cut = 0.10` in "Part 2's ANCOM-BC2 call" (`:567`). None checkable from this file.
- README tool-versions row for CONCOMPRA lists `seqtk` (module) but nothing records the Section 3 `seqkit` dependency (F-04). README.md:54 (script-numbering, F-09) and README.md:55 (SLURM header convention, F-10).
- The SOP deliberately deviates from the `--chdir`+relative-logs convention (README.md:55) by hardcoding `cd` in the SLURM scripts, with a stated reason (`:302`). Reasoned choice, flagged not filed.

## Rewrite plan

1. **F-01 — rewrite "Sample list" → "Run configuration file"** (§4.3). Closes F-01; absorbs the `MIN`/`MAX` gap. Independent; medium. Do first — F-08's link target depends on the new heading.
2. **F-02 — rewrite "Primer file"** (§4.4): head/tail header names + write-to-`primer_set.fa` step, keeping the orientation prose. Closes F-02. Independent; small.
3. **F-03 — fix the "submitted" count** (§6.1) to `ls *.fastq | wc -l`. Closes F-03. Independent; tiny.
4. **F-06 — point the run script at `./main.sh`** (§5). Closes F-06. Independent; tiny.
5. **F-04 — add the `seqkit` availability note** to Deduplicate (§3.2). Closes F-04. Independent; tiny.
6. **F-08 — correct the Section 9 causes** and relink to the renamed §4.3. Closes F-08. Do after step 1; small.
7. **F-05, F-07, F-09, F-10 — polish** (Threads wording, OTU×sample label, script numbering, SLURM shebang). Independent; tiny each.

---

### Self-check output

```
findings=10 S1=2 S2=1 S3=5 S4=2
CLEAN
```

Hand-confirmed:
- [x] Ledger accounts for every heading in the file (all `#`/`##`/`###` headings listed; roadmap grouped with the title block).
- [x] No proposed cut touches load-bearing content — the two REWRITEs preserve the orientation "why" and add configuration content; nothing on the Keep list is removed.
- [x] Every `NOT-VERIFIABLE-HERE` is genuinely not verifiable here — filtlong dup-abort needs a built conda env; full OTU-id↔header matching and the SILVA-bundle build need a real run / the OSF download.

CONTRACT: PASS
