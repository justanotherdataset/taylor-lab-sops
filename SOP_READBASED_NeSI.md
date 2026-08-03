*Taylor Lab | Read-Based Shotgun Metagenomics SOP*

# **Read-Based Shotgun Metagenomics: Taxonomy and Function on NeSI**

**v3.0** | last updated July 2026 | NeSI (SLURM) | Illumina paired-end | human-associated samples

This document takes Illumina shotgun reads to taxonomic and functional profiles without assembling anything. Reads are matched directly against reference databases: MetaPhlAn 4 for taxonomy, HUMAnN for gene families and pathways. The statistics then run on `SOP_R_Analysis.md`, with Section 13 below listing what changes because the input is relative abundance rather than counts.

Illumina sequences each fragment from both ends, so every sample arrives as two files — `_R1` and `_R2` — whose paired reads are called *mates*; the workflow keeps or discards the two together throughout.

**This SOP is for human-associated samples** — gut, skin, oral, nasal, respiratory. MetaPhlAn's marker genes are built from human-associated taxa, so the workflow does not transfer to animal or environmental samples. If you need novel genomes rather than a profile of known ones, you need assembly and binning, which this repo does not cover; see the [Genomics Aotearoa Metagenomics Summer School](https://genomicsaotearoa.github.io/metagenomics_summer_school/).

**This SOP does not re-teach the cluster.** It uses bash, modules, `sbatch` and array jobs without explaining them. If you have not used them, work through `SOP_EMU_NeSI.md` Sections 1–2 first — Section 1 starts from `pwd` and teaches the cluster with no command-line experience assumed, and Section 2 covers the data concepts (FASTQ files, quality scores).

---

## **Quick Roadmap: What You'll Do**

```
STAGE 1: Plan (before sequencing)
   Ethics and governance → control design → depth budget
                    ↓
STAGE 2: Set up
   Preflight checks → directories and manifest → databases
                    ↓
STAGE 3: Clean the reads
   QC → trim + remove PhiX → QC again → deplete host reads
                    ↓
STAGE 4: Check before committing compute
   Read accounting → depth gates → STOP and review
                    ↓
STAGE 5: Profile
   MetaPhlAn 4 (taxonomy) → HUMAnN (function)
                    ↓
STAGE 6: Assemble tables
   Merge → normalise → split stratified from unstratified
                    ↓
STAGE 7: Screen and analyse
   Contamination screening → statistics (SOP_R_Analysis.md + Section 13)
```

Sections 1 and 2 happen before you generate data or load a module. Section 8 is a deliberate stop: review it before spending compute on Sections 9 and 10, which are by far the most expensive steps.

---

## **1. Before You Generate Data**

Three things cannot be fixed after sequencing: your ethics coverage, your controls, and your sequencing depth. Read this section before you send samples away.

### **Governance**

Host depletion reduces identifiability. It does not remove it. Residual human reads in gut metagenomes have been used to re-identify individuals against matched genotype data at 93.3% sensitivity, and to infer genetic sex and ancestry (Tomofuji et al. 2023, *Nature Microbiology*).

Treat host-depleted FASTQ files as controlled-access data unless your ethics approval explicitly permits open release. Derived tables — abundance profiles, pathway tables — are normally shareable. Confirm your ethics coverage and any Māori data sovereignty obligations before you generate the data, not when a journal asks where it is deposited.

### **Controls**

Controls are collected at the bench and cannot be added later. Aim for at least one control per four samples, sequenced in the same run and listed in `samples.txt` alongside the real samples. They are mandatory for skin, nasal, BAL (bronchoalveolar lavage, a saline wash of the lung) and any other low-biomass sample type, because contamination screening (Section 12) is impossible without them.

| Control | What it catches |
| --- | --- |
| Negative extraction blank | Contamination from reagents and extraction kits |
| No-template library control | Contamination introduced during library prep |
| Sampling control (blank swab or vessel) | Contamination picked up during collection |
| Positive mock community | Whether the pipeline is working — and the only way to detect over-removal in Section 7 |

The mock community earns its place twice over. It tells you that the pipeline finds what is there, and it is the only check on whether host depletion is deleting genuine microbial reads.

### **Depth**

Budget depth on the reads that survive trimming and host depletion, not on what the sequencer produces. The table below is the clean depth you need to end up with:

| Goal | Clean depth needed | Approximate read pairs at 2×150 |
| --- | --- | --- |
| Taxonomic profiling | ≥1.5 Gb | ~5 million |
| Pathway profiling | ≥2 Gb | ~7 million |
| Pathway completeness above 80% | ≥5 Gb | ~17 million |
| Protein-level functional analysis | ≥10 Gb | ~33 million |

To turn that into an order, work **backwards**, dividing by the fraction that survives each loss:

```
raw pairs to order  =  clean pairs needed  ÷  (1 − host fraction)  ÷  trim survival
```

Take the host fraction from the table in Section 7 and use 0.85 for trim survival (Section 8 flags anything below 0.80). Worked through, for the 5 million clean pairs that taxonomic profiling needs:

| Site | Host fraction | Raw pairs to order |
| --- | --- | --- |
| Gut / stool | 0.10 | 5 000 000 ÷ 0.90 ÷ 0.85 ≈ **6.5 million** |
| Oral, saliva, vaginal | 0.90 | 5 000 000 ÷ 0.10 ÷ 0.85 ≈ **59 million** |
| BAL, no wet-lab depletion | 0.997 | 5 000 000 ÷ 0.003 ÷ 0.85 ≈ **2 billion** |

Divide, do not multiply. Multiplying by the host fraction shrinks the order, and shrinks it most at exactly the sites that need the largest increase — which is the surest way to arrive at a whole run where every sample fails the depth gate in Section 8.

The BAL row is not a typo. It is why Section 7 says that at high-host sites wet-lab depletion at the bench achieves far more than any amount of extra sequencing.

Neither MetaPhlAn nor HUMAnN rarefies internally, so uneven depth propagates straight into your results. If depth varies widely across samples, subsample to a common depth with `reformat.sh samplereadstarget=` before Section 9, and say so in your methods.

---

## **2. Preflight and Storage**

### **Preflight**

Run this once, before anything else, and keep the output. Module strings and database paths drift between platform refreshes, and this is where a shared SOP most often fails for the next person.

```bash
ACCOUNT=<your_nesi_project_code>        # substitute; reused throughout

hostname; sinfo -s          # NeSI refreshed platforms from 2025 - confirm the current cluster
for m in FastQC MultiQC BBMap MetaPhlAn HUMAnN Humann fastp Miniforge3 Bowtie2; do
  echo "== $m"; module -t spider "$m" 2>&1 | head -20
done
# Whether compute nodes have internet decides if tools may resolve databases at runtime.
srun --account=$ACCOUNT --time=00:02:00 --mem=1G \
  bash -c 'curl -sI --max-time 10 https://pypi.org | head -1 || echo NO_INTERNET'
ls -d /opt/nesi/db 2>/dev/null || echo "no shared DB tree - install your own (Section 3.3)"
nn_check_quota
```

The internet check matters more than it looks. MetaPhlAn will try to resolve its database over HTTP at runtime unless you pin it explicitly, which is why Section 9 insists on `--index` and `--offline`.

### **Storage**

Databases and working data belong on `nobackup`; scripts and final tables belong on `project`, which is backed up.

| Filesystem | Size | Backup | Use for |
| --- | --- | --- | --- |
| `project` | ~100 GB | 7-day snapshots | Scripts, final tables, `versions.txt` |
| `nobackup` | ~10 TB | None | Databases, raw and intermediate data |

**`nobackup` deletes files that have not been accessed or modified for 90 days**, flagging them at day 76 in `nn_doomed_list`. Check that list if a project goes quiet for a few months.

