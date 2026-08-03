## Document: SOP_READBASED_NeSI.md

## Verdict against the specification

This is a technically excellent runbook wearing the wrong shape for its reader.
Its layer-2 content is the strongest in the set: the depth-budget arithmetic, the
"why T2T-CHM13", the "why masked", the zcat-pipefail and `--index`/`--offline`
warnings, the round()-destroys-data trap — this is exactly the "why this number"
and silent-failure material the spec exists to protect, and none of it may be cut.
But the document was written for someone who "has already run one pipeline" (line
11), and the spec withdraws that reader. Measured against a graduate student who
has never opened a terminal, three structural defects dominate: (1) **every job
script is shown without its header** — Section 4 defines the header once and tells
the reader to "add it yourself", which is the exact anti-pattern R11 names, and six
of the eight bodies use `$SAMPLE`, which only the omitted header assigns; (2)
**concept-first openers are missing** where the science is newest — Section 6 opens
on a subtlety of `ktrim=r` before the reader has been told what an adapter or PhiX
is, and Section 10 opens on a conda install before HUMAnN is ever introduced; (3)
**no step states its runtime and the profiling steps carry no inline checkpoint**,
so the reader cannot tell a working 24-hour job from a hung one, or an empty
profile from a full one. Fixing these adds layer-1 and per-step scaffolding; the
word budget comes back by tightening the one 100-word paragraph (L753) and cutting
the closing paragraph that duplicates Section 2. Voice is largely clean — UK
spelling throughout, no `the user`, no `one should` — but `we` never appears, so
lab decisions are never marked as such (V1), and a few banned words survive (V3).

| Rule | Pass / Partial / Fail | One-line evidence |
| --- | --- | --- |
| R1 (both layers, in order) | **Fail** | §6, §10, §11 open on commands/layer-2 with no layer-1; only §7, §9 teach first. |
| R2 (nothing used before introduced) | **Fail** | PhiX, ktrim, adapters, SGB, CPM, RPK, BAL, paired-end, rclr, compositional all used before (or without) definition. |
| R3 (concepts before commands) | Partial | §1, §7, §9 open in prose; §5, §6, §10, §11 open straight into a command block. |
| R4 (setup where needed) | Partial | Storage/quota table up front is allowed; §2 Preflight front-loads a module-spider loop, and L882 repeats it. |
| R5 (every step states its outcome) | **Fail** | No step gives a runtime; §9/§10 have no inline checkpoint (existence checks are exiled to Appendix B). |
| R6 (one numbered spine) | Partial | Sections 1–14 run in performance order and script names match, but §4 is a reference block occupying a step slot. |
| R7 (every fork has a default) | Partial | Host depletion (A recommended) and trimming (BBDuk default) name defaults; §6 also recommends a BBMap version that does not exist. |
| R8 (plain words first, jargon second) | **Fail** | `ktrim=r`, PhiX, SGB, CPM introduced as the term with no plain-language gloss. |
| R9 (one voice) | Partial | Register is consistent, but `we` is used zero times so layer-2 lab choices read as impersonal fact. |
| R10 (explain the failure) | **Pass** | Outstanding: empty `$SAMPLE`, zcat pipefail, `--index`/`--offline`, `-s`, round(), trap — do not thin. |
| R11 (every script complete) | **Fail** | 8 job bodies shown without shebang/`#SBATCH`/`set -euo pipefail`; Section 4 says "add it yourself". |
| F1 (no paragraph over 80 words) | Partial | One genuine prose offender: L753 (100 words). Scan also flags four list-concatenations (not true violations). |
| F2 (a definition is 1–2 sentences) | Partial | Where definitions exist they are tight; the problem is absence, not swelling. |
| F3 (enumerable becomes table/list) | **Pass** | Strong: depth, gates, controls, host fractions, resources, Section-13 deltas are all tables. |
| F4 (the point comes first) | **Pass** | Bold run-ins lead most blocks; a scanner reading bold + first sentences gets it right. |
| F5 (the "why" is separable) | Partial | Mostly good; §6's justification is fused to the action with no separable layer-1 above it. |

Voice (V-rules): V1 **Fail** (`we` used 0×); V2 **Pass**; V3 **Partial** (`simply` L407/L740, `easiest` L92/L221); V4 **Pass**; V5 **Pass** (UK spelling, no US forms found); V6 Partial (closing L882 restates §2).

## Jargon table

Every term a never-touched-a-terminal reader would not know, its first use, and where (if anywhere) it is defined.

