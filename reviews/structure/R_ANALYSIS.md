## Document: SOP_R_Analysis.md

Part 2 — count tables to results in R. 1208 lines. Runs locally on the reader's
own machine (correctly, per lab policy); the R packages are unverifiable from
NeSI by design, not a gap (see `reviews/structure/00_REALITY.md`).

## Verdict against the specification

This is the strongest document in the set on *why* and the weakest on *what*.
Its layer-2 content is exceptional — the silent-failure guards (positional index
mismatch, stale `ps_raw`, `ps_raw`/`ps_srs` mixing, the figure-vs-text p-value
trap, `pairwise.adonis2` swallowing `p.adjust.m`, FDR-on-the-filtered-subset) are
the best content in the repository and must not thin. But it opens straight into
a 30-line install block with no concept section in front of it, front-loads a
dozen undefined terms in the roadmap and Key-objects table (`SRS`, `Cmin`, `PCoA`,
`PERMANOVA`, `Aitchison`, `rCLR`, `ANCOM-BC2`…), never says what `phyloseq` *is*,
never defines the decontam `prevalence method` it selects, and gives **no runtime
on any step** — so a beginner watching a silent 30-minute Bioconductor install or
a multi-minute `ancombc2()` call cannot tell a working job from a hung one. The
§2 heading census is the core defect: ~1 layer-1 heading across 1208 lines. The
fix is structural (add a concepts-only "Understanding your data" section, a
"Before you start" block, and an Appendices back-matter), not more prose — the
6 over-80 paragraphs must come *down* while layer-1 headings go up.

| Rule | Pass / Partial / Fail | One-line evidence |
| --- | --- | --- |
| R1 both layers, in order | Partial | Layer 2 everywhere; layer 1 often absent or late (`phyloseq`, roadmap terms). |
| R2 nothing used before introduced | **Fail** | `prevalence method`, `phyloseq`, `CLR`/`rCLR`, `lfc`, `PCoA`/`PERMANOVA`/`Aitchison` all used before (or without) definition. |
| R3 concepts before commands | Partial | Section 1 opens on the install block; no concepts-only opener. Alpha/Beta/DA subsections do open with prose. |
| R4 setup where needed | Partial | All packages front-loaded up top incl. rarely-used mixed-model set; no file-transfer step from NeSI. |
| R5 every step states outcome | **Fail** | Zero runtimes anywhere; only one formal checkpoint (the `ps_raw` sanity print). |
| R6 one numbered spine | Partial | `## 1`/`## 2` sections vs "Stage 1–5" vs "Step 1–6"; Key-objects table cites "Section 1 Step 1" imprecisely. |
| R7 every fork has a default | Partial | SRS, PCoA, `holm` all defaulted with reasons; decontam `prevalence` chosen with no reasoning. |
| R8 plain words first, jargon second | Partial | Often good; several terms lead with jargon (`rCLR`, `CLR`, `EM-estimated`). |
| R9 one voice | Partial | `we`/`you` split is consistent; a few `simply`/`just`/`merely` (V3). |
| R10 explain the failure | **Pass** | The document's strength — must not thin under restructure. |
| R11 every script complete/runnable | **Pass** | R blocks are self-contained; install block bootstraps `BiocManager`/`devtools` before use. |
| F1 no paragraph over 80 words | **Fail** | 6 genuine prose paragraphs + 1 bullet over 80 (scanner reports 12; 5 are bullet-list aggregations). |
| F2 definition is 1–2 sentences | Partial | `neg_lb` bullet is a 112-word definition. |
| F3 enumerable → table/list | Partial | Many tables already; PERMANOVA "how it works" steps (1)–(4) buried in prose. |
| F4 point first, bold what scans | **Pass** | Strong bold run-ins; point-first blocks. |
| F5 the "why" is separable | **Pass** | Layer 2 sits in skippable run-ins and bullets. |

## Jargon table

Every term a never-opened-a-terminal grad student would not know. "Defined at"
is where a plain-language gloss actually appears; a line number earlier than
"First used" or a dash is an R2 finding.

| Term | First used | Defined at | Verdict |
| --- | --- | --- | --- |
| count table | L7 (intro) | L104 | Partial — used in intro/roadmap before L104 gloss. |
| taxonomy table | L15 | L105 | OK. |
| metadata | L15 | L106 | OK. |
| `phyloseq` (package + object) | L21 | L273 (partial) | **Fail** — never says what phyloseq *is*; only "bundles … into one object" 250 lines later. |
| Decontam / `decontam` | L21 | L240 | OK — defined at first real use. |
| `SRS` | L28 (roadmap) | L391 | **Fail (R2)** — abbreviation in roadmap + install before expansion at L391. |
| `Cmin` | L28 | L393 | **Fail (R2)** — used in roadmap before def; named-offender class. |
| `ps_raw` / `ps_srs` | L21/L28 | L49–51 (table) | OK — table defines both, but see front-load finding S-05. |
| rarefaction / rarefying | L27 | L384–388 | OK — the distinction is explicitly drawn. |
| Alpha diversity | L31 | L473 | OK — concept opener. |
| Beta diversity | L32 | L580 | OK — concept opener. |
| `PERMANOVA` | L38 | L794 | Partial — mechanism at L794; acronym never expanded, used at L38/L52 first. |
| differential abundance / `DA` | L34 / L55 | L946/L950 | Partial — `DA` abbrev in Key-objects table before concept section. |
| indicator species | L35 | L1108 | OK. |
| `OTU` | L7 | — | Minor — never expanded here (upstream term). |
| `Bray-Curtis` | L51 (table) | L588 | Partial — named in Key-objects table before def. |
| `Aitchison` distance | L49 (table) | L594 | **Fail (R2)** — table + L389 rationale before def at L594. |
| `PCoA` | L52 (table) | L615 | Partial — table before def; acronym expanded L615. |
| `betadisper` / dispersion | L54 (table) | L695 | Partial — table before def. |
| `CLR` (Centred Log-Ratio) | L389 | L397 | **Fail (R2)** — used in Schloss rationale before def 8 lines later. |
| `rCLR` / robust CLR | L389 | L397/L605 | **Fail (R2)** — named offender; abbrev leads the jargon. |
| `TSS` / `CSS` | L399/L401 | L399/L401 | OK — defined at introduction. |
| compositionality | L380 | L954 | Partial — parenthetical at L380, worked example L954. |
| zero-inflation | L380 | — | Minor — named, never defined. |
| `prevalence method` (decontam) | L249 | — | **Fail (R2/R7)** — named offender; used with no definition and no reason vs the frequency method. |
| `EM-estimated` floats | L151 | — | Minor (R2) — "EM" never expanded. |
| `lfc` (log fold change) | L206 | L1013 | **Fail (R2)** — used to justify factor-level naming 800 lines before def. |
| FDR / BH / Benjamini-Hochberg | L495 (`BH`) | L952 | Partial — `BH` in code before FDR/BH expansion at L952. |
| omnibus test | L483 | L483 (context) | OK-ish — glossed by context. |
| structural zeros | L973 | L973 | OK. |
| Wilcoxon / Kruskal-Wallis | L483 | L483 | OK. |
| NMDS | L616 | L616 | OK. |
| IndVal | L1115 | L1115 | OK. |