The databases will not fit anywhere else: the MetaPhlAn index is 25–30 GB, the human reference index 20–25 GB, and HUMAnN's databases around 40 GB. That is 85–95 GB, which exceeds a default `project` quota on its own.

---

## **3. Setup**

### **3.1 Directories and the Sample Manifest**

```bash
ACCOUNT=<your_nesi_project_code>        # as set in Section 2
WORK=/nesi/nobackup/$ACCOUNT/readbased
DB=/nesi/nobackup/$ACCOUNT/db

mkdir -p "$WORK"/{raw,trim,clean,metaphlan,humann,tables,qc/{raw,trim},logs,scripts}
mkdir -p "$DB"/{human,metaphlan4,humann}
cd "$WORK"

ls raw/*_R1.fastq.gz | xargs -n1 basename | sed 's/_R1\.fastq\.gz$//' > samples.txt
sed -i 's/\r$//; /^$/d' samples.txt     # CRLF and blank lines become an empty $SAMPLE
while read -r S; do
  [[ -s "raw/${S}_R1.fastq.gz" && -s "raw/${S}_R2.fastq.gz" ]] || echo "INCOMPLETE PAIR: $S"
done < samples.txt
NSAMP=$(wc -l < samples.txt); echo "samples: $NSAMP"
```

> **Expect** `$NSAMP` to equal the number of samples you sequenced. More than that usually means a stray file matched the `raw/*_R1.fastq.gz` glob; fewer means a pair is missing — check the `INCOMPLETE PAIR` lines the loop printed before you go on.

The `sed` line is not decoration. A manifest edited on Windows carries carriage returns, and a trailing blank line produces an empty `$SAMPLE` — both give you array tasks that fail in confusing ways much later.

Adjust the filename pattern to match your data. For Illumina's `<sample>_S1_L001_R1_001.fastq.gz` convention, concatenate lanes first, then simplify the names.

Two constraints to note now:

- **Create `logs/` before your first `sbatch`.** Every header below sets `--chdir` to `$WORK`, so all relative paths and log files resolve there no matter which directory you submit from — but the `logs/` directory must already exist, or SLURM fails without telling you why. The `mkdir -p` above already creates it.
- **NeSI caps job arrays at 1000 tasks.** Larger cohorts need to be split.

### **3.2 Modules**

Three were confirmed present when this SOP was written: `FastQC/0.12.1`, `BBMap/39.01-GCC-11.3.0`, `Miniforge3/25.3.1-0`.

Verify these with `module spider` before you rely on them, capitalisation included: `MultiQC/1.24.1-foss-2023a-Python-3.11.6`, `MetaPhlAn/4.1.0-gimkl-2022a-Python-3.10.5`, `fastp/0.23.4-GCC-11.3.0`.

**Do not use the `Humann/3.0.0.alpha.3` module.** Section 10 explains why.

### **3.3 References and Databases**

One-time setup, on the login node; both downloads are large, so start them before you need them. The MetaPhlAn index is **always** needed. The chm13 human reference is **only for host-depletion Option B (BBMap)** — skip it if you are using Hostile (Option A, the recommended path in Section 7), which fetches its own masked index.

```bash
# Always needed: MetaPhlAn marker index (pinned deliberately; newer indexes exist)
MPA_INDEX=mpa_vJun23_CHOCOPhlAnSGB_202403
module load MetaPhlAn/4.1.0-gimkl-2022a-Python-3.10.5
srun --account=$ACCOUNT --time=02:00:00 --mem=8G --cpus-per-task=4 \
  metaphlan --install --index "$MPA_INDEX" --bowtie2db "$DB/metaphlan4"

# Option B (BBMap) ONLY — skip if you use Hostile (Option A). The ~20-25 GB
# unmasked T2T-CHM13 human reference:
cd "$DB/human"
wget https://s3-us-west-2.amazonaws.com/human-pangenomics/T2T/CHM13/assemblies/analysis_set/chm13v2.0.fa.gz
md5sum chm13v2.0.fa.gz | tee chm13v2.0.fa.gz.md5   # records provenance (Section 14); to
                                                   # actually verify, compare against the
                                                   # checksum published with the file
```

**How long:** 2–4 hours for the two downloads combined. Run them before you need them, not on the day you want to profile.

**We pin** the MetaPhlAn index rather than accepting the default. Section 9 explains what an unpinned index does to reproducibility.

---

## **4. The Standard Job Header**

Every script below carries the complete job header — shebang, `#SBATCH` directives, and `set -euo pipefail` — so you can copy a block, substitute the placeholders, and submit it. The per-script resource values (`--time`, `--mem`, `--cpus-per-task`) are collected in Appendix C. Each header sets `--chdir /nesi/nobackup/<your_nesi_project_code>/readbased`, so `logs/` and every relative path resolve there no matter which directory you run `sbatch` from.

**Set the real array size at submission**, not in the script. The array scripts carry no `#SBATCH --array` line, so you add the range when you submit: `sbatch --array=1-${NSAMP}%20 scripts/06.trim.sl`. Leaving it out is the mistake most often made in this SOP — but without a range the job fails loudly on an unset `${SLURM_ARRAY_TASK_ID}` under `set -u`, rather than silently running sample 1 only.

The `%20` suffix throttles the array to 20 concurrent tasks, which keeps you from filling the queue; HUMAnN throttles harder, to `%10`.

---

## **5. Quality Control**

**Quality control** tells you whether your reads are good enough to trust before you spend compute on them. **FastQC** scans each FASTQ file and reports per-base quality, adapter contamination, GC content and over-represented sequences; **MultiQC** gathers every sample's FastQC output into one report you can read across the cohort. You run QC twice — on the raw reads and again after trimming — so you can see what trimming changed, using one parameterised script for both.

`scripts/05a.qc_fastqc.sl` (array job):

```bash
#!/bin/bash
#SBATCH --account <your_nesi_project_code>
#SBATCH --job-name qc_fastqc
#SBATCH --chdir /nesi/nobackup/<your_nesi_project_code>/readbased
#SBATCH --time 00:30:00
#SBATCH --mem 4G
#SBATCH --cpus-per-task 2
#SBATCH --output logs/%x_%A_%a.out
#SBATCH --error  logs/%x_%A_%a.err
# array range set at submission: sbatch --array=1-${NSAMP}%20 scripts/05a.qc_fastqc.sl raw qc/raw

set -euo pipefail
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" samples.txt)
[[ -n "$SAMPLE" ]] || { echo "empty sample at ${SLURM_ARRAY_TASK_ID}"; exit 1; }

IN=${1:?usage: sbatch 05a.qc_fastqc.sl <indir> <outdir>}; OUT=${2:?}
module purge; module load FastQC/0.12.1
fastqc -t 2 -o "$OUT" "$IN/${SAMPLE}_R1.fastq.gz" "$IN/${SAMPLE}_R2.fastq.gz"
```

`scripts/05b.qc_multiqc.sl`:

```bash
#!/bin/bash
#SBATCH --account <your_nesi_project_code>
#SBATCH --job-name qc_multiqc
#SBATCH --chdir /nesi/nobackup/<your_nesi_project_code>/readbased
#SBATCH --time 00:20:00
#SBATCH --mem 4G
#SBATCH --cpus-per-task 1
#SBATCH --output logs/%x_%j.out
#SBATCH --error  logs/%x_%j.err

set -euo pipefail

module purge; module load MultiQC/1.24.1-foss-2023a-Python-3.11.6
multiqc -f -o "${1:?}_report" "${1:?}"
```

A few things worth knowing:

- **`-t 2`, not more.** FastQC uses one thread per input file, so with two files there is nothing for extra threads to do.
- **MultiQC writes to a sibling directory**: input `qc/raw` produces `qc/raw_report`.
- **MultiQC must be a dependent job.** Submit it with `--dependency=afterok` (Appendix A). Submitted alongside the FastQC array instead, it runs immediately, reports on however few samples happen to have finished, and exits 0 — leaving you a report that looks fine and is silently incomplete.

