#!/bin/bash
#SBATCH --account uoa03769
#SBATCH --job-name dada2_example
#SBATCH --time 08:00:00
#SBATCH --mem 120G
#SBATCH --cpus-per-task 6
#SBATCH --output /nesi/nobackup/uoa03769/dada2_example_%j.out
#SBATCH --error /nesi/nobackup/uoa03769/dada2_example_%j.err
# =============================================================================
# run_example.sh  --  worked example for SOP_DADA2_NeSI.md
# -----------------------------------------------------------------------------
# Reproduces the three illustrative DADA2 figures in the SOP by running the SOP's
# own workflow (cutadapt -> quality profile -> DADA2 -> taxonomy) on the
# DE-IDENTIFIED TOFI V3-V4 16S cohort, grouped by Ethnicity x Gender (the
# cohort's actual study design). Full clean-matched, non-control cohort (~157
# samples), full read depth -- a production-scale run, hence a SLURM batch job.
#
# GOVERNANCE  (read README.md first):
#   * Raw reads are held in the lab PROJECT directory (access-controlled) and are
#     NOT publicly deposited. Only DE-IDENTIFIED derived outputs are committed:
#     figures/*.png, metadata.tsv, counts_dada2.tsv, track.tsv -- all keyed to
#     generic Sample### labels. No raw reads, dates, or clinical fields are ever
#     committed.
#   * The label <-> participant key is written to a PRIVATE, backed-up path on
#     PROJECT ($PRIV, default /nesi/project/uoa03769/dada2_example_private),
#     OUTSIDE the repo. Treat it like the clinical sheet; never commit it.
#   * k-anonymity is enforced by select_subset.R (>=3 samples per published
#     Ethnicity x Gender cell). Only Ethnicity and Gender are published.
#   * Publish only on the lab's confirmation that ethics/consent covers public
#     release of a de-identified 16S dataset -- the same basis as this cohort's
#     already-public shotgun metagenome (same Ethnicity/Gender framing).
#
# Run it (as a lab member with project access), from THIS directory:
#     cd examples/dada2 && sbatch run_example.sh
# Overrides:  RAW=... META_XLSX=... TRUNC_F=280 TRUNC_R=220 bash run_example.sh
# =============================================================================
set -euo pipefail

# --- config: PRIVATE inputs (referenced, never committed) --------------------
RAW="${RAW:-/nesi/project/uoa03769/Tommy/Rawdata}"
META_XLSX="${META_XLSX:-/nesi/project/uoa03769/Tommy/TOFI FU microbiome sample list_CHECKED_UPDATED_17Mar2022 data entry list.xlsx}"
PER_CELL="${PER_CELL:-0}"          # 0 = every clean-matched non-control sample (full cohort)
TRUNC_F="${TRUNC_F:-280}"          # 2x300 reads (SOP Section 4)
TRUNC_R="${TRUNC_R:-220}"
THREADS="${SLURM_CPUS_PER_TASK:-6}"
FWD=CCTACGGGNGGCWGCAG              # 341F
REV=GACTACHVGGGTATCTAATCC          # 785R

# SELF_DIR = where the helper scripts live; EXDIR = where committed outputs land
# (defaults to SELF_DIR; override EXDIR to send outputs elsewhere, e.g. a test dir)
SELF_DIR="${SELF_DIR:-${SLURM_SUBMIT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}}"
EXDIR="${EXDIR:-$SELF_DIR}"
FIGDIR="$EXDIR/figures"; mkdir -p "$FIGDIR"
# scratch for reads/intermediates (nobackup); NEVER the repo
WORKDIR="${WORKDIR:-/nesi/nobackup/uoa03769/dada2_example}"
# the re-identification key lives on PROJECT (backed up, access-controlled),
# OUTSIDE the repo; treat it like the clinical sheet and never commit it.
PRIV="${PRIV:-/nesi/project/uoa03769/dada2_example_private}"
mkdir -p "$WORKDIR"/{raw_deid,trimmed,asv,ref,logs} "$PRIV"
echo "example dir : $EXDIR"
echo "scratch     : $WORKDIR"
echo "private key : $PRIV/key.tsv"

# --- 1. select the de-identified, k-anonymous set (writes PRIVATE key + PUBLIC metadata) ---
module purge; module load R-bundle-Bioconductor/3.23-foss-2026-R-4.6.0
Rscript "$SELF_DIR/select_subset.R" "$RAW" "$META_XLSX" "$PER_CELL" "$PRIV/key.tsv" "$EXDIR/metadata.tsv"

