#!/usr/bin/env Rscript
# Select the DE-IDENTIFIED, k-anonymous set of TOFI V3-V4 samples for the worked
# example, grouped by Ethnicity x Gender (the cohort's study design). Writes a
# PRIVATE key (label <-> participant; never committed) and a PUBLIC de-identified
# metadata.tsv (generic Sample### labels; Ethnicity + Gender + SampleType only).
#
# Usage: select_subset.R <raw_dir> <meta_xlsx> <per_cell> <key_out> <meta_out>
#   per_cell = 0 (or "all")  -> every clean-matched, non-control sample per cell
#   per_cell = N (>0)        -> the first N per Ethnicity x Gender cell (small example)
suppressMessages(library(readxl))
a <- commandArgs(trailingOnly = TRUE)
raw <- a[1]; xlsx <- a[2]
per_cell <- suppressWarnings(as.integer(a[3])); if (is.na(per_cell) || per_cell <= 0) per_cell <- Inf
key_out <- a[4]; meta_out <- a[5]

d <- read_excel(xlsx, sheet = 1)[, c("ID","Ethnicity","Gender")]
d$ID <- as.character(d$ID)
# normalise Ethnicity spelling/case; collapse rare labels into a broad label if needed
d$Ethnicity <- tools::toTitleCase(tolower(trimws(d$Ethnicity)))   # "chinese"/"Chinese" -> "Chinese"
d$Gender    <- trimws(d$Gender)

# FASTQ sample names -> numeric core; drop controls and IDs that do not match metadata
r1   <- list.files(raw, pattern = "_R1_001\\.fastq\\.gz$")
samp <- sub("_S[0-9]+_L[0-9]+_R1_001\\.fastq\\.gz$", "", r1)
ctrl <- grepl("Control|NAT|CHUNG|Blank|NTC|POS|NEG", samp, ignore.case = TRUE)
core <- sub("[^0-9].*$", "", sub("^[A-Za-z]+", "", samp))
ok   <- !ctrl & !is.na(core) & core != "" & core %in% d$ID
mm   <- match(core[ok], d$ID)
df   <- data.frame(prefix = samp[ok], core = core[ok],
                   Ethnicity = d$Ethnicity[mm], Gender = d$Gender[mm], stringsAsFactors = FALSE)
df   <- df[!is.na(df$Ethnicity) & !is.na(df$Gender), ]
df$cell <- paste(df$Ethnicity, df$Gender, sep = "|")

sel <- do.call(rbind, lapply(split(df, df$cell), function(g) {
  g <- g[order(as.numeric(g$core)), ]; head(g, per_cell) }))
tab <- table(sel$cell)
if (any(tab < 3)) stop("k-anonymity: a published Ethnicity x Gender cell has < 3 samples: ",
                       paste(names(tab)[tab < 3], collapse = ", "))
sel <- sel[order(sel$Ethnicity, sel$Gender, as.numeric(sel$core)), ]
sel$label <- sprintf("Sample%03d", seq_len(nrow(sel)))

write.table(sel[, c("label","prefix","core","Ethnicity","Gender")], key_out,
            sep = "\t", quote = FALSE, row.names = FALSE)                      # PRIVATE
write.table(data.frame(SampleID = sel$label, Ethnicity = sel$Ethnicity,
                       Gender = sel$Gender, SampleType = "sample"),
            meta_out, sep = "\t", quote = FALSE, row.names = FALSE)            # PUBLIC de-id
cat("selected", nrow(sel), "samples (per_cell =", per_cell, ")\n")
cat("k-anonymity cell counts (all must be >= 3):\n"); print(table(sel$Ethnicity, sel$Gender))