| Term | First used | Defined at | Verdict |
| --- | --- | --- | --- |
| read-based / shotgun | title, L3–L7 | L7 ("matched directly against reference databases", "without assembling") | OK inline; README also defines |
| paired-end, `_R1`/`_R2`, "mate" | L5, L7, L153 | never | **R2 fail** — no gloss for two files per sample / mates |
| FASTQ / `.fastq.gz` | L146, L150 | never | Assumed from Part 1; borderline |
| PhiX | L25 (roadmap), L272 | never | **R2/R8 fail — S1** (drives §6, no definition anywhere) |
| adapter / adapter trimming | L256, §6 | never (used as term) | **R2/R8 fail** — no plain-language gloss |
| `ktrim` / `ktrim=r` | L272 | never | **R2/R8 fail** — term used to explain a subtlety before it is defined |
| BBDuk / BBMap | L272, §3.2 | never (tool role implied) | Partial — role clear from context, never named as "part of BBMap" |
| PhiX vs artifacts (`ref=phix,artifacts`) | L288 | never | Partial |
| poly-G, two-/four-colour chemistry | L256, roadmap | L299, L266 (defined at point of use) | OK — concept given where it matters |
| host depletion / "host" | L25 | L334 ("keep a read pair only if neither mate maps to the human genome") | OK layer-1 |
| T2T-CHM13v2.0 / masked | §7 | L336, L342 (dedicated "why" subsections) | **Exemplary** — the pattern the rest of the doc lacks |
| BAL | L56 | never (expanded nowhere) | **R2 fail** — bronchoalveolar lavage, used 4× |
| low-biomass | L56 | never | Minor |
| SGB | L470 | never (expanded nowhere) | **R2 fail** — "species-level genome bin" never spelled out |
| marker genes | L470 | L470 ("clade-specific marker genes") | OK |
| StrainPhlAn | L470 | context | OK |
| HUMAnN | L7 | never (what it *does*) | **R1/R3 fail — S2** (§10 opens on install, not concept) |
| gene families / pathways | L7, §10 | never (as concepts) | **R2 fail** |
| RPK | L634 | never (expanded nowhere) | **R2 fail** — "reads per kilobase" |
| CPM | L34, L634, §11 table | never (expanded nowhere) | **R2 fail** — "copies/counts per million" |
| stratified / unstratified | L34, §11 | L639 (code comment: "community totals from per-species rows") | Partial — definition buried in a comment |
| EC / KO (enzyme commission / KEGG orthologues) | L643 | L662 (table expands both) | OK |
| ChocoPhlAn / UniRef90 / diamond | §3.3, §10 | never | Partial — named, not defined; acceptable as DB names |
| compositional | L755 | L755 (asserted, not explained) | **R2 fail** — no gloss for a reader who lacks it |
| rclr / rCLR | L728 | L728 ("tolerates zeros without a pseudocount") | Partial — effect given, not the term |
| Aitchison / CLR | L722, L744 | never | Partial — Part 2 territory but first-used here |
| SRS | L711 | L711 ("subsamples integer counts") | OK inline |
| Chao1/ACE, singletons/doubletons | L712 | L712 ("extrapolate from singletons and doubletons") | OK inline |
| PERMANOVA / betadisper / Bray–Curtis | §13 | never (Part 2 owns) | Acceptable — cross-doc |
| UniFrac / Faith's PD | L682, §13 | L682 ("phylogenetic diversity") | OK inline |
| array job / `sbatch` / `srun` / module | throughout | redirected to EMU §1 (L11) | Acceptable by redirect once L11 is reframed |
| JVM / `-Xmx` / heap / OOM | L278, L409 | L409/L864 (heap "sits outside the heap") | Partial — JVM never expanded |

## Section ledger

| § | Heading | Lines | Treatment | Findings |
| --- | --- | --- | --- | --- |
| — | Descriptor + title + version line | 1–5 | CLEAN | — |
| — | Opening scope paragraphs | 7–11 | REWRITE-VOICE + ADD-LAYER-1 | S-07 (L11 withdrawn assumption); define paired-end |
| — | Quick Roadmap | 15–40 | CLEAN | PhiX first appears here (S-03) |
| 1 | Before You Generate Data | 44–96 | CLEAN | define BAL (S-08); strong governance content — keep |
| 1 | ├ Governance | 48–52 | CLEAN | never-cut (governance/ethics) |
| 1 | ├ Controls | 54–65 | CLEAN | — |
| 1 | └ Depth | 67–96 | TIGHTEN | keep the backwards-arithmetic; never-cut |
| 2 | Preflight and Storage | 100–133 | MOVE | S-10 (front-loaded module check dup L882) |
| 2 | ├ Preflight | 102–120 | MOVE | module-spider loop → prose note / first use |
| 2 | └ Storage | 122–133 | CLEAN | R4 exception (quota) — keep up front |
| 3 | Setup | 137–195 | CLEAN | — |
| 3 | ├ 3.1 Directories & manifest | 139–166 | ADD-OUTCOME | add checkpoint (expected NSAMP) |
| 3 | ├ 3.2 Modules | 167–173 | CLEAN | — |
| 3 | └ 3.3 References and databases | 175–195 | ADD-OUTCOME | download runtime + checksum checkpoint |
| 4 | The Standard Job Header | 199–223 | MOVE + REWRITE | S-01, S-09 (inline header everywhere; demote §4 to reference) |
| 5 | Quality Control | 227–266 | ADD-LAYER-1 + ADD-OUTCOME | S-04 (MultiQC-exists checkpoint); what QC checks |
| 5 | ├ Reading the reports | 252–256 | CLEAN | carries the checkpoint content for trimming |
| 5 | └ Identify your chemistry now | 258–266 | CLEAN | — |
| 6 | Trimming and PhiX Removal | 270–297 | ADD-LAYER-1 | S-05 (no layer-1), S-03 (PhiX), S-01 (header) |
| 6 | ├ Two-colour chemistry: poly-G | 299–303 | REWRITE | S-12 (BBMap 39.09/39.10 does not exist) |
| 6 | └ Alternative: fastp for pass one | 305–328 | ADD-OUTCOME | header + runtime |
| 7 | Host Depletion | 332–420 | CLEAN | exemplary layer-1/2 — keep as the model |
| 7 | ├ Why T2T-CHM13v2.0 | 336–340 | CLEAN | never-cut (why-this-tool) |
| 7 | ├ Why the reference must be masked | 342–344 | CLEAN | never-cut |
| 7 | ├ Option A — Hostile (recommended) | 346–374 | ADD-OUTCOME | header + runtime + checkpoint |
| 7 | ├ Option B — BBMap unmasked | 376–409 | ADD-OUTCOME | header + runtime |
| 7 | └ Expected host fraction by site | 411–420 | CLEAN | — |
| 8 | Read Accounting and Depth Gates | 424–464 | ADD-OUTCOME | serves as collective checkpoint for §6–§7 — keep; add runtime |
| 8 | └ The gates | 453–464 | CLEAN | never-cut (how to tell a step failed) |
| 9 | Taxonomy with MetaPhlAn 4 | 468–508 | ADD-OUTCOME | S-04 (no inline checkpoint), S-02 (runtime), S-01 (header) |
| 9 | ├ Why --index and --offline | 498–500 | CLEAN | never-cut (reproducibility) |
| 9 | └ Why there are two passes | 502–508 | CLEAN | never-cut |
| 10 | Function with HUMAnN | 512–513 | ADD-LAYER-1 | S-06 (HUMAnN never introduced) |
| 10 | ├ Install a current release | 514–534 | CLEAN | never-cut (the alpha-module warning) |
| 10 | └ Running it | 536–562 | ADD-OUTCOME | S-04 (checkpoint), S-02 (24h runtime), S-01 (header) |
| 11 | Merging, Normalising, Splitting | 566–573 | ADD-LAYER-1 | what stratified/CPM/RPK mean (S-08) |
| 11 | ├ Taxonomy: relative abundance | 574–592 | CLEAN | — |
| 11 | ├ Taxonomy: estimated counts | 594–620 | CLEAN | — |
| 11 | ├ Function | 622–652 | CLEAN | — |
| 11 | └ What Section 13 needs | 654–663 | CLEAN | — |
| 12 | Contamination Screening | 667–674 | CLEAN | numbered list (scan flags as 139w — not a true F1) |
| 13 | Statistics: What Changes | 678–761 | TIGHTEN | S-11 (L753 100w); never-cut deltas |
| 13 | ├ Reshape before you open Part 2 | 684–707 | CLEAN | never-cut (silent rounding) |
| 13 | ├ Beta diversity | 720–728 | CLEAN | define rclr/compositional (S-08) |
| 13 | ├ PERMANOVA | 730–740 | CLEAN | — |
| 13 | ├ Differential abundance | 742–755 | TIGHTEN | S-11 (L753) |
| 13 | └ Functional tables | 757–761 | CLEAN | never-cut |
| 14 | Provenance | 765–801 | CLEAN | never-cut (methods reproducibility) |
| A | Appendix A: Submission Chain | 805–834 | CLEAN | reference at back — correct place |
| B | Appendix B: Triage | 836–858 | MOVE (partial) | existence checks → surface as §9/§10 checkpoints (S-04) |
| C | Appendix C: Resources | 860–878 | CLEAN | runtime numbers live here — surface at each step (S-02) |
| — | Closing "verify the environment" para | 882 | MERGE/CUT | S-10 (duplicates §2 Preflight) |