`CPM` and `stratified` (named in R2) do **not** appear in this document — they are
READBASED terms. Confirmed by grep.

## Section ledger

| § | Heading | Lines | Treatment | Findings |
| --- | --- | --- | --- | --- |
| — | Title + version + intro | 1–9 | CLEAN | — |
| — | (missing) Before you start | — | ADD-LAYER-1 | S-08 |
| A | Quick Roadmap: What You'll Do | 13–38 | ADD-LAYER-1 (front-loads terms) | S-05 |
| B | Key objects you'll work with | 40–57 | MOVE (into Understanding-your-data) | S-05, S-11 |
| 1 | Analysis of Amplicon/Count Data in R | 61–63 | SPLIT / ADD-LAYER-1 | S-09 |
| 1.0 | Installing and loading libraries | 65–98 | ADD-OUTCOME / MOVE | S-01, S-05 |
| 1.1 | Stage 1: Loading and preparing data | 100–236 | ADD-OUTCOME / TIGHTEN | S-03, S-07 |
| 1.2 | Stage 2: Decontamination + build ps_raw | 238–305 | ADD-LAYER-1 / ADD-OUTCOME | S-02, S-04 |
| 1.3 | Stage 3: Exploring your data | 307–374 | CLEAN | — |
| 1.4 | Stage 4: Normalisation | 376–465 | MOVE-REF / TIGHTEN | S-06, S-12, S-17 |
| 1.5 | Stage 5: Analysis | 467–469 | CLEAN | — |
| 1.5a | Alpha diversity | 471–576 | TIGHTEN | S-15 |
| 1.5b | Beta diversity | 578–583 | CLEAN | — |
| 1.5b-1 | Step 1: Distance matrices | 584–607 | TIGHTEN | S-19 |
| 1.5b-2 | Step 2: Ordination | 609–691 | CLEAN | — |
| 1.5b-3 | Step 3: Check dispersion | 693–790 | TIGHTEN | S-16 |
| 1.5b-4 | Step 4: PERMANOVA | 792–837 | SPLIT (prose enum) | S-18 |
| 1.5b-5 | Step 5: Pairwise PERMANOVA | 839–874 | CLEAN | — |
| 1.5b-6 | Step 6 (optional): Jaccard | 876–907 | CLEAN | — |
| 1.5c | Taxonomy barplots | 909–944 | CLEAN | — |
| 2 | Going Further in R | 946–948 | REWRITE (renumber) | S-11 |
| 2.1 | Why you can't just test each taxon | 950–967 | REWRITE-VOICE | S-14, S-21 |
| 2.2 | Differential abundance with ANCOM-BC2 | 969–1023 | TIGHTEN | S-20 |
| 2.3 | Differential abundance with MaAsLin2 | 1025–1100 | CLEAN | — |
| 2.4 | A note on ALDEx2 | 1102–1104 | MERGE (demote) | S-13 |
| 2.5 | Indicator species analysis | 1106–1156 | CLEAN | — |
| 2.6 | Figures | 1158–1167 | MOVE (to appendix/reprod) | — |
| 2.7 | Reproducibility | 1169–1177 | CLEAN | — |
| 3 | Common Pitfalls to Avoid | 1179–1207 | ADD (Troubleshooting/Appendices) | S-10 |

## Findings

