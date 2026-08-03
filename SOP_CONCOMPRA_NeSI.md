*Taylor Lab | Consensus OTUs from Nanopore 16S*

# **CONCOMPRA Pipeline: Consensus OTUs on NeSI**

**v2.1** | last updated July 2026 | NeSI (SLURM) | Oxford Nanopore full-length 16S

This document covers the CONCOMPRA pipeline on NeSI Mahuika: installation, run configuration, submission, verification, post-processing (taxonomy, alignment, phylogeny), and preparing outputs for R. CONCOMPRA builds reference-free consensus OTUs rather than aligning reads to a reference. Its outputs feed the same R analysis (`SOP_R_Analysis.md`).

It **runs after `SOP_EMU_NeSI.md`, not instead of it**: it takes that pipeline's filtered reads as its input, builds its SILVA SINTAX database from the Emu SILVA bundle installed there, and uses the Emu taxonomy as its only validation check.

Paths use `<your_nesi_project_code>` and `<your_project>` placeholders. Substitute your own throughout.

### **Before you start**

This document assumes you have:

- **A NeSI account and project code**, and enough bash and SLURM to submit a job, read a `.err` file and check `squeue`. If you do not, work through Section 1 of `SOP_EMU_NeSI.md` first — it is the only document in this set that teaches the cluster, and this one does not repeat it.

- **Your Nanopore reads already basecalled, demultiplexed and quality/length-filtered**, as one per-sample `.fastq` file in a single directory. This document calls that directory `filtered/` throughout; it is the output of the read-filtering step in `SOP_EMU_NeSI.md`. CONCOMPRA does its own primer-chopping and `filtlong` quality pass on top of that filtering — it does not replace it.

- **A sample metadata sheet** as a `.csv`, one row per sample, sample ID in the first column, using exactly the sample IDs that appear in your fastq filenames.

This document does not cover basecalling, demultiplexing or read filtering.

---

## **Quick Roadmap: What You'll Do**

```
STAGE 1: Install (once per project)
   CONCOMPRA repo + conda env + SILVA SINTAX database
                    ↓
STAGE 2: Pre-flight
   Screen for duplicate reads → deduplicate if present
                    ↓
STAGE 3: Configure the run
   Symlink fastqs → directory_list.txt → primer_set.fa
                    ↓
STAGE 4: Run and verify
   Submit main.sh (SLURM) → check per-sample consensus on disk
                    ↓
STAGE 5: Post-process
   sintax taxonomy → MAFFT alignment → FastTree phylogeny
                    ↓
STAGE 6: Hand off to R
   Build concompra_for_R/ → phyloseq analysis (SOP_R_Analysis.md)
```

