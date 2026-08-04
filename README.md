# Taylor Lab Bioinformatic SOPs

Standard operating procedures for microbial community analysis on [NeSI](https://www.nesi.org.nz/) (New Zealand eScience Infrastructure) and in R, written for someone running their first analysis. Each SOP is a complete walkthrough — what a step does, the exact commands, and what correct output looks like.

## Which SOP do I need?

| Your data | Upstream (cluster) | Downstream (R) |
| --- | --- | --- |
| Full-length 16S rRNA amplicons, Oxford Nanopore (27F–1492R) | `SOP_EMU_NeSI.md` | `SOP_R_Analysis.md` |
| The same data, where you also need consensus sequences, a tree, or resolution for taxa the reference databases miss | `SOP_EMU_NeSI.md` first, then `SOP_CONCOMPRA_NeSI.md` | `SOP_R_Analysis.md` |
| Short-read 16S amplicons, Illumina (V3–V4, 341F–785R) | Not yet covered — you need a DADA2 or similar ASV workflow | `SOP_R_Analysis.md` applies once you have a count table |
| Shotgun metagenomes, read-based profiling, human-associated samples | `SOP_READBASED_NeSI.md` | `SOP_R_Analysis.md`, with the deltas in that SOP's Section 13 |
| Shotgun metagenomes, read-based profiling, animal or environmental samples | Not covered — MetaPhlAn's marker genes are built for human-associated taxa | — |
| Shotgun metagenomes, assembly and binning into MAGs | `SOP_READBASED_NeSI.md` Sections 1–8 for clean reads, then `SOP_ASSEMBLY_NeSI.md` **(draft, v0.1 — not yet reviewed)** | `SOP_R_Analysis.md`, with the deltas in `SOP_ASSEMBLY_NeSI.md` Section 15 |

**Amplicon** means you PCR-amplified one gene (16S) and sequenced only that; **shotgun** means you sequenced all DNA without targeting a gene. **Read-based** profiles reads directly against reference databases with no assembly step — faster and works on lower-coverage data, but it finds only organisms and genes already in the databases and recovers no novel genomes (for those, you want assembly and binning).

**Settle two things before you generate shotgun data**, because neither can be fixed afterwards: whether your ethics approval covers host-depleted human sequence (depletion reduces identifiability but does not remove it), and whether you have enough negative and positive controls to run contamination screening. Both are Section 1 of the read-based SOP — read it before sequencing, not after.

## What each document covers

| File | Covers |
| --- | --- |
| [`SOP_EMU_NeSI.md`](SOP_EMU_NeSI.md) | **Part 1 — sequencing → count tables.** Nanopore full-length 16S: NeSI onboarding (bash, modules, SLURM), read QC, filtering, Emu profiling against SILVA and RDP, combined count tables. The only document that teaches the cluster itself, starting from `pwd`. |
| [`SOP_R_Analysis.md`](SOP_R_Analysis.md) | **Part 2 — count tables → results.** phyloseq, decontam, SRS normalisation, alpha/beta diversity, PERMANOVA, differential abundance (ANCOM-BC2 and MaAsLin2, ALDEx2 noted), indicator species, common pitfalls. Platform-agnostic; runs locally in R. |
| [`SOP_CONCOMPRA_NeSI.md`](SOP_CONCOMPRA_NeSI.md) | **Runs after Part 1, same Nanopore data.** Reference-free consensus OTUs alongside Emu's assignments: install, dedup, run configuration, submission, verification, then SINTAX taxonomy, MAFFT alignment, FastTree phylogeny. Takes Part 1's filtered reads as input and hands off to Part 2. |
| [`SOP_READBASED_NeSI.md`](SOP_READBASED_NeSI.md) | **Illumina shotgun, read-based.** Governance and controls, trimming and PhiX removal, host depletion against T2T-CHM13, depth gates, taxonomy (MetaPhlAn 4), function (HUMAnN), contamination screening, and what changes in Part 2 for compositional input. Does not re-teach the cluster — it points first-timers back to Part 1 Section 1. |
| [`SOP_ASSEMBLY_NeSI.md`](SOP_ASSEMBLY_NeSI.md) | **Illumina shotgun, assembly-based.** Takes the read-based SOP's clean, host-depleted reads and reconstructs genomes: assembly (MEGAHIT/metaSPAdes), coverage mapping, binning (MetaBAT2, MaxBin2, CONCOCT) with DAS_Tool refinement, MAG quality (CheckM2, MIMAG tiers), dereplication (dRep), taxonomy (GTDB-Tk), annotation (Bakta; eggNOG/DRAM optional), and a MAG × sample abundance table. Hands off to Part 2 with compositional deltas (its Section 15). |

**Part 2 is platform-agnostic** — one R document, not one per platform. Once you have a count table, a taxonomy table and a metadata file, the R workflow is identical whether the reads were profiled with Emu, CONCOMPRA or MetaPhlAn; only the interpretation differs (Part 1 covers this under "Full-length vs short-read"; the read-based SOP's Section 13 lists what changes when the input is relative abundance rather than counts).

**Start with Part 1 if this is your first pipeline** — it is the only document that teaches the cluster (bash, modules, SLURM, array jobs). The two cluster documents downstream of it (CONCOMPRA, read-based) say so at the top and point back to Part 1 Section 1; Part 2 runs locally and legitimately does not.

## Before you start

- **A NeSI account and project code** — the allocation code (e.g. `uoa03068`, written `<your_nesi_project_code>` in the SOPs) that every SLURM script needs.

- **Storage planned on day one** — databases on `/nesi/nobackup/`, scripts and final tables on the backed-up `/nesi/project/`; the read-based database set alone runs to ~85–95 GB.

- **R on your own machine** — Part 2 runs locally, so install a current R and the Part 2 packages before you need them, not on NeSI.

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

**Shotgun, assembly (MAGs):**

| Tool | Module string | Purpose |
| --- | --- | --- |
| MEGAHIT | `MEGAHIT/1.2.9-gimkl-2022a-Python-3.10.5` | Assembly (default) |
| SPAdes (metaSPAdes) | `SPAdes/4.0.0-foss-2023a-Python-3.11.6` | Assembly (alternative), `spades.py --meta` |
| QUAST (metaQUAST) | `QUAST/5.2.0-gimkl-2022a` | Assembly QC |
| MetaBAT2 / MaxBin2 / CONCOCT | `MetaBAT/2.17-GCC-12.3.0`, `MaxBin/2.2.7-GCC-11.3.0-Perl-5.34.1`, `CONCOCT/1.1.0-gimkl-2020a-Python-3.8.2` | Binning |
| DAS_Tool | `DAS_Tool/1.1.5-gimkl-2022a-R-4.2.1` | Bin refinement |
| CheckM2 | `CheckM2/1.0.1-Miniconda3` | MAG completeness/contamination |
| dRep | `drep/3.4.2-gimkl-2022a-Python-3.10.5` | Dereplication |
| GTDB-Tk | `GTDB-Tk/2.7.1-foss-2023a-Python-3.11.6` | Taxonomy (GTDB R232) |
| Bakta | `bakta/1.10.1-foss-2023a` | Annotation |
| CoverM | `CoverM/0.7.0-GCC-12.3.0` | MAG × sample abundance |

GTDB-Tk, CheckM2, Bakta, eggNOG-mapper (`eggnog-mapper/2.1.12-gimkl-2022a`) and DRAM (`DRAM/1.3.5-Miniconda3`) resolve their large reference databases from NeSI's central `/opt/nesi/db` — nothing to download.

Reference databases: SILVA v138.1 and RDP for the amplicon work, via Emu's prebuilt OSF archives. Part 1 explains why we use the validated v138.1 build rather than the newer SILVA 138.2 archive, and why we run both databases and compare. The read-based SOP pins the MetaPhlAn index explicitly (`mpa_vJun23_CHOCOPhlAnSGB_202403`) and explains why an unpinned index makes results depend on when the database was last refreshed.

## Contributing

These are living documents. If something did not work, or needed explaining and did not get it, that is worth fixing for the next person.

- **Small corrections** (typos, broken links, a changed module version): edit and commit directly, with a message saying what changed and why.

- **Substantive changes** (a different tool, a changed threshold, a new step): open a pull request or discuss with the lab first, since methods sections may cite the current version.

- **New SOPs**: write them against [`TUTORIAL_SPEC.md`](TUTORIAL_SPEC.md), follow the `SOP_<Topic>_<Environment>.md` naming, and add a row to the routing table above.

- **Conventions live in the spec** — placeholders, headings, the job header, ranks, object names, voice — so link to it rather than copying them here.

The spec carries three scans — heading census, paragraph length, and script-header completeness — that tell you in seconds whether an edit made a document worse. If you document a threshold or a tool choice, write down the reasoning, not just the value: most of the useful content in these SOPs is in the "why this number" paragraphs.

## Citing and reusing

If these SOPs shaped your methods, cite the underlying tools rather than this repository — that is what reviewers need. The SOPs give primary references where the choice of tool or method needs justifying:

| Document | Primary references |
| --- | --- |
| **Part 1 (Emu)** | Emu — Curry et al. 2022, *Nature Methods*; chopper — De Coster & Rademakers 2023, *Bioinformatics*; SILVA — Quast et al. 2013, *Nucleic Acids Research*. |
| **CONCOMPRA** | the pipeline — Stock et al. 2025; SINTAX — Edgar 2016; MAFFT — Katoh & Standley 2013; FastTree — Price et al. 2010 (all in that SOP's Appendix B). |
| **Read-based shotgun** | MetaPhlAn 4 — Blanco-Míguez et al. 2023, *Nature Biotechnology*; re-identification from residual human reads — Tomofuji et al. 2023, *Nature Microbiology*; DA-method benchmarking — Yang & Chen 2022, *Microbiome*. |
| **Part 2 (R)** | rarefaction debate — McMurdie & Holmes 2014, *PLoS Computational Biology*, and Schloss 2024, *mSphere*; DA-method comparison — Nearing et al. 2022, *Nature Communications*; indicator species — Dufrêne & Legendre 1997, *Ecological Monographs*. |

For the remaining R packages, look up the citation with `citation("phyloseq")` and equivalents. Record your package versions with `sessionInfo()` and keep the output alongside your results. For shotgun work, the read-based SOP's Section 14 lists what a methods section needs — the MetaPhlAn index tag, the HUMAnN and ChocoPhlAn/UniRef versions, whether the host reference was masked, the depth gates, which samples were excluded and why, and every model formula.

You are welcome to adapt these for your own lab. **Note that no licence has been added to this repository yet**, which by default means no reuse rights are granted. If sharing outside the lab is intended, adding a `LICENSE` file (CC BY 4.0 is common for protocols, MIT for scripts) would make that explicit.

---

*Last updated: July 2026 — second review round. The four Nanopore, Illumina and R SOPs (`SOP_EMU_NeSI.md`, `SOP_CONCOMPRA_NeSI.md`, `SOP_READBASED_NeSI.md`, `SOP_R_Analysis.md`) and this README were probed against NeSI Mahuika and its R installation ([`reviews/00_ENVIRONMENT.md`](reviews/00_ENVIRONMENT.md)), reviewed adversarially, and rewritten against the findings; the first round is archived in [`reviews/v1/`](reviews/v1/). `SOP_ASSEMBLY_NeSI.md` (v0.1, August 2026) was added afterwards and is still a draft — it has not yet been through the correctness or tutorial review rounds. The sixteen questions the first round could not answer without cluster access are now settled in this round's reports. A whole-suite capstone review followed in August 2026 ([`reviews/capstone/`](reviews/capstone/)). The review harness is [`prompts/SOP_REVIEW_PROMPT.md`](prompts/SOP_REVIEW_PROMPT.md).*
