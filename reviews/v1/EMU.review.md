## Document: SOP_EMU_NeSI.md

This is trying to be the one document that takes a student who has never opened a
terminal from a NeSI login prompt to a combined count table, and its explanatory
half — 16S biology, Nanopore chemistry, Phred scores, EM, why these filter
thresholds, why two databases — is genuinely good and mostly ready to ship. The
executable half is not. The workspace path the pipeline actually uses
(`/nesi/nobackup/<code>/`) is not the workspace path the document defines
(`/nesi/nobackup/<code>/<your_project>/`), the raw-data import loop breaks on the
file layout MinKNOW actually produces, the read-count check uses a method the
document's own ASCII table proves wrong, the QC report is pooled across barcodes
while every interpretation rule is per-barcode, and the combiner script silently
discards a sample when two subdirectories share a basename — a layout its own
docstring advertises. The single change that would most improve it: **fix and
then hold one workspace path for the whole document**, put every SLURM script
under `--chdir` on that path, and add an "expected output / check this" line
after each of the seven commands that can currently fail without saying so.

## Section ledger

| § | Heading | Lines | Verdict | Findings |
|---|---|---|---|---|
| — | `# Part 1: NeSI Pipeline (Sequencing to Count Tables)` | 1-4 | REWRITE | F-20, F-29 |
| — | `# Taylor Lab Bioinformatic SOP: Full-Length 16S rRNA…` | 5-18 | MERGE | F-29, F-36 |
| — | Analysis steps | 19-28 | TIGHTEN | F-20 |
| 1 | Getting Started on NeSI | 29-32 | CLEAN | — |
| 1 | What is NeSI and why we use it | 33-36 | CLEAN | — |
| 1 | Logging in | 37-64 | REWRITE | F-01 |
| 1 | Basic bash commands | 65-122 | TIGHTEN | F-30 |
| 1 | Using modules | 123-136 | CLEAN | — |
| 1 | SLURM: running jobs on the cluster | 137-180 | TIGHTEN | F-24, F-30, F-32 |
| 1 | A note on array jobs | 181-184 | CLEAN | — |
| 1 | Further reading | 185-195 | CLEAN | — |
| 2 | Understanding Your Data | 196-199 | CLEAN | — |
| 2 | What is 16S rRNA and why do we sequence it? | 200-211 | CLEAN | — |
| 2 | What is an amplicon? | 212-221 | CLEAN | — |
| 2 | How does Nanopore sequencing work? | 222-231 | TIGHTEN | F-19 |
| 2 | What are quality scores? | 232-242 | TIGHTEN | F-19 |
| 2 | What does a FASTQ file look like? | 243-257 | CLEAN | — |
| 2 | What does Nanopore data look like on disk? | 258-274 | EXPAND | F-02 |
| 2 | Full-length vs short-read: why it matters | 275-288 | CLEAN | — |
| 3 | Processing Nanopore Reads | 289-292 | CLEAN | — |
| 3 | Step 1. Organise your raw data | 293-310 | REWRITE | F-01, F-02, F-05, F-17, F-22 |
| 3 | Step 2. Quality assessment of raw reads | 311-384 | REWRITE | F-06, F-07, F-19, F-23 |
| 3 | Step 3. Filtering with chopper | 385-445 | REWRITE | F-03, F-06, F-18 |
| 3 | Step 4. Quality assessment of filtered reads | 446-504 | TIGHTEN | F-07, F-18 |
| 3 | Interpreting NanoPlot output | 505-524 | RESTRUCTURE | F-28 |
| 4 | Taxonomy and Community Profiling with Emu | 525-528 | CLEAN | — |
| 4 | What Emu does and why we use it | 529-550 | CLEAN | — |
| 4 | Understanding the reference databases | 551-575 | CLEAN | — |
| 4 | Setting up the databases | 576-619 | EXPAND | F-01, F-08, F-09, F-25 |
| 4 | Running Emu | 620-725 | REWRITE | F-07, F-10, F-11, F-12, F-16, F-25, F-27, F-31, F-33 |
| 4 | Combining Emu outputs | 726-729 | CLEAN | — |
| 4 | Option A: `emu combine-outputs` | 730-765 | RESTRUCTURE | F-26, F-33 |
| 4 | Option B: Custom combiner script | 766-927 | REWRITE | F-04, F-13, F-14, F-15, F-26 |

## Findings

### F-01 · S1 · Pipeline runs in the shared allocation root, not `<your_project>`
- **Where:** SOP_EMU_NeSI.md:51-55, 298-299, 583-584, § 1 Logging in / § 3 Step 1 / § 4 Setting up the databases
- **Quote:**
  > Because you will be working out of `/nesi/nobackup/<your_nesi_project_code>/<your_project>/` constantly, typing the full path gets old fast.
  >
  > ln -s /nesi/nobackup/<your_nesi_project_code>/<your_project> ~/proj

  and, 247 lines later:

  > cd /nesi/nobackup/<your_nesi_project_code>/
  > mkdir -p raw_files filtered qc_raw qc_filtered emu_results logs

  and, 285 lines after that:

  > mkdir -p /nesi/nobackup/<your_nesi_project_code>/<your_project>/emu_databases
- **Defect:** The document defines the workspace as `<code>/<your_project>/`, creates the
  databases there, and points the `~/proj` symlink there — but every working directory in the
  actual pipeline (lines 298, 327, 409, 462, 627, 648, 900, 906) is one level up, in
  `/nesi/nobackup/<your_nesi_project_code>/`, which is the allocation root shared by everyone
  on the project code.
- **Failure:** The reader creates `raw_files/`, `filtered/`, `emu_results/` and `emu_manifest.txt`
  directly in the shared allocation root. `cd ~/proj` then shows an empty directory, so they cannot
  find their own work. When they run a second sequencing run — or a labmate on the same project
  code runs the SOP — `raw_files/` and `filtered/` are overwritten and `ls filtered/*_filtered.fastq
  > emu_manifest.txt` silently enumerates both runs' samples. Emu processes them all, the combiner
  emits one table with both studies' columns, and nothing anywhere errors.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — the two path forms are both in this file and are not the same directory.
- **Fix:** Replace lines 297-300 with:

  ````markdown
  Everything in this SOP runs out of one workspace directory. Create it and move in:

  ```bash
  mkdir -p /nesi/nobackup/<your_nesi_project_code>/<your_project>
  cd /nesi/nobackup/<your_nesi_project_code>/<your_project>
  mkdir -p raw_files filtered qc_raw qc_filtered emu_results emu_databases logs
  ```

  Work inside `<your_project>`, never in `/nesi/nobackup/<your_nesi_project_code>/` itself.
  That level is shared by everyone on your allocation. If two people — or two of your own
  sequencing runs — write `raw_files/` and `filtered/` there, the second overwrites the first
  and the manifest you build in Section 4 will list both sets of samples without complaint.
  This is the directory `~/proj` points at, so from here on `cd ~/proj` gets you back.
  ````

  Then replace `cd /nesi/nobackup/<your_nesi_project_code>/` with
  `cd /nesi/nobackup/<your_nesi_project_code>/<your_project>/` at lines 327, 409, 462, 627 and
  648, and the same substitution in the two `combine_emu_results.py` invocations at lines 900
  and 906. Delete line 583's separate `mkdir -p …/emu_databases` (it is now created above) and
  leave line 584's `cd` pointing at `…/<your_project>/emu_databases`.

### F-02 · S1 · Raw-data copy loop fails on multi-file and gzipped barcode directories
- **Where:** SOP_EMU_NeSI.md:304-309, § 3 Step 1
- **Quote:**
  > for dir in sequencing_run/barcode*/; do
  >     BARCODE=$(basename ${dir})
  >     cp ${dir}*.fastq raw_files/${BARCODE}.fastq
  > done
- **Defect:** `cp` requires the final argument to be a directory whenever there is more than one
  source file, so this line fails for any barcode directory holding more than one FASTQ chunk;
  and the glob matches only `.fastq`, so it matches nothing at all when MinKNOW has written
  `.fastq.gz`. There is no `set -e`, no error check, and no "expected output" statement.
- **Failure:** The reader's run has chunked output (`…_barcode01_0.fastq`, `…_1.fastq`). For every
  such barcode `cp` prints `cp: target 'raw_files/barcode01.fastq' is not a directory` and creates
  nothing. The errors scroll past in a wall of output; the reader moves on. NanoPlot, chopper, the
  manifest and the array job all run happily on whichever barcodes happened to be single-file, and
  the final count table is simply missing samples — with no message at any stage saying so.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — `cp a b dest` where `dest` is a filename is an error in every POSIX
  `cp`; the document's own directory sketch at lines 264-271 shows the single-file case only.
- **Fix:** Replace lines 302-309 with:

  ````markdown
  If your FASTQ files are in per-barcode subdirectories from the sequencer, concatenate each
  barcode's files into one FASTQ in `raw_files`. MinKNOW usually writes several chunks per
  barcode and often gzips them, so this is a concatenation, not a copy — `cp` cannot do it
  (given more than one source file it demands a directory as the destination and fails):

  ```bash
  shopt -s nullglob
  for dir in sequencing_run/barcode*/; do
      BARCODE=$(basename "${dir}")
      files=( "${dir}"*.fastq "${dir}"*.fastq.gz )
      if [ ${#files[@]} -eq 0 ]; then
          echo "WARNING: no FASTQ files in ${dir} — skipping"
          continue
      fi
      zcat -f "${files[@]}" > "raw_files/${BARCODE}.fastq"
      echo "${BARCODE}: $(( $(wc -l < raw_files/${BARCODE}.fastq) / 4 )) reads from ${#files[@]} file(s)"
  done
  shopt -u nullglob
  ```

  `zcat -f` reads gzipped and plain files alike, so you do not need to know which you have.

  **Check before continuing.** The loop prints one line per barcode with a read count. Compare
  that list against your barcode sheet: a barcode that printed a WARNING, or that is missing
  from the list entirely, will be absent from every downstream table, and nothing later in this
  pipeline will tell you it is gone.

  ```bash
  ls -lh raw_files/
  ```
  ````

