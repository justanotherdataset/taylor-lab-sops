## Document: SOP_CONCOMPRA_NeSI.md

## Verdict against the specification

`SOP_CONCOMPRA_NeSI.md` is the cleanest *runbook* in the set and the emptiest
*tutorial*. Its operational spine is excellent: the "verify on disk, never the
`.out` log" thread is the strongest silent-failure content in the repository,
every fork that matters (`MIN`/`MAX`, `THREADS`, `sintax_cutoff`, primer
orientation) carries a real default with a reason, both job scripts are complete
and runnable, and the voice is disciplined — no banned words, no `we`/`the user`
drift, no throat-clearing, UK spelling throughout. What it does not have is a
single line of **layer 1**. It opens the word "OTU" in its own title and never
defines it; it clusters reads with "UMAP/OPTICS", builds a "consensus",
"dereplicates", and "detects chimeras" in one sentence (line 51) with none of
those five words explained; it runs MAFFT, FastTree and SINTAX in Section 7 with
no prose saying what alignment, a phylogeny or classification *are*. The spec
measures this as 0 layer-1 and 0 layer-2 headings, and that is exactly right: the
document is missing an entire explanatory layer, not carrying it badly. The fix
is growth — one concepts section and a handful of one-line glosses — with the
"why this number" content (which is dense and correct) left untouched. The two
over-80 paragraphs and one SLURM-style inconsistency are the only form defects.

| Rule | Pass / Partial / Fail | One-line evidence |
| --- | --- | --- |
| R1 both layers, in order | **Fail** | Layer-2 "why" everywhere; layer-1 "what is this" absent from every section. |
| R2 nothing used before introduced | **Fail** | OTU, chimera, consensus, dereplication, UMAP/OPTICS, SINTAX, MAFFT, FastTree, ASV, GTR/bootstrap used with no prior definition. |
| R3 concepts before commands | **Fail** | Zero pure-prose concept subsections; §7 opens straight into a SLURM job. |
| R4 setup where needed | **Pass** | Install is install-once (R4 exception); env activation, config, DB build all appear at the step that needs them. |
| R5 every step states its outcome | **Partial** | Strong checkpoints in §3, §6, §7, §8; env build and primer file lack an expected/mismatch. |
| R6 one numbered spine | **Partial** | Numbering runs in performance order and script names match sections, but `03_dedup.sh` is named in the tree yet never authored. |
| R7 every fork has a default | **Partial** | Most forks defaulted; the `prv_cut` prevalence fork (line 589) has none. |
| R8 plain words first, jargon second | **Fail** | Line 51 is jargon-only; chimera/dereplication/OTU never get a plain-words gloss. |
| R9 one voice | **Pass** | Consistent imperative; no `we`/`the user`/`one should`. |
| R10 explain the failure | **Pass (strong)** | Silent-failure content is the document's best asset; one dangling pointer ("chimera-detection settings"). |
| R11 every script complete | **Pass** | Both job blocks carry shebang, `--account`, `--time`, `set -euo pipefail`; no bare `$SAMPLE`. |
| F1 no paragraph over 80 words | **Partial** | Two genuine over-80: L7 (83w) and L324 (87w). |
| F2 definition one or two sentences | **Partial** | Where definitions exist they are tight; the problem is absence, not length. |
| F3 enumerable becomes table/list | **Partial** | A few prose failure-cause runs (L601, L185) are unwritten lists. |
| F4 the point comes first | **Pass** | First sentences and bold runs carry the operative fact. |
| F5 the "why" is separable | **Pass** | §7 "Notes on the steps" sits after the commands; layer-2 is skippable. |

## Jargon table

| Term | First used | Defined at | Verdict |
| --- | --- | --- | --- |
| OTU | L3 (title), L7 | never | **FAIL** — flagship term, in the title, no definition, no in-doc lookup |
| consensus / consensus sequence | L3, L7, L51 | implied L51 (`lamassemble`) | **FAIL** — the core product, never defined as a concept |
| reference-free / de novo | L7, L53 | inline L7 ("rather than aligning to a reference") | PARTIAL — glossed by contrast only |
| chimera / chimeric | L51, L376, L392 | never | **FAIL** — §5 R2 names this explicitly; drives an output file and a troubleshooting branch |
| clustering (UMAP / OPTICS) | L51 | never | **FAIL** — named parenthetically with zero explanation |
| dereplicate / dereplication | L51 | never | **FAIL** — undefined verb |
| lamassemble | L51 | inline L51 ("builds consensus") | PARTIAL |
| SINTAX | L7, L124 | Appendix B (L701) | **FAIL** — used ~10x before its definition at the back |
| SILVA | L7 | Appendix B (L703) | PARTIAL — reference DB, first use undefined |
| vsearch / `--sintax` | L126 | inline by use | PARTIAL |
| UDB (`.udb`) | L74, L129 | inline L74 ("what vsearch --sintax reads") | PASS |
| MAFFT | L39, L402 | Appendix B (L705) | **FAIL** — first substantive use at L402, defined only at back |
| FastTree | L39, L461 | Appendix B (L707) | **FAIL** — same |
| alignment / aligned | L402, L456 | never (concept) | FAIL — the operation is never explained |
| phylogeny / tree / Newick / `.nwk` | L39, L461, L485 | never (concept) | FAIL |
| GTR / maximum-likelihood | L461, L478 | never | **FAIL** — layer-2 ("why -gtr") with no layer-1 |
| bootstrap / SH-like supports | L476, L478 | never | **FAIL** — "0.8 bootstrap threshold" precedes any definition of bootstrap |
| ASV | L589 | never | **FAIL** — "Illumina ASV data", no contrast to OTU given |
| conda / conda environment | L66, L87 | never | FAIL — first-timer from EMU (modules, not conda) meets it cold |
| Miniforge3 / Miniconda3 | L87 | inline L87 (which and why) | PASS |
| `defaults` channel | L87 | inline L87 | PASS |
| `PYTHONNOUSERSITE` | L122 | inline L122 | PASS |
| filtlong | L16, L142 | inline L283 (retention) | PARTIAL — used before purpose given |
| POD5 | L142, L165 | inline L165 (UUIDs) | PARTIAL |
| symlink / `ln -s` / `realpath` | L33, L212 | inline L212 (realpath only) | PARTIAL — "symlink" itself not defined |
| FASTA / `.fa` / `.fasta` | L33, L130 | never | PARTIAL — inherited from EMU, assumed |
| head/tail, sense-strand, reverse-complement, 5'/3' | L251 | inline L251-263 | PASS — well explained in the primer section |
| `directory_list.txt` | L33, L225 | inline L225 ("shell fragment, not a list") | PASS |
| `set -e` / `set -euo pipefail` | L249, L313 | inline by consequence | PASS |
| prevalence filtering / `prv_cut` | L589 | inline L589 (partial) | PARTIAL — §5 R2 names "prevalence method"; no default |
| UniFrac / Faith's PD | L584 | never | PARTIAL — flagged optional/advanced |

