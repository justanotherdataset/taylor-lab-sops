# Synthesis — Taylor Lab Bioinformatic SOPs

Seam review plus consolidation of `reviews/EMU.review.md`, `reviews/CONCOMPRA.review.md`,
`reviews/READBASED.review.md` and `reviews/R_ANALYSIS.review.md`.

**Citation convention in this document.** `F-01` … `F-22` are this report's own seam findings,
defined in *Seam findings* below. Findings inherited from the four document reviews are always
written with their file prefix — `EMU F-01`, `CONCOMPRA F-02`, `READBASED F-01`, `R F-09` — and
are never referred to by a bare number.

---

## State of the repository

The explanatory writing is the asset and it is close to finished. The 16S and Nanopore background
in Part 1, the EM explanation, the rarefaction/rarefying distinction and the compositionality
worked example in Part 2, the governance and control-design sections in the read-based SOP, and
the silent-failure warnings scattered through all four documents are better than most published
protocols. Almost none of that needs rewriting. The four reviewers independently reached the same
verdict: keep the prose, fix the code and the joins.

The weakness is at the boundaries — inside code blocks, and between documents. Seventeen S1
defects across the set produce output that looks right and is not: a depth budget that
under-orders sequencing by up to two orders of magnitude, a metadata vector applied to a count
table in the wrong order, an FDR correction applied to the survivors of an earlier filter, a
consensus taken between two methods run at different taxonomic ranks. Between documents it is
worse, because nobody owns the joins: **Part 2's data loader cannot read what two of its three
upstream documents produce, and will silently destroy relative-abundance input rather than
refuse it.** The README asserts that Part 2 is platform-agnostic and that CONCOMPRA "hands off to
Part 2"; neither is true of the code as written.

Three structural facts drive most of the seam work. First, Part 2 numbers its sections 5 and 6 as
a continuation of Part 1, which breaks the README's own cross-reference rule and makes nonsense of
the numbering for readers arriving from CONCOMPRA (§1–10) or the read-based SOP (§1–14). Second,
no document produces the metadata sheet Part 2 requires, and Part 1 never mentions negative
controls at all, although the workflow it feeds cannot run decontamination without them. Third,
the three documents give three different answers to the same cluster question — where a batch job
runs from — and one of them argues explicitly against the answer another one uses.

**Where to spend time first.** One day on the README conventions and the two dead cross-document
pointers; then, in parallel, the read-based depth formula (irreversible, one paragraph) and Part
2's input contract and sample-identity discipline (blocks nine other items). After that the
per-document work can run in parallel across three people. Do not start CONCOMPRA's or Part 1's
handoff sections until Part 2's input contract is settled — they both write into it.

**Do not** treat this as a shortening exercise. Of roughly ten cuts proposed across the four
reports, one was struck outright and two were amended (see *Audit of proposed cuts* at the end of
the Work plan). The reviewers held the line on load-bearing content; the rewrite must too.

---

## Blocking defects

Every S1 across all five files, globally ranked. Ranking is by (a) irreversibility, (b) how many
readers reach the defect, (c) how plausible the wrong output looks — not by document order.
Note that **severity rank is not work order**: EMU F-01 sits at #10 but must be fixed before the
rest of Part 1, because five other Part 1 fixes depend on the path it settles.

| # | Finding | Anchor | Failure in one line |
|---|---|---|---|
| 1 | READBASED F-01 | `SOP_READBASED_NeSI.md:69` | Reader multiplies the depth target by the host fraction instead of dividing by (1 − host fraction), orders 4.5 M pairs where 59 M were needed, and every sample fails the depth gate — after the sequencing money is spent. **The only defect in the repository that cannot be fixed afterwards.** |
| 2 | **F-01** (seam, merges R F-09) | `SOP_R_Analysis.md:126` + `SOP_READBASED_NeSI.md:632`, `SOP_CONCOMPRA_NeSI.md:481` | Reader arrives from the read-based SOP with a relative-abundance table, runs Part 2's loader as instructed, `round()` turns percentages into small integers, SRS "normalises" to a Cmin of ~100, and a complete set of diversity figures is produced from destroyed data with no error. |
| 3 | R F-01 | `SOP_R_Analysis.md:202-222`, `:958` | Metadata rows are never ordered against count-table columns, so `neg = is_blank` marks the wrong sample as the blank, decontam removes taxa from a real sample, and every indicator species is assigned to the wrong site. |
| 4 | R F-02 | `SOP_R_Analysis.md:379-381` | Reader drops a shallow sample in Stage 4; `ps_srs` then holds n−1 samples and `ps_raw` still holds n, so Bray-Curtis and Aitchison results computed on different datasets are reported as agreement. |
| 5 | R F-07 | `SOP_R_Analysis.md:969-975` | FDR is applied to the taxa that already passed p < 0.05, so ~25 of 30 "FDR-corrected" indicator species survive where correct BH across all 400 tested would leave about 3. |
| 6 | R F-06 | `SOP_R_Analysis.md:905` vs `:847` | ANCOM-BC2 tests genera, MaAsLin2 tests species, and the document's headline recommendation is to report their consensus — which is computed between two lists that could never overlap. |
| 7 | R F-04 | `SOP_R_Analysis.md:728-738` | `p.adjust.m` is swallowed by `...`, so pairwise PERMANOVA p-values are raw while the text says they are BH-corrected. `NEEDS-BENCH-CHECK` — `args(pairwiseAdonis::pairwise.adonis2)`. |
| 8 | R F-05 | `SOP_R_Analysis.md:854` vs `:872` | The code sets `neg_lb = TRUE`, the note six lines below says it needs ≥30 samples per group, and the worked example has four; taxa are declared structurally absent on the strength of three observations. |
| 9 | R F-03 | `SOP_R_Analysis.md:404-436` | Kruskal-Wallis returns p = 0.14 and the reader reports no pairwise result, while the plotting block draws an unadjusted `*` bracket on the same data and that figure goes into the thesis. |
| 10 | EMU F-01 | `SOP_EMU_NeSI.md:51-55`, `:298-299`, `:583-584` | The pipeline runs in the shared allocation root rather than the workspace the document defines, so a second run or a labmate overwrites `raw_files/`, and the manifest silently enumerates both studies' samples into one count table. |
| 11 | EMU F-03 | `SOP_EMU_NeSI.md:433-436` | `grep -c "^@"` also counts quality lines beginning with `@` (Q31 in the Phred table this document prints at line 256), so retention percentages are wrong in both directions and the 30% alarm threshold is applied to a number that was never right. |
| 12 | EMU F-04 | `SOP_EMU_NeSI.md:787-788`, `:821-823` | Two per-sample files with the same basename in different subdirectories — the layout the script's own docstring advertises — collide, one sample's counts are discarded and the other's are written into two identically named columns. |
| 13 | EMU F-02 | `SOP_EMU_NeSI.md:304-309` | `cp` fails on any barcode directory holding more than one FASTQ chunk and matches nothing when MinKNOW gzipped its output, so samples are simply absent from every downstream table with no message at any stage. |
| 14 | READBASED F-02 | `SOP_READBASED_NeSI.md:601-602`, `:688` | `ec_cpm.tsv` and `ko_cpm.tsv` are never split, then offered to MaAsLin as a test set, so every EC number is tested twice inside one BH family — the exact error the document names at line 596. |
| 15 | READBASED F-03 | `SOP_READBASED_NeSI.md:640` | The SRS row routes model-estimated counts into alpha diversity, which line 476 of the same document forbids. |
| 16 | CONCOMPRA F-01 | `SOP_CONCOMPRA_NeSI.md:135-140`, `:156` | The duplicate screen compares whole header lines while `filtlong` keys on the read name alone, so a re-basecalled run reports zero duplicates, passes the gate, and fails silently downstream. |
| 17 | CONCOMPRA F-02 | `SOP_CONCOMPRA_NeSI.md:291-299` vs `:534` | Section 6's only per-sample verification reads `temporary/`, which `main.sh` deletes at the end of every successful run, so the gate the roadmap calls "the one thing to remember" never fires. |

Paste-ready replacement text for all seventeen exists in the four source reports at the finding
IDs above; this report does not reproduce it. Items 2 and its Part 2 counterpart are specified in
full under **F-01** below, because the reviewer's version needs the cross-document wording.

---

## Seam findings

### F-01 · S1 · Part 2 silently destroys relative-abundance input that two upstream SOPs send it
- **Where:** `SOP_R_Analysis.md:111-126` and `SOP_READBASED_NeSI.md:632, 640`; same path from
  `SOP_CONCOMPRA_NeSI.md:481`
- **Quote:**
  > emu_combined <- read.table("emu-combined-counts_silva.tsv",
  >                            header = TRUE, row.names = 1,
  >                            check.names = FALSE, sep = "\t")
  > …
  > # Round counts to whole numbers (Emu counts are EM-estimated floats)
  > counts_raw <- round(counts_raw)

  against `SOP_READBASED_NeSI.md:632`:

  > Follow `SOP_R_Analysis.md` for the mechanics. This section covers only what differs because
  > your input is MetaPhlAn relative abundance rather than an amplicon count table.
- **Defect:** Part 2's loader is written for one file with one shape. MetaPhlAn's
  `merged_species.tsv` has no rank columns (the lineage is a single `clade_name` string), and its
  values are relative abundance as a **percentage**, 0–100. `round()` on that yields small
  integers rather than an error, and every step after it runs.
- **Failure:** A reader finishes the read-based SOP, reads line 632, opens Part 2 at Stage 1 and
  runs it. `tax_cols` is empty, so `taxonomy` becomes a zero-column matrix; `round()` turns a
  species at 0.4% into 0 and a species at 12.3% into 12; `Cmin` comes out near 100; SRS runs; alpha
  diversity returns a handful of "taxa" per sample; ANCOM-BC2 fits a model to what is effectively
  binary data. Every command completes. The reader has a full figure set built from a table that
  was destroyed at line 126.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — `SOP_READBASED_NeSI.md:548-549` builds `merged_species.tsv` with
  `clade_name` rows and no rank columns; `SOP_R_Analysis.md:117-123` selects taxonomy by the
  literal rank names `species … superkingdom`; `SOP_R_Analysis.md:126` rounds unconditionally.
- **Fix:** Two edits, both required.

  **(a)** Insert immediately before the `read.table` call at `SOP_R_Analysis.md:109`:

  ````markdown
  **What this document requires as input.** Three files, whatever produced them:

  | Input | Required shape |
  | --- | --- |
  | Count table | **Integer read counts.** One row per taxon, one column per sample. Tab-separated, taxonomy in named rank columns (`species`, `genus`, `family`, `order`, `class`, `phylum`, `superkingdom`), sample columns after them. |
  | Taxonomy | Either the rank columns above, in the same file, or a separate table with the same rank names and the same row keys. |
  | Metadata | Tab-separated, one row per sample, sample IDs in the first column matching the count-table column headers exactly, including a `SampleType` column. |

  The loader below reads Emu's combined counts table, which is already in that shape. The other
  two upstream pipelines are not, and each needs one reshaping step first:

  - **CONCOMPRA** produces `otu_table.csv` (comma-separated), taxonomy in a separate four-column
    sintax file and a Newick tree. Reshape it with the block in `SOP_CONCOMPRA_NeSI.md` Section 8
    before starting here.
  - **MetaPhlAn / the read-based SOP** produces relative abundance, not counts, with the lineage
    in a single `clade_name` column. Use the reshaping block in `SOP_READBASED_NeSI.md`
    Section 13, and read that section before this one.

  **If your table holds relative abundance rather than integer counts, do not run the `round()`
  line below, do not run SRS, and do not pass the table to ANCOM-BC2, MaAsLin2 or ALDEx2 as
  written.** Rounding a percentage table produces small whole numbers instead of an error, and
  every step after it will run and be wrong. The guard below stops that:

  ```r
  # Refuse to continue on a table that is not integer counts. A relative-abundance
  # table survives round() as small integers and produces a complete, plausible,
  # entirely wrong set of results.
  colsum <- colSums(counts_raw)
  if (all(abs(colsum - 100) < 1) || all(abs(colsum - 1) < 0.01)) {
      stop("Column sums are 100 or 1: this is a relative-abundance table, not counts. ",
           "See the input table above before going any further.")
  }
  ```
  ````

  **(b)** Replace `SOP_READBASED_NeSI.md:632` with:

  > `SOP_R_Analysis.md` assumes an integer count table with taxonomy in named rank columns.
  > MetaPhlAn produces neither, so **reshape before you open Part 2** — its Stage 1 loader will
  > round your percentages into small integers rather than reject them. Split `clade_name` into
  > the rank columns Part 2 expects, and decide which of the two tables each analysis takes:
  >
  > ```bash
  > python3 - <<'PY'
  > import pandas as pd
  > RANKS = ["superkingdom","phylum","class","order","family","genus","species"]
  > PFX   = ["k__","p__","c__","o__","f__","g__","s__"]
  > for src, out in [("tables/merged_species.tsv",        "tables/part2_relab.tsv"),
  >                  ("tables/merged_species_counts.tsv", "tables/part2_counts.tsv")]:
  >     df = pd.read_csv(src, sep="\t", index_col=0)
  >     tax = pd.DataFrame(
  >         [{r: next((p[3:] for p in str(i).split("|") if p.startswith(x)), "")
  >           for r, x in zip(RANKS, PFX)} for i in df.index], index=df.index)
  >     tax.insert(0, "tax_id", [str(i).split("|")[-1] for i in df.index])
  >     pd.concat([tax, df], axis=1).to_csv(out, sep="\t", index=False)
  >     print(out, pd.concat([tax, df], axis=1).shape)
  > PY
  > ```
  >
  > `part2_counts.tsv` holds model-estimated read counts; round it in R and use it **only** for
  > differential abundance. `part2_relab.tsv` holds relative abundance; use it for beta diversity
  > and for `decontam`, and never pass it through `round()` or SRS. The rest of this section lists
  > what else changes.

