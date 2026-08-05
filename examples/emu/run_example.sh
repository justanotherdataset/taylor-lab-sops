#!/bin/bash
# =============================================================================
# run_example.sh  --  worked QC example for SOP_EMU_NeSI.md (Section 3)
# -----------------------------------------------------------------------------
# Reproduces the four NanoPlot QC figures embedded in the EMU SOP by running the
# SOP's exact read-QC workflow on a small public Oxford Nanopore full-length 16S
# dataset:
#
#   1. download a public ONT full-length 16S run from ENA
#   2. subsample to 15,000 reads (keeps it small and fast)
#   3. NanoPlot on the raw reads            -> qc_raw/
#   4. chopper filter (Q>=10, 1200-1800 bp) -> filtered/
#   5. NanoPlot on the filtered reads        -> qc_filtered/
#   6. copy the four selected plots into examples/emu/figures/
#
# The NanoPlot and chopper commands and parameters mirror SOP_EMU_NeSI.md
# Section 3 exactly. See README.md for dataset provenance and the note that
# these are ILLUSTRATIVE figures from public data, not from your own run.
#
# Runs in a few minutes on 15,000 reads; light enough for a NeSI login node,
# or submit as an sbatch job. Modules match the SOP:
#   NanoPlot/1.43.0-foss-2023a-Python-3.11.6
#   chopper/0.12.0b-GCC-12.3.0
#   SeqKit/2.4.0            (for download-subsampling only; not an EMU step)
#
# Usage:   bash run_example.sh
# Override scratch/threads:  WORKDIR=/path/to/scratch THREADS=8 bash run_example.sh
# =============================================================================
set -euo pipefail

# --- config -----------------------------------------------------------------
ACCESSION="ERR3674472"   # Ground_Zymo: ZymoBIOMICS mock, full-length 16S rDNA, ONT
FASTQ_URL="https://ftp.sra.ebi.ac.uk/vol1/fastq/ERR367/002/ERR3674472/ERR3674472_1.fastq.gz"
SUBSAMPLE_N=15000        # reads to keep
SUBSAMPLE_SEED=100       # fixed seed -> reproducible subsample
THREADS="${THREADS:-6}"

# Scratch for the (large) download and intermediates. NEVER put these in the repo.
WORKDIR="${WORKDIR:-${CLAUDE_JOB_DIR:-/tmp}/emu_qc_build}"
# Directory this script lives in (repo examples/emu) -> where the 4 figures land.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIGDIR="${SCRIPT_DIR}/figures"

mkdir -p "${WORKDIR}"/{raw_files,filtered,qc_raw,qc_filtered,logs} "${FIGDIR}"
cd "${WORKDIR}"
echo "Workdir: ${WORKDIR}"
echo "Figures will be written to: ${FIGDIR}"

# --- 1+2. download + subsample (not an EMU step; keeps the example small) ----
if [[ ! -s "${ACCESSION}_1.fastq.gz" ]]; then
    echo "Downloading ${ACCESSION} from ENA ..."
    curl -fSL -o "${ACCESSION}_1.fastq.gz" "${FASTQ_URL}"
fi

module purge >/dev/null 2>&1 || true
module load SeqKit/2.4.0
echo "Subsampling to ${SUBSAMPLE_N} reads (seed ${SUBSAMPLE_SEED}) ..."
seqkit sample -s "${SUBSAMPLE_SEED}" -n "${SUBSAMPLE_N}" "${ACCESSION}_1.fastq.gz" \
    2>/dev/null | seqkit seq -o raw_files/zymo_ground.fastq 2>/dev/null
seqkit stats -a raw_files/zymo_ground.fastq

# --- 3. NanoPlot on the RAW reads (SOP Section 3, Step 2) --------------------
module purge >/dev/null 2>&1 || true
module load NanoPlot/1.43.0-foss-2023a-Python-3.11.6
echo "NanoPlot: raw reads ..."
NanoPlot \
    --fastq raw_files/*.fastq \
    --outdir qc_raw \
    --prefix raw_ \
    --threads "${THREADS}" \
    --loglength \
    --plots dot \
    --title "Raw 16S reads" > logs/nanoplot_raw.log 2>&1

# --- 4. chopper filter (SOP Section 3, Step 3 -- EXACT thresholds) ----------
module purge >/dev/null 2>&1 || true
module load chopper/0.12.0b-GCC-12.3.0
MIN_LENGTH=1200
MAX_LENGTH=1800
MIN_QUALITY=10
echo "chopper: Q>=${MIN_QUALITY}, ${MIN_LENGTH}-${MAX_LENGTH} bp ..."
for fastq in raw_files/*.fastq; do
    sample=$(basename "${fastq}" .fastq)
    chopper \
        --input "${fastq}" \
        --quality ${MIN_QUALITY} \
        --minlength ${MIN_LENGTH} \
        --maxlength ${MAX_LENGTH} \
        --threads "${THREADS}" \
        > "filtered/${sample}_filtered.fastq" 2>> logs/chopper.log
    raw_count=$(( $(wc -l < "${fastq}") / 4 ))
    filt_count=$(( $(wc -l < "filtered/${sample}_filtered.fastq") / 4 ))
    pct=$(awk -v r="${raw_count}" -v f="${filt_count}" \
          'BEGIN{ if (r>0) printf "%.1f", 100*f/r; else print "NA" }')
    echo "  ${sample}: ${raw_count} raw -> ${filt_count} filtered (${pct}% retained)"
done

# --- 5. NanoPlot on the FILTERED reads (SOP Section 3, Step 4) --------------
module purge >/dev/null 2>&1 || true
module load NanoPlot/1.43.0-foss-2023a-Python-3.11.6
echo "NanoPlot: filtered reads ..."
NanoPlot \
    --fastq filtered/*_filtered.fastq \
    --outdir qc_filtered \
    --prefix filtered_ \
    --threads "${THREADS}" \
    --loglength \
    --plots dot \
    --title "Filtered 16S reads (Q>=10, 1200-1800 bp)" > logs/nanoplot_filtered.log 2>&1

# --- 6. select + rename the four figures for the SOP -------------------------
# The dataset carries rare ultra-long concatemer reads (max ~300 kb), so the
# LINEAR length axis is unreadable; the SOP's --loglength plots are the faithful
# choice and keep the raw-vs-filtered comparison on the same axis.
echo "Copying the four figures into ${FIGDIR} ..."
cp qc_raw/raw_Non_weightedLogTransformed_HistogramReadlength.png            "${FIGDIR}/raw_read_length_histogram.png"
cp qc_raw/raw_LengthvsQualityScatterPlot_loglength_dot.png                  "${FIGDIR}/raw_length_vs_quality.png"
cp qc_filtered/filtered_Non_weightedLogTransformed_HistogramReadlength.png  "${FIGDIR}/filtered_read_length_histogram.png"
cp qc_filtered/filtered_LengthvsQualityScatterPlot_loglength_dot.png        "${FIGDIR}/filtered_length_vs_quality.png"

echo "Done. Four figures written:"
ls -la "${FIGDIR}"/*.png