## Section ledger

| § | Heading | Lines | Treatment | Findings |
| --- | --- | --- | --- | --- |
| — | Title + version + intro paragraph | 1–9 | SPLIT | S-13 |
| — | Before you start | 11–19 | CLEAN | — |
| — | Quick Roadmap | 23–45 | CLEAN | — |
| 1 | Overview | 49–60 | ADD-LAYER-1 / REWRITE | S-01 |
| 2 | Installation (intro) | 64–66 | ADD-LAYER-1 | S-05 |
| 2 | ├ Locations | 68–74 | CLEAN | — |
| 2 | ├ Clone the repository | 76–83 | CLEAN | — |
| 2 | ├ Build the conda environment | 85–101 | ADD-OUTCOME | S-06 |
| 2 | ├ Verify the environment | 103–122 | ADD-OUTCOME / TIGHTEN | S-06, S-15 |
| 2 | └ SILVA SINTAX database | 124–136 | CLEAN | — |
| 3 | Pre-flight: Screen for Duplicate Reads | 140–142 | CLEAN | — |
| 3 | ├ Screen | 144–161 | CLEAN | — |
| 3 | ├ Deduplicate | 163–181 | CLEAN | — |
| 3 | └ Record run metadata | 183–185 | TIGHTEN | S-15 |
| 4 | Run Configuration | 189 | CLEAN | — |
| 4 | ├ Directory layout | 191–208 | TIGHTEN | S-10 |
| 4 | ├ Symlink the input fastqs | 210–221 | CLEAN | — |
| 4 | ├ Run configuration file | 223–245 | CLEAN | — |
| 4 | ├ Primer file | 247–263 | CLEAN | — |
| 4 | └ Threads | 265–269 | CLEAN | — |
| 5 | Submitting the Run | 273–332 | MERGE / SPLIT | S-11, S-14 |
| 6 | Verifying the Run | 336–396 | CLEAN | S-09 (at L392) |
| 6 | ├ Per-sample verification | 340–366 | CLEAN | — |
| 6 | ├ Output files | 368–392 | CLEAN | S-09 |
| 6 | └ Cross-check against Emu | 394–396 | CLEAN | — |
| 7 | Post-processing (intro) | 400–402 | ADD-LAYER-1 | S-03 |
| 7 | ├ (job script) | 418–463 | REWRITE-VOICE | S-12 |
| 7 | ├ Notes on the steps | 472–478 | ADD-LAYER-1 | S-04 |
| 7 | └ Verifying the outputs | 480–488 | CLEAN | — |
| 8 | Preparing for R / phyloseq (intro) | 492–495 | CLEAN | — |
| 8 | ├ The R-ready folder | 496–507 | CLEAN | — |
| 8 | ├ Building it | 508–540 | CLEAN | — |
| 8 | ├ Checking sample IDs | 541–550 | CLEAN | — |
| 8 | └ Building the phyloseq object | 551–594 | TIGHTEN | S-07, S-08 |
| 9 | Troubleshooting | 595 | CLEAN | — |
| 9 | ├ Empty consensus output | 597–601 | TIGHTEN | S-15 |
| 9 | ├ Empty sintax output | 603–605 | CLEAN | — |
| 9 | ├ medaka, racon, or samtools missing | 607–609 | CLEAN | — |
| 9 | └ A run is stuck or slow | 611–618 | CLEAN | — |
| 10 | Maintenance | 622 | CLEAN | — |
| 10 | ├ Updating CONCOMPRA | 624–635 | CLEAN | — |
| 10 | └ The temporary directory | 637–646 | MERGE | S-11 |
| A | Appendix A: SILVA SINTAX Database Build (intro) | 650–653 | CLEAN | — |
| A | ├ The reformatter | 654–665 | CLEAN | — |
| A | ├ Build | 666–690 | REWRITE | S-02 |
| A | └ Refreshing for a new SILVA release | 691–696 | CLEAN | — |
| B | Appendix B: References | 697–712 | CLEAN | — |