**The one thing to remember:** `main.sh` logs "consensus sequences generated" for every sample even when a step failed silently and produced nothing. Verify the consensus output on disk ([Verifying the run](#6-verifying-the-run)), never from the `.out` log.

---

## **1. Understanding your data**

CONCOMPRA turns your filtered Nanopore reads into **OTUs** — operational taxonomic units, groups of near-identical sequences that stand in for "a kind of organism" when you cannot put a species name to them. Where Emu asks *which known species are here* by matching each read to a reference database, CONCOMPRA asks *what distinct sequences are here*, whether or not any database knows them.

It never consults a reference to decide what counts as an OTU — that is what **reference-free**, or **de novo** ("from scratch"), means — so it can resolve novel or poorly-catalogued taxa that Emu can only return as "unclassified".

It gets there in four moves, and the output files are named after them:

- **Clustering.** Reads from one sample are grouped by sequence similarity (the algorithms are UMAP and OPTICS; you never call them directly). Each cluster is one candidate OTU.

- **Consensus.** For each cluster, `lamassemble` collapses its reads into a single best-estimate sequence — the **consensus** — averaging out per-read Nanopore errors.

- **Dereplication.** Identical consensus sequences from different samples are merged into one OTU, so a taxon seen in ten samples is one row, not ten.

- **Chimera detection.** A **chimera** is an artificial hybrid sequence formed during PCR, when a half-finished copy of one organism's DNA completes on another's template. It is not a real organism, so CONCOMPRA flags chimeras and sets them aside in a separate file.

The run produces an **OTU table** (OTUs in rows, samples in columns, counts in the cells) and a **consensus FASTA**. Post-processing (Section 7) then names each OTU against SILVA (**SINTAX** classification), aligns the sequences (**MAFFT**), and builds a tree (**FastTree**) so you can place novel OTUs next to their nearest known relatives.

Use it alongside Emu. Emu gives fast alignment-based taxonomy and relative abundance against curated databases; CONCOMPRA gives reference-free consensus sequences for novel or poorly-resolved taxa and for sequence-level work like trees and primer-mismatch checks.

| Pipeline | What it gives | Best for |
|---|---|---|
| Emu | Alignment-based taxonomy and relative abundance | Primary taxonomy, fast turnaround |
| CONCOMPRA | Reference-free consensus sequences (de novo OTUs) | Novel taxa, trees, sequence-level work |

Run both on the same deduplicated input and compare.

---

## **2. Installation**

Install CONCOMPRA and its conda environment once per project directory, then reuse them across runs and users on that project.

CONCOMPRA's tools are not available as NeSI modules, so you install them into a **conda environment** — a self-contained folder holding a specific version of every package the pipeline needs, isolated from the rest of the system. You build it once from the recipe shipped with CONCOMPRA (`CONCOMPRA.yml`), then `conda activate` it whenever you run the pipeline, much as you `module load` a NeSI tool.

### **Locations**

| Path | Contents |
|---|---|
| `/nesi/project/<your_nesi_project_code>/CONCOMPRA/` | Cloned repository |
| `/nesi/project/<your_nesi_project_code>/conda_envs/CONCOMPRA/` | Conda environment |
| `/nesi/project/<your_nesi_project_code>/databases/silva_emu_sintax/` | SILVA SINTAX database for post-processing |

### **Clone the repository**

```bash
cd /nesi/project/<your_nesi_project_code>/
git clone https://github.com/willem-stock/CONCOMPRA.git
cd CONCOMPRA
git log -1 --oneline   # record the commit you installed from
```

### **Build the conda environment**

NeSI blocks the Anaconda `defaults` channel. The upstream `CONCOMPRA.yml` lists it, so strip it before `conda env create` or the solve fails with a channel-access error. Use Miniforge3, not Miniconda3: Miniconda's base config re-adds the `defaults` channel and fails the solve regardless of the patch.

```bash
module purge
module load Miniforge3/25.3.1-0
source "$(conda info --base)"/etc/profile.d/conda.sh

# Strip the defaults channel (keeps a .bak)
sed -i.bak '/^[[:space:]-]*defaults[[:space:]]*$/d' CONCOMPRA.yml

conda env create \
    -f CONCOMPRA.yml \
    -p /nesi/project/<your_nesi_project_code>/conda_envs/CONCOMPRA \
    --solver=libmamba
```

The solve typically takes 5–15 minutes and prints little while it resolves dependencies. A long silent pause is normal here, not a hang — do not interrupt it.

### **Verify the environment**

```bash
conda activate /nesi/project/<your_nesi_project_code>/conda_envs/CONCOMPRA
conda list -p /nesi/project/<your_nesi_project_code>/conda_envs/CONCOMPRA
```

Confirm the upstream pins are present: `filtlong 0.2.1`, `minimap2 2.1.1`, `python 3.11`, `numba 0.60.0`. The environment does not include `medaka`, `racon`, or `samtools`; CONCOMPRA uses `lamassemble` for consensus, so their absence is correct and you should not add them.

A missing pin, or a solver error instead of a package list, means the `defaults`-channel strip or the Miniforge requirement above was not met. Remove the half-built environment (`conda env remove -p /nesi/project/<your_nesi_project_code>/conda_envs/CONCOMPRA`) and rebuild before going on; a partially-solved environment fails silently mid-run.

**Optional —** an activation alias for `~/.bashrc`:

```bash
alias lab_concompra='module purge && \
    module load Miniforge3/25.3.1-0 && \
    source "$(conda info --base)"/etc/profile.d/conda.sh && \
    export PYTHONNOUSERSITE=1 && \
    conda activate /nesi/project/<your_nesi_project_code>/conda_envs/CONCOMPRA'
```

`PYTHONNOUSERSITE=1` stops user-installed packages in `~/.local/lib/python*` from leaking into the environment.

### **SILVA SINTAX database**

Post-processing classifies OTUs against SILVA with `vsearch --sintax`, which needs a SINTAX-formatted reference. No canonical SINTAX-formatted SILVA exists, so build one from Emu's SILVA bundle. Using Emu's bundle keeps the SILVA release identical to the parallel Emu workflow. Build it once ([Appendix A](#appendix-a-silva-sintax-database-build)) and store it in the project directory so every run points at one copy:

```
/nesi/project/<your_nesi_project_code>/databases/silva_emu_sintax/
├── silva_sintax.fa                   FASTA with SINTAX-style taxonomy headers
├── silva_sintax.udb                  Indexed UDB (what vsearch --sintax reads)
├── reformat_silva_for_sintax.py      Reformatter (Emu SILVA to SINTAX format)
└── README.md                         Source SILVA release, build date, record counts
```

Point post-processing at this project-directory UDB, not a copy under `nobackup`, which is purged on a rolling basis.

---

## **3. Pre-flight: Screen for Duplicate Reads**

A Nanopore run that was interrupted and restarted can have its POD5 files merged such that reads are basecalled twice, producing FASTQs with duplicated read IDs. Emu tolerates this silently, but CONCOMPRA's `filtlong 0.2.1` aborts on duplicate read names, and the run then fails silently (see [Empty consensus output](#empty-consensus-output)). The screen is cheap, so run it on every new dataset before processing.

### **Screen**

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

### **Deduplicate**

POD5 read IDs are globally-unique UUIDs, so duplicate IDs come from file-level duplication, not collisions between distinct reads. Removing by read name keeps one copy per physical read and is lossless.

This step needs `seqkit`, which is not on a bare login shell. It is in the CONCOMPRA conda environment you built in Section 2 (`conda activate /nesi/project/<your_nesi_project_code>/conda_envs/CONCOMPRA`); in a fresh shell instead, `module load SeqKit/2.4.0` (run `module spider SeqKit` for the version currently installed).

```bash
mkdir -p filtered_dedup
for f in filtered/*.fastq; do
    seqkit rmdup -n "$f" -o filtered_dedup/$(basename "$f")
done

# Confirm zero duplicates remain, in every sample
for f in filtered_dedup/*.fastq; do
    echo "$(basename "$f")  $(awk 'NR%4==1{print $1}' "$f" | sort | uniq -d | wc -l)"
done
```

Every line must end in `0`. The previous form of this check named a single literal `filtered_dedup/sample.fastq`, which does not exist — `wc -l` then printed `0` for a file it never read, which looks exactly like a clean result.

### **Record run metadata**

Capture in a `RUN_METADATA.md` beside the fastqs:

- Flowcell and chemistry (e.g. `FLO-PRO114M`, `SQK-NBD114.96 + EXP-PBC096`).
- Basecaller and model (e.g. `dorado v1.0.2`, `dna_r10.4.1_e8.2_400bps_sup@v5.0.0`).
- Whether the run was interrupted or restarted, and how the POD5s were merged.
- The duplicate-screen result.

---

## **4. Run Configuration**

### **Directory layout**

```
/nesi/nobackup/<your_nesi_project_code>/<your_project>/
├── 05_concompra.sh               # main run submission (Section 5)
├── 07_concompra_postprocess.sh   # post-processing submission (Section 7)
├── logs/                         # post-processing logs
├── concompra/                    # CONCOMPRA run directory
│   ├── *.fastq                   # symlinks into filtered_dedup/
│   ├── directory_list.txt        # run configuration, sourced by main.sh
│   ├── primer_set.fa             # primer sequences (head/tail named)
│   └── logs/                     # main-run logs
├── concompra_for_R/              # R-ready folder (Section 8, built after Section 7)
└── filtered_dedup/               # deduplicated input
```

Keep the `concompra/` run directory separate from the filtered fastqs; CONCOMPRA writes intermediates next to its inputs.

### **Symlink the input fastqs**

Symlink rather than copy. Use `realpath` so the links resolve after CONCOMPRA changes directory mid-run.

```bash
mkdir -p concompra/
cd concompra/
for f in ../filtered_dedup/*.fastq; do
    ln -s "$(realpath "$f")" .
done
ls *.fastq | wc -l   # should equal your sample count
```

### **Run configuration file**

Despite its name, `directory_list.txt` is **not** a list of fastq paths — it is a shell fragment that `main.sh` runs with `source directory_list.txt`, and it holds every parameter the run needs. `main.sh` finds the input reads by globbing `*.fastq` in the run directory (the symlinks you just made), not from this file. Copy the template out of the repo and edit it in place:

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

One `directory_list.txt` serves the whole run; there are no per-sample entries. Confirm the edits took:

```bash
grep -E '^(TEMPLATE_DIR|PRIMER_SET|MIN|MAX|THREADS)=' directory_list.txt
```

### **Primer file**

`primer-chop` decides which end of each read is the 5' end from the **names** of the two primers: the forward (head) primer's header must contain `head`, and the reverse (tail) primer's header `tail` (case-insensitive, substring match). Headers like `>27F` / `>1492R` contain neither, so `primer-chop-analyze` aborts with `RuntimeError: bad primer name`. Because `main.sh` has no `set -e`, the run continues regardless, still logs "consensus sequences generated", and leaves an empty `otu_table.csv` — so check the `.err` log, not the `.out`.

CONCOMPRA searches for primers as they appear on the forward strand of the amplicon. For 1492R this means the sense-strand sequence `AAGTCGTAACAAGGTAACC`, not the reverse-complement `GGTTACCTTGTTACGACTT` written in most protocols. The wrong orientation gives almost no primer hits and an empty downstream funnel. Write the file into the run directory as `primer_set.fa` (the path you set as `PRIMER_SET`):

```bash
cd /nesi/nobackup/<your_nesi_project_code>/<your_project>/concompra/
cat > primer_set.fa <<'EOF'
>head_27F
AGAGTTTGATCCTGGCTCAG
>tail_1492R
AAGTCGTAACAAGGTAACC
EOF
```

For other primer sets, apply the same two rules: name the forward primer `head…` and the reverse `tail…`, both as they appear on the forward strand, 5' to 3'.

### **Threads**

`THREADS` in `directory_list.txt` sets both outer parallelism (samples run concurrently) and inner parallelism (threads per sample). For a 16-CPU allocation, `THREADS=4` gives 4 samples at a time with 4 threads each. This may run faster than `THREADS=16` (which would instead run 16 samples at once, 16 threads each — heavy oversubscription on a 16-CPU node) on many-sample datasets; test it on a run before committing.

To change parameters not exposed through the config files, copy `main.sh` from `/nesi/project/<your_nesi_project_code>/CONCOMPRA/scripts/` into the run directory and edit that copy.

---

## **5. Submitting the Run**

**Resources.** For roughly 192 samples at ~80k reads per sample after filtering:

| Resource | Value |
|---|---|
| Walltime | 48h |
| Memory | 80 G |
| CPUs | 16 |

A 192-sample run can take a day or more, so 48h leaves headroom. Per-sample, about 45% of reads survive primer-chop and `filtlong` then keeps the top 80% by quality, so a sample of 80,000 reads enters clustering with roughly 29,000.

**Keep the per-sample intermediates.** `main.sh` ends with `rm -rf temporary`, and `temporary/` holds the per-sample consensus files that localise a silent failure to a step. Decide this before your first submission, not after: copy `main.sh` into the run directory and comment that line out.

```bash
cd /nesi/nobackup/<your_nesi_project_code>/<your_project>/concompra/
cp /nesi/project/<your_nesi_project_code>/CONCOMPRA/scripts/main.sh .
sed -i 's|^\([[:space:]]*\)rm -rf temporary|\1# rm -rf temporary   # kept for Section 6|' main.sh
grep -n 'rm -rf temporary' main.sh    # must show the line commented out
```

Then have `05_concompra.sh` run your copy — `bash ./main.sh` — rather than the one in the repository. Section 6's primary check works either way; this only buys you the finer diagnosis when something does fail. Delete `temporary/` yourself once the analysis is final (Section 9).

**Script.** Save as `05_concompra.sh` in the parent of `concompra/`. The job runs inside the `concompra/` run directory (`#SBATCH --chdir`), so its log paths are relative to that directory — create `concompra/logs/` first:

```bash
mkdir -p /nesi/nobackup/<your_nesi_project_code>/<your_project>/concompra/logs
```

```bash
#!/bin/bash
#SBATCH --job-name concompra_<your_project>
#SBATCH --account <your_nesi_project_code>
#SBATCH --chdir /nesi/nobackup/<your_nesi_project_code>/<your_project>/concompra
#SBATCH --time 48:00:00
#SBATCH --cpus-per-task 16
#SBATCH --mem 80G
#SBATCH --output logs/concompra_%j.out
#SBATCH --error logs/concompra_%j.err

set -euo pipefail

module purge
module load Miniforge3/25.3.1-0
source "$(conda info --base)"/etc/profile.d/conda.sh
export PYTHONNOUSERSITE=1
conda activate /nesi/project/<your_nesi_project_code>/conda_envs/CONCOMPRA

bash ./main.sh
```

`main.sh` takes no arguments: it `source`s `directory_list.txt` and reads `primer_set.fa` from the working directory, which `--chdir` set to `concompra/`. `bash ./main.sh` runs your edited copy — the one with `rm -rf temporary` commented out — not the repo copy. It finds its sub-scripts through `TEMPLATE_DIR`, so the job needs nothing from your login shell.

The wrapper's `set -euo pipefail` guards its own setup only. `main.sh` runs as a separate process and keeps its own deliberately lenient error handling — which is why Section 6 verifies the outputs on disk rather than trusting the exit code.

**Submit.**

```bash
cd /nesi/nobackup/<your_nesi_project_code>/<your_project>/
sbatch 05_concompra.sh
squeue -u $USER
```

---

## **6. Verifying the Run**

`main.sh` has no `set -e`, so a failure in an inner step (filtlong, primer-chop, OPTICS) does not stop the script or change its exit code, and it still logs "consensus sequences generated for X" for every sample. Do not trust the `.out` log; check the outputs on disk.

### **Per-sample verification**

A sample that failed silently contributes zero reads to the OTU table, and `results/otu_table.csv` exists whether or not you kept `temporary/`. Use it as the gate:

```bash
cd /nesi/nobackup/<your_nesi_project_code>/<your_project>/concompra/

# Per-sample read totals, ascending. Zero means the sample produced nothing.
awk -F, 'NR==1 {for(i=2;i<=NF;i++) n[i]=$i; next}
              {for(i=2;i<=NF;i++) s[i]+=$i}
         END  {for(i=2;i<=NF;i++) print s[i] "\t" n[i]}' \
  results/otu_table.csv | sort -n | head -20

# Sample count in the table must match the sample count you submitted
echo "in otu_table: $(head -1 results/otu_table.csv | awk -F, '{print NF-1}')"
echo "submitted:    $(ls *.fastq | wc -l)"
```

Both counts must agree, and no sample may total zero. Any shortfall is a silent failure; see [Troubleshooting](#9-troubleshooting).

If you kept `temporary/` (see Section 5), you can also check the per-sample consensus files directly, which localises *which* step failed rather than only telling you that one did:

```bash
find temporary -name "*.consensus.fasta" -exec wc -l {} \; | sort -n | head -20
```

Do not make this your only check. `main.sh` deletes `temporary/` at the end of every successful run, so on a healthy run `find` returns nothing and the check reads as a failure — or, worse, as a clean result if you only counted the zero-line files.

### **Output files**

In `results/`:

| File | Contents |
|---|---|
| `all_consensus.fasta` | All per-sample consensus, pre-chimera and pre-dereplication |
| `clustered_consensus.fasta` | Consensus after dereplication |
| `noglobal_nolocalchim.consensus.sequences.fas` | Chimera-filtered; the working fasta for downstream |
| `chimeric_consensus.sequences.fas` | Removed as chimeric; keep for QC |
| `otu_table.csv` | OTU × sample count matrix (rows = OTUs, columns = samples) |
| `cluster_plots.pdf` | Clustering diagnostic plots |

```bash
# Sequences in the working fasta
grep -c "^>" results/noglobal_nolocalchim.consensus.sequences.fas

# Per-sample read totals, ascending; flags failed extractions and negative controls
awk -F, 'NR==1 {for(i=2;i<=NF;i++) n[i]=$i; next}
              {for(i=2;i<=NF;i++) s[i]+=$i}
         END  {for(i=2;i<=NF;i++) print s[i] "\t" n[i]}' \
  results/otu_table.csv | sort -n | head -10
```

Zero-count samples are not pipeline errors; decide per sample whether to keep them as controls or drop them.

A non-empty `clustered_consensus.fasta` with an empty chimera-filtered fasta means every sequence was called chimeric — usually a sign the input was near-empty or badly degraded rather than a real chimera storm, so check the `.err` log for upstream failures first (Section 6). The chimera step is not exposed through `directory_list.txt`; to change its thresholds you edit the pipeline script directly, the same way you would for any parameter not in the config ([Threads](#threads)).

### **Cross-check against Emu**

For one or two samples, compare the dominant taxa from Emu with the closest matches for the corresponding CONCOMPRA consensus sequences. Investigate large disagreements before moving to post-processing.

---

## **7. Post-processing: Taxonomy, Alignment, Phylogeny**

Post-processing answers three questions about the OTUs you just built, and runs all three in one short job:

- **What is each OTU?** `vsearch --sintax` compares each consensus sequence to the SILVA reference and assigns a name down to the most confident rank — this is **taxonomic classification**.

- **How do the sequences line up?** **MAFFT** performs a multiple-sequence **alignment**: it stacks the sequences so equivalent positions sit in the same column, which is the input a tree needs.

- **How are they related?** **FastTree** turns that alignment into a **phylogenetic tree**, so you can place novel OTUs next to their nearest known relatives and, later, compute phylogenetic diversity.

One SLURM job filters the chimera-clean fasta to OTUs that have reads, classifies them with `vsearch --sintax`, aligns with MAFFT, and builds a FastTree phylogeny. Run it as a SLURM job rather than on a login node: the SILVA UDB needs about 3 GB of RAM and MAFFT adds more. Runtime is typically under a minute.

**Resources.**

| Resource | Value |
|---|---|
| Walltime | 2h |
| Memory | 16 G |
| CPUs | 16 |

**Script.** Save as `07_concompra_postprocess.sh` in the run directory (the same parent as `05_concompra.sh`). Create the log directory first:

```bash
mkdir -p /nesi/nobackup/<your_nesi_project_code>/<your_project>/logs
```

```bash
#!/bin/bash
#SBATCH --job-name concompra_postprocess
#SBATCH --account <your_nesi_project_code>
#SBATCH --chdir /nesi/nobackup/<your_nesi_project_code>/<your_project>
#SBATCH --time 02:00:00
#SBATCH --cpus-per-task 16
#SBATCH --mem 16G
#SBATCH --output logs/postprocess_%j.out
#SBATCH --error logs/postprocess_%j.err

# set -euo pipefail: unlike main.sh, this script aborts on first error
set -euo pipefail

BASE=/nesi/nobackup/<your_nesi_project_code>/<your_project>
RESULTS=$BASE/concompra/results
SILVA_UDB=/nesi/project/<your_nesi_project_code>/databases/silva_emu_sintax/silva_sintax.udb

module purge
module load VSEARCH/2.21.1-GCC-11.3.0
module load MAFFT/7.505-gimkl-2022a-with-extensions
module load FastTree/2.1.11-GCC-11.3.0
module load seqtk/1.4-GCC-11.3.0

# 1. Filter the fasta to OTUs that have counts in the OTU table
tail -n +2 "$RESULTS/otu_table.csv" | cut -d',' -f1 > "$RESULTS/otus_with_counts.txt"
seqtk subseq \
    "$RESULTS/noglobal_nolocalchim.consensus.sequences.fas" \
    "$RESULTS/otus_with_counts.txt" \
    > "$RESULTS/consensus_in_otutable.fas"

# 2. Taxonomy
vsearch --sintax "$RESULTS/consensus_in_otutable.fas" \
        --db "$SILVA_UDB" \
        --tabbedout "$RESULTS/consensus.sintax" \
        --sintax_cutoff 0.8 \
        --threads 16

# 3. Alignment
mafft --auto --thread 16 \
      "$RESULTS/consensus_in_otutable.fas" \
      > "$RESULTS/consensus_aligned.fas"

# 4. Phylogeny
FastTree -gtr -nt "$RESULTS/consensus_aligned.fas" \
    > "$RESULTS/consensus.tree"
```

**Submit.**

```bash
cd /nesi/nobackup/<your_nesi_project_code>/<your_project>/
sbatch 07_concompra_postprocess.sh
```

### **Notes on the steps**

**Step 1.** The chimera-clean fasta holds every sequence that survived chimera detection; the OTU table holds every OTU with reads, including some chimera detection later removed. The intersection is the working set. Fewer sequences than OTU-table rows is expected. Read retention in the 70 to 90% range is typical for Nanopore 16S even when the OTU count drops further, because the filter mostly removes low-abundance OTUs.

**Step 2.** `vsearch --sintax` writes a 4-column file: query ID; all hits with confidence scores; strand; and the cutoff-filtered assignment. For phyloseq and any downstream use, take column 4, not column 2. Column 2 lists every hit at every confidence level; column 4 applies the cutoff. Using column 2 silently corrupts taxonomy at low-confidence ranks, usually genus and species.

The 0.8 cutoff is the standard SINTAX bootstrap threshold (a 0–1 confidence score from repeated resampling; higher is more reliable); a higher cutoff yields more `unclassified` calls but more reliable assignments.

**Step 4.** `FastTree -gtr -nt` builds an approximate **maximum-likelihood** tree — the branching pattern most consistent with the aligned sequences — under the **GTR** model, the standard general model of how one DNA base substitutes for another. By default it reports **SH-like local supports**: a 0–1 score on each branch estimating how well the data back that split, higher being more trustworthy. For the more familiar resample-based **bootstrap** supports instead, add `-boot 1000`.

### **Verifying the outputs**

```bash
grep -c ">" results/consensus_in_otutable.fas    # OTU count
wc -l results/consensus.sintax                    # one row per OTU
wc -l results/consensus.tree                      # one line for Newick
```

All four outputs should have content. An empty sintax file usually means the `SILVA_UDB` path is wrong; an empty alignment means MAFFT received an empty input from step 1.

---

## **8. Preparing for R / phyloseq**

Assemble four files plus your metadata into a clean folder before opening R.

### **The R-ready folder**

```
<your_project>/concompra_for_R/
├── otu_table.csv           Filtered to chimera-clean OTUs; .CONCOMPRA and _filtered suffixes stripped
├── otu_sequences.fasta     Chimera-clean, in-OTU-table consensus sequences
├── otu_taxonomy.sintax     sintax output (column 4)
├── otu_tree.nwk            FastTree output
├── sample_metadata.csv     Your sample sheet (added manually)
└── README.md               Provenance
```

### **Building it**

Filter the OTU table to the chimera-clean intersection so the table, sequences, taxonomy, and tree all cover the same OTUs. Otherwise phyloseq joins leave orphaned rows. The lab's `assemble_R_inputs.py` does this. A self-contained equivalent:

```bash
RUN=/nesi/nobackup/<your_nesi_project_code>/<your_project>
mkdir -p $RUN/concompra_for_R
cd $RUN/concompra_for_R

cp ../concompra/results/consensus_in_otutable.fas  otu_sequences.fasta
cp ../concompra/results/consensus.sintax           otu_taxonomy.sintax
cp ../concompra/results/consensus.tree             otu_tree.nwk

# OTU table: keep chimera-clean OTUs, strip the .CONCOMPRA column suffix
python <<'PY'
from Bio import SeqIO
keep = {rec.id for rec in SeqIO.parse("otu_sequences.fasta", "fasta")}
with open("../concompra/results/otu_table.csv") as fin, \
     open("otu_table.csv", "w") as fout:
    header = fin.readline().rstrip("\n").split(",")
    # Strip both tool-added suffixes. The input fastqs came from SOP_EMU_NeSI.md's
    # filtered/ directory, so their basenames carry _filtered; Emu's own tables do
    # not. Leave it on and the same physical sample is called barcode01_filtered
    # here and barcode01 there, so one metadata sheet cannot serve both pipelines
    # and the two results cannot be compared sample by sample.
    header = [h.replace(".CONCOMPRA", "").replace("_filtered", "") for h in header]
    fout.write(",".join(header) + "\n")
    for line in fin:
        if line.split(",", 1)[0] in keep:
            fout.write(line)
PY
```

### **Checking sample IDs**

CONCOMPRA's `.CONCOMPRA` column suffix and the `_filtered` suffix inherited from the input filenames both break joins with the metadata, and both must be gone before the IDs will match Emu's. After stripping them, confirm:

```bash
head -1 otu_table.csv | tr ',' '\n' | tail -n +2 | sort > /tmp/otu_samples.txt
cut -d, -f1 sample_metadata.csv | tail -n +2 | sort > /tmp/meta_samples.txt
diff /tmp/otu_samples.txt /tmp/meta_samples.txt   # no output means they match
```

### **Building the phyloseq object**

`SOP_R_Analysis.md` opens on a tab-separated table with taxonomy in named rank columns. CONCOMPRA produces a comma-separated OTU table, taxonomy in a separate SINTAX file and a Newick tree, so **convert the folder once, here** — Part 2 has no code for any of the three formats and will not tell you it is looking at the wrong shape:

```r
library(phyloseq); library(phangorn); library(ape)

otu  <- read.csv("otu_table.csv", row.names = 1, check.names = FALSE)

# sintax: column 4 is the cutoff-filtered assignment. Column 2 lists every hit at
# every confidence and using it silently corrupts genus and species.
sx   <- read.delim("otu_taxonomy.sintax", header = FALSE,
                   row.names = 1, sep = "\t")[, 3, drop = FALSE]
RANK <- c(superkingdom = "d", phylum = "p", class = "c", order = "o",
          family = "f", genus = "g", species = "s")
tax  <- t(vapply(strsplit(as.character(sx[[1]]), ","), function(p) {
    vapply(RANK, function(k) {
        hit <- grep(paste0("^", k, ":"), p, value = TRUE)
        if (length(hit)) sub("^[a-z]:", "", hit[1]) else ""
    }, character(1))
}, character(length(RANK))))
rownames(tax) <- rownames(sx)

tree <- midpoint(read.tree("otu_tree.nwk"))   # FastTree output is unrooted

# Same OTUs in all three, in the same order — Part 2 indexes them positionally.
keep <- Reduce(intersect, list(rownames(otu), rownames(tax), tree$tip.label))
stopifnot(length(keep) > 0)
write.table(cbind(tax_id = keep, tax[keep, ], otu[keep, ]),
            "counts_concompra.tsv", sep = "\t", quote = FALSE, row.names = FALSE)
saveRDS(drop.tip(tree, setdiff(tree$tip.label, keep)), "tree_concompra.rds")
```

`counts_concompra.tsv` is now in the shape Part 2's data-loading step (Section 3) describes: substitute its filename for `emu-combined-counts_silva.tsv` there. The rank names are Part 2's (`superkingdom` … not `Domain`), which is what its barplot and `tax_level = "genus"` code expects. Keep `tree_concompra.rds`: Part 2 does not use it, but it lets you add phylogenetic-diversity analyses (UniFrac, Faith's PD) yourself if you want them.

Two things Part 2 does not know about CONCOMPRA output:

- **Counts are integers already.** Part 2's `round()` step is a no-op here; leave it in, and the relative-abundance guard above it will pass.

- **Prevalence filtering.** Low-prevalence OTUs from per-sample consensus are often genuine rare taxa, so Part 2's `prv_cut = 0.10` — tuned for Illumina **ASV** data (amplicon sequence variants, the exact-sequence features short-read pipelines call, the short-read counterpart of these consensus OTUs) — may over-filter here. **Start at `prv_cut = 0.05`** (half the Illumina default), record what you used, and set `prv_cut = 0` to disable prevalence filtering entirely when rare taxa are the study's point.

**Template.** CONCOMPRA's `CONCOMPRA_local_postprocessing.R` in the upstream repo is a starting point; adapt its paths to this folder.

---

## **9. Troubleshooting**

### **Empty consensus output**

Usually duplicate read IDs in the input. `filtlong 0.2.1` aborts on the first duplicate read name; the run then continues on empty input, producing OPTICS "empty vocabulary" errors and empty consensus files. Check the `.err` log for filtlong duplicate-name errors, run the [duplicate screen](#screen), and if duplicates are present [deduplicate](#deduplicate) and re-run. Do not replace or downgrade filtlong; its version is pinned for compatibility.

Other causes:

- A mis-configured `directory_list.txt` ([Run configuration file](#run-configuration-file)) — an unset `MIN`/`MAX` discards every read, and an unset `TEMPLATE_DIR`/`PRIMER_SET` breaks the run silently.
- Primer headers not named `head`/`tail` ([Primer file](#primer-file)), which leaves almost no reads after primer-chop.
- Too few reads per sample for clustering.

### **Empty sintax output**

Almost always a wrong `SILVA_UDB` path. The post-processing script uses `set -euo pipefail`, so it stops on the vsearch error; check the `.err` log for `unable to open`. An empty input fasta means [verification](#6-verifying-the-run) was skipped.

### **medaka, racon, or samtools appear to be missing**

They are deliberately not in the environment. CONCOMPRA uses `lamassemble`, not medaka or racon. Adding them does nothing useful and can cause dependency conflicts.

### **A run is stuck or slow**

```bash
ls -lhtr temporary/ | tail -20      # most recent activity
du -sh temporary/*/ | sort -h | tail # uneven sizes can flag a stuck sample
```

If one sample dominates the wall-clock time, check its read count; an outlier may need a tuned `THREADS` value ([Threads](#threads)) or its own run.

---

## **10. Maintenance**

### **Updating CONCOMPRA**

`minimap2` is pinned to 2.1.1 by upstream; do not change it. To update the code without touching the environment:

```bash
cd /nesi/project/<your_nesi_project_code>/CONCOMPRA
git fetch
git log HEAD..origin/main --oneline
git pull
```

Rebuild the environment only if `CONCOMPRA.yml` changed materially. Build a dated environment alongside the current one, verify it on a known dataset, switch the activation alias and project scripts over, and keep the previous environment for a month before deleting it.

### **The temporary directory**

CONCOMPRA deletes `temporary/` on a successful run. Section 5 covers commenting that out before your first run to keep the per-sample intermediates for debugging. Once your analysis is final, delete the directory yourself:

```bash
cd /nesi/nobackup/<your_nesi_project_code>/<your_project>/concompra/
rm -rf temporary/
```

Keep `directory_list.txt`, `primer_set.fa`, the SLURM scripts, `results/`, and `concompra_for_R/`.

---

## **Appendix A: SILVA SINTAX Database Build**

Build the database once and store it in the project directory.

### **The reformatter**

`vsearch --sintax` needs headers in the form `>id;tax=d:Domain,p:Phylum,...;`. Emu's headers are not in this form, for example:

```
>1:emu-silva:1 ['dada2-silva_1 Bacteria;Proteobacteria;...;Pseudomonas;amygdali;']
```

`reformat_silva_for_sintax.py` extracts the bracketed lineage, splits it into seven ranks (domain to species), joins genus and species into a binomial (`amygdali` becomes `Pseudomonas_amygdali`), drops empty ranks, filters non-informative species labels (`phage`, `metagenome`, `uncultured`, `sp.`), and replaces spaces, commas, and semicolons in names with underscores.

The script is committed to this repository as [`reformat_silva_for_sintax.py`](reformat_silva_for_sintax.py). It takes `IN.fasta OUT.fasta [--limit N]`, rewrites only the headers (sequences pass through unchanged), and prints a records-in / records-out count so you can confirm none were dropped.

### **Build**

```bash
# 1. Reformat (about 7 seconds for ~412k records; expect 0 dropped).
#    Copy the reformatter into the database directory, then cd to the SILVA
#    bundle SOP_EMU_NeSI.md installed — the directory that holds Emu's
#    species_taxid.fasta (its SILVA database download). If you do not have it,
#    build it via SOP_EMU_NeSI.md's database step first.
cp reformat_silva_for_sintax.py /nesi/project/<your_nesi_project_code>/databases/silva_emu_sintax/
cd /nesi/project/<your_nesi_project_code>/databases/emu/silva/   # the Emu SILVA bundle
python /nesi/project/<your_nesi_project_code>/databases/silva_emu_sintax/reformat_silva_for_sintax.py \
    species_taxid.fasta silva_sintax.fa

# Test on a subset first if needed:
#   python /nesi/project/<your_nesi_project_code>/databases/silva_emu_sintax/reformat_silva_for_sintax.py \
#       species_taxid.fasta test.fa --limit 100

# 2. Index (a few minutes; UDB is 500 MB to 1 GB)
module load VSEARCH/2.21.1-GCC-11.3.0
vsearch --makeudb_usearch silva_sintax.fa --output silva_sintax.udb

# 3. Install
mv silva_sintax.fa silva_sintax.udb \
   /nesi/project/<your_nesi_project_code>/databases/silva_emu_sintax/
```

Confirm the file is present before reformatting: `ls species_taxid.fasta` should list it; "No such file" means you are in the wrong directory or the Emu SILVA database was never downloaded.

Record in the directory's `README.md`: source SILVA release and Emu bundle version, build date, reformatter commit, and record counts in and out (they should match).

### **Refreshing for a new SILVA release**

Build into a dated staging directory beside the current one, update its README, validate by re-running a known dataset's post-processing and diffing the taxonomy against the previous run, then swap the staging directory into place. Keep the old version for at least one analysis cycle.

---

## **Appendix B: References**

CONCOMPRA. Stock W. et al. (2025). *CONCOMPRA: consensus from Oxford Nanopore communities for microbial phylogenetic resolution and abundance.* Briefings in Bioinformatics. doi:10.1093/bib/bbae642. Repo: https://github.com/willem-stock/CONCOMPRA

SINTAX. Edgar R.C. (2016). *SINTAX: a simple non-Bayesian taxonomy classifier for 16S and ITS sequences.* bioRxiv. doi:10.1101/074161. vsearch: https://github.com/torognes/vsearch

SILVA. Quast C. et al. (2013). *The SILVA ribosomal RNA gene database project.* Nucleic Acids Res. doi:10.1093/nar/gks1219

MAFFT. Katoh K., Standley D.M. (2013). *MAFFT version 7.* Mol Biol Evol. doi:10.1093/molbev/mst010

FastTree. Price M.N., Dehal P.S., Arkin A.P. (2010). *FastTree 2.* PLoS ONE. doi:10.1371/journal.pone.0009490

POD5 specification: https://software-docs.nanoporetech.com/pod5/latest/specification/

NeSI Mahuika documentation: https://docs.nesi.org.nz