### S-01 · S1 · No runtime on any step; slow installs and models look hung
- **Where:** SOP_R_Analysis.md:65-98, §1 Installing and loading libraries (also L977-996 ANCOM-BC2, L813-827 PERMANOVA, L684-689 NMDS)
- **Anchor:** `Install packages (only need to do this once)`
- **Quote:**
  > # Install packages (only need to do this once)
  > install.packages(c("tidyverse", "vegan", "ggpubr", "EnvStats", "SRS",
- **Breaks:** R5 (§4 item 4 — every step states how long it takes), F4
- **Reader impact:** The Bioconductor install of `phyloseq`, `ANCOMBC`, `Maaslin2`
  et al. can run 20–40 minutes with long silent stretches and occasional compile
  chatter. A beginner with no "this takes X" note assumes it has frozen, kills it,
  and is left with a half-installed, broken package set that then errors
  cryptically three sections later. The same is true of `ancombc2()` with
  `pairwise = TRUE, pseudo_sens = TRUE` (minutes on real data), `adonis2()` with
  9,999 permutations, and NMDS at `trymax = 999`. Not one carries a runtime.
- **Fix:** Add a runtime line under the install block and each slow call. Under the
  install block (after L98):
  > **How long.** The CRAN packages install in a few minutes. The Bioconductor
  > block (`phyloseq`, `ANCOMBC`, `Maaslin2`, `ALDEx2`, `mia`) is the slow one — 20
  > to 40 minutes on a first run, with long silent pauses while packages compile.
  > That is normal; do not interrupt it. You only run this block once.
  Add inline, before the `ancombc2()` call (L977): `# Runtime: seconds on a toy
  set, several minutes with pairwise + sensitivity on real data — let it run.`
  Before `adonis2()` (L813): `# Runtime: 9,999 permutations take a few seconds to
  ~a minute.` Before NMDS (L685): `# Runtime: trymax=999 can take a minute or two;
  it is iterating, not stuck.`

### S-02 · S1 · decontam "prevalence method" chosen with no definition and no reason
- **Where:** SOP_R_Analysis.md:249-251, §1 Stage 2
- **Anchor:** `Run decontam (prevalence method). isContaminant expects samples as ROWS,`
- **Quote:**
  > # Run decontam (prevalence method). isContaminant expects samples as ROWS,
  > # so transpose counts_raw (which is taxa × samples).
  > contam_df <- isContaminant(t(counts_raw), neg = is_blank, method = "prevalence")
- **Breaks:** R2 (`prevalence method` — a named R2 offender — used with no definition), R7 (fork with no reasoned default), R8
- **Reader impact:** `decontam` offers two methods — `frequency` (needs per-sample
  DNA concentrations) and `prevalence` (uses presence/absence patterns in blanks
  vs samples). The document picks `prevalence` silently. A beginner has no idea
  what the prevalence method *does*, why it was chosen, or that a `frequency` run
  would need data they may have. They run it on faith and cannot judge whether the
  contaminant calls are trustworthy — and choosing the wrong method produces a
  wrong contaminant list with no error.
- **Fix:** Insert before the code block (after L242):
  > **What "prevalence" means here.** `decontam` has two ways to spot a
  > contaminant. The *frequency* method needs the DNA concentration of every
  > sample and flags taxa whose abundance rises as input DNA falls. The
  > *prevalence* method needs no concentrations: it flags taxa that appear more
  > consistently in your blanks than in real samples. **We use prevalence** because
  > most labs do not have per-sample DNA quantitation, and negative controls are
  > always available. Use `frequency` only if you recorded a concentration for
  > every sample.

### S-03 · S1 · No step to move the count tables from NeSI onto the local machine
- **Where:** SOP_R_Analysis.md:124-130, §1 Stage 1
- **Anchor:** `Read in the combined counts table (from combine_emu_results.py)`
- **Quote:**
  > setwd("~/path/to/your/files")
  >
  > # Read in the combined counts table (from combine_emu_results.py)
- **Breaks:** R4 (setup happens where it is needed), R5, R2
- **Reader impact:** Every upstream pipeline (Emu, CONCOMPRA, MetaPhlAn) produces
  its count table *on NeSI*, but Part 2 runs on the reader's own laptop. Nothing
  in the document tells them to copy the file across. A beginner who has just
  finished Part 1 on the cluster reaches `read.table("emu-combined-counts_silva.tsv"…)`
  with the file still sitting on NeSI, R cannot find it, and they stop — this is
  the first command in the analysis and the first place a clean run derails.
  (This sits on the Part 1 → Part 2 seam; a cross-file agent may also own it —
  flag for dedupe, but the gap is real inside this document.)
- **Fix:** Add to the new "Before you start" block, and echo one line above L124:
  > **Get your files onto this machine first.** The count table, taxonomy and
  > metadata are produced on NeSI; this document runs locally. Copy them down
  > before you start — from a terminal on your own machine:
  > `scp <username>@login.mahuika.nesi.org.nz:/nesi/project/<your_nesi_project_code>/…/emu-combined-counts_silva.tsv .`
  > (or drag them across in the NeSI JupyterHub file browser). Point `setwd()` at
  > the folder you put them in.

### S-04 · S2 · phyloseq is used throughout but never defined as what it is
- **Where:** SOP_R_Analysis.md:273-280, §1 Stage 2
- **Anchor:** `This bundles counts, taxonomy, and metadata into one object.`
- **Quote:**
  > **Build `ps_raw`, your raw-counts phyloseq object.** This bundles counts,
  > taxonomy, and metadata into one object. When you subset samples or remove taxa
  > later, all three tables stay synchronised.
- **Breaks:** R1 (layer 2 without layer 1), R2 (`phyloseq` used from L21)
- **Reader impact:** `phyloseq` drives the whole document — nearly every function
  takes or returns one — yet the reader is never told it is an R package (which
  they installed at the top) *and* a data container that is the standard object
  for microbiome data. They meet `phyloseq(otu_table(...), tax_table(...),
  sample_data(...))` at L276 as three unexplained function calls, build `ps_raw`
  by rote, and cannot reason about why `ps_raw` and `ps_srs` are separate objects
  or what `sample_data(ps_srs)$Site` is reaching into later.
- **Fix:** Add a one-sentence layer-1 gloss the first time phyloseq appears in a
  concept section (in the new "Understanding your data" section), and keep L273:
  > **phyloseq** is both an R package and the object type it gives you: a single
  > container holding your count table, taxonomy and metadata together, so that
  > subsetting or filtering keeps all three in step. Every analysis below reads
  > from one of two such objects, `ps_raw` and `ps_srs`.

### S-05 · S2 · Roadmap and Key-objects table front-load a dozen undefined terms
- **Where:** SOP_R_Analysis.md:40-57, Key objects table (and roadmap L17-36)
- **Anchor:** `Consistent naming is what lets you copy code between sections without breaking things.`
- **Quote:**
  > The same objects appear throughout. Consistent naming is what lets you copy
  > code between sections without breaking things.
- **Breaks:** R2 (first appearance carries the definition), R3 (concepts before commands)
- **Reader impact:** Before any definition exists, the roadmap and this table name
  `SRS`, `Cmin`, `PCoA`, `PERMANOVA`, `Aitchison`, `Bray-Curtis`, `betadisper`,
  `ANCOM-BC2`, `MaAsLin2`, `ALDEx2` and `DA`. A scanner (the spec's assumed reader)
  meets ten acronyms in the first screen with nothing to anchor them, and either
  bounces or proceeds with a fog of half-guessed terms that never lifts because
  the definitions are scattered hundreds of lines downstream.
- **Fix:** The table itself is valuable and stays — but it must be *preceded* by
  the concepts-only "Understanding your data" section (S-09) that defines the core
  terms (count table, taxonomy, metadata, phyloseq, `ps_raw` vs `ps_srs`,
  compositionality) in plain words first. Move this Key-objects table to sit at
  the end of that new section, so every term in it has already been met. No new
  words in the table; the fix is ordering.

### S-06 · S2 · CLR / rCLR / Aitchison used in the rarefaction rationale before they are defined
- **Where:** SOP_R_Analysis.md:389, §1 Stage 4
- **Anchor:** `the standard CLR/Aitchison distance, despite being theoretically compositionally correct`
- **Quote:**
  > He also found that the standard CLR/Aitchison distance, despite being
  > theoretically compositionally correct, remained strongly sensitive to
  > sequencing depth on real, sparse data. … we use the robust (rCLR) variant …
- **Breaks:** R2 (`CLR`, `rCLR`, `Aitchison` — `rCLR` is a named offender), R8 (jargon before plain words)
- **Reader impact:** This paragraph turns on `CLR`, `rCLR` and `Aitchison distance`,
  but `CLR` is not defined until L397 and `Aitchison` not until L594. A beginner
  hits the load-bearing caveat ("Aitchison still tracks depth, so we use rCLR")
  before they know what any of the three transformations are, so the caution — one
  of the document's best judgement calls — lands as noise.
- **Fix:** Add a one-line forward gloss at first mention (edit L389, first
  sentence of the clause):
  > … the standard CLR/Aitchison distance (CLR = centred log-ratio, the transform
  > behind Aitchison distance; both defined under Step 1 below) …
  and add "(defined below)" is not enough on its own — pair it with reordering so
  the SRS/CLR/TSS method definitions at L391-401 sit *before* this Schloss
  paragraph, which currently justifies a choice using terms it has not yet named.

### S-07 · S2 · `lfc` used to justify factor-level naming 800 lines before it is defined
- **Where:** SOP_R_Analysis.md:206, §1 Stage 1
- **Anchor:** `ANCOM-BC2 builds its output column names by pasting the variable name onto the level`
- **Quote:**
  > **Avoid spaces and punctuation in factor levels.** ANCOM-BC2 builds its output
  > column names by pasting the variable name onto the level (`lfc_SiteZealandia`),
  > so a level like `Young Nicks Head` produces …
- **Breaks:** R2 (`lfc` used here, defined at L1013)
- **Reader impact:** This is a keeper warning (silent breakage from spaces in
  factor levels), but it explains the danger using `lfc_SiteZealandia` — and `lfc`
  (log fold change) is not defined until the ANCOM-BC2 output section 800 lines
  later. The reader sees an unexplained column name and cannot tell whether they
  should care, weakening a warning they genuinely need to act on now.
- **Fix:** Gloss `lfc` in place (edit L206):
  > … ANCOM-BC2 builds its output column names by pasting the variable name onto
  > the level (e.g. `lfc_SiteZealandia`, the log fold change for Zealandia) …

### S-08 · S3 · No "Before you start" block; prerequisites and scope are scattered
- **Where:** SOP_R_Analysis.md:5-11, header
- **Anchor:** `Adapt all variable names to your own metadata.`
- **Quote:**
  > The examples use Cam's tuatara PhD data … Adapt all variable names to your own
  > metadata.
- **Breaks:** R4 (setup/prerequisites), R5 (scope limits belong up front, §3 template)
- **Reader impact:** The §3 template requires a "Before you start" block — what you
  need, what this does not cover, where to go if you lack the prerequisites. Here
  that information is dispersed: R-runs-locally is only in the version line, the
  input contract is buried in Stage 1, and "what this does not cover" (no
  DADA2/ASV upstream, no assembly, parallel designs only) is split between the
  intro and a roadmap aside. A reader cannot, in one glance, tell whether this
  document is for them or what they must have ready.
- **Fix:** Insert after the intro (after L9), before the roadmap:
  > ### **Before you start**
  >
  > - **You need R on your own machine.** Part 2 runs locally, not on NeSI.
  >   Install a current R (RStudio is the usual front end) and run the package
  >   block in Section 2 once — it is slow, so do it before you need it.
  > - **You need three files, already on this machine:** an integer count table,
  >   a taxonomy table (or ranks inside the count table) and a metadata file with
  >   a `SampleType` column. Sample IDs must match byte-for-byte across them. See
  >   "Get your files onto this machine" below for copying them off NeSI.
  > - **What this does not cover.** Producing the count table (see Part 1 for
  >   Nanopore, `SOP_READBASED_NeSI.md` for Illumina shotgun); short-read ASV
  >   workflows (DADA2); non-independent designs beyond the pointers given
  >   (repeated measures, nested, co-housed — see Common Pitfalls).
  > - **If you have no count table yet,** stop here and start with Part 1.

### S-09 · S3 · Section 1 opens on the install block; no concepts-only "Understanding your data" section
- **Where:** SOP_R_Analysis.md:61-67, §1
- **Anchor:** `move to R for statistical analysis and visualisation`
- **Quote:**
  > With your count table and taxonomy table from Emu, move to R for statistical
  > analysis and visualisation. … [next line is a code fence]
- **Breaks:** R3 (a section introducing new tooling opens with prose, no commands), R1, R6 (§3 template: "## 1. Understanding your data — concepts only")
- **Reader impact:** This is the central §2 heading-census defect: the whole 1208
  lines carry ~1 layer-1 heading. Section 1 is titled "Analysis of Amplicon/Count
  Data in R" but its first content is a 30-line `install.packages`/`BiocManager`
  block — commands before any concept. The reader is asked to install and load a
  dozen packages before being told what a phyloseq object is, what compositional
  data is, or why counts (not proportions) are required. There is nowhere that
  answers "what IS this?" before the doing starts.
- **Fix:** Add a concepts-only section (no commands) as the new Section 1, ahead of
  the install block. It absorbs and consolidates content that already exists but is
  scattered: the input contract (L108-114), the phyloseq gloss (S-04), the
  `ps_raw`/`ps_srs` rule (L57), and a two-sentence compositionality primer drawn
  from L954. Roughly 250 words, net-neutral because it is mostly relocation:
  > ## **1. Understanding your data**
  >
  > Before any code, three things to hold in your head. **(1) Your data is a table
  > of counts** — taxa in rows, samples in columns, one integer per cell: how many
  > reads of each taxon in each sample. **(2) Those counts are compositional** —
  > each sample has a fixed read total, so a taxon's count is really its *share* of
  > that sample, not an absolute cell count; if one taxon rises, the others must
  > fall even when nothing about them changed. This single fact drives every
  > normalisation and test choice below. **(3) Everything is bundled in a phyloseq
  > object** [S-04 gloss] … The two you will build are `ps_raw` (raw counts) and
  > `ps_srs` (depth-normalised); **use `ps_raw` for differential abundance and
  > Aitchison distance, `ps_srs` for alpha diversity and Bray-Curtis — mixing them
  > gives wrong answers with no error.** [then the Key-objects table, moved here.]

### S-10 · S3 · No Troubleshooting or Appendices back-matter; citations sit inline mid-walkthrough
- **Where:** SOP_R_Analysis.md:1179-1207, Common Pitfalls
- **Anchor:** `Common Pitfalls to Avoid`
- **Quote:**
  > ## **Common Pitfalls to Avoid**
- **Breaks:** R3 (reference material lives at the back), R6 (§3 template: Troubleshooting, Appendices)
- **Reader impact:** The §3 template ends with Troubleshooting and Appendices.
  This document has neither. "Common Pitfalls" is a strong conceptual list but is
  not symptom→cause→fix troubleshooting, and there is no back-matter for the things
  a reader looks up rather than performs: primary citations (Schloss L384,
  McMurdie & Holmes L384, Nearing L1035, Dufrêne & Legendre L1115) are scattered
  through the walkthrough, and the threshold/resource figures (depth floor 1000,
  `prv_cut` 0.10, Cmin, stress cutoffs, IndVal 0.5) are spread across sections with
  no single lookup.
- **Fix:** Add an "## Appendices" back-matter section with three tables — A:
  References (the five primary citations, grouped), B: the normalisation-methods
  catalogue moved from S-12, C: a threshold table (depth floor, `prv_cut`,
  `lib_cut`, Cmin rule, NMDS stress bands, IndVal strength). Keep "Common Pitfalls"
  but retitle the tail "## Troubleshooting and common pitfalls" so a stuck reader
  knows to look there. This is relocation, not new content.

### S-11 · S3 · Numbering collision: sections vs "Stage" vs "Step"; imprecise cross-references
- **Where:** SOP_R_Analysis.md:52-55, Key objects table
- **Anchor:** `Distance matrices | Section 1 Step 1`
- **Quote:**
  > | `dist_bray`, `dist_ait` | dist | Distance matrices | Section 1 Step 1 | PCoA, PERMANOVA, betadisper |
- **Breaks:** R6 (one numbered spine; a bare number means the current document)
- **Reader impact:** The document has two top-level numbered sections (`## 1`,
  `## 2`), but the workflow inside `## 1` is labelled "Stage 1–5", and Beta
  diversity is labelled "Step 1–6". The Key-objects table then cites "Section 1
  Step 1/2/3" — which actually means Section 1 → Stage 5 → Beta diversity → Step 1,
  three levels down. A reader trying to follow the cross-reference cannot find
  "Section 1 Step 1" because no such heading exists at that level.
- **Fix:** Adopt one spine: renumber the "Stages" as top-level sections in run
  order (see Target outline — Understanding, Install, Load, Decontam, Explore,
  Normalise, Alpha, Beta, Taxonomy, DA, Indicator, Figures). Then the Key-objects
  table cites real headings ("Section 8, Step 1" for distance matrices). If a full
  renumber is deferred, at minimum fix the table's cross-references to name the
  actual nested heading ("Beta diversity, Step 1").

### S-12 · S3 · Normalisation-methods catalogue is reference material mid-walkthrough
- **Where:** SOP_R_Analysis.md:397-401, §1 Stage 4
- **Anchor:** `divides each count by the sample total to get proportions`
- **Quote:**
  > **TSS (Total Sum Scaling)** divides each count by the sample total to get
  > proportions. … **CSS (Cumulative Sum Scaling)** is a quantile-based
  > normalisation from metagenomeSeq …
- **Breaks:** R3 (reference material lives at the back), R4
- **Reader impact:** The `CLR`/`TSS`/`CSS` descriptions read as an encyclopaedia of
  methods the walkthrough then barely uses — the workflow runs SRS plus internal
  rCLR. Sitting mid-Stage-4, they slow the one decision the reader must make here
  (SRS, why, to what depth) and bury it under options they will not touch.
- **Fix:** MOVE the full method catalogue (the CLR/TSS/CSS bold-run-in
  descriptions) to Appendix B. Keep inline only: the SRS definition and its "why
  SRS" reasoning (never cut — it is why-this-number), plus the "Which normalisation
  for which analysis" decision table (L405-413), which *is* load-bearing. Leave a
  one-line pointer: "Other methods (CLR, TSS, CSS) and when they apply are in
  Appendix B."

### S-13 · S3 · Optional ALDEx2 side-path given a full heading equal to the two main methods
- **Where:** SOP_R_Analysis.md:1102-1104, §2
- **Anchor:** `A note on ALDEx2`
- **Quote:**
  > ### **A note on ALDEx2**
  >
  > If you want a third method, ALDEx2 follows the same pattern …
- **Breaks:** R3, R7 (an optional side-path weighted like the main path; F5)
- **Reader impact:** ANCOM-BC2 and MaAsLin2 are the required two-method consensus;
  ALDEx2 is an optional tie-breaker. Giving all three the same `###` heading level
  reads as "three methods to run", pushing a beginner to install and run a third
  tool the workflow does not require, and blurring the two-method default.
- **Fix:** Demote to a bold run-in at the end of the MaAsLin2 consensus discussion
  rather than its own section:
  > **An optional third method.** If ANCOM-BC2 and MaAsLin2 disagree, ALDEx2 is a
  > useful tie-breaker — same pattern, `ps_raw` in, CLR applied internally via
  > Monte Carlo sampling. Reporting the consensus of all three is the most
  > defensible result, but two is the default.

### S-14 · S4 · F1 — compositionality worked example runs to 101 words
- **Where:** SOP_R_Analysis.md:956, §2.1
- **Anchor:** `A concrete example: a gut sample with 1,000 cells each of Species A, B, and C`
- **Quote:**
  > A concrete example: a gut sample with 1,000 cells each of Species A, B, and C
  > yields ~1,000 reads each from 3,000 total. … A naive test would falsely report
  > a decrease in B and C. This happens whenever any taxon truly changes …
- **Breaks:** F1 (101 words), R8 — but this is a concept the reader genuinely lacks; **rewrite tighter, keep the arithmetic**, never cut
- **Reader impact:** The single longest prose paragraph. The arithmetic is the
  whole point (it is what makes compositionality click), so it must survive — but
  at 101 words in one block a scanner slides off it.
- **Fix:** Split into the setup and the lesson, keeping every number:
  > A concrete example. Three species at 1,000 cells each give ~1,000 reads each
  > from 3,000 total. Double species A to 2,000 cells and the true total is 4,000
  > — but the instrument still returns only 3,000 reads: A ≈ 1,500, B ≈ 750, C ≈
  > 750.
  >
  > B and C now *look* 25% lower though neither changed, and a naive test reports a
  > false decrease in both. This happens whenever any taxon truly changes, and is
  > worst when a dominant taxon changes.

### S-15 · S4 · F1 — figure-vs-text p-value warning runs to 92 words
- **Where:** SOP_R_Analysis.md:502, §1.5a Alpha diversity
- **Anchor:** `The figure must be drawn from these adjusted p-values, not from a second set computed inside the plotting call.`
- **Quote:**
  > **The figure must be drawn from these adjusted p-values, not from a second set
  > computed inside the plotting call.** `stat_compare_means()` runs its own
  > unadjusted Wilcoxon tests … a figure can carry a `*` on the same data for which
  > the text reports "no significant difference" …
- **Breaks:** F1 (92 words), R10 (silent-failure warning — never cut; rewrite tighter)
- **Reader impact:** This is one of the document's best silent-failure catches (the
  figure disagreeing with the text goes into the thesis). It must not thin, but at
  92 words the operative instruction competes with the explanation.
- **Fix:** Lead with the rule, move the mechanism to a second sentence:
  > **Draw the figure from these adjusted p-values — never let the plot compute its
  > own.** `stat_compare_means()` silently runs *unadjusted* Wilcoxon tests and
  > brackets every comparison, ignoring the Kruskal-Wallis gate. Left in, it can
  > stamp a `*` on data the text calls non-significant — and the figure is what
  > reaches the thesis. The helper below turns the adjusted matrix into brackets so
  > there is only ever one set of numbers.

### S-16 · S4 · F1 — centroid-plot interpretation runs to 87 words
- **Where:** SOP_R_Analysis.md:786, §1.5b Step 3
- **Anchor:** `In the centroid plot, each point is a sample, each diamond is a group centroid`
- **Quote:**
  > In the centroid plot, each point is a sample, each diamond is a group centroid,
  > and the ray length is the distance betadisper tests. … For a thesis figure,
  > publish the centroid plot; keep the boxplot for supplementary material …
- **Breaks:** F1 (87 words), R5, F3 (three plot-reading facts + a recommendation)
- **Reader impact:** Reads as one dense block covering two plots and a
  publish/supplement recommendation; the reader parsing figure guidance has to
  hold all of it at once.
- **Fix:** Split the "how to read it" from the "which to publish":
  > In the centroid plot, each point is a sample, each diamond a group centroid,
  > and the ray length is the distance betadisper tests — long rays mean high
  > dispersion. In the boxplot, the y-axis is each sample's distance to its own
  > centroid; a visibly higher box means the test will likely return p < 0.05.
  >
  > The centroid plot shows the spatial pattern, the boxplot the magnitude. For a
  > thesis figure publish the centroid plot; keep the boxplot for supplementary
  > material or for diagnosing a surprising result.

### S-17 · S4 · F1 — Schloss rarefaction rationale runs to 85 words
- **Where:** SOP_R_Analysis.md:389, §1 Stage 4
- **Anchor:** `Schloss found rarefaction was the only method that decoupled diversity from sequencing depth`
- **Quote:**
  > Schloss found rarefaction was the only method that decoupled diversity from
  > sequencing depth across all metrics tested. He also found that the standard
  > CLR/Aitchison distance … we use the robust (rCLR) variant, and Step 2 includes
  > an explicit check …
- **Breaks:** F1 (85 words), R1 (why-this-number layer 2 — **rewrite tighter, never cut**), R2 (see S-06)
- **Reader impact:** Carries the central methodological judgement (why rarefaction
  is defensible; why Aitchison is kept but flagged). It is exactly the "why this
  number" content the spec protects, so the reason must cross intact — but at 85
  words it buries its own conclusion.
- **Fix:** Tighten to two sentences, keeping the whole reason:
  > Schloss found rarefaction the only method that decoupled diversity from depth
  > across every metric tested. He also found Aitchison distance still tracked
  > depth on sparse data — a caution, not a veto: we report Aitchison alongside
  > Bray-Curtis (not instead of it), use the robust rCLR variant, and check in
  > Step 2 that the Aitchison ordination is not merely tracking library size.

### S-18 · S4 · F1/F3 — PERMANOVA "how it works" buries a 4-step procedure in prose
- **Where:** SOP_R_Analysis.md:796, §1.5b Step 4
- **Anchor:** `It builds its own null from your data:`
- **Quote:**
  > **How it works.** Unlike a t-test or ANOVA, PERMANOVA assumes no distribution.
  > It builds its own null from your data: (1) compute the real F-statistic …; (2)
  > shuffle the group labels and recompute F; (3) repeat 9,999 times; (4) count how
  > many permuted F values exceed your real F. …
- **Breaks:** F1 (82 words), F3 (a (1)–(4) enumeration inside prose), R3
- **Reader impact:** The four-step permutation procedure is exactly what a beginner
  needs to understand PERMANOVA, but strung inline the steps run together and the
  key idea (the null comes from shuffling) is easy to miss on a scan.
- **Fix:** Lift the steps into a numbered list:
  > **How it works.** Unlike a t-test or ANOVA, PERMANOVA assumes no distribution —
  > it builds its own null by reshuffling your data:
  >
  > 1. Compute the real F-statistic: variation explained by your grouping variable
  >    versus residual.
  > 2. Shuffle the group labels and recompute F.
  > 3. Repeat 9,999 times.
  > 4. Count how many shuffled F values beat the real one. Fewer than 5% means
  >    p < 0.05 — if the groups were truly alike, shuffling would barely change F.

### S-19 · S4 · F1 — Aitchison-distance definition runs to 82 words
- **Where:** SOP_R_Analysis.md:594, §1.5b Step 1
- **Anchor:** `is the compositionally appropriate alternative.`
- **Quote:**
  > **Aitchison distance** is the compositionally appropriate alternative.
  > Sequencing data is compositional: each sample has a fixed total … Aitchison
  > distance applies a CLR transformation … and computes Euclidean distance in that
  > space, where taxa are independent.
- **Breaks:** F1 (82 words), R8 (this is a layer-1 definition — rewrite tighter, keep it)
- **Reader impact:** This is the primary definition of Aitchison distance (the
  document's second beta-diversity metric) and it also has to carry the
  compositionality idea. At 82 words the definition and the motivation blur.
- **Fix:** Split the motivation from the mechanism:
  > **Aitchison distance** is the compositionally appropriate alternative.
  > Sequencing data is compositional — each sample has a fixed read total, so if
  > one taxon's proportion rises the others must fall, even with no real change.
  > Bray-Curtis ignores this, which distorts distances when a few taxa dominate.
  >
  > Aitchison distance applies a CLR transformation (divide each count by the
  > sample's geometric mean, then take the log) and measures ordinary Euclidean
  > distance in that space, where taxa behave independently.

### S-20 · S4 · F1/F2 — `neg_lb` bullet is a 112-word definition
- **Where:** SOP_R_Analysis.md:1008, §2.2 ANCOM-BC2 parameters
- **Anchor:** `the default and what this workflow uses. It controls whether an asymptotic`
- **Quote:**
  > `neg_lb = FALSE` is the default and what this workflow uses. It controls whether
  > an asymptotic lower bound is used … Set it to `TRUE` only if every level of
  > `group` has ≥30 samples … and check `?ancombc2` for the exact wording …
- **Breaks:** F2 (a definition over two sentences), F1 (112 words), R7 (why-this-number — **rewrite tighter, never cut the ≥30 rule**)
- **Reader impact:** The only single bullet over 80 words, and it carries a genuine
  silent-failure warning (`neg_lb = TRUE` on small groups invents structural zeros
  that surface as fake strong differences). The reasoning must survive; at 112
  words in one bullet it swamps the parameter list around it.
- **Fix:** Tighten to two sentences, keeping the threshold and the failure mode:
  > `neg_lb = FALSE` (the default, used here) controls the lower bound for calling
  > a taxon structurally absent from a group. **Leave it FALSE unless every group
  > has ≥30 samples** — below that the bound is unstable and invents structural
  > zeros, which appear as strong, highly significant differences that are really
  > just under-sampling (the worked example has four per group, so it stays FALSE).

### S-21 · S4 · V3 banned words, plus scanner-artifact reconciliation (omnibus)
- **Where:** SOP_R_Analysis.md:378, and L389, L639, L950, L973, L1008, L1203
- **Anchor:** `simply because deeper sequencing catches rarer taxa`
- **Quote:**
  > Sample A with 50,000 reads will appear more diverse than Sample B with 5,000,
  > simply because deeper sequencing catches rarer taxa.
- **Breaks:** R9 (one voice), V3 (banned: `simply`, `just`, `merely`)
- **Reader impact:** Scattered belittling-adjacent words: `simply` (L378, L389,
  L639), `just` in the heading L950 ("Why you can't just test each taxon") and
  L1203, `merely` (L973). None is egregious, but V3 is a hard ban and the heading
  instance is the most visible. Cumulatively they nick the "never make a beginner
  feel stupid" voice.
- **Fix:** Reword each: L378 "simply because" → "because"; L389 "not simply
  tracking" → "not merely tracking" → "not tracking"; L639 "simply has more" →
  "has more"; L950 heading → "**Why you can't test each taxon on its own**"; L973
  "not merely undersampled" → "not just undersampled" → "not undersampled"; L1203
  "not just `~ Sex`" → "not `~ Sex` alone".
  **Scanner reconciliation (F1):** `scan.py` reports 12 over-80 paragraphs, but 5
  are the scanner gluing adjacent bullets into one block — each underlying bullet
  is well under 80 (L189 3 bullets ≤50w; L477 3 bullets ≤41w; L902 4 bullets
  ≤38w; L960 4 bullets ≤12w; L808 2 bullets ≤47w; L1003 the ANCOM parameter list,
  whose only genuine offender is the `neg_lb` bullet handled in S-20). These five
  are F3-compliant lists, **not** paragraph violations; do not "split" them. The
  genuine F1 set is the 6 prose paragraphs (S-14 to S-19) plus the one oversized
  bullet (S-20) — matching the spec's baseline of 6 prose paragraphs, longest 101.

## Target outline

The finished heading structure, in run order. Renumbering the "Stages" into a
single 1..12 spine is the mechanism that closes R6 (S-11); everything below the
Appendices is relocation, so net words stay roughly flat.

```
*Taylor Lab | …*                              KEEP
# Part 2: R Analysis (Count Tables to Results) KEEP
**v2.1** | … | runs locally in R …            KEEP (bump version)
<intro paragraph>                             KEEP (trim lightly)
### Before you start                          NEW  — S-08. R+RStudio local; 3 input
                                                     files; how to get them off NeSI;
                                                     scope-out (DADA2/assembly/non-
                                                     independent); ~130 words.
## Quick roadmap                              KEEP (relabel STAGE→section numbers)
## 1. Understanding your data                 NEW (concepts only, no commands) — S-09.
                                                     count table; compositionality
                                                     (2 sentences from L954); phyloseq
                                                     gloss (S-04); ps_raw vs ps_srs
                                                     rule; then Key-objects table
                                                     MOVED FROM L40-57. ~250 words.
## 2. Install and load packages               MOVE FROM L65-98 + REWRITE — S-01 runtime
                                                     note; split rarely-used mixed-model
                                                     installs into a labelled block.
## 3. Load and prepare your data              MOVE FROM Stage 1 (L100-236) — add file-
                                                     transfer note (S-03); keep round()
                                                     + relabund guard + positional-match
                                                     guard; gloss lfc (S-07).
## 4. Remove contaminants and build ps_raw    MOVE FROM Stage 2 (L238-305) — add
                                                     prevalence-method definition (S-02)
                                                     + a checkpoint on decontam output.
## 5. Explore your data before analysis       MOVE FROM Stage 3 (L307-374)   KEEP content
## 6. Normalise to ps_srs                     MOVE FROM Stage 4 (L376-465) — keep SRS why
                                                     + decision table; CLR/TSS/CSS
                                                     catalogue MOVED to Appendix B (S-12);
                                                     tighten Schloss para (S-17).
## 7. Alpha diversity                         MOVE FROM L471-576 — tighten S-15.
## 8. Beta diversity                          MOVE FROM L578-907 — Steps 1-6 become
                                                     ### subsections; tighten S-16/18/19.
## 9. Taxonomy barplots                       MOVE FROM L909-944            KEEP content
## 10. Differential abundance                 MOVE FROM §2 (L946-1067) — concept opener
                                                     (why multiple testing/compositionality)
                                                     KEEP; tighten S-14/S-20; ALDEx2
                                                     demoted to run-in here (S-13).
## 11. Indicator species                      MOVE FROM L1106-1156         KEEP content
## 12. Figures and reproducibility            MOVE FROM L1158-1177         KEEP content
## Troubleshooting and common pitfalls        REWRITE FROM L1179-1207 — retitle so a
                                                     stuck reader finds it (S-10).
## Appendices                                 NEW — S-10. A: references (5 primary cites,
    A. References                                    grouped); B: normalisation-methods
    B. Normalisation methods (CLR/TSS/CSS)            catalogue moved from L397-401;
    C. Thresholds and resource figures               C: depth floor, prv_cut, lib_cut,
                                                     Cmin rule, NMDS stress bands, IndVal.
```

Layer-1 headings after this: "1. Understanding your data" plus the concept
openers under 7/8/10 now sit under a clean spine — census goes up. The over-80
count goes down (6 prose paragraphs tightened, none added).

## Keep list

Content a restructure would be tempted to drop or thin. None of it is proposed
for removal anywhere above.

1. **Relative-abundance guard** — L142-149 (`stop()` on column sums of 100/1).
   Silent-failure prevention (R10); a percentage table survives `round()`.
2. **Positional-index match guard** — L168-182 (`setdiff` + `stopifnot`). decontam,
   blank removal and indicator grouping index positionally; a mismatch is silently wrong.
3. **Stale-`ps_raw` rebuild after the depth gate** — L444-449. A stale object runs
   without error on samples you thought you removed (R10).
4. **Figure-vs-text p-value trap + `bracket_frame` gate** — L502, L507-519. The
   strongest silent-failure catch; the figure that contradicts the text (R10).
5. **`neg_lb` ≥30-samples rule** — L1008. Why-this-number; fake structural zeros on
   small groups (never cut, only tighten — S-20).
6. **rarefaction vs rarefying distinction + Schloss/McMurdie citations** — L384-389.
   Why-this-number + primary literature.
7. **"Which normalisation for which analysis" table** — L405-413. The load-bearing
   decision table; the map from analysis to object.
8. **`ps_raw` vs `ps_srs` "one rule to remember"** — L57. The single easiest thing
   to get wrong in Part 2.
9. **Aitchison depth-tracking caveat + library-size colour check** — L639, L656-665.
   Why + a silent-confound check.
10. **`pairwise.adonis2` swallows `p.adjust.m` + `adjust_pairwise`** — L847-874.
    Silent no-correction; overstated significance (R10).
11. **FDR-across-every-taxon note for indicators** — L1142-1156. Correcting on the
    filtered subset silently inflates indicator counts (R10).
12. **Compositionality worked example (the arithmetic)** — L954-956. A concept the
    reader genuinely lacks; keep every number (tighten only — S-14).
13. **Factor-level naming warning** — L206. Spaces in levels silently break ANCOM-BC2
    /MaAsLin2 column names.
14. **Common Pitfalls list** — L1179-1207 (pseudoreplication, confounding, Simpson's
    paradox, ecological fallacy, technical vs biological replicates). Interpretation
    and governance content.

## Rewrite plan

Ordered, dependency-aware. This document is self-contained and can proceed
independently of the other three files (its only cross-file touchpoint is the
NeSI→local file transfer in S-03, which a seam agent may also cover — coordinate
to avoid duplication).

1. **Add the two missing front sections (S-08, S-09).** Insert "Before you start"
   and the concepts-only "1. Understanding your data", relocating the Key-objects
   table into the latter. Closes S-08, S-09, and the front-load half of S-05.
   Largest structural change; do it first because the renumber depends on it.
   Net words ~flat (mostly relocation). ~+250 words in, offset by cuts below.
2. **Renumber the spine (S-11).** Promote Stages→Sections 1–12; fix the
   Key-objects cross-references to name real headings. No prose change.
3. **Insert the missing definitions (S-02, S-04, S-06, S-07).** prevalence method,
   phyloseq, CLR/rCLR forward-gloss + reorder, lfc gloss. Closes the R2 core.
4. **Add runtimes (S-01).** Install block + `ancombc2` + `adonis2` + NMDS. ~30 words.
5. **Move reference material to Appendices (S-10, S-12).** Citations, CLR/TSS/CSS
   catalogue, threshold table to the back; retitle Common Pitfalls. Net negative
   words inline.
6. **Tighten the seven over-length blocks (S-14 to S-20).** Each rewrite carries
   its whole reason across; total words come *down*. Closes F1.
7. **Voice pass (S-21).** Reword the six banned-word instances.

After steps 1–2 the layer-1 heading count is up and the numbering is clean; after
6 the over-80 count is down from 6 to 0. Both §11 gates then pass.

---

### Self-check

```
findings=21 S1=3 S2=4 S3=6 S4=8
CLEAN
```

Confirmed by hand: the section ledger accounts for every heading in the document
(title through Common Pitfalls, including the nested Beta-diversity Steps 1–6);
the target outline covers every section in the ledger (each mapped to KEEP / MOVE
/ REWRITE / NEW); nothing on the keep list is proposed for removal — every keep
item is marked "tighten only" or "keep content" where it is touched at all.

CONTRACT: PASS