## Findings

### S-01 · S1 · Every script omits the job header; Section 4 says add it yourself (R11)
- **Where:** SOP_READBASED_NeSI.md:199-223 (Section 4), and every script body: 233, 241, 276, 309, 360, 382, 391, 430, 476, 540
- **Anchor:** `shown without it — add it yourself`
- **Quote:**
  > Every script in this SOP uses the header below. Only the job name and the resource requests change, and Appendix C lists those per script. The script bodies in later sections are shown without it — add it yourself.
- **Breaks:** R11 (no "add the header yourself"; script must be complete as shown)
- **Reader impact:** This is the document's worst defect and the reason the spec singles it out. Eight job-script bodies are printed with no shebang, no `#SBATCH --account/--time/--mem/--cpus-per-task`, no `--output`, and no `set -euo pipefail`; six of them (`05a`, `06`, `07.host_hostile`, `07b`, `09`, `10`, plus the fastp variant) reference `$SAMPLE`, which is assigned only by the `SAMPLE=$(sed -n ...)` line in the header the reader was told to add. A never-touched-a-terminal reader copies the `09.metaphlan.sl` block, runs `sbatch`, and either the job dies with `unbound variable`, or — worse — `$SAMPLE` expands empty and MetaPhlAn profiles `clean/_R1.fastq.gz`, producing a silent wrong result with a green exit code. The spec has already ruled on the duplication objection: "a header wrong in one script is one bad job; a header the reader forgets is a silent wrong result." Inline the header into every block.
- **Fix:** Delete the sentence "The script bodies in later sections are shown without it — add it yourself." Demote Section 4 to a one-line pointer ("Every script below carries the full header; the per-script resource values are in Appendix C") and prepend the complete header to each of the eight script blocks, filling `--job-name/--time/--mem/--cpus-per-task` from the table below. The header to prepend (array jobs shown; drop the last three lines and use `--output logs/%x_%j.out` for the non-array scripts `05b`, `07a`, `08`):

  ```bash
  #!/bin/bash
  #SBATCH --account <your_nesi_project_code>
  #SBATCH --job-name metaphlan
  #SBATCH --time 04:00:00
  #SBATCH --mem 32G
  #SBATCH --cpus-per-task 16
  #SBATCH --array=1-1                    # real range set at submission: sbatch --array=1-${NSAMP}%20
  #SBATCH --output logs/%x_%A_%a.out
  set -euo pipefail
  cd "${SLURM_SUBMIT_DIR:?}"
  SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" samples.txt)
  [[ -n "$SAMPLE" ]] || { echo "empty sample at ${SLURM_ARRAY_TASK_ID}"; exit 1; }
  ```

  Header values per script (from Appendix C), so assembly is mechanical:

  | Script | job-name | time | mem | cpus | array? |
  | --- | --- | --- | --- | --- | --- |
  | `05a.qc_fastqc.sl` | qc_fastqc | 00:30:00 | 4G | 2 | yes |
  | `05b.qc_multiqc.sl` | qc_multiqc | 00:20:00 | 4G | 1 | no |
  | `06.trim.sl` | trim | 02:00:00 | 16G | 12 | yes |
  | `07.host_hostile.sl` | host_hostile | 01:00:00 | 24G | 16 | yes |
  | `07a.host_index.sl` | host_index | 01:00:00 | 36G | 12 | no |
  | `07b.host_filter.sl` | host_filter | 01:00:00 | 32G | 20 | yes |
  | `08.read_counts.sl` | read_counts | 02:00:00 | 4G | 1 | no |
  | `09.metaphlan.sl` | metaphlan | 04:00:00 | 32G | 16 | yes |
  | `10.humann.sl` | humann | 24:00:00 | 48G | 16 | yes |

  Fully assembled exemplar to show the reader once (Section 9), so the pattern is unambiguous:

  ```bash
  #!/bin/bash
  #SBATCH --account <your_nesi_project_code>
  #SBATCH --job-name metaphlan
  #SBATCH --time 04:00:00
  #SBATCH --mem 32G
  #SBATCH --cpus-per-task 16
  #SBATCH --array=1-1
  #SBATCH --output logs/%x_%A_%a.out
  set -euo pipefail
  cd "${SLURM_SUBMIT_DIR:?}"
  SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" samples.txt)
  [[ -n "$SAMPLE" ]] || { echo "empty sample at ${SLURM_ARRAY_TASK_ID}"; exit 1; }

  module purge; module load MetaPhlAn/4.1.0-gimkl-2022a-Python-3.10.5
  DB=/nesi/nobackup/<your_nesi_project_code>/db; MPA_INDEX=mpa_vJun23_CHOCOPhlAnSGB_202403
  rm -f "metaphlan/${SAMPLE}.bt2.bz2"
  metaphlan "clean/${SAMPLE}_R1.fastq.gz,clean/${SAMPLE}_R2.fastq.gz" \
    --input_type fastq --nproc ${SLURM_CPUS_PER_TASK} \
    --bowtie2db "$DB/metaphlan4" --index "$MPA_INDEX" --offline \
    --bowtie2out "metaphlan/${SAMPLE}.bt2.bz2" -o "metaphlan/${SAMPLE}.profile.tsv"
  metaphlan "metaphlan/${SAMPLE}.bt2.bz2" \
    --input_type bowtie2out --nproc ${SLURM_CPUS_PER_TASK} \
    --bowtie2db "$DB/metaphlan4" --index "$MPA_INDEX" --offline \
    -t rel_ab_w_read_stats -o "metaphlan/${SAMPLE}.readstats.tsv"
  ```