### F-03 · S1 · Read counts computed with `grep -c "^@"`, which the document's own ASCII table shows is wrong
- **Where:** SOP_EMU_NeSI.md:433-436, § 3 Step 3
- **Quote:**
  >     # Quick stats
  >     raw_count=$(grep -c "^@" ${fastq} || echo 0)
  >     filt_count=$(grep -c "^@" filtered/${sample}_filtered.fastq || echo 0)
- **Defect:** In a FASTQ file the quality line is arbitrary ASCII, and `@` is a legal quality
  character. Section 2 of this document states it: "Q30 = `?`" (line 256) — `?` is ASCII 63, so
  `@` is ASCII 64, i.e. Q31. Any read whose first base scores exactly Q31 contributes a second
  match, so `grep -c "^@"` overcounts, and it overcounts by a different amount before and after
  filtering. (Separately, `grep -c` prints `0` *and* exits 1 when there are no matches, so the
  `|| echo 0` fallback yields the string `0 0`, not `0`.)
- **Failure:** With SUP-basecalled data — the document's own example has 14.6% of reads above
  mean Q30 — a meaningful fraction of quality lines start with `@`. The reader sees, say,
  `barcode07: 41230 raw -> 39980 filtered`, computes 97% retention, and concludes filtering barely
  removed anything, or sees an inflated raw count and computes 55% retention and thinks the sample
  failed. They then apply the rule at line 444 ("If a barcode retains less than ~30%, something may
  be wrong") to a number that was never right. No error is printed at any point.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — follows directly from the Phred+33 mapping stated at line 256 of
  this same document.
- **Fix:** Replace lines 433-436 with:

  ```bash
      # Quick stats. Count records as lines/4, not with grep. A FASTQ quality
      # line is arbitrary ASCII and "@" is Q31 (see the Phred table in Section 2),
      # so `grep -c "^@"` also counts quality lines and silently inflates the count.
      raw_count=$(( $(wc -l < "${fastq}") / 4 ))
      filt_count=$(( $(wc -l < "filtered/${sample}_filtered.fastq") / 4 ))
      pct=$(awk -v r="${raw_count}" -v f="${filt_count}" \
            'BEGIN{ if (r>0) printf "%.1f", 100*f/r; else print "NA" }')
      echo "  ${sample}: ${raw_count} raw -> ${filt_count} filtered (${pct}% retained)"
  ```

### F-04 · S1 · Combiner silently discards a sample when two subdirectories share a basename
- **Where:** SOP_EMU_NeSI.md:787-788 and 821-823, § 4 Option B
- **Quote:**
  > Each database directory can hold per-sample files directly or in
  > subdirectories (e.g., plate1/, plate2/); the script searches recursively.

  and

  >         sample_name = os.path.basename(fpath).replace("_rel-abundance.tsv", "")
  >         sample_names.append(sample_name)
- **Defect:** `sample_name` is derived from the basename only, and `sample_names` is a plain list
  with no uniqueness check. Two files with the same basename in different subdirectories — exactly
  the layout the docstring advertises — produce the same key. The second file read overwrites the
  first in `taxa[tax_id]["abundances"]` / `["counts"]`, and because the duplicate name appears
  twice in `sample_names`, the surviving value is then written into two identically named columns.
- **Failure:** The reader has `emu_results/silva/plate1/barcode01_rel-abundance.tsv` and
  `emu_results/silva/plate2/barcode01_rel-abundance.tsv`. The script prints
  `Found 48 sample files` and `… across 48 samples`, and writes a table with 48 columns —
  everything looks correct. In fact plate1's barcode01 counts have been thrown away and plate2's
  are duplicated into both `barcode01` columns. In R, `phyloseq` accepts the table, the two samples
  are perfectly correlated, and the reader reports a plate effect of zero and a diversity estimate
  for a sample that was never measured.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — provable from the code and the docstring in this file.
- **Fix:** Replace lines 821-823 with:

  ```python
      for fpath in abundance_files:
          sample_name = os.path.basename(fpath).replace("_rel-abundance.tsv", "")
          if sample_name in sample_names:
              sys.exit(
                  f"ERROR: two files under {db_path} both give the sample name "
                  f"'{sample_name}'. Rename one so every sample name is unique, then "
                  f"re-run. Continuing would silently discard one file's counts and "
                  f"write the other's into two identically named columns."
              )
          sample_names.append(sample_name)
  ```

  and add to the note at line 770: "Sample names come from the filename, so every per-sample file
  under a database directory must have a unique basename even if they sit in different
  subdirectories. The script stops with an error if two collide."

### F-05 · S2 · No instructions for getting sequencing data onto NeSI
- **Where:** SOP_EMU_NeSI.md:295, § 3 Step 1
- **Quote:**
  > When downloading from BaseSpace or Globus, put your data exactly where you want it in a named directory.
- **Defect:** This is the first hands-on step of the pipeline and it assumes the FASTQ files are
  already on the cluster, in a directory called `sequencing_run/`, without ever saying how they got
  there. The stated audience has never opened a terminal, so "put your data exactly where you want
  it" is not an instruction they can act on.
- **Failure:** The reader has a MinKNOW output folder on a laptop or an external drive and no idea
  how to move ~30 GB of it to NeSI. They stall at the first command of the pipeline, and the
  document offers nothing — no `scp`, no `rsync`, no Globus endpoint, no mention that the Jupyter
  file-browser upload is impractical at this size.
- **Type:** GAP
- **Confidence:** CONFIRMED — no transfer method appears anywhere in the file (searched for scp,
  rsync, transfer, upload, Globus).
- **Fix:** Insert before line 295:

  ````markdown
  **Getting the data onto NeSI.** Nanopore data arrives as a MinKNOW output folder, usually on a
  sequencing-facility server or an external drive, not in a cloud service. Two ways to move it:

  - **From your own machine**, over the terminal. From a terminal *on your laptop* (not on NeSI):

    ```bash
    rsync -avh --progress /path/to/sequencing_run/ \
        <username>@login.mahuika.nesi.org.nz:/nesi/nobackup/<your_nesi_project_code>/<your_project>/sequencing_run/
    ```

    `rsync` resumes where it left off if the connection drops, which `scp` does not — with tens of
    gigabytes over a campus connection, that matters. Run it from the machine holding the data.

  - **From a facility that offers Globus**, use the NeSI Globus endpoint; NeSI's own documentation
    covers this and it is the better option above ~100 GB.

  Do not use the Jupyter file-browser upload for a whole run. It is fine for a script or a
  metadata sheet, not for FASTQ.

  Once the data is on NeSI, put it exactly where you want it in a named directory. Navigate to
  your project directory and set up your workspace:
  ````

### F-06 · S2 · NanoPlot report is pooled across all barcodes, but every interpretation rule is per-barcode
- **Where:** SOP_EMU_NeSI.md:332-339, 348 and 444, § 3 Steps 2-3
- **Quote:**
  > NanoPlot \
  >     --fastq raw_files/*.fastq \
  >     --outdir qc_raw \

  and

  > - **Total yield and read count.** For 16S you generally want at least 10,000-50,000 reads per barcode.

  and

  > If a barcode retains less than ~30%, something may be wrong with that sample; check its NanoPlot output.
- **Defect:** The glob passes every sample to one NanoPlot invocation writing one report, so the
  output is a single pooled summary across the whole run. There is no per-barcode NanoPlot output
  to check, and the report's read count is the run total, not a per-sample count. The worked
  example makes this concrete and uncommented: 21,019,028 reads (line 359) is a whole-run figure
  sitting directly beneath advice framed "per barcode".
- **Failure:** A reader whose barcode07 retained 25% follows line 444, goes looking for
  "its NanoPlot output", and finds only `qc_raw/` — one report covering all 24 samples. They cannot
  do the check the document just told them to do. Worse, a reader who compares the pooled read
  count (21M) against "at least 10,000-50,000 reads per barcode" concludes every sample is fine,
  when a barcode with 400 reads is invisible inside that total.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — one `--outdir`, one `--prefix`, one report; the per-barcode advice
  has no artefact to read.
- **Fix:** Insert after line 342:

  ````markdown
  **The report is pooled.** One NanoPlot run over all barcodes gives you one report describing the
  whole run. That is what you want for judging the run, but it cannot tell you that one barcode
  underperformed. Get per-barcode counts separately:

  ```bash
  for f in raw_files/*.fastq; do
      printf "%s\t%s\n" "$(basename "$f" .fastq)" "$(( $(wc -l < "$f") / 4 ))"
  done | tee qc_raw/raw_read_counts.tsv
  ```
  ````

  Replace the "Total yield and read count" bullet (line 348) with:

  > - **Total yield.** This is the run total across every barcode, not a per-sample figure — use
  >   `qc_raw/raw_read_counts.tsv` for that. Per barcode you generally want at least 10,000-50,000
  >   reads for 16S. More helps detect rare taxa, with diminishing returns above ~50,000 reads for
  >   most communities. A barcode far below 10,000 will give unstable diversity estimates and is a
  >   candidate for exclusion.

  Replace line 444 with:

  > You should typically retain 60-80% of reads. The per-sample line printed by the loop above tells
  > you which barcodes fell outside that. If a barcode retains less than ~30%, check its row in
  > `qc_raw/raw_read_counts.tsv` and re-read its raw length distribution — the NanoPlot reports are
  > pooled across all barcodes, so there is no per-sample report to open.

### F-07 · S2 · SLURM `--output logs/…` is relative to the submission directory the document never specifies
- **Where:** SOP_EMU_NeSI.md:324-327, § 3 Step 2 (and identically at 406-409, 459-462, 645-648)
- **Quote:**
  > #SBATCH --output logs/nanoplot_raw_%j.out
  > #SBATCH --error logs/nanoplot_raw_%j.err
  >
  > cd /nesi/nobackup/<your_nesi_project_code>/
- **Defect:** SLURM resolves relative `--output`/`--error` paths against the job's working
  directory, which is the directory `sbatch` was run from — the in-script `cd` happens far too
  late to affect it. The document never says where to save or submit the scripts from, and its own
  storage advice at line 46 says "Use for SLURM scripts" of `/nesi/project/…`, where no `logs/`
  directory is ever created.
- **Failure:** The reader follows line 46, saves `01_nanoplot_raw.sh` under
  `/nesi/project/<code>/`, and runs `sbatch 01_nanoplot_raw.sh` there. SLURM cannot create
  `logs/nanoplot_raw_1234567.out`, the job fails at launch, and there is no log file to explain
  why — the one artefact that would have told them is the thing that could not be written.
  `squeue` shows nothing; the reader assumes the job is queued and waits.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — the in-script `cd` cannot affect a path SLURM resolves before the
  script runs; the document's own line 46 sends scripts to a different filesystem.
- **Fix:** In all four SLURM scripts, add `--chdir` immediately above the `--output` line and
  delete the in-script `cd`. For `01_nanoplot_raw.sh` (lines 318-327) this gives:

  ```bash
  #!/bin/bash -e
  #SBATCH --account <your_nesi_project_code>
  #SBATCH --job-name nanoplot_raw
  #SBATCH --time 00:30:00
  #SBATCH --mem 8G
  #SBATCH --cpus-per-task 8
  #SBATCH --chdir /nesi/nobackup/<your_nesi_project_code>/<your_project>
  #SBATCH --output logs/nanoplot_raw_%j.out
  #SBATCH --error logs/nanoplot_raw_%j.err

  module purge
  module load NanoPlot/1.43.0-foss-2023a-Python-3.11.6
  ```

  and add this paragraph once, immediately after the first script (before line 342):

  > **Why `--chdir`.** SLURM resolves `--output` and `--error` before your script runs, relative to
  > wherever you typed `sbatch`. If `logs/` does not exist there, the job dies at launch and cannot
  > write a log saying so — you get a job ID and then silence. `--chdir` sets the working directory
  > for the whole job, so the log paths and every relative path inside the script resolve against
  > your workspace no matter where you keep the scripts. Keep the scripts on `/nesi/project/` as
  > Section 1 recommends; `--chdir` is what makes that safe.

### F-08 · S2 · `pip install osfclient` given with no `--user`, no PATH step and no success check
- **Where:** SOP_EMU_NeSI.md:582-588, § 4 Setting up the databases
- **Quote:**
  > module purge
  > module load Emu/3.6.2
  > pip install osfclient
- **Defect:** A bare `pip install` inside a loaded module environment tries to write into a
  read-only shared installation. The usual outcome on NeSI is either a permission error or a
  fallback user install whose `~/.local/bin` is not on `PATH`. Either way the next command,
  `osf -p 56uf7 fetch …`, is the first thing that fails, and the document states no expected
  output for the install step.
- **Failure:** The reader runs the block, sees a wall of pip output ending in an error or a
  warning they cannot parse, moves to Step 2, and gets `osf: command not found`. Nothing in the
  document connects that message back to the install, and `pip install osfclient` "succeeding"
  in a user directory that is not on `PATH` produces exactly the same symptom as failing outright.
- **Type:** CORRECTNESS
- **Confidence:** NEEDS-BENCH-CHECK — run `module purge && module load Emu/3.6.2 && pip install
  osfclient && which osf` on Mahuika and record whether the install succeeds and whether `osf`
  resolves without a PATH edit.
- **Fix:** Replace lines 582-588 with:

  ````markdown
  ```bash
  cd /nesi/nobackup/<your_nesi_project_code>/<your_project>/emu_databases
  module purge
  module load Emu/3.6.2
  pip install --user osfclient
  export PATH="${HOME}/.local/bin:${PATH}"

  # Check: this must print a path ending in /.local/bin/osf before you continue.
  which osf
  ```

  `--user` installs into your home directory; without it pip tries to write into the shared,
  read-only module installation. `~/.local/bin` is not on your `PATH` by default, which is why
  the `export` line is there — skip it and the next step fails with `osf: command not found`
  even though the install worked. Add that `export` line to `~/.bashrc` if you want it to
  persist across logins.
  ````

### F-09 · S2 · No check that the database extracted where `DB_PATH` points
- **Where:** SOP_EMU_NeSI.md:596-599 and 707, § 4 Setting up the databases / Running Emu
- **Quote:**
  > cd ${EMU_DATABASE_DIR}
  > osf -p 56uf7 fetch osfstorage/emu-prebuilt/${EMU_PREBUILT_DB}.tar
  > tar -xvf ${EMU_PREBUILT_DB}.tar
  > rm -f ${EMU_PREBUILT_DB}.tar

  and, 108 lines later:

  > - `--db` — path to the database directory (contains `species_taxid.fasta` and `taxonomy.tsv`).
- **Defect:** The document states what the database directory must contain but never tells the
  reader to verify it, and `rm -f` deletes the tar before anything confirms the extraction landed
  at the right level. If the archive contains a top-level folder, the files end up one directory
  deeper than `DB_PATH`.
- **Failure:** The reader completes the setup with no visible problem, writes `emu_array.sh`,
  submits a 24-task array, and every task fails with a database-not-found error. They now have
  24 `.err` files, a deleted tar, and a several-GB re-download to work out whether the path or the
  archive was wrong — none of which the document anticipates.
- **Type:** GAP
- **Confidence:** NEEDS-BENCH-CHECK — run `tar -tf silva.tar | head -3` and see whether the entries
  are bare filenames or sit under a directory prefix.
- **Fix:** Insert after line 599 (and identically after line 611, changing `silva` to `rdp` in the
  prose):

  ````markdown
  **Check before continuing.** Both of these files must exist at the top level of
  `${EMU_DATABASE_DIR}`; that directory is what you will pass to `--db`:

  ```bash
  ls -lh ${EMU_DATABASE_DIR}/species_taxid.fasta ${EMU_DATABASE_DIR}/taxonomy.tsv
  ```

  If that errors but `ls ${EMU_DATABASE_DIR}` shows a single subdirectory, the archive extracted
  one level deeper than expected. Either move the contents up
  (`mv ${EMU_DATABASE_DIR}/*/* ${EMU_DATABASE_DIR}/`) or set `DB_PATH` to that subdirectory. Do
  this now: the next time you find out is when all 24 array tasks fail at once.
  ````

### F-10 · S2 · RDP instructions list two edits; the script needs three
- **Where:** SOP_EMU_NeSI.md:669 and 692, § 4 Running Emu
- **Quote:**
  > mkdir -p emu_results/silva

  and

  > **For the RDP run**, copy the script to `emu_array_rdp.sh`, point `DB_PATH` at `emu_databases/rdp`, and change `--output-dir` to `./emu_results/rdp`:
- **Defect:** `emu_array.sh` contains a hard-coded `mkdir -p emu_results/silva` at line 669 that
  the RDP instruction does not mention. The copied script therefore creates the SILVA output
  directory and writes RDP results to a directory that may not exist.
- **Failure:** The reader copies the script, edits the two lines they were told to edit, and
  submits. Every RDP task either fails on a missing output directory or — worse, if Emu creates it
  — succeeds while the script also keeps re-creating `emu_results/silva`, leaving the reader
  unsure which directory holds what. The job name in the `squeue` listing is still `emu_array`,
  so they cannot tell the two arrays apart either.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED — line 669 is inside the script being copied and is not in the list of
  changes at line 692.
- **Fix:** Replace lines 692-698 with:

  ````markdown
  **For the RDP run**, copy the script and change four lines:

  ```bash
  cp emu_array.sh emu_array_rdp.sh
  ```

  | Line in `emu_array_rdp.sh` | Change to |
  | --- | --- |
  | `#SBATCH --job-name emu_array` | `#SBATCH --job-name emu_array_rdp` |
  | `DB_PATH=…/emu_databases/silva` | `DB_PATH=/nesi/nobackup/<your_nesi_project_code>/<your_project>/emu_databases/rdp` |
  | `mkdir -p emu_results/silva` | `mkdir -p emu_results/rdp` |
  | `--output-dir ./emu_results/silva` | `--output-dir ./emu_results/rdp` |

  Missing the `mkdir` line is the easy one to miss — it is not next to the other two. Then submit
  separately:

  ```bash
  sbatch --array=0-$(( $(wc -l < emu_manifest.txt) - 1 )) emu_array_rdp.sh
  ```
  ````

### F-11 · S2 · Array range is hard-coded, with no check that every sample produced output
- **Where:** SOP_EMU_NeSI.md:644 and 686-687, § 4 Running Emu
- **Quote:**
  > #SBATCH --array=0-23                  # CHANGE to match your sample count (0 to N-1)

  and

  > mkdir -p logs
  > sbatch emu_array.sh
- **Defect:** The sample count is duplicated between `emu_manifest.txt` and the SBATCH header, with
  nothing but a comment keeping them in step, and there is no post-run check that the number of
  output files matches the number of manifest lines. The in-script guard at lines 660-663 catches
  only the case of *too many* tasks; too few produces no diagnostic at all.
- **Failure:** The reader has 30 samples and forgets to edit line 644. Tasks 0-23 run and succeed;
  samples 25-30 are never processed. `squeue` empties, every `.err` file is clean, the combiner
  finds 24 files and reports "24 samples", and the reader carries a count table missing six samples
  into R. The only signal is a number they were never told to compare against anything.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — the array bound and the manifest length are independent values in
  this file with no reconciliation step.
- **Fix:** Change line 644 to:

  ```bash
  #SBATCH --array=0-0                   # placeholder — always set the real range on the command line
  ```

  and replace lines 683-690 with:

  ````markdown
  **Step 3: Submit, deriving the array range from the manifest.** Do not retype the sample count —
  read it off the manifest, so the two can never drift apart. Options given to `sbatch` override
  the ones in the script header:

  ```bash
  mkdir -p logs
  sbatch --array=0-$(( $(wc -l < emu_manifest.txt) - 1 )) emu_array.sh
  ```

  Monitor with `squeue -u $USER`. Each task writes its own log in `logs/`, so if a sample fails you
  can check its `.err` file directly.

  **Check when the array finishes.** These two numbers must be equal. If there are fewer outputs
  than manifest lines, some tasks failed or never ran — and nothing downstream will warn you,
  because a missing sample simply becomes a missing column:

  ```bash
  echo "manifest: $(wc -l < emu_manifest.txt)"
  echo "outputs:  $(ls emu_results/silva/*_rel-abundance.tsv 2>/dev/null | wc -l)"
  ```
  ````

### F-12 · S2 · Per-sample output columns stated as fixed in one place and variable in another
- **Where:** SOP_EMU_NeSI.md:722 and 768-770, § 4 Running Emu / Option B
- **Quote:**
  > **What Emu outputs.** For each sample, a file called `<sample>_rel-abundance.tsv`. Each row is a detected taxon with columns: tax_id (NCBI taxonomy ID), species, genus, family, order, class, phylum, superkingdom, abundance (relative, 0-1), and (with `--keep-counts`) estimated counts.

  and, 46 lines later:

  > **Note:** Whether a given SILVA build ships split-rank columns or a single lineage string depends on the exact prebuilt archive.
- **Defect:** Line 722 describes the per-sample output as having one fixed set of split rank
  columns; line 768 says the built-in combiner "works well for the RDP database, where taxonomy is
  stored in split rank columns", implying SILVA may not be; line 770 says the format varies. Three
  statements about the same file, and they do not agree.
- **Failure:** The reader opens their SILVA output, sees a single `lineage` column, and concludes
  Emu ran wrong or the database is corrupt — because Section 4 told them flatly what the columns
  would be. They spend an afternoon re-running Emu against a problem that does not exist. Or the
  reverse: they trust line 722, write their own R importer against those column names, and it
  breaks on the file they actually have.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED — lines 722 and 770 make incompatible claims about the same file.
- **Fix:** Replace line 722 with:

  ````markdown
  **What Emu outputs.** For each sample, a file called `<sample>_rel-abundance.tsv`: one row per
  detected taxon, with a `tax_id` column (NCBI taxonomy ID), an `abundance` column (relative,
  0-1), and — with `--keep-counts` — an estimated-counts column. How the taxonomy is stored
  depends on which prebuilt database you used: most builds give one column per rank (species,
  genus, family, order, class, phylum, superkingdom), some give a single semicolon-delimited
  `lineage` column. Check yours once, now, so nothing later surprises you:

  ```bash
  head -1 emu_results/silva/*_rel-abundance.tsv | head -2
  ```

  Both layouts are handled by the combiner in the next section, so you do not need to do anything
  differently — this is only so you recognise your own file.
  ````

### F-13 · S2 · Combiner writes blank taxonomy columns when the header matches neither expected layout
- **Where:** SOP_EMU_NeSI.md:770 and 828, 848-851, § 4 Option B
- **Quote:**
  > The script below handles either, so you do not have to check first.

  and

  >             is_lineage = "lineage" in headers

  and

  >                     if is_lineage:
  >                         tax_dict = parse_lineage(row.get("lineage", ""))
  >                     else:
  >                         tax_dict = {r: row.get(r, "") for r in RANKS}
- **Defect:** The single-column branch is selected only by an exact match on the field name
  `lineage`. If a build names that column anything else, `is_lineage` is `False` and the
  `else` branch runs `row.get(r, "")` for seven rank names that do not exist in the file,
  returning `""` for every one. The script then writes a full-size table with completely empty
  taxonomy columns and no warning. The note at line 770 asserts the opposite.
- **Failure:** The reader's combined counts table has correct tax_ids and correct per-sample
  counts, and seven empty columns where the taxonomy should be. They load it in R, build the
  phyloseq tax_table, and every barplot and every taxon-level test comes out labelled `NA` — or,
  if they drop empty ranks, they analyse at tax_id level and never notice the taxonomy was lost.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — provable from the code; the failure mode is a table of empty strings,
  not an exception.
- **Fix:** Replace lines 826-829 with:

  ```python
          with open(fpath) as f:
              reader = csv.DictReader(f, delimiter='\t')
              headers = reader.fieldnames or []
              is_lineage = "lineage" in headers
              if not is_lineage and not any(r in headers for r in RANKS):
                  sys.exit(
                      f"ERROR: {fpath} has neither a 'lineage' column nor any of the "
                      f"expected rank columns {RANKS}.\n"
                      f"Header found: {headers}\n"
                      f"Stopping rather than writing a table with empty taxonomy columns."
                  )
  ```

  and replace the second sentence of the note at line 770 with: "The script handles either and
  stops with an error if it finds a third layout, rather than writing a table with empty taxonomy
  columns."

### F-14 · S2 · Combiner silently drops the `unassigned` row; `emu combine-outputs` does not
- **Where:** SOP_EMU_NeSI.md:831-833, § 4 Option B
- **Quote:**
  >                 tax_id = row.get("tax_id", "").strip()
  >                 if not tax_id or tax_id == "unassigned":
  >                     continue
- **Defect:** The script discards the unassigned row, and nothing in the surrounding prose says so.
  Option A, presented as the alternative route to the same table, has no such filter. The two
  routes therefore produce different per-sample totals from identical input, and the document
  presents them as interchangeable.
- **Failure:** A reader who ran Option A and a labmate who ran Option B compare library sizes and
  find they disagree by the unassigned fraction — for a divergent environmental community that can
  be 10-30% of reads. Neither can find anything in the SOP explaining the difference. More
  seriously, a reader who normalises to a fixed depth in Part 2 gets a different depth depending
  on which combiner they used, and the document gives no reason to expect that.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED for the drop (the code does it and the prose never mentions it).
  NEEDS-BENCH-CHECK for the divergence — run `emu combine-outputs emu_results/silva species
  --counts` and `grep -c unassigned` the result to confirm Option A retains the row.
- **Fix:** Replace lines 831-833 with:

  ```python
                  tax_id = row.get("tax_id", "").strip()
                  if not tax_id:
                      continue
                  if tax_id == "unassigned":
                      # Reads Emu could not place at the requested rank. Dropped so the
                      # combined table holds classified taxa only. `emu combine-outputs`
                      # (Option A) keeps this row, so the two routes give different
                      # per-sample totals — never mix tables from both in one analysis.
                      continue
  ```

  and add after line 912:

  > **Note on the unassigned fraction.** This script keeps classified taxa only; the `unassigned`
  > row from each per-sample file is dropped, so column sums are classified reads, not total reads.
  > That is deliberate — an "unassigned" pseudo-taxon behaves badly in diversity and differential
  > abundance analysis — but it means the totals here are smaller than the read counts you saw
  > after filtering, and smaller than what `emu combine-outputs` would give. Pick one combiner and
  > use it for the whole study. If you want to know how large your unassigned fraction is, read it
  > out of the per-sample files before combining:
  >
  > ```bash
  > grep -H "^unassigned" emu_results/silva/*_rel-abundance.tsv | cut -f1,2
  > ```

### F-15 · S2 · No barcode-to-sample mapping produced, so the count table columns are barcode numbers
- **Where:** SOP_EMU_NeSI.md:914 and 926, § 4 Option B
- **Quote:**
  > Both share the structure: `tax_id | species | genus | family | order | class | phylum | superkingdom | sample1 | sample2 | ...`

  and

  > Download the counts and abundance files to your computer for the R analysis.
- **Defect:** Sample names are derived from FASTQ filenames, which the document set to `barcode01`,
  `barcode02` … at line 307. The document ends by handing off a table whose columns are barcode
  numbers, with no step anywhere that records which barcode was which biological sample, and no
  instruction to build the metadata file the R analysis needs.
- **Failure:** The reader downloads a table with columns `barcode01 … barcode24` and, weeks later,
  builds a metadata sheet from memory or from a plate map they read in the wrong orientation. Every
  sample label is shifted by one. Ordination separates the groups beautifully, PERMANOVA is
  significant, and the result is wrong — with nothing anywhere in either document capable of
  detecting it.
- **Type:** GAP
- **Confidence:** CONFIRMED — no mapping, sample sheet, or metadata step appears anywhere in the
  file.
- **Fix:** Replace line 926 with:

  ````markdown
  ### Record what each barcode was

  Your table's columns are `barcode01`, `barcode02`, … because that is what the FASTQ files were
  called. Nothing downstream can recover which biological sample each barcode held, and a
  mis-numbered mapping produces a clean, significant, entirely wrong result. Write the mapping down
  now, while the run is fresh, as a CSV with one row per barcode:

  ```bash
  cat > sample_metadata.csv <<'EOF'
  SampleID,SampleName,Site,Sex,Species,SampleType
  barcode01,TK_01,Takapourewa,F,Sphenodon punctatus,gut
  barcode02,TK_02,Takapourewa,M,Sphenodon punctatus,gut
  barcode03,BLANK_01,NA,NA,NA,extraction_blank
  EOF
  ```

  Rules that matter later: the `SampleID` column must match the count-table column headers exactly
  (`barcode01`, not `Barcode01` or `barcode1`); include every barcode you sequenced, including
  blanks and mock communities; and give controls a `SampleType` that marks them as controls, since
  Part 2's decontamination step selects on exactly that.

  ### Hand off to the R analysis

  Download three files to your computer for the R analysis: `emu-combined-counts_silva.tsv`,
  `emu-combined-abundance_silva.tsv` and `sample_metadata.csv` — plus the RDP equivalents if you
  ran both databases.
  ````

### F-16 · S2 · `--type lr:hq` may not be an accepted value in the pinned Emu version
- **Where:** SOP_EMU_NeSI.md:17, 672 and 706, § front matter / Running Emu
- **Quote:**
  > emu abundance ${FASTQ} \
  >     --type lr:hq \

  and

  > - `--type lr:hq` — input is long-read, high-quality (SUP-basecalled Nanopore). … use `map-ont` (the Emu default) for older HAC-basecalled reads.

  and, from the front matter:

  > The commands here are compatible with v3.4.0+.
- **Defect:** `lr:hq` is a comparatively recent minimap2 preset. Emu validates `--type` against a
  fixed list of presets; if `lr:hq` is not in that list for the module version being loaded, every
  array task aborts on argument parsing. The document asserts compatibility back to v3.4.0 without
  qualification, and this is the one flag in the command most likely to break that claim.
- **Failure:** All 24 array tasks exit in under a second with an argparse error buried in 24
  separate `.err` files. The reader, who has been told the command works on v3.4.0+, checks the
  database path and the manifest first and loses an afternoon before reading an `.err` file
  closely enough to spot `invalid choice: 'lr:hq'`.
- **Type:** CORRECTNESS
- **Confidence:** NEEDS-BENCH-CHECK — run `module load Emu/3.6.2 && emu abundance --help` and read
  the accepted values for `--type`.
- **Fix:** Once checked, replace the front-matter claim at line 17 with a version-specific one and
  add a one-command smoke test before line 683:

  ````markdown
  **Test one sample before submitting the array.** Twenty-four tasks failing on a typo costs you
  an hour; one task failing costs you a minute. Run the Emu command interactively on the first
  manifest line first:

  ```bash
  module purge && module load Emu/3.6.2
  emu abundance $(head -1 emu_manifest.txt) \
      --type lr:hq --db ${DB_PATH} --keep-counts --threads 2 \
      --output-dir ./emu_results/test --output-basename smoketest
  ```

  If this errors with `invalid choice: 'lr:hq'`, your Emu build predates that minimap2 preset —
  use `--type map-ont` throughout instead. It is the Emu default and tuned for older HAC-basecalled
  reads, so it is slightly less well matched to SUP data but entirely usable. Delete
  `emu_results/test` once the smoke test passes.
  ````

### F-17 · S2 · No mention of negative controls, though the workflow this document feeds requires them
- **Where:** SOP_EMU_NeSI.md:25, § Analysis steps
- **Quote:**
  > 5. Analysis of amplicon data in R (phyloseq, decontamination, rarefying, alpha and beta diversity, taxonomy plots)
- **Defect:** The document's own roadmap promises a decontamination step downstream, but nowhere in
  Sections 1-4 does it say that decontamination requires extraction blanks and no-template controls
  to have been sequenced alongside the samples. The word "control" does not appear in the document
  outside the phrase "quality control". This is the one requirement in the whole pipeline that
  cannot be satisfied retrospectively.
- **Failure:** The reader sequences 24 biological samples and no blanks, follows this SOP to a
  clean count table, opens Part 2, and finds a decontam step they cannot run. They skip it. Reagent
  contaminants — *Ralstonia*, *Burkholderia*, *Pseudomonas*, which dominate low-biomass amplicon
  libraries — are reported as members of the community, and in low-biomass samples they may
  dominate the ordination. Nothing in the data looks wrong.
- **Type:** GAP
- **Confidence:** CONFIRMED — searched the file for control/blank/negative; the only hits are
  "quality control" and the roadmap line quoted above.
- **Fix:** Insert as a callout immediately after line 292, at the head of Section 3:

  ````markdown
  > **Before you sequence: controls.** This is here rather than in Section 5 because it is the one
  > thing in this pipeline you cannot fix afterwards. Part 2 removes reagent and kit contaminants
  > with `decontam`, and `decontam` works by comparing your samples against **negative controls**
  > that went through extraction and PCR with no template. Include at least one extraction blank
  > per extraction batch and one no-template PCR control per PCR plate, barcode them like any other
  > sample, and sequence them. They will look nearly empty, which is the point.
  >
  > This matters most for low-biomass material — swabs, water, tissue, anything with little DNA —
  > where reagent taxa such as *Ralstonia*, *Burkholderia* and *Pseudomonas* can make up a large
  > share of the reads. Without blanks you cannot tell those apart from real community members,
  > and they will appear in your results as biology.
  >
  > A positive control (a mock community of known composition) is also worth a barcode: it is the
  > only way to check that your whole pipeline, including the database choice in Section 4,
  > recovers the composition it should.
  ````

### F-18 · S3 · Two different alarm thresholds for read retention, and the worked example sits outside both
- **Where:** SOP_EMU_NeSI.md:444, 483 and 485, § 3 Steps 3-4
- **Quote:**
  > You should typically retain 60-80% of reads. If a barcode retains less than ~30%, something may be wrong with that sample

  and

  > - **Read count.** A drop of 20-40% is typical. Losing more than 60% means your raw data had quality or fragmentation issues.

  and

  > we retained about 17.8M of 21M reads (~85%)
- **Defect:** Two thresholds for the same decision: line 444 raises the alarm below 30% retention,
  line 483 raises it below 40%. And the document's own worked example retains 85%, above the
  "typical" band both statements give, with no comment.
- **Failure:** The reader's barcode retains 35%. Line 444 says that is acceptable; line 483 says it
  is not. They have no basis for choosing, and if their own run retains 85% like the example they
  cannot tell whether that is good or a sign that the filters did not run.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED — both thresholds are in this file, describing the same quantity.
- **Fix:** Use one threshold everywhere. Change line 483 to "**Read count.** Retaining 60-85% is
  normal; below 60% is worth a look and below 30% means that sample had quality or fragmentation
  problems." Change line 444 to match ("60-85%"), and add one clause to line 485: "…(~85%) — a
  clean library sits at the top of the normal range".

### F-19 · S3 · SUP read quality stated three incompatible ways
- **Where:** SOP_EMU_NeSI.md:229, 241, 347 and 358, § 2 / § 3 Step 2
- **Quote:**
  > error rates are typically 0.5-1% on R10.4.1 flow cells with SUP basecalling

  and

  > Nanopore reads with the SUP basecaller typically average Q15-Q20.

  and

  > with R10.4.1 flow cells and SUP basecalling, median quality is typically Q15-Q20

  and, from the worked example:

  > Median read quality:                  24.3
- **Defect:** 0.5-1% error is Q20-Q23. Q15-Q20 is 1-3.2% error. These are different claims about
  the same data, made 12 lines apart, and the document's own real example (median Q24.3, mean
  Q20.4) sits above both stated ranges.