## Findings

### S-01 · S1 · No layer-1 concepts section; OTU, consensus, chimera never defined
- **Where:** SOP_CONCOMPRA_NeSI.md:49-60, § 1 Overview
- **Anchor:** `## **1. Overview**`
- **Quote:**
  > CONCOMPRA (Stock et al., 2025) clusters primer-trimmed reads (UMAP/OPTICS),
  > builds a per-sample consensus sequence per cluster with `lamassemble`,
  > dereplicates across samples, detects chimeras, and outputs an OTU table and
  > consensus sequences.
- **Breaks:** R1 (layer-2 without layer-1), R2 (OTU/consensus/chimera/dereplication/UMAP/OPTICS undefined), R3 (no concept subsection), R8 (jargon first)
- **Reader impact:** The reader arrives from the Emu SOP knowing "profiling" and
  meets a document whose title word, OTU, is never expanded, and whose one
  descriptive sentence is five undefined terms in a row. They can still run every
  command — the pipeline is copy-paste — but they cannot say what an OTU is, why
  there are two consensus FASTAs, what "chimeric" means when a file is named that,
  or what makes this "reference-free". Every downstream interpretation (the OTU
  table, the chimera file, the tree) is then a guess. This is the single missing
  layer the spec says this document must grow.
- **Fix:** Rename § 1 to **`## **1. Understanding your data**`** and replace the
  current Overview body (lines 51–60) with the following, keeping the existing
  comparison table at the end:

  > CONCOMPRA turns your filtered Nanopore reads into **OTUs** — operational
  > taxonomic units, groups of near-identical sequences that stand in for "a kind
  > of organism" when you cannot put a species name to them. Where Emu asks
  > *which known species are here* by matching each read to a reference database,
  > CONCOMPRA asks *what distinct sequences are here*, whether or not any database
  > knows them.
  >
  > It never consults a reference to decide what counts as an OTU — that is what
  > **reference-free**, or **de novo** ("from scratch"), means — so it can resolve
  > novel or poorly-catalogued taxa that Emu can only return as "unclassified".
  >
  > It gets there in four moves, and the output files are named after them:
  >
  > - **Clustering.** Reads from one sample are grouped by sequence similarity (the
  >   algorithms are UMAP and OPTICS; you never call them directly). Each cluster
  >   is one candidate OTU.
  > - **Consensus.** For each cluster, `lamassemble` collapses its reads into a
  >   single best-estimate sequence — the **consensus** — averaging out per-read
  >   Nanopore errors.
  > - **Dereplication.** Identical consensus sequences from different samples are
  >   merged into one OTU, so a taxon seen in ten samples is one row, not ten.
  > - **Chimera detection.** A **chimera** is an artificial hybrid sequence formed
  >   during PCR, when a half-finished copy of one organism's DNA completes on
  >   another's template. It is not a real organism, so CONCOMPRA flags chimeras
  >   and sets them aside in a separate file.
  >
  > The run produces an **OTU table** (OTUs in rows, samples in columns, counts in
  > the cells) and a **consensus FASTA**. Post-processing (Section 7) then names
  > each OTU against SILVA (**SINTAX** classification), aligns the sequences
  > (**MAFFT**), and builds a tree (**FastTree**) so you can place novel OTUs next
  > to their nearest known relatives.
  >
  > Use it alongside Emu. Emu gives fast alignment-based taxonomy and relative
  > abundance against curated databases; CONCOMPRA gives reference-free consensus
  > sequences for novel or poorly-resolved taxa and for sequence-level work like
  > trees and primer-mismatch checks.

  (Then the existing `| Pipeline | What it gives | Best for |` table and the
  "Run both on the same deduplicated input and compare." line, unchanged.)

### S-02 · S1 · Appendix A: Emu `species_taxid.fasta` path is unresolvable
- **Where:** SOP_CONCOMPRA_NeSI.md:673, Appendix A § Build
- **Anchor:** `cd <where Emu's species_taxid.fasta lives>`
- **Quote:**
  > cd <where Emu's species_taxid.fasta lives>
- **Breaks:** R2 (undefined location), R6 (a cross-document reference must name the file and path)
- **Reader impact:** To build the SILVA SINTAX database — a hard prerequisite for
  all of Section 7 — the reader must `cd` to the Emu SILVA bundle, but the
  document never says where that is. A reader who set CONCOMPRA up in its own
  directory has no idea which path holds `species_taxid.fasta`; they stop here,
  or guess a path and get "file not found". The location lives in the Emu SOP and
  is never carried across.
- **Fix:** Replace the placeholder line and its comment with an explicit
  cross-reference:

  > ```bash
  > # 1. Reformat (about 7 seconds for ~412k records; expect 0 dropped).
  > #    Copy the reformatter into the database directory, then cd to the SILVA
  > #    bundle SOP_EMU_NeSI.md installed — the directory that holds Emu's
  > #    species_taxid.fasta (its SILVA database download). If you do not have it,
  > #    build it via SOP_EMU_NeSI.md's database step first.
  > cp reformat_silva_for_sintax.py /nesi/project/<your_nesi_project_code>/databases/silva_emu_sintax/
  > cd /nesi/project/<your_nesi_project_code>/databases/emu/silva/   # the Emu SILVA bundle
  > ```

  Confirm the file is present before reformatting: `ls species_taxid.fasta`
  should list it; "No such file" means you are in the wrong directory or the Emu
  SILVA database was never downloaded.