### S-02 · S1 · No step states its runtime; the 24h HUMAnN job invites a kill
- **Where:** SOP_READBASED_NeSI.md:536-562 (Section 10) and every other compute step (§3.3, §5, §6, §7, §8, §9); numbers exist only in Appendix C (860-878)
- **Anchor:** `Each sample generates 100–170 GB of temporary files`
- **Quote:**
  > **`--remove-temp-output` is mandatory** at cohort scale. Each sample generates 100–170 GB of temporary files; at ten concurrent tasks that is 1–1.7 TB.
- **Breaks:** R5 / §4 item 4 (every step states an order-of-magnitude runtime)
- **Reader impact:** Step template item 4 ("How long it takes") is absent from every step. The runtimes exist, but only in Appendix C, three pages away. A beginner who submits `10.humann.sl` and watches it sit for eight hours has no way to know that 24 hours is normal — the single most expensive step in the pipeline is exactly where a reader cancels a working job, wastes the queue time already spent, and re-runs it into the same wall. Six words at the step prevents this.
- **Fix:** Add a bold **How long** line to each compute step, taking the figure from Appendix C. For Section 10 (after the command block): **How long:** 12–24 hours per sample — the longest step in the pipeline. Do not kill it early; watch progress in `logs/${SAMPLE}.humann.log`. For the others: §3.3 databases "2–4 hours, run before you need them"; §5 FastQC "~30 minutes, MultiQC ~20"; §6 trim "~2 hours"; §7 host depletion "~1 hour"; §8 read accounting "~1–2 hours across the cohort"; §9 MetaPhlAn "~1–4 hours per sample".

### S-03 · S1 · PhiX drives Section 6 but is never defined
- **Where:** SOP_READBASED_NeSI.md:25 (roadmap), 256, 270-272, 288, 323
- **Anchor:** `trim + remove PhiX → QC again`
- **Quote:**
  > STAGE 3: Clean the reads
  >    QC → trim + remove PhiX → QC again → deplete host reads
- **Breaks:** R2 (term used before/without definition), R8 (jargon with no plain-language gloss)
- **Reader impact:** "PhiX" appears in the roadmap, the Section 6 title, and three code blocks, and is never once explained. A reader who has never met it cannot tell whether it is a contaminant to fear, a reagent, or a mistake they made — and cannot decide whether the two-pass removal matters for their data. It is Illumina control DNA, not biology; the reader needs one sentence saying so before Section 6 asks them to filter it. There is no glossary and no other occurrence to look it up in, which makes this S1.
- **Fix:** Introduce PhiX at first substantive use, in the Section 6 layer-1 paragraph (see S-05), with this clause: "Illumina also spikes every run with **PhiX**, a small bacteriophage genome used as a sequencing-quality control; its reads are real DNA but not part of your sample, so they must be removed too." One plain-language gloss upstream discharges every later use.

### S-04 · S1 · Profiling steps 9 and 10 carry no inline checkpoint
- **Where:** SOP_READBASED_NeSI.md:476-496 (§9), 540-556 (§10); existence checks sit only in Appendix B (843-846)
- **Anchor:** `[[ -s "metaphlan/${S}.profile.tsv" ]]`
- **Quote:**
  > while read -r S; do
  >   [[ -s "metaphlan/${S}.profile.tsv" ]] || echo "MISSING metaphlan: $S"
  >   [[ -s "humann/${S}/${S}_genefamilies.tsv" ]] || echo "MISSING humann: $S"
  > done < samples.txt
