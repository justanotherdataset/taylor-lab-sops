*Taylor Lab | Full-Length 16S rRNA Nanopore SOP*

# **Part 1: NeSI Pipeline (Sequencing to Count Tables)**

**v2.0** | last updated July 2026 | NeSI (SLURM) | Oxford Nanopore full-length 16S

This document covers everything from logging into NeSI through to generating combined count tables with Emu. The statistics that follow are in `SOP_R_Analysis.md`, which numbers its own sections from 1.

**It assumes no prior command-line experience** and starts from `pwd`. It is the only document in this set that teaches the cluster itself; the other three assume it.

**NeSI module versions used in this SOP:**

| Tool | Module string |
| --- | --- |
| Emu | `Emu/3.6.2` |
| NanoPlot | `NanoPlot/1.43.0-foss-2023a-Python-3.11.6` |
| chopper | `chopper/0.12.0b-GCC-12.3.0` |

Verify the latest Emu module on your cluster with `module spider Emu`. The commands here are compatible with v3.4.0+.

## Analysis steps

1. Getting started on NeSI
2. Understanding your data
3. Processing Nanopore reads (NanoPlot QC, chopper filtering, NanoPlot QC again)
4. Taxonomy and community profiling with Emu (databases, running Emu, combining outputs)

The R analysis that follows — phyloseq, decontamination, SRS normalisation, diversity, differential abundance and write-up — is in `SOP_R_Analysis.md`.

## 1. Getting Started on NeSI

> **Before you begin:** Replace `<your_nesi_project_code>` with your NeSI project allocation code (e.g., uoa03068) and `<your_project>` with your project directory name throughout.

### What is NeSI and why we use it

NeSI (New Zealand eScience Infrastructure) is a national high-performance computing platform, a very powerful shared computer that researchers across New Zealand use. Bioinformatic analyses need more memory, processing power, and storage than a laptop provides. A typical laptop has 8-16 GB of RAM and 2-4 CPU cores; NeSI nodes can have 256+ GB and 64+ cores. NeSI also has most bioinformatics tools pre-installed as modules, so you skip installation and dependency management, and it lets you run long jobs in the background. Submit a job, close your laptop, do labwork, come back later for the results.

### Logging in

Go to https://ondemand.nesi.org.nz/public/ and log in. Several applications are available; we use Mahuika Shell Access (the terminal where you submit jobs with `sbatch`) and Jupyter Lab (a GUI for file navigation and editing).

One gotcha with Jupyter Lab: the terminal pane and the file-explorer pane operate independently. `cd`-ing in the terminal does not change what the file explorer shows, and clicking through folders in the explorer does not change your terminal's working directory. If your scripts seem to be missing, check that the file explorer is pointing at your working directory and not the default landing folder. Right-click a folder in the explorer and choose "Open in Terminal" to launch a terminal already pointed there.

You start in your home directory (`/home/<username>/`). NeSI has three filesystems, and which one you use depends on what you are storing:

- `/home/<username>/` — your landing directory. Use for shell configs, login scripts, and small personal files. Small quota, backed up.
- `/nesi/project/<your_nesi_project_code>/` — persistent, backed-up project storage. Use for SLURM scripts, final result tables, and anything that would be painful to lose.
- `/nesi/nobackup/<your_nesi_project_code>/` — large, fast scratch space. Use for raw FASTQs, reference databases, and intermediate outputs. Not backed up, and files may be purged on a rolling basis. Do not store irreplaceable data here.

A reasonable habit: keep raw data and databases on nobackup, keep scripts and final outputs on project. If you `rm` something on nobackup, it is gone.

Because you will be working out of `/nesi/nobackup/<your_nesi_project_code>/<your_project>/` constantly, typing the full path gets old fast. A symbolic link (symlink) is a shortcut: a small pointer file that resolves to a real directory elsewhere. Create one from your home directory and you can `cd` into your workspace from anywhere:

```bash
ln -s /nesi/nobackup/<your_nesi_project_code>/<your_project> ~/proj
```

Now `cd ~/proj` takes you straight there, even right after logging in. Name it whatever you like. You can have several pointing at different places (e.g. `~/db` for Emu databases, `~/raw` for raw FASTQs). If you forget where a symlink points, `realpath` resolves it:

```bash
realpath ~/proj
```

Symlinks are cheap to make and safe to delete: `rm ~/proj` removes the symlink, not the directory it points to. **Do not run `rm -r ~/proj`**, which follows the link and recursively deletes the target. Just `rm`.

### Basic bash commands

The terminal is a text-based interface. Instead of clicking on folders and files, you type commands. The essentials:

**Moving around:**

```bash
pwd                               # print working directory (where you are)
cd /nesi/nobackup/<your_nesi_project_code>/<your_project>/   # change directory
cd my_folder                      # move into a subfolder
cd ..                             # go up one level
cd ~                              # go to your home directory
ls                                # list files
ls -lh                            # list with details and human-readable sizes
```

**Working with files and folders:**

```bash
mkdir my_folder                   # make a new folder
mkdir -p path/to/nested/folder    # make nested folders in one go
cp file1.txt file2.txt            # copy a file
cp -r folder1/ folder2/           # copy a whole folder (-r = recursive)
mv file1.txt somewhere_else/      # move a file (also used to rename)
rm file1.txt                      # delete a file. NO UNDO.
rm -r folder/                     # delete a folder and everything in it. NO UNDO.
```

**Looking at files:**

```bash
cat myfile.txt                    # print entire file to screen
head -20 myfile.txt               # first 20 lines
tail -20 myfile.txt               # last 20 lines
less myfile.txt                   # scroll interactively (q to quit)
wc -l myfile.txt                  # count lines
nano myfile.txt                   # simple text editor (Ctrl+X to exit)
```

**Compression (sequencing files are large, often many GB):**

```bash
gzip myfile.fastq                 # compress -> myfile.fastq.gz
gunzip myfile.fastq.gz            # decompress
zcat myfile.fastq.gz | head -20   # peek inside without unzipping
```

**Other useful commands:**

```bash
du -sh folder/                    # how much disk space a folder uses
find . -name "*.fastq"            # find all .fastq files below current directory
grep "pattern" file.txt           # search for text in a file
history                           # see your recent commands
nn_storage_quota                  # storage usage across all project directories
nn_seff <job_id>                  # resource usage of a finished job, great for right-sizing
```

### Using modules

NeSI installs bioinformatics tools as modules. A module is a packaged piece of software you load when you need it and unload when you are done. This exists because different tools need different versions of the same underlying software (e.g., Python 3.8 vs 3.11), and having them all active at once causes conflicts.

```bash
module spider emu                  # search for available versions of a tool
module spider NanoPlot             # case-sensitive, try different capitalizations
module load Emu/3.6.2              # load a specific version
module list                        # see what's currently loaded
module purge                       # unload everything
```

**Run `module purge` first.** Get in the habit of purging before loading a new tool. This clears previously loaded modules and their dependencies, preventing conflicts. For example, chopper needs GCC 12.3 while NanoPlot needs Python 3.11; loading incompatible toolchains together breaks things.

