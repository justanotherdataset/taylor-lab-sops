#!/usr/bin/env Rscript
# Worked-example DADA2 run + three illustrative figures for SOP_DADA2_NeSI.md,
# on the de-identified TOFI V3-V4 cohort. Mirrors SOP Sections 3-6. This is the
# example harness; the production single-run pipeline is the repo-root 05_dada2.R.
# All committed outputs are DE-IDENTIFIED (generic Sample### labels only).
#
# Usage: example_dada2.R <trimmed> <scratch_out> <ref> <truncF> <truncR> <threads> <figdir> <metadata_tsv> <example_dir>
suppressMessages({ library(dada2); library(ShortRead); library(ggplot2)
                   library(tidyr); library(vegan) })
a <- commandArgs(trailingOnly = TRUE)
reads <- a[1]; out <- a[2]; ref <- a[3]
tF <- as.integer(a[4]); tR <- as.integer(a[5]); nthreads <- as.integer(a[6])
figdir <- a[7]; metaf <- a[8]; exdir <- a[9]
dir.create(file.path(out, "filtered"), recursive = TRUE, showWarnings = FALSE)
dir.create(figdir, recursive = TRUE, showWarnings = FALSE)
silva   <- file.path(ref, "silva_nr99_v138.1_train_set.fa.gz")
silvasp <- file.path(ref, "silva_species_assignment_v138.1.fa.gz")

fnF <- sort(list.files(reads, pattern = "_R1_001\\.fastq\\.gz$", full.names = TRUE))
fnR <- sort(list.files(reads, pattern = "_R2_001\\.fastq\\.gz$", full.names = TRUE))
sn  <- sub("_R1_001\\.fastq\\.gz$", "", basename(fnF))   # already de-identified: Sample###
filtF <- file.path(out, "filtered", paste0(sn, "_F.fq.gz"))
filtR <- file.path(out, "filtered", paste0(sn, "_R.fq.gz"))

## FIGURE 1 -- aggregate quality profile of the primer-trimmed reads (SOP Section 4)
ggsave(file.path(figdir, "01_quality_profile.png"),
       plotQualityProfile(c(fnF, fnR), aggregate = TRUE) +
         ggtitle("Aggregate quality profile, primer-trimmed reads (illustrative example)"),
       width = 8, height = 4, dpi = 120)

## self-tuning truncLen cap (SOP Section 4 / 5)
sw <- function(f) { w <- integer(0)
  for (x in f[seq_len(min(6, length(f)))]) {
    q <- tryCatch(readFastq(x), error = function(e) NULL)
    if (!is.null(q) && length(q) > 0) w <- c(w, width(q)) }
  w }
capF <- floor(quantile(sw(fnF), 0.02, na.rm = TRUE)); capR <- floor(quantile(sw(fnR), 0.02, na.rm = TRUE))
tF <- min(tF, capF); tR <- min(tR, capR)
message(sprintf("truncLen %s/%s (2%%ile cap %s/%s)", tF, tR, capF, capR))

## denoise (SOP Section 5a-5e)
flt <- filterAndTrim(fnF, filtF, fnR, filtR, truncLen = c(tF, tR),
                     maxEE = c(2, 2), truncQ = 2, maxN = 0, rm.phix = TRUE,
                     compress = TRUE, multithread = nthreads)
keep <- file.exists(filtF); filtF <- filtF[keep]; filtR <- filtR[keep]; sn <- sn[keep]
errF <- learnErrors(filtF, multithread = nthreads); errR <- learnErrors(filtR, multithread = nthreads)
ddF  <- dada(filtF, err = errF, multithread = nthreads); ddR <- dada(filtR, err = errR, multithread = nthreads)
mg   <- mergePairs(ddF, filtF, ddR, filtR)
tm   <- sum(unlist(lapply(mg, function(x) sum(x$abundance))), na.rm = TRUE)
td   <- sum(sapply(ddF, function(x) sum(getUniques(x))), na.rm = TRUE)
fr   <- if (td > 0) tm / td else 0
if (fr >= 0.20) { st <- makeSequenceTable(mg); mode <- "merged" } else { st <- makeSequenceTable(ddF); mode <- "R1only" }
stnc <- removeBimeraDenovo(st, method = "consensus", multithread = nthreads)
taxa <- addSpecies(assignTaxonomy(stnc, silva, multithread = nthreads, tryRC = TRUE), silvasp)
message(sprintf("mode=%s  ASVs=%d  merged_frac=%.2f  median_reads=%.0f", mode, ncol(stnc), fr, median(rowSums(stnc))))