- **Failure:** The reader's run comes back at median Q22. Line 347 tells them that is unusually
  good; line 229 tells them it is normal. They have no way to judge whether the run is fine, and
  the example — the one concrete anchor in the section — contradicts the rule it illustrates.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED — arithmetic on the document's own Q-to-error mapping at lines 234-239.
- **Fix:** Standardise on one range. Change lines 241 and 347 to "median quality is typically
  Q18-Q25 (about 0.3-1.5% error)" and note at line 351 that the worked example's median of Q24.3
  is at the good end of that range.

### F-20 · S3 · Roadmap numbers Sections 5-7, which do not exist in this document
- **Where:** SOP_EMU_NeSI.md:3 and 25-27, § front matter / Analysis steps
- **Quote:**
  > For the R analysis (Sections 5-7), see `SOP_R_Analysis.md`.

  and

  > 5. Analysis of amplicon data in R (phyloseq, decontamination, rarefying, alpha and beta diversity, taxonomy plots)
  > 6. Going further in R (ANCOM-BC2, MaAsLin2, indicator species)
  > 7. Writing up your results
- **Defect:** The document contains Sections 1-4 only. Items 5-7 of the roadmap are content in a
  different file, presented under this document's own numbering. The README states the convention
  being broken: "**A bare section number always means the current document.** 'Section 9' in one
  SOP never points at another SOP's Section 9."