# --- 2. de-identify + repair -------------------------------------------------
#   Rename the subset to generic labels AND repair truncated gzips: some raw
#   FASTQs in this cohort are incomplete (interrupted copies), and R1/R2 truncate
#   at different points. We salvage complete 4-line records from each, then trim
#   R1/R2 to equal length -- Illumina keeps mates in the same order, so the first
#   K records of each file are paired. (Verify raw integrity with `gzip -t`.)
rm -f "$WORKDIR"/raw_deid/*.fastq.gz
sal() { { zcat "$1" 2>/dev/null || true; } | awk 'NR%4==1{r=$0"\n";next}{r=r$0"\n"} NR%4==0{printf "%s",r}'; }
tail -n +2 "$PRIV/key.tsv" | while IFS=$'\t' read -r label prefix core eth gen; do
    r1=$(ls "$RAW/${prefix}_"*"_R1_001.fastq.gz" 2>/dev/null | head -1)
    r2=$(ls "$RAW/${prefix}_"*"_R2_001.fastq.gz" 2>/dev/null | head -1)
    if [ -z "$r1" ] || [ -z "$r2" ]; then echo "WARN: reads missing for $label"; continue; fi
    o1="$WORKDIR/raw_deid/${label}_R1_001.fastq.gz"; o2="$WORKDIR/raw_deid/${label}_R2_001.fastq.gz"
    sal "$r1" | gzip -c > "$o1"; sal "$r2" | gzip -c > "$o2"
    k1=$(( $(zcat "$o1" | wc -l) / 4 )); k2=$(( $(zcat "$o2" | wc -l) / 4 )); K=$(( k1 < k2 ? k1 : k2 ))
    if [ "$k1" -ne "$k2" ]; then
        zcat "$o1" | awk -v n=$((K*4)) 'NR<=n' | gzip -c > "$o1.t" && mv "$o1.t" "$o1"
        zcat "$o2" | awk -v n=$((K*4)) 'NR<=n' | gzip -c > "$o2.t" && mv "$o2.t" "$o2"
    fi
done
echo "de-identified samples: $(ls "$WORKDIR"/raw_deid/*_R1_001.fastq.gz | wc -l)"

# --- 3. remove primers (SOP Section 3) ---------------------------------------
module purge; module load cutadapt/5.2-foss-2023a-Python-3.11.6
for r1 in "$WORKDIR"/raw_deid/*_R1_001.fastq.gz; do
    r2="${r1/_R1_001/_R2_001}"; b=$(basename "$r1" _R1_001.fastq.gz)
    cutadapt -g "$FWD" -G "$REV" --discard-untrimmed -j "$THREADS" \
        -o "$WORKDIR/trimmed/${b}_R1_001.fastq.gz" \
        -p "$WORKDIR/trimmed/${b}_R2_001.fastq.gz" "$r1" "$r2" >> "$WORKDIR/logs/cutadapt.log"
done

# --- 4. SILVA 138.1 reference (once) -----------------------------------------
REF="$WORKDIR/ref"
[ -s "$REF/silva_nr99_v138.1_train_set.fa.gz" ]    || wget -q -O "$REF/silva_nr99_v138.1_train_set.fa.gz"    https://zenodo.org/records/4587955/files/silva_nr99_v138.1_train_set.fa.gz
[ -s "$REF/silva_species_assignment_v138.1.fa.gz" ] || wget -q -O "$REF/silva_species_assignment_v138.1.fa.gz" https://zenodo.org/records/4587955/files/silva_species_assignment_v138.1.fa.gz

# --- 5. DADA2 + the three illustrative figures (SOP Sections 4-6) -------------
module purge; module load R-bundle-Bioconductor/3.23-foss-2026-R-4.6.0
Rscript "$SELF_DIR/example_dada2.R" "$WORKDIR/trimmed" "$WORKDIR/asv" "$REF" \
        "$TRUNC_F" "$TRUNC_R" "$THREADS" "$FIGDIR" "$EXDIR/metadata.tsv" "$EXDIR"

echo "Done. Committed-example outputs (de-identified):"
ls -la "$FIGDIR"/*.png "$EXDIR"/metadata.tsv "$EXDIR"/counts_dada2.tsv "$EXDIR"/track.tsv 2>/dev/null
