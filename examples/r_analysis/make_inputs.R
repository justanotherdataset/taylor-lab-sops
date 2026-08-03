#!/usr/bin/env Rscript
# =============================================================================
# make_inputs.R  --  derive the small worked-example inputs from GlobalPatterns
# -----------------------------------------------------------------------------
# Produces counts.tsv, taxonomy.tsv and metadata.tsv in this directory from the
# GlobalPatterns dataset that ships inside the phyloseq package. Run this only
# to REGENERATE the inputs; the committed TSVs are the canonical copy and
# run_example.R reads those, not GlobalPatterns.
#
# Dataset : GlobalPatterns (Caporaso et al. 2011, PNAS 108 Suppl 1:4516-4522).
#           Ships with phyloseq (McMurdie & Holmes 2013). Derived count/taxonomy/
#           metadata tables are redistributable; see README.md for provenance.
#
# Subsetting / relabelling (kept truthful, no invented biology):
#   * The 9 GlobalPatterns SampleType values are collapsed into one grouping
#     variable `Environment` with three levels:
#       Human      = Feces + Skin + Tongue          (n = 9)
#       Freshwater = Freshwater + Freshwater (creek) (n = 5)
#       Saline     = Ocean + Sediment (estuary)      (n = 6)
#     Soil (n = 3) is dropped (< 5 samples). The original label is kept in
#     `OriginalSampleType` for provenance.
#   * GlobalPatterns has NO extraction blanks. The 3 Mock community samples
#     (a positive control of known composition) are carried through and marked
#     SampleType = "blank" ONLY so the decontam prevalence code path can be
#     exercised for an illustrative figure. This is NOT a real contamination
#     screen -- see run_example.R and README.md.
#   * Taxa are pruned to those present in >= 3 samples with total count >= 100
#     across the 23-sample subset, to keep the committed table small.
# =============================================================================

suppressMessages({
  library(phyloseq)
  library(dplyr)
})

set.seed(1)
outdir <- (function() {
  a <- commandArgs(trailingOnly = FALSE)
  f <- grep("^--file=", a, value = TRUE)
  if (length(f)) dirname(sub("^--file=", "", f[1])) else getwd()
})()

data(GlobalPatterns)
gp <- GlobalPatterns

st  <- as.character(sample_data(gp)$SampleType)
env <- case_when(
  st %in% c("Feces", "Skin", "Tongue")            ~ "Human",
  st %in% c("Freshwater", "Freshwater (creek)")   ~ "Freshwater",
  st %in% c("Ocean", "Sediment (estuary)")        ~ "Saline",
  st == "Mock"                                     ~ "Mock",
  TRUE                                             ~ "Other")

# Keep the three analysis environments plus the Mock illustrative controls.
keep <- env %in% c("Human", "Freshwater", "Saline", "Mock")
sub  <- prune_samples(keep, gp)
sub  <- prune_taxa(taxa_sums(sub) > 0, sub)

# Prune to prevalent taxa to keep the committed table small.
ct   <- as(otu_table(sub), "matrix")               # taxa x samples
if (!taxa_are_rows(sub)) ct <- t(ct)
prev <- rowSums(ct > 0)
tot  <- rowSums(ct)
keep_tx <- prev >= 3 & tot >= 100
sub  <- prune_taxa(keep_tx, sub)

cat(sprintf("Kept %d taxa x %d samples\n", ntaxa(sub), nsamples(sub)))

# ---- assemble the three tables ---------------------------------------------
counts <- as.data.frame(as(otu_table(sub), "matrix"))
if (!taxa_are_rows(sub)) counts <- as.data.frame(t(counts))
counts <- counts[, order(colnames(counts))]        # stable column order

tax <- as.data.frame(as(tax_table(sub), "matrix"), stringsAsFactors = FALSE)
# Rename GlobalPatterns ranks to the SOP's lowercase scheme.
rank_map <- c(Kingdom = "superkingdom", Phylum = "phylum", Class = "class",
              Order = "order", Family = "family", Genus = "genus",
              Species = "species")
colnames(tax) <- rank_map[colnames(tax)]
tax <- tax[, c("species", "genus", "family", "order", "class",
               "phylum", "superkingdom")]
tax <- tax[rownames(counts), , drop = FALSE]

sd <- as(sample_data(sub), "data.frame")
orig <- as.character(sd$SampleType)
environment <- case_when(
  orig %in% c("Feces", "Skin", "Tongue")          ~ "Human",
  orig %in% c("Freshwater", "Freshwater (creek)") ~ "Freshwater",
  orig %in% c("Ocean", "Sediment (estuary)")      ~ "Saline",
  orig == "Mock"                                   ~ "Mock",
  TRUE                                             ~ "Other")
meta <- data.frame(
  SampleID           = rownames(sd),
  Environment        = environment,
  OriginalSampleType = orig,
  # decontam control indicator: Mock stands in as an ILLUSTRATIVE blank only.
  SampleType         = ifelse(environment == "Mock", "blank", "sample"),
  row.names          = rownames(sd),
  stringsAsFactors   = FALSE)
meta <- meta[colnames(counts), , drop = FALSE]

stopifnot(identical(rownames(meta), colnames(counts)))
stopifnot(identical(rownames(tax),  rownames(counts)))

# ---- write ------------------------------------------------------------------
write.table(data.frame(tax_id = rownames(counts), counts, check.names = FALSE),
            file.path(outdir, "counts.tsv"),
            sep = "\t", quote = FALSE, row.names = FALSE)
write.table(data.frame(tax_id = rownames(tax), tax, check.names = FALSE),
            file.path(outdir, "taxonomy.tsv"),
            sep = "\t", quote = FALSE, row.names = FALSE)
write.table(meta,
            file.path(outdir, "metadata.tsv"),
            sep = "\t", quote = FALSE, row.names = FALSE)

cat("Environment x SampleType:\n")
print(table(meta$Environment, meta$SampleType))
cat("\nWrote counts.tsv, taxonomy.tsv, metadata.tsv to ", outdir, "\n", sep = "")