- **Failure:** The reader finishes Section 4, scrolls for Section 5, reaches the end of the file,
  and cannot tell whether the document is truncated or whether they have missed something. If they
  then open `SOP_R_Analysis.md` looking for a section numbered 5, they will not find one either.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED — README.md:53 states the convention; this file has four `##`-numbered
  sections.
- **Fix:** Change the heading at line 19 to "## What this document covers", cut items 5-7 from the
  list, and end the list with: "The R analysis that follows — phyloseq, decontamination, SRS
  normalisation, diversity, differential abundance, write-up — is in `SOP_R_Analysis.md`, which
  numbers its own sections from 1." Change line 3 to point at the file without a section number.

### F-21 · S3 · No expected runtime or scale caveat on the NanoPlot job, whose worked example is 21 million reads
- **Where:** SOP_EMU_NeSI.md:321-323 and 342, § 3 Step 2
- **Quote:**
  > #SBATCH --time 00:30:00
  > #SBATCH --mem 8G

  and

  > Submit with `sbatch 01_nanoplot_raw.sh`. No need to array this; it is lightweight and fast.
- **Defect:** "Lightweight and fast" is stated with no scale attached, next to a worked example of
  21 million reads and 27.5 Gbases. `--plots dot` renders a point per read. The reader is given
  a walltime and memory figure but no way to judge whether they apply to a run ten times larger
  than the example, and no instruction to check afterwards — even though Section 1 taught
  `nn_seff` for exactly this.