### F-02 · S2 · CONCOMPRA's handoff folder cannot be opened by Part 2, which the README says it can
- **Where:** `SOP_CONCOMPRA_NeSI.md:429-486` and `SOP_R_Analysis.md:111-123`; claim at
  `README.md:15`
- **Quote:**
  > | [`SOP_CONCOMPRA_NeSI.md`](SOP_CONCOMPRA_NeSI.md) | … then sintax taxonomy, MAFFT alignment and FastTree phylogeny. Hands off to Part 2. …

  against `SOP_CONCOMPRA_NeSI.md:483-484`:

  > - **Taxonomy.** Parse column 4 of the sintax file. Format is `d:Domain,p:Phylum,c:Class,o:Order,f:Family,g:Genus,s:Species`; ranks below the cutoff are absent.
  > - **Tree.** FastTree output is unrooted. Root it with `phangorn::midpoint()` before passing it to phyloseq.
- **Defect:** Part 2 reads one tab-separated file with rank columns. CONCOMPRA delivers a
  comma-separated OTU table, taxonomy in a separate four-column sintax file using `d:`/`p:` rank
  prefixes, and a Newick tree. Part 2 contains no CSV read, no sintax parser, no tree handling and
  no `phangorn` in its install block — the word "tree" does not appear in it.
- **Failure:** The reader assembles `concompra_for_R/` exactly as instructed, opens Part 2, and the
  first command fails: `read.table(..., sep = "\t")` on a CSV puts the whole line in one field and
  `row.names = 1` errors. If they switch to `read.csv`, `tax_cols` is empty, `taxonomy` becomes a
  zero-column matrix and `tax_table()` fails. There is no instruction anywhere for parsing the
  sintax file into a `tax_table`, and the tree they were told to build has no consumer.
- **Type:** GAP
- **Confidence:** CONFIRMED — `phangorn` appears once in the repository, at
  `SOP_CONCOMPRA_NeSI.md:484`; `SOP_R_Analysis.md` contains no occurrence of "tree", "Newick",
  "phylogen" or `read.csv`.
- **Fix:** Add to `SOP_CONCOMPRA_NeSI.md` Section 8, replacing the four bullets at lines 483-486:

  ````markdown
  Part 2 opens on a tab-separated table with taxonomy in named rank columns. Convert the folder
  once, here, so Part 2's Stage 1 works unchanged:

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

  `counts_concompra.tsv` is now in the shape Part 2's Stage 1 describes: substitute its filename
  for `emu-combined-counts_silva.tsv` there. The rank names are Part 2's (`superkingdom` … not
  `Domain`), which is what its barplot and `tax_level = "genus"` code expects. Keep
  `tree_concompra.rds` — Part 2's phylogenetic-diversity subsection takes it.

  Two things Part 2 does not know about CONCOMPRA output:

  - **Counts are integers already.** Part 2's `round()` step is a no-op here; leave it in.
  - **Prevalence filtering.** Low-prevalence OTUs from per-sample consensus are often genuine rare
    taxa, so the `prv_cut = 0.10` in Part 2's ANCOM-BC2 call, tuned for Illumina ASV data, may
    discard real signal. Report the threshold you used either way.
  ````

  and change `README.md:15` from "Hands off to Part 2." to "Ends by converting its outputs into
  the table and tree Part 2 opens on."