**How long:** FastQC about 30 minutes across the cohort, MultiQC about 20 minutes.

After MultiQC finishes, confirm the report exists:

```bash
ls qc/raw_report/multiqc_report.html
```

> **Missing** means MultiQC ran before the FastQC array finished — resubmit it with `--dependency=afterok` (Appendix A).

### **Reading the Reports**

Several FastQC modules fail reliably on metagenomes and can be ignored: GC content, duplication levels, and overrepresented sequences. A metagenome is a mixture of organisms with different GC contents, so a single-genome expectation does not apply.

What does matter: adapter content, any collapse in quality towards the read ends, poly-G tails, and samples with unusually low read counts. After trimming, expect adapter content at zero, poly-G gone, and more than 80% of reads surviving.

### **Identify Your Chemistry Now**

Section 6 branches on this, so settle it before you trim. Check the instrument ID in the read headers, or look for poly-G in the overrepresented sequences:

```bash
zcat raw/<sample>_R1.fastq.gz | head -1
```

NovaSeq and NextSeq are two-colour instruments and produce poly-G artefacts. HiSeq and MiSeq are four-colour and do not.

---

## **6. Trimming and PhiX Removal**

Sequencing does not stop cleanly at the end of your DNA fragment. When a fragment is shorter than the read, the machine reads on into the **adapter** — the short synthetic sequence that library prep attached to every fragment so it would bind the flow cell — and those bases are not biology. **Adapter trimming** finds and removes them.

Illumina also spikes every run with **PhiX**, a small bacteriophage genome used as a sequencing-quality control; its reads are real DNA but not part of your sample, so they must be removed too. This section does both with **BBDuk** (part of the BBMap package): trim adapters in the first pass, filter PhiX in the second. `ktrim=r` below means "trim the matched k-mer and everything to its right".

This runs as **two passes, and they cannot be combined into one.** The reason is that `ktrim=r` applies to every sequence in `ref=`. Listing PhiX alongside the adapters would therefore *truncate* PhiX-contaminated reads and keep the remainder, rather than discarding them. BBDuk's default behaviour with no `ktrim` is to filter whole reads, which is what you want for PhiX. So: trim adapters in pass one, filter PhiX in pass two.

`scripts/06.trim.sl` (array job):

```bash
#!/bin/bash
#SBATCH --account <your_nesi_project_code>
#SBATCH --job-name trim
#SBATCH --chdir /nesi/nobackup/<your_nesi_project_code>/readbased
#SBATCH --time 02:00:00
#SBATCH --mem 16G
#SBATCH --cpus-per-task 12
#SBATCH --output logs/%x_%A_%a.out
#SBATCH --error  logs/%x_%A_%a.err
# array range set at submission: sbatch --array=1-${NSAMP}%20 scripts/06.trim.sl

set -euo pipefail
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" samples.txt)
[[ -n "$SAMPLE" ]] || { echo "empty sample at ${SLURM_ARRAY_TASK_ID}"; exit 1; }

module purge; module load BBMap/39.01-GCC-11.3.0
HALF=$(( SLURM_CPUS_PER_TASK / 2 ))   # two JVMs run CONCURRENTLY in the pipe: halve
                                      # both heap and threads or you OOM/oversubscribe
bbduk.sh \
  in1="raw/${SAMPLE}_R1.fastq.gz" in2="raw/${SAMPLE}_R2.fastq.gz" out=stdout.fq \
  ref=adapters ktrim=r k=23 mink=11 hdist=1 tbo tpe ftm=5 \
  qtrim=rl trimq=10 minlen=50 \
  stats="logs/${SAMPLE}.adapters.stats" threads=${HALF} -Xmx6g \
| bbduk.sh \
  in=stdin.fq int=t \
  out1="trim/${SAMPLE}_R1.fastq.gz" out2="trim/${SAMPLE}_R2.fastq.gz" \
  ref=phix,artifacts k=31 hdist=1 \
  stats="logs/${SAMPLE}.phix.stats" threads=${HALF} -Xmx6g
```

Notes on the parameters:

- **`trimq=10`, not 20.** Double-ended quality trimming at Q20 with `minlen=50` biases against GC-extreme and low-coverage genomes — precisely the taxa you are least confident about already.
- **Keep the `stats=` files.** They belong in your methods section.
- **Do not deduplicate.** In a low-complexity community, duplicate reads from a dominant taxon are usually genuine, and removing them distorts abundance.
- Optional additions: `outs=` retains singletons, and `entropy=0.90 entropywindow=50` drops low-complexity reads.

**How long:** about 2 hours per sample. The after-trimming QC in Section 5 is your checkpoint — adapter content should read zero and more than 80% of reads should survive.

### **Two-Colour Chemistry: Poly-G**

Two-colour instruments read an absent signal as G, producing poly-G tails. Add `trimpolygright=8` to the pass-one call above. BBDuk has carried the `trimpolyg*` flags since version 38.21, so the pinned 39.01 module supports them.

Version 39.01 (the newest BBMap on the cluster) catches clean poly-G runs. If your two-colour data has poly-G runs interrupted by the occasional non-G base, use the fastp alternative below, whose `--trim_poly_g` handles interrupted runs.

### **Alternative: fastp for Pass One**

fastp is a reasonable substitute for the first pass. It detects adapters without a reference and produces a better report. It replaces **pass one only** — PhiX filtering still has to happen afterwards, so the script below runs fastp then BBDuk in turn.

```bash
#!/bin/bash
#SBATCH --account <your_nesi_project_code>
#SBATCH --job-name trim
#SBATCH --chdir /nesi/nobackup/<your_nesi_project_code>/readbased
#SBATCH --time 02:00:00
#SBATCH --mem 16G
#SBATCH --cpus-per-task 12
#SBATCH --output logs/%x_%A_%a.out
#SBATCH --error  logs/%x_%A_%a.err
# array range set at submission: sbatch --array=1-${NSAMP}%20 scripts/06.trim.sl

set -euo pipefail
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" samples.txt)
[[ -n "$SAMPLE" ]] || { echo "empty sample at ${SLURM_ARRAY_TASK_ID}"; exit 1; }

module purge; module load fastp/0.23.4-GCC-11.3.0
fastp -i "raw/${SAMPLE}_R1.fastq.gz" -I "raw/${SAMPLE}_R2.fastq.gz" \
      -o "trim/${SAMPLE}_R1.tmp.fastq.gz" -O "trim/${SAMPLE}_R2.tmp.fastq.gz" \
      --detect_adapter_for_pe --trim_poly_g --poly_g_min_len 8 \
      --cut_front --cut_tail --cut_mean_quality 10 \
      --qualified_quality_phred 15 --unqualified_percent_limit 40 --length_required 50 \
      --thread ${SLURM_CPUS_PER_TASK} \
      --json "qc/trim/${SAMPLE}.fastp.json" --html "qc/trim/${SAMPLE}.fastp.html"

# Pass 2 on fastp's output. One JVM this time, so full threads and heap - no halving.
module purge; module load BBMap/39.01-GCC-11.3.0
bbduk.sh in1="trim/${SAMPLE}_R1.tmp.fastq.gz" in2="trim/${SAMPLE}_R2.tmp.fastq.gz" \
  out1="trim/${SAMPLE}_R1.fastq.gz" out2="trim/${SAMPLE}_R2.fastq.gz" \
  ref=phix,artifacts k=31 hdist=1 \
  stats="logs/${SAMPLE}.phix.stats" threads=${SLURM_CPUS_PER_TASK} -Xmx12g
rm -f "trim/${SAMPLE}_R1.tmp.fastq.gz" "trim/${SAMPLE}_R2.tmp.fastq.gz"
```