### S-03 · S2 · Section 7 runs three tools with no conceptual lead-in
- **Where:** SOP_CONCOMPRA_NeSI.md:400-402, § 7
- **Anchor:** `One SLURM job filters the chimera-clean fasta`
- **Quote:**
  > One SLURM job filters the chimera-clean fasta to OTUs that have reads,
  > classifies them with `vsearch --sintax`, aligns with MAFFT, and builds a
  > FastTree phylogeny.
- **Breaks:** R3 (section introduces new tooling with no concept prose), R2 (MAFFT, FastTree, alignment, phylogeny undefined at use)
- **Reader impact:** Section 7 is where three unfamiliar tools appear at once. The
  reader is told the mechanics (one job, four steps) but never *why* they align
  sequences or build a tree, or what those operations are. They run the job and
  get three output files they cannot interpret — an alignment, a `.sintax` table,
  a Newick tree — with no mental model of what each is for.
- **Fix:** Insert immediately after the `## **7. Post-processing...**` heading,
  before the "One SLURM job..." paragraph:

  > Post-processing answers three questions about the OTUs you just built, and runs
  > all three in one short job:
  >
  > - **What is each OTU?** `vsearch --sintax` compares each consensus sequence to
  >   the SILVA reference and assigns a name down to the most confident rank —
  >   this is **taxonomic classification**.
  > - **How do the sequences line up?** **MAFFT** performs a multiple-sequence
  >   **alignment**: it stacks the sequences so equivalent positions sit in the
  >   same column, which is the input a tree needs.
  > - **How are they related?** **FastTree** turns that alignment into a
  >   **phylogenetic tree**, so you can place novel OTUs next to their nearest
  >   known relatives and, later, compute phylogenetic diversity.

### S-04 · S2 · GTR, bootstrap and SH-like supports stated without a plain-words gloss
- **Where:** SOP_CONCOMPRA_NeSI.md:472-478, § 7 Notes on the steps
- **Anchor:** `builds an approximate maximum-likelihood tree under GTR`
- **Quote:**
  > **Step 4.** `FastTree -gtr -nt` builds an approximate maximum-likelihood tree
  > under GTR and reports SH-like local supports by default. For resample-based
  > supports, add `-boot 1000`.
- **Breaks:** R1 (layer-2 "why -gtr / add -boot" with no layer-1), R2 (GTR, maximum-likelihood, bootstrap, SH-like supports undefined), R8 (jargon first)
- **Reader impact:** Step 2 already says "the 0.8 cutoff is the standard SINTAX
  bootstrap threshold" before "bootstrap" is ever defined; Step 4 then stacks GTR,
  maximum-likelihood and SH-like supports in one line. A beginner cannot tell what
  a support value means, so they cannot read their own tree or decide whether to
  add `-boot`. The reasoning is worth keeping — it just needs its terms explained.
- **Fix:** In Step 2, gloss bootstrap at first use — change "the standard SINTAX
  bootstrap threshold" to "the standard SINTAX **bootstrap** threshold (a 0–1
  confidence score from repeated resampling; higher is more reliable)". Then
  replace Step 4 with:

  > **Step 4.** `FastTree -gtr -nt` builds an approximate **maximum-likelihood**
  > tree — the branching pattern most consistent with the aligned sequences —
  > under the **GTR** model, the standard general model of how one DNA base
  > substitutes for another. By default it reports **SH-like local supports**: a
  > 0–1 score on each branch estimating how well the data back that split, higher
  > being more trustworthy. For the more familiar resample-based **bootstrap**
  > supports instead, add `-boot 1000`.

### S-05 · S2 · "conda environment" used throughout but never introduced
- **Where:** SOP_CONCOMPRA_NeSI.md:64-66, § 2 Installation
- **Anchor:** `Install CONCOMPRA and its conda environment once per project directory`
- **Quote:**
  > Install CONCOMPRA and its conda environment once per project directory, then
  > reuse them across runs and users on that project.
- **Breaks:** R2 (conda / conda environment undefined), R3 (Installation opens on tooling with no concept line)
- **Reader impact:** The reader learned modules in the Emu SOP; CONCOMPRA is the
  first document to use conda, and it never says what a conda environment is or
  why this pipeline needs one instead of `module load`. They copy `conda env
  create` and `conda activate` on faith, and when either fails they have no model
  of what an "environment" even is to debug it.
- **Fix:** Insert after the existing opening line of Section 2:

  > CONCOMPRA's tools are not available as NeSI modules, so you install them into a
  > **conda environment** — a self-contained folder holding a specific version of
  > every package the pipeline needs, isolated from the rest of the system. You
  > build it once from the recipe shipped with CONCOMPRA (`CONCOMPRA.yml`), then
  > `conda activate` it whenever you run the pipeline, much as you `module load` a
  > NeSI tool.

### S-06 · S2 · conda solve has no runtime and the verify step has no mismatch meaning
- **Where:** SOP_CONCOMPRA_NeSI.md:85-122, § 2 Build / Verify the environment
- **Anchor:** `Confirm the upstream pins are present`
- **Quote:**
  > Confirm the upstream pins are present: `filtlong 0.2.1`, `minimap2 2.1.1`,
  > `python 3.11`, `numba 0.60.0`.