- **Failure:** The job hits the 30-minute walltime or OOMs on a large run. The reader, told the
  step is lightweight, assumes something is broken rather than under-resourced, and has no stated
  expected runtime to compare against.
- **Type:** GAP
- **Confidence:** NEEDS-BENCH-CHECK — run `01_nanoplot_raw.sh` on the full raw set and read peak
  memory and elapsed time off `nn_seff <job_id>`.
- **Fix:** Replace the second sentence of line 342 with: "No need to array this — one NanoPlot run
  covers every barcode. Expect roughly N minutes and under M GB for a run of this size; run
  `nn_seff <job_id>` afterwards and raise `--time`/`--mem` if you were close to either limit.
  `--plots dot` draws one point per read, so both scale with total read count, not sample count."
  (Fill N and M from the bench check.)

### F-22 · S3 · BaseSpace named as a source for Nanopore data
- **Where:** SOP_EMU_NeSI.md:295, § 3 Step 1
- **Quote:**
  > When downloading from BaseSpace or Globus, put your data exactly where you want it in a named directory.
- **Defect:** BaseSpace is Illumina's sequencing cloud. Nanopore data does not come from it — as
  this document says at line 260, "Data from the sequencer (MinKNOW) comes as FASTQ files organised
  in subdirectories by barcode."
- **Failure:** A reader with no prior experience goes looking for their Nanopore run in a BaseSpace
  account they do not have, and concludes their data is missing or that they were meant to be given
  access to something.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — contradicts line 260 of this document.
