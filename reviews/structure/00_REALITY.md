# Stage 0 — Reality check

Run 2026-08-03 on NeSI (Mahuika), Lmod 8.7.65, from
`/nesi/project/uoa03769/taylor-lab-sops`.

**The single fact most likely to surprise someone who trusted these documents:**
nothing the SOPs name is a dead reference. Despite the docs warning repeatedly
that "every module string will drift," **not one of the 14 pinned module strings
has drifted** — all resolve verbatim on Mahuika today — and the two MetaPhlAn
helper scripts the READBASED doc calls (`merge_metaphlan_tables.py`,
`calculate_diversity.R`) ship inside the loaded module. The only named thing a
reader cannot get is the "newer BBMap (39.09 / 39.10)" that `SOP_READBASED_NeSI.md`
twice nudges you to prefer if `module spider` offers one: **39.01 is the newest
BBMap on the cluster, so there is nothing newer to switch to.** Separately, the R
package list is genuinely unverifiable from this session — Part 2 is documented to
run on the reader's own machine, not NeSI, so no NeSI check can speak to it.

---

## What I loaded to run these checks

- `module` is a shell function (Lmod 8.7.65). In a bare login shell **R, Rscript
  and conda are not on `PATH`** (`command -v R Rscript conda` → empty), exactly as
  the reader would find.
- Modules resolved against a full terse spider dump: `module -t spider` (7040
  lines) grepped for each exact string.