- **Breaks:** R5 (§4 item 4 runtime and item 5 mismatch-meaning both missing), R2 (a silent half-solve is a failure mode not named)
- **Reader impact:** A libmamba solve of this environment runs for many minutes
  and prints little; with no time estimate the reader assumes it hung and kills
  it, leaving a half-built environment that then fails obscurely at run time. The
  "Verify" step lists the expected pins but never says what a missing pin *means*
  or what to do — so a wrong result reads as fine.
- **Fix:** Add a runtime line immediately after the `conda env create` block:

  > The solve typically takes 5–15 minutes and prints little while it resolves
  > dependencies. A long silent pause is normal here, not a hang — do not
  > interrupt it.

  And extend the Verify paragraph with a mismatch clause:

  > A missing pin, or a solver error instead of a package list, means the
  > `defaults`-channel strip or the Miniforge requirement above was not met.
  > Remove the half-built environment (`conda env remove -p
  > /nesi/project/<your_nesi_project_code>/conda_envs/CONCOMPRA`) and rebuild
  > before going on; a partially-solved environment fails silently mid-run.

### S-07 · S2 · "ASV" used with no definition or contrast to OTU
- **Where:** SOP_CONCOMPRA_NeSI.md:589, § 8
- **Anchor:** `tuned for Illumina ASV data`
- **Quote:**
  > so the `prv_cut = 0.10` in Part 2's ANCOM-BC2 call, tuned for Illumina ASV
  > data, may discard real signal.
- **Breaks:** R2 (ASV undefined), R8 (term alone, no plain-words lead)
- **Reader impact:** The reader has only just, at best, learned what an OTU is;
  "ASV" arrives with no expansion and no explanation of how it differs, so the
  sentence's whole point — that a threshold tuned for one kind of feature may be
  wrong for theirs — lands as noise.
- **Fix:** Replace "tuned for Illumina ASV data" with:

  > tuned for Illumina **ASV** data — amplicon sequence variants, the
  > exact-sequence features short-read pipelines call, which are the short-read
  > counterpart of these consensus OTUs —

### S-08 · S2 · Prevalence-filter fork gives no default value
- **Where:** SOP_CONCOMPRA_NeSI.md:589, § 8
- **Anchor:** `prv_cut = 0.10`
- **Quote:**
  > may discard real signal. Consider lowering it and say what you used.
- **Breaks:** R7 (fork with no named default), R2 (prevalence method under-specified)
- **Reader impact:** "Consider lowering it" tells the reader to make a
  parameter decision with no starting point — exactly the stop-and-research the
  spec forbids. They do not know *to what*, so they either leave a threshold that
  may delete real rare taxa or invent a number blind.
- **Fix:** Replace "Consider lowering it and say what you used." with a named
  default and reason:

  > For CONCOMPRA input, **start at `prv_cut = 0.05`** (half the Illumina default)
  > and record the value you used; low-prevalence OTUs from per-sample consensus
  > are often genuine rare taxa, so the Illumina-tuned `0.10` over-filters here.
  > Set `prv_cut = 0` to disable prevalence filtering entirely when rare taxa are
  > the point of the study.

### S-09 · S2 · "check the chimera-detection settings" points at nothing documented
- **Where:** SOP_CONCOMPRA_NeSI.md:392, § 6 Output files
- **Anchor:** `check the chimera-detection settings`
- **Quote:**
  > A non-empty `clustered_consensus.fasta` with an empty chimera-filtered fasta
  > means everything was called chimeric; check the chimera-detection settings.
- **Breaks:** R10 (failure named but not actionable), R2 (the "settings" are never located)
- **Reader impact:** The reader hits an all-chimeric result and is told to "check
  the chimera-detection settings" — which the document never exposes through any
  config file and never locates. They stop, with a failure diagnosed but no lever
  named.