- **Fix:** Covered by the replacement text in F-05, which removes the BaseSpace reference and
  replaces it with the actual transfer routes. If applying this finding alone, change line 295 to
  "Nanopore runs arrive as a MinKNOW output folder, usually from the sequencing facility rather
  than a cloud service."

### F-23 · S3 · "Start modest (4 GB)" is ambiguous next to a `--mem-per-cpu` template
- **Where:** SOP_EMU_NeSI.md:149-150 and 179, § 1 SLURM
- **Quote:**
  > #SBATCH --mem-per-cpu 4G                      # memory per CPU
  > #SBATCH --cpus-per-task 2                     # number of CPU cores

  and

  > **Choosing resources.** Start modest (1 hour, 4 GB, 2 CPUs) and increase if your job runs out of time or memory.
- **Defect:** The template requests 4 GB per CPU across 2 CPUs — 8 GB total — while the prose
  describes the same request as "4 GB". Every actual script in the document then uses `--mem`
  (total), which is a different flag. The document never says that `--mem` is total and
  `--mem-per-cpu` is per core, and the two are taught interchangeably.
- **Failure:** The reader learns from the template, writes `--mem-per-cpu 10G --cpus-per-task 8`
  for the Emu array as instructed at line 702 ("Start with `--mem 10G`"), and requests 80 GB per
  task across 24 tasks. The job either queues for hours behind a request SLURM cannot easily place,
  or draws a note from NeSI staff — the exact outcome line 179 warns against.
- **Type:** CLARITY
- **Confidence:** CONFIRMED — line 149 and line 179 describe the same header with different totals.
- **Fix:** Change the template line 149 to `#SBATCH --mem 8G  # total memory for the job (use
  --mem-per-cpu instead if you want it per core)`, and change line 179's opening to "Start modest
  (1 hour, 8 GB total, 2 CPUs)". Use `--mem` consistently in the four real scripts, which they
  already do.

### F-24 · S3 · "Step 1/2/3" reused for three unrelated sequences
- **Where:** SOP_EMU_NeSI.md:293, 580 and 624, § 3 / § 4
- **Quote:**
  > ### Step 1. Organise your raw data

  and

  > **Step 1: Create your database directory and install the download tool.**

  and

  > **Step 1: Build a manifest file.**
- **Defect:** Three independent step sequences all start at Step 1 in one document — Section 3's
  Steps 1-4, the database setup's Steps 1-3, and the Emu run's Steps 1-3. Nothing distinguishes
  them in the text.
- **Failure:** The reader takes a note that says "stuck at Step 2", or a supervisor asks them to
  redo Step 3, and neither can tell which of the three is meant without re-reading the document.
- **Type:** STRUCTURE
- **Confidence:** CONFIRMED — all three occur in this file.
- **Fix:** Renumber the two Section 4 sequences as 4.1/4.2/4.3 (database setup) and 4.4/4.5/4.6
  (running Emu), or drop the "Step N" prefix in Section 4 and use plain bold labels
  ("Create the database directory", "Download SILVA", "Download RDP").

### F-25 · S3 · Option A given more space than the preferred Option B, and as reference material
- **Where:** SOP_EMU_NeSI.md:730-765, § 4 Option A
- **Quote:**
  > #### Option A: `emu combine-outputs`
  >
  > Emu ships with a `combine-outputs` subcommand that merges per-sample tables into one.
- **Defect:** Option B is labelled "preferred for consistency", yet Option A comes first and gets a
  full reference treatment — syntax block, positional arguments, optional flags, output naming,
  worked examples, and a blockquoted warning — in the middle of the walkthrough. The reader meets
  the route they are not supposed to take before the one they are.
- **Failure:** The reader works top to bottom, runs Option A because it appears first and looks
  more official, produces `emu-combined-species.tsv` — a filename that appears nowhere in the rest
  of the document — and then finds every subsequent instruction referring to
  `emu-combined-counts_<db>.tsv`, which they do not have.
- **Type:** STRUCTURE
- **Confidence:** CONFIRMED — line 766 states Option B is preferred; Option A occupies 36 lines
  ahead of it.
- **Fix:** Lead with the custom combiner as the main path (rename the heading to "Combining with
  `combine_emu_results.py`") and demote Option A to a short subsection at the end titled "If you
  would rather use Emu's built-in combiner", keeping the syntax reference but adding: "Its output
  is named `emu-combined-<rank>.tsv` and includes the unassigned row, so it is not
  interchangeable with the tables the rest of this SOP refers to."

### F-26 · S3 · `--min-align-len` offered with no default or recommendation
- **Where:** SOP_EMU_NeSI.md:719, § 4 Running Emu
- **Quote:**
  > - `--min-align-len 1000` — minimum aligned query length in bp (default `0`). Discards short partial alignments that may lack enough variable regions for reliable classification.
- **Defect:** Presented as an optional flag with a concrete value attached and a reason to use it,
  but no statement of whether this workflow uses it. Every other flag in the list either says what
  to do (`--keep-counts`: "essential, do not omit"; `--min-pid`: "only raise this if…") or is
  self-evidently diagnostic. This one leaves the reader to decide.
- **Failure:** The reader adds `--min-align-len 1000` on the strength of the rationale given,
  without realising that chopper has already imposed a 1,200 bp floor on read length in Section 3,
  so the flag does almost nothing except make their command differ from the SOP's — and from a
  labmate's — for no recorded reason.
- **Type:** CLARITY
- **Confidence:** CONFIRMED — the bullet states a value and a rationale but no default for this
  workflow.
- **Fix:** Change to: "`--min-align-len 1000` — minimum aligned query length in bp (default `0`).
  **We do not use it.** chopper has already removed everything under 1,200 bp in Section 3, so the
  short partial alignments this targets are largely gone before Emu sees them. It is worth
  considering only if you skipped the length filter."

### F-27 · S3 · Three NanoPlot interpretation blocks covering overlapping ground
- **Where:** SOP_EMU_NeSI.md:344, 371, 479 and 505-507, § 3 Steps 2-4
- **Quote:**
  > **How to interpret the report:**

  and

  > Two plots to check first when assessing run quality:

  and

  > **What to compare between raw and filtered:**

  and

  > ### Interpreting NanoPlot output
  >
  > NanoPlot produces several plots. You do not need all of them; these are the key ones.
- **Defect:** Read-length interpretation appears at 346, 373-377, 481 and 513; length-vs-quality
  interpretation at 379-383 and 515-519. "These are the key ones" (507) and "Two plots to check
  first" (371) make the same claim about the same two plots, 136 lines apart. The heading at 505
  also sits at `###` alongside "Step 1"-"Step 4" without being a step.
- **Failure:** The reader reads the raw-plot guidance in Step 2, the comparison list in Step 4, and
  the filtered-plot guidance in an unnumbered section afterwards, and has to reconstruct which
  advice applies to which report. Twice they are told which plots matter most, in different words.
- **Type:** STRUCTURE
- **Confidence:** CONFIRMED — four interpretation blocks, all in this file.
- **Fix:** Fold lines 505-524 into Step 4 as "**How to read the filtered report**", delete the
  duplicated "these are the key ones" framing at line 507 (the claim is already made at line 371),
  and keep the raw/filtered image pairs adjacent so the before/after comparison the document
  recommends for a thesis is actually laid out that way.

### F-28 · S4 · `nn_seff` introduced twice with two different glosses
- **Where:** SOP_EMU_NeSI.md:120 and 167, § 1 Basic bash commands / SLURM
- **Quote:**
  > nn_seff <job_id>                  # resource usage of a finished job, great for right-sizing

  and

  > nn_seff <job_id>                  # friendlier resource summary, great for right-sizing
- **Defect:** `nn_seff` is a SLURM accounting tool, but it is taught first in the general bash
  list at line 120 — 47 lines before jobs, job IDs or SLURM exist in the document — and then taught
  again in the SLURM block with a reworded gloss, so it has no single home.
- **Failure:** The reader meets `nn_seff` in the general-bash list before SLURM has been introduced,
  learns it again 47 lines later, and cannot tell whether the two are the same command.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED
- **Fix:** Delete the line 120 entry; `nn_seff` belongs in the SLURM block, not in general bash.

### F-29 · S4 · Two `#`-level titles, near-duplicates of each other
- **Where:** SOP_EMU_NeSI.md:1 and 5, § front matter
- **Quote:**
  > # Part 1: NeSI Pipeline (Sequencing to Count Tables)

  and

  > # Taylor Lab Bioinformatic SOP: Full-Length 16S rRNA Analysis (Nanopore Long Reads)
- **Defect:** The file opens with two `#`-level headings four lines apart, neither subordinated to
  the other, so the document has no single title — against the convention of one `#`-level title
  per document.
- **Failure:** The rendered table of contents shows two top-level titles for one document, and the
  reader cannot tell whether "Part 1" and the SOP title name the same thing.
- **Type:** STRUCTURE
- **Confidence:** CONFIRMED
- **Fix:** Merge into one `#` title — "Part 1 — Full-Length 16S rRNA on Nanopore: Sequencing to
  Count Tables (NeSI)" — and keep the one-line scope sentence beneath it.

### F-30 · S4 · `<your_email>@auckland.ac.nz` makes the placeholder boundary ambiguous
- **Where:** SOP_EMU_NeSI.md:173, § 1 SLURM
- **Quote:**
  > #SBATCH --mail-user <your_email>@auckland.ac.nz   # where notifications go
- **Defect:** The domain is written outside the angle brackets, so this line's placeholder covers
  only the local part of the address, while README.md:50 defines `<your_email>` as the entire
  address to be substituted — one slot with two incompatible spellings.
- **Failure:** The README defines `<your_email>` as the whole address, so a reader substituting as
  documented produces `jsmith@auckland.ac.nz@auckland.ac.nz` and gets no mail, with no error.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED — README.md:50 lists `<your_email>` among the placeholders to substitute.
- **Fix:** Change to `#SBATCH --mail-user <your_email>` and add "(your full address, e.g.
  `jsmith@auckland.ac.nz`)" to the trailing comment.