### SLURM: running jobs on the cluster

NeSI is a shared resource used by hundreds of researchers at once. To manage this fairly, it uses a job scheduler called SLURM (Simple Linux Utility for Resource Management). Instead of running commands directly in the terminal (which ties up your session and has strict resource limits), you write a SLURM script that declares the resources you need and the commands to run. SLURM queues your job and runs it when resources are free.

A basic SLURM script (easier to set up in Jupyter, but `nano` in the terminal works fine):

```bash
#!/bin/bash
#SBATCH --account <your_nesi_project_code>   # project account (for billing)
#SBATCH --job-name my_job                    # a name to identify the job
#SBATCH --chdir /nesi/nobackup/<your_nesi_project_code>/<your_project>   # run the job here; paths below are relative to it
#SBATCH --time 01:00:00                      # max wall time (HH:MM:SS), killed if exceeded
#SBATCH --mem 4G                             # total memory for the job
#SBATCH --cpus-per-task 2                     # number of CPU cores
#SBATCH --output logs/%x_%j.out              # standard output (%x = job name, %j = job ID)
#SBATCH --error logs/%x_%j.err               # error messages

set -euo pipefail                            # stop on the first error, unset variable, or failed pipe

# Commands go below
module purge
module load some_tool/version
some_tool --input file.fastq --output result.txt
```

This is the standard header for every job in these SOPs. Two lines carry their weight and appear in every later script:

- **`--chdir`** sets the job's working directory *before anything runs*, so the relative `logs/` paths — and every other relative path — resolve there no matter which directory you launch `sbatch` from. Create the workspace and its `logs/` folder once (Section 3, Step 1) before you submit. This replaces the older habit of `cd`-ing inside the script: that runs too late, after SLURM has already tried, and failed, to open the log files.
- **`set -euo pipefail`** stops on the first error, unset variable, or failed pipe, rather than ploughing on and leaving you half-finished output that looks complete.

For a job array, leave the range out of the header and set it at submission (see *A note on array jobs* below).

Save as `myjob.sh`, then:

```bash
sbatch myjob.sh                   # submit; SLURM returns a job ID
squeue -u $USER                   # check your jobs (R = running, PD = pending)
sacct -j <job_id>                 # resource usage after a job finishes
scancel <job_id>                  # cancel a job
nn_seff <job_id>                  # friendlier resource summary, great for right-sizing
```

**Email notifications (optional).** Ask SLURM to email you when a job changes state by adding two flags to the header:

```bash
#SBATCH --mail-user <your_email>                  # your full email, e.g. alice@auckland.ac.nz
#SBATCH --mail-type END,FAIL,TIME_LIMIT_80        # notify on completion, failure, 80% walltime
```

`TIME_LIMIT_80` is the most useful: if a job is approaching its walltime and will not finish, you get an email while it is still running, so you can decide whether to let it die and resubmit with more time. Available mail types: BEGIN, END, FAIL, REQUEUE, ALL, TIME_LIMIT_50, TIME_LIMIT_80, TIME_LIMIT_90. For long array jobs, FAIL alone is a reasonable minimum.

**Choosing resources.** Start modest (1 hour, 4 GB, 2 CPUs) and increase if your job runs out of time or memory. Check the `.err` file: "OUT OF MEMORY" or "TIMEOUT" tells you which setting to raise. **Do not over-request.** Bigger requests wait longer in the queue because SLURM has to find a larger slot, and NeSI staff will flag persistent over-requesting. After a job or test batch finishes, run `nn_seff <job_id>` to see how much time and memory it actually used, and right-size the next submission accordingly.

### A note on array jobs

When you need to process many files in parallel (e.g., hundreds of samples), SLURM supports array jobs. You submit one script and set the range at submission time — `sbatch --array=1-N%20 myjob.sh` runs N copies (throttled to 20 at once), each with a different `$SLURM_ARRAY_TASK_ID` counting from 1. Keeping the range out of the header, rather than hard-coding it, means the same script works for any sample count. This is far faster than a loop for heavy steps like Emu classification.

### Further reading

For a more thorough introduction to bash, SLURM, and HPC fundamentals, the Genomics Aotearoa Metagenomics Summer School materials are an excellent NeSI-specific resource:

- Bash and shell: https://genomicsaotearoa.github.io/metagenomics_summer_school/day1/ex1_bash_and_scheduler/
- HPC and SLURM scheduler: https://genomicsaotearoa.github.io/metagenomics_summer_school/day1/ex2_1_intro_to_scheduler/
- Command-line and SBATCH quick reference: https://genomicsaotearoa.github.io/metagenomics_summer_school/resources/7_command_line_shortcuts/
- NeSI filesystem and symlinks: https://genomicsaotearoa.github.io/metagenomics_summer_school/supplementary/supplementary_2/

The summer school covers shotgun metagenomics rather than amplicon work, so its pipeline content does not apply to us, but its NeSI, bash, and SLURM material matches our environment exactly.

## 2. Understanding Your Data

Before the commands, some background on the biology and technology.

### What is 16S rRNA and why do we sequence it?

Every living cell makes proteins using molecular machines called **ribosomes**, which read messenger RNA and assemble amino acids into protein chains. Ribosomes have two subunits. In bacteria and archaea, the small subunit contains a ribosomal RNA molecule called **16S rRNA** (the "S" is Svedberg units, a sedimentation measure that correlates roughly with size).

The gene encoding 16S rRNA is approximately **1,542 bp** long and is extraordinarily useful for microbial identification for two reasons:

1. **It is universal.** Every bacterium and archaeon has at least one copy. A single pair of PCR primers can amplify the gene from virtually any bacterium, whether *E. coli*, *Staphylococcus*, an uncultured soil bacterium, or a hot-spring archaeon. The primers bind to **conserved regions** that are nearly identical across all species because they are essential for ribosome function and under strong evolutionary constraint.

2. **It has variable regions.** Between the conserved regions are nine **variable regions** (V1-V9) that differ between species because they are under less functional constraint and accumulate differences over time. Comparing these regions to a database of known sequences tells us which species a read came from.

Universal primers (to catch everything) plus variable regions (to distinguish species) are what make 16S the standard for bacterial identification and community profiling.

### What is an amplicon?

Amplicon sequencing means sequencing a specific DNA region that was amplified by PCR. Here, the amplicon is the 16S rRNA gene.

**PCR** uses two short DNA sequences called **primers** that bind to locations flanking the target region. Primers act as starting points for a DNA polymerase, which copies everything between them. Each cycle roughly doubles the amount of DNA, so after 25-35 cycles you have millions of copies of the target. This amplification is what makes 16S sequencing sensitive enough to detect low-abundance bacteria.

