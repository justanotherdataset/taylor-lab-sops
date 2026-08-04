# Worked QC example for `SOP_EMU_NeSI.md`

The four read-QC figures embedded in **Section 3** of the EMU SOP, produced by
running the SOP's own read-QC workflow (NanoPlot -> chopper -> NanoPlot) on a
small public Oxford Nanopore full-length 16S dataset. Reproducible with one
command:

```bash
bash run_example.sh        # download + subsample + regenerate the 4 figures
```

> **These are illustrative example output from a public dataset — not from your
> own run.** They show the *shape* of good raw and filtered 16S QC so you know
> what to expect when you run Section 3 on your data. Your read counts, quality
> and retention will differ.

## Dataset provenance

| Field | Value |
| --- | --- |
| Run accession | **ERR3674472** (`Ground_Zymo`) |
| Study | PRJEB35494 (ERP118545) — *Off-Earth identification of bacterial populations using 16S rDNA nanopore sequencing* |
| Sample | **ZymoBIOMICS Microbial Community Standard** (defined 8-bacteria mock), ground control |
| Assay | Full-length 16S rDNA amplicon, Oxford Nanopore (MinION) |
| How to obtain | Direct FASTQ from ENA: `ftp.sra.ebi.ac.uk/vol1/fastq/ERR367/002/ERR3674472/ERR3674472_1.fastq.gz` (no SRA toolkit) |
| Full run size | 258,187 reads / 410.5 Mb (411 MB gzipped) |
| Licence | Public INSDC/ENA submission; freely redistributable. Only the four small derived PNGs are committed here — no raw reads. |

A mock community is used deliberately: its composition is known, so the QC
plots are interpretable and free of confounding biology. The reads are genuine
**full-length 16S** (median 1,433 bp, N50 1,483 bp — see below), matching the
27F–1492R amplicon the SOP teaches.

## What was subsampled

The full run (258 k reads) is subsampled to **15,000 reads** with a fixed seed
so the example stays small and fast and the figures reproduce exactly:

```bash
seqkit sample -s 100 -n 15000 ERR3674472_1.fastq.gz > raw_files/zymo_ground.fastq
```

Subsampling only reduces the read count; it does not change the length or
quality distribution the figures show. No reads are otherwise altered.

## Exact commands run (mirroring SOP Section 3)

```bash
# Step 2 — NanoPlot on the raw reads
NanoPlot --fastq raw_files/*.fastq --outdir qc_raw --prefix raw_ \
         --threads 6 --loglength --plots dot --title "Raw 16S reads"

# Step 3 — chopper filter, EMU's exact thresholds
chopper --input raw_files/zymo_ground.fastq \
        --quality 10 --minlength 1200 --maxlength 1800 --threads 6 \
        > filtered/zymo_ground_filtered.fastq

# Step 4 — NanoPlot on the filtered reads
NanoPlot --fastq filtered/*_filtered.fastq --outdir qc_filtered --prefix filtered_ \
         --threads 6 --loglength --plots dot \
         --title "Filtered 16S reads (Q>=10, 1200-1800 bp)"
```

Modules: `NanoPlot/1.43.0-foss-2023a-Python-3.11.6`, `chopper/0.12.0b-GCC-12.3.0`
(and `SeqKit/2.4.0` for the download-subsampling step only). `run_example.sh`
wraps all of the above, including the download.

## What the figures show (this subsample)

| | Raw (15,000 reads) | Filtered (Q>=10, 1200–1800 bp) |
| --- | --- | --- |
| Reads | 15,000 | 7,355 (**49.0% retained**) |
| Median length | 1,433 bp | 1,478 bp |
| Read length N50 | 1,483 bp | 1,480 bp |
| STDEV length | 5,785 bp | 71 bp |
| % reads > Q10 | 61.9% | 100% |

Filtering collapses the length spread (STDEV 5,785 -> 71 bp: the short-fragment
tail and rare ultra-long concatemers are gone) and enforces the Q10 floor —
exactly the before/after effect Section 3 describes.

> **Note on retention (~49%).** This is a 2019 R9-era mock control with a median
> read quality near Q10, so the Q10 filter removes about half the reads — lower
> than the 60–85% the SOP quotes for a clean modern **R10.4.1 / SUP** library.
> That is a property of this older public dataset, not of the workflow. The
> figures still demonstrate the QC transformation clearly, which is their
> purpose.

### Why the log-length plots

The raw run contains a handful of ultra-long concatemer reads (max ~300 kb), so
NanoPlot's linear length axis is squashed to the far left and unreadable. The
SOP's `--loglength` flag exists precisely for this; the four committed figures
are the log-length NanoPlot outputs, which show the distribution properly and
keep the raw-vs-filtered comparison on the same axis.

## Figures

Copied and renamed from the NanoPlot output directories:

| Committed file | NanoPlot source | Shows |
| --- | --- | --- |
| `figures/raw_read_length_histogram.png` | `qc_raw/raw_Non_weightedLogTransformed_HistogramReadlength.png` | Raw read-length histogram (log x): amplicon peak ~1,450 bp plus short and long tails. |
| `figures/raw_length_vs_quality.png` | `qc_raw/raw_LengthvsQualityScatterPlot_loglength_dot.png` | Raw length-vs-mean-quality scatter: the good amplicon cluster and the low-quality / short reads chopper will remove. |
| `figures/filtered_read_length_histogram.png` | `qc_filtered/filtered_Non_weightedLogTransformed_HistogramReadlength.png` | Filtered read-length histogram: single tight peak, tails gone. |
| `figures/filtered_length_vs_quality.png` | `qc_filtered/filtered_LengthvsQualityScatterPlot_loglength_dot.png` | Filtered length-vs-quality scatter: a clean cluster bounded by the filters (>1,200 bp, >=Q10). |

## Files

| File | What it is |
| --- | --- |
| `run_example.sh` | Build script: download, subsample, and run the NanoPlot/chopper/NanoPlot steps; writes the four figures. |
| `figures/*.png` | The four QC figures embedded in `SOP_EMU_NeSI.md` Section 3. |
