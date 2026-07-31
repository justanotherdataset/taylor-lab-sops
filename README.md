# Taylor Lab Bioinformatic SOPs

Standard operating procedures for microbial community analysis on [NeSI](https://www.nesi.org.nz/) (New Zealand eScience Infrastructure) and in R, for people running their first analysis. Each SOP is a complete walkthrough, not a reference card: it explains what a step does and why, gives the exact commands or code, and shows what correct output looks like. Part 1 (Emu) assumes no command-line experience and starts from `pwd`; the others build on it.

## What's here

One upstream document per data type, plus one shared downstream document for the statistics.

| File | Covers |
| --- | --- |
| [`SOP_EMU_NeSI.md`](SOP_EMU_NeSI.md) | **Part 1 — sequencing → count tables.** Nanopore full-length 16S: NeSI onboarding (bash, modules, SLURM), read QC, filtering, Emu profiling against SILVA and RDP, combined count tables. The only document that teaches the cluster itself. |
| [`SOP_R_Analysis.md`](SOP_R_Analysis.md) | **Part 2 — count tables → results.** phyloseq, decontam, SRS normalisation, alpha/beta diversity, PERMANOVA, differential abundance (ANCOM-BC2 and MaAsLin2, ALDEx2 noted), indicator species, common pitfalls. Platform-agnostic; runs locally in R. |
| [`SOP_CONCOMPRA_NeSI.md`](SOP_CONCOMPRA_NeSI.md) | **Runs after Part 1, same Nanopore data.** Reference-free consensus OTUs alongside Emu's assignments: install, dedup, run configuration, submission, verification, then SINTAX taxonomy, MAFFT alignment, FastTree phylogeny. Takes Part 1's filtered reads as input and hands off to Part 2. |
| [`SOP_READBASED_NeSI.md`](SOP_READBASED_NeSI.md) | **Illumina shotgun, read-based.** Governance and controls, trimming and PhiX removal, host depletion against T2T-CHM13, depth gates, taxonomy (MetaPhlAn 4), function (HUMAnN), contamination screening, and what changes in Part 2 for compositional input. Assumes one prior pipeline; does not re-teach bash or SLURM. |

**Part 2 is platform-agnostic** — one R document, not one per platform. Once you have a count table, a taxonomy table and a metadata file, the R workflow is identical whether the reads were profiled with Emu, CONCOMPRA or MetaPhlAn; only the interpretation differs (Part 1 covers this under "Full-length vs short-read"; the read-based SOP's Section 13 lists what changes when the input is relative abundance rather than counts).

**Start with Part 1 if this is your first pipeline** — it is the only document that teaches the cluster (bash, modules, SLURM, array jobs). The two cluster documents downstream of it (CONCOMPRA, read-based) say so at the top and point back to Part 1 Section 1; Part 2 runs locally and legitimately does not.

## Which SOP do I need?

| Your data | Upstream (cluster) | Downstream (R) |
| --- | --- | --- |
| Full-length 16S rRNA amplicons, Oxford Nanopore (27F–1492R) | `SOP_EMU_NeSI.md` | `SOP_R_Analysis.md` |
| The same data, where you also need consensus sequences, a tree, or resolution for taxa the reference databases miss | `SOP_EMU_NeSI.md` first, then `SOP_CONCOMPRA_NeSI.md` | `SOP_R_Analysis.md` |
| Short-read 16S amplicons, Illumina (V3–V4, 341F–785R) | Not yet covered — you need a DADA2 or similar ASV workflow | `SOP_R_Analysis.md` applies once you have a count table |
| Shotgun metagenomes, read-based profiling, human-associated samples | `SOP_READBASED_NeSI.md` | `SOP_R_Analysis.md`, with the deltas in that SOP's Section 13 |
| Shotgun metagenomes, read-based profiling, animal or environmental samples | Not covered — MetaPhlAn's marker genes are built for human-associated taxa | — |
| Shotgun metagenomes, assembly and binning into MAGs | Not covered — see the [Genomics Aotearoa Metagenomics Summer School](https://genomicsaotearoa.github.io/metagenomics_summer_school/) | — |

**Amplicon** means you PCR-amplified one gene (16S) and sequenced only that; **shotgun** means you sequenced all DNA without targeting a gene. **Read-based** profiles reads directly against reference databases with no assembly step — faster and works on lower-coverage data, but it finds only organisms and genes already in the databases and recovers no novel genomes (for those, you want assembly and binning).

**Settle two things before you generate shotgun data**, because neither can be fixed afterwards: whether your ethics approval covers host-depleted human sequence (depletion reduces identifiability but does not remove it), and whether you have enough negative and positive controls to run contamination screening. Both are Section 1 of the read-based SOP — read it before sequencing, not after.

## Before you start

- **A NeSI account and project code.** Apply through your institution; you need the allocation code (e.g. `uoa03068`) for every SLURM script. The SOPs write it as `<your_nesi_project_code>` — replace it throughout.
- **Storage.** Reference databases belong on `/nesi/nobackup/`; scripts and final tables on the backed-up `/nesi/project/` (Part 1 explains the three NeSI filesystems). Get this right on day one. The amplicon databases are a few GB, but the read-based set (MetaPhlAn index, masked human reference, HUMAnN's ChocoPhlAn and UniRef90) runs to ~85–95 GB and will not fit a default 100 GB `project` quota alongside anything else. `nobackup` deletes files untouched for 90 days.
- **R on your own machine.** Part 2 runs locally, not on NeSI. Install a current release of R (RStudio is the usual front end) plus the CRAN and Bioconductor packages listed at the top of Part 2 — before you need them, since Bioconductor installs are slow and occasionally need troubleshooting.
- **No command-line experience needed to start.** Part 1 begins at `pwd` and `cd`. For more grounding first, the [Genomics Aotearoa Metagenomics Summer School](https://genomicsaotearoa.github.io/metagenomics_summer_school/) material (linked at the end of Part 1 Section 1) is NeSI-specific; its cluster fundamentals match our environment exactly and are what the read-based SOP assumes, so it is the natural bridge from amplicons to shotgun.

## Conventions

- **Angle brackets are placeholders.** The full set: `<your_nesi_project_code>` (allocation code, e.g. `uoa03068`), `<your_project>` (your working directory under it), `<username>`, `<your_email>` (the whole address, domain included), `<sample>`, `<job_id>`. Nothing works if you paste them literally. Shell variables (`$WORK`, `$DB`) may be used in interactive blocks but never inside a SLURM script body — a batch job does not inherit your login shell, so define them in the script.
- **Every document numbers its sections from 1.** A bare section number means the current document; a cross-document reference names the file and, if it needs a section, names it under that file's own numbering. Check the file and section still exist before committing.
- **One `#`-level title per document**, followed by a one-line scope statement, a prerequisites line, and an ASCII roadmap block.
- **Script filenames carry the number of the section that defines them** — `05_concompra.sh` for Section 5, `09.metaphlan.sl` for Section 9. Numbers do not run across documents; suffix multiples in one section (`07a`, `07b`).
- **One SLURM job header, defined in Part 1 Section 1.** `#!/bin/bash` plus `set -euo pipefail`; space-separated `#SBATCH` options; `#SBATCH --chdir <absolute workspace path>` on every job with log paths relative to it; `mkdir -p logs` before the first submission. Arrays are 1-based with their real range set at submission (`sbatch --array=1-N%20`), never in the header, and indexed with `sed -n "${SLURM_ARRAY_TASK_ID}p"`. The read-based SOP's equivalent — `cd "${SLURM_SUBMIT_DIR:?}"` plus submitting from your workspace — is accepted in place of `--chdir`.
- **Taxonomic ranks have one vocabulary**: `superkingdom, phylum, class, order, family, genus, species`, lowercase. Any pipeline whose output differs (`d:`/`k__`/`Domain`) is converted to these before it reaches Part 2.
- **One sample ID per sample, set upstream and never suffixed.** The ID in the count-table header, the metadata file's first column and every other pipeline's output for that sample must be byte-identical. Strip tool-added suffixes (`_filtered`, `.CONCOMPRA`, `.profile`, `_Abundance-RPKs`) where they are created, not in R.
- **Part 2's input contract**: a tab-separated table of **integer counts** (taxa in rows, rank columns before sample columns) plus a tab-separated metadata file with sample IDs in the first column and a `SampleType` column. Any upstream document that produces something else owns the conversion.
- **phyloseq objects carry a suffix naming what they hold**: `ps_raw` (raw counts), `ps_srs` (SRS-normalised), `ps_relab` (relative abundance), `ps_estcounts` (model-estimated counts). All four are defined in Part 2's "Key objects" table. Mixing them produces plausible wrong answers with no error message — the single easiest thing to get wrong in Part 2.
- **Write down the reasoning, not just the value.** If you document a threshold, parameter or tool choice, record why. Most of the useful content in these SOPs is in the "why this number" paragraphs, and a rewrite that removes one has made the document worse.
- **UK spelling. `SLURM` in capitals. Bold section headings.** Each document carries `**vN.N** | last updated <Month Year>` under its title.
- **Worked examples come from real data.** Part 1's NanoPlot statistics are from an actual run; the R examples use variables and site names from a tuatara study (`Site`, `Sex`, `Species`; Takapourewa, Zealandia, YoungNicksHead) — adapt these to your own metadata rather than copying them.
- **Module versions are pinned but will drift.** Confirm with `module spider <tool>` before relying on a string, capitalisation included.

## Tool versions

The NeSI modules these SOPs were written against, confirmed present on Mahuika in July 2026. Every one will drift — confirm with `module spider <tool>` (capitalisation included) before you rely on a string.

**Amplicon, Nanopore (Part 1):**

| Tool | Module string | Purpose |
| --- | --- | --- |
| Emu | `Emu/3.6.2` | Taxonomic profiling and abundance estimation |
| NanoPlot | `NanoPlot/1.43.0-foss-2023a-Python-3.11.6` | Read QC plots and statistics |
| chopper | `chopper/0.12.0b-GCC-12.3.0` | Quality and length filtering |

**Consensus OTUs (CONCOMPRA):** the pipeline runs from a conda environment built via `Miniforge3/25.3.1-0`; the deduplication step uses `SeqKit/2.4.0`; post-processing uses `VSEARCH/2.21.1-GCC-11.3.0`, `MAFFT/7.505-gimkl-2022a-with-extensions`, `FastTree/2.1.11-GCC-11.3.0` and `seqtk/1.4-GCC-11.3.0`.

**Shotgun, read-based:**

| Tool | Module string | Purpose |
| --- | --- | --- |
| FastQC | `FastQC/0.12.1` | Per-sample read QC |
| BBMap / BBDuk | `BBMap/39.01-GCC-11.3.0` | Adapter and quality trimming, PhiX removal, optional host mapping |
| MultiQC | `MultiQC/1.24.1-foss-2023a-Python-3.11.6` | Aggregated QC report |
| fastp | `fastp/0.23.4-GCC-11.3.0` | Alternative trimmer; two-colour poly-G handling |
| MetaPhlAn | `MetaPhlAn/4.1.0-gimkl-2022a-Python-3.10.5` | Marker-gene taxonomic profiling |
| HUMAnN | conda, via `Miniforge3/25.3.1-0` | Gene families and pathways |
| Hostile | conda, via `Miniforge3/25.3.1-0` | Host depletion against a masked human index |

HUMAnN is deliberately **not** taken from a module — NeSI's `Humann/3.0.0.alpha.3` module is a 2020 pre-release that predates every MetaPhlAn 4 database and must not be used with this workflow.

Reference databases: SILVA v138.1 and RDP for the amplicon work, via Emu's prebuilt OSF archives. Part 1 explains why we use the validated v138.1 build rather than the newer SILVA 138.2 archive, and why we run both databases and compare. The read-based SOP pins the MetaPhlAn index explicitly (`mpa_vJun23_CHOCOPhlAnSGB_202403`) and explains why an unpinned index makes results depend on when the database was last refreshed.

## Contributing

These are living documents. If something did not work, or needed explaining and did not get it, that is worth fixing for the next person.

- **Small corrections** (typos, broken links, a changed module version): edit and commit directly, with a message saying what changed and why.
- **Substantive changes** (a different tool, a changed threshold, a new analysis step): open a pull request or discuss with the lab first, since other people's methods sections may cite the current version. Say what you changed and what evidence prompted it.
- **New SOPs**: follow the naming pattern (`SOP_<Topic>_<Environment>.md`), keep the explain-then-command structure, and add a row to the table at the top of this README — adding the file without the row is the usual way a SOP goes unnoticed.
- **Cross-references** between documents must name the file; before committing, check the target exists in the repository — a reference to a document that was never written is worse than no reference.

If you document a threshold or a tool choice, write down the reasoning, not just the value. Most of the useful content in these SOPs is in the "why this number" paragraphs.

## Citing and reusing

If these SOPs shaped your methods, cite the underlying tools rather than this repository — that is what reviewers need. The SOPs give primary references where the choice of tool or method needs justifying:

- **Part 1 (Emu):** Emu — Curry et al. 2022, *Nature Methods*; chopper — De Coster & Rademakers 2023, *Bioinformatics*; SILVA — Quast et al. 2013, *Nucleic Acids Research*.
- **CONCOMPRA:** the pipeline — Stock et al. 2025; SINTAX — Edgar 2016; MAFFT — Katoh & Standley 2013; FastTree — Price et al. 2010. All five are in that SOP's Appendix B.
- **Read-based shotgun:** MetaPhlAn 4 — Blanco-Míguez et al. 2023, *Nature Biotechnology*; re-identification from residual human reads — Tomofuji et al. 2023, *Nature Microbiology*.
- **Part 2 (R):** the rarefaction debate — McMurdie & Holmes 2014, *PLoS Computational Biology*, and Schloss 2024, *mSphere*; DA method comparison — Nearing et al. 2022, *Nature Communications*, and Yang & Chen 2022, *Microbiome*; indicator species — Dufrêne & Legendre 1997, *Ecological Monographs*.

For the remaining R packages, look up the citation with `citation("phyloseq")` and equivalents. Record your package versions with `sessionInfo()` and keep the output alongside your results. For shotgun work, the read-based SOP's Section 14 lists what a methods section needs — the MetaPhlAn index tag, the HUMAnN and ChocoPhlAn/UniRef versions, whether the host reference was masked, the depth gates, which samples were excluded and why, and every model formula.

You are welcome to adapt these for your own lab. **Note that no licence has been added to this repository yet**, which by default means no reuse rights are granted. If sharing outside the lab is intended, adding a `LICENSE` file (CC BY 4.0 is common for protocols, MIT for scripts) would make that explicit.

---

*Last updated: July 2026 — second review round. All four SOPs and this README were probed against NeSI Mahuika and its R installation ([`reviews/00_ENVIRONMENT.md`](reviews/00_ENVIRONMENT.md)), reviewed adversarially, and rewritten against the findings; the first round is archived in [`reviews/v1/`](reviews/v1/). The sixteen questions the first round could not answer without cluster access are now settled in this round's reports. The review harness is [`prompts/SOP_REVIEW_PROMPT.md`](prompts/SOP_REVIEW_PROMPT.md).*