### F-03 · S2 · CONCOMPRA sample IDs carry a suffix Emu's do not, so the two cannot share a metadata sheet
- **Where:** `SOP_EMU_NeSI.md:431` and `:665` against `SOP_CONCOMPRA_NeSI.md:193-205, 471-476`
- **Quote:**
  > chopper \
  >     --input ${fastq} \
  >     …
  >     > filtered/${sample}_filtered.fastq

  and, from Part 1's Emu array job:

  > SAMPLE=$(basename ${FASTQ} _filtered.fastq)

  against CONCOMPRA:

  > for f in ../filtered_dedup/*.fastq; do
  >     ln -s "$(realpath "$f")" .
  > done
- **Defect:** Part 1 strips `_filtered` before naming Emu's outputs, so its count-table columns are
  `barcode01`. CONCOMPRA takes its sample names from the FASTQ filenames it is given, which are
  Part 1's `barcode01_filtered.fastq`, so its OTU-table columns are `barcode01_filtered` once the
  `.CONCOMPRA` suffix is stripped. Nothing in either document reconciles them.
- **Failure:** The reader runs both pipelines on the same run, as `SOP_CONCOMPRA_NeSI.md:48`
  instructs, and builds one metadata sheet. The `diff` check at `SOP_CONCOMPRA_NeSI.md:474-476`
  reports every ID as different; the reader concludes the metadata is wrong and edits it to match
  CONCOMPRA, at which point the Emu tables no longer join. Neither document mentions that the two
  pipelines name samples differently.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED for the `_filtered` suffix — it is written by
  `SOP_EMU_NeSI.md:431` and stripped only inside Part 1's Emu job at line 665.
  `NEEDS-BENCH-CHECK` for the exact CONCOMPRA header form — run one sample and
  `head -1 results/otu_table.csv` to confirm the columns are `<fastq basename>.CONCOMPRA`.
- **Fix:** Add to `SOP_CONCOMPRA_NeSI.md`, immediately after the symlink loop:

  ```bash
  # Strip Part 1's "_filtered" suffix from the link names. CONCOMPRA takes sample
  # IDs from these filenames, and Part 1's Emu step strips the same suffix, so
  # leaving it here gives the two pipelines different IDs for the same sample and
  # neither will join to your metadata sheet.
  for f in *_filtered.fastq; do
      [ -e "$f" ] || continue
      mv "$f" "${f%_filtered.fastq}.fastq"
  done
  ls *.fastq | wc -l   # must equal your sample count
  ```

  and add to `SOP_EMU_NeSI.md` Section 3 Step 3, after the chopper script: "The `_filtered` suffix
  is stripped again before Emu names its outputs, so your count-table columns are `barcode01`, not
  `barcode01_filtered`. If you also run `SOP_CONCOMPRA_NeSI.md` on these files, strip the suffix
  there too — the two pipelines must produce the same sample IDs or they cannot share a metadata
  sheet."

### F-04 · S2 · Three job working-directory models, and one document argues against another's
- **Where:** `SOP_EMU_NeSI.md:324-327`, `SOP_CONCOMPRA_NeSI.md:265-269`,
  `SOP_READBASED_NeSI.md:146, 193`
- **Quote:**
  > #SBATCH --output logs/nanoplot_raw_%j.out
  > #SBATCH --error logs/nanoplot_raw_%j.err
  >
  > cd /nesi/nobackup/<your_nesi_project_code>/

  against `SOP_CONCOMPRA_NeSI.md:269`:

  > The `cd` is a hardcoded absolute path rather than `$SLURM_SUBMIT_DIR`, which would point at the wrong place if you submit from elsewhere or move the script.

  against `SOP_READBASED_NeSI.md:193` and `:146`:

  > cd "${SLURM_SUBMIT_DIR:?}"
  >
  > - **Submit every job from `$WORK`.** All paths in this SOP are relative to it, and `logs/` must exist before your first `sbatch` or Slurm fails without telling you why.
- **Defect:** Three models for one problem: in-script `cd` with relative log paths (Part 1, which
  is broken — `EMU F-07`), hardcoded in-script `cd` (CONCOMPRA), and `$SLURM_SUBMIT_DIR` with a
  submit-from-here rule (read-based). CONCOMPRA states in prose that the read-based model is wrong.
  None of the three fixes the log-path problem, which SLURM resolves before the script runs.
- **Failure:** A reader who has done the amplicon pipeline moves to shotgun, copies the header
  pattern they learned, and submits from their scripts directory on `/nesi/project/`. `logs/` does
  not exist there, the job dies at launch, and the one artefact that would explain why is the log
  that could not be written. `squeue` shows nothing and the reader assumes the job is queued. A
  reader who then reads CONCOMPRA is told the model they were just given is unsafe.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED for the disagreement — the three forms and CONCOMPRA's argument
  against the third are all quoted above. `NEEDS-BENCH-CHECK` for the fix: submit a job with
  `#SBATCH --chdir` pointing at a directory containing `logs/`, from a directory that has none,
  and confirm the log file appears under `--chdir`.
- **Fix:** One model, in all three documents. Add to `SOP_EMU_NeSI.md` Section 1 (the canonical
  header) and mirror the header in the other two:

  ````markdown
  **Always set `--chdir`.** SLURM resolves `--output` and `--error` *before* your script runs,
  relative to wherever you typed `sbatch`. If `logs/` does not exist there, the job dies at launch
  and cannot write a log saying so — you get a job ID and then silence. `--chdir` sets the working
  directory for the whole job, so both the log paths and every relative path inside the script
  resolve against your workspace no matter where the script lives or where you submit from. It
  replaces both an in-script `cd` and any reliance on `$SLURM_SUBMIT_DIR`.

  ```bash
  #!/bin/bash
  #SBATCH --account <your_nesi_project_code>
  #SBATCH --job-name <name>
  #SBATCH --time <hh:mm:ss>
  #SBATCH --mem <total, e.g. 8G>
  #SBATCH --cpus-per-task <n>
  #SBATCH --chdir /nesi/nobackup/<your_nesi_project_code>/<your_project>
  #SBATCH --output logs/%x_%j.out          # %x_%A_%a.out for array jobs
  #SBATCH --error  logs/%x_%j.err

  set -euo pipefail
  mkdir -p logs
  module purge
  ```

  Create `logs/` under the `--chdir` directory once, before your first submission.
  ````

  Delete the in-script `cd` from all four Part 1 scripts, replace CONCOMPRA's hardcoded `cd` and
  its `$SLURM_SUBMIT_DIR` paragraph with a pointer to this header, and replace
  `SOP_READBASED_NeSI.md:193`'s `cd "${SLURM_SUBMIT_DIR:?}"` and the "Submit every job from
  `$WORK`" bullet with `--chdir "$WORK"` written out in full.

### F-05 · S2 · The README routes CONCOMPRA as an alternative to Part 1; CONCOMPRA requires Part 1 and an Emu run
- **Where:** `README.md:15, 26` against `SOP_CONCOMPRA_NeSI.md:41, 48, 114, 327-329`
- **Quote:**
  > | Full-length 16S rRNA amplicons, Oxford Nanopore (27F–1492R) | `SOP_EMU_NeSI.md`, or `SOP_CONCOMPRA_NeSI.md` for consensus OTUs | `SOP_R_Analysis.md` |

  against CONCOMPRA:

  > Use it alongside Emu.
  >
  > Run both on the same deduplicated input and compare.
  >
  > Using Emu's bundle keeps the SILVA release identical to the parallel Emu workflow.
  >
  > For one or two samples, compare the dominant taxa from Emu with the closest matches for the corresponding CONCOMPRA consensus sequences.
- **Defect:** The README presents the two as either/or. CONCOMPRA presents itself as an adjunct: it
  takes Part 1's filtered reads as input, builds its SINTAX database out of Part 1's Emu SILVA
  bundle, and makes an Emu cross-check its only validation step.
- **Failure:** A reader chooses CONCOMPRA off the routing table instead of Part 1, reaches
  `for f in filtered/*.fastq` with no `filtered/` directory and no statement that one was
  expected, reaches Appendix A and is told to `cd <where Emu's species_taxid.fasta lives>` without
  having run Emu, and reaches Section 6's cross-check with nothing to check against. Three dead
  ends, all created by the routing table.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — the four CONCOMPRA statements above all assume an Emu run.
- **Fix:** Replace the routing row at `README.md:26` with:

  > | Full-length 16S rRNA amplicons, Oxford Nanopore (27F–1492R) | `SOP_EMU_NeSI.md` | `SOP_R_Analysis.md` |
  > | The same data, where you also need consensus sequences, a tree, or resolution for taxa the reference databases miss | `SOP_EMU_NeSI.md` first, then `SOP_CONCOMPRA_NeSI.md` | `SOP_R_Analysis.md` |

  and change `README.md:15` from "**Alternative to Part 1, same Nanopore data.**" to
  "**Run after Part 1, on the same Nanopore data.** Reference-free consensus OTUs alongside Emu's
  reference-based assignment. It takes Part 1's filtered reads as input, builds its SILVA SINTAX
  database from Part 1's Emu bundle, and validates against Part 1's taxonomy, so it is an addition
  to Part 1 rather than a replacement for it."

### F-06 · S2 · The log-directory lesson is taught by the two documents that assume it, and missing from the one that teaches the cluster
- **Where:** `SOP_CONCOMPRA_NeSI.md:242` and `SOP_READBASED_NeSI.md:146`, against
  `SOP_EMU_NeSI.md:137-180`
- **Quote:**
  > **Script.** Save as `06_concompra.sh` in the parent of `concompra/`. Slurm resolves the log paths relative to the submission directory before the script runs, so create the log directory first:

  and

  > - **Submit every job from `$WORK`.** All paths in this SOP are relative to it, and `logs/` must exist before your first `sbatch` or Slurm fails without telling you why.
- **Defect:** Part 1 is the only document that teaches SLURM, and its SLURM section says nothing
  about how `--output` paths are resolved. Both documents that declare Part 1 as their prerequisite
  teach the rule themselves — which is the signature of a boundary drawn in the wrong place, and
  it is why all four of Part 1's own scripts are broken in exactly this way (`EMU F-07`).
- **Failure:** The reader learns SLURM from Part 1, follows Part 1's own storage advice at line 46
  and saves the scripts on `/nesi/project/`, submits from there, and every job in Part 1 dies at
  launch with no log. Nothing in Part 1 can explain it. The explanation exists twice in the
  repository, in two documents this reader has not opened.
- **Type:** GAP
- **Confidence:** CONFIRMED — `SOP_EMU_NeSI.md` Section 1 contains no statement about how
  `--output`, `--error` or relative paths are resolved.
- **Fix:** The canonical header block in **F-04**'s fix goes into `SOP_EMU_NeSI.md` Section 1 and
  carries this rule. Then shorten `SOP_CONCOMPRA_NeSI.md:242` to "**Script.** Save as
  `06_concompra.sh` in the parent of `concompra/`." and shorten `SOP_READBASED_NeSI.md:146` to
  "- **`--chdir` and `logs/`.** Every script in this SOP sets `--chdir "$WORK"`; create
  `$WORK/logs` before your first `sbatch` (Part 1, Section 1)." Both keep their triage entries.

### F-07 · S2 · Nothing upstream produces the metadata sheet Part 2 requires, and Part 1 never mentions controls
- **Where:** `SOP_R_Analysis.md:143-160, 196-203` against `SOP_EMU_NeSI.md:926` and
  `SOP_CONCOMPRA_NeSI.md:437`
- **Quote:**
  > Download the counts and abundance files to your computer for the R analysis.

  against Part 2:

  > - **`SampleType`** with values `"sample"` or `"blank"`. The decontam step (Stage 2) uses this to identify your negative controls, and it is far more robust than hardcoding which columns are blanks. Every sample, including blanks, needs a value here.
- **Defect:** Part 1 ends by handing over two count tables and stops. It never records which
  barcode held which biological sample, never produces a metadata file, and — searched for
  "control", "blank" and "negative" — mentions none of them anywhere outside the phrase "quality
  control". CONCOMPRA's handoff folder lists `sample_metadata.csv` as "added manually" with no
  specification. Part 2 cannot run Stage 2 without a `SampleType` column and cannot run at all
  without a metadata file, and controls cannot be added after sequencing.
- **Failure:** The reader sequences 24 biological samples and no blanks, follows Part 1 to a clean
  count table, opens Part 2, and finds a decontamination step they cannot run. They skip it, and
  reagent taxa — *Ralstonia*, *Burkholderia*, *Pseudomonas* — enter the results as biology. A
  second reader, who did sequence blanks, builds the metadata sheet weeks later from a plate map
  read in the wrong orientation; every label is shifted by one, ordination separates the groups
  beautifully, and nothing anywhere can detect it.
- **Type:** GAP
- **Confidence:** CONFIRMED — a case-insensitive search of `SOP_EMU_NeSI.md` for
  control/blank/negative returns only "quality control" (line 291) and one mention of mock
  communities in the Emu benchmarking paragraph (line 533).
- **Fix:** Two additions. In `SOP_EMU_NeSI.md`, at the head of Section 3 (before any command):

  ````markdown
  > **Before you sequence: controls.** This is here rather than in the R analysis because it is
  > the one thing in this pipeline you cannot fix afterwards. `SOP_R_Analysis.md` removes reagent
  > and kit contaminants with `decontam`, which works by comparing your samples against **negative
  > controls** that went through extraction and PCR with no template. Include at least one
  > extraction blank per extraction batch and one no-template PCR control per plate, barcode them
  > like any other sample, and sequence them. They will look nearly empty; that is the point.
  >
  > This matters most for low-biomass material — swabs, water, tissue — where reagent taxa such as
  > *Ralstonia*, *Burkholderia* and *Pseudomonas* can be a large share of the reads. Without blanks
  > you cannot tell those from real community members. A mock community of known composition is
  > worth a barcode too: it is the only check that the whole pipeline, including the database
  > choice in Section 4, recovers the composition it should. `SOP_READBASED_NeSI.md` Section 1 has
  > the fuller treatment of control design, including how many of each type.
  ````

  and, at the end of `SOP_EMU_NeSI.md` Section 4, before the download instruction:

  ````markdown
  ### Record what each barcode was

  Your table's columns are `barcode01`, `barcode02`, … because that is what the FASTQ files were
  called. Nothing downstream can recover which biological sample each barcode held, and a
  mis-numbered mapping produces a clean, significant, entirely wrong result. Write it down now,
  while the run is fresh, as the metadata file `SOP_R_Analysis.md` opens on — tab-separated, one
  row per barcode, sample ID in the first column:

  ```bash
  cat > metadata_file.txt <<'EOF'
  SampleID	Site	Sex	Species	Batch	Plate	SampleType
  barcode01	Takapourewa	Male	Tuatara	B1	plate1	sample
  barcode02	Takapourewa	Female	Tuatara	B1	plate1	sample
  barcode03	NA	NA	NA	B1	plate1	blank
  EOF
  ```

  Four rules that matter later: the `SampleID` column must match the count-table headers exactly
  (`barcode01`, not `Barcode01` or `barcode1`); every barcode you sequenced needs a row, blanks and
  mocks included; `SampleType` must say `blank` for negative controls, because Part 2's
  decontamination selects on exactly that; and `Batch` and `Plate` must be recorded even if you
  think everything was processed together, because Part 2 tests for both and they are much harder
  to reconstruct later.

  ### Hand off to the R analysis

  Download `emu-combined-counts_silva.tsv`, `emu-combined-abundance_silva.tsv` and
  `metadata_file.txt` to your computer — plus the RDP equivalents if you ran both databases — and
  continue in `SOP_R_Analysis.md`.
  ````

  Add the same "record what each barcode was" pointer to `SOP_CONCOMPRA_NeSI.md:437`, replacing
  "Your sample sheet (added manually)" with "Your sample sheet: tab-separated, one header row,
  sample ID in the first column, `SampleType` column marking blanks — see `SOP_EMU_NeSI.md`
  Section 4".

### F-08 · S2 · Cross-document section numbers that do not exist, in both directions
- **Where:** `SOP_EMU_NeSI.md:3, 25-27` and `SOP_R_Analysis.md:5`, against `README.md:53`
- **Quote:**
  > This document covers everything from logging into NeSI through to generating combined count tables with Emu. For the R analysis (Sections 5-7), see `SOP_R_Analysis.md`.

  and

  > This document covers statistical analysis and visualisation in R, starting from the combined count tables produced by Part 1. For the NeSI pipeline (Sections 1-4), see `SOP_NeSI_Pipeline.md`.

  against the README's own rule:

  > - **A bare section number always means the current document.** "Section 9" in one SOP never points at another SOP's Section 9; a cross-document reference always names the file.
- **Defect:** Both pointers state another document's section numbers as if they were their own, and
  one of the two ranges does not exist: `SOP_R_Analysis.md` has Sections 5 and 6 and no Section 7,
  so Part 1's roadmap item 7 ("Writing up your results") names content that exists nowhere in the
  repository. Part 2's own numbering starting at 5 is the root cause — it is a continuation of
  Part 1's, which makes the numbers meaningless for the two other upstream documents that also
  feed it (CONCOMPRA §1–10, read-based §1–14).
- **Failure:** The reader finishes Part 1 Section 4, scrolls for Section 5, hits the end of the
  file, and cannot tell whether the document is truncated. They open Part 2, find a Section 5, and
  reasonably conclude the two documents share one numbering — then look for the Section 7 the
  roadmap promised and find the document ends at "Common Pitfalls". A reader arriving from the
  read-based SOP instead sees Part 2 open at Section 5 with no Sections 1–4 and no explanation.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED — `SOP_R_Analysis.md` has exactly two numbered `##` sections, 5 (line
  59) and 6 (line 810); there is no Section 7 and no Sections 1–4.
- **Fix:** Renumber `SOP_R_Analysis.md` from 1 (Section 5 → Section 1, Section 6 → Section 2; see
  *Convention decisions*), then:

  - Replace `SOP_EMU_NeSI.md:3` with: "This document covers everything from logging into NeSI
    through to generating combined count tables with Emu. The statistics that follow are in
    `SOP_R_Analysis.md`, which numbers its own sections from 1."
  - Replace `SOP_EMU_NeSI.md:19-28` ("Analysis steps") with a four-item list of this document's own
    sections, ending: "The R analysis that follows — phyloseq, decontamination, SRS normalisation,
    diversity, differential abundance and write-up — is in `SOP_R_Analysis.md`."
  - Replace `SOP_R_Analysis.md:5` with: "This document starts from the combined count tables
    produced upstream. For the Nanopore amplicon pipeline see `SOP_EMU_NeSI.md`, or
    `SOP_CONCOMPRA_NeSI.md` for consensus OTUs; for Illumina shotgun see `SOP_READBASED_NeSI.md`,
    whose Section 13 lists what changes here when the input is relative abundance."

### F-09 · S2 · Part 2 and the read-based SOP give opposite PERMANOVA defaults for the same test
- **Where:** `SOP_R_Analysis.md:691` against `SOP_READBASED_NeSI.md:632, 664`
- **Quote:**
  > We use sequential testing here because it gives all terms including the interaction, with cleanly partitioning R² values. Put your primary variable first.

  against, in a document that has just said "Follow `SOP_R_Analysis.md` for the mechanics":

  > adonis2(dist ~ batch + group, data = meta, by = "margin", permutations = 999)
- **Defect:** Two SOPs give opposite defaults for the same argument of the same function, and
  neither acknowledges the other. Part 2 also standardises on 9,999 permutations
  (`SOP_R_Analysis.md:695`); the read-based example uses 999.
- **Failure:** The reader is told to follow Part 2 for the mechanics, then given a code block that
  contradicts it. If they use `by = "margin"`, the R² values no longer partition, and Part 2's
  reporting template — "with site explaining 35-38% of the variation" — is no longer a true
  statement about their output. They have no basis for choosing and no tie-break anywhere.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED — both statements are quoted above and describe the same call.
- **Fix:** Replace the three-line code block at `SOP_READBASED_NeSI.md:663-667` with:

  > ```r
  > # Mechanics, permutation count and the by= choice: SOP_R_Analysis.md, PERMANOVA.
  > # What is specific to read-based data is that batch belongs IN the model.
  > adonis2(d_bray ~ batch + group, data = meta,
  >         permutations = how(nperm = 9999), by = "terms")
  > anova(betadisper(d_bray, meta$group))   # always run this, not only when PERMANOVA is significant
  > ```
  >
  > Model batch rather than pre-testing for it. An unadjusted PERMANOVA on batch alone tells you
  > whether batch associates with community structure, which is not the same as whether it
  > *confounds* your group effect. If you need each term tested as if entered last, `by = "margin"`
  > does that — at the cost of R² values that no longer partition cleanly, so say which you used.

### F-10 · S2 · CONCOMPRA's script numbers continue a series Part 1 never finishes
- **Where:** `SOP_CONCOMPRA_NeSI.md:171-175` against `README.md:51` and `SOP_EMU_NeSI.md:315, 397,
  450, 635`
- **Quote:**
  > ├── 05b_dedup.sh                  # if dedup was needed (Stage 2)
  > ├── 06_concompra.sh               # main run submission (Section 5)
  > ├── 07_concompra_postprocess.sh   # post-processing submission (Section 7)

  against the README:

  > - **The QC and filtering SLURM scripts are numbered in run order** (`01_nanoplot_raw.sh`, `02_chopper_filter.sh`, `03_nanoplot_filtered.sh`) so the directory reads as the pipeline.
- **Defect:** CONCOMPRA's numbering implies an upstream series running to at least 05. Part 1
  defines `01`, `02`, `03` and then two scripts named by function (`emu_array.sh`,
  `emu_array_rdp.sh`). There is no `04` and no `05` anywhere in the repository, and `05b_dedup.sh`
  is a file CONCOMPRA never tells the reader to create — Section 3 gives an interactive loop.
- **Failure:** The reader lists the directory layout, counts back, and concludes they have skipped
  two steps. They search both documents for `04_` and `05_`, find nothing, and either invent
  scripts or stop to work out what they missed.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED — a search of the repository for `04_` and `05_` as script prefixes
  returns nothing outside this layout block.
- **Fix:** Renumber CONCOMPRA's scripts to its own sections — `03_dedup.sh` (Section 3),
  `05_concompra.sh` (Section 5), `07_concompra_postprocess.sh` (Section 7) — update every
  reference, and add one line under the layout: "Script numbers are this document's section
  numbers. They are not a continuation of `SOP_EMU_NeSI.md`'s series, which numbers its scripts in
  run order within that document." Then add the missing `03_dedup.sh` as a script rather than an
  interactive loop, or drop it from the layout.

### F-11 · S3 · README states an audience for CONCOMPRA that CONCOMPRA does not serve
- **Where:** `README.md:5, 20` against `SOP_CONCOMPRA_NeSI.md:1-8`
- **Quote:**
  > The amplicon SOPs assume a student or new lab member with no prior command-line experience and start from `pwd`.

  and

  > **Start with Part 1 if this is your first pipeline.** All four documents explain before they command, but only Part 1 teaches the cluster itself — bash, modules, SLURM, array jobs. The other three assume it. The read-based SOP says so at the top and points back here.
- **Defect:** CONCOMPRA is an amplicon SOP and does not start from `pwd`: it opens at `git clone`,
  and assumes conda environments, channel configuration, `sed -i`, Slurm and `realpath` within its
  first fifty lines. The README says "the other three assume it" and then names only the read-based
  SOP as saying so — which is accurate, and is the problem: CONCOMPRA has no prerequisites block
  at all.
- **Failure:** A reader takes the README at its word, opens CONCOMPRA as their first document, and
  meets `conda env create --solver=libmamba` with no grounding and no pointer to where that
  grounding lives.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — `SOP_CONCOMPRA_NeSI.md` lines 1-8 contain no prerequisites statement
  and no reference to Part 1's Section 1.
- **Fix:** Change `README.md:5` to "The Emu SOP assumes a student or new lab member with no prior
  command-line experience and starts from `pwd`. The other three build on it." and change
  `README.md:20`'s last sentence to "All three say so at the top and point back to Part 1
  Section 1." Then add the prerequisites block from `CONCOMPRA F-04` to CONCOMPRA's front matter,
  so the README's claim becomes true.

### F-12 · S3 · Two SOPs depend on conda; none teaches it
- **Where:** `SOP_CONCOMPRA_NeSI.md:73-110` and `SOP_READBASED_NeSI.md:330-334, 488-499`, against
  `SOP_EMU_NeSI.md:123-136`
- **Quote:**
  > conda env create \
  >     -f CONCOMPRA.yml \
  >     -p /nesi/project/<your_project_code>/conda_envs/CONCOMPRA \
  >     --solver=libmamba
- **Defect:** Part 1's "Using modules" section teaches Lmod modules and nothing else. Both other
  cluster SOPs require conda environments — `conda activate` by path, `PYTHONNOUSERSITE`, channel
  configuration, `mamba create`, `source "$(conda info --base)"/etc/profile.d/conda.sh` — and the
  document they both name as their prerequisite covers none of it.
- **Failure:** The reader has met `module load` and nothing else. The `source "$(conda info
  --base)"...` line is opaque, and when it fails (a common outcome in a non-login shell) they have
  no model of what it was doing and nothing to search.
- **Type:** GAP
- **Confidence:** CONFIRMED — "conda" does not appear in `SOP_EMU_NeSI.md`.
- **Fix:** Add ten lines to `SOP_EMU_NeSI.md` Section 1, after "Using modules": what a conda
  environment is and how it differs from a module; why the lab builds environments under
  `/nesi/project/.../conda_envs/` and activates them by path rather than by name; why
  `source "$(conda info --base)"/etc/profile.d/conda.sh` is needed in a batch job (batch jobs do
  not source `~/.bashrc`, so `conda` is not a function yet); and that `PYTHONNOUSERSITE=1` stops
  packages in `~/.local` leaking in. CONCOMPRA and the read-based SOP then keep their commands and
  drop the incidental explanations.

### F-13 · S3 · Two different NeSI quota commands, one per document
- **Where:** `SOP_EMU_NeSI.md:119` against `SOP_READBASED_NeSI.md:99`
- **Quote:**
  > nn_storage_quota                  # storage usage across all project directories

  against

  > nn_check_quota
- **Defect:** Two names for the same operation, in the document that teaches the cluster and the
  document that assumes it.
- **Failure:** The reader learns `nn_storage_quota`, hits `command not found` when the platform
  changed the name, and has no way to know that the repository already contains the other spelling
  in a document they may not have opened.
- **Type:** CONSISTENCY
- **Confidence:** `NEEDS-BENCH-CHECK` — run `nn_storage_quota` and `nn_check_quota` on Mahuika and
  record which exists; NeSI's 2025 platform refresh renamed several `nn_*` helpers.
- **Fix:** Use the surviving name in both places, and add to Part 1: "The `nn_*` helpers are
  NeSI-specific and have been renamed across platform refreshes. If one is not found, `module
  spider` will not help — check NeSI's current documentation."

### F-14 · S3 · Array indices are 0-based in the teaching document and 1-based in the one that depends on it
- **Where:** `SOP_EMU_NeSI.md:644, 658` against `SOP_READBASED_NeSI.md:189, 196`
- **Quote:**
  > #SBATCH --array=0-23                  # CHANGE to match your sample count (0 to N-1)
  > …
  > FASTQ=$(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" ${MANIFEST})

  against

  > #SBATCH --array=1-1                      # array jobs only - placeholder, see below
  > …
  > SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" samples.txt)
- **Defect:** Each document is internally consistent, but a reader who learned arrays from Part 1
  meets the opposite convention in the document that says Part 1's Section 1 is its prerequisite,
  including the `+ 1` that exists only to reconcile 0-based indices with 1-based line numbers.
- **Failure:** The reader adapts Part 1's pattern into a read-based script, keeps the `+ 1` with a
  1-based array, and task 1 processes sample 2 while the last sample is never processed and the
  array reports success.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED — both forms are quoted above.
- **Fix:** Standardise on 1-based (`--array=1-N`, `sed -n "${SLURM_ARRAY_TASK_ID}p"`), which
  removes the arithmetic entirely. Update Part 1's Emu array script and its "How the array job
  works" paragraph, and adopt the read-based SOP's practice of setting the real range at
  submission — `sbatch --array=1-$(wc -l < emu_manifest.txt)%20` — in both documents.

### F-15 · S3 · `nobackup` retention stated three ways, vaguest in the onboarding document
- **Where:** `SOP_EMU_NeSI.md:47`, `SOP_CONCOMPRA_NeSI.md:124`, `SOP_READBASED_NeSI.md:113`,
  `README.md:42`
- **Quote:**
  > Not backed up, and files may be purged on a rolling basis. Do not store irreplaceable data here.

  against

  > **`nobackup` deletes files that have not been accessed or modified for 90 days**, flagging them at day 76 in `nn_doomed_list`. Check that list if a project goes quiet for a few months.
- **Defect:** The document responsible for teaching the filesystems gives the least actionable
  version of the rule; the specific figure and the `nn_doomed_list` mechanism appear only in the
  document that assumes the reader already knows this.
- **Failure:** A student returns to their raw FASTQs six months later to answer a reviewer and
  finds them gone. "May be purged on a rolling basis" gave them no reason to copy anything, and no
  date to plan around.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED — all four statements are quoted or cited above.
- **Fix:** Use the read-based SOP's wording in Part 1 verbatim, including `nn_doomed_list`, and
  shorten CONCOMPRA's line to "…not a copy under `nobackup`, which deletes untouched files after
  90 days (Part 1, Section 1)."

### F-16 · S3 · The README's tool table omits tools two SOPs actually require
- **Where:** `README.md:69` against `SOP_CONCOMPRA_NeSI.md:152, 456` and `SOP_READBASED_NeSI.md:92`
- **Quote:**
  > **Consensus OTUs (CONCOMPRA):** the pipeline itself runs from a conda environment built via `Miniforge3/25.3.1-0`; post-processing uses `VSEARCH/2.21.1-GCC-11.3.0`, `MAFFT/7.505-gimkl-2022a-with-extensions`, `FastTree/2.1.11-GCC-11.3.0` and `seqtk/1.4-GCC-11.3.0`.
- **Defect:** CONCOMPRA also requires `seqkit` (line 152, deduplication) and Python with Biopython
  (line 456, the R-prep block); neither is in the README's list, neither is loaded anywhere in
  CONCOMPRA, and `seqtk` — which is listed — has no `rmdup` subcommand, so a reader who substitutes
  it stalls. The read-based preflight also spiders `Bowtie2`, which the README's shotgun table
  omits.
- **Failure:** The reader checks the README's tool list before starting, sees five tools, and
  reaches line 152 with `seqkit: command not found` and no idea whether the command or the list is
  wrong.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED — `seqkit` appears once in the repository (CONCOMPRA:152) and in no
  tool list; `from Bio import SeqIO` appears at CONCOMPRA:456.
- **Fix:** Adopt the module-free `awk` deduplication and `awk` OTU-table filter from
  `CONCOMPRA F-05` and `CONCOMPRA F-11`, which removes both dependencies, and leave the README's
  list as it stands. If the lab prefers `seqkit`, add it to the README's list, add a `module load`
  to CONCOMPRA, and confirm the module exists. Add `Bowtie2` to the shotgun table with the note
  that Hostile supplies its own.

### F-17 · S3 · The README credits the SOPs with a citation none of them contains
- **Where:** `README.md:100` against `SOP_READBASED_NeSI.md` (whole file) and
  `SOP_CONCOMPRA_NeSI.md:587-601`
- **Quote:**
  > The SOPs give primary references where the choice of tool or method needs justifying (Emu: Curry et al. 2022, *Nature Methods*; chopper: De Coster & Rademakers 2023, *Bioinformatics*; SILVA: Quast et al. 2013, *Nucleic Acids Research*; the rarefaction debate: Schloss 2024, *mSphere*; DA method comparison: Nearing et al. 2022, *Nature Communications*, and Yang & Chen 2022, *Microbiome*; MetaPhlAn 4: Blanco-Míguez et al. 2023, *Nature Biotechnology*; re-identification from residual human reads: Tomofuji et al. 2023, *Nature Microbiology*).
- **Defect:** The read-based SOP contains no MetaPhlAn citation — searching it for "Blanco" or
  "Nature Biotechnology" returns nothing — so the README points a reader at a reference the SOPs do
  not carry. In the other direction, the README's list omits every citation in CONCOMPRA's
  Appendix B (Stock 2025 for CONCOMPRA itself, Edgar 2016 for SINTAX, Katoh 2013 for MAFFT, Price
  2010 for FastTree) and Dufrêne & Legendre 1997 from Part 2's indicator-species section.
- **Failure:** A student writing a methods section takes the README's list as the repository's
  bibliography, cites Blanco-Míguez without ever seeing it justified in the SOP, and omits the
  CONCOMPRA paper for a pipeline they actually ran.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED — no MetaPhlAn citation exists in `SOP_READBASED_NeSI.md`; CONCOMPRA's
  five references are at lines 589-599 and none appears in the README.
- **Fix:** Add "MetaPhlAn 4 profiles reads against clade-specific marker genes (Blanco-Míguez et
  al. 2023, *Nature Biotechnology*)." to `SOP_READBASED_NeSI.md:446`, and extend the README's list
  with CONCOMPRA (Stock et al. 2025), SINTAX (Edgar 2016), MAFFT (Katoh & Standley 2013), FastTree
  (Price et al. 2010) and indicator species (Dufrêne & Legendre 1997).

### F-18 · S3 · Three rank-name vocabularies across the three upstream paths
- **Where:** `SOP_EMU_NeSI.md:797`, `SOP_CONCOMPRA_NeSI.md:483`, `SOP_READBASED_NeSI.md:549`,
  consumed at `SOP_R_Analysis.md:117-118`
- **Quote:**
  > RANKS = ["superkingdom", "phylum", "class", "order", "family", "genus", "species"]

  against CONCOMPRA:

  > Format is `d:Domain,p:Phylum,c:Class,o:Order,f:Family,g:Genus,s:Species`; ranks below the cutoff are absent.

  against the read-based SOP:

  > grep -E "s__" tables/merged_taxonomy_allranks.tsv | grep -v "t__" >> tables/merged_species.tsv
- **Defect:** Three vocabularies for one concept — Emu's lowercase rank words, SINTAX's
  single-letter prefixes with `d:` for domain, and MetaPhlAn's `k__`/`s__` prefixes with `t__` for
  strain. Part 2 selects taxonomy columns by exact match on the Emu set and warns at line 116 that
  case differences will error.
- **Failure:** A reader converting CONCOMPRA or MetaPhlAn output names the top rank `Domain` or
  `Kingdom`; Part 2's `tax_cols` selection silently drops that column, `tax_glom(taxrank =
  "genus")` fails or aggregates the wrong rank, and the barplot's `fill = phylum` finds nothing.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED — the three forms are quoted above and Part 2's selector is at lines
  117-123.
- **Fix:** Declare Emu's seven lowercase names the repository vocabulary (see *Convention
  decisions*) and require every conversion block to emit them. The conversion code in **F-01(b)**
  and **F-02** already does; state the rule once in the README and once in Part 2's input table.

### F-19 · S3 · The duplicate-read hazard is documented only in the document that survives it
- **Where:** `SOP_CONCOMPRA_NeSI.md:130, 48` against `SOP_EMU_NeSI.md` (whole file)
- **Quote:**
  > A Nanopore run that was interrupted and restarted can have its POD5 files merged such that reads are basecalled twice, producing FASTQs with duplicated read IDs. Emu tolerates this silently, but CONCOMPRA's `filtlong 0.2.1` aborts on duplicate read names…

  and

  > Run both on the same deduplicated input and compare.
- **Defect:** "Emu tolerates this silently" is a silent-failure warning about Part 1, recorded only
  in a document Part 1's readers have no reason to open. Emu tolerating duplicates means the counts
  it estimates are inflated — for a 50% file-level duplication, roughly doubled — which propagates
  into depth, normalisation and every count-based test. Separately, CONCOMPRA instructs the reader
  to run both pipelines on the same deduplicated input, which is impossible as written because
  Part 1 has no deduplication step.
- **Failure:** A reader with a restarted run follows Part 1 end to end. Nothing errors, every
  barcode's read count is roughly doubled, `Cmin` is computed from inflated depths, and the
  duplicated reads are counted twice in every abundance estimate. If they later run CONCOMPRA on
  deduplicated input as instructed, the two pipelines' results are not comparable and neither
  document says why.
- **Type:** GAP
- **Confidence:** CONFIRMED — "duplicate" does not appear in `SOP_EMU_NeSI.md`.
- **Fix:** Add to `SOP_EMU_NeSI.md` Section 3 Step 1, after the import loop: "**If your run was
  interrupted and restarted**, the POD5 files may have been merged such that reads were basecalled
  twice, giving FASTQs with duplicated read IDs. Emu does not complain — it simply counts every
  duplicated read twice, inflating depth and every abundance estimate. Screen for it before
  filtering: the check and the fix are in `SOP_CONCOMPRA_NeSI.md` Section 3, and the screen is
  cheap enough to run on every new dataset. If you deduplicate, do it before this step so that both
  pipelines use the same input."

### F-20 · S3 · The README's script/section/roadmap alignment claim does not hold in the document it names
- **Where:** `README.md:53` against `SOP_READBASED_NeSI.md:17-38, 210, 218`
- **Quote:**
  > In the read-based SOP the numbered sections, the script filenames and the roadmap stages are deliberately aligned, so `scripts/09.metaphlan.sl` belongs to Section 9.
- **Defect:** Two of the SOP's ten scripts — `qc_fastqc.sl` and `qc_multiqc.sl`, both Section 5 —
  carry no number, and the roadmap's seven stages are not section numbers at all: Stage 3 covers
  Sections 5-7, Stage 5 covers Sections 9-10. The README asserts a three-way alignment where a
  two-way one holds with two exceptions.
- **Failure:** The reader lists `scripts/` expecting the pipeline in order and finds two files that
  sort to the end and belong at the start; a reader looking for "Stage 5" in the section headings
  finds no such heading.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED — the roadmap block at lines 17-38 numbers seven stages against
  fourteen sections; the two script names are at lines 210 and 218.
- **Fix:** Rename to `scripts/05.qc_fastqc.sl` and `scripts/05b.qc_multiqc.sl` throughout
  (`READBASED F-18` lists every occurrence), and change `README.md:53`'s second sentence to: "In
  the read-based SOP the script filenames carry the number of the section that defines them, so
  `scripts/09.metaphlan.sl` belongs to Section 9. The roadmap stages group sections; they are not
  section numbers."

### F-21 · S3 · Part 2 recommends ALDEx2 as a tie-breaker; the read-based SOP says it is the wrong tool for that job
- **Where:** `SOP_R_Analysis.md:936-938` against `SOP_READBASED_NeSI.md:682`
- **Quote:**
  > If you want a third method, ALDEx2 follows the same pattern: use `ps_raw` (it applies CLR internally via Monte Carlo sampling from a Dirichlet posterior). It is a useful tie-breaker when ANCOM-BC2 and MaAsLin2 disagree. The consensus across all three is the most defensible result to report.

  against

  > Read ALDEx2 at small N as a defensible *conservative* choice — few false positives, low power — rather than as the reliable one.
- **Defect:** A low-power method breaks ties in one direction only: it will side with whichever
  method found nothing. Part 2 recommends exactly that use; the read-based SOP warns against
  reading ALDEx2's conservatism as reliability, and cites Yang & Chen 2022 for it — a citation Part
  2 does not carry, though the README credits the repository with it.
- **Failure:** ANCOM-BC2 and MaAsLin2 disagree on a taxon at n = 12. The reader runs ALDEx2, which
  finds nothing at that sample size, and records the taxon as not differentially abundant — a
  decision driven by the tie-breaker's power, not by the evidence.
- **Type:** CHALLENGE
- **Confidence:** CONFIRMED for the disagreement; the statistical reading is the lab's to accept
  or reject.
- **Fix:** Replace the last two sentences of `SOP_R_Analysis.md:938` with: "It is a conservative
  method — few false positives, low power — so treat a null result from it as weak evidence rather
  than as a casting vote. Where ANCOM-BC2 and MaAsLin2 disagree, report the disagreement and put
  the union in supplementary material (Nearing et al. 2022, *Nat Commun*; Yang & Chen 2022,
  *Microbiome* 10:130)." Raise with the lab before applying — see *Open questions*.

### F-22 · S4 · Omnibus: register and shape drift across the set
- **Where:** eleven locations, listed below
- **Quote:**
  > *Taylor Lab | Full-Length 16S rRNA Nanopore SOP*

  (`SOP_R_Analysis.md:1` — a Nanopore banner on the document the README calls platform-agnostic)
- **Defect:** Eleven small inconsistencies that make the set read as four documents.
- **Failure:** Each costs a reader a few seconds of doubt about whether two things are the same
  thing; together they undo the trust the prose earns.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED — each is checkable at the line given.
- **Fix:** Apply in place.
  1. **`SOP_EMU_NeSI.md:1` and `:5`** — two `#`-level titles. Merge into one.
  2. **`SOP_R_Analysis.md:1`** — Nanopore banner on a platform-agnostic document. Change to
     `*Taylor Lab | Microbial community analysis in R*`.
  3. **SLURM capitalisation** — `SOP_CONCOMPRA_NeSI.md` uses `Slurm` four times and `SLURM` once;
     `SOP_READBASED_NeSI.md` mixes 13 and 3. Use `SLURM` throughout, as Part 1 and the README do.
  4. **SBATCH option syntax** — `SOP_CONCOMPRA_NeSI.md` uses `--flag=value` throughout,
     `SOP_EMU_NeSI.md` mixes both within one header (lines 639-646). Use the space-separated form
     everywhere, matching the canonical header in **F-04**.
  5. **Shebang and error handling** — `#!/bin/bash -e` (Part 1, CONCOMPRA §5) against
     `#!/bin/bash` + `set -euo pipefail` (CONCOMPRA §7, read-based). Use the second form
     everywhere.
  6. **Roadmap block** — three documents open with an ASCII roadmap; `SOP_EMU_NeSI.md` has a bare
     numbered list headed "Analysis steps". Give it the same block.
  7. **Date and version labels** — `SOP_EMU_NeSI.md:7` "Last updated: May 2026";
     `SOP_READBASED_NeSI.md:5` "v3.0" with no date; CONCOMPRA and Part 2 have neither; `README.md:108`
     "July 2026". Give every document one line: `**vN.N** | last updated <Month Year>`.
  8. **`<your_email>@auckland.ac.nz`** (`SOP_EMU_NeSI.md:173`) — the README defines `<your_email>`
     as the whole address, so substituting as documented doubles the domain. Use `<your_email>`
     alone.
  9. **US spelling** — "capitalizations" at `SOP_EMU_NeSI.md:129` in an otherwise UK-spelled set.
  10. **`/tmp` scratch files** (`SOP_CONCOMPRA_NeSI.md:474-476`) — fixed filenames on a shared login
      node collide between users. Write into the current directory and delete after the `diff`.
  11. **Heading style** — three documents bold their headings (`## **1. Overview**`),
      `SOP_EMU_NeSI.md` does not. Pick one; bold matches three of four.

---

## Reference integrity table

| Source | Line | Points at | Exists? | Correct? | Action |
| --- | --- | --- | --- | --- | --- |
| README | 13-16 | The four SOP files, as links | Yes | Yes | — |
| README | 5 | "amplicon SOPs … start from `pwd`" → EMU + CONCOMPRA | Yes | **No** — CONCOMPRA does not | F-11 |
| README | 18 | Part 1 § "Full-length vs short-read: why it matters" → `SOP_EMU_NeSI.md:275` | Yes | Yes | — |
| README | 18, 28 | read-based SOP Section 13 → `SOP_READBASED_NeSI.md:630` | Yes | Yes | — |
| README | 20 | "The other three assume it … says so at the top" | Partly | **No** — CONCOMPRA says nothing | F-11 |
| README | 26 | CONCOMPRA as an alternative to EMU | Yes | **No** — CONCOMPRA requires EMU | F-05 |
| README | 30 | Genomics Aotearoa summer school (external URL) | Unverified | — | `NEEDS-BENCH-CHECK` — fetch the URL |
| README | 36 | "Section 1 of the read-based SOP" → `SOP_READBASED_NeSI.md:44` | Yes | Yes | — |
| README | 42 | "Part 1 explains the three NeSI filesystems" → `SOP_EMU_NeSI.md:43-49` | Yes | Yes | — |
| README | 44 | "install block is at the top of Part 2" → `SOP_R_Analysis.md:65` | Yes | Yes | — |
| README | 46 | "end of Part 1 Section 1" → `SOP_EMU_NeSI.md:185-194` | Yes | Yes | — |
| README | 52 | Part 2's "Key objects" table → `SOP_R_Analysis.md:38` | Yes | Partly — `ps_relab`/`ps_estcounts` are not in it | Add both rows to Part 2 |
| README | 53 | "`scripts/09.metaphlan.sl` belongs to Section 9" | Yes | Partly — two scripts unnumbered, stages ≠ sections | F-20 |
| README | 85 | "Part 1 explains why we use the validated v138.1" → `SOP_EMU_NeSI.md:565` | Yes | Yes | — |
| README | 100 | "MetaPhlAn 4: Blanco-Míguez et al. 2023" as given by the SOPs | **No** | **No** | F-17 |
| README | 102 | "read-based SOP's Section 14" → `SOP_READBASED_NeSI.md:694` | Yes | Yes | — |
| EMU | 3 | `SOP_R_Analysis.md` "Sections 5-7" | File yes; §5, §6 yes; **§7 no** | **No** | F-08 |
| EMU | 25-27 | Roadmap items 5-7 under this document's numbering | §7 nowhere | **No** | F-08 |
| EMU | 189-192 | Four Genomics Aotearoa URLs | Unverified | — | `NEEDS-BENCH-CHECK` — fetch all four |
| EMU | 375, 381, 511, 517 | GitHub user-attachment image URLs | Unverified | — | Render only on GitHub; see *Deferred* |
| EMU | 531, 557 | Emu GitHub, arb-silva.de | Unverified | — | `NEEDS-BENCH-CHECK` — fetch |
| CONCOMPRA | 5 | `SOP_NeSI_Pipeline.md` | **No** | **No** | `CONCOMPRA F-03` — retarget to `SOP_EMU_NeSI.md` |
| CONCOMPRA | 5, 30, 481 | `SOP_R_Analysis.md` | Yes | **No** — Part 2 cannot open its output | F-02 |
| CONCOMPRA | 33, 494-500 | In-document anchors (`#6-verifying-the-run`, `#screen`, …) | Yes | Yes — GitHub slugs resolve through the bold markers | — |
| CONCOMPRA | 589-601 | Five external references and two URLs | Unverified | — | `NEEDS-BENCH-CHECK` — resolve DOIs |
| READBASED | 7 | `SOP_R_Analysis.md` + "Section 13 below" | Yes | **No** — handoff broken | F-01 |
| READBASED | 9 | Genomics Aotearoa URL | Unverified | — | `NEEDS-BENCH-CHECK` |
| READBASED | 11 | `SOP_EMU_NeSI.md` Section 1 for bash, modules, `sbatch`, arrays | Yes | Yes — all four are covered | — |
| READBASED | 624 | `SOP_R_Analysis.md` decontam, prevalence method | Yes | Partly — Part 2's decontam sits after `round()` | F-01 |
| READBASED | 632, 688 | `SOP_R_Analysis.md` | Yes | **No** — see F-01, F-09 | F-01, F-09 |
| READBASED | 634 | "Part 2 covers no phylogenetic diversity at all" | — | **Yes, true** | Resolve by adding it to Part 2 |
| READBASED | 644 | "Part 2 does the same to Emu's EM estimates" (rounding) | — | **Yes, true** — `SOP_R_Analysis.md:126` | — |
| READBASED | 645 | `ps_relab` / `ps_estcounts` | **No** — not defined in Part 2 | **No** | Add both to Part 2's Key objects table |
| READBASED | 163, 319 | S3 download URL, two benchmark papers | Unverified | — | `NEEDS-BENCH-CHECK` |
| R_Analysis | 5 | `SOP_NeSI_Pipeline.md` "Sections 1-4" | **No** | **No** | F-08 (known calibration defect) |
| R_Analysis | 109 | "(from `combine_emu_results.py`)" → `SOP_EMU_NeSI.md:772` | Yes | Yes | — |
| R_Analysis | 111 | `emu-combined-counts_silva.tsv` → `SOP_EMU_NeSI.md:911` | Yes | Yes | — |
| R_Analysis | 117-118 | Rank column names → `SOP_EMU_NeSI.md:797, 860` | Yes | Yes — exact match, lowercase | — |
| R_Analysis | 808 | "Comparing SILVA and RDP results" → `SOP_EMU_NeSI.md:574` | Yes | Partly — no procedure at either end | `R F-23` + `EMU` gap; Part 2 owns |

---

## Consistency matrix

The **Target** column is the decision, not a description of the variance.

| Item | EMU | CONCOMPRA | READBASED | R_Analysis | README | Target |
| --- | --- | --- | --- | --- | --- | --- |
| Project-code placeholder | `<your_nesi_project_code>` | `<your_project_code>` | `<your_nesi_project_code>` | — | `<your_nesi_project_code>` | `<your_nesi_project_code>` |
| Workspace placeholder | `<your_project>` | `<your_run_name>` | `$WORK` (shell var) | — | `<your_project>` | `<your_project>` everywhere; `<your_run_name>` retired |
| Username placeholder | `<username>` | — | — | — | not listed | `<username>`, added to README |
| Email placeholder | `<your_email>@auckland.ac.nz` | — | — | — | `<your_email>` | `<your_email>` (whole address) |
| Sample placeholder | `<sample>` | — | `<sample>` | — | not listed | `<sample>`, added to README |
| Local path placeholder | angle brackets | angle brackets | angle brackets | `~/path/to/your/files` | angle brackets | angle brackets everywhere |
| Job working directory | in-script `cd`, logs relative | hardcoded `cd`, argues against `$SLURM_SUBMIT_DIR` | `cd "$SLURM_SUBMIT_DIR"` + submit-from-`$WORK` | n/a | silent | `#SBATCH --chdir <abs path>`, no in-script `cd` (F-04) |
| `logs/` creation | not stated | stated | stated | n/a | silent | Stated once in EMU §1; others link |
| SBATCH option syntax | mixed space and `=` | all `=` | space (except `--array=`) | n/a | — | Space-separated |
| Shebang / errexit | `#!/bin/bash -e` | both forms | `#!/bin/bash` + `set -euo pipefail` | n/a | — | `#!/bin/bash` + `set -euo pipefail` |
| Array index base | 0-based + `+1` | n/a | 1-based | n/a | — | 1-based |
| Array size set | hardcoded in header | n/a | at submission, `%N` throttled | n/a | — | At submission, throttled |
| Script numbering | `01`-`03` run order + named array jobs | `05b`/`06`/`07`, phantom `04`/`05` | section numbers, two exceptions | n/a | run order (EMU), aligned (READBASED) | Section number of the document that defines the script |
| SLURM capitalisation | `SLURM` ×25 | `Slurm` ×4, `SLURM` ×1 | `SLURM` ×13, `Slurm` ×3 | — | `SLURM` | `SLURM` |
| Section numbering base | 1 | 1 | 1 | **5** | — | 1, in every document |
| `#`-level titles | **two** | one | one | one | one | One |
| Roadmap block | numbered list | ASCII block | ASCII block | ASCII block | n/a | ASCII block |
| Heading style | plain | bold | bold | bold | plain | Bold in the SOPs |
| Resource table | inline per script | inline per section | Appendix C | none | n/a | Appendix table per SOP |
| Triage section | none | §9 Troubleshooting | Appendix B | none | n/a | One per SOP |
| Provenance block | none | scattered | §14 | `sessionInfo()` | n/a | One per SOP, READBASED §14 as model |
| `nobackup` retention | "rolling basis" | "rolling basis" | 90 days + `nn_doomed_list` | n/a | 90 days | 90 days + `nn_doomed_list` |
| Quota command | `nn_storage_quota` | none | `nn_check_quota` | n/a | none | Whichever exists (F-13) |
| Rank vocabulary | `superkingdom … species` | `d:`/`p:`/…/`s:` | `k__`/…/`t__` | `superkingdom … species` | n/a | `superkingdom, phylum, class, order, family, genus, species` |
| Sample-ID form | `barcode01` | `barcode01_filtered.CONCOMPRA` | from `samples.txt`, three merge rules | must match metadata rows | n/a | One ID per sample, set upstream, unsuffixed |
| Count-table format | TSV, taxa rows, rank columns | CSV, taxa rows, no rank columns | TSV, `clade_name` lineage, relab | TSV, taxa rows, rank columns | n/a | TSV, taxa rows, rank columns, integer counts |
| phyloseq object names | n/a | n/a | names `ps_relab`, `ps_estcounts` | defines `ps_raw`, `ps_srs` only | lists all four | All four defined in Part 2 |
| Controls / blanks | **absent** | one passing mention | §1, full treatment | required by Stage 2 | §36 mentions | READBASED §1 owns; EMU and CONCOMPRA carry a callout |
| decontam | not mentioned | not mentioned | §12 points to Part 2 | owns it | mentioned | Part 2 owns |
| PERMANOVA `by=` | n/a | n/a | `by = "margin"`, 999 perms | `by = "terms"`, 9,999 perms | n/a | `by = "terms"`, 9,999 (F-09) |
| ALDEx2 framing | n/a | n/a | conservative, not reliable | "useful tie-breaker" | n/a | Conservative; not a casting vote (F-21) |
| Date / version | "May 2026" | none | "v3.0" | none | "July 2026" | `**vN.N** \| last updated <Month Year>` |
| Spelling | UK, one US slip | UK | UK | UK | UK | UK |

---

## Ownership map

| Topic | Owner | Who links | What each must change |
| --- | --- | --- | --- |
| Bash, modules, SLURM, array jobs, filesystems | `SOP_EMU_NeSI.md` §1 | CONCOMPRA, READBASED | EMU: add the canonical job header with `--chdir` and the log-path rule (F-04, F-06), the conda primer (F-12), the 90-day retention figure (F-15), 1-based arrays (F-14). CONCOMPRA: add the prerequisites block naming EMU §1. READBASED: keep its one-line pointer; delete its local restatements of the log rule. |
| Getting data onto NeSI | `SOP_EMU_NeSI.md` §3 (new) | CONCOMPRA, READBASED | EMU: add `rsync`/Globus block (`EMU F-05`). READBASED: one-line pointer in §3.1. |
| Storage layout and quotas | `SOP_EMU_NeSI.md` §1 | README, READBASED | README: keep the two-sentence summary. READBASED: keep only the read-based size table (25-30/20-25/40 GB), drop the general filesystem explanation. |
| Study design: controls, replication, depth budget | `SOP_READBASED_NeSI.md` §1 | EMU, CONCOMPRA, R_Analysis | READBASED: fix the depth formula (`READBASED F-01`), add the 1:4 reasoning (`READBASED F-15`). EMU and CONCOMPRA: add the controls callout in F-07 pointing here. Part 2: keep the metadata-columns block. |
| Duplicate-read screening for Nanopore | `SOP_CONCOMPRA_NeSI.md` §3 | EMU | CONCOMPRA: fix the screen key (`CONCOMPRA F-01`). EMU: add the pointer in F-19. |
| Emu SILVA/RDP database setup | `SOP_EMU_NeSI.md` §4 | CONCOMPRA Appendix A | EMU: add the extraction check (`EMU F-09`). CONCOMPRA: replace `<where Emu's species_taxid.fasta lives>` with the path EMU establishes. |
| Consensus OTUs, sintax, MAFFT, FastTree | `SOP_CONCOMPRA_NeSI.md` | — | Owns them outright; no duplication anywhere. |
| MetaPhlAn / HUMAnN and functional tables | `SOP_READBASED_NeSI.md` §§9-11, 13 | R_Analysis | READBASED: split the regrouped tables (`READBASED F-02`). Part 2: keep the one sentence saying functional tables are not covered here and naming where they are. |
| Normalisation theory (rarefaction, SRS, CLR, TSS, CSS) | `SOP_R_Analysis.md` | READBASED §13 | Part 2: keep all four paragraphs. READBASED: reduce its SRS row to the delta and stop routing estimated counts into alpha diversity (`READBASED F-03`). |
| decontam | `SOP_R_Analysis.md` Stage 2 | READBASED §12, EMU, CONCOMPRA | Part 2: add the threshold and its reasoning (`R F-17`). READBASED: keep its one-line pointer. |
| PERMANOVA, betadisper, ordination | `SOP_R_Analysis.md` | READBASED §13 | Part 2: keep the full treatment. READBASED: reduce to the read-based delta and adopt Part 2's `by=` and permutation count (F-09). |
| DA method choice and benchmarking | `SOP_R_Analysis.md` §6 | READBASED §13 | Part 2: absorb Yang & Chen 2022 and the ALDEx2 framing (F-21). READBASED: keep only "which methods accept relative abundance" and link. |
| Phylogenetic diversity (UniFrac, Faith's PD) | `SOP_R_Analysis.md` (new subsection) | CONCOMPRA §8, READBASED §13 | Part 2: add ~20 lines — `phangorn` in the install block, `midpoint()` rooting, `UniFrac()` on a tree-bearing phyloseq object. CONCOMPRA: hand over `tree_concompra.rds` (F-02). READBASED: replace its UniFrac row with a pointer plus the SGB-table command (`READBASED F-12`). |
| SILVA vs RDP comparison | `SOP_R_Analysis.md` | EMU §4 | Part 2: add the procedure (`R F-23`). EMU: keep "run both and compare" and point forward. |
| Provenance and methods checklist | `SOP_READBASED_NeSI.md` §14 (model) | all | EMU, CONCOMPRA: add a short document-specific version. Part 2: keep `sessionInfo()`, add the model formulas and thresholds to record. |
| Repository conventions | `README.md` | all | Adopt the *Convention decisions* block below verbatim. |

---

## Work plan

Sequenced so shared conventions land before the rewrites that depend on them, and so no two items
collide in the same lines of the same file. **‖** marks items that can run in parallel with the
rest of their block.

| # | Item | Files | Closes | Size | Depends on |
| --- | --- | --- | --- | --- | --- |
| 1 | Adopt the convention block; fix the two dead `SOP_NeSI_Pipeline.md` pointers and the routing table | README, CONCOMPRA:5, R_Analysis:5 | F-05, F-11, F-17, F-20, `CONCOMPRA F-03`, calibration defect | S | — |
| 2 ‖ | **Read-based depth formula.** One paragraph, irreversible defect, no dependencies — start it on day one | READBASED:69 | `READBASED F-01` | S | — |
| 3 | Placeholder and naming sweep: `<your_project_code>` → `<your_nesi_project_code>`, `<your_run_name>` → `<your_project>`, README placeholder list | CONCOMPRA (global), README:50 | `CONCOMPRA F-13`, matrix rows 1-6 | S | 1 |
| 4 | **Part 2 input contract.** New front-matter block, the three input shapes, the integer-count guard | R_Analysis:98-141 | **F-01**, `R F-09` | L | 1 |
| 5 | **Part 2 sample identity.** Stage 1 alignment guard, Stage 4 depth gate that rebuilds both objects, grouping vectors from `sample_data()` | R_Analysis:140, 379-390, 958 | `R F-01`, `R F-02` | L | 4 (same lines) |
| 6 ‖ | Part 2 statistics corrections | R_Analysis:404-448, 723-738, 854-872, 905, 969-976 | `R F-03`-`F-07`, `F-12` | L | 5; three bench checks first |
| 7 ‖ | Part 2 scope and method contradictions; add the phylogenetic-diversity subsection | R_Analysis:1, 61, 287-316, 336, 530, 762, 936-938 + new | `R F-10`, `F-11`, `F-13`, F-21, ownership row | M | 4 |
| 8 | **Part 1 workspace path, `--chdir`, array submission.** One commit — everything else in Part 1 assumes it | EMU:51-55, 297-300, 318-330, 400-420, 452-475, 627-700 | `EMU F-01`, `F-07`, `F-10`, `F-11`, F-04, F-06, F-14 | L | 1 |
| 9 | Part 1 data handling: transfer, import loop, controls callout, duplicate-read pointer | EMU:293-310 + new | `EMU F-02`, `F-05`, `F-17`, `F-22`, F-19, half of F-07 | L | 8 |
| 10 ‖ | Part 1 counting and QC interpretation | EMU:433-436, 342-348, 444, 479-524 | `EMU F-03`, `F-06`, `F-18`, `F-19`, `F-27` | M | 8 |
| 11 ‖ | Part 1 database hardening and Emu smoke test | EMU:576-619, 683-720 | `EMU F-08`, `F-09`, `F-16`, `F-26`, `F-36` | M | 8; three bench checks first |
| 12 | Part 1 combiner rewrite and metadata handoff | EMU:726-927 | `EMU F-04`, `F-12`, `F-13`, `F-14`, `F-15`, `F-25`, rest of F-07 | L | 4, 8 |
| 13 ‖ | **Read-based §11 validation block** — split the regrouped tables, header by name, one sample-name convention | READBASED:539-617 | `READBASED F-02`, `F-10`, `F-11` | M | 2 |
| 14 | Read-based §13 rewrite: the reshaping block, the SRS row, UniFrac, PERMANOVA alignment | READBASED:630-692 | `READBASED F-03`, `F-12`, F-01(b), F-09 | M | 4, 13 |
| 15 ‖ | Read-based remainder: Option B, `$DB`, gates, HUMAnN, provenance, checks, omnibus | READBASED:56-78, 132-137, 161-166, 210-304, 355-386, 430-443, 484-529, 694-805 | `READBASED F-04`-`F-09`, `F-13`-`F-26` | L | 2 |
| 16 | CONCOMPRA prerequisites, §3 and §4 executable, input directory named once | CONCOMPRA:1-8, 128-197 | `CONCOMPRA F-01`, `F-04`, `F-05`, `F-06`, F-03, F-11, F-12 | L | 3, 8 (EMU's `filtered/` naming) |
| 17 ‖ | CONCOMPRA §6 verification rebuilt on `otu_table.csv`; §5 keeps `temporary/` | CONCOMPRA:230-330, 532-541 | `CONCOMPRA F-02`, `F-08`, `F-16` | M | 16 |
| 18 ‖ | CONCOMPRA post-processing repairs | CONCOMPRA:222-226, 333-421 | `CONCOMPRA F-07`, `F-09`, `F-10`, `F-17`, `F-19`, `F-20`, `F-21` | M | 16; two bench checks first |
| 19 | CONCOMPRA → R handoff conversion block | CONCOMPRA:425-486 | **F-02**, `CONCOMPRA F-11`, `F-22`, `F-23`, `F-36` | M | 4, 7, 17 |
| 20 ‖ | CONCOMPRA Appendix A made self-contained | CONCOMPRA:545-583 | `CONCOMPRA F-12` | M | Lab decision on the canonical reformatter |
| 21 | Script renumbering across CONCOMPRA and READBASED | CONCOMPRA layout + refs, READBASED:210, 218, 735-743, 791-792 | F-10, F-20, `READBASED F-18`, `CONCOMPRA F-15` | S | 16, 15 |
| 22 | README rewrite to match: routing, CONCOMPRA description, tool lists, citations, conventions | README | F-05, F-11, F-16, F-17, F-20 | M | all |
| 23 | Final consistency sweep: SLURM capitalisation, headers, titles, dates, spelling, `/tmp` | all five | **F-22** | M | all |

**Bench checks to clear before items 6, 11, 13, 18.** Run them in one session and record the
answers in the repository: `--chdir` log-path behaviour (F-04); `nn_storage_quota` vs
`nn_check_quota` (F-13); CONCOMPRA's `otu_table.csv` header form (F-03); `emu abundance --help`
for `--type lr:hq` (`EMU F-16`); `tar -tf silva.tar` structure (`EMU F-09`); `pip install
osfclient` under the Emu module (`EMU F-08`); `args(pairwiseAdonis::pairwise.adonis2)` (`R F-04`);
`symnum()` argument length (`R F-12`); `?adonis2` default for `by` (`R F-21`);
`args(SRS::SRS.shiny.app)` (`R F-31`); `ancombc2` runtime (`R F-24`); FastTree `-boot` semantics
(`CONCOMPRA F-10`); `CONCOMPRA.yml`'s minimap2 pin (`CONCOMPRA F-24`); MetaPhlAn merged-table
first line (`READBASED F-11`); pandas in the MetaPhlAn module (`READBASED F-22`); MetaPhlAn
bowtie2out overwrite (`READBASED F-24`).

### Audit of proposed cuts

Ten removals were proposed across the four reports. **One was struck; two were amended; seven
stand.** A count this low says the straightforwardness instruction did not run hot, and the next
pass does not need a firmer guardrail.

- **Struck → REWRITE TIGHTER: `CONCOMPRA F-28`** (delete the Section 1 prose sentence as a
  duplicate of the table beside it). The sentence carries two things the table does not — "novel or
  **poorly-resolved** taxa" and "primer-mismatch checks" — which are scope statements about when
  CONCOMPRA is the right tool. Replace with one clause instead of cutting: "Use it alongside Emu on
  the same input, where you need sequences rather than assignments — novel or poorly-resolved taxa,
  trees, primer-mismatch checks — and compare."
- **Amended: `READBASED F-26.12`** (cut the closing paragraph as a restatement of §2). The
  replacement sentence must keep the phrase "including capitalisation", which is a silent-failure
  warning about module strings, not a restatement: "Run § 2 before anything else, not after a
  failed array — every module string in this document will drift, capitalisation included."
- **Amended: `READBASED F-26.9`** (drop `outs=` or explain it). Resolve to *keep with the reason*
  rather than drop: an optional flag with a stated consequence is worth four words; a silently
  removed one is a question the next reader asks again.
- **Stand:** `EMU F-20` (roadmap items describing another document, replaced by a pointer);
  `EMU F-28` (duplicate `nn_seff` gloss); `EMU F-32` (third restatement of the `--keep-counts`
  warning — audited specifically, and allowed only because the strongest instance at line 708
  survives verbatim at the point of use); `CONCOMPRA F-30` (second full copy of the medaka note,
  keeping the searchable one in §9); `CONCOMPRA F-37` (pointer to an unlocatable script, which the
  README's own contributing rule forbids); `R F-26` (`mia` install and the bare
  `library(microbiome)`, neither used anywhere).

---

## Convention decisions

Paste into the README's "Conventions used in these SOPs" section, replacing the current list.

- **Angle brackets are placeholders.** The full set: `<your_nesi_project_code>` (allocation code,
  e.g. `uoa03068`), `<your_project>` (your working directory under it), `<username>`,
  `<your_email>` (the whole address, domain included), `<sample>`, `<job_id>`. Nothing works if you
  paste them literally. Shell variables (`$WORK`, `$DB`) may be used in interactive blocks but
  never inside a SLURM script — a batch job does not inherit your login shell.
- **Every document numbers its own sections from 1**, and a bare section number always means the
  current document. A cross-document reference names the file and, if it needs a section, names the
  section under that file's own numbering. Before committing, check that the file exists and that
  the section number is still right.
- **One `#`-level title per document**, followed by a one-line scope statement, a prerequisites
  line, and an ASCII roadmap block.
- **Script filenames carry the number of the section that defines them** — `05_concompra.sh` for
  Section 5, `09.metaphlan.sl` for Section 9. Numbers do not run across documents. Where a document
  has several scripts in one section, suffix them (`07a`, `07b`).
- **One SLURM job header, in Part 1 Section 1.** Space-separated options, `#!/bin/bash` plus
  `set -euo pipefail`, `#SBATCH --chdir <absolute workspace path>`, log paths relative to it, and
  `mkdir -p logs` before the first submission. Arrays are 1-based and their real range is set at
  submission (`sbatch --array=1-N%20`), never in the header.
- **Taxonomic ranks have one vocabulary**: `superkingdom, phylum, class, order, family, genus,
  species`, lowercase. Any pipeline whose output uses different names (`d:`/`k__`/`Domain`) is
  converted to these before it reaches Part 2.
- **One sample ID per sample, set upstream and never suffixed.** The ID in the count-table header,
  the metadata file's first column and every other pipeline's output for the same sample must be
  byte-identical. Strip tool-added suffixes (`_filtered`, `.CONCOMPRA`, `_Abundance-RPKs`) where
  they are created, not in R.
- **Part 2's input contract**: a tab-separated table of **integer counts**, taxa in rows, rank
  columns before sample columns; plus a tab-separated metadata file with sample IDs in the first
  column and a `SampleType` column. Any upstream document that produces something else owns the
  conversion.
- **phyloseq objects carry a suffix naming what they hold.** `ps_raw` raw counts, `ps_srs`
  SRS-normalised, `ps_relab` relative abundance, `ps_estcounts` model-estimated counts. All four
  are defined in Part 2's "Key objects" table. Mixing them produces plausible wrong answers with no
  error message.
- **Write down the reasoning, not just the value.** If you document a threshold, a parameter or a
  tool choice, record why. Most of the useful content in these SOPs is in the "why this number"
  paragraphs, and a rewrite that removes one has made the document worse.
- **UK spelling. `SLURM` in capitals. Bold section headings.** Each document carries
  `**vN.N** | last updated <Month Year>` under its title.

---

## Consolidated keep list

The regression test for the rewrite. If any of this is lost, the rewrite failed. Merged across the
four reports and this one; every entry survived the load-bearing audit.

**`SOP_EMU_NeSI.md`**

1. `:391-395` — the three chopper threshold justifications, including why 1,200 bp and not 1,500
   (16S gene length varies 1,400-1,540 bp across species). Not a table of values.
2. `:718` — the `--min-pid` scale warning: "Do not write `0.9` expecting 90%; Emu reads that as
   0.9% identity, which filters nothing." Verbatim.
3. `:720` — `--max-align-len` silently caps alignment length; "raise it or reads are discarded
   without warning". Looks irrelevant to this workflow, which is why it will be cut.
4. `:708` — `--keep-counts` is essential; "Forget this and you re-run Emu from scratch." Keep in
   full even while deleting the restatement at `:764`.
5. `:63` — "**Do not run `rm -r ~/proj`**, which follows the link and recursively deletes the
   target."
6. `:41` — the Jupyter two-pane gotcha.
7. `:724` — why Emu counts are fractional, and the rounding decision Part 2 depends on.
8. `:565` — the SILVA v138.1 vs 138.2 note and both OSF project IDs.
9. `:353-369`, `:487-503` — the two real NanoStats blocks. Fix the ranges they contradict; do not
   replace them with idealised numbers.
10. `:537-547` — the EM explanation and the "community context" paragraph.
11. `:275-288` — "Full-length vs short-read: why it matters", which the README points readers to
    by name.

**`SOP_CONCOMPRA_NeSI.md`**

12. `:33` — "`main.sh` logs 'consensus sequences generated' for every sample even when a step
    failed silently". Belongs in the roadmap.
13. `:75` — the `defaults`-channel and Miniforge-not-Miniconda paragraph.
14. `:98` / `:502-504` — medaka, racon and samtools deliberately absent. De-duplication keeps one
    full copy, not two compressed ones.
15. `:130` — "`filtlong 0.2.1` aborts on duplicate read names, and the run then fails silently".
16. `:147` — POD5 read IDs are globally-unique UUIDs, so name-based deduplication is lossless.
17. `:201` — relative paths in `directory_list.txt` break silently; use absolute paths.
18. `:211` — the primer-orientation paragraph, including the sense-strand 1492R sequence and "the
    wrong orientation gives almost no primer hits and an empty downstream funnel".
19. `:283` — "`main.sh` has no `set -e`, so a failure in an inner step … does not stop the script
    or change its exit code."
20. `:409` — take column 4, not column 2, of the sintax output; column 2 "silently corrupts
    taxonomy at low-confidence ranks". Plus the 0.8 cutoff rationale.
21. `:124` — point at the project-directory UDB, not a `nobackup` copy.

**`SOP_READBASED_NeSI.md`**

22. `:200` — "forget it and the job runs successfully on sample 1 only, with no error to alert
    you."
23. `:229` — MultiQC without `--dependency` "runs immediately, reports on however few samples
    happen to have finished, and exits 0".
24. `:251` — the two-pass explanation: `ktrim=r` applies to every sequence in `ref=`.
25. `:273` — "`trimq=10`, not 20", with the GC-extreme and low-coverage reasoning.
26. `:317` — the T2T rationale: unmapped human reads "misalign to microbial references and appear
    as species that were never in your sample".
27. `:321-324` — why the reference must be masked.
28. `:411-412`, `:512-513`, `:140` — the three comments explaining why a defensive line exists
    (zcat under pipefail, the `trap` under `set -e`, CRLF in the manifest). Deleting the comment
    invites deleting the line.
29. `:545-547` — "a column sums to roughly 8x the classified fraction - not 100%. Never hand the
    all-ranks table to anything that expects a species table."
30. `:476` — MetaPhlAn counts are model-estimated, "do not use them for alpha diversity".
31. `:50-52` — the governance paragraph and the Tomofuji 93.3% re-identification figure.
32. `:680` — "An empty profile, or one where a single taxon sits above 99%, is a failed sample
    rather than a finding."
33. `:9`, `:34` (README) — the scope limits: human-associated only, no novel genomes, no assembly.
34. `:468-471` — why `--index` and `--offline` are not optional.
35. `:486` — why the `Humann/3.0.0.alpha.3` module must not be used.
36. `:605` — `--file_name` is a substring match, so joined tables never go back into `humann/`.

**`SOP_R_Analysis.md`**

37. `:55` and `:1005` — the `ps_raw`/`ps_srs` rule, stated twice deliberately. Both copies stay.
38. `:331-336` — the McMurdie & Holmes / Schloss rarefaction reasoning and the
    rarefying-vs-rarefaction distinction.
39. `:818-820` — the 1,000-cells worked example of compositionality, with its concrete numbers.
40. `:496` — why `robust.aitchison` rather than `aitchison`.
41. `:362` — "Feeding pre-normalised data to ANCOM-BC2, MaAsLin2, or ALDEx2 produces incorrect
    results." Keep the bolding.
42. `:593` — "will fail silently if you ever drop or reorder samples between the two."
43. `:882` — "Trust results only where both `diff_` and `passed_ss_` are TRUE."
44. `:145-149` — the three housekeeping metadata columns (`SampleType`, `Batch`, `Plate`).
45. `:1013` — "Choosing rarefaction depth after seeing results … is p-hacking."
46. `:999-1027` — the Common Pitfalls list entire, including pseudoreplication, Simpson's paradox,
    the ecological fallacy and the species-level over-claiming warning.

**`README.md`**

47. `:36` — the two things to settle before generating shotgun data.
48. `:83` — why HUMAnN is deliberately not taken from a module.
49. `:96` — "If you are documenting a threshold or a tool choice, write down the reasoning, not
    just the value."
50. `:104` — the note that no licence has been added and what that means.

---

## Deferred

- **Renaming `SOP_R_Analysis.md` to match the declared `SOP_<Topic>_<Environment>.md` pattern.**
  It is the one file that inverts the pattern (environment first). Renaming breaks every link in
  the repository and any external citation for no reader benefit; state the exception in the
  README instead.
- **The GitHub user-attachment image URLs in Part 1.** They render only on GitHub, which is where
  these documents live. Re-hosting them in the repository would be tidier and is not worth the
  churn now.
- **A separate bibliography file.** The README's citation list plus CONCOMPRA's Appendix B is
  enough at five documents. Revisit if a sixth SOP arrives.
- **Interpretation guidance for CONCOMPRA's `cluster_plots.pdf`.** Two sentences of value against
  the cost of characterising good and bad clustering plots properly.
- **A short-read amplicon (DADA2) SOP.** The README already names the gap at line 27 and routes
  readers out of the repository. Out of scope for this rewrite.
- **A "typical runtime" column on every resource table.** Worth having, but it needs a full cohort
  run on current hardware; add opportunistically as bench checks are done.

---

## Open questions for the lab

1. **Is CONCOMPRA an alternative to Part 1 or an addition to it?** F-05 shows the README says one
   thing and the document assumes the other. *Options:* (a) reposition CONCOMPRA as a step that
   runs after Part 1 — matches what the document already does, costs one README row; (b) make
   CONCOMPRA genuinely standalone — requires it to own read filtering, database setup and an
   independent validation step, roughly 100 lines. **Recommend (a).**
2. **Should Part 2 renumber its sections from 1?** F-08 fixes two dead pointers and makes the
   numbering meaningful for all three upstream paths, but any methods section or lab note that
   cites "Section 5 of the R SOP" goes stale. **Recommend renumbering**, with a one-line note in
   the README recording the change.
3. **Who owns phylogenetic diversity?** CONCOMPRA builds a tree, the read-based SOP says Part 2
   covers no phylogenetic diversity, and Part 2 has no tree code. *Options:* (a) Part 2 gains a
   ~20-line subsection and both upstream documents hand it a rooted tree; (b) the tree stays
   decorative and CONCOMPRA drops its FastTree step. **Recommend (a)** — the tree is one of
   CONCOMPRA's two reasons to exist.
4. **`FastTree` support values** (`CONCOMPRA F-10`): if `-boot N` only changes the resample count
   of the SH-like test, the current sentence invites a wrong methods statement. Settle it with one
   `FastTree` usage dump and fix the wording either way.
5. **Masking the alignment before FastTree** (`CONCOMPRA F-18`, raised as a CHALLENGE): unmasked
   terminal gap runs can make UniFrac partly measure consensus length. *Options:* (a) add
   `trimal -gt 0.5` between MAFFT and FastTree; (b) state that masking is deliberately omitted and
   show the length-uniformity check that justifies it. Either is defensible; **record the decision
   either way.**
6. **"No canonical SINTAX-formatted SILVA exists"** (`CONCOMPRA F-31`, CHALLENGE): the claim is
   contestable and the real justification — matching the Emu SILVA release exactly — is stronger.
   **Recommend leading with the version-matching reason** regardless of how the factual question
   resolves.
7. **ALDEx2's role** (F-21): Part 2 calls it a tie-breaker; the read-based SOP calls it
   conservative and low-powered. These cannot both stand. **Recommend the read-based framing**, and
   that Part 2 report disagreement between methods rather than resolve it with a third.
8. **`neg_lb` in ANCOM-BC2** (`R F-05`): the reviewer's reasoning is sound for the worked example's
   sample size, but if the lab routinely runs ≥30 per group the default may be deliberate. Confirm
   before flipping it, and record which way and why.
9. **Are controls mandatory on the amplicon path?** The read-based SOP makes them mandatory for
   low-biomass sample types; Part 1 does not mention them. **Recommend adopting the read-based
   rule repository-wide**, since Part 2's decontamination step is not optional either.
10. **A `LICENSE` file** (`README.md:104`): no reuse rights are currently granted. CC BY 4.0 for
    the protocols and MIT for the scripts is the usual pairing. Lab decision, not a rewrite item.

---

## Self-check

- [x] Ledger accounts for every heading in the file — *(Agent A only; not applicable to this
      report)*
- [x] Every finding has a line-anchored verbatim quote
- [x] Every finding has a concrete Failure line
- [x] Every S1 and S2 has paste-ready replacement text — F-01 and F-02 supply full blocks; F-03
      through F-10 supply the exact replacement text for both ends of each seam
- [x] Every `NEEDS-BENCH-CHECK` names the one check that settles it — F-03 (CONCOMPRA's
      `otu_table.csv` header), F-04 (`--chdir` log-path behaviour), F-13 (`nn_storage_quota` vs
      `nn_check_quota`), plus every inherited check listed under the Work plan
- [x] No proposed cut touches load-bearing content — ten inherited proposals audited: one struck
      and downgraded to REWRITE TIGHTER, two amended, seven stand; this report proposes no cuts of
      its own
- [x] S4 count ≤ 15 — one omnibus entry (F-22) covering eleven items
- [x] Sections match the required skeleton exactly, in order

CONTRACT: PASS
