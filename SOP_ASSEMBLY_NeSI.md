*Taylor Lab | Assembly-Based Shotgun Metagenomics SOP*

# **Assembly and Binning: Recovering MAGs on NeSI**

**v0.1** | last updated August 2026 | NeSI (SLURM) | Illumina paired-end | suite v1.1 (August 2026, draft)

> **Draft (v0.1) — not yet through the lab's correctness and tutorial review rounds.** The other SOPs in this suite have each been through two dedicated reviews; this one has not. Treat every command as unverified end-to-end: run one sample first and check each checkpoint before you rely on results or scale to a cohort.

This document takes clean Illumina shotgun reads and reconstructs the genomes of the organisms in your sample — assembling reads into contigs, grouping contigs into bins, and curating those bins into metagenome-assembled genomes (**MAGs**). It ends with a dereplicated MAG set carrying GTDB taxonomy, quality metrics, functional annotations, and a MAG × sample abundance table, which then feeds `SOP_R_Analysis.md`.

Unlike read-based profiling (`SOP_READBASED_NeSI.md`), this workflow can recover organisms and genes that are in **no reference database** — the point of assembly. It costs far more compute, and needs deeper sequencing, in exchange.

### **Before you start**

- **You need clean, host-depleted reads.** This SOP starts where `SOP_READBASED_NeSI.md` reaches its depth gates (that SOP's Section 8): trimmed, PhiX-removed, host-depleted paired FASTQ files in a `clean/` directory, with a `samples.txt` manifest. Run that SOP's Sections 1–8 first. We do not repeat QC, trimming or host depletion here.
- **You need to have run one NeSI pipeline before.** Bash, `module`, `sbatch` and array jobs are taken as familiar. If they are not, work through `SOP_EMU_NeSI.md` Section 1 first — it is the only document that teaches the cluster.
- **This does not cover** long-read or hybrid assembly (Illumina only), viruses or plasmids (assembly recovers them but binning and CheckM2 are built for prokaryotes — a separate viral workflow is needed), or eukaryotic genomes.

---

## **Quick Roadmap: What You'll Do**

```
STAGE 1: Understand and plan
   What assembly gives you → governance → depth reality
                    ↓
STAGE 2: Reconstruct genomes
   Assemble → assess → map for coverage → bin → refine
                    ↓
STAGE 3: Curate the MAGs
   Quality (CheckM2 + MIMAG) → dereplicate → classify (GTDB-Tk)
                    ↓
STAGE 4: Annotate and quantify
   Annotate (Bakta; eggNOG/DRAM optional) → MAG × sample abundance
                    ↓
STAGE 5: Hand off
   Reshape → SOP_R_Analysis.md (compositional deltas) → provenance
```

Assembly (Section 4) and GTDB-Tk (Section 11) are by far the heaviest steps. Section 9 is a natural stop: look at your MAG quality before spending compute on annotation.

---

## **1. Understanding Your Data**

This section is concepts only — no commands. If assembly is new to you, read it once before running anything.

### **Assembly versus read-based profiling**

**Read-based** profiling (`SOP_READBASED_NeSI.md`) matches each read against a reference database. It is fast and works at low depth, but it can only report organisms already in the database and recovers no genomes. **Assembly** stitches overlapping reads into longer contiguous sequences (**contigs**), then groups contigs that belong to the same organism into a genome. It finds novel organisms, but needs more depth and far more compute.

Use assembly when you need the genomes themselves: novel or uncultured organisms, gene linkage (which functions co-occur in one genome), or strain-resolved biology.

### **From reads to a MAG**

Four ideas, in the order the pipeline uses them:

| Term | What it is |
| --- | --- |
| **Contig** | A single contiguous sequence assembled from overlapping reads. One genome fragments into many contigs. |
| **Coverage** | How deeply a contig was sequenced. Contigs from one genome share similar coverage across samples — a key binning signal. |
| **Bin** | A cluster of contigs grouped by composition and coverage, proposed to be one genome. |
| **MAG** | A metagenome-assembled genome: a bin that has passed quality control (completeness and contamination). |

### **Why binning uses two signals**

A binner groups contigs by **sequence composition** (k-mer frequencies, which are genome-characteristic) and by **coverage** (contigs of one genome rise and fall together across samples). Neither signal alone is enough, which is why we run three binners and reconcile them (Section 8): each weights the two signals differently, and their consensus is more complete and less contaminated than any one alone.

### **Completeness, contamination and the MIMAG tiers**

A MAG is judged on two numbers. **Completeness** estimates what fraction of the genome was recovered; **contamination** estimates what fraction of the bin comes from a *different* organism. The community standard (**MIMAG**, Bowers et al. 2017) sets the tiers we use in Section 9: high-quality (≥90% complete, <5% contamination, plus rRNA and tRNA genes) and medium-quality (≥50% complete, <10% contamination). Below medium-quality, a bin is not a MAG.

### **Dereplication and ANI**

Assemble ten samples that share a species and you get up to ten copies of its genome — one per sample. **Dereplication** collapses these to a single representative. It groups genomes by **average nucleotide identity (ANI)**, the genome-wide sequence similarity; two genomes above **95% ANI** are the same species (Jain et al. 2018). Section 10 dereplicates at 95% to build a species-level catalogue.

### **What GTDB gives you**

A MAG is a sequence with no name until you classify it. **GTDB-Tk** places each MAG in the Genome Taxonomy Database, a genome-based, phylogenetically consistent taxonomy, and returns a name from superkingdom to species (Section 11). Novel organisms come back classified only to the rank where they stop matching — an unnamed genus is a normal, informative result, not a failure.

### **The final table is compositional**

The last step (Section 14) maps every sample's reads back to the dereplicated MAG set and builds a **MAG × sample abundance table**. Because it is coverage-derived relative abundance — proportions that sum to a whole — it is **compositional**, and behaves like `SOP_READBASED_NeSI.md`'s MetaPhlAn output, not like an amplicon count table. Section 15 spells out what that changes in the R analysis.

---

## **2. Before You Generate Data**

Assembly does not change the governance, controls and depth planning in `SOP_READBASED_NeSI.md` Section 1 — **read that section before sequencing.** It changes three things, below.

### **Residual host sequence survives into contigs**

Read-level host depletion (that SOP's Section 7) is not perfect, and the reads it misses can *assemble* into contigs that then bin into a MAG. Screen your MAGs for human sequence before depositing them in a public archive. Treat a MAG carrying human contigs as controlled data, exactly as the read-based SOP treats host-depleted FASTQs.

### **Assembly needs more depth than profiling**

Read-based profiling detects an organism from a handful of marker-gene reads. Assembly needs enough coverage across the *whole* genome to connect it — a genome below roughly 5–10× coverage fragments into short contigs that will not bin. A rare organism that MetaPhlAn reports may leave no MAG at all. Budget depth accordingly: **≥5 Gb of clean sequence per sample** is a common floor for gut communities, more for diverse or high-host sites.

### **Controls still matter, differently**

A negative control should yield *no* MAG. If it does, you have found contamination that will also be in your real assemblies — investigate before trusting anything. A positive (mock) community is the only way to check that assembly and binning recover genomes you know are present.

---

## **3. Setup**

### **3.1 Directories and the input contract**

Assembly intermediates are large — assembly graphs and BAM files run to tens of gigabytes per sample — so everything lives on `nobackup`. Your input is the read-based SOP's `clean/` output; we link to it rather than copying.

```bash
ACCOUNT=<your_nesi_project_code>                 # your allocation code
WORK=/nesi/nobackup/$ACCOUNT/assembly
RB=/nesi/nobackup/$ACCOUNT/readbased            # where SOP_READBASED_NeSI.md ran

mkdir -p "$WORK"/{assemblies,coassembly,qc_assembly,mapping,bins,dastool,mags,checkm2,drep,gtdbtk,annotation,coverm,tables,logs,scripts}
cd "$WORK"

ln -sf "$RB/clean" clean                         # host-depleted reads = the input
cp "$RB/samples.txt" samples.txt
sed -i 's/\r$//; /^$/d' samples.txt              # CRLF / blank lines become an empty $SAMPLE
NSAMP=$(wc -l < samples.txt); echo "samples: $NSAMP"
```

> **Expect** `samples: N` matching your cohort, and `ls clean/*_R1.fastq.gz | wc -l` to equal it. **Fewer** clean files than samples means the read-based pipeline did not finish for every sample — go back and complete it before assembling, or you will assemble a truncated cohort without any error.

### **3.2 The job header**

Every script below is complete and runnable as printed: shebang, every `#SBATCH` directive, `set -euo pipefail`, and the array boilerplate where relevant. Copy a block, replace `<your_nesi_project_code>`, and submit. The one value you set at submission, never in the script, is the array range — `sbatch --array=1-${NSAMP}%4`. Forget it and the job runs on sample 1 only and exits 0, with no error to warn you.

### **3.3 A note on module strings**

Every module string here was confirmed on Mahuika in August 2026, but they drift — check with `module spider <tool>`, capitalisation included, before you rely on one. The tools and their confirmed versions are collected in Appendix B.

---

## **4. Assemble the Reads**

**Assembly** reconstructs contigs from your reads using a de Bruijn graph — it breaks reads into overlapping k-mers, threads a graph through them, and reads contigs off the graph. Two choices define this step: which **assembler**, and per-sample versus co-assembly.

### **Assembler: MEGAHIT (default) or metaSPAdes**

**We default to MEGAHIT.** It handles the uneven coverage of a metagenome well, and its memory footprint is modest enough to run per-sample on standard nodes. **metaSPAdes** often produces more contiguous assemblies on lower-diversity samples, but it can demand 200–250 GB of RAM and must queue on `hugemem` — a real cost you choose knowingly, not a free upgrade.

### **Strategy: per-sample or co-assembly**

There is no universal default, so decide by your study:

| Strategy | Recovers | Costs | Choose when |
| --- | --- | --- | --- |
| **Per-sample** | Strain variation preserved; bounded memory; mirrors the per-sample array of the read-based SOP | Misses organisms too rare in any single sample to assemble | Most studies — **the default unless the row below applies** |
| **Co-assembly** | Low-abundance organisms shared across samples, by pooling their reads | Blurs strain variation; much heavier; a single huge job | Many related, individually shallow samples where shared rare genomes are the goal |

**The rule: assemble per-sample unless you have many related, low-biomass samples and specifically want the rare genomes they share** — then co-assemble. The two are not exclusive; some studies do both and compare.

### **Per-sample assembly with MEGAHIT (default)**

`scripts/04a.assemble_megahit.sl` (array job):

```bash
#!/bin/bash
#SBATCH --account <your_nesi_project_code>
#SBATCH --job-name asm_megahit
#SBATCH --chdir /nesi/nobackup/<your_nesi_project_code>/assembly
#SBATCH --time 12:00:00
#SBATCH --mem 60G
#SBATCH --cpus-per-task 16
#SBATCH --output logs/%x_%A_%a.out
#SBATCH --error  logs/%x_%A_%a.err
# array range set at submission: sbatch --array=1-${NSAMP}%4 scripts/04a.assemble_megahit.sl

set -euo pipefail
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" samples.txt)
[[ -n "$SAMPLE" ]] || { echo "empty sample at ${SLURM_ARRAY_TASK_ID}"; exit 1; }

module purge; module load MEGAHIT/1.2.9-gimkl-2022a-Python-3.10.5

# MEGAHIT refuses to write into an existing output directory and exits 1, so a
# re-run of a failed task must start from a clean slate.
rm -rf "assemblies/${SAMPLE}"
megahit -1 "clean/${SAMPLE}_R1.fastq.gz" -2 "clean/${SAMPLE}_R2.fastq.gz" \
  -o "assemblies/${SAMPLE}" --out-prefix "${SAMPLE}" \
  --min-contig-len 1000 --k-list 21,29,39,59,79,99,119,141 \
  -t "${SLURM_CPUS_PER_TASK}" -m 0.9
```

- **`--min-contig-len 1000`.** Contigs shorter than ~1 kb carry too little composition and coverage signal to bin reliably. We keep 1 kb here and filter harder before binning (Section 5).
- **`-m 0.9`** caps MEGAHIT at 90% of the memory it detects. NeSI's cgroup limits it to your `--mem`, so leave the 10% headroom rather than setting `-m 1`.
- **The contigs land at** `assemblies/${SAMPLE}/${SAMPLE}.contigs.fa`.

**How long:** roughly 2–12 hours per gut sample; diverse or deep samples take longer.

### **Alternative: per-sample with metaSPAdes**

`scripts/04b.assemble_metaspades.sl` (array job) — swap this in only if you have chosen metaSPAdes:

```bash
#!/bin/bash
#SBATCH --account <your_nesi_project_code>
#SBATCH --job-name asm_spades
#SBATCH --chdir /nesi/nobackup/<your_nesi_project_code>/assembly
#SBATCH --time 24:00:00
#SBATCH --mem 250G
#SBATCH --partition hugemem
#SBATCH --cpus-per-task 20
#SBATCH --output logs/%x_%A_%a.out
#SBATCH --error  logs/%x_%A_%a.err
# array range set at submission: sbatch --array=1-${NSAMP}%2 scripts/04b.assemble_metaspades.sl

set -euo pipefail
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" samples.txt)
[[ -n "$SAMPLE" ]] || { echo "empty sample at ${SLURM_ARRAY_TASK_ID}"; exit 1; }

module purge; module load SPAdes/4.0.0-foss-2023a-Python-3.11.6
spades.py --meta -1 "clean/${SAMPLE}_R1.fastq.gz" -2 "clean/${SAMPLE}_R2.fastq.gz" \
  -o "assemblies/${SAMPLE}" -t "${SLURM_CPUS_PER_TASK}" -m 240

# metaSPAdes writes contigs.fasta; give it MEGAHIT's canonical name so Sections 5–8 need no change.
ln -sf contigs.fasta "assemblies/${SAMPLE}/${SAMPLE}.contigs.fa"
```

- **`-m 240`, under the 250 GB request.** SPAdes terminates itself the moment it exceeds `-m`, so setting it above your allocation trades a clean stop for an out-of-memory kill deep into a 24-hour run. metaSPAdes writes contigs to `assemblies/${SAMPLE}/contigs.fasta` — a different name from MEGAHIT's `${SAMPLE}.contigs.fa`, so the `ln -sf` line above gives it that canonical name and Sections 5–8 run unchanged.

**How long:** 8–24+ hours per sample, and the reason it is throttled to `%2`.

### **Alternative: co-assembly with MEGAHIT**

`scripts/04c.coassemble_megahit.sl` (single job, no array). MEGAHIT takes comma-separated file lists, so no concatenation is needed:

```bash
#!/bin/bash
#SBATCH --account <your_nesi_project_code>
#SBATCH --job-name asm_coassembly
#SBATCH --chdir /nesi/nobackup/<your_nesi_project_code>/assembly
#SBATCH --time 48:00:00
#SBATCH --mem 200G
#SBATCH --partition hugemem
#SBATCH --cpus-per-task 32
#SBATCH --output logs/%x_%j.out
#SBATCH --error  logs/%x_%j.err

set -euo pipefail
module purge; module load MEGAHIT/1.2.9-gimkl-2022a-Python-3.10.5

R1=$(ls clean/*_R1.fastq.gz | paste -sd,)        # comma-separated, all samples
R2=$(ls clean/*_R2.fastq.gz | paste -sd,)
rm -rf coassembly/all
megahit -1 "$R1" -2 "$R2" -o coassembly/all --out-prefix coassembly \
  --min-contig-len 1000 --k-list 21,29,39,59,79,99,119,141 \
  -t "${SLURM_CPUS_PER_TASK}" -m 0.9
```

If you co-assemble, the rest of the SOP treats `coassembly/all/coassembly.contigs.fa` as the single assembly, and Section 6 maps **every** sample against it (that is how co-assembly recovers per-sample coverage for binning).

### **Checkpoint**

```bash
grep -c "^>" assemblies/*/*.contigs.fa 2>/dev/null || grep -c "^>" coassembly/all/coassembly.contigs.fa
```

> **Expect** thousands to hundreds of thousands of contigs per assembly. **Zero, or a file that does not exist,** means the assembler failed — check the `.err` log for an out-of-memory kill (raise `--mem`, or move MEGAHIT to `hugemem`) before going on.

---

## **5. Assess the Assembly**

**metaQUAST** summarises an assembly: how many contigs, total length, N50 (the length such that half the assembly sits in contigs at least that long), and the largest contig. It tells you whether an assembly is worth binning before you spend compute mapping to it.

`scripts/05.metaquast.sl` (array job, one per assembly):

```bash
#!/bin/bash
#SBATCH --account <your_nesi_project_code>
#SBATCH --job-name metaquast
#SBATCH --chdir /nesi/nobackup/<your_nesi_project_code>/assembly
#SBATCH --time 01:00:00
#SBATCH --mem 16G
#SBATCH --cpus-per-task 8
#SBATCH --output logs/%x_%A_%a.out
#SBATCH --error  logs/%x_%A_%a.err
# array range set at submission: sbatch --array=1-${NSAMP} scripts/05.metaquast.sl

set -euo pipefail
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" samples.txt)
[[ -n "$SAMPLE" ]] || { echo "empty sample at ${SLURM_ARRAY_TASK_ID}"; exit 1; }

module purge; module load QUAST/5.2.0-gimkl-2022a
metaquast.py "assemblies/${SAMPLE}/${SAMPLE}.contigs.fa" \
  -o "qc_assembly/${SAMPLE}" --min-contig 1000 \
  --max-ref-number 0 --threads "${SLURM_CPUS_PER_TASK}"
```

- **`--max-ref-number 0` is not optional.** Without it, metaQUAST tries to *download* reference genomes from SILVA over the internet to compare against — which hangs or fails on a compute node with no network, and is not what you want for novel-genome work anyway. Zero turns off reference downloading and gives you a pure assembly summary.
- **`--min-contig 1000`** matches the assembler's floor so the statistics describe the contigs you will actually bin.

**How long:** a few minutes per assembly.

### **Filter short contigs before binning**

Binners lose accuracy on short contigs, so we drop everything under 1500 bp before Section 6. Run this once, interactively:

```bash
srun --account=<your_nesi_project_code> --time=00:20:00 --mem=4G --pty bash
module purge; module load SeqKit/2.4.0
while read -r S; do
  seqkit seq -m 1500 "assemblies/${S}/${S}.contigs.fa" > "assemblies/${S}/${S}.min1500.fa"
done < samples.txt
```

> **Expect** each `*.min1500.fa` to hold somewhat fewer contigs than the raw assembly. metaQUAST's report tells you how much length you removed — if you lose most of the assembly at 1500 bp, the sample was too shallow to assemble well, and its MAGs (if any) will be poor. Note it now rather than discovering it at Section 9.

**Co-assembly only.** There are no per-sample assemblies to loop over, so run metaQUAST and the min1500 filter **once** on the single co-assembly, in place of the array/loop above:

```bash
srun --account=<your_nesi_project_code> --time=01:00:00 --mem=8G --cpus-per-task=8 --pty bash
module purge; module load QUAST/5.2.0-gimkl-2022a
metaquast.py coassembly/all/coassembly.contigs.fa -o qc_assembly/coassembly \
  --min-contig 1000 --max-ref-number 0 --threads 8       # can take a while on a large co-assembly
module purge; module load SeqKit/2.4.0
seqkit seq -m 1500 coassembly/all/coassembly.contigs.fa > coassembly/all/coassembly.min1500.fa
exit
```

From here, `coassembly/all/coassembly.min1500.fa` is the single `$ASM` that Sections 6–8 use, and Section 6's mapping array still runs `1-${NSAMP}` — every sample is mapped to the one assembly.

---

## **6. Map Reads for Coverage**

Binning needs each contig's **coverage** — how deeply it was sequenced. We get it by mapping the reads back to the contigs with **minimap2**, sorting the alignments with **SAMtools**, and summarising per-contig depth with MetaBAT2's `jgi_summarize_bam_contig_depths`.

For **per-sample** assembly, map each sample to its own assembly (below). For **co-assembly**, map every sample to the one co-assembly instead, producing one BAM per sample — the coverage differences across samples are what let the binner separate genomes.

`scripts/06.map_coverage.sl` (array job):

```bash
#!/bin/bash
#SBATCH --account <your_nesi_project_code>
#SBATCH --job-name map_cov
#SBATCH --chdir /nesi/nobackup/<your_nesi_project_code>/assembly
#SBATCH --time 03:00:00
#SBATCH --mem 32G
#SBATCH --cpus-per-task 16
#SBATCH --output logs/%x_%A_%a.out
#SBATCH --error  logs/%x_%A_%a.err
# array range set at submission: sbatch --array=1-${NSAMP}%8 scripts/06.map_coverage.sl

set -euo pipefail
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" samples.txt)
[[ -n "$SAMPLE" ]] || { echo "empty sample at ${SLURM_ARRAY_TASK_ID}"; exit 1; }

module purge; module load minimap2/2.30-GCC-12.3.0 SAMtools/1.23.1-GCC-12.3.0
ASM="assemblies/${SAMPLE}/${SAMPLE}.min1500.fa"    # co-assembly: coassembly/all/coassembly.min1500.fa

# -ax sr = short-read preset. Pipe straight into samtools sort to avoid a huge SAM on disk.
minimap2 -t "${SLURM_CPUS_PER_TASK}" -ax sr "$ASM" \
    "clean/${SAMPLE}_R1.fastq.gz" "clean/${SAMPLE}_R2.fastq.gz" \
  | samtools sort -@ "${SLURM_CPUS_PER_TASK}" -o "mapping/${SAMPLE}.bam" -
samtools index "mapping/${SAMPLE}.bam"

module load MetaBAT/2.17-GCC-12.3.0
jgi_summarize_bam_contig_depths --outputDepth "mapping/${SAMPLE}.depth.txt" "mapping/${SAMPLE}.bam"
```

- **The depth file is shared by two of the three binners.** MetaBAT2 reads it directly; MaxBin2 needs one column of it (Section 7).

**How long:** 1–3 hours per sample.

> **Checkpoint:** `samtools flagstat mapping/${SAMPLE}.bam` should report a mapping rate in the tens of percent or higher. **A rate near zero** means reads and assembly do not match — usually the wrong `$ASM` path (a per-sample script pointed at a co-assembly, or vice versa).

---

## **7. Bin the Contigs**

We run three binners — **MetaBAT2**, **MaxBin2** and **CONCOCT** — and reconcile them in Section 8. Each groups contigs by composition and coverage but weights and models them differently, so their consensus recovers more genomes, more cleanly, than any single tool.

All three run in one array job per sample. The script is longer than most here because it drives three tools; each block is independent.

`scripts/07.bin.sl` (array job):

```bash
#!/bin/bash
#SBATCH --account <your_nesi_project_code>
#SBATCH --job-name bin
#SBATCH --chdir /nesi/nobackup/<your_nesi_project_code>/assembly
#SBATCH --time 06:00:00
#SBATCH --mem 48G
#SBATCH --cpus-per-task 16
#SBATCH --output logs/%x_%A_%a.out
#SBATCH --error  logs/%x_%A_%a.err
# array range set at submission: sbatch --array=1-${NSAMP}%6 scripts/07.bin.sl

set -euo pipefail
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" samples.txt)
[[ -n "$SAMPLE" ]] || { echo "empty sample at ${SLURM_ARRAY_TASK_ID}"; exit 1; }

ASM="assemblies/${SAMPLE}/${SAMPLE}.min1500.fa"
DEPTH="mapping/${SAMPLE}.depth.txt"
mkdir -p "bins/metabat/${SAMPLE}" "bins/maxbin/${SAMPLE}" "bins/concoct/${SAMPLE}"

# --- MetaBAT2: reads the jgi depth file directly ---
module purge; module load MetaBAT/2.17-GCC-12.3.0
metabat2 -i "$ASM" -a "$DEPTH" -o "bins/metabat/${SAMPLE}/bin" \
  -m 1500 -t "${SLURM_CPUS_PER_TASK}"

# --- MaxBin2: needs a two-column abundance file (contig <TAB> mean depth) ---
# jgi depth columns are: contigName, contigLen, totalAvgDepth, then per-BAM values.
# Columns 1 and 3 are exactly MaxBin's abundance input.
cut -f1,3 "$DEPTH" | tail -n +2 > "mapping/${SAMPLE}.maxbin_abund.txt"
module purge; module load MaxBin/2.2.7-GCC-11.3.0-Perl-5.34.1
run_MaxBin.pl -contig "$ASM" -out "bins/maxbin/${SAMPLE}/bin" \
  -abund "mapping/${SAMPLE}.maxbin_abund.txt" \
  -min_contig_length 1500 -thread "${SLURM_CPUS_PER_TASK}"

# --- CONCOCT: cut contigs into 10 kb chunks, build its own coverage table, cluster, merge back ---
module purge; module load CONCOCT/1.1.0-gimkl-2020a-Python-3.8.2 SAMtools/1.23.1-GCC-12.3.0
C="bins/concoct/${SAMPLE}"
cut_up_fasta.py "$ASM" -c 10000 -o 0 --merge_last -b "$C/contigs_10K.bed" > "$C/contigs_10K.fa"
concoct_coverage_table.py "$C/contigs_10K.bed" "mapping/${SAMPLE}.bam" > "$C/coverage_table.tsv"
concoct --composition_file "$C/contigs_10K.fa" --coverage_file "$C/coverage_table.tsv" \
  -b "$C/out" -t "${SLURM_CPUS_PER_TASK}"
merge_cutup_clustering.py "$C/out_clustering_gt1000.csv" > "$C/clustering_merged.csv"
mkdir -p "$C/fasta_bins"
extract_fasta_bins.py "$ASM" "$C/clustering_merged.csv" --output_path "$C/fasta_bins"
```

- **MetaBAT2 writes `bin.N.fa`, MaxBin2 writes `bin.NNN.fasta`, CONCOCT writes `N.fa`.** The extensions differ (`fa` vs `fasta`); Section 8 accounts for that.
- **CONCOCT is the multi-step one** because it bins 10 kb fragments, not whole contigs, then reassembles the clustering — do not skip `merge_cutup_clustering.py`, or bins will be fragments.

**How long:** 1–6 hours per sample, CONCOCT usually the slowest.

> **Checkpoint:** `ls bins/*/${SAMPLE}/*.fa bins/*/${SAMPLE}/*.fasta bins/concoct/${SAMPLE}/fasta_bins/*.fa 2>/dev/null | wc -l` should be non-zero. **Zero bins from all three** on a sample that assembled well points at the depth file — check it has more than a header line.

---

## **8. Refine the Bins**

**DAS_Tool** takes the three binners' outputs and picks the best, non-redundant set: it scores every candidate bin on single-copy marker genes and keeps the highest-scoring, non-overlapping combination. The result is one curated bin set per sample, better than any single binner produced.

DAS_Tool needs each bin set as a **contig-to-bin table** (contig name, tab, bin name). Its bundled helper `Fasta_to_Contig2Bin.sh` builds these; it lives in the module's `src/` directory, not on `PATH`, so we resolve its path from the `DAS_Tool` binary.

`scripts/08.dastool.sl` (array job):

```bash
#!/bin/bash
#SBATCH --account <your_nesi_project_code>
#SBATCH --job-name dastool
#SBATCH --chdir /nesi/nobackup/<your_nesi_project_code>/assembly
#SBATCH --time 02:00:00
#SBATCH --mem 32G
#SBATCH --cpus-per-task 16
#SBATCH --output logs/%x_%A_%a.out
#SBATCH --error  logs/%x_%A_%a.err
# array range set at submission: sbatch --array=1-${NSAMP}%6 scripts/08.dastool.sl

set -euo pipefail
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" samples.txt)
[[ -n "$SAMPLE" ]] || { echo "empty sample at ${SLURM_ARRAY_TASK_ID}"; exit 1; }

module purge; module load DAS_Tool/1.1.5-gimkl-2022a-R-4.2.1
FTC="$(dirname "$(command -v DAS_Tool)")/src/Fasta_to_Contig2Bin.sh"
mkdir -p "dastool/${SAMPLE}"

# Note the differing extensions: MetaBAT2/CONCOCT emit .fa, MaxBin2 emits .fasta.
"$FTC" -i "bins/metabat/${SAMPLE}"              -e fa    > "dastool/${SAMPLE}/metabat.tsv"
"$FTC" -i "bins/maxbin/${SAMPLE}"              -e fasta > "dastool/${SAMPLE}/maxbin.tsv"
"$FTC" -i "bins/concoct/${SAMPLE}/fasta_bins" -e fa    > "dastool/${SAMPLE}/concoct.tsv"

ASM="assemblies/${SAMPLE}/${SAMPLE}.min1500.fa"
DAS_Tool \
  -i "dastool/${SAMPLE}/metabat.tsv,dastool/${SAMPLE}/maxbin.tsv,dastool/${SAMPLE}/concoct.tsv" \
  -l metabat,maxbin,concoct -c "$ASM" -o "dastool/${SAMPLE}/${SAMPLE}" \
  --search_engine diamond --write_bins --threads "${SLURM_CPUS_PER_TASK}"
```

- **DAS_Tool ships its own single-copy-gene database**, so no reference download is needed.
- **`--write_bins` writes the curated FASTA files** to `dastool/${SAMPLE}/${SAMPLE}_DASTool_bins/`.
- **A sample can legitimately yield zero refined bins** if none of its candidates clears the internal score threshold — a real result for a shallow or very complex sample, not an error.

### **Collect every sample's MAGs into one place**

Dereplication and quality control work across the whole cohort, so gather all refined bins into `mags/`, prefixing filenames with the sample so IDs stay unique and traceable:

```bash
for d in dastool/*/*_DASTool_bins; do
  S=$(basename "$(dirname "$d")")
  for f in "$d"/*.fa; do
    [[ -e "$f" ]] || continue
    cp "$f" "mags/${S}__$(basename "$f")"
  done
done
ls mags/*.fa | wc -l
```

> **Expect** a total across all samples — tens to hundreds is typical. The `${S}__` prefix means a MetaBAT `bin.1.fa` from two samples never collides.

---

## **9. Assess MAG Quality**

**CheckM2** estimates every MAG's completeness and contamination with a machine-learning model trained on reference genomes. We use it rather than the older CheckM: it is a single command, its model handles novel lineages that lineage-specific marker sets miss, and its database is already installed on NeSI and wired into the module.

`scripts/09.checkm2.sl` (single job):

```bash
#!/bin/bash
#SBATCH --account <your_nesi_project_code>
#SBATCH --job-name checkm2
#SBATCH --chdir /nesi/nobackup/<your_nesi_project_code>/assembly
#SBATCH --time 04:00:00
#SBATCH --mem 32G
#SBATCH --cpus-per-task 16
#SBATCH --output logs/%x_%j.out
#SBATCH --error  logs/%x_%j.err

set -euo pipefail
module purge; module load CheckM2/1.0.1-Miniconda3
# The module sets CHECKM2DB to the shared diamond database - no download, no flag needed.
checkm2 predict --input mags/ -x fa --output-directory checkm2/ \
  --threads "${SLURM_CPUS_PER_TASK}" --force
```

**How long:** under an hour for a few hundred MAGs.

### **Apply the MIMAG tiers**

CheckM2 writes `checkm2/quality_report.tsv`, with `Completeness` and `Contamination` columns. Filter to at least medium quality — the working set for everything downstream:

```bash
# Medium-quality or better: completeness >=50 AND contamination <10 (MIMAG).
awk -F'\t' 'NR==1 || ($2>=50 && $3<10)' checkm2/quality_report.tsv > checkm2/mags_mq.tsv
tail -n +2 checkm2/mags_mq.tsv | cut -f1 | wc -l                       # how many pass
```

| MIMAG tier | Completeness | Contamination | Also requires |
| --- | --- | --- | --- |
| **High-quality** | ≥90% | <5% | 23S, 16S, 5S rRNA and ≥18 tRNAs present |
| **Medium-quality** | ≥50% | <10% | — |

- **We carry medium-quality and better forward,** and flag which are high-quality when reporting. CheckM2 does not check rRNA/tRNA genes, so full high-quality status needs a separate check (e.g. Bakta's output, Section 12) — completeness and contamination alone place a MAG at *medium*, not high.
- **Contamination above 10% is not automatically fatal** — it can mean a bin merged two close strains — but such bins do not belong in a MAG catalogue without manual refinement.

> **Checkpoint:** the passing count should be a sensible fraction of your total bins. **Zero passing** MAGs means either very shallow data or a binning problem — do not proceed to build a catalogue from nothing.

---

## **10. Dereplicate Across Samples**

Assemble a cohort that shares species and you get the same genome many times over. **dRep** collapses these to one representative per species: it clusters genomes by ANI and keeps the best-scoring member of each cluster, scored on completeness, contamination and contiguity. We feed it CheckM2's numbers directly so it does not re-run its own quality step.

`scripts/10.drep.sl` (single job):

```bash
#!/bin/bash
#SBATCH --account <your_nesi_project_code>
#SBATCH --job-name drep
#SBATCH --chdir /nesi/nobackup/<your_nesi_project_code>/assembly
#SBATCH --time 06:00:00
#SBATCH --mem 32G
#SBATCH --cpus-per-task 16
#SBATCH --output logs/%x_%j.out
#SBATCH --error  logs/%x_%j.err

set -euo pipefail
module purge; module load drep/3.4.2-gimkl-2022a-Python-3.10.5

# Build dRep's genomeInfo from CheckM2. dRep expects a CSV with header
# genome,completeness,contamination where 'genome' is the FASTA basename WITH extension.
{ echo "genome,completeness,contamination"
  tail -n +2 checkm2/quality_report.tsv | awk -F'\t' '{print $1".fa,"$2","$3}'
} > drep/genomeInfo.csv

dRep dereplicate drep/ -g mags/*.fa --genomeInfo drep/genomeInfo.csv \
  -comp 50 -con 10 -sa 0.95 -p "${SLURM_CPUS_PER_TASK}"
```

- **`-sa 0.95` sets the species boundary.** 95% ANI is the operational species threshold (Jain et al. 2018); the representatives in `drep/dereplicated_genomes/` are a species-level catalogue. For strain-level tracking, raise it to `-sa 0.99` and expect more, finer clusters.
- **`-comp 50 -con 10`** keep dRep's quality filter aligned with the MIMAG medium-quality gate from Section 9, so nothing sub-threshold sneaks back in.
- **Providing `--genomeInfo` is what stops dRep running CheckM itself** — without it, dRep would try to run its own (older) CheckM and could disagree with your Section 9 numbers.

> **Checkpoint:** `ls drep/dereplicated_genomes/*.fa | wc -l` is your species count — always ≤ the input MAG count, and usually well below it in a cohort with shared taxa. **A number equal to the input** means nothing dereplicated: check that `genomeInfo.csv` matched the filenames (the `.fa` suffix is the usual culprit).

---

## **11. Classify the MAGs**

**GTDB-Tk** names each dereplicated MAG by placing it in the Genome Taxonomy Database — identifying marker genes, aligning them, placing the genome in the GTDB reference tree, and assigning ANI-based species where one matches. It is the second heavy step after assembly.

`scripts/11.gtdbtk.sl` (single job):

```bash
#!/bin/bash
#SBATCH --account <your_nesi_project_code>
#SBATCH --job-name gtdbtk
#SBATCH --chdir /nesi/nobackup/<your_nesi_project_code>/assembly
#SBATCH --time 08:00:00
#SBATCH --mem 128G
#SBATCH --cpus-per-task 16
#SBATCH --output logs/%x_%j.out
#SBATCH --error  logs/%x_%j.err

set -euo pipefail
module purge; module load GTDB-Tk/2.7.1-foss-2023a-Python-3.11.6

# The module sets GTDBTK_DATA_PATH to the shared GTDB R232 release - confirm it before running.
echo "GTDBTK_DATA_PATH=${GTDBTK_DATA_PATH:?GTDB reference path not set by module}"

gtdbtk classify_wf --genome_dir drep/dereplicated_genomes -x fa \
  --out_dir gtdbtk --cpus "${SLURM_CPUS_PER_TASK}" --pplacer_cpus 1
```

- **`--pplacer_cpus 1` bounds the memory.** pplacer loads the reference tree once per thread, so more pplacer CPUs multiply the memory; one thread keeps it under the 128 GB request. It is the slow part, but the safe one.
- **Do not add `--full_tree`.** The unsplit bacterial tree needs more than 320 GB of RAM to load; the default split tree gives the same classification within the memory here.
- **This version uses skani for the ANI step, built into the R232 database** — no `--mash_db` flag and no separate download.

**How long:** roughly 1–4 hours for tens of MAGs; pplacer placement dominates.

### **Convert GTDB ranks to the repository vocabulary**

GTDB writes taxonomy as `d__Bacteria;p__…;s__…`. The R analysis expects the lab's seven lowercase ranks (`superkingdom` … `species`). Convert now, so the handoff table in Section 14 carries clean ranks:

```bash
srun --account=<your_nesi_project_code> --time=00:15:00 --mem=4G --pty bash
python3 - <<'PY'
import csv, glob, os
RANKS = ["superkingdom","phylum","class","order","family","genus","species"]
rows = []
for f in glob.glob("gtdbtk/classify/*.summary.tsv"):          # bac120 and/or ar53
    with open(f) as fh:
        for r in csv.DictReader(fh, delimiter="\t"):
            parts = {p[0]: p[3:] for p in (r["classification"].split(";"))
                     if len(p) > 3 and p[1:3] == "__"}
            # GTDB prefixes: d,p,c,o,f,g,s  ->  the seven repo ranks in order
            vals = [parts.get(k, "") for k in ["d","p","c","o","f","g","s"]]
            rows.append([r["user_genome"]] + vals)
with open("tables/mag_taxonomy.tsv","w",newline="") as out:
    w = csv.writer(out, delimiter="\t")
    w.writerow(["MAG"] + RANKS)
    w.writerows(sorted(rows))
print(f"{len(rows)} MAGs classified -> tables/mag_taxonomy.tsv")
PY
```

> **Expect** one row per dereplicated MAG, ranks lowercase and unprefixed. **Empty `species` fields are normal** — a novel organism is classified only as deep as it matches, and that gap is a finding, not an error.

---

## **12. Annotate the MAGs**

**Bakta** calls genes and assigns functions — coding sequences, rRNAs, tRNAs and more — using a database already installed on NeSI. Its rRNA/tRNA calls are also what let you confirm the high-quality MIMAG tier from Section 9.

First list the dereplicated MAGs so the array can index them:

```bash
ls drep/dereplicated_genomes/*.fa | xargs -n1 basename | sed 's/\.fa$//' > mags_derep.txt
NMAG=$(wc -l < mags_derep.txt); echo "MAGs to annotate: $NMAG"
```

`scripts/12.bakta.sl` (array job):

```bash
#!/bin/bash
#SBATCH --account <your_nesi_project_code>
#SBATCH --job-name bakta
#SBATCH --chdir /nesi/nobackup/<your_nesi_project_code>/assembly
#SBATCH --time 02:00:00
#SBATCH --mem 32G
#SBATCH --cpus-per-task 16
#SBATCH --output logs/%x_%A_%a.out
#SBATCH --error  logs/%x_%A_%a.err
# array range set at submission: sbatch --array=1-${NMAG}%10 scripts/12.bakta.sl

set -euo pipefail
MAG=$(sed -n "${SLURM_ARRAY_TASK_ID}p" mags_derep.txt)
[[ -n "$MAG" ]] || { echo "empty MAG at ${SLURM_ARRAY_TASK_ID}"; exit 1; }

module purge; module load bakta/1.10.1-foss-2023a
bakta --db /opt/nesi/db/bakta/v5.1/db \
  --output "annotation/bakta/${MAG}" --prefix "${MAG}" \
  --threads "${SLURM_CPUS_PER_TASK}" \
  "drep/dereplicated_genomes/${MAG}.fa"
```

- **The database is the shared 72 GB Bakta v5.1 build** at `/opt/nesi/db/bakta/v5.1/db` — no download.
- **Each MAG gets its own output directory** with `.gff3`, `.tsv`, `.faa` (proteins) and more. The `.faa` feeds the optional functional step below.

> **Checkpoint:** `ls annotation/bakta/*/*.tsv | wc -l` should equal `$NMAG`. A MAG with **zero coding sequences** is not a real genome — cross-check it against its CheckM2 completeness.

---

## **13. Deep Functional Annotation (Optional)**

Bakta names genes; for pathway- and orthology-level function, two tools go further. **Both are optional and heavy** — run them only if your questions need functional profiles, and skip to Section 14 if a taxonomic MAG catalogue is enough.

### **eggNOG-mapper — orthology and functional categories**

eggNOG-mapper assigns each protein to an orthologous group and its KEGG, GO and COG annotations. It runs on Bakta's predicted proteins.

`scripts/13a.eggnog.sl` (array job over `mags_derep.txt`):

```bash
#!/bin/bash
#SBATCH --account <your_nesi_project_code>
#SBATCH --job-name eggnog
#SBATCH --chdir /nesi/nobackup/<your_nesi_project_code>/assembly
#SBATCH --time 04:00:00
#SBATCH --mem 32G
#SBATCH --cpus-per-task 16
#SBATCH --output logs/%x_%A_%a.out
#SBATCH --error  logs/%x_%A_%a.err
# array range set at submission: sbatch --array=1-${NMAG}%6 scripts/13a.eggnog.sl

set -euo pipefail
MAG=$(sed -n "${SLURM_ARRAY_TASK_ID}p" mags_derep.txt)
[[ -n "$MAG" ]] || { echo "empty MAG at ${SLURM_ARRAY_TASK_ID}"; exit 1; }

module purge; module load eggnog-mapper/2.1.12-gimkl-2022a
mkdir -p annotation/eggnog
# The module does NOT point at a database; its bundled data directory is empty and
# emapper fails with "not a valid file" unless --data_dir names the shared install.
emapper.py -i "annotation/bakta/${MAG}/${MAG}.faa" --itype proteins \
  -m diamond --data_dir /opt/nesi/db/eggnog_db/data \
  -o "${MAG}" --output_dir annotation/eggnog --cpu "${SLURM_CPUS_PER_TASK}"
```

- **`--data_dir /opt/nesi/db/eggnog_db/data` is mandatory.** Loading the module alone leaves eggNOG-mapper pointing at an empty bundled directory, and it exits with `not a valid file`. The 94 GB shared install has the real `eggnog.db` and diamond database.
- **`-m diamond`** uses the pre-built diamond database rather than HMMER — far faster for whole genomes.

### **DRAM — metabolic reconstruction**

**DRAM** distills annotations into a metabolism summary — carbon, nitrogen and sulfur cycling and more. Treat it as advanced and expensive: its reference set is a 539 GB shared install, and a run over many MAGs takes many hours.

We confirmed the tool loads and its database is present, but a full run needs real MAGs and long walltime. Validate on one or two MAGs before scaling, and check `DRAM.py annotate` sees the shared configuration — `DRAM-setup.py print_config` can be slow to return.

```bash
#!/bin/bash
#SBATCH --account <your_nesi_project_code>
#SBATCH --job-name dram
#SBATCH --chdir /nesi/nobackup/<your_nesi_project_code>/assembly
#SBATCH --time 24:00:00
#SBATCH --mem 200G
#SBATCH --cpus-per-task 20
#SBATCH --output logs/%x_%j.out
#SBATCH --error  logs/%x_%j.err

set -euo pipefail
module purge; module load DRAM/1.3.5-Miniconda3
DRAM.py annotate -i 'drep/dereplicated_genomes/*.fa' \
  -o annotation/dram --threads "${SLURM_CPUS_PER_TASK}"
DRAM.py distill -i annotation/dram/annotations.tsv -o annotation/dram/distilled
```

- **Start with two MAGs, calibrate walltime and memory with `nn_seff`, then scale.** DRAM is the most likely step in this SOP to exceed its allocation on a first run.

---

## **14. Build the MAG × Sample Abundance Table**

The catalogue tells you *which* genomes exist; this step tells you *how much* of each is in *each* sample. **CoverM** maps every sample's reads against the whole dereplicated MAG set and reports each MAG's relative abundance per sample — one MAG × sample matrix. Mapping against the full set (not each sample's own MAGs) is what gives every MAG a value in every sample, even where it was only assembled once.

`scripts/14.coverm.sl` (single job):

```bash
#!/bin/bash
#SBATCH --account <your_nesi_project_code>
#SBATCH --job-name coverm
#SBATCH --chdir /nesi/nobackup/<your_nesi_project_code>/assembly
#SBATCH --time 08:00:00
#SBATCH --mem 48G
#SBATCH --cpus-per-task 24
#SBATCH --output logs/%x_%j.out
#SBATCH --error  logs/%x_%j.err

set -euo pipefail
# CoverM's genome mode shells out to minimap2 (its mapper) and samtools; the CoverM
# module bundles neither. Note SAMtools 1.23.1 (used in Section 6) is broken here by
# CoverM's LegacySystemLibs/7 dependency (a krb5 symbol clash) — pin 1.19 for this step.
module purge; module load CoverM/0.7.0-GCC-12.3.0 minimap2/2.30-GCC-12.3.0 SAMtools/1.19-GCC-12.3.0

# Build the coupled read list across ALL samples, in manifest order.
READS=()
while read -r S; do READS+=("clean/${S}_R1.fastq.gz" "clean/${S}_R2.fastq.gz"); done < samples.txt

# Relative abundance for beta diversity and decontam.
coverm genome --coupled "${READS[@]}" \
  --genome-fasta-directory drep/dereplicated_genomes -x fa \
  --methods relative_abundance --min-covered-fraction 0.10 \
  --threads "${SLURM_CPUS_PER_TASK}" -o coverm/mag_relabund.tsv

# Read counts for differential abundance (the DA tools need counts). CoverM rejects
# `count` when --min-covered-fraction > 0 (count computes no covered fraction, so it
# errors out and writes nothing); presence is already gated by the relative_abundance
# table above, so set the fraction to 0 here.
coverm genome --coupled "${READS[@]}" \
  --genome-fasta-directory drep/dereplicated_genomes -x fa \
  --methods count --min-covered-fraction 0 \
  --threads "${SLURM_CPUS_PER_TASK}" -o coverm/mag_counts.tsv
```

- **`-x fa`** matches dRep's output extension; CoverM defaults to `fna` and would otherwise find no genomes.
- **`--min-covered-fraction 0.10`** reports a MAG as present in a sample only if at least 10% of its length is covered, which suppresses spurious low-level cross-mapping. Report the value you use.
- **Two tables on purpose:** relative abundance for compositional analyses, counts for differential abundance — the same split the read-based SOP makes (its Section 13).

> **Checkpoint:** both tables should have one row per MAG and one column per sample (the relative-abundance table also carries an `unmapped` row; the count table does not). **A column of all zeros** for a real sample usually means its reads never reached `clean/` — reconcile against `samples.txt`.

---

## **15. Handoff to the R Analysis**

Follow `SOP_R_Analysis.md` for the statistics. This section covers only what differs because MAG abundances are **coverage-derived and compositional**, not amplicon counts. The differences mirror the read-based SOP's Section 13 — a MAG × sample table behaves like a MetaPhlAn table, not like an Emu count table.

### **Reshape before you open the R analysis**

The R analysis expects taxa in rows with named rank columns before the sample columns. Join CoverM's abundances to the GTDB taxonomy from Section 11:

```bash
srun --account=<your_nesi_project_code> --time=00:15:00 --mem=4G --pty bash
python3 - <<'PY'
import pandas as pd
tax = pd.read_csv("tables/mag_taxonomy.tsv", sep="\t")             # MAG + 7 ranks
for src, out in [("coverm/mag_relabund.tsv","tables/part2_relab.tsv"),
                 ("coverm/mag_counts.tsv",  "tables/part2_counts.tsv")]:
    ab = pd.read_csv(src, sep="\t")
    ab.columns = [c.split(" ")[0].split("/")[-1].replace("_R1.fastq.gz","")
                  for c in ab.columns]                              # tidy sample IDs
    ab = ab.rename(columns={ab.columns[0]: "MAG"})
    ab = ab[ab["MAG"] != "unmapped"]
    pd.merge(tax, ab, on="MAG", how="right").to_csv(out, sep="\t", index=False)
    print(out)
PY
```

`part2_relab.tsv` holds relative abundance; use it for beta diversity and `decontam`, and never round it or pass it through SRS. `part2_counts.tsv` holds read counts; round it in R and use it **only** for differential abundance.

### **What changes in the R analysis**

| Step | On MAG input |
| --- | --- |
| **SRS normalisation** | **Skip it.** Relative abundance is already depth-normalised. If depth varies enough to worry you, subsample the FASTQs before Section 6, not the table afterwards. |
| **Chao1 / ACE** | **Invalid.** They extrapolate from singletons and doubletons, which a MAG catalogue does not have. Use Shannon, Simpson, Pielou. |
| **Observed richness** | Number of MAGs detected — interpretable, but it tracks catalogue completeness and `--min-covered-fraction`, not true richness. Report the threshold. |
| **decontam** | Prevalence method, on `part2_relab.tsv`. |
| **Differential abundance** | Use `part2_counts.tsv`, rounded. ANCOM-BC2 and ALDEx2 need counts; treat the abundances as compositional and use compositionally aware methods. |
| **`ps_` object names** | `ps_relab` and `ps_estcounts`, as in the read-based SOP — the suffix names what the table holds. |
| **phylogenetic diversity (UniFrac, Faith's PD)** | **Available, unlike the read-based path.** GTDB-Tk emits a placement tree (`gtdbtk/classify/*.classify.tree`); with it you can compute UniFrac and Faith's PD in R. The R analysis does not cover the mechanics, so treat this as your own extension. |

### **Where MAG analysis legitimately diverges**

A MAG table is more than a taxonomy table — its rows are **genomes you reconstructed**, not database hits. Three consequences:

- An organism present but too rare to assemble is absent from the catalogue — a coverage limit, not a database gap.
- Two MAGs more than 95% ANI apart are two rows, even where GTDB gives them the same species name.
- Each row links to a genome you can annotate (Sections 12–13), so function and taxonomy come from the *same* object, not two separate profilers.

Say in your methods that abundances are coverage-based and compositional, and report the dereplication ANI and `--min-covered-fraction`.

---

## **16. Provenance**

Generate this as part of the run, not afterwards from memory. Your methods section needs it.

```bash
#!/bin/bash
#SBATCH --account <your_nesi_project_code>
#SBATCH --job-name provenance
#SBATCH --chdir /nesi/nobackup/<your_nesi_project_code>/assembly
#SBATCH --time 00:10:00
#SBATCH --mem 2G
#SBATCH --cpus-per-task 1
#SBATCH --output logs/%x_%j.out
#SBATCH --error  logs/%x_%j.err

set -euo pipefail
{
  echo "# Assembly run provenance"; date -Iseconds; echo "host: $(hostname)"
  echo; echo "## Modules used"
  module -t spider MEGAHIT SPAdes QUAST MetaBAT MaxBin CONCOCT DAS_Tool \
    CheckM2 drep GTDB-Tk bakta eggnog-mapper CoverM 2>&1 | sort -u
  echo; echo "## Key parameters"
  echo "assembler: MEGAHIT 1.2.9 (or metaSPAdes 4.0.0)"
  echo "strategy: per-sample (or co-assembly)"
  echo "contig min length for binning: 1500 bp"
  echo "MIMAG gate: completeness >=50, contamination <10"
  echo "dereplication ANI: 0.95 (species)"
  echo "GTDB release: ${GTDBTK_DATA_PATH:-set at classify time}"
  echo "CoverM min-covered-fraction: 0.10"
  echo; echo "## MAG counts"
  echo "bins total:     $(ls mags/*.fa 2>/dev/null | wc -l)"
  echo "dereplicated:   $(ls drep/dereplicated_genomes/*.fa 2>/dev/null | wc -l)"
} > versions.txt
cat versions.txt
```

Record additionally, as you go: which samples yielded no MAGs and why, the GTDB release tag (from `${GTDBTK_DATA_PATH}`), the Bakta and eggNOG database versions, and whether MAGs were screened for host sequence before any deposition.

---

## **Troubleshooting**

| Symptom | Cause and fix |
| --- | --- |
| MEGAHIT exits 1 immediately | Output directory already exists — the script's `rm -rf` clears it; re-run the task. |
| Assembly job `OUT_OF_MEMORY` | Raise `--mem`; for metaSPAdes move to `hugemem` and set `-m` a little under the request. |
| metaQUAST hangs or fails on a compute node | Missing `--max-ref-number 0` — it was trying to download references over a network the node does not have. |
| `flagstat` shows ~0% mapped | `$ASM` points at the wrong assembly (per-sample vs co-assembly), or at the pre-filter contigs. |
| All three binners return nothing | Depth file is header-only — check Section 6 produced real coverage; check the BAM is indexed. |
| DAS_Tool writes no bins | No candidate cleared the score threshold — legitimate for a shallow/complex sample; confirm the input `.tsv` tables are non-empty. |
| dRep dereplicates nothing (output = input) | `genomeInfo.csv` genome names did not match the FASTA basenames — they need the `.fa` extension. |
| GTDB-Tk killed on memory | `--full_tree` was set (needs >320 GB); remove it, and keep `--pplacer_cpus 1`. |
| eggNOG-mapper: `not a valid file` | Missing `--data_dir /opt/nesi/db/eggnog_db/data`. |
| CoverM finds no genomes | Missing `-x fa` (it defaults to `fna`). |
| CoverM: `Cannot continue without minimap2`, or `samtools: symbol lookup error … krb5` | Section 14 needs `minimap2/2.30-GCC-12.3.0` and `SAMtools/1.19-GCC-12.3.0` loaded alongside CoverM — it bundles no mapper, and the newer SAMtools 1.23.1 from Section 6 is broken here by CoverM's `LegacySystemLibs/7`. |
| Any array runs only sample 1 | The `--array` range was left at the header placeholder — set it at submission. |

---

## **Appendix A: Submission Chain**

Run from `$WORK`. Each job waits on the one it depends on, so you can submit the pipeline at once and let SLURM sequence it. This assumes per-sample assembly with MEGAHIT; swap `04a` for `04b`/`04c` if you chose otherwise.

```bash
cd "$WORK"; NSAMP=$(wc -l < samples.txt)

ASM=$(sbatch --parsable --array=1-${NSAMP}%4 scripts/04a.assemble_megahit.sl)
QC=$(sbatch  --parsable --dependency=afterok:$ASM --array=1-${NSAMP} scripts/05.metaquast.sl)
# Filter to min1500 interactively (Section 5) after assembly, before mapping.
MAP=$(sbatch  --parsable --dependency=afterok:$ASM --array=1-${NSAMP}%8 scripts/06.map_coverage.sl)
BIN=$(sbatch  --parsable --dependency=afterok:$MAP --array=1-${NSAMP}%6 scripts/07.bin.sl)
DAS=$(sbatch  --parsable --dependency=afterok:$BIN --array=1-${NSAMP}%6 scripts/08.dastool.sl)
# Collect bins into mags/ (Section 8) after DAS_Tool, before CheckM2.
CM2=$(sbatch  --parsable --dependency=afterok:$DAS scripts/09.checkm2.sl)
DREP=$(sbatch --parsable --dependency=afterok:$CM2 scripts/10.drep.sl)
GTDB=$(sbatch --parsable --dependency=afterok:$DREP scripts/11.gtdbtk.sl)
# Build mags_derep.txt (Section 12) after dRep.
BAK=$(sbatch  --parsable --dependency=afterok:$DREP --array=1-${NMAG}%10 scripts/12.bakta.sl)
       sbatch --dependency=afterok:$DREP scripts/14.coverm.sl

squeue --me
```

The two interactive steps (contig filtering, bin collection) break the chain deliberately — they are quick, and each is a point to look at your data before committing the next heavy stage.

## **Appendix B: Tools and Resources**

Confirmed on Mahuika, August 2026. Every module string will drift — check with `module spider` before relying on one. All large reference databases are hosted centrally on NeSI; you download none of them.

| Stage | Tool | Module string | Reference database |
| --- | --- | --- | --- |
| Assembly | MEGAHIT | `MEGAHIT/1.2.9-gimkl-2022a-Python-3.10.5` | — |
| Assembly (alt) | metaSPAdes | `SPAdes/4.0.0-foss-2023a-Python-3.11.6` (`spades.py --meta`) | — |
| Assembly QC | metaQUAST | `QUAST/5.2.0-gimkl-2022a` | — |
| Contig filter | SeqKit | `SeqKit/2.4.0` | — |
| Mapping | minimap2 + SAMtools | `minimap2/2.30-GCC-12.3.0`, `SAMtools/1.23.1-GCC-12.3.0` | — |
| Binning | MetaBAT2 | `MetaBAT/2.17-GCC-12.3.0` | — |
| Binning | MaxBin2 | `MaxBin/2.2.7-GCC-11.3.0-Perl-5.34.1` | — |
| Binning | CONCOCT | `CONCOCT/1.1.0-gimkl-2020a-Python-3.8.2` | — |
| Refinement | DAS_Tool | `DAS_Tool/1.1.5-gimkl-2022a-R-4.2.1` | bundled (self-contained) |
| MAG quality | CheckM2 | `CheckM2/1.0.1-Miniconda3` | `CHECKM2DB` auto-set (2.9 GB) |
| Dereplication | dRep | `drep/3.4.2-gimkl-2022a-Python-3.10.5` | — |
| Taxonomy | GTDB-Tk | `GTDB-Tk/2.7.1-foss-2023a-Python-3.11.6` | `GTDBTK_DATA_PATH` auto-set → GTDB R232 (hosted) |
| Annotation | Bakta | `bakta/1.10.1-foss-2023a` | `/opt/nesi/db/bakta/v5.1/db` (72 GB) |
| Function (opt) | eggNOG-mapper | `eggnog-mapper/2.1.12-gimkl-2022a` | `/opt/nesi/db/eggnog_db/data` (94 GB) — pass `--data_dir` |
| Metabolism (opt) | DRAM | `DRAM/1.3.5-Miniconda3` | `/opt/nesi/db/DRAM_1.3.5` (539 GB) |
| Abundance | CoverM (+ minimap2, SAMtools 1.19) | `CoverM/0.7.0-GCC-12.3.0`, `minimap2/2.30-GCC-12.3.0`, `SAMtools/1.19-GCC-12.3.0` | CoverM bundles no mapper; pin SAMtools 1.19, not the 1.23.1 used in Section 6 |

Starting-point resources — size on two or three samples and calibrate with `nn_seff` before a full cohort:

| Script | mem | cpus | time | Notes |
| --- | --- | --- | --- | --- |
| `04a.assemble_megahit` | 60 GB | 16 | 12 h | Per gut sample; deeper/diverse take longer |
| `04b.assemble_metaspades` | 250 GB | 20 | 24 h | `hugemem`; `-m` a little under `--mem` |
| `04c.coassemble_megahit` | 200 GB | 32 | 48 h | `hugemem`; one job, all samples |
| `05.metaquast` | 16 GB | 8 | 1 h | `--max-ref-number 0` |
| `06.map_coverage` | 32 GB | 16 | 3 h | minimap2 → sort → jgi depth |
| `07.bin` | 48 GB | 16 | 6 h | Three binners; CONCOCT slowest |
| `08.dastool` | 32 GB | 16 | 2 h | diamond search |
| `09.checkm2` | 32 GB | 16 | 4 h | Whole cohort at once |
| `10.drep` | 32 GB | 16 | 6 h | skani ANI |
| `11.gtdbtk` | 128 GB | 16 | 8 h | `--pplacer_cpus 1`; never `--full_tree` |
| `12.bakta` | 32 GB | 16 | 2 h | Per MAG |
| `13a.eggnog` | 32 GB | 16 | 4 h | Optional; needs `--data_dir` |
| `13b.dram` | 200 GB | 20 | 24 h | Optional; validate on 1–2 MAGs first |
| `14.coverm` | 48 GB | 24 | 8 h | Maps every sample to the catalogue |

## **Appendix C: References**

Cite the tools, not this SOP.

- **MEGAHIT** — Li et al. 2015, *Bioinformatics* 31:1674.
- **metaSPAdes** — Nurk et al. 2017, *Genome Research* 27:824.
- **QUAST/metaQUAST** — Mikheenko et al. 2016, *Bioinformatics* 32:1088.
- **MetaBAT2** — Kang et al. 2019, *PeerJ* 7:e7359.
- **MaxBin2** — Wu et al. 2016, *Bioinformatics* 32:605.
- **CONCOCT** — Alneberg et al. 2014, *Nature Methods* 11:1144.
- **DAS_Tool** — Sieber et al. 2018, *Nature Microbiology* 3:836.
- **CheckM2** — Chklovski et al. 2023, *Nature Methods* 20:1203.
- **MIMAG standard** — Bowers et al. 2017, *Nature Biotechnology* 35:725.
- **dRep** — Olm et al. 2017, *ISME Journal* 11:2864.
- **95% ANI species boundary** — Jain et al. 2018, *Nature Communications* 9:5114.
- **GTDB-Tk** — Chaumeil et al. 2022, *Bioinformatics* 38:5315; **GTDB** — Parks et al. 2022, *Nucleic Acids Research* 50:D785.
- **Bakta** — Schwengers et al. 2021, *Microbial Genomics* 7:000685.
- **eggNOG-mapper** — Cantalapiedra et al. 2021, *Molecular Biology and Evolution* 38:5825.
- **DRAM** — Shaffer et al. 2020, *Nucleic Acids Research* 48:8883.
- **CoverM** — Aroney et al., https://github.com/wwood/CoverM.

---

**Before relying on this SOP, verify the environment.** Confirm the Appendix B module strings with `module spider` (capitalisation included), that `/opt/nesi/db` still hosts the GTDB, Bakta and eggNOG databases, and that your clean reads from `SOP_READBASED_NeSI.md` are in place.

This document was probed against NeSI Mahuika in August 2026: the heavy steps (assembly, GTDB-Tk) and the optional DRAM path were confirmed to load and resolve their databases, but a full cohort run on real data was not timed here. Calibrate walltime on two or three samples first.