## reshape to the SOP_R_Analysis.md Section 3 contract (SOP Section 5g)
asv  <- sprintf("ASV%04d", seq_len(ncol(stnc)))
seqs <- colnames(stnc)
writeLines(paste0(">", asv, "\n", seqs), file.path(exdir, "asv.fasta"))   # for the optional UniFrac tree
cnt <- t(stnc); rownames(cnt) <- asv; colnames(cnt) <- sn
tx  <- as.data.frame(taxa)[, c("Kingdom","Phylum","Class","Order","Family","Genus","Species")]
colnames(tx) <- c("superkingdom","phylum","class","order","family","genus","species")
tx  <- tx[, c("species","genus","family","order","class","phylum","superkingdom")]; rownames(tx) <- asv
write.table(data.frame(tax_id = asv, tx, cnt[asv, , drop = FALSE], check.names = FALSE),
            file.path(exdir, "counts_dada2.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)

## FIGURE 2 -- reads through the pipeline (SOP Section 6)
gN <- function(x) sum(getUniques(x))
mergedN <- if (mode == "merged") sapply(mg, gN) else NA
trk <- data.frame(sample = sn, input = flt[keep, 1], filtered = flt[keep, 2],
                  denoised = sapply(ddF, gN), merged = mergedN, nonchim = rowSums(stnc))
write.table(trk, file.path(exdir, "track.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)
steps <- c("input", "filtered", "denoised", "merged", "nonchim")
long  <- pivot_longer(trk, all_of(steps), names_to = "step", values_to = "reads")
long$step <- factor(long$step, levels = steps)
p2 <- ggplot(long, aes(step, reads, group = sample)) +
  geom_line(alpha = 0.25, colour = "#4C72B0") + geom_point(size = 0.6, colour = "#4C72B0") +
  stat_summary(aes(group = 1), fun = median, geom = "line", colour = "#C44E52", linewidth = 1.1) +
  labs(x = NULL, y = "reads", title = "Reads through the DADA2 pipeline (illustrative example; red = median)") +
  theme_minimal(base_size = 11)
ggsave(file.path(figdir, "02_read_tracking.png"), p2, width = 7.5, height = 4.5, dpi = 120)

## FIGURE 3 -- rarefaction: ASV richness vs sequencing depth (SOP Section 6)
meta <- tryCatch(read.delim(metaf), error = function(e) NULL)
cols <- c(Caucasian = "#4C72B0", Chinese = "#DD8452")
grp  <- if (!is.null(meta)) meta$Ethnicity[match(sn, meta$SampleID)] else NULL   # sn aligns with stnc rows
rcol <- if (!is.null(grp) && !all(is.na(grp))) cols[grp] else "#4C72B0"
png(file.path(figdir, "03_asv_rarefaction.png"), width = 950, height = 680, res = 120)
rarecurve(stnc, step = 500, col = rcol, label = FALSE,
          xlab = "reads sampled", ylab = "ASVs observed",
          main = "Rarefaction: ASV richness vs depth (illustrative example)")
if (!is.null(grp) && !all(is.na(grp)))
  legend("bottomright", legend = names(cols), col = cols, lwd = 2, bty = "n", title = "Ethnicity")
dev.off()

cat(sprintf("example done: mode=%s samples=%d ASVs=%d -> figures in %s\n", mode, nrow(stnc), ncol(stnc), figdir))