- **Fix:** Replace the sentence with an actionable version:

  > A non-empty `clustered_consensus.fasta` with an empty chimera-filtered fasta
  > means every sequence was called chimeric — usually a sign the input was
  > near-empty or badly degraded rather than a real chimera storm, so check the
  > `.err` log for upstream failures first (Section 6). The chimera step is not
  > exposed through `directory_list.txt`; to change its thresholds you edit the
  > pipeline script directly, the same way you would for any parameter not in the
  > config ([Threads](#threads)).

### S-10 · S3 · Directory tree lists `03_dedup.sh`, a script the document never writes
- **Where:** SOP_CONCOMPRA_NeSI.md:191-208, § 4 Directory layout
- **Anchor:** `# if dedup was needed (Section 3)`
- **Quote:**
  > ├── 03_dedup.sh                   # if dedup was needed (Section 3)
- **Breaks:** R6 (script filenames name scripts that exist; Section 3's dedup is an interactive loop, not a saved `.sh`)
- **Reader impact:** The reader who kept the directory tree as a checklist looks
  for a `03_dedup.sh` to write or run and finds none — Section 3 deduplicates with
  an interactive loop straight into `filtered_dedup/`. Minor, but it is a
  named artefact the workflow never produces.
- **Fix:** Delete the `├── 03_dedup.sh ... # if dedup was needed (Section 3)`
  line from the tree. Section 3's dedup is run interactively and its only output,
  `filtered_dedup/`, already appears in the tree below. If the lab prefers a saved
  script, wrap the Section 3 loop as `03_dedup.sh` and keep the row — but pick one.

### S-11 · S3 · `rm -rf temporary` rationale duplicated across § 5 and § 10
- **Where:** SOP_CONCOMPRA_NeSI.md:637-646, § 10 The temporary directory
- **Anchor:** `so per-sample intermediates are deleted on a successful run`
- **Quote:**
  > CONCOMPRA's `main.sh` ends with `rm -rf temporary`, so per-sample
  > intermediates are deleted on a successful run. If you need them for debugging,
  > comment that line out before running.
- **Breaks:** R6 (one canonical place per idea), F5 — the "comment it out before running" instruction lives in full in § 5 (line 285) too
- **Reader impact:** The "comment out `rm -rf temporary` before your first run"
  instruction appears in Section 5 (operationally, where it must be acted on) and
  again in Section 10. Two copies of the same reasoning drift; the Section 10 copy
  is the one that will go stale.
- **Fix:** Keep Section 5 as the canonical instruction. Reduce Section 10's
  "The temporary directory" to a cross-reference plus the final-cleanup command:

  > CONCOMPRA deletes `temporary/` on a successful run. Section 5 covers commenting
  > that out before your first run to keep the per-sample intermediates for
  > debugging. Once your analysis is final, delete the directory yourself:
  >
  > ```bash
  > cd /nesi/nobackup/<your_nesi_project_code>/<your_project>/concompra/
  > rm -rf temporary/
  > ```
  >
  > Keep `directory_list.txt`, `primer_set.fa`, the SLURM scripts, `results/`, and
  > `concompra_for_R/`.

### S-12 · S4 · Post-processing script uses `=`-separated `#SBATCH`, breaking the one-style rule
- **Where:** SOP_CONCOMPRA_NeSI.md:419-426, § 7 job script
- **Anchor:** `#SBATCH --job-name=concompra_postprocess`
- **Quote:**
  > #SBATCH --job-name=concompra_postprocess
  > #SBATCH --account=<your_nesi_project_code>
  > #SBATCH --time=02:00:00
- **Breaks:** §8 (SLURM directives, one style throughout — space-separated), R11 (script consistency across the document)
- **Reader impact:** Section 5's script writes `#SBATCH --time 48:00:00`
  (space-separated); Section 7's writes `#SBATCH --time=02:00:00` (equals). Both
  submit, but the reader copying both now sees two conventions and cannot tell
  which the lab means, or whether the difference is load-bearing.
- **Fix:** Convert the Section 7 header to the space-separated style used
  everywhere else:

  > ```bash
  > #!/bin/bash
  > #SBATCH --job-name concompra_postprocess
  > #SBATCH --account <your_nesi_project_code>
  > #SBATCH --time 02:00:00
  > #SBATCH --mem 16G
  > #SBATCH --cpus-per-task 16
  > #SBATCH --output logs/postprocess_%j.out
  > #SBATCH --error logs/postprocess_%j.err
  > ```

  (For full parity with Section 5, also add `#SBATCH --chdir
  /nesi/nobackup/<your_nesi_project_code>/<your_project>` so the log paths do not
  depend on the submit directory; the current submit-from-run-dir approach works
  but is a second convention.)

### S-13 · S4 · Opening paragraph is 83 words (F1)
- **Where:** SOP_CONCOMPRA_NeSI.md:7, front matter
- **Anchor:** `This document covers the CONCOMPRA pipeline on NeSI Mahuika`
- **Quote:**
  > This document covers the CONCOMPRA pipeline on NeSI Mahuika: installation, run
  > configuration, submission, verification, post-processing (taxonomy, alignment,
  > phylogeny), and preparing outputs for R.
- **Breaks:** F1 (83 words > 80), R3 (this is the document's layer-1 summary and should stay tight)
- **Reader impact:** The scope statement — the first thing a scanner reads — packs
  the whole pipeline, the ordering dependency on Emu, and the R hand-off into one
  block, so the load-bearing "runs after, not instead of" fact is buried mid-run.
- **Fix:** Split into two paragraphs, no content lost:

  > This document covers the CONCOMPRA pipeline on NeSI Mahuika: installation, run
  > configuration, submission, verification, post-processing (taxonomy, alignment,
  > phylogeny), and preparing outputs for R. CONCOMPRA builds reference-free
  > consensus OTUs rather than aligning reads to a reference. Its outputs feed the
  > same R analysis (`SOP_R_Analysis.md`).
  >
  > It **runs after `SOP_EMU_NeSI.md`, not instead of it**: it takes that
  > pipeline's filtered reads as its input, builds its SILVA SINTAX database from
  > the Emu SILVA bundle installed there, and uses the Emu taxonomy as its only
  > validation check.

### S-14 · S4 · Wrapper-script explanation is 87 words (F1)
- **Where:** SOP_CONCOMPRA_NeSI.md:324, § 5
- **Anchor:** `takes no command-line arguments`
- **Quote:**
  > `main.sh` takes no command-line arguments; it `source`s `directory_list.txt`
  > and reads `primer_set.fa` from the working directory, which `--chdir` has set
  > to `concompra/`.
- **Breaks:** F1 (87 words > 80), R11 (script-behaviour explanation; keep the load-bearing facts, drop the restatement)
- **Reader impact:** A single 87-word block restates several facts the reader can
  see in the script, obscuring the two that matter: the job needs nothing from
  the login shell, and the wrapper's `set -euo pipefail` does not govern
  `main.sh` — which is *why* Section 6 verifies on disk.
- **Fix:** Split and tighten to two paragraphs, keeping both load-bearing facts:

  > `main.sh` takes no arguments: it `source`s `directory_list.txt` and reads
  > `primer_set.fa` from the working directory, which `--chdir` set to
  > `concompra/`. `bash ./main.sh` runs your edited copy — the one with `rm -rf
  > temporary` commented out — not the repo copy. It finds its sub-scripts through
  > `TEMPLATE_DIR`, so the job needs nothing from your login shell.
  >
  > The wrapper's `set -euo pipefail` guards its own setup only. `main.sh` runs as
  > a separate process and keeps its own deliberately lenient error handling —
  > which is why Section 6 verifies the outputs on disk rather than trusting the
  > exit code.

### S-15 · S4 · Omnibus: minor form and tightening (F3 prose-lists, optional side-path, list spacing)
- **Where:** SOP_CONCOMPRA_NeSI.md:112-122, 183-185, 601 (representative)
- **Anchor:** `An optional activation alias for`
- **Quote:**
  > An optional activation alias for `~/.bashrc`:
- **Breaks:** F3 (enumerable runs left as prose), R4 (optional setup side-path weighted like the main path)
- **Reader impact:** Individually small; together they cost the scanner a little
  each time. None blocks.
- **Fix:** Apply as tidy-ups, no content removed:
  - **L601** ("Other causes: a mis-configured `directory_list.txt` ...; primer
    headers not named `head`/`tail` ...; or too few reads per sample ...") — recast
    the three causes as a bulleted list, each keeping its cross-reference.
  - **L183-185** ("Record run metadata": flowcell/chemistry; basecaller/model;
    interrupted/restarted; duplicate-screen result) — the four items are already
    semicolon-separated; make them four bullets.
  - **L112-122** (optional `~/.bashrc` alias + `PYTHONNOUSERSITE`) — prefix the
    heading with "**Optional —**" so this convenience side-path is not read as a
    required step.
  - **L15-17** (the "Before you start" bullets) — they run with no blank line
    between, so the form scan reads them as one 138-word block; a blank line
    between bullets removes the false positive and reads no differently.

## Target outline

The finished document, in order. `KEEP` = exists, unchanged; `REWRITE`/`NEW`
annotated with what it must hold and rough length.

```
*Taylor Lab | Consensus OTUs from Nanopore 16S*
# **CONCOMPRA Pipeline: Consensus OTUs on NeSI**
**v2.1** | last updated <Month Year> | NeSI (SLURM) | Oxford Nanopore full-length 16S

Intro paragraph          REWRITE (split per S-13; two paras, ≤80w each)
### Before you start      KEEP (add blank lines between bullets, S-15)
## Quick Roadmap          KEEP

## 1. Understanding your data   REWRITE from "Overview" (S-01)
    NEW layer-1 concept prose (~280w, in ≤80w paras + one 4-item bullet list):
    defines OTU, reference-free/de novo, clustering (UMAP/OPTICS, one plain line),
    consensus, dereplication, chimera; one line each on SINTAX/MAFFT/FastTree as a
    forward pointer to §7. KEEP the Emu-vs-CONCOMPRA table and the "run both" line.

## 2. Installation        REWRITE intro (S-05: one ~65w conda-environment gloss)
    ### Locations                 KEEP
    ### Clone the repository       KEEP
    ### Build the conda environment  KEEP + NEW runtime line (S-06, ~2 lines)
    ### Verify the environment     KEEP + NEW mismatch clause (S-06); mark alias "Optional" (S-15)
    ### SILVA SINTAX database      KEEP (SINTAX now defined in §1)

## 3. Pre-flight: Screen for Duplicate Reads   KEEP
    ### Screen / Deduplicate       KEEP
    ### Record run metadata        KEEP (bulletise the 4 items, S-15)

## 4. Run Configuration   KEEP
    ### Directory layout           KEEP (drop phantom 03_dedup.sh, S-10)
    ### Symlink / Run configuration file / Primer file / Threads   KEEP

## 5. Submitting the Run  KEEP (split L324, S-14)

## 6. Verifying the Run   KEEP
    ### Per-sample verification / Output files / Cross-check   KEEP
    (fix the "chimera-detection settings" pointer in Output files, S-09)

## 7. Post-processing: Taxonomy, Alignment, Phylogeny   KEEP
    NEW conceptual lead-in after the heading (S-03, 3-bullet layer-1)
    (job script)                   KEEP + REWRITE headers to space-separated (S-12)
    ### Notes on the steps         KEEP + gloss GTR/bootstrap/supports (S-04)
    ### Verifying the outputs      KEEP

## 8. Preparing for R / phyloseq   KEEP
    ### The R-ready folder            KEEP
    ### Building it                   KEEP
    ### Checking sample IDs           KEEP
    ### Building the phyloseq object  KEEP (gloss ASV, S-07; name the prv_cut default, S-08)

## 9. Troubleshooting     KEEP (bulletise "Other causes", S-15)

## 10. Maintenance        KEEP
    ### Updating CONCOMPRA         KEEP
    ### The temporary directory    REWRITE to cross-ref §5 (S-11)

## Appendix A: SILVA SINTAX Database Build   KEEP
    ### The reformatter            KEEP
    ### Build                      REWRITE (resolve Emu path, S-02)
    ### Refreshing for a new SILVA release   KEEP

## Appendix B: References  KEEP
```

Net effect: one new concepts section (~280w) and roughly eight one-to-three-line
glosses added; two over-length paragraphs split (net-neutral) and one duplicated
passage trimmed. The document grows by the missing layer, as the spec intends;
nothing is cut.

## Keep list

Content a restructure must not lose (anchored). All are layer-2 "why" or
silent-failure content — the document's real value.

1. **Verify on disk, not the `.out` log** — `main.sh` logs "consensus sequences
   generated" even on silent failure. Anchor: `never from the` (roadmap L45),
   restated L249, L338. The spine of the whole document.
2. **`MIN`/`MAX` unset drops every read silently.** Anchor: `the filter drops
   **every** read, silently`. (R7 default + silent failure)
3. **filtlong aborts on duplicate read names; version is pinned — do not
   downgrade.** Anchor: `Do not replace or downgrade filtlong`.
4. **Screen read *names* only, not whole headers.** Anchor: `Compare read *names*
   only`. Why the dedup screen keys on the first field.
5. **Primer must be the forward-strand (sense) sequence, not the
   reverse-complement.** Anchor: `not the reverse-complement`. Wrong orientation →
   empty funnel.
6. **`THREADS` sets both outer and inner parallelism; test before committing.**
   Anchor: `both outer parallelism`. The "why this number" for THREADS.
7. **Retention expectation: ~45% survive primer-chop, filtlong keeps top 80%, so
   80k → ~29k.** Anchor: `enters clustering with roughly 29,000`.
8. **Keep `temporary/`: comment out `rm -rf temporary` before the first run.**
   Anchor: `kept for Section 6`. Localises a silent failure to a step.
9. **SINTAX: take column 4, not column 2 — column 2 silently corrupts genus and
   species.** Anchor: `silently corrupts taxonomy at low-confidence ranks`.
10. **The 0.8 SINTAX cutoff rationale.** Anchor: `standard SINTAX bootstrap
    threshold`. Why this number (keep even as S-04 glosses it).
11. **Strip `.CONCOMPRA` and `_filtered` suffixes or joins break and Emu/CONCOMPRA
    cannot be compared sample-by-sample.** Anchor: `one metadata sheet cannot serve
    both pipelines`.
12. **CONCOMPRA counts are already integers; `prv_cut` may discard genuine rare
    taxa.** Anchor: `often genuine rare taxa`. The Part-2 adaptation notes.
13. **Point post-processing at the project-directory UDB, not a `nobackup` copy
    (purged).** Anchor: `not a copy under`.
14. **Strip the `defaults` channel and use Miniforge, not Miniconda.** Anchor:
    `re-adds the `. Why the install succeeds at all.

## Rewrite plan

Ordered, dependency-aware. Every item is internal to this file — none depends on
another SOP being edited first, except S-02, which references (does not edit)
the Emu SOP's database path.

1. **§1 → "Understanding your data" (S-01).** The keystone; do it first because
   §2, §7 and §8 glosses forward-reference it. Adds ~280w. Independent.
2. **§7 lead-in (S-03) + Step 2/4 glosses (S-04).** Adds the second-biggest
   concept gap. Depends on nothing; smoother if §1 lands first so the tool names
   are already introduced. ~120w added.
3. **§2 conda intro (S-05) + build runtime and verify mismatch (S-06).** Closes
   the install-layer gaps. ~90w added. Independent.
4. **§8 ASV gloss (S-07) + prv_cut default (S-08).** Two sentence-level edits.
   Independent.
5. **Appendix A Emu path (S-02).** One code-block edit; needs the reader to know
   the Emu SILVA directory but changes only this file. Independent.
6. **§6 chimera pointer (S-09); §5↔§10 temporary merge (S-11); §4 tree phantom
   (S-10).** Three small shape fixes. Independent.
7. **Form pass: split L7 (S-13) and L324 (S-14); §7 SLURM style (S-12); omnibus
   tidy-ups (S-15).** Do last, after prose settles, then re-run the scan to
   confirm 0 over-80 paragraphs and the heading census shows layer-1 > 0.

After the rewrite, both spec gates must hold: layer-1 heading count has gone from
0 to ≥1 (the new §1), and the over-80 count has gone from 2 to 0 (S-13, S-14
split; the new material is written in ≤80w paragraphs and bullets).

## Self-check

Automated (the harness script from AGENT PROMPT A):

```
findings=15 S1=2 S2=7 S3=2 S4=4
CLEAN
```

Form scan (`scan_CONCOMPRA.py SOP_CONCOMPRA_NeSI.md`):

```
101 paragraphs, 3 over 80 words
  L15     138w  - **A NeSI account and project code**, and enough bash and S...
  L324     87w  `main.sh` takes no command-line arguments; it `source`s `dir...
  L7       83w  This document covers the CONCOMPRA pipeline on NeSI Mahuika:...
```

L15 is a scan artefact: the three "Before you start" bullets (L15–L17) carry no
blank line between them, so the scanner merges them into one 138-word block; each
bullet is well under 80 words. The two genuine F1 hits are **L7 (83w)** and
**L324 (87w)**, matching the baseline of 2 — both are closed by S-13 and S-14.

By-hand confirmation:
- **Ledger accounts for every heading** — every `##`/`###` in the source, plus the
  front-matter intro paragraph, has a row. PASS.
- **Target outline covers every ledger section** — one-to-one, same order. PASS.
- **Nothing on the keep list is proposed for removal** — every keep-list item is
  KEEP or REWRITE-TIGHTER; the two edits that touch keep-list content (S-11 merge
  keeps §5's canonical instruction; S-04 glosses but retains the 0.8-cutoff
  rationale) preserve it. PASS.

**CONTRACT: PASS**