**How long:** about 2 hours per sample, as for the BBDuk-only route. MultiQC parses fastp's JSON, so Section 5 still gives you a single report either way.

---

## **7. Host Depletion**

The rule is simple: keep a read pair only if **neither** mate maps to the human genome.

### **Why T2T-CHM13v2.0**

**We deplete against T2T-CHM13v2.0**, not hg38 — not for raw sensitivity, where the per-read gain is a fraction of a percentage point, but for false positives. T2T-CHM13v2.0 adds roughly 200 Mb of centromeric, segmental and satellite sequence that hg38 lacks. Human reads from those regions have nowhere to map in hg38, so they misalign to microbial references and appear as species that were never in your sample. A more complete human reference captures them.

Take the effect size from a benchmark rather than from this SOP: *Telomere-to-Telomere Assembly Improves Host Reads Removal in Metagenomic High-Throughput Sequencing of Human Samples* (bioRxiv 2023.05.05.539517), and *Use of the CHM13-T2T genome improves metagenomic analysis by minimizing host DNA contamination* (*mSystems*, 2025).

### **Why the Reference Must Be Masked**

An unmasked human reference deletes genuine microbial reads, because rRNA genes, conserved regions and low-complexity repeats are shared between human and microbial sequence. Masking those regions is what stops it. This matters for Option B below, whose parameters come from JGI's recipe and assume a masked reference.

### **Option A — Masked Index via Hostile (Recommended)**

**We default to** Hostile because it fetches its own masked index, so you never build or store the human reference yourself. **Hostile** is not a NeSI module, so you install it with **conda** — a package manager that, as an alternative to `module load`, installs tools into a named *environment* you activate when you need it. Set it up once on the login node:

```bash
module load Miniforge3/25.3.1-0
source "$(conda info --base)/etc/profile.d/conda.sh"
mamba create -y -n hostile -c conda-forge -c bioconda hostile
conda activate hostile; hostile clean --help          # confirm the CLI for your version
export HOSTILE_CACHE_DIR=$DB/hostile; hostile fetch --name human-t2t-hla-argos985
```

`scripts/07.host_hostile.sl` (array job):

```bash
#!/bin/bash
#SBATCH --account <your_nesi_project_code>
#SBATCH --job-name host_hostile
#SBATCH --chdir /nesi/nobackup/<your_nesi_project_code>/readbased
#SBATCH --time 01:00:00
#SBATCH --mem 24G
#SBATCH --cpus-per-task 16
#SBATCH --output logs/%x_%A_%a.out
#SBATCH --error  logs/%x_%A_%a.err
# array range set at submission: sbatch --array=1-${NSAMP}%20 scripts/07.host_hostile.sl

set -euo pipefail
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" samples.txt)
[[ -n "$SAMPLE" ]] || { echo "empty sample at ${SLURM_ARRAY_TASK_ID}"; exit 1; }

module purge; module load Miniforge3/25.3.1-0
source "$(conda info --base)/etc/profile.d/conda.sh"; conda activate hostile
export HOSTILE_CACHE_DIR=/nesi/nobackup/<your_nesi_project_code>/db/hostile

hostile clean --fastq1 "trim/${SAMPLE}_R1.fastq.gz" --fastq2 "trim/${SAMPLE}_R2.fastq.gz" \
  --index human-t2t-hla-argos985 --out-dir clean --threads ${SLURM_CPUS_PER_TASK}

# Normalise Hostile's naming. VERIFY on your first sample: run one, `ls clean/`,
# then fix these two lines before scaling.
mv "clean/${SAMPLE}_R1.clean_1.fastq.gz" "clean/${SAMPLE}_R1.fastq.gz"
mv "clean/${SAMPLE}_R2.clean_2.fastq.gz" "clean/${SAMPLE}_R2.fastq.gz"
```

**How long:** about 1 hour per sample. Run a single sample first and check what actually landed in `clean/`:

```bash
ls -l "clean/${SAMPLE}_R1.fastq.gz" "clean/${SAMPLE}_R2.fastq.gz"
```

> **Both present and non-empty** means depletion worked and the `mv` lines matched. **Missing** almost always means Hostile's output filenames differ in your version — Hostile's naming has changed between versions, so `ls clean/` and fix the two `mv` lines before launching the full array.

### **Option B — Modules Only, BBMap Against Unmasked T2T**

Use this only if you cannot install Hostile, and only if two conditions hold: you have a mock community (Section 1) to quantify how much microbial signal you lose, and your methods section states that the reference was unmasked.

`scripts/07a.host_index.sl` (no array). The filter must not start until this finishes — see Appendix A:

```bash
#!/bin/bash
#SBATCH --account <your_nesi_project_code>
#SBATCH --job-name host_index
#SBATCH --chdir /nesi/nobackup/<your_nesi_project_code>/readbased
#SBATCH --time 01:00:00
#SBATCH --mem 36G
#SBATCH --cpus-per-task 12
#SBATCH --output logs/%x_%j.out
#SBATCH --error  logs/%x_%j.err

set -euo pipefail

module purge; module load BBMap/39.01-GCC-11.3.0
DB=/nesi/nobackup/<your_nesi_project_code>/db   # batch jobs do not inherit your login shell; define it here (as in Section 9)
cd "$DB/human"
bbmap.sh ref=chm13v2.0.fa.gz threads=${SLURM_CPUS_PER_TASK} -Xmx30g
```

`scripts/07b.host_filter.sl` (array job):

```bash
#!/bin/bash
#SBATCH --account <your_nesi_project_code>
#SBATCH --job-name host_filter
#SBATCH --chdir /nesi/nobackup/<your_nesi_project_code>/readbased
#SBATCH --time 01:00:00
#SBATCH --mem 32G
#SBATCH --cpus-per-task 20
#SBATCH --output logs/%x_%A_%a.out
#SBATCH --error  logs/%x_%A_%a.err
# array range set at submission: sbatch --array=1-${NSAMP}%20 scripts/07b.host_filter.sl

set -euo pipefail
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" samples.txt)
[[ -n "$SAMPLE" ]] || { echo "empty sample at ${SLURM_ARRAY_TASK_ID}"; exit 1; }

module purge; module load BBMap/39.01-GCC-11.3.0
DB=/nesi/nobackup/<your_nesi_project_code>/db   # batch jobs do not inherit your login shell; define it here (as in Section 9)
bbmap.sh -Xmx26g threads=${SLURM_CPUS_PER_TASK} \
  minid=0.95 maxindel=3 bwr=0.16 bw=12 quickmatch fast minhits=2 \
  qtrim=rl trimq=10 untrim \
  in1="trim/${SAMPLE}_R1.fastq.gz" in2="trim/${SAMPLE}_R2.fastq.gz" \
  path="$DB/human" \
  outu1="clean/${SAMPLE}_R1.fastq.gz" outu2="clean/${SAMPLE}_R2.fastq.gz" \
  statsfile="logs/${SAMPLE}.hostmap.stats"
```

Three details that cause real failures:

- The parameter is `threads=`, not `-t=`.
- `path=` takes the directory *containing* the auto-generated `ref/` subdirectory, not `ref/` itself.
- `outu` excludes an unmapped read whose mate mapped. That is the behaviour you want — if either mate hits human, both go — but it means clean is not raw minus host when you reconcile the numbers in Section 8.

Keep `-Xmx26g` under a 32 GB allocation. The JVM's overhead sits outside the heap, so a tighter margin gets the job OOM-killed partway through an array.

**How long:** indexing about 1 hour, run once; filtering about 1 hour per sample.

### **Expected Host Fraction by Site**

| Site | Typical host fraction |
| --- | --- |
| Gut / stool | <10% |
| Oral, saliva, vaginal | >90% |
| BAL | ~99.7%, still ~81% after the best wet-lab depletion |
| Skin | High, and low-biomass as well |