- MetaPhlAn utilities checked by actually loading the module:
  `module load MetaPhlAn/4.1.0-gimkl-2022a-Python-3.10.5` (exit 0; `module list`
  shows it as #60), then `command -v` and `find` over its install tree.
- Caveat learned mid-run: `module load … | grep …` runs the load in a pipe
  subshell and does **not** mutate the parent shell — an unpiped `module load`
  is required, or tools appear falsely "not found."

## Modules

Claim = the pinned string in the docs. Command = `grep -qxF "<string>"` against
`module -t spider`. All 14 matched exactly.

| Module string (as written in docs) | Verdict |
| --- | --- |
| `BBMap/39.01-GCC-11.3.0` | EXISTS (exact) |
| `chopper/0.12.0b-GCC-12.3.0` | EXISTS (exact) |
| `Emu/3.6.2` | EXISTS (exact) |
| `fastp/0.23.4-GCC-11.3.0` | EXISTS (exact) |
| `FastQC/0.12.1` | EXISTS (exact) |
| `FastTree/2.1.11-GCC-11.3.0` | EXISTS (exact) |
| `MAFFT/7.505-gimkl-2022a-with-extensions` | EXISTS (exact) |
| `MetaPhlAn/4.1.0-gimkl-2022a-Python-3.10.5` | EXISTS (exact; loads, exit 0) |
| `Miniforge3/25.3.1-0` | EXISTS (exact) |
| `MultiQC/1.24.1-foss-2023a-Python-3.11.6` | EXISTS (exact) |
| `NanoPlot/1.43.0-foss-2023a-Python-3.11.6` | EXISTS (exact) |
| `SeqKit/2.4.0` | EXISTS (exact; casing `SeqKit` correct) |
| `seqtk/1.4-GCC-11.3.0` | EXISTS (exact; casing `seqtk` correct) |
| `VSEARCH/2.21.1-GCC-11.3.0` | EXISTS (exact) |

Docs-referenced but not pinned, checked for consistency:

- `Humann/3.0.0.alpha.3` — **EXISTS.** `SOP_READBASED_NeSI.md:516` tells the
  reader **not** to use it; the warning targets a real module (also present:
  `Humann/4.0.0.alpha.1-final`). Good.
- `Emu` — docs say "compatible with v3.4.0+" and pin 3.6.2. Cluster carries
  `Emu/3.5.0` and `Emu/3.6.2`. EXISTS; claim holds.
- `some_tool/version` (`SOP_EMU_NeSI.md:159`) — literal teaching placeholder in
  the "how to load a module" example, not a real claim. N/A.

## Tools and flags

| Named thing | Command run | Actual output | Verdict |
| --- | --- | --- | --- |
| `merge_metaphlan_tables.py` (READBASED §11) | `command -v` after loading MetaPhlAn | `/opt/nesi/CS400_centos7_bdw/MetaPhlAn/4.1.0-gimkl-2022a-Python-3.10.5/bin/merge_metaphlan_tables.py` | EXISTS (ships with module) |
| `metaphlan` | `command -v metaphlan` | `…/MetaPhlAn/4.1.0-…/bin/metaphlan` | EXISTS |
| `calculate_diversity.R` (READBASED §12, `metaphlan/utils/…`) | `find` in module tree | `…/site-packages/metaphlan/utils/calculate_diversity.R` | EXISTS (ships with module) |
| conda envs `hostile`, `humann`, CONCOMPRA env | — | Built by the reader per docs (`conda env create` / `conda create`) | UNCHECKABLE — these are install steps, not pre-existing; correctly so |
| CONCOMPRA `main.sh`, `consensus_generation.sh`, `primer-chop` | — | From the cloned CONCOMPRA GitHub repo the docs tell you to clone | UNCHECKABLE without the clone |

## R packages

**All UNCHECKABLE from this session, and that is correct, not a gap.** Part 2 is
documented to run locally: `SOP_R_Analysis.md` header ("runs locally in R, not on
NeSI") and `README.md:39` ("R on your own machine. Part 2 runs locally, not on
NeSI"). No NeSI check can confirm the reader's laptop. Per the brief I did **not**
load a NeSI R module and present its libraries as satisfying the reader.

The install block (`SOP_R_Analysis.md:69-85`) is self-bootstrapping — it installs
`BiocManager` and `devtools` before using them — and every name is a real,
well-known CRAN / Bioconductor / GitHub package. Full set named across the doc:

- CRAN via `install.packages`: `tidyverse, vegan, ggpubr, EnvStats, SRS, ape,
  permute, phangorn, indicspecies, lme4, lmerTest, emmeans, broom, broom.mixed`.
- Bioconductor via `BiocManager::install`: `phyloseq, decontam, ANCOMBC, Maaslin2,
  microbiome`.
- GitHub via `devtools::install_github` (the only ones not on CRAN/Bioc):
  `microbiomeutilities` (microsud), `pairwiseAdonis` (pmartinezarbizu — its
  `install_github` line is commented out at lines 82 and 844).

`grep '^\s*[a-z]+::[A-Za-z_.]+\(' *.md` returned only `devtools::install_github(`;
package use is via `library(...)`, extracted separately.

## Files the documents reference

| File | Nature | Verdict |
| --- | --- | --- |
| `reformat_silva_for_sintax.py` | Committed to the repo; CONCOMPRA §… links it repo-relative and `ls` confirms it (4991 bytes) | EXISTS (repo file) |
| `combine_emu_results.py` | Authored **inline** in `SOP_EMU_NeSI.md:775` ("Save this as…") with full script | EXISTS (self-contained in doc) |
| Job scripts: `emu_array.sh`, `01_nanoplot_raw.sh`, `02_chopper_filter.sh`, `03_dedup.sh`, `05_concompra.sh`, `07_concompra_postprocess.sh`, `host_filter.sl`, `host_index.sl`, `host_hostile.sl`, `humann.sl`, `metaphlan.sl`, `qc_fastqc.sl`, `qc_multiqc.sl`, `read_counts.sl`, `trim.sl` | Authored inline as copy-and-submit code blocks in the SOPs (numbered `NN.name.sl`) | EXISTS (self-contained) — completeness/headers are a §11 structure concern, out of scope here |
| `.tsv/.csv/.fa/.nwk` data: `counts.tsv`, `abundance.tsv`, `emu-combined-counts_<db>.tsv`, `merged_taxonomy_allranks.tsv`, `otu_table.csv`, `otu_tree.nwk`, `silva_sintax.fa`, `primer_set.fa`, etc. | Pipeline **outputs/inputs the reader generates**, not references to shipped files | N/A — produced by the workflow |
| Teaching placeholders: `file.txt`, `file1.txt`, `file2.txt`, `myfile.txt`, `myjob.sh`, `name.sl`, `test.fa`, `0.fa`, `result.txt`, `directory_list.txt`, `metadata_file.txt`, `read.csv`, `samples.txt` | Illustrative names in the shell-basics teaching (EMU) | N/A — pedagogical examples |

## Absent or drifted

- **DRIFTED / stale advice — BBMap "newer version."** `SOP_READBASED_NeSI.md:303`
  ("prefer a newer BBMap if `module spider BBMap` offers one", naming 39.09 /
  39.10). Actual `grep '^BBMap/'` output: `38.73, 38.81, 38.90, 38.95, 39.01` —
  **39.01 is the newest; no 39.09/39.10 exists.** A reader following the advice
  finds nothing newer to switch to. The doc hedges ("if offered"), so this is
  soft, but it is the one place a trusting reader hits a wall.
- **ABSENT: nothing.** No pinned module string, tool, or referenced repo file
  was missing or version-drifted.
- **UNCHECKABLE (not defects):** all R packages (Part 2 is local by design);
  reader-built conda envs and the cloned CONCOMPRA sub-scripts (`main.sh`,
  `consensus_generation.sh`, `primer-chop`) — these are steps the reader performs,
  not pre-existing artefacts.