For full-length 16S we use **27F** (forward, binds near the gene's start) and **1492R** (reverse, binds near the end), giving an amplicon of approximately 1,500 bp, nearly the whole gene.

For short-read Illumina 16S we typically use **341F** and **785R**, targeting the V3-V4 regions, giving an amplicon of about 440 bp.

### How does Nanopore sequencing work?

Oxford Nanopore sequencing works on a different principle from Illumina. A Nanopore **flow cell** contains a membrane with thousands of tiny protein pores. An ionic current flows through each pore; when a DNA strand is threaded through by a motor protein, it partially blocks the current. Different bases (A, T, G, C) block the current by different amounts, producing a characteristic signal. A neural network **basecaller** translates these current fluctuations back into a DNA sequence.

Consequences:

- **Long reads.** There is no inherent length limit; the sequencer reads whatever length is threaded through the pore. For 16S, this means reading the entire ~1,500 bp gene in a single read rather than in short fragments.
- **Higher error rate.** The basecaller infers sequence from noisy signals. Even with the best models (super-high-accuracy, "SUP"), error rates are typically 0.5-1% on R10.4.1 flow cells with SUP basecalling (up to ~5% on legacy R9.4.1 chemistry), versus <0.1% for Illumina. Errors are roughly random (substitutions, insertions, deletions), not systematic.
- **Real-time output.** Data is produced continuously as DNA passes through pores, rather than in batch cycles.

### What are quality scores?

Every base in a FASTQ file has a **quality score** (Phred or Q score), a measure of confidence in the base call, defined as **Q = -10 x log10(P)**, where P is the probability the call is wrong.

- **Q10** = 1 in 10 error = 90% accuracy
- **Q15** = 1 in ~32 = ~97% accuracy
- **Q20** = 1 in 100 = 99% accuracy
- **Q30** = 1 in 1,000 = 99.9% accuracy

Illumina reads are typically Q30+ for most bases. Nanopore reads with the SUP basecaller typically average Q15-Q20. Filtering at Q10 removes the worst reads while keeping most usable data; Emu handles the remaining errors statistically.

### What does a FASTQ file look like?

Each read is exactly four lines:

```
@read_id runid=abc123 barcode=barcode01
ATCGATCGATCGATCG...
+
!"#$%&'()*+,-./0...
```

Line 1: header starting with `@` (read ID and metadata). Line 2: the DNA sequence. Line 3: a separator (always `+`). Line 4: quality scores as ASCII characters.

Q scores map to ASCII: Q0 = `!`, Q10 = `+`, Q20 = `5`, Q30 = `?`, Q40 = `I`. Higher characters mean better quality. Tools like NanoPlot decode these for you.

### What does Nanopore data look like on disk?

Data from the sequencer (MinKNOW) comes as FASTQ files organised in subdirectories by barcode. Each barcode is one sample. Barcoding is how Nanopore multiplexes (runs multiple samples on one flow cell): during library prep each sample's DNA is tagged with a unique short sequence, and MinKNOW uses these tags to sort reads into per-sample files afterward.

A typical directory structure:

```
sequencing_run/
├── barcode01/
│   └── barcode01_SupHigh_calls.fastq
├── barcode02/
│   └── barcode02_SupHigh_calls.fastq
└── ...
```

"SupHigh" refers to the super-high-accuracy basecalling model. Models trade speed for accuracy: "fast" is quick but less accurate, "hac" (high-accuracy) is the middle ground, and "sup" (super-high-accuracy) is slowest but most accurate. For 16S amplicon work, always use SUP if possible.

### Full-length vs short-read: why it matters

With **Illumina** (short reads) we typically sequence just the V3-V4 region (~440 bp) using 341F-785R. Reads are very accurate (<0.1% error), but the short fragment usually limits identification to genus level; many closely related species share identical V3-V4 sequences (e.g., several *Streptococcus* or *Bacillus* species cannot be distinguished by V3-V4 alone).

With **Nanopore** (long reads) we sequence nearly the entire gene (~1,500 bp) using 27F-1492R. This covers all nine variable regions, giving resolution potentially down to species level. The extra regions (V1, V2, V5-V9) carry species-specific differences that V3-V4 misses.

**The key difference in the workflow:** with Illumina/DADA2 we first denoise reads into exact ASVs (Amplicon Sequence Variants, unique sequences differing by even one base), then assign taxonomy. This works because Illumina error rates are low enough to distinguish true biological variants from sequencing errors.

With Nanopore the error rate is too high for this; a single species would generate hundreds of slightly different sequences due to errors, making ASV inference impractical. Instead we classify each read directly against a reference database, then count reads per species. Emu uses statistical methods to handle the errors.

Because of this, overall alpha diversity may appear lower with Nanopore than with Illumina for the same samples; Illumina resolves more fine-grained ASVs while Nanopore collapses reads to species level.

Once reads are processed into a count table and taxonomy table, the downstream R/phyloseq workflow is the same regardless of platform, though interpretation differs. Nanopore-derived taxa are species-level identifications (not ASVs), counts are EM-estimated (not exact), and the total feature count is typically lower than with Illumina.

## 3. Processing Nanopore Reads

Quality control and filtering of raw sequencing data on NeSI.

### Step 1. Organise your raw data

When downloading from BaseSpace or Globus, put your data exactly where you want it in a named directory. Everything in this SOP runs out of one workspace directory. Create it and move in:

```bash
mkdir -p /nesi/nobackup/<your_nesi_project_code>/<your_project>
cd /nesi/nobackup/<your_nesi_project_code>/<your_project>
mkdir -p raw_files filtered qc_raw qc_filtered emu_results emu_databases logs
```

Work inside `<your_project>`, never in `/nesi/nobackup/<your_nesi_project_code>/` itself. That level is shared by everyone on your allocation. If two people — or two of your own sequencing runs — write `raw_files/` and `filtered/` there, the second overwrites the first and the manifest you build in Section 4 will list both sets of samples without complaint. This is the directory `~/proj` points at, so from here on `cd ~/proj` gets you back.

If your FASTQ files are in per-barcode subdirectories from the sequencer, concatenate each barcode's files into one FASTQ in `raw_files`. MinKNOW usually writes several chunks per barcode and often gzips them, so this is a concatenation, not a copy — `cp` cannot do it (given more than one source file it demands a directory as the destination and fails):

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

**Check before continuing.** The loop prints one line per barcode with a read count. Compare that list against your barcode sheet: a barcode that printed a WARNING, or that is missing from the list entirely, will be absent from every downstream table, and nothing later in this pipeline will tell you it is gone.

### Step 2. Quality assessment of raw reads

Before filtering, assess raw read quality. **NanoPlot** generates an interactive HTML report with plots and statistics telling you whether the run was successful and helping you choose filtering thresholds. It is part of the NanoPack toolkit, built for Oxford Nanopore data, and produces plots of read length distributions, quality distributions, output over time, and summary statistics (total bases, median length, median quality, N50).

Create a SLURM script called `01_nanoplot_raw.sh`:

```bash
#!/bin/bash
#SBATCH --account <your_nesi_project_code>
#SBATCH --job-name nanoplot_raw
#SBATCH --chdir /nesi/nobackup/<your_nesi_project_code>/<your_project>
#SBATCH --time 00:30:00
#SBATCH --mem 8G
#SBATCH --cpus-per-task 8
#SBATCH --output logs/nanoplot_raw_%j.out
#SBATCH --error logs/nanoplot_raw_%j.err

set -euo pipefail

module purge
module load NanoPlot/1.43.0-foss-2023a-Python-3.11.6

NanoPlot \
    --fastq raw_files/*.fastq \
    --outdir qc_raw \
    --prefix raw_ \
    --threads ${SLURM_CPUS_PER_TASK} \
    --loglength \
    --plots dot \
    --title "Raw 16S reads"
```

Submit with `sbatch 01_nanoplot_raw.sh`. No need to array this; it is lightweight and fast. Once finished, open the HTML report in `qc_raw/`. In Jupyter, click **Trust HTML** at the top of the file to enable the interactive plots.

`--fastq raw_files/*.fastq` passes every barcode at once, so this report **pools all barcodes into one dataset** — use it to judge whether the *run* succeeded (overall length peak, median quality, N50), not any single sample. Per-barcode signals come from elsewhere: read counts from the Step 1 loop (compare against your barcode sheet) and per-barcode retention from the Step 3 chopper log. To QC one suspect barcode on its own, run NanoPlot on just that file (`NanoPlot --fastq raw_files/barcode07.fastq --outdir qc_raw/barcode07 --prefix barcode07_ --threads 8`).

**How to interpret the report:**

- **Read length distribution.** Expect a sharp peak around 1,400-1,500 bp (successfully amplified full-length amplicons). You may also see a small peak below ~200 bp (primer dimers or failed amplifications), a tail above 1,800 bp (possible chimeras or off-target products), or a broad messy distribution with no clear peak (library prep problems).
- **Quality score distribution.** Most reads should exceed Q10; with R10.4.1 flow cells and SUP basecalling, median quality is typically Q15-Q20. A median below Q10 means poor run quality. A bimodal distribution may indicate reads basecalled with different models.
- **Total yield and read count.** For 16S you generally want at least 10,000-50,000 reads per barcode. More helps detect rare taxa, with diminishing returns above ~50,000 reads for most communities.
- **N50.** The read length at which 50% of all bases sit in reads at least that long. For 16S it should be close to the amplicon length (~1,450-1,500 bp); a much shorter N50 suggests fragmented amplicons.

Here is what a raw dataset's `raw_NanoStats.txt` looks like. The mean read length (1,309 bp) sits below the target amplicon (~1,500 bp) because short fragments drag the average down. The median (1,494 bp) is much closer, telling us most reads are full length with a tail of short junk. The N50 of 1,496 bp confirms the majority of data is in full-length reads. 99.7% of reads pass Q10, which is excellent:

```
General summary:
Mean read length:                  1,309.6
Mean read quality:                    20.4
Median read length:                1,494.0
Median read quality:                  24.3
Number of reads:              21,019,028.0
Read length N50:                   1,496.0
STDEV read length:                   573.5
Total bases:              27,527,166,710.0
Number, percentage and megabases of reads above quality cutoffs
>Q10:	20949474 (99.7%) 27460.3Mb
>Q15:	19987476 (95.1%) 26362.0Mb
>Q20:	16690528 (79.4%) 22030.0Mb
>Q25:	9351510 (44.5%) 11611.3Mb
>Q30:	3061234 (14.6%) 2775.6Mb
```

Two plots to check first when assessing run quality:

**Read length histogram (raw):**

<img width="700" height="500" alt="Read length histogram, raw" src="https://github.com/user-attachments/assets/3caf1fec-5796-4595-becc-07a36e956379" />

The distribution of read lengths. For a 16S run you want a dominant peak around 1,400-1,500 bp. The long tail below 1,000 bp is truncated amplicons (the strand fell out of the pore early), primer dimers, or off-target products. Reads above 1,800 bp are likely chimeras. Both tails are removed by chopper in the next step.

**Read length vs quality scatter (raw):**

<img width="700" height="500" alt="Length vs quality scatter plot, raw" src="https://github.com/user-attachments/assets/62050053-5426-4b7e-8ef5-c73f67ebcf7b" />

Every dot is one read, plotted by length (x) and mean quality (y). The dense cluster around 1,450-1,500 bp at Q15-Q25 is your good amplicon data. Dots below Q10 and below 1,200 bp are what chopper will remove. After filtering, this plot should be a clean rectangle with nothing outside your filter boundaries.

### Step 3. Filtering with chopper

**Chopper** filters FASTQ reads by quality score and length. It is the Rust reimplementation of NanoFilt and NanoLyse (De Coster & Rademakers 2023, *Bioinformatics* 39(5):btad311), runs roughly 7x faster than the Python version, and is the recommended tool for new projects. We use it to remove reads that are too short (truncated amplicons missing variable regions), too long (likely chimeras), or too error-prone (low quality).

**Why chopper over NanoFilt?** Chopper is the official successor to NanoFilt (same developer), written in Rust. It runs roughly 7x faster, handles both compressed and uncompressed FASTQ directly via `--input`, and supports multithreading with `--threads`. NanoFilt is deprecated and no longer updated (last release v2.8.0, Dec 2022).

**Why these thresholds:**

- **`--quality 10` (minimum average quality Q10).** Removes reads where average per-base accuracy is below 90%. Emu does not need each read to be perfect; its EM algorithm works on the statistical pattern across thousands of reads, and as long as errors are roughly random (which they are in Nanopore data), the true composition emerges from the aggregate. Q10 is the widely used standard for Nanopore 16S.
- **`--minlength 1200` (minimum length 1,200 bp).** Removes clearly truncated reads missing multiple variable regions. We use 1,200 rather than 1,500 bp because the 27F-1492R amplicon is approximately 1,500 bp and 16S gene length varies across species (roughly 1,400-1,540 bp); a 1,500 bp floor would discard many legitimate full-length reads. The 1,200 bp floor keeps genuine amplicons while removing reads that have lost enough sequence to compromise classification.
- **`--maxlength 1800` (maximum length 1,800 bp).** Removes abnormally long reads that are likely **chimeras**, artificial hybrids formed during PCR when an incomplete amplicon from one species primes a different species' template. Chimeras cause false species detections. The 1,800 bp ceiling leaves generous room above the longest expected amplicons while catching obvious chimeric products.

Create a SLURM script called `02_chopper_filter.sh`:

```bash
#!/bin/bash
#SBATCH --account <your_nesi_project_code>
#SBATCH --job-name chopper_filter
#SBATCH --chdir /nesi/nobackup/<your_nesi_project_code>/<your_project>
#SBATCH --time 01:00:00
#SBATCH --mem 8G
#SBATCH --cpus-per-task 8
#SBATCH --output logs/chopper_%j.out
#SBATCH --error logs/chopper_%j.err

set -euo pipefail

# Filter parameters for full-length 16S rRNA (~1,500 bp)
MIN_LENGTH=1200
MAX_LENGTH=1800
MIN_QUALITY=10

mkdir -p filtered

module purge
module load chopper/0.12.0b-GCC-12.3.0

for fastq in raw_files/*.fastq; do
    sample=$(basename ${fastq} .fastq)
    echo "Processing ${sample}... $(date)"

    chopper \
        --input ${fastq} \
        --quality ${MIN_QUALITY} \
        --minlength ${MIN_LENGTH} \
        --maxlength ${MAX_LENGTH} \
        --threads ${SLURM_CPUS_PER_TASK} \
        > filtered/${sample}_filtered.fastq

    # Quick stats. Count records as lines/4, not with grep. A FASTQ quality
    # line is arbitrary ASCII and "@" is Q31 (see the Phred table in Section 2),
    # so `grep -c "^@"` also counts quality lines and silently inflates the count.
    raw_count=$(( $(wc -l < "${fastq}") / 4 ))
    filt_count=$(( $(wc -l < "filtered/${sample}_filtered.fastq") / 4 ))
    pct=$(awk -v r="${raw_count}" -v f="${filt_count}" \
          'BEGIN{ if (r>0) printf "%.1f", 100*f/r; else print "NA" }')
    echo "  ${sample}: ${raw_count} raw -> ${filt_count} filtered (${pct}% retained)"
done

echo "=== Chopper filtering complete === $(date)"
```

Submit with `sbatch 02_chopper_filter.sh`. No array needed; chopper is fast.

You should typically retain 60-85% of reads; a clean library (like the worked example below, ~85%) sits at the top of that band. Retaining under ~50% overall, or under ~30% for a single barcode, suggests quality or fragmentation problems — check that barcode's NanoPlot output.

### Step 4. Quality assessment of filtered reads

Run NanoPlot again on the filtered reads to compare before and after. This confirms the filters removed the short fragments and low-quality tails without cutting into the main amplicon peak.

Create a SLURM script called `03_nanoplot_filtered.sh`:

```bash
#!/bin/bash
#SBATCH --account <your_nesi_project_code>
#SBATCH --job-name nanoplot_filt
#SBATCH --chdir /nesi/nobackup/<your_nesi_project_code>/<your_project>
#SBATCH --time 00:30:00
#SBATCH --mem 8G
#SBATCH --cpus-per-task 8
#SBATCH --output logs/nanoplot_filt_%j.out
#SBATCH --error logs/nanoplot_filt_%j.err

set -euo pipefail

module purge
module load NanoPlot/1.43.0-foss-2023a-Python-3.11.6

NanoPlot \
    --fastq filtered/*_filtered.fastq \
    --outdir qc_filtered \
    --prefix filtered_ \
    --threads ${SLURM_CPUS_PER_TASK} \
    --loglength \
    --plots dot \
    --title "Filtered 16S reads (Q>=10, 1200-1800 bp)"
```

Submit with `sbatch 03_nanoplot_filtered.sh`.

**What to compare between raw and filtered:**

- **Read length distribution.** The filtered report should show a tight peak around 1,400-1,500 bp with no short tail and no long chimeric tail. If the peak shape barely changed, your library was already clean.
- **Quality distribution.** No reads below Q10. Median quality should stay the same or rise slightly.
- **Read count.** A drop of 15-40% is typical. Losing more than 60% means your raw data had quality or fragmentation issues.

For example, `filtered_NanoStats.txt` shows the mean read length jumped from 1,309 to 1,499 bp (short-fragment tail gone), the standard deviation dropped from 573 to 35 bp (reads tightly clustered around the amplicon length), and we retained about 17.8M of 21M reads (~85%):

```
General summary:
Mean read length:                  1,499.6
Mean read quality:                    20.9
Median read length:                1,496.0
Median read quality:                  24.2
Number of reads:              17,798,064.0
Read length N50:                   1,496.0
STDEV read length:                    35.2
Total bases:              26,690,546,448.0
Number, percentage and megabases of reads above quality cutoffs
>Q10:	17798064 (100.0%) 26690.5Mb
>Q15:	17139976 (96.3%) 25704.6Mb
>Q20:	14426848 (81.1%) 21645.1Mb
>Q25:	7592920 (42.7%) 11400.1Mb
>Q30:	1772122 (10.0%) 2663.2Mb
```

### Interpreting NanoPlot output

NanoPlot produces several plots. You do not need all of them; these are the key ones.

**Read length histogram (filtered):**

<img width="700" height="500" alt="Read length histogram, filtered" src="https://github.com/user-attachments/assets/0fb8ff83-5d8b-4b34-bd29-5a49603d44d9" />

After filtering, expect a single tight peak around 1,400-1,500 bp with sharp cutoffs at your filter boundaries (1,200 and 1,800 bp). Compared to the raw histogram, the short-read and chimeric tails are gone. A broad peak or multiple shoulders means fragmented amplicons or off-target products.

**Read length vs quality scatter (filtered):**

<img width="700" height="500" alt="Length vs quality scatter plot, filtered" src="https://github.com/user-attachments/assets/939cc9ba-4733-4378-ace1-0c5a7c88258f" />

The cloud of points should concentrate in a clean rectangle bounded by your filters: 1,200-1,800 bp on the x-axis, Q10+ on the y-axis, densest around 1,450-1,500 bp and Q15-Q25. No dots below Q10 or outside the length range should remain. This is the single most informative NanoPlot output because it shows both filter dimensions at once.

**Other plots.** NanoPlot also produces log-scaled scatter plots (more useful for whole-genome data than amplicons), weighted histograms (counting total bases instead of total reads; nearly identical to the unweighted version for amplicons since reads are roughly the same length), and cumulative yield plots (a near-vertical jump at the amplicon length). These are less critical for amplicon QC.

**For your thesis.** The two most useful are the read length histogram (raw vs filtered, side by side) and the filtered length-vs-quality scatter. The before/after comparison is particularly effective because reviewers can immediately see what was removed and what was kept.

## 4. Taxonomy and Community Profiling with Emu

Setting up reference databases, running Emu for taxonomic classification, and combining results across samples.

### What Emu does and why we use it

Emu (https://github.com/treangenlab/emu) is a relative abundance estimator for 16S sequences, optimised for error-prone full-length reads. It takes your filtered FASTQ reads and classifies them against a reference database to determine which bacteria are present and at what abundances.

**Why Emu over other tools?** Several tools classify 16S reads (Kraken2, minimap2 as used in EPI2ME, Centrifuge, NanoCLUST). Emu was designed for long, error-prone reads and benchmarked against these alternatives. In the original paper (Curry et al., *Nature Methods* 2022), it produced more accurate abundance estimates with fewer false positives and false negatives on both synthetic and mock communities. Fewer false positives matters because reporting species that are not actually present leads to incorrect biological conclusions.

**How Emu works:**

1. **Alignment with minimap2.** Emu aligns each read against the reference database using minimap2, a fast aligner for long, error-prone reads. For each read, minimap2 reports the top ~50 matching references (the `--N` parameter). Because of sequencing errors and the similarity of closely related 16S sequences, many reads match multiple species roughly equally well. This **multi-mapping** is the central challenge of 16S classification with noisy long reads.

2. **The problem with "best hit."** Assigning each read to its single best match is naive. When a read has 95% identity to Species A and 94.5% to Species B, that 0.5% could easily be sequencing error rather than biology. Across thousands of reads these small misassignments add up, creating false positives and distorting abundances.

3. **Expectation-Maximization (EM).** Emu resolves this iteratively:
   - **Start:** assume all database species are equally likely.
   - **E-step:** for each read, compute the probability it came from each candidate species, given current abundance estimates and alignment scores.
   - **M-step:** update each species' abundance by summing the probabilities assigned to it across all reads.
   - **Repeat** until abundances stabilise (typically 10-50 iterations).

   The key idea is that EM uses **community context** to resolve ambiguous reads. If read #1 maps equally well to Species A and B, but thousands of other reads clearly map to A and almost none to B, EM infers read #1 probably came from A too. Species without strong unique support shrink toward zero, eliminating false positives.

4. **Output.** After convergence, Emu reports the estimated relative abundance and read count for each surviving species. Species below a threshold (default 0.0001, i.e. 0.01%) are treated as not present.

### Understanding the reference databases

A reference database is a curated collection of known 16S sequences, each labelled with its taxonomy. When Emu classifies a read it is asking which known sequence the read most closely matches. The database's completeness directly affects results: a bacterium not represented in the database cannot be identified correctly; it is either classified as a close relative (if one exists) or reported as unclassified. This is why database choice matters.

We set up **both** SILVA and RDP:

**SILVA** (Quast et al. 2013, *Nucleic Acids Research*; https://www.arb-silva.de/):

- The most comprehensive ribosomal RNA database, with millions of sequences.
- Maintained by a European consortium, updated roughly annually.
- Uses its own curated taxonomy, which can differ from NCBI taxonomy.
- Excellent coverage of environmental bacteria (soil, water, gut).
- A good default for most ecological and environmental studies.

> **Version note:** The Emu prebuilt fetched by `EMU_PREBUILT_DB='silva'` is **SILVA v138.1**, built from the DADA2 SILVA species-level database. A separate, newer build (`EMU_PREBUILT_DB='silva-138.2'`) exists but, per the Emu README, has not yet been tested or validated with Emu. We use the validated v138.1 (`silva`) throughout this SOP. Separately, the Emu **default** database was refreshed in March 2026 (rrnDB v5.10 + NCBI March 2026) and lives on a different OSF project (`32sh5`, not `56uf7`). We do not use the default database in this workflow, but note the project ID in case you ever want the latest build.

**RDP** (Ribosomal Database Project):

- Smaller, more conservative, focused on quality over quantity.
- Strongly curated; sequences with poor taxonomy or low quality are excluded.
- May produce more "unassigned" taxa because it has fewer references.
- Better when classification accuracy matters more than completeness.

**Run both and compare.** It is little extra effort and worth it. A taxon appearing in both SILVA and RDP results is more likely genuinely present. A taxon appearing with only one database is worth investigating; it could be a real organism missing from the other database, or a misclassification.

### Setting up the databases

You only need to do this once per project. If someone in your lab has already set up the databases in a shared directory, point your `DB_PATH` there instead of downloading again. Databases are several GB, so store them on `/nesi/nobackup/` (more space, not backed up, fine since you can re-download).

**Step 1: Create your database directory and install the download tool.** Emu's databases are hosted on OSF (Open Science Framework). The `osfclient` package downloads them from the command line:

```bash
mkdir -p /nesi/nobackup/<your_nesi_project_code>/<your_project>/emu_databases
cd /nesi/nobackup/<your_nesi_project_code>/<your_project>/emu_databases
module purge
module load Emu/3.6.2
pip install osfclient
```

**Step 2: Download SILVA (v138.1).** Set `EMU_PREBUILT_DB` to choose the archive and `EMU_DATABASE_DIR` to choose where it goes. Then `cd` in, fetch, extract, and remove the tar:

```bash
export EMU_PREBUILT_DB='silva'
export EMU_DATABASE_DIR=/nesi/nobackup/<your_nesi_project_code>/<your_project>/emu_databases/silva
mkdir -p ${EMU_DATABASE_DIR}
cd ${EMU_DATABASE_DIR}
osf -p 56uf7 fetch osfstorage/emu-prebuilt/${EMU_PREBUILT_DB}.tar
tar -xvf ${EMU_PREBUILT_DB}.tar
rm -f ${EMU_PREBUILT_DB}.tar
```

**Step 3: Download RDP.** Same pattern, just change the two `export` lines:

```bash
export EMU_PREBUILT_DB='rdp'
export EMU_DATABASE_DIR=/nesi/nobackup/<your_nesi_project_code>/<your_project>/emu_databases/rdp
mkdir -p ${EMU_DATABASE_DIR}
cd ${EMU_DATABASE_DIR}
osf -p 56uf7 fetch osfstorage/emu-prebuilt/${EMU_PREBUILT_DB}.tar
tar -xvf ${EMU_PREBUILT_DB}.tar
rm -f ${EMU_PREBUILT_DB}.tar
```

**Note your database path.** You need it for every Emu command. The rest of this SOP uses `DB_PATH`:

```bash
DB_PATH=/nesi/nobackup/<your_nesi_project_code>/<your_project>/emu_databases/silva
```

### Running Emu

We use a SLURM **array job** to process all samples in parallel. A sequential loop processes one sample at a time, fine for a handful of barcodes but slow at scale (e.g., 192 samples x ~10 minutes each = ~32 hours). An array job submits each sample as an independent task, and SLURM runs them simultaneously, so a run that takes a day sequentially can finish in under an hour.

**Step 1: Build a manifest file.** The manifest lists one FASTQ path per line. The SLURM array index maps to a line number, so each task knows which sample to process:

```bash
cd /nesi/nobackup/<your_nesi_project_code>/<your_project>/
# List all filtered FASTQ files, one per line
ls filtered/*_filtered.fastq > emu_manifest.txt

# Verify: line count should equal your number of samples
wc -l emu_manifest.txt
```

**Step 2: Create the array job script.** Save as `emu_array.sh`. Leave the array range out of the header and set it at submission (Step 3), so the same script works for any sample count. Test your resources first: submit a small range (say `--array=1-10`), check with `nn_seff` whether time, memory, and CPUs were enough, then submit the rest.

```bash
#!/bin/bash
#SBATCH --account <your_nesi_project_code>
#SBATCH --job-name emu_array
#SBATCH --chdir /nesi/nobackup/<your_nesi_project_code>/<your_project>
#SBATCH --time 00:50:00
#SBATCH --mem 10G
#SBATCH --cpus-per-task 8
#SBATCH --array 1-1                   # placeholder; set the real range at submission (Step 3)
#SBATCH --output logs/emu_%A_%a.out   # %A = array job ID, %a = task index
#SBATCH --error logs/emu_%A_%a.err

set -euo pipefail

module purge
module load Emu/3.6.2

# ── Paths ──
DB_PATH=/nesi/nobackup/<your_nesi_project_code>/<your_project>/emu_databases/silva
MANIFEST="emu_manifest.txt"

# ── Get this task's FASTQ (line number = array index, 1-based) ──
FASTQ=$(sed -n "${SLURM_ARRAY_TASK_ID}p" ${MANIFEST})

if [ -z "${FASTQ}" ] || [ ! -f "${FASTQ}" ]; then
    echo "ERROR: No fastq found for array index ${SLURM_ARRAY_TASK_ID}"
    exit 1
fi

SAMPLE=$(basename ${FASTQ} _filtered.fastq)
echo "=== Task ${SLURM_ARRAY_TASK_ID}: ${SAMPLE} === $(date)"

# ── Run Emu ──
mkdir -p emu_results/silva

emu abundance ${FASTQ} \
    --type lr:hq \
    --db ${DB_PATH} \
    --keep-counts \
    --threads ${SLURM_CPUS_PER_TASK} \
    --output-dir ./emu_results/silva \
    --output-basename ${SAMPLE} \
    --min-abundance 0.0001

echo "=== Done: ${SAMPLE} === $(date)"
```

**Step 3: Submit, setting the array range now.** The `logs/` directory already exists from Step 1. Set the real range at submission — `1-N`, where N is your sample (manifest line) count, throttled to 20 tasks at once:

```bash
N=$(wc -l < emu_manifest.txt)          # number of samples
sbatch --array=1-${N}%20 emu_array.sh
```

**Set the range every time.** Run `sbatch emu_array.sh` without `--array` and the `1-1` placeholder means only the first sample is processed — the job succeeds with no error, and every other sample is silently missing. Check the task count in `squeue -u $USER` after submitting.

Monitor with `squeue -u $USER`. Each task writes its own log in `logs/`, so if a sample fails you can check its `.err` file directly.

**For the RDP run**, copy the script to `emu_array_rdp.sh`, point `DB_PATH` at `emu_databases/rdp`, and change `--output-dir` to `./emu_results/rdp`:

```bash
DB_PATH=/nesi/nobackup/<your_nesi_project_code>/<your_project>/emu_databases/rdp
```

Submit separately, again setting the range: `sbatch --array=1-$(wc -l < emu_manifest.txt)%20 emu_array_rdp.sh`.

**How the array job works.** `--array=1-N` launches N tasks (indices 1 to N), each with a unique `$SLURM_ARRAY_TASK_ID`. The `sed` command uses this to pick the matching manifest line, so task 1 processes the first sample, task 2 the second, and so on. Each task requests its own memory and CPUs, so they do not compete.

**Choosing resources.** Each Emu task typically needs 6-10 GB of memory (to load the database) and benefits from 4-16 threads for the minimap2 alignment. Start with `--mem 10G --cpus-per-task 8 --time 00:50:00` and adjust based on `nn_seff` after the first run. Beyond ~16 threads, returns diminish.

**The flags:**

- `--type lr:hq` — input is long-read, high-quality (SUP-basecalled Nanopore). This tunes minimap2 for modern high-accuracy reads. Use `lr:hq` for SUP/Q20+ data; use `map-ont` (the Emu default) for older HAC-basecalled reads.
- `--db` — path to the database directory (contains `species_taxid.fasta` and `taxonomy.tsv`).
- `--keep-counts` — **essential, do not omit.** Without it, Emu outputs only relative abundances. With it, each per-sample file also includes an estimated read count column. All downstream statistics in R (phyloseq, SRS normalisation, ANCOM-BC2, MaAsLin2) need counts, not percentages. Forget this and you re-run Emu from scratch.
- `--threads` — CPU cores for minimap2. `${SLURM_CPUS_PER_TASK}` matches whatever you requested in the header.
- `--output-dir` — where results go.
- `--output-basename` — names output after the sample rather than the full input path, keeping filenames clean.

**Optional flags:**

- `--keep-read-assignments` — writes a per-read file with the probability distribution across species for each read. Useful for QC, but large.
- `--min-abundance 0.0001` — the default threshold (0.01%). Raise it (e.g., `0.01` for 1%) to reduce noise, or leave it at the default for maximum sensitivity.
- `--output-unclassified` — writes separate FASTA files for unmapped and unclassified reads. Useful for investigating your "unassigned" fraction.
- `--min-pid 90` — minimum percent identity for an alignment, based on the NM tag (default `0`, i.e. no filter). The value is a **percent out of 100**, so `90` means 90% identity. Do not write `0.9` expecting 90%; Emu reads that as 0.9% identity, which filters nothing. Setting `90` removes very poor matches, reducing false positives at the risk of missing divergent taxa. By default Emu applies no PID filter and lets the EM algorithm resolve ambiguous alignments statistically, which is usually the better approach for noisy long reads, so only raise this if you are specifically chasing false positives, and compare against your unfiltered run rather than replacing it.
- `--min-align-len 1000` — minimum aligned query length in bp (default `0`). Discards short partial alignments that may lack enough variable regions for reliable classification.
- `--max-align-len` — maximum aligned query length, default `2000`. Silently caps the alignment length Emu considers. Fine for standard 27F-1492R amplicons (~1,500 bp), but for longer fragments (e.g., 16S-ITS-23S operons) raise it or reads are discarded without warning.

**What Emu outputs.** For each sample, a file called `<sample>_rel-abundance.tsv`. Each row is a detected taxon with columns: tax_id (NCBI taxonomy ID), species, genus, family, order, class, phylum, superkingdom, abundance (relative, 0-1), and (with `--keep-counts`) estimated counts.

**About estimated counts.** Emu's counts are not always whole numbers. You might see 4.6 instead of 5. The EM algorithm distributes ambiguous reads probabilistically, so a read mapping equally well to two species contributes 0.5 to each. Per the Emu docs, the estimated count is the product of estimated relative abundance and total classified reads, which is why it is fractional. We round to whole numbers in R before analysis; this adds a tiny amount of imprecision but is necessary for count-based methods.

### Combining Emu outputs

After all array tasks finish, merge the per-sample files into combined tables.

Use the `combine_emu_results.py` script below — this is the **standard method**, and the one Part 2 expects. It produces separate abundance and counts tables with identical column layouts across every database in one pass, and it parses both the split-column format and any single-column semicolon-delimited lineage format into the same structure. This keeps the downstream R code identical no matter which database a table came from, and it writes the exact filename Part 2 loads (`emu-combined-counts_<db>.tsv`).

Emu also ships a built-in `combine-outputs` subcommand. It is a quick way to eyeball one database's results, but it writes different filenames that Part 2 does not read, so use the script here for anything feeding Part 2 — see *Alternative: `emu combine-outputs`* at the end of this section.

> **Note:** Whether a given SILVA build ships split-rank columns or a single lineage string depends on the exact prebuilt archive. The script below handles either, so you do not have to check first. Verify the header of your own combined output (`head -1 emu-combined-counts_silva.tsv`) if you want to confirm the layout.
>
> Sample names come from the filename, so every per-sample file under a database directory must have a unique basename even if they sit in different subdirectories — a `plate1/barcode01_rel-abundance.tsv` and a `plate2/barcode01_rel-abundance.tsv` both resolve to `barcode01`. The script stops with an error if two collide, rather than discarding one sample's counts and writing the other's into two identically named columns.

Save this as `combine_emu_results.py` in your project directory:

```python
#!/usr/bin/env python3
"""
Combine Emu per-sample abundance files into one table per database.
Handles both split-column and single-column lineage taxonomy formats.

Usage:
    python3 combine_emu_results.py /path/to/emu_results [db1 db2 ...]

    First argument:  path to emu_results containing one subdirectory per
                     database (e.g., silva/, rdp/).
    Remaining args:  database names to combine (default: all subdirectories).

Each database directory can hold per-sample files directly or in
subdirectories (e.g., plate1/, plate2/); the script searches recursively.

Output (written to each database directory):
    emu-combined-counts_<db>.tsv      estimated read counts
    emu-combined-abundance_<db>.tsv   relative abundances
"""

import os, csv, glob, sys

RANKS = ["superkingdom", "phylum", "class", "order", "family", "genus", "species"]

def parse_lineage(lineage_str):
    """Split a semicolon-delimited lineage into a taxonomy dict."""
    parts = [p.strip() for p in lineage_str.strip(";").split(";") if p.strip()]
    return {rank: (parts[i] if i < len(parts) else "") for i, rank in enumerate(RANKS)}

def find_abundance_files(db_path):
    """Recursively find *_rel-abundance.tsv files, excluding threshold/combined."""
    files = sorted(glob.glob(os.path.join(db_path, "**", "*_rel-abundance.tsv"), recursive=True))
    return [f for f in files if "threshold" not in os.path.basename(f)
                            and "combined" not in os.path.basename(f)]

def combine_database(db_path, db_name):
    abundance_files = find_abundance_files(db_path)
    if not abundance_files:
        print(f"  WARNING: no abundance files found for {db_name}, skipping")
        return

    print(f"  Found {len(abundance_files)} sample files")

    taxa = {}          # tax_id -> {taxonomy, abundances, counts}
    sample_names = []

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

        with open(fpath) as f:
            reader = csv.DictReader(f, delimiter='\t')
            headers = reader.fieldnames
            is_lineage = "lineage" in headers

            for row in reader:
                tax_id = row.get("tax_id", "").strip()
                if not tax_id or tax_id == "unassigned":
                    continue

                abundance = float(row.get("abundance", 0))

                # Estimated counts column (name varies by Emu version)
                count_val = None
                for h in headers:
                    if "estimated counts" in h.lower() or "count" in h.lower():
                        try:
                            count_val = float(row[h])
                        except (ValueError, KeyError):
                            pass
                        break

                if tax_id not in taxa:
                    if is_lineage:
                        tax_dict = parse_lineage(row.get("lineage", ""))
                    else:
                        tax_dict = {r: row.get(r, "") for r in RANKS}
                    taxa[tax_id] = {"taxonomy": tax_dict, "abundances": {}, "counts": {}}

                taxa[tax_id]["abundances"][sample_name] = abundance
                if count_val is not None:
                    taxa[tax_id]["counts"][sample_name] = count_val

    print(f"  {len(taxa)} unique tax_ids across {len(sample_names)} samples")

    out_ranks = ["species", "genus", "family", "order", "class", "phylum", "superkingdom"]

    for suffix, value_key in [("abundance", "abundances"), ("counts", "counts")]:
        outfile = os.path.join(db_path, f"emu-combined-{suffix}_{db_name}.tsv")
        with open(outfile, "w", newline="") as f:
            writer = csv.writer(f, delimiter='\t')
            writer.writerow(["tax_id"] + out_ranks + sample_names)
            for tax_id in sorted(taxa, key=lambda x: (0, int(x)) if x.isdigit() else (1, x)):
                info = taxa[tax_id]
                values = [info[value_key].get(s, 0) for s in sample_names]
                if sum(v for v in values if v) == 0:
                    continue
                writer.writerow([tax_id] + [info["taxonomy"].get(r, "") for r in out_ranks] + values)
        n_rows = sum(1 for t in taxa.values() if any(t[value_key].get(s, 0) for s in sample_names))
        print(f"  Written: {os.path.basename(outfile)} ({n_rows} taxa x {len(sample_names)} samples)")

# ── Main ──
if len(sys.argv) < 2:
    print("Usage: python3 combine_emu_results.py /path/to/emu_results [db1 db2 ...]")
    sys.exit(1)

base = sys.argv[1]
databases = sys.argv[2:] if len(sys.argv) > 2 else sorted(
    d for d in os.listdir(base) if os.path.isdir(os.path.join(base, d))
)

for db_name in databases:
    db_path = os.path.join(base, db_name)
    if not os.path.isdir(db_path):
        print(f"Skipping {db_name}: directory not found")
        continue
    print(f"\n=== Combining {db_name} ===")
    combine_database(db_path, db_name)

print("\nDone!")
```

Run it from NeSI (Python 3 is available by default):

```bash
python3 combine_emu_results.py /nesi/nobackup/<your_nesi_project_code>/<your_project>/emu_results
```

Or specify which databases to combine:

```bash
python3 combine_emu_results.py /nesi/nobackup/<your_nesi_project_code>/<your_project>/emu_results silva rdp
```

**Output files** (written to each database directory):

- `emu-combined-counts_<db>.tsv` — estimated read counts (taxa x samples), with taxonomy columns. Use this for statistics in R.
- `emu-combined-abundance_<db>.tsv` — relative abundances (taxa x samples), with taxonomy columns. Useful for quick comparisons and reporting.

Both share the structure: `tax_id | species | genus | family | order | class | phylum | superkingdom | sample1 | sample2 | ...`

Verify the output:

```bash
for db in silva rdp; do
    echo "=== ${db} ==="
    f="emu_results/${db}/emu-combined-counts_${db}.tsv"
    if [ -f "$f" ]; then
        echo "  $(head -1 "$f" | tr '\t' '\n' | tail -n +9 | wc -l) samples, $(tail -n +2 "$f" | wc -l) taxa"
    else
        echo "  (no combined counts table — did combine_emu_results.py run for ${db}?)"
    fi
done
```

The `else` branch matters: without it, a combine step that silently produced nothing leaves this check printing an empty line, which reads like success.

Download the counts and abundance files to your computer for the R analysis.

#### Alternative: `emu combine-outputs`

Emu's built-in `combine-outputs` subcommand merges the per-sample tables for one database at a time. It is handy for a quick look, but its output is named `emu-combined-<rank>.tsv` (and, with `--counts`, `emu-combined-<rank>-counts.tsv`) — **not** the `emu-combined-counts_<db>.tsv` that Part 2 loads — so it is not the handoff. Use `combine_emu_results.py` above for anything feeding Part 2.

```bash
# One database, species level: abundance then counts
emu combine-outputs emu_results/silva species
emu combine-outputs emu_results/silva species --counts   # needs --keep-counts at the abundance step
```

The counts table only works if you ran `emu abundance` with `--keep-counts`; without it there is no way to recover counts from abundance-only output short of re-running Emu.