At high-host sites, wet-lab depletion at the bench achieves far more than any bioinformatic step can. If you are working on BAL or oral samples, that is where to spend the effort.

---

## **8. Read Accounting and Depth Gates**

Run this as a job. NeSI terminates long-running processes on login nodes, and counting reads across a cohort takes a while.

`scripts/08.read_counts.sl` (no array):

```bash
#!/bin/bash
#SBATCH --account <your_nesi_project_code>
#SBATCH --job-name read_counts
#SBATCH --chdir /nesi/nobackup/<your_nesi_project_code>/readbased
#SBATCH --time 02:00:00
#SBATCH --mem 4G
#SBATCH --cpus-per-task 1
#SBATCH --output logs/%x_%j.out
#SBATCH --error  logs/%x_%j.err

set -euo pipefail

OUT=tables/read_counts.tsv
printf "sample\traw_pairs\ttrim_pairs\tclean_pairs\ttrim_frac\thost_frac\n" > "$OUT"

# zcat's failure must be checked explicitly: inside $( ) in an arithmetic expansion it
# does NOT trip -e/pipefail, so a truncated gzip would silently yield a short count.
count() {
  [[ -s "$1" ]] || { echo 0; return; }
  local n; n=$(zcat "$1" | wc -l) || { echo "ERROR: zcat failed on $1" >&2; exit 1; }
  echo $(( n / 4 ))
}

while read -r S; do
  raw=$(count "raw/${S}_R1.fastq.gz"); trim=$(count "trim/${S}_R1.fastq.gz")
  clean=$(count "clean/${S}_R1.fastq.gz")
  tf=$(awk -v a="$trim"  -v b="$raw"  'BEGIN{if(b>0)printf "%.4f",a/b;   else printf "NA"}')
  hf=$(awk -v a="$clean" -v b="$trim" 'BEGIN{if(b>0)printf "%.4f",1-a/b; else printf "NA"}')
  printf "%s\t%s\t%s\t%s\t%s\t%s\n" "$S" "$raw" "$trim" "$clean" "$tf" "$hf" >> "$OUT"
done < samples.txt
```

These are read **pairs**, not reads. One million pairs is roughly 0.3 Gb of sequence at 2×150, which is the conversion behind every figure in Section 1.

**How long:** about 1–2 hours across the cohort.

### **The Gates**

| Condition | What to do |
| --- | --- |
| `trim_frac` below 0.80 | Investigate over-trimming |
| `trim_frac` below 0.50 | Exclude the sample or re-sequence it |
| `host_frac` far above the site expectation (for example >0.30 in stool) | Investigate sample handling |
| `clean_pairs` below ~5 million | Not enough for defensible taxonomy — flag it |
| `clean_pairs` below ~17 million | Not enough for pathway completeness — drop from functional analysis, or state the limitation |
| Controls with read counts comparable to real samples | Serious contamination — stop and investigate |

**Stop here the first time you run this pipeline.** Read this table and both MultiQC reports before committing compute to Sections 9 and 10. Those two steps consume most of the pipeline's total resources, and there is no point spending them on data you are going to exclude.

---

## **9. Taxonomy with MetaPhlAn 4**