### F-31 · S4 · `--min-abundance 0.0001` passed explicitly, then described as the default
- **Where:** SOP_EMU_NeSI.md:678 and 716, § 4 Running Emu
- **Quote:**
  >     --min-abundance 0.0001

  and

  > - `--min-abundance 0.0001` — the default threshold (0.01%). Raise it (e.g., `0.01` for 1%) to reduce noise
- **Defect:** The flag is written into the array script as part of the standard command, yet
  documented 38 lines later under "Optional flags" as merely restating Emu's default, so the
  document never says whether it is deliberate or redundant.
- **Failure:** The reader sees the flag in the main script, then finds it under "Optional flags"
  described as the default, and cannot tell whether removing it would change anything.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED
- **Fix:** Keep the flag in the script (explicit is better for reproducibility) and change line 716
  to open: "`--min-abundance 0.0001` — Emu's default (0.01%); we set it explicitly so the value is
  on the record in your script."

### F-32 · S4 · `--keep-counts` warning repeated three times
- **Where:** SOP_EMU_NeSI.md:708, 747 and 764, § 4 Running Emu / Option A
- **Quote:**
  > - `--keep-counts` — **essential, do not omit.** … Forget this and you re-run Emu from scratch.

  and

  > - `--counts` — output estimated counts instead of relative abundance. Only includes samples whose per-sample files already contain estimated counts … Without that, the counts table is empty.

  and

  > > **Important:** The counts table only works if you ran `emu abundance` with `--keep-counts`. Without it there is no way to recover counts from abundance-only output; you would have to re-run Emu.
- **Defect:** One warning — omitting `--keep-counts` costs a full Emu re-run — is stated three
  times within 56 lines, as a flag description, as a property of `--counts`, and as a standalone
  blockquote, with the second and third adding no information the first does not already carry.
- **Failure:** The reader reads the same warning three times in 56 lines and starts skimming
  callouts — including the ones they have not seen before.
- **Type:** CLARITY
- **Confidence:** CONFIRMED
- **Fix:** Keep line 708 in full (it is the point of use and the strongest statement), keep the
  clause in line 747 since it explains that flag's behaviour, and delete the blockquote at 764,
  which adds nothing the other two do not say.

### F-33 · S4 · `mkdir -p filtered` and `mkdir -p logs` re-created after Step 1 already made them
- **Where:** SOP_EMU_NeSI.md:299, 416 and 686, § 3 Step 1 / Step 3 / § 4
- **Quote:**
  > mkdir -p raw_files filtered qc_raw qc_filtered emu_results logs

  and

  > **Step 3: Create the logs directory and submit:**
- **Defect:** `filtered/` and `logs/` are both created by Step 1's setup block and then created
  again at lines 416 and 686, and the line 686 heading announces the second `logs` creation as a
  new step even though jobs 01-03 have already written into that directory.
- **Failure:** "Create the logs directory" at line 686 implies `logs/` does not exist — but jobs
  01-03 already wrote into it, so a reader who took line 686 literally would conclude those earlier
  jobs should have failed, and go looking for a problem that is not there.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED
- **Fix:** Change the line 686 heading to "**Step 3: Submit.**" and keep the `mkdir -p logs` command
  as a harmless safety net without describing it as creating something new.

### F-34 · S4 · SBATCH long options mix space and `=` syntax within one header
- **Where:** SOP_EMU_NeSI.md:639-646, § 4 Running Emu
- **Quote:**
  > #SBATCH --job-name emu_array
  > #SBATCH --time 00:50:00
  > …
  > #SBATCH --array=0-23                  # CHANGE to match your sample count (0 to N-1)
- **Defect:** Seven options in this header use the space-separated long-option form and `--array`
  uses `=`, and the document nowhere states which form it follows — the other three SLURM scripts
  use spaces exclusively.
- **Failure:** A reader copying the pattern for a new flag guesses wrong about which form the
  document uses and, on a flag where SLURM is fussier, gets a parse error they cannot attribute.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED
- **Fix:** Use the space-separated form throughout, matching the other three scripts: `#SBATCH
  --array 0-23`.

### F-35 · S4 · US spelling in an otherwise UK-spelled document
- **Where:** SOP_EMU_NeSI.md:129, § 1 Using modules
- **Quote:**
  > module spider NanoPlot             # case-sensitive, try different capitalizations
- **Defect:** "capitalizations" is the only US spelling in the document; every other instance of
  the pattern uses the UK form ("organise" at 293, "organised" at 260, "optimised" at 531,
  "normalisation" at 708).
- **Failure:** Trivial in isolation, but the document is otherwise consistently UK-spelled
  ("organise", "normalisation", "optimised"), and the drift signals to a contributor that either
  convention is acceptable.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED
- **Fix:** "capitalisations".

### F-36 · S4 · Front-matter version claim not tied to the module table beneath it
- **Where:** SOP_EMU_NeSI.md:17, § front matter
- **Quote:**
  > Verify the latest Emu module on your cluster with `module spider Emu`. The commands here are compatible with v3.4.0+.
- **Defect:** The compatibility claim is unconditional and sits directly beneath a module table
  pinning v3.6.2, but Section 4's command uses `--type lr:hq`, a preset whose availability is
  version-dependent — so the claim vouches for a flag it cannot vouch for.
- **Failure:** The reader finds only `Emu/3.4.0` on the cluster, is told the commands are
  compatible, and hits the `--type lr:hq` question in Section 4 with no warning that the
  compatibility claim has an exception.
- **Type:** CLARITY
- **Confidence:** CONFIRMED — the claim is unconditional and the document later uses a flag whose
  availability is version-dependent.
- **Fix:** Change to: "Verify what is installed with `module spider Emu`. The commands here were
  written against v3.6.2 and work on v3.4.0+ with one exception — see the `--type` note in Section
  4 if your build is older."

## Keep list

1. **SOP_EMU_NeSI.md:391-395, the three threshold justifications.** `--quality 10`,
   `--minlength 1200`, `--maxlength 1800` each get a paragraph explaining the number, including the
   non-obvious reason 1,200 rather than 1,500 (16S gene length varies 1,400-1,540 bp across species,
   so a 1,500 floor discards real full-length reads). A rewrite aiming at length will be tempted to
   compress these into a table of values. They are the reason the document exists.
2. **SOP_EMU_NeSI.md:718, the `--min-pid` scale warning.** "The value is a **percent out of 100**,
   so `90` means 90% identity. Do not write `0.9` expecting 90%; Emu reads that as 0.9% identity,
   which filters nothing." This is a silent-failure warning about a flag that looks like it took
   effect and did not. The paragraph runs long and will attract an editor; tighten the prose around
   it if you must, but the 0.9-vs-90 sentence must survive verbatim.
3. **SOP_EMU_NeSI.md:720, the `--max-align-len` default.** "Silently caps the alignment length Emu
   considers… raise it or reads are discarded without warning." Same category, and it looks
   irrelevant to this workflow (our reads are under 1,800 bp), which is exactly why it will be cut.
4. **SOP_EMU_NeSI.md:708, `--keep-counts` is essential.** "Forget this and you re-run Emu from
   scratch." Keep this instance in full even while deleting the two restatements (F-32).
5. **SOP_EMU_NeSI.md:63, the `rm -r ~/proj` warning.** "**Do not run `rm -r ~/proj`**, which follows
   the link and recursively deletes the target." One sentence standing between a novice and the
   loss of an entire nobackup workspace.
6. **SOP_EMU_NeSI.md:41, the Jupyter two-pane gotcha.** Reads like trivia; is the single most
   common way a first-time NeSI user loses half an hour.
7. **SOP_EMU_NeSI.md:724, why Emu counts are fractional.** Explains a number the reader will
   otherwise assume is a bug, and states the rounding decision that Part 2 depends on.
8. **SOP_EMU_NeSI.md:565, the SILVA version note.** Records why v138.1 rather than the newer 138.2
   ("has not yet been tested or validated with Emu") and the OSF project IDs. Exactly the kind of
   provenance a methods section needs and nobody can reconstruct later.
9. **SOP_EMU_NeSI.md:353-369 and 487-503, the two real NanoStats blocks.** These are the only
   place a reader can calibrate their own output against a run that worked. Fix the ranges they
   contradict (F-18, F-19); do not replace them with idealised numbers.
10. **SOP_EMU_NeSI.md:537-547, the EM explanation.** Four steps plus the "community context"
    paragraph. This is the concept the audience most genuinely lacks, and it is what makes the
    difference between Emu and best-hit assignment comprehensible.

## Gaps

- **What a failed array task looks like, and how to re-run just that task.** SHOULD-ADD, ~8 lines.
  The document tells the reader each task writes its own `.err` (line 690) but never shows a
  failure, never says how to identify which indices failed (`sacct -j <job_id> --format=JobID,State`),
  and never says that re-running is `sbatch --array=7,19 emu_array.sh`. This is the single most
  likely thing to go wrong in Section 4.
- **What to do about a sample with very few reads.** SHOULD-ADD, ~5 lines. Line 348 gives a target
  of 10,000-50,000 reads per barcode but no action for a barcode that comes in at 800. Drop it,
  keep it, re-sequence? The decision affects normalisation depth in Part 2, and the reader is left
  to invent a rule.
- **Disk space required.** CONSIDER, ~3 lines. The reader is told databases are "several GB" (line
  578) but never given a figure for the workspace itself. With 21M reads the raw + filtered FASTQs
  in the worked example are well over 50 GB, and `nobackup` quotas are finite. One sentence with a
  per-sample estimate and a pointer to `nn_storage_quota` (already taught at line 119) would close it.