- **Breaks:** R5 / §4 (the checkpoint block — command, expected value, meaning of a mismatch — is item 5 and not optional)
- **Reader impact:** Sections 9 and 10 end at the command with no way for the reader to tell it worked. The success test exists — but it is the existence loop in Appendix B, which a beginner does not know to run and will not find mid-walkthrough. MetaPhlAn can exit 0 having produced an all-header profile with no species; HUMAnN can exit 0 with empty tables when the input FASTQ was empty (see the `$SAMPLE`-expands-empty failure in S-01). Without an inline "expect this, a mismatch means that", the reader scales a broken run across the whole cohort before noticing. Surface the check at the step, with a threshold and a diagnosis.
- **Fix:** Add a checkpoint block at the end of Section 9:

  ```bash
  grep -c 's__' "metaphlan/${SAMPLE}.profile.tsv"
  ```
  > **Expect** tens to a few hundred species lines for a typical gut sample. **Zero or a near-empty profile** means the reads did not map — check that `clean/${SAMPLE}_R1.fastq.gz` is non-empty and that `--index` and `--bowtie2db` point at the installed database, then re-run the task before scaling the array.

  And at the end of Section 10:

  ```bash
  ls -l "humann/${SAMPLE}/${SAMPLE}_genefamilies.tsv" "humann/${SAMPLE}/${SAMPLE}_pathabundance.tsv"
  ```
  > **Expect** both files present and non-empty. **Missing or empty** means HUMAnN found nothing to profile — usually an empty `clean/` FASTQ or a MetaPhlAn/ChocoPhlAn mismatch (Section 10's first bullet). Do not launch the full array until one sample produces both. Also add a MultiQC checkpoint at Section 5 (`ls qc/raw_report/multiqc_report.html`; **missing** means it ran before FastQC finished — resubmit with `--dependency=afterok`).

### S-05 · S2 · Section 6 opens on layer 2 with no layer 1 (adapters, PhiX, ktrim)
- **Where:** SOP_READBASED_NeSI.md:270-272
- **Anchor:** `This runs as **two passes, and they cannot be combined into one.**`
- **Quote:**
  > This runs as **two passes, and they cannot be combined into one.** The reason is that `ktrim=r` applies to every sequence in `ref=`. Listing PhiX alongside the adapters would therefore *truncate* PhiX-contaminated reads and keep the remainder, rather than discarding them.
- **Breaks:** R1 (layer 2 without layer 1), R3 (section opens on a command justification, not concept), R2/R8 (adapter, PhiX, ktrim undefined)
- **Reader impact:** This is the spec's own worked example. The reader arrives at Section 6 having never been told what an adapter is, why PhiX is in their data, or what `ktrim` does — and the very first thing the section does is explain a subtlety of `ktrim=r` behaviour. They copy both commands without knowing what either removes, and afterwards cannot tell whether the trimming worked. The layer-2 paragraph is correct and must be kept; it needs a layer-1 paragraph above it.
- **Fix:** Insert this layer-1 paragraph as the new opening of Section 6, immediately after the heading and before the existing "This runs as two passes…":

  > Sequencing does not stop cleanly at the end of your DNA fragment. When a fragment is shorter than the read, the machine reads on into the **adapter** — the short synthetic sequence that library prep attached to every fragment so it would bind the flow cell — and those bases are not biology. **Adapter trimming** finds and removes them. Illumina also spikes every run with **PhiX**, a small bacteriophage genome used as a sequencing-quality control; its reads are real DNA but not part of your sample, so they must be removed too. This section does both with **BBDuk** (part of the BBMap package): trim adapters in the first pass, filter PhiX in the second. `ktrim=r` below means "trim the matched k-mer and everything to its right".

  Keep the existing "This runs as two passes…" paragraph unchanged directly after it.

### S-06 · S2 · Section 10 opens on install steps; HUMAnN is never introduced
- **Where:** SOP_READBASED_NeSI.md:512-516
- **Anchor:** `### **Install a current release**`
- **Quote:**
  > ## **10. Function with HUMAnN**
  >
  > ### **Install a current release**
  >
  > **Do not use the `Humann/3.0.0.alpha.3` module.**
- **Breaks:** R1 (no layer 1 before the first instruction), R3 (section opens on a conda install, not a concept)
- **Reader impact:** Section 10 never says what HUMAnN *is* or *does*. It jumps straight to "install a current release" and a warning about which module to avoid. A reader who has just profiled taxonomy has no anchor for why they are now installing a second, heavier tool, what "function" means here, or what gene families and pathways are. They run a 24-hour job whose output they cannot interpret — the definition of S2. The install warning is excellent and stays; it needs a concept paragraph above it.
- **Fix:** Insert this layer-1 paragraph as the opening of Section 10, before "### Install a current release":

  > MetaPhlAn told you *who* is in each sample. **HUMAnN** tells you *what they can do*: it maps your reads to **gene families** (groups of related genes, here UniRef90 clusters) and reconstructs the metabolic **pathways** the community can carry out, so you can ask which functions differ between groups rather than only which species. It reuses Section 9's taxonomic profile to choose which reference genomes to search, which is why it runs after MetaPhlAn. Its database install is large and each sample is slow, so read both subsections below before you start.

### S-07 · S2 · Doc claims prior-pipeline experience the spec withdraws
- **Where:** SOP_READBASED_NeSI.md:11
- **Anchor:** `It assumes you have already run one pipeline on NeSI.`
- **Quote:**
  > **It assumes you have already run one pipeline on NeSI.** Bash, modules, `sbatch` and array jobs are taken as familiar. If they are not, work through `SOP_EMU_NeSI.md` Section 1 first.
- **Breaks:** R1 / §1 (one reader — a graduate student who has never opened a terminal; the assumption is explicitly withdrawn)
- **Reader impact:** Spec §1 names one reader for all documents and states outright that this line's assumption is withdrawn: "Someone who followed one pipeline six months ago does not thereby know what PhiX is or why `ktrim=r` matters." A genuine beginner reading "It assumes you have already run one pipeline on NeSI" may reasonably conclude the document is not for them and stop. The redirect to EMU §1 is the right instinct and must survive (it is the scope limit, never-cut #5) — but the framing must change from "you must already have done this" to "this document does not re-teach the cluster; here is where to learn it."
- **Fix:** Replace line 11 with:

  > **This SOP does not re-teach the cluster.** It uses bash, modules, `sbatch` and array jobs without explaining them. If you have not used them, work through `SOP_EMU_NeSI.md` Section 1 first — it starts from `pwd` and assumes no command-line experience.

### S-08 · S2 · Terms used before they are defined: BAL, SGB, CPM, RPK, stratified, rclr (R2)
- **Where:** SOP_READBASED_NeSI.md:56 (BAL), 470 (SGB), 634 (RPK/CPM), 34/639 (stratified), 728 (rclr), 755 (compositional), 5/153 (paired-end)
- **Anchor:** `mandatory for skin, nasal, BAL and any other low-biomass`
- **Quote:**
  > They are mandatory for skin, nasal, BAL and any other low-biomass sample type, because contamination screening (Section 12) is impossible without them.
- **Breaks:** R2 (first appearance carries no definition), R8 (abbreviation given with no expansion)
- **Reader impact:** A cluster of abbreviations appears cold. BAL (used 4×) is never expanded; SGB, CPM and RPK are used as if known; "stratified/unstratified" is defined only inside a code comment at L639; "paired-end", "rclr" and "compositional" are used without a gloss. Individually small; together they are the R2 evidence, and each is a place a reader stops to guess. Add a one-line definition at first use — no paragraph swelling, per F2.
- **Fix:** Insert each definition at the cited first use (one sentence, in place):
  - L56, first "BAL": "(BAL — bronchoalveolar lavage, a saline wash of the lung)".
  - L5/L7, "paired-end": add once near the opening — "Illumina sequences each fragment from both ends, giving two files per sample, `_R1` and `_R2`, whose reads are *mates*."
  - L470, first "SGB": "(SGB — species-level genome bin, MetaPhlAn's genome-based unit, roughly a species including unnamed ones)".
  - §11, first "RPK"/"CPM": "RPK is reads per kilobase (length-corrected, not depth-corrected); CPM is copies per million, the depth-normalised unit."
  - §11 opening, "stratified": "**Unstratified** tables give one number per feature for the whole community; **stratified** tables break that number down by contributing species." (promote out of the L639 comment).
  - L722/L728, "compositional"/"rclr": "These abundances are **compositional** — proportions of a fixed total, so one taxon rising forces others down; they carry only relative information. **rclr** (robust centred log-ratio) is a compositional transform that tolerates zeros without a pseudocount."

### S-09 · S3 · Section 4 is a reference block in the numbered spine, enabling the header defect
- **Where:** SOP_READBASED_NeSI.md:199-223
- **Anchor:** `## **4. The Standard Job Header**`
- **Quote:**
  > ## **4. The Standard Job Header**
  >
  > Every script in this SOP uses the header below.
- **Breaks:** R6 (the numbered spine is performance order; §4 is a reference, not a performed step), R4 (front-loaded setup), R3 (reference material mid-walkthrough)
- **Reader impact:** Section 4 is not an action the reader performs at position 4 — it is reference material that exists only to be pointed back to, and its "add it yourself" instruction is what creates the R11 defect (S-01). A numbered step slot spent on a lookup table pushes the first real action (QC) to Section 5 and teaches the reader that headers live somewhere other than the script they copy. Once headers are inlined (S-01), Section 4's separate existence is redundant.
- **Fix:** After inlining the full header into every script (S-01), reduce Section 4 to a two-line note kept where it is or folded into Appendix C: "Every script below carries the complete job header. The per-script resource values (`--time`, `--mem`, `--cpus-per-task`) are in Appendix C; set the array range at submission with `sbatch --array=1-${NSAMP}%20`, never in the header." Do not renumber Sections 5–14 (script filenames and cross-references depend on the current numbers); leave Section 4 as a short reference stub in place.

### S-10 · S3 · Preflight module checks front-loaded and duplicated by the closing paragraph
- **Where:** SOP_READBASED_NeSI.md:100-120 (§2 Preflight) and 882 (closing paragraph)
- **Anchor:** `Run Section 2 first, not after a failed array.`
- **Quote:**
  > **Before relying on this SOP, verify the environment.** Section 2 covers most of it: whether `/opt/nesi/db/` exists, the MultiQC, MetaPhlAn, fastp and HUMAnN module strings including capitalisation, whether compute nodes have internet, and the current platform name after NeSI's 2025 refresh. Run Section 2 first, not after a failed array.
- **Breaks:** R4 (front-loaded block of environment checks), V6 (the closing paragraph restates Section 2), F (duplication drifts)
- **Reader impact:** The environment verification is stated twice — as the Section 2 Preflight block and again as a full paragraph at the very end of the document. Two copies of the same instruction drift apart when one is edited. The closing paragraph adds nothing Section 2 does not already say and sits after the appendices, where a reader following the workflow has long since acted. The storage/quota half of Section 2 legitimately stays up front (R4 exception); the module-spider verification is the front-loaded part, but it earns its place as a one-time "does my environment still match" gate — the fix here is the duplication, not Section 2 itself.
- **Fix:** Delete the closing paragraph at line 882 in full. If a pointer is wanted at the end, replace it with a single sentence: "If anything here failed, re-run Section 2 — module strings and platform names drift between refreshes." Keep Section 2 as the single source.

### S-11 · S3 · Method-choice paragraph runs to 100 words (F1) — rewrite tighter
- **Where:** SOP_READBASED_NeSI.md:753
- **Anchor:** `On method choice: benchmarking has repeatedly found`
- **Quote:**
  > On method choice: benchmarking has repeatedly found that the more elaborate compositional methods control false discovery rates less well than their complexity implies. Yang & Chen 2022 (*Microbiome* 10:130) report FDR inflation for several of them at small sample sizes, and find that linear models, the Wilcoxon test, limma and fastANCOM control false discoveries at comparable sensitivity. Nearing et al. 2022 (*Nature Communications*) found ALDEx2 and ANCOM-II the most conservative and the most concordant across 38 datasets. Read ALDEx2 at small N as a defensible *conservative* choice — few false positives, low power — rather than as the reliable one.
- **Breaks:** F1 (100 words > 80); R1/F5 — this is why-this-tool content and both citations (never-cut #1, #4) must survive the tightening, never be cut
- **Reader impact:** The paragraph is the doc's one genuine F1 violation (the scan's other four hits are numbered/bulleted lists the scanner concatenates, not walls of text). It carries two primary citations and a recommendation, so it cannot be cut — only tightened. At 100 words it is the kind of dense block a scanning, tired reader skips, losing exactly the guidance that keeps them from over-trusting an elaborate method.
- **Fix:** Replace L753 with this 78-word version, which keeps both citations and the ALDEx2 conclusion:

  > On method choice: elaborate compositional methods often control false discovery rates worse than their complexity implies. Yang & Chen 2022 (*Microbiome* 10:130) report FDR inflation at small sample sizes, with linear models, Wilcoxon, limma and fastANCOM matching them on sensitivity. Nearing et al. 2022 (*Nature Communications*) found ALDEx2 and ANCOM-II the most conservative and most concordant across 38 datasets. At small N, read ALDEx2 as a defensible *conservative* choice — few false positives, low power — not the reliable one.

### S-12 · S3 · Doc nudges toward a newer BBMap (39.09/39.10) that does not exist
- **Where:** SOP_READBASED_NeSI.md:301-303
- **Anchor:** `so prefer a newer BBMap if`
- **Quote:**
  > Releases 39.09 and 39.10 improved the trimmer to tolerate poly-G runs interrupted by the occasional non-G base. Version 39.01 catches clean runs only, so prefer a newer BBMap if `module spider BBMap` offers one.
- **Breaks:** R7 (recommends a default the reader cannot obtain — no such module exists), N3-style staleness (claim about the environment is not true now)
- **Reader impact:** `reviews/structure/00_REALITY.md` confirms 39.01 is the newest BBMap on Mahuika — `module spider BBMap` returns 38.73, 38.81, 38.90, 38.95, 39.01 and nothing higher. The paragraph names two non-existent versions (39.09, 39.10) and tells the reader to prefer them "if offered". A reader following the advice searches, finds nothing, and is left unsure whether their poly-G handling is adequate. The hedge ("if offered") softens it, but the doc still presents a dead upgrade path as the better option.
- **Fix:** Replace both sentences with:

  > Version 39.01 (the newest BBMap on the cluster) catches clean poly-G runs. If your two-colour data has poly-G runs interrupted by the occasional non-G base, use the fastp alternative below, whose `--trim_poly_g` handles interrupted runs.

  This keeps the real limitation of 39.01 and points at the fastp route already documented in Section 6, instead of a version that does not exist.

### S-13 · S4 · Voice omnibus: no we for lab decisions (V1), banned words (V3), minor form
- **Where:** SOP_READBASED_NeSI.md:whole document; V1 (no `we` anywhere); V3 at 92, 221, 407, 740
- **Anchor:** `the single easiest mistake to make in this SOP`
- **Quote:**
  > This is the single easiest mistake to make in this SOP — forget it and the job runs successfully on sample 1 only, with no error to alert you.
- **Breaks:** R9 / V1 (`we` used 0×, so lab decisions read as impersonal fact), V3 (`simply`, `easiest`)
- **Reader impact:** Small, cosmetic, and merged here per the S4 cap. Two threads: (1) V1 — the document uses `we` zero times, so every lab decision ("we pin the index", "we prefer T2T-CHM13", "we default to Hostile") reads as impersonal fact rather than a marked Taylor Lab choice; the spec wants `we chose` versus `you run` doing visible work. (2) V3 — `simply` at L407 and L740, `easiest` at L92 and L221 are the four banned/adjacent words; each dents a beginner who does not find the thing easy. UK spelling (V5) and person (`you`/no `the user`) are clean.
- **Fix:** (a) Where a paragraph states a Taylor Lab decision, mark it with `we`: e.g. L195 "Pin the MetaPhlAn index" → "**We pin** the MetaPhlAn index rather than accepting the default"; L346 "Option A … (recommended)" body → "**We default to** Hostile because it fetches its own masked index"; §7 "Why T2T-CHM13v2.0" → "**We use** T2T-CHM13v2.0…". Reserve `we` for these layer-2 choices only, never for a reader action. (b) Remove the banned words: L407 "clean is not simply raw minus host" → "clean is not raw minus host"; L740 "may simply reflect" → "may reflect"; L92 "the easiest way to arrive at" → "the surest way to arrive at"; L221 "the single easiest mistake to make" → "the mistake most often made". (c) These are the only V-rule hits — no other register, person, or spelling changes are needed.

## Target outline

The full heading structure the finished document should have, in order. `KEEP` = exists, unchanged. `REWRITE` = same slot, changed content. `NEW` = insert. `MOVE` = relocate. Someone can rebuild the document from this plus the findings.

```
*Taylor Lab | Read-Based Shotgun Metagenomics SOP*                     KEEP
# Read-Based Shotgun Metagenomics: Taxonomy and Function on NeSI       KEEP
**v3.0** | ... | Illumina paired-end | human-associated samples        KEEP
Opening paragraph (what it does, what it produces)                     KEEP
  + one-sentence paired-end gloss                                      NEW (S-08)
Scope: human-associated only; no assembly                              KEEP (never-cut #5)
"This SOP does not re-teach the cluster" (was line 11)                 REWRITE (S-07)

## Quick Roadmap: What You'll Do                                       KEEP

## 1. Before You Generate Data                                        KEEP
### Governance                                                         KEEP (never-cut #6)
### Controls                                                           KEEP; +BAL gloss (S-08)
### Depth                                                              KEEP (never-cut #1)

## 2. Preflight and Storage                                           KEEP
### Preflight                                                          KEEP (single source; S-10)
### Storage                                                            KEEP (R4 exception)

## 3. Setup
### 3.1 Directories and the sample manifest                           KEEP; +NSAMP checkpoint
### 3.2 Modules                                                       KEEP
### 3.3 References and databases                                      KEEP; +runtime (S-02)

## 4. The Standard Job Header                                         REWRITE → short stub (S-09)
   (full header now inlined into every script below, S-01)

## 5. Quality Control                                                 KEEP
   + layer-1: what QC checks / what FastQC is (1-2 sentences)         NEW (R1)
   + MultiQC-exists checkpoint                                        NEW (S-04)
### Reading the reports                                               KEEP
### Identify your chemistry now                                       KEEP

## 6. Trimming and PhiX Removal
   layer-1: adapters, PhiX, ktrim, BBDuk                              NEW (S-05, S-03)
   "This runs as two passes…" (layer-2)                               KEEP (never-cut #1)
   06.trim.sl — with full header                                      REWRITE (S-01)
   + runtime line                                                     NEW (S-02)
### Two-colour chemistry: poly-G                                      REWRITE (S-12)
### Alternative: fastp for pass one                                   KEEP; +header/runtime

## 7. Host Depletion                                                  KEEP (the model section)
### Why T2T-CHM13v2.0                                                 KEEP (never-cut #1,#4)
### Why the reference must be masked                                  KEEP (never-cut #1)
### Option A — Hostile (recommended)                                  KEEP; +header/runtime/checkpoint
### Option B — BBMap unmasked                                         KEEP; +header/runtime
### Expected host fraction by site                                    KEEP

## 8. Read Accounting and Depth Gates                                 KEEP (collective checkpoint)
### The gates                                                         KEEP (never-cut #3); +runtime

## 9. Taxonomy with MetaPhlAn 4                                       KEEP (has layer-1)
   09.metaphlan.sl — full header (exemplar)                           REWRITE (S-01)
   + runtime + species-count checkpoint                              NEW (S-02, S-04)
### Why --index and --offline are not optional                       KEEP (never-cut #1)
### Why there are two passes                                         KEEP (never-cut #1)

## 10. Function with HUMAnN
   layer-1: what HUMAnN does, gene families, pathways                 NEW (S-06)
### Install a current release                                        KEEP (never-cut warning)
### Running it                                                       KEEP; +header/runtime/checkpoint
   10.humann.sl — full header                                         REWRITE (S-01)

## 11. Merging, Normalising and Splitting Tables
   + layer-1: stratified/unstratified, CPM, RPK one-liner            NEW (S-08)
### Taxonomy: relative abundance                                     KEEP
### Taxonomy: estimated counts                                       KEEP
### Function                                                         KEEP
### What Section 13 needs                                            KEEP

## 12. Contamination Screening                                       KEEP (never-cut #2,#3)

## 13. Statistics: What Changes from SOP_R_Analysis.md               KEEP
### Reshape before you open Part 2                                   KEEP (never-cut #2)
### Beta diversity                                                   KEEP; +rclr/compositional gloss
### PERMANOVA                                                        KEEP
### Differential abundance                                           KEEP; L753 tightened (S-11)
### Functional tables                                                KEEP (never-cut #2)

## 14. Provenance                                                    KEEP (never-cut, methods)

## Appendix A: Submission Chain                                      KEEP
## Appendix B: Triage                                                KEEP (checkpoints also surfaced inline)
## Appendix C: Resources                                             KEEP (runtimes also surfaced at steps)
(closing "verify the environment" paragraph)                         CUT (S-10)
```

## Keep list

Content that must survive the restructure, with why a rewrite would be tempted to drop it.

1. **The backwards depth arithmetic** (L78-94, "Divide, do not multiply") — a rewrite compressing Section 1 would cut the worked BAL example; it is the whole point (never-cut #1).
2. **Governance / re-identification** (L48-52, Tomofuji 2023) — ethics + primary citation; never-cut #4, #6.
3. **Controls table + mock-community rationale** (L58-65) — never-cut #3, #5.
4. **"Why T2T-CHM13v2.0" and "Why masked"** (L336-344, two benchmark citations) — the exemplar layer-2; never-cut #1, #4.
5. **`--index`/`--offline` reproducibility** (L498-500) — silent DB-drift failure; never-cut #1, #2.
6. **"Why two passes" + model-estimated caveat** (L502-508, "do not use them for alpha diversity") — never-cut #1, #2.
7. **The `Humann/3.0.0.alpha.3` warning** (L514-516) — a restructure that adds a layer-1 opener could displace it; keep it (never-cut #2).
8. **The `ktrim=r` two-pass reasoning** (L272) — the layer-2 that S-05 adds a layer-1 *above*, not instead of.
9. **Reshape-before-Part-2 / silent rounding** (L684-706) — the single highest-value silent-failure warning; never-cut #2.
10. **Section 8 gates table** (L455-464) — the collective checkpoint for the cleaning stage; never-cut #3.
11. **zcat-pipefail, `-s`, trap, round() traps** (L436-440, L630, L549, L715) — R10 content, the strongest in the set; must not thin.
12. **Section 13 deltas table + UniFrac/Faith's additions** (L709-718) — never-cut #1, #2; adapts Part 2 correctly.
13. **Provenance block** (L765-801) — methods reproducibility; never-cut.
14. **BAL/high-host "spend effort at the bench" point** (L94, L420) — the non-obvious conclusion the depth section builds to.

## Rewrite plan

Ordered, dependency-aware. Every change is internal to this file; none depends on the other three SOPs.

1. **Inline the job header into all eight scripts (S-01).** Closes the document's worst defect. Mechanical given the values table. Do first — the assembled `09.metaphlan.sl` becomes the reference the reader sees; then reduce Section 4 to a stub (S-09). ~+90 words net (header × 8, minus Section 4 body).
2. **Add per-step runtime and profiling checkpoints (S-02, S-04).** Numbers come from Appendix C and existence checks from Appendix B — no new facts, just surfaced at the step. ~+60 words.
3. **Add the three missing layer-1 openers (S-05, S-06, and QC).** Independent of 1–2. This is the structural fix the spec measures (layer-1 count must go up). Carries the PhiX definition (S-03). ~+230 words.
4. **Reframe line 11 and add first-use glosses (S-07, S-08).** One-line inserts at first use; no relocation. ~+70 words.
5. **Tighten L753 and cut the closing paragraph (S-11, S-10).** This is where the word budget comes back: −22 words on L753, −55 on the closing paragraph. Together roughly offset the definitions added in 2–4, keeping net count near flat as the brief requires.
6. **Fix the BBMap version nudge (S-12).** Self-contained, one paragraph.
7. **Voice pass (S-13).** Last, after content settles: add `we` to marked lab decisions, remove the four banned words.

Net effect: layer-1 heading count rises (QC, §6, §10, plus §11 opener); the over-80 paragraph count falls (L753 fixed, nothing new over 80 — the new layer-1 paragraphs are each under the ~100-word layer-1 allowance and under 80 where prose); word count stays roughly flat. Both §11 checks pass.

## Self-check

```
findings=13 S1=4 S2=4 S3=4 S4=1
CLEAN
```

Manual confirmation:
- **Ledger accounts for every heading:** all 14 numbered sections, all subsections, 3 appendices, front matter and the closing paragraph are listed. Yes.
- **Target outline covers every section in the ledger:** every ledger row maps to an outline line (KEEP/REWRITE/NEW/MOVE/CUT). Yes.
- **Nothing on the keep list is proposed for removal:** the only CUT is the closing duplicate paragraph (S-10), which is not on the keep list; the L753 and Section-4 changes are rewrite/tighten, not cuts of keep-list content. Yes.

CONTRACT: PASS