MetaPhlAn matches reads against clade-specific marker genes and reports composition at species and SGB level (SGB — species-level genome bin, MetaPhlAn's genome-based unit, roughly a species including unnamed ones; Blanco-Míguez et al. 2023, *Nature Biotechnology*). It is not strain-level: that needs StrainPhlAn, which can reuse the `.bt2.bz2` alignment files saved below.

Marker genes are the reason this workflow is restricted to human-associated samples: the marker set is built from human-associated taxa, so a species absent from it cannot be reported no matter how abundant it is in your data.

`scripts/09.metaphlan.sl` (array job):

```bash
#!/bin/bash
#SBATCH --account <your_nesi_project_code>
#SBATCH --job-name metaphlan
#SBATCH --chdir /nesi/nobackup/<your_nesi_project_code>/readbased
#SBATCH --time 04:00:00
#SBATCH --mem 32G
#SBATCH --cpus-per-task 16
#SBATCH --output logs/%x_%A_%a.out
#SBATCH --error  logs/%x_%A_%a.err
# array range set at submission: sbatch --array=1-${NSAMP}%20 scripts/09.metaphlan.sl

set -euo pipefail
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" samples.txt)
[[ -n "$SAMPLE" ]] || { echo "empty sample at ${SLURM_ARRAY_TASK_ID}"; exit 1; }

module purge; module load MetaPhlAn/4.1.0-gimkl-2022a-Python-3.10.5
DB=/nesi/nobackup/<your_nesi_project_code>/db; MPA_INDEX=mpa_vJun23_CHOCOPhlAnSGB_202403

# MetaPhlAn refuses to overwrite an existing --bowtie2out file and exits 1. A task that
# failed after pass 1 leaves one behind, so clear any leftover first; this makes
# re-running a failed array index (Appendix B) safe.
rm -f "metaphlan/${SAMPLE}.bt2.bz2"

# Pass 1: align once, save the alignment, emit the standard rel_ab profile.
metaphlan "clean/${SAMPLE}_R1.fastq.gz,clean/${SAMPLE}_R2.fastq.gz" \
  --input_type fastq --nproc ${SLURM_CPUS_PER_TASK} \
  --bowtie2db "$DB/metaphlan4" --index "$MPA_INDEX" --offline \
  --bowtie2out "metaphlan/${SAMPLE}.bt2.bz2" -o "metaphlan/${SAMPLE}.profile.tsv"

# Pass 2: estimated read counts from the SAVED alignment - no remapping.
metaphlan "metaphlan/${SAMPLE}.bt2.bz2" \
  --input_type bowtie2out --nproc ${SLURM_CPUS_PER_TASK} \
  --bowtie2db "$DB/metaphlan4" --index "$MPA_INDEX" --offline \
  -t rel_ab_w_read_stats -o "metaphlan/${SAMPLE}.readstats.tsv"
```

**How long:** roughly 1–4 hours per sample. Confirm the profile is populated before you scale the array:

```bash
grep -c 's__' "metaphlan/${SAMPLE}.profile.tsv"
```

> **Expect** tens to a few hundred species lines for a typical gut sample. **Zero or a near-empty profile** means the reads did not map — check that `clean/${SAMPLE}_R1.fastq.gz` is non-empty and that `--index` and `--bowtie2db` point at the installed database, then re-run the task before scaling the array.

### **Why `--index` and `--offline` Are Not Optional**

The default index setting is `latest`, which triggers an HTTP lookup at runtime. On a compute node without internet, that either fails outright with `Cannot find a local database` or quietly falls back to a cached tag. Either way, the database a sample was profiled against would depend on when someone last ran the tool with internet access. Pinning the index is what makes the run reproducible.

### **Why There Are Two Passes**

Section 13's differential abundance methods need counts, and `-t rel_ab` provides none. Pass two re-reads the saved alignment to produce them, which costs almost nothing because no reads are re-mapped.

Be clear about what these counts are: they are **model-estimated** reads, not sequencer counts. State that in your methods, and do not use them for alpha diversity.

MetaPhlAn pools the two mates and ignores pairing, so the comma-separated input above is correct usage rather than a shortcut.

---

## **10. Function with HUMAnN**

MetaPhlAn told you *who* is in each sample. **HUMAnN** tells you *what they can do*: it maps your reads to **gene families** (groups of related genes, here UniRef90 clusters) and reconstructs the metabolic **pathways** the community can carry out, so you can ask which functions differ between groups rather than only which species.

HUMAnN reuses Section 9's taxonomic profile to choose which reference genomes to search, which is why it runs after MetaPhlAn. Its database install is large and each sample is slow, so read both subsections below before you start.

### **Install a Current Release**

**Do not use the `Humann/3.0.0.alpha.3` module.** It is a June 2020 pre-release, older than stable 3.0.0. It hard-targets MetaPhlAn 3.0 and ChocoPhlAn v30, which predate every MetaPhlAn 4 SGB database, ships 2019-vintage UniRef90, and has known memory bugs. Install a current release through Miniforge3 instead (conda, as introduced in Section 7).

```bash
module load Miniforge3/25.3.1-0
source "$(conda info --base)/etc/profile.d/conda.sh"
mamba create -y -n humann -c conda-forge -c bioconda -c biobakery humann
conda activate humann
humann --version; humann_config --print       # record both; confirm DB paths resolve
# if they don't, install ~40 GB under srun:
# Export DB first: inside single quotes, $DB is expanded by the NEW shell, not this
# one, and an unexported DB arrives empty — every target becomes /humann at the
# filesystem root. set -e stops the second and third downloads if the first fails.
export DB
srun --account=$ACCOUNT --time=04:00:00 --mem=8G --cpus-per-task=4 bash -c '
  set -euo pipefail
  humann_databases --download chocophlan full         "$DB/humann" --update-config yes
  humann_databases --download uniref uniref90_diamond "$DB/humann" --update-config yes
  humann_databases --download utility_mapping full    "$DB/humann" --update-config yes'
```

### **Running It**

`scripts/10.humann.sl` (array job, throttled to `%10`):

```bash
#!/bin/bash
#SBATCH --account <your_nesi_project_code>
#SBATCH --job-name humann
#SBATCH --chdir /nesi/nobackup/<your_nesi_project_code>/readbased
#SBATCH --time 24:00:00
#SBATCH --mem 48G
#SBATCH --cpus-per-task 16
#SBATCH --output logs/%x_%A_%a.out
#SBATCH --error  logs/%x_%A_%a.err
# array range set at submission: sbatch --array=1-${NSAMP}%10 scripts/10.humann.sl

set -euo pipefail
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" samples.txt)
[[ -n "$SAMPLE" ]] || { echo "empty sample at ${SLURM_ARRAY_TASK_ID}"; exit 1; }

module purge; module load Miniforge3/25.3.1-0
source "$(conda info --base)/etc/profile.d/conda.sh"; conda activate humann

TMPFQ="humann/${SAMPLE}.fastq.gz"
export TMPDIR="/nesi/nobackup/<your_nesi_project_code>/tmp/${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}"
mkdir -p "$TMPDIR"
# Clean up BOTH on any exit path: under -e a HUMAnN failure aborts immediately and
# anything outside the trap leaks - the temp dir is 100-170 GB per sample.
trap 'rm -rf "$TMPFQ" "$TMPDIR"' EXIT

cat "clean/${SAMPLE}_R1.fastq.gz" "clean/${SAMPLE}_R2.fastq.gz" > "$TMPFQ"  # HUMAnN ignores pairing

humann --input "$TMPFQ" --output "humann/${SAMPLE}" --threads ${SLURM_CPUS_PER_TASK} \
  --taxonomic-profile "metaphlan/${SAMPLE}.profile.tsv" \
  --remove-temp-output --o-log "logs/${SAMPLE}.humann.log"
```

**How long:** 12–24 hours per sample — the longest step in the pipeline. Do not kill it early; watch progress in `logs/${SAMPLE}.humann.log`. Confirm one sample produced both tables before launching the full array:

```bash
ls -l "humann/${SAMPLE}/${SAMPLE}_genefamilies.tsv" "humann/${SAMPLE}/${SAMPLE}_pathabundance.tsv"
```

> **Expect** both files present and non-empty. **Missing or empty** means HUMAnN found nothing to profile — usually an empty `clean/` FASTQ or a MetaPhlAn/ChocoPhlAn mismatch (the first note below). Do not launch the full array until one sample produces both.

Three things to understand here:

- **`--taxonomic-profile` reuses Section 9's profile**, which saves HUMAnN from running MetaPhlAn again. But first verify that your HUMAnN's ChocoPhlAn build is compatible with `$MPA_INDEX`. If it is not, drop the flag and let HUMAnN run its own MetaPhlAn — that is much better than feeding it a mismatched profile.
- **`--remove-temp-output` is mandatory** at cohort scale. Each sample generates 100–170 GB of temporary files; at ten concurrent tasks that is 1–1.7 TB.
- **The `trap` matters.** Because `set -e` aborts immediately on a HUMAnN failure, any cleanup placed after the command would never run, and the temporary files would accumulate until the filesystem fills.

---

## **11. Merging, Normalising and Splitting Tables**

HUMAnN and MetaPhlAn hand you tables in units built for the tools, not for statistics, so this section merges every sample into one table per feature type and converts the units. **RPK** (reads per kilobase) is HUMAnN's raw output — length-corrected but not depth-corrected — so a deeper sample looks richer; **CPM** (copies per million) is the depth-normalised unit you want.

**Unstratified** tables give one number per feature for the whole community; **stratified** tables break that number down by contributing species. Split the two before testing — mixing them makes the multiple-testing correction meaningless.

Run this interactively:

```bash
srun --account=$ACCOUNT --time=00:30:00 --mem=8G --cpus-per-task=2 --pty bash
```

### **Taxonomy: Relative Abundance**

```bash
module purge; module load MetaPhlAn/4.1.0-gimkl-2022a-Python-3.10.5
merge_metaphlan_tables.py metaphlan/*.profile.tsv > tables/merged_taxonomy_allranks.tsv

# The merged table holds EVERY rank (k__ through t__) and reports the same reads at all
# eight, so a column sums to roughly 8x the classified fraction - not 100%.
# Never hand the all-ranks table to anything that expects a species table.
# merge_metaphlan_tables.py writes the #mpa_ version line FIRST and the real
# 'clade_name<TAB>samples' header on the SECOND line, and suffixes each sample
# column with '.profile' from the input filename. Take the header from the
# clade_name line (NOT head -1, which grabs the #mpa_ comment) and strip the
# suffix, so these sample IDs stay byte-identical to merged_species_counts.tsv
# and your metadata.
grep -m1 '^clade_name' tables/merged_taxonomy_allranks.tsv \
  | sed 's/\.profile\(\t\|$\)/\1/g' > tables/merged_species.tsv
grep -E "s__" tables/merged_taxonomy_allranks.tsv | grep -v "t__" >> tables/merged_species.tsv
```

### **Taxonomy: Estimated Counts**

Counts need a separate merge, because `merge_metaphlan_tables.py` only merges the `relative_abundance` column. The script below finds the count column by name from the `#clade_name` header, since the column layout varies between MetaPhlAn versions.

```bash
python3 - <<'PY'
import glob, os, pandas as pd
COL, frames = "estimated_number_of_reads_from_the_clade", {}
for f in sorted(glob.glob("metaphlan/*.readstats.tsv")):
    header, rows = None, {}
    for line in open(f):
        if not line.strip(): continue
        if line.startswith("#"):
            if "clade_name" in line: header = line.lstrip("#").rstrip("\n").split("\t")
            continue
        if header is None or COL not in header:
            raise SystemExit(f"{f}: no '{COL}' column - made with -t rel_ab_w_read_stats?")
        p = line.rstrip("\n").split("\t")
        if len(p) > header.index(COL): rows[p[0]] = float(p[header.index(COL)])
    frames[os.path.basename(f)[:-len(".readstats.tsv")]] = pd.Series(rows, dtype=float)
m = pd.DataFrame(frames).fillna(0)
m = m[m.index.str.contains("s__") & ~m.index.str.contains("t__")]
m.index.name = "clade_name"
m.to_csv("tables/merged_species_counts.tsv", sep="\t")
print(f"{m.shape[0]} species x {m.shape[1]} samples")
PY
```

### **Function**

```bash
module purge; module load Miniforge3/25.3.1-0
source "$(conda info --base)/etc/profile.d/conda.sh"; conda activate humann

# -s is REQUIRED: HUMAnN writes into per-sample subdirectories and join does not recurse.
# Without it you get "Zero gene tables were found to join" and an empty table.
humann_join_tables -i humann -o tables/genefamilies.tsv  --file_name genefamilies  -s
humann_join_tables -i humann -o tables/pathabundance.tsv --file_name pathabundance -s
humann_join_tables -i humann -o tables/pathcoverage.tsv  --file_name pathcoverage  -s

# Normalise BOTH: raw HUMAnN output is RPK, which does not correct for depth.
humann_renorm_table -i tables/genefamilies.tsv  -o tables/genefamilies_cpm.tsv  --units cpm
humann_renorm_table -i tables/pathabundance.tsv -o tables/pathabundance_cpm.tsv --units cpm

# Split community totals from per-species rows: testing both in one multiple-testing
# family is a statistical error.
humann_split_stratified_table -i tables/genefamilies_cpm.tsv  -o tables/
humann_split_stratified_table -i tables/pathabundance_cpm.tsv -o tables/

humann_regroup_table -i tables/genefamilies_cpm.tsv -g uniref90_level4ec -o tables/ec_cpm.tsv
humann_regroup_table -i tables/genefamilies_cpm.tsv -g uniref90_ko       -o tables/ko_cpm.tsv

# Regrouping preserves stratification, so ec_cpm.tsv and ko_cpm.tsv carry BOTH the community
# totals and the per-species rows, exactly as genefamilies_cpm.tsv did. Split them too.
humann_split_stratified_table -i tables/ec_cpm.tsv -o tables/
humann_split_stratified_table -i tables/ko_cpm.tsv -o tables/
```

`--file_name` is a substring match, so always write joined tables into `tables/` and never back into `humann/`. Writing them into `humann/` means the next join finds its own output.

### **What Section 13 Needs**

| File | Contents |
| --- | --- |
| `merged_species.tsv` | Relative abundance (%) |
| `merged_species_counts.tsv` | Model-estimated read counts |
| `*_cpm_unstratified.tsv` | Community-level function, CPM |
| `*_stratified.tsv` | Per-species function, CPM |
| `ec_cpm_unstratified.tsv`, `ko_cpm_unstratified.tsv` | Community-level function regrouped to enzyme commission numbers and KEGG orthologues, CPM |
| `ec_cpm_stratified.tsv`, `ko_cpm_stratified.tsv` | The same, per contributing species — follow-up only |

---

## **12. Contamination Screening**

Skip this only if you have no low-biomass samples, and write down why.

1. **Look at your controls directly.** Finding reagent contaminants in blanks is expected, not anomalous. The usual suspects are *Ralstonia*, *Burkholderia*, *Bradyrhizobium*, *Pseudomonas*, *Cutibacterium* and *Delftia*.
2. **Screen with `decontam`**, which `SOP_R_Analysis.md` already covers. Use the **prevalence** method: it needs only the abundance table, no DNA concentrations. Feed it the reshaped `part2_relab.tsv` from Section 13 (not the raw `merged_species.tsv`, which Part 2 silently rounds — see Section 13). `Squeegee` and `MicrobIEM` are alternatives.
3. **Check the mock community.** Anything you expected to see and did not is either a casualty of host depletion (Section 7) or a gap in the database. Both are worth knowing about.
4. **Report, do not silently remove.** Record which taxa you removed, by what method, at what threshold — then re-run the primary analysis with and without them and report whether the conclusions change.

---

## **13. Statistics: What Changes from `SOP_R_Analysis.md`**

Follow `SOP_R_Analysis.md` for the mechanics. This section covers only what differs because your input is MetaPhlAn relative abundance rather than an amplicon count table.

Two rows below (UniFrac, Faith's PD) are additions rather than changes: Part 2 covers no phylogenetic diversity at all, because the upstream tools disagree on whether they emit a tree — Emu does not, while CONCOMPRA and MetaPhlAn both do — so it is left to the upstream document or your own code.

### **Reshape Before You Open Part 2**

`SOP_R_Analysis.md` assumes an integer count table with taxonomy in named rank columns. MetaPhlAn produces neither, so **reshape before you open Part 2** — Part 2's data-loading step, Section 3, will round your percentages into small integers rather than reject them, and every figure after that will be produced from destroyed data without an error anywhere. Split `clade_name` into the rank columns Part 2 expects, and decide which of the two tables each analysis takes:

```bash
python3 - <<'PY'
import pandas as pd
RANKS = ["superkingdom","phylum","class","order","family","genus","species"]
PFX   = ["k__","p__","c__","o__","f__","g__","s__"]
for src, out in [("tables/merged_species.tsv",        "tables/part2_relab.tsv"),
                 ("tables/merged_species_counts.tsv", "tables/part2_counts.tsv")]:
    df = pd.read_csv(src, sep="\t", index_col=0)
    tax = pd.DataFrame(
        [{r: next((p[3:] for p in str(i).split("|") if p.startswith(x)), "")
          for r, x in zip(RANKS, PFX)} for i in df.index], index=df.index)
    tax.insert(0, "tax_id", [str(i).split("|")[-1] for i in df.index])
    pd.concat([tax, df], axis=1).to_csv(out, sep="\t", index=False)
    print(out, pd.concat([tax, df], axis=1).shape)
PY
```

`part2_counts.tsv` holds model-estimated read counts; round it in R and use it **only** for differential abundance. `part2_relab.tsv` holds relative abundance; use it for beta diversity and for `decontam`, and never pass it through `round()` or SRS. The rest of this section lists what else changes.

You also need metadata keyed by sample ID, with group, batch or run, and every covariate you intend to adjust for.

| Step | On MetaPhlAn input |
| --- | --- |
| **SRS normalisation** | **Skip it.** SRS subsamples integer counts, and `merged_species.tsv` holds relative abundance, which is already depth-normalised — go straight to beta diversity and to the Shannon / Simpson / Pielou metrics below. Do **not** substitute `merged_species_counts.tsv`: those are model-estimated floats, and Section 9 rules them out for alpha diversity. That table exists for differential abundance only. If depth genuinely varies enough to worry you, subsample the FASTQs before profiling (Section 1), not the profiles afterwards. |
| **Chao1 / ACE** | **Invalid.** Both extrapolate from singletons and doubletons, which a marker-gene profile does not have. |
| **Observed richness** | Computable, but it tracks sequencing depth and MetaPhlAn's detection threshold rather than diversity, so it is not comparable across samples as-is. Define it as "species above X% relative abundance at matched depth" and report X. Shannon, Simpson and Pielou are safe. |
| **decontam** | Prevalence method (Section 12). |
| **ANCOM-BC2, ALDEx2** | Need `merged_species_counts.tsv`, not `merged_species.tsv` — and **`round()` it first**, because these are model-estimated floats and both tools expect integers. Part 2 does the same to Emu's EM estimates. |
| **`ps_raw` / `ps_srs` suffixes** | Use `ps_relab` and `ps_estcounts`, so the object-naming discipline still tells you what a table holds. |
| **UniFrac** | **Available here, though Part 2 does not cover it.** MetaPhlAn 4 ships the SGB phylogeny with its database: `metaphlan/utils/calculate_diversity.R -d beta -m unweighted-unifrac -t <tree> -s t__`. The tree's tips are SGBs, so it needs the `t__` rows that Section 11 strips out — keep an SGB-level table as well if you want this. |
| **Faith's PD** | Not among `calculate_diversity.R`'s alpha metrics (richness, Shannon, Simpson, Gini), but computable in R from the same tree. |

### **Beta Diversity**

Use Bray–Curtis, Aitchison, or both. These abundances are **compositional** — proportions of a fixed total, so one taxon rising forces the others down, and they carry only relative information (Part 2 owns the full treatment). Aitchison requires you to choose how to handle zeros, and to state the choice:

| Approach | Trade-off |
| --- | --- |
| Pseudocount below the smallest non-zero value | Simple, but biased |
| `zCompositions::cmultRepl` | Built for counts, so off-label on relative abundance |
| **`rclr`** (robust centred log-ratio) | Tolerates zeros without a pseudocount — the cleanest option |

### **PERMANOVA**

Model batch rather than pre-testing for it. An unadjusted PERMANOVA on batch tells you whether batch associates with community structure, which is not the same as whether it *confounds* your group effect.

```r
adonis2(dist ~ batch + group, data = meta, by = "margin", permutations = 999)
adonis2(dist ~ group, data = meta, strata = meta$batch, permutations = 999)
anova(betadisper(dist, meta$group))   # REQUIRED whenever PERMANOVA is significant
```

Always run `betadisper`. Without it, a significant PERMANOVA may reflect unequal within-group variance rather than a difference in location — the most common objection reviewers raise.

### **Differential Abundance**

Method requirements differ: MaAsLin 3 and MaAsLin 2 accept counts or relative abundance, ANCOM-BC2 and ALDEx2 need counts, and LinDA is CLR-based (check its vignette). Then:

1. Apply a prevalence filter, for example present in at least 10% of samples, plus a minimum abundance. Report both thresholds.
2. Adjust for confounders. Unadjusted analysis both hides real associations and manufactures false ones.
3. Run at least two methods, report the consensus, and put the union in supplementary material.
4. Apply BH correction separately to taxonomy, community-level function, and stratified function.
5. State an effect-size threshold, not significance alone.
6. **Decide your exclusion rule for failed profiles in advance.** An empty profile, or one where a single taxon sits above 99%, is a failed sample rather than a finding. Apply the rule to controls and samples alike, and report how many samples it removed from each group.

On method choice: elaborate compositional methods often control false discovery rates worse than their complexity implies. Yang & Chen 2022 (*Microbiome* 10:130) report FDR inflation at small sample sizes, with linear models, Wilcoxon, limma and fastANCOM matching them on sensitivity. Nearing et al. 2022 (*Nature Communications*) found ALDEx2 and ANCOM-II the most conservative and most concordant across 38 datasets. At small N, read ALDEx2 as a defensible *conservative* choice — few false positives, low power — not the reliable one.

**Read-based abundances are compositional.** Use compositionally aware methods, and never pass relative abundances to an ordinary linear model as though they were counts.

### **Functional Tables**

`SOP_R_Analysis.md` does not cover these, so this SOP owns them. Run MaAsLin 2 or 3 on the `_unstratified` CPM tables — `genefamilies_cpm_unstratified.tsv`, `pathabundance_cpm_unstratified.tsv`, `ec_cpm_unstratified.tsv`, `ko_cpm_unstratified.tsv` — with `normalization = "NONE"`, because the tables are already CPM. **Never test an unsplit table.** It holds each feature's community total alongside the per-species rows that sum to it, so the tests are not independent and the multiple-testing correction is meaningless.

Treat the stratified tables as follow-up on features that came out significant, not as a primary test set. They are much larger, and testing them primarily costs you most of your power to multiple-testing correction.

---

## **14. Provenance**

Generate this as part of the run, not afterwards from memory.

```bash
module purge
module load FastQC/0.12.1 BBMap/39.01-GCC-11.3.0 \
            MetaPhlAn/4.1.0-gimkl-2022a-Python-3.10.5 Miniforge3/25.3.1-0
{
  echo "# Run provenance"; date -Iseconds; echo "host: $(hostname)"
  echo; echo "## Modules";  module list 2>&1
  echo; echo "## Versions"; fastqc --version; bbduk.sh --version 2>&1 | head -3
  metaphlan --version; conda run -n humann humann --version
  echo; echo "## Databases"; echo "MetaPhlAn index: ${MPA_INDEX:-UNSET}"
  conda run -n humann humann_config --print
  echo; echo "## Host reference"
  if [ -f "$DB/human/chm13v2.0.fa.gz.md5" ]; then
    echo "Option B (BBMap): unmasked T2T-CHM13"; cat "$DB/human/chm13v2.0.fa.gz.md5"
  else
    echo "Option A (Hostile): human-t2t-hla-argos985 (masked)"
  fi
  echo; echo "## Samples"; wc -l < samples.txt
} > versions.txt
grep -i "command not found\|UNSET" versions.txt && \
  echo "WARNING: provenance incomplete - fix module loads and re-run" >&2
```

Your methods section needs all of the following. Most of it is in `versions.txt`; the rest you have to record as you go.

- The MetaPhlAn index tag
- HUMAnN, ChocoPhlAn and UniRef versions
- The host reference, and whether it was masked
- Trimming parameters
- Depth gates applied
- Which samples were excluded, and why
- The contamination screening method and threshold
- Every model formula

---



## **Appendix A: Triage**

```bash
JOB=12345678
sacct -j "$JOB" --format=JobID,JobName%20,State,ExitCode,Elapsed,MaxRSS,ReqMem
nn_seff "$JOB"
sbatch --array=3,17,42 scripts/09.metaphlan.sl        # re-run failed tasks; the script clears its stale .bt2.bz2 first
while read -r S; do
  [[ -s "metaphlan/${S}.profile.tsv" ]] || echo "MISSING metaphlan: $S"
  [[ -s "humann/${S}/${S}_genefamilies.tsv" ]] || echo "MISSING humann: $S"
done < samples.txt
```

| Symptom | Cause |
| --- | --- |
| `OUT_OF_MEMORY` in Section 7 | `-Xmx` set too close to `--mem` |
| MetaPhlAn `Cannot find a local database` | `--index` unpinned and no internet (Section 9) |
| MetaPhlAn `BowTie2 output file detected … Exiting` | Stale `--bowtie2out` from a failed run; the §9 script's `rm -f` clears it — re-run the task |
| `Zero gene tables were found to join` | Missing `-s` (Section 11) |
| Section 10 fills the filesystem | Missing `--remove-temp-output`, or `TMPDIR` on a small filesystem |
| Empty MultiQC report | Ran before the FastQC array finished — use `--dependency` |
| `cd: no such file or directory` in Section 7 | Reference never downloaded (Section 3.3) |
| Nothing in `logs/` | `logs/` did not exist at submission |

## **Appendix C: Resources**

These are starting points. Size them on two or three samples and calibrate with `nn_seff` before launching a full cohort.

`-Xmx` should leave 15–25% of `--mem` free for JVM overhead, which sits outside the heap. Where two JVMs share a pipe, halve both the heap and the thread count.

| Script | mem | cpus | time | Notes |
| --- | --- | --- | --- | --- |
| Database installs (Sections 3.3, 10) | 8 GB | 4 | 2–4 h | Run under `srun`; needs ~25–30 GB + ~40 GB disk |
| `05a.qc_fastqc` | 4 GB | 2 | 30 m | One thread per file |
| `05b.qc_multiqc` | 4 GB | 1 | 20 m | Single-threaded |
| `06.trim` | 16 GB | 12 | 2 h | `-Xmx6g` ×2, `threads=6` ×2 |
| `07a.host_index` | 36 GB | 12 | 1 h | `-Xmx30g` |
| `07b.host_filter` | 32 GB | 20 | 1 h | `-Xmx26g` |
| `07.host_hostile` | 24 GB | 16 | 1 h | bowtie2 |
| `08.read_counts` | 4 GB | 1 | 2 h | Serial |
| `09.metaphlan` | 32 GB | 16 | 4 h | Pass 2 reuses the saved alignment |
| `10.humann` | 48 GB | 16 | 24 h | **100–170 GB temp per sample**; throttle to `%10` |
| Section 11 merge | 8 GB | 2 | 30 m | Run under `srun` |