- **Cleaning up.** CONSIDER, ~3 lines. Nothing tells the reader that raw FASTQs on `nobackup` are
  purged after 90 days (the README says so at line 42; this document says only "may be purged on a
  rolling basis" at line 47), or that the filtered FASTQs can be deleted once the count tables
  exist. A student returning to their data six months later to answer a reviewer will find it gone.
- **A worked expectation for the combiner's console output.** CONSIDER, ~4 lines. The script prints
  `Found N sample files` and `M unique tax_ids across N samples`, but the document never shows what
  those lines look like or what values are reasonable — so a reader whose SILVA run reports 12,000
  tax_ids and whose RDP run reports 400 has no basis for judging either.
- **Whether to compare SILVA and RDP, and how.** SHOULD-ADD, ~6 lines. Line 574 says "Run both and
  compare… A taxon appearing with only one database is worth investigating", and the pipeline duly
  produces two sets of tables — then the document ends without a single command or criterion for
  the comparison. The reader is left with two count tables and an instruction they cannot act on.

## Cross-document flags

Every claim in this file about another document, the README, or a shared convention. None resolved
— I read only this file and README.md.

| Line | Claim to check |
| --- | --- |
| 3 | "For the R analysis (Sections 5-7), see `SOP_R_Analysis.md`." — file exists per the README, but does it number sections such that "5-7" means anything there? See F-20. |
| 7 | "**Last updated:** May 2026" vs README.md:108 "*Last updated: July 2026*". Check whether the README's July update should have touched this file. |
| 13-15 | Module table (`Emu/3.6.2`, `NanoPlot/1.43.0-foss-2023a-Python-3.11.6`, `chopper/0.12.0b-GCC-12.3.0`) duplicated at README.md:65-67. Verify they still agree after any edit; two copies of a version string will drift. |
| 25-27 | Roadmap items 5-7 claim `SOP_R_Analysis.md` covers "phyloseq, decontamination, rarefying, alpha and beta diversity, taxonomy plots", "ANCOM-BC2, MaAsLin2, indicator species", "Writing up your results". README.md:14 says Part 2 uses **SRS normalisation**, not rarefying. Check which term Part 2 actually uses — this document says "rarefying" and the README says "SRS normalisation", and README.md:52 warns that mixing normalisation states is "the single easiest thing to get wrong in Part 2". |
| 51-54 / 583 | The `~/proj` symlink target and the database location assume a `<your_project>` subdirectory. Check `SOP_CONCOMPRA_NeSI.md`, which the README says "assumes Part 1 Section 1 has been read", uses the same workspace path after F-01 is applied. |
| 187-194 | Genomics Aotearoa Summer School links, also cited at README.md:46 as the bridge to the read-based SOP. Check the four URLs still resolve and that the README's characterisation matches. |
| 275-288 | "Full-length vs short-read: why it matters" — README.md:18 points readers here by name for the interpretation differences. Verify the section still carries what the README promises. |
| 287 | "the downstream R/phyloseq workflow is the same regardless of platform" — README.md:18 makes the same claim. Check `SOP_R_Analysis.md` and the read-based SOP's Section 13 agree. |
| 565 | SILVA v138.1 vs 138.2 rationale and the OSF project IDs (`56uf7`, `32sh5`). README.md:85 summarises this; check the two accounts agree. |
| 722 / 911-914 | The handoff artefact: `emu-combined-counts_<db>.tsv` with columns `tax_id | species | … | superkingdom | sample1 …`. Check that `SOP_R_Analysis.md` opens on exactly this filename and this column layout, including the eight leading columns the verification loop at line 922 assumes. |
| 724 | "We round to whole numbers in R before analysis" — a claim about what Part 2 does. Verify Part 2 actually rounds, and at which step. |
| 926 | "Download the counts and abundance files to your computer for the R analysis." Check Part 2's first section expects both files, and see F-15 on the missing metadata file — Part 2 will need one and this document never produces it. |
| README:51 | "The QC and filtering SLURM scripts are numbered in run order (`01_nanoplot_raw.sh`, `02_chopper_filter.sh`, `03_nanoplot_filtered.sh`) … The Emu array jobs are named by function instead (`emu_array.sh`, `emu_array_rdp.sh`)." This file honours that. Flagged so a later agent knows the convention is met here and can check the other SOPs against it. |
| README:53 | "A bare section number always means the current document." Violated at line 3 and lines 25-27 — see F-20. |

## Rewrite plan

Ordered by dependency. Items 1-3 must land before the rest, because everything below assumes one
settled workspace path and one settled submission model.

1. **Settle the workspace path.** Closes F-01. Rewrite Step 1's setup block, then apply the
   `<your_project>` substitution at lines 327, 409, 462, 627, 648, 900, 906, and remove the now
   duplicate `mkdir` at 583. ~15 lines changed, touches six code blocks. Independent of other
   documents, but flag to the cross-document agent so `SOP_CONCOMPRA_NeSI.md` can be checked for
   the same split.
2. **Put every SLURM script under `--chdir` and delete the in-script `cd`.** Closes F-07. Four
   headers plus one new explanatory paragraph, ~25 lines. Depends on item 1 (the `--chdir` value is
   the settled path). Independent of other documents.
3. **Fix the array submission model.** Closes F-11 and half of F-10. Change line 644 to a
   placeholder, rewrite the submit block to derive the range from the manifest, add the
   manifest-vs-outputs check, and replace the RDP paragraph with the four-line change table.
   ~35 lines. Depends on items 1-2.
4. **Rewrite Step 1's data handling.** Closes F-02, F-05, F-22, and adds the controls callout
   (F-17). The transfer section, the `zcat -f` import loop with its check, and the controls
   blockquote. ~55 lines added, the largest single addition. Depends on item 1.
5. **Fix the counting and QC-interpretation layer.** Closes F-03, F-06, F-18. Replace the
   `grep -c` block, add the per-barcode read-count loop after both NanoPlot submissions, rewrite the
   "Total yield" bullet, and unify the retention thresholds at 60-85% / 30% in both places.
   ~30 lines. Depends on items 1-2.
6. **Harden the database setup.** Closes F-08, F-09. The `pip install --user` block with its
   `which osf` check, and the `ls species_taxid.fasta taxonomy.tsv` verification after each extract.
   ~20 lines. Depends on item 1. Two NEEDS-BENCH-CHECK items must be resolved on Mahuika first.
7. **Add the Emu smoke test and resolve `--type`.** Closes F-16, F-36, F-26. One new code block
   before the array submission, plus edits to the front-matter compatibility claim and the
   `--min-align-len` bullet. ~20 lines. Depends on item 3 and on running `emu abundance --help`.
8. **Rewrite the combining section.** Closes F-04, F-12, F-13, F-14, F-25. Reorder so the custom
   combiner leads and Option A becomes a closing subsection; patch the three code defects in the
   script; rewrite "What Emu outputs" to be format-neutral; add the unassigned-fraction note.
   ~60 lines changed. Depends on item 1 only, so it can proceed in parallel with items 4-7.
9. **Add the handoff section.** Closes F-15. The barcode-to-sample metadata block and the revised
   download instruction at the end of the document. ~30 lines added. Depends on item 8 (it follows
   the combiner output) and should be checked against `SOP_R_Analysis.md`'s expected inputs —
   **this is the one item that should not be finalised without reading Part 2.**
10. **Structural and consistency pass.** Closes F-19, F-20, F-21, F-23, F-24, F-27, and the S4
    block F-28 through F-35. Merge the two `#` titles, rewrite the roadmap, unify the SUP quality
    ranges, fix the `--mem` template, renumber the three "Step 1" sequences, fold the fourth
    NanoPlot interpretation block into Step 4, and sweep the small consistency items. ~50 lines
    scattered across the document. Do this last, once the structure has stopped moving. F-19's
    replacement range and F-21's runtime figure both need the bench checks resolved first.

---

CONTRACT: PASS

Re-run mechanically against the file rather than from memory, after a repair pass. Two defects in
the first version of this report are recorded below rather than quietly corrected.

- [x] **Ledger accounts for every heading in the file.** 33 headings, lines 1-927, counted with a
      fence-aware sweep (`awk '/^```/{f=!f;next} !f && /^#{1,6} /'`) so that `#`-prefixed comment
      lines inside code blocks are not miscounted as headings. The ledger has 33 data rows and they
      align 1:1 with those headings, in document order.
      *Correction:* the first version of this box claimed 34 headings and described the exclusions
      incoherently — "four matches excluded" followed by ten line numbers. The table itself was
      right; the arithmetic reported above it was not. It came from a naive `^#{1,4} ` grep that
      counted in-code comments, then a hand-count on top of it. This box is now derived from the
      file, not asserted.
- [x] **Every finding has a line-anchored verbatim quote.** 36/36.
- [x] **Every finding has a concrete Failure line.** 36/36.
- [x] **Every finding carries all seven fields in contract order** (`Where → Quote → Defect →
      Failure → Type → Confidence → Fix`). 36/36, verified by extracting the field sequence from
      each block and comparing against the contract string.
      *Correction:* the first version of this report omitted the `Defect` field from all nine S4
      findings (F-28 through F-36) and asserted `CONTRACT: PASS` regardless. The self-check had no
      box for field completeness, so nothing caught it — the skeleton was checked at section level
      and the finding blocks were checked by impression. The nine `Defect` lines have been added in
      contract position; no `Failure` or `Fix` text was altered.
- [x] **Every S1 and S2 has paste-ready replacement text.** 17/17 (4 S1, 13 S2), each `Fix` block
      containing a fenced code block or blockquoted replacement prose, not a description of one.
- [x] **Every `NEEDS-BENCH-CHECK` names the one check that settles it.** Five: F-08 (`pip install
      osfclient && which osf` on Mahuika), F-09 (`tar -tf silva.tar | head -3`), F-14 second half
      (`emu combine-outputs … --counts` then `grep -c unassigned`), F-16 (`emu abundance --help`),
      F-21 (`nn_seff` on a full-scale NanoPlot run).
- [x] **No proposed cut touches load-bearing content.** The only deletions proposed are the
      duplicate `nn_seff` gloss (F-28), one of three restatements of the same `--keep-counts`
      warning (F-32, with the strongest instance kept in full), and roadmap items describing another
      document (F-20).
- [x] **S4 count = 9** (F-28 through F-36), within the cap of 15.
- [x] **Sections match the required skeleton exactly, in order:** Document, Section ledger,
      Findings, Keep list, Gaps, Cross-document flags, Rewrite plan — nothing before or after.

Known deviation, accepted by the orchestrator and left unchanged: 19 finding summaries exceed the
ten-word cap. Each states the defect rather than the topic, which is the substantive requirement.
