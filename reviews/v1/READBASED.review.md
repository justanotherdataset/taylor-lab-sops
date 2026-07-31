## Document: SOP_READBASED_NeSI.md

This is trying to be a self-contained walkthrough that takes a reader who has finished one
NeSI pipeline from raw Illumina shotgun FASTQs to analysis-ready taxonomic and functional
tables, plus the deltas needed to run Part 2 on compositional input. It is close: the
explain-then-command discipline is consistent, the why-this-number paragraphs are dense and
mostly excellent, the silent-failure warnings (`--array=1-1`, MultiQC without `--dependency`,
`-s` on `humann_join_tables`, the `trap` in Section 10, CRLF in the manifest) are the best
content in the repository, and the internal cross-references and resource numbers reconcile
almost everywhere. What it is not yet is *safe at the two ends*. Section 1's depth budget
tells the reader to multiply by the host fraction where the correct operation is to divide by
one minus it — an error that under-orders sequencing by up to two orders of magnitude and
cannot be fixed afterwards. At the other end, Section 11 hands Section 13 a set of tables that
are not, as produced, analysis-ready: the EC and KO tables are never split, the sample column
names are derived by three different rules and never reconciled, the species-table header may
be a comment line, and the SRS row contradicts Section 9's own warning about estimated counts.
**The single change that would most improve this document is to end Section 11 with a
validation block that proves the tables are analysis-ready** — split every regrouped table,
normalise sample names to one convention across all of them, and print the checks (column
sums, header, sample list) that let the reader see it worked. That closes four findings and
converts the weakest handoff in the document into its strongest.

## Section ledger

| § | Heading | Lines | Verdict | Findings |
|---|---|---|---|---|
| — | Front matter / title | 1–13 | CLEAN | — |
| — | Quick Roadmap: What You'll Do | 15–42 | CLEAN | — |
| 1 | Before You Generate Data | 44–47 | CLEAN | — |
| 1a | Governance | 48–53 | CLEAN | — |
| 1b | Controls | 54–66 | TIGHTEN | F-15 |
| 1c | Depth | 67–80 | REWRITE | F-01, F-04 |
| 2 | Preflight and Storage | 82–83 | CLEAN | — |
| 2a | Preflight | 84–103 | CLEAN | F-26 (omnibus) |
| 2b | Storage | 104–117 | CLEAN | — |
| 3 | Setup | 119–120 | CLEAN | — |
| 3.1 | Directories and the sample manifest | 121–148 | TIGHTEN | F-16 |
| 3.2 | Modules | 149–156 | CLEAN | — |
| 3.3 | References and databases | 157–176 | TIGHTEN | F-17, F-26 |
| 4 | The Standard Job Header | 178–204 | CLEAN | — |
| 5 | Quality Control | 206–230 | TIGHTEN | F-18 |
| 5a | Reading the reports | 231–236 | CLEAN | — |
| 5b | Identify your chemistry now | 237–247 | CLEAN | — |
| 6 | Trimming and PhiX Removal | 249–277 | EXPAND | F-19, F-26 |
| 6a | Two-colour chemistry: poly-G | 278–283 | CLEAN | F-26 |
| 6b | Alternative: fastp for pass one | 284–309 | TIGHTEN | F-20, F-26 |
| 7 | Host Depletion | 311–314 | CLEAN | — |
| 7a | Why T2T-CHM13v2.0 | 315–320 | CLEAN | — |
| 7b | Why the reference must be masked | 321–324 | CLEAN | — |
| 7c | Option A — masked index via Hostile | 325–354 | CLEAN | — |
| 7d | Option B — BBMap against unmasked T2T | 355–387 | REWRITE | F-05, F-06 |
| 7e | Expected host fraction by site | 388–399 | CLEAN | — |
| 8 | Read Accounting and Depth Gates | 401–429 | CLEAN | — |
| 8a | The gates | 430–443 | EXPAND | F-07, F-21 |
| 9 | Taxonomy with MetaPhlAn 4 | 445–467 | CLEAN | — |
| 9a | Why `--index` and `--offline` are not optional | 468–471 | CLEAN | — |
| 9b | Why there are two passes | 472–480 | CLEAN | — |
| 10 | Function with HUMAnN | 482–483 | CLEAN | — |
| 10a | Install a current release | 484–500 | REWRITE | F-08 |
| 10b | Running it | 501–529 | EXPAND | F-09 |
| 11 | Merging, Normalising and Splitting Tables | 531–538 | CLEAN | — |
| 11a | Taxonomy: relative abundance | 539–551 | REWRITE | F-10, F-11 |
| 11b | Taxonomy: estimated counts | 552–579 | TIGHTEN | F-10, F-22 |
| 11c | Function | 580–606 | REWRITE | F-02, F-10, F-26 |
| 11d | What Section 13 needs | 607–617 | REWRITE | F-02, F-26 |
| 12 | Contamination Screening | 619–628 | CLEAN | — |
| 13 | Statistics: What Changes from `SOP_R_Analysis.md` | 630–648 | REWRITE | F-03, F-12, F-26 |
| 13a | Beta diversity | 649–658 | CLEAN | — |
| 13b | PERMANOVA | 659–670 | TIGHTEN | F-26 |
| 13c | Differential abundance | 671–685 | CLEAN | — |
| 13d | Functional tables | 686–692 | REWRITE | F-02 |
| 14 | Provenance | 694–726 | EXPAND | F-13, F-23 |
| A | Appendix A: Submission Chain | 728–758 | CLEAN | — |
| B | Appendix B: Triage | 759–781 | EXPAND | F-14, F-24, F-25 |
| C | Appendix C: Resources | 782–801 | TIGHTEN | F-26 |
| — | Closing verification note | 802–805 | MERGE | F-26 |

## Findings

### F-01 · S1 · Depth budget multiplies by host fraction instead of dividing
- **Where:** SOP_READBASED_NeSI.md:69, § 1 Depth
- **Quote:**
  > Budget depth on the reads that survive trimming and host depletion, not on what the sequencer produces. At a high-host site most of your data is human, so multiply your target by the expected host fraction (Section 7 gives typical values) when deciding what to order.
- **Defect:** The arithmetic is inverted. To end with a target number of clean pairs you divide
  by `(1 − host fraction)`; multiplying by the host fraction *reduces* the order, and reduces it
  most at exactly the sites where you need the largest increase.
- **Failure:** A reader sampling saliva looks up "Oral, saliva, vaginal | >90%" in the table at
  line 392, reads line 69, and orders `5,000,000 × 0.9 = 4.5 million` read pairs instead of the
  `5,000,000 ÷ 0.10 ÷ 0.85 ≈ 59 million` actually required. Every sample then fails the
  `clean_pairs below ~5 million` gate at line 437, and Section 1's own opening sentence —
  "Three things cannot be fixed after sequencing" — means the run is unrecoverable. For BAL at
  99.7% host the instruction changes the order by 0.3% where a 333-fold increase is needed.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — contradicts the document's own host-fraction table (line 392–395)
  and its own clean-depth targets (lines 73–76); no reading of "multiply by the host fraction"
  produces a larger number than the target.
- **Fix:** Replace line 69 with:

  > Budget depth on the reads that survive trimming and host depletion, not on what the
  > sequencer produces. Work backwards from the clean depth you need:
  >
  > ```
  > raw pairs to order  =  clean pairs needed  ÷  (1 − host fraction)  ÷  trim survival
  > ```
  >
  > Take the host fraction from the table in Section 7 and use 0.85 for trim survival (Section 8
  > flags anything below 0.80). Worked through:
  >
  > | Site | Host fraction | Raw pairs to order for 5 M clean pairs |
  > | --- | --- | --- |
  > | Stool | 0.10 | 5 000 000 ÷ 0.90 ÷ 0.85 ≈ **6.5 million** |
  > | Oral / saliva | 0.90 | 5 000 000 ÷ 0.10 ÷ 0.85 ≈ **59 million** |
  > | BAL, no wet-lab depletion | 0.997 | 5 000 000 ÷ 0.003 ÷ 0.85 ≈ **2 billion** |
  >
  > The BAL row is not a typo. It is why Section 7 says that at high-host sites wet-lab depletion
  > at the bench achieves far more than any amount of extra sequencing.

### F-02 · S1 · EC and KO tables never split, then handed to MaAsLin as a test set
- **Where:** SOP_READBASED_NeSI.md:601-602 and 688, § 11 Function and § 13 Functional tables
- **Quote:**
  > humann_regroup_table -i tables/genefamilies_cpm.tsv -g uniref90_level4ec -o tables/ec_cpm.tsv
  > humann_regroup_table -i tables/genefamilies_cpm.tsv -g uniref90_ko       -o tables/ko_cpm.tsv

  and

  > `SOP_R_Analysis.md` does not cover these, so this SOP owns them. Run MaAsLin 2 or 3 on the `_unstratified` CPM tables, or on `ec_cpm.tsv`, with `normalization = "NONE"` — the tables are already normalised.
- **Defect:** `humann_regroup_table` preserves stratification, so `ec_cpm.tsv` and `ko_cpm.tsv`
  inherit both the community-total rows and the per-species rows of `genefamilies_cpm.tsv`.
  Neither is passed through `humann_split_stratified_table`, yet line 688 offers `ec_cpm.tsv` as
  a drop-in alternative to the split `_unstratified` tables.
- **Failure:** The reader runs MaAsLin on `ec_cpm.tsv`. Every EC number is tested twice over —
  once as the community total and again as each contributing species — inside one BH family.
  The tests are not independent (the stratified rows sum to the community total), the feature
  count is inflated ten- to fiftyfold, and the resulting q-values are wrong in an unpredictable
  direction. Nothing errors, and the output table looks exactly like a correct one. This is the
  precise error the document names at lines 596–597 ("testing both in one multiple-testing
  family is a statistical error") and again at line 678.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — internal contradiction between lines 596–599 (which split
  `genefamilies_cpm` and `pathabundance_cpm` for this stated reason), line 678, and line 688.
- **Fix:** Replace lines 601–602 with:

  ```bash
  humann_regroup_table -i tables/genefamilies_cpm.tsv -g uniref90_level4ec -o tables/ec_cpm.tsv
  humann_regroup_table -i tables/genefamilies_cpm.tsv -g uniref90_ko       -o tables/ko_cpm.tsv

  # Regrouping preserves stratification, so ec_cpm.tsv and ko_cpm.tsv carry BOTH the community
  # totals and the per-species rows, exactly as genefamilies_cpm.tsv did. Split them too.
  humann_split_stratified_table -i tables/ec_cpm.tsv -o tables/
  humann_split_stratified_table -i tables/ko_cpm.tsv -o tables/
  ```

  Replace the table row at line 615 with:

  > | `ec_cpm_unstratified.tsv`, `ko_cpm_unstratified.tsv` | Community-level function regrouped to enzyme commission numbers and KEGG orthologues, CPM |
  > | `ec_cpm_stratified.tsv`, `ko_cpm_stratified.tsv` | The same, per contributing species — follow-up only |

  Replace line 688 with:

  > `SOP_R_Analysis.md` does not cover these, so this SOP owns them. Run MaAsLin 2 or 3 on the
  > `_unstratified` CPM tables — `genefamilies_cpm_unstratified.tsv`,
  > `pathabundance_cpm_unstratified.tsv`, `ec_cpm_unstratified.tsv`, `ko_cpm_unstratified.tsv` —
  > with `normalization = "NONE"`, because the tables are already CPM. **Never test an unsplit
  > table.** It holds each feature's community total alongside the per-species rows that sum to
  > it, so the tests are not independent and the multiple-testing correction is meaningless.

### F-03 · S1 · SRS row routes estimated counts into the alpha diversity Section 9 forbids
- **Where:** SOP_READBASED_NeSI.md:640, § 13 table
- **Quote:**
  > | **SRS normalisation** | **Does not apply** — SRS subsamples integer counts. Use `merged_species_counts.tsv` and state that the counts are model-estimated, or skip normalisation: the profile is already compositional. |
- **Defect:** In `SOP_R_Analysis.md` SRS normalisation exists to make alpha diversity comparable
  across depths. Telling the reader to "use `merged_species_counts.tsv`" for that step directly
  contradicts line 476, which forbids using those counts for alpha diversity. The row also omits
  the `round()` step that line 644 says these floats require.
- **Failure:** The reader reads "does not apply … use `merged_species_counts.tsv`", builds
  `ps_estcounts`, runs SRS on it, and computes Shannon and observed richness from the result.
  SRS on unrounded model-estimated floats either silently truncates or errors; if it runs, the
  alpha-diversity values are derived from an EM model's read attribution rather than from
  sequencing, are not comparable across samples, and carry no warning. The reader reports them
  as ordinary diversity numbers. Line 476, two hundred lines earlier, says not to.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — line 476 states "do not use them for alpha diversity"; line 640
  points the normalisation step whose purpose is alpha diversity at that same table.
- **Fix:** Replace the row at line 640 with:

  > | **SRS normalisation** | **Skip it.** SRS subsamples integer counts, and `merged_species.tsv` holds relative abundance, which is already depth-normalised — go straight to beta diversity and to the Shannon / Simpson / Pielou metrics below. Do **not** substitute `merged_species_counts.tsv`: those are model-estimated floats, and Section 9 rules them out for alpha diversity. That table exists for differential abundance only. If depth genuinely varies enough to worry you, subsample the FASTQs before profiling (Section 1), not the profiles afterwards. |

### F-04 · S2 · Depth subsampling given with no target, no output path and no downstream wiring
- **Where:** SOP_READBASED_NeSI.md:78, § 1 Depth
- **Quote:**
  > Neither MetaPhlAn nor HUMAnN rarefies internally, so uneven depth propagates straight into your results. If depth varies widely across samples, subsample to a common depth with `reformat.sh samplereadstarget=` before Section 9, and say so in your methods.
- **Defect:** A flag with no value, no input or output files, no threshold for "varies widely",
  and no statement that Sections 9 *and* 10 both read `clean/` and would both need repointing.
  This is the only remedy the document offers for a hazard it calls out as propagating "straight
  into your results".
- **Failure:** The reader sees `clean_pairs` ranging 4 M to 40 M in `tables/read_counts.tsv`,
  decides to subsample, has nothing to run, and either skips it (and reports richness that
  tracks depth) or writes the subsampled reads over `clean/`, invalidating the read accounting in
  Section 8 and leaving no record of the original depths for the methods section.
- **Type:** GAP
- **Confidence:** CONFIRMED — the sentence names a flag and no argument; no other part of the
  document supplies the missing mechanics.
- **Fix:** Replace line 78 with:

  > Neither MetaPhlAn nor HUMAnN rarefies internally, so uneven depth propagates straight into
  > your results: a deeper sample simply detects more low-abundance species. If `clean_pairs`
  > (Section 8) spans more than about three-fold across the cohort, subsample to a common depth
  > before Section 9. Take the target from the smallest `clean_pairs` you are keeping, and write
  > to a new directory so Section 8's accounting stays valid:
  >
  > ```bash
  > module load BBMap/39.01-GCC-11.3.0
  > mkdir -p sub
  > TARGET=5000000        # read PAIRS - set from the smallest clean_pairs you are keeping
  > while read -r S; do
  >   reformat.sh in1="clean/${S}_R1.fastq.gz" in2="clean/${S}_R2.fastq.gz" \
  >     out1="sub/${S}_R1.fastq.gz" out2="sub/${S}_R2.fastq.gz" \
  >     samplereadstarget=$TARGET sampleseed=42 -Xmx8g
  > done < samples.txt
  > # BBTools counts a pair as one unit for paired input. Confirm on the first sample before
  > # running the loop: `echo $(( $(zcat sub/<sample>_R1.fastq.gz | wc -l) / 4 ))` must equal
  > # $TARGET. If it is half that, double TARGET.
  > ```
  >
  > `sampleseed` makes the draw reproducible. If you do this, change `clean/` to `sub/` in the
  > Section 9 and Section 10 scripts as well, and record the target in your methods.

### F-05 · S2 · Option B applies masked-reference parameters to an unmasked reference, unresolved
- **Where:** SOP_READBASED_NeSI.md:323 and 355-357, § 7 Why the reference must be masked / Option B
- **Quote:**
  > This matters for Option B below, whose parameters come from JGI's recipe and assume a masked reference.

  and

  > ### **Option B — modules only, BBMap against unmasked T2T**
  >
  > Use this only if you cannot install Hostile, and only if two conditions hold: you have a mock community (Section 1) to quantify how much microbial signal you lose, and your methods section states that the reference was unmasked.
- **Defect:** The document establishes that these parameters presuppose a masked reference, then
  gives an option that violates that presupposition, and never says what to do about it — no
  expected magnitude of loss, no parameter to adjust, no pointer to a masked reference.
- **Failure:** A reader who cannot install Hostile takes Option B, loses genuine microbial reads
  from rRNA, conserved and low-complexity regions with no error and no flag in the output, and
  has no basis for deciding whether the loss is 0.1% or 10%. The mock-community condition is
  stated but not operationalised: nothing says to profile the mock through the same pipeline,
  compare against its expected composition, or what number to record.
- **Type:** GAP
- **Confidence:** CONFIRMED — line 323 states the assumption; the Option B heading states that it
  is not met; nothing between them reconciles the two.
- **Fix:** Replace lines 355–357 with:

  > ### **Option B — modules only, BBMap against an unmasked T2T reference**
  >
  > Use this only if you cannot install Hostile, and understand what it costs before you commit.
  > The parameters below are JGI's, and as Section 7 says, JGI's recipe assumes a *masked*
  > reference. Run against unmasked `chm13v2.0.fa.gz` they will delete genuine microbial reads
  > from rRNA, conserved and low-complexity regions — silently, with no error and nothing in the
  > output to flag it. Two conditions therefore apply and both are mandatory:
  >
  > 1. **Quantify the loss with your mock community.** Run the mock through Sections 6, 7 and 9
  >    twice, once through Option B and once with the host-depletion step skipped entirely, and
  >    compare the two species profiles. The taxa lost, and the percentage of mock reads removed,
  >    are your over-removal estimate. Without that number you have no idea how large the loss is
  >    and cannot defend the result.
  > 2. **State it in your methods:** that the human reference was unmasked, and the number from
  >    step 1.
  >
  > Raising `minid=0.95` reduces over-removal but also reduces host removal; do not change it
  > without re-running the mock. If you can obtain a masked human reference, substitute it at the
  > indexing step and say so — that removes the need for condition 2.

### F-06 · S2 · `07a` and `07b` depend on a `$DB` that the other scripts deliberately spell out
- **Where:** SOP_READBASED_NeSI.md:363 and 375, § 7 Option B
- **Quote:**
  > cd "$DB/human"

  and

  >   path="$DB/human" \
- **Defect:** These are the only two SLURM scripts in the document that read a shell variable
  defined in Section 3.1 rather than writing the path out. `scripts/07.host_hostile.sl` (line
  342), `scripts/09.metaphlan.sl` (line 453) and `scripts/10.humann.sl` (line 510) all spell out
  `/nesi/nobackup/<your_nesi_project_code>/…` for exactly this reason. The standard header sets
  `set -euo pipefail`, so an unset `$DB` is a fatal `unbound variable`, not an empty path.
- **Failure:** The reader sets `DB=` in Section 3.1, logs out, logs back in the next day, submits
  `07a.host_index.sl`, and the task dies immediately with `DB: unbound variable` in
  `logs/`. Appendix B's triage table (line 779) attributes a Section 7 path failure to "Reference
  never downloaded (Section 3.3)", which sends the reader to re-download a 1 GB file that is
  already there. Two of eight scripts using a different path convention from the other six is
  also exactly the drift that makes a reader stop trusting the document.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED — lines 342, 453 and 510 spell the path out; lines 363 and 375 do not;
  the header at line 192 sets `set -u`.
- **Fix:** Replace the `scripts/07a.host_index.sl` body (lines 362–364) with:

  ```bash
  module purge; module load BBMap/39.01-GCC-11.3.0
  DB=/nesi/nobackup/<your_nesi_project_code>/db   # spelled out: sbatch cannot be relied on to
  cd "$DB/human"                                  # carry a $DB from a login session that ended
  bbmap.sh ref=chm13v2.0.fa.gz threads=${SLURM_CPUS_PER_TASK} -Xmx30g
  ```

  and the `scripts/07b.host_filter.sl` body (lines 370–377) with:

  ```bash
  module purge; module load BBMap/39.01-GCC-11.3.0
  DB=/nesi/nobackup/<your_nesi_project_code>/db
  bbmap.sh -Xmx26g threads=${SLURM_CPUS_PER_TASK} \
    minid=0.95 maxindel=3 bwr=0.16 bw=12 quickmatch fast minhits=2 \
    qtrim=rl trimq=10 untrim \
    in1="trim/${SAMPLE}_R1.fastq.gz" in2="trim/${SAMPLE}_R2.fastq.gz" \
    path="$DB/human" \
    outu1="clean/${SAMPLE}_R1.fastq.gz" outu2="clean/${SAMPLE}_R2.fastq.gz" \
    statsfile="logs/${SAMPLE}.hostmap.stats"
  ```

  Add to Section 4, after line 202:

  > **Every script defines its own absolute paths.** `$WORK`, `$DB` and `$ACCOUNT` live in your
  > login shell and disappear when the session does. Because the header sets `set -u`, a script
  > that relies on one of them dies with `unbound variable` rather than doing something
  > plausible — which is the good outcome, but only if you know to look for it.

### F-07 · S2 · Depth gates would exclude the controls Section 12 requires
- **Where:** SOP_READBASED_NeSI.md:437-439, § 8 The gates
- **Quote:**
  > | `clean_pairs` below ~5 million | Not enough for defensible taxonomy — flag it |
  > | `clean_pairs` below ~17 million | Not enough for pathway completeness — drop from functional analysis, or state the limitation |
  > | Controls with read counts comparable to real samples | Serious contamination — stop and investigate |
- **Defect:** Section 1 (line 56) requires controls to be "listed in `samples.txt` alongside the
  real samples", so they flow through Section 8 and are scored by these gates. A negative
  extraction blank is *supposed* to be nearly empty, and the gates as written mark every one of
  them as failing. Nothing in Section 8 exempts controls.
- **Failure:** The reader applies the gate table mechanically, excludes every blank for having
  fewer than 5 million clean pairs, builds the tables from real samples only, reaches Section 12
  — "Screen with `decontam` … use the **prevalence** method" — and has no negatives left to
  screen against. In low-biomass work (skin, nasal, BAL — the sample types Section 1 calls
  controls "mandatory" for) they then either skip screening or report a community that is partly
  reagent contamination.
- **Type:** GAP
- **Confidence:** CONFIRMED — line 56 puts controls in `samples.txt`; line 437 gates on
  `clean_pairs` with no exemption; line 624 requires the controls downstream.
- **Fix:** Insert immediately before the gate table (after line 430's heading):

  > **The `clean_pairs` gates apply to real samples only.** A negative blank with 20 000 clean
  > pairs has passed, not failed — that is what a clean blank looks like. Keep every control in
  > the cohort through to Section 12; if you drop them here, contamination screening becomes
  > impossible and you will not find out until the tables are already built. Mark them in your
  > metadata with a `sample_type` column (`sample`, `neg_extraction`, `neg_ntc`, `neg_sampling`,
  > `mock`) and filter on that, not on depth.

  and replace the last two rows of the table with:

  > | `clean_pairs` within an order of magnitude of the real samples, **in a negative control** | Serious contamination — stop and investigate before profiling anything |
  > | A negative control with very few reads | Expected. Keep it — Section 12 needs it |
  > | A mock community failing any gate | The pipeline, not the sample, is the problem — fix it before proceeding |

### F-08 · S2 · `$DB` inside a single-quoted `bash -c` expands to nothing
- **Where:** SOP_READBASED_NeSI.md:495-498, § 10 Install a current release
- **Quote:**
  > srun --account=$ACCOUNT --time=04:00:00 --mem=8G --cpus-per-task=4 bash -c '
  >   humann_databases --download chocophlan full         "$DB/humann" --update-config yes
  >   humann_databases --download uniref uniref90_diamond "$DB/humann" --update-config yes
  >   humann_databases --download utility_mapping full    "$DB/humann" --update-config yes'
- **Defect:** The `bash -c` argument is single-quoted, so `$DB` is expanded by the new shell, not
  the calling one. `DB` was set with a plain assignment at line 126 and never exported, so the
  new shell sees it as empty and every target path becomes `/humann`. There is also no
  `set -e` inside the subshell, so a failure in the first download does not stop the other two.
- **Failure:** The reader pastes the block and gets three permission-denied errors against
  `/humann` at the filesystem root, with no clue that the cause is a quoting rule three
  characters wide. If they work around it by dropping the quoting, `$ACCOUNT` on the same line is
  already unquoted and expands correctly, so nothing about the error points at `$DB`.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — `DB` is assigned without `export` at line 126; a single-quoted
  `bash -c` string is expanded by the child shell, which inherits only exported variables.
- **Fix:** Replace lines 494–498 with:

  ```bash
  # if they don't, install ~40 GB under srun. Re-assert both variables: a new login session has
  # neither, and they must be exported for the bash -c subshell to see them.
  ACCOUNT=<your_nesi_project_code>
  DB=/nesi/nobackup/$ACCOUNT/db
  export ACCOUNT DB
  srun --account="$ACCOUNT" --time=04:00:00 --mem=8G --cpus-per-task=4 bash -c '
    set -euo pipefail
    humann_databases --download chocophlan full         "$DB/humann" --update-config yes
    humann_databases --download uniref uniref90_diamond "$DB/humann" --update-config yes
    humann_databases --download utility_mapping full    "$DB/humann" --update-config yes'
  humann_config --print | grep -i "database folders" -A4   # confirm all three now resolve
  ```

### F-09 · S2 · "Verify ChocoPhlAn compatibility" with no procedure and no symptom
- **Where:** SOP_READBASED_NeSI.md:525, § 10 Running it
- **Quote:**
  > - **`--taxonomic-profile` reuses Section 9's profile**, which saves HUMAnN from running MetaPhlAn again. But first verify that your HUMAnN's ChocoPhlAn build is compatible with `$MPA_INDEX`. If it is not, drop the flag and let HUMAnN run its own MetaPhlAn — that is much better than feeding it a mismatched profile.
- **Defect:** The reader is told to verify something, given no way to verify it, and no
  description of what an incompatible pair looks like. The failure mode is silent: HUMAnN with a
  mismatched profile still completes and still writes gene family and pathway tables.
- **Failure:** The reader cannot execute the check, keeps the flag because it is in the code
  block, and HUMAnN selects zero or near-zero pangenomes from the prescreen. Nucleotide search
  contributes almost nothing, everything falls through to translated search, and the resulting
  gene-family tables are far shallower than they should be — with normal-looking values, no
  error, and no line in the log the reader has been told to read. At 24 h per sample that is
  discovered, if at all, after the whole cohort has run.
- **Type:** GAP
- **Confidence:** CONFIRMED — the instruction names no command, no file and no expected value;
  the check that would settle whether the specific grep string below matches your HUMAnN release
  is to run one sample and `ls`/`grep` its `*_humann_temp/*.log`.
- **Fix:** Replace the bullet at line 525 with:

  > - **`--taxonomic-profile` reuses Section 9's profile**, which saves HUMAnN from running
  >   MetaPhlAn again — but only if HUMAnN's ChocoPhlAn build was made for the same MetaPhlAn
  >   generation as `$MPA_INDEX`. Check that on one sample before launching the array:
  >
  >   ```bash
  >   conda activate humann
  >   humann_config --print | grep -i chocophlan          # note the version string
  >   humann --input "clean/<sample>_R1.fastq.gz" --output humann_test \
  >          --taxonomic-profile "metaphlan/<sample>.profile.tsv" --threads 8
  >   grep -i "species" humann_test/*_humann_temp/*.log | head
  >   ```
  >
  >   A compatible pair selects tens to low hundreds of species from the prescreen. **Zero, or a
  >   single-digit count for a sample whose profile listed eighty species, means the builds do not
  >   match.** This fails silently — HUMAnN finishes, writes tables, and the numbers look normal;
  >   they are simply built from translated search alone. If you see it, drop the flag and let
  >   HUMAnN run its own MetaPhlAn. That costs one extra alignment per sample and is far better
  >   than a mismatched profile.

### F-10 · S2 · Sample column names derived by three different rules, never reconciled
- **Where:** SOP_READBASED_NeSI.md:543, 571 and 588-590, § 11
- **Quote:**
  > merge_metaphlan_tables.py metaphlan/*.profile.tsv > tables/merged_taxonomy_allranks.tsv

  and

  >     frames[os.path.basename(f)[:-len(".readstats.tsv")]] = pd.Series(rows, dtype=float)

  and

  > humann_join_tables -i humann -o tables/genefamilies.tsv  --file_name genefamilies  -s
- **Defect:** Three merge routines name their sample columns three different ways —
  `merge_metaphlan_tables.py` from the profile filename, the Python block explicitly from the
  readstats basename, and `humann_join_tables` from HUMAnN's per-sample output names, which
  carry HUMAnN's own suffixes. Section 13 (line 636) requires "metadata keyed by sample ID" and
  the handoff table at lines 609–615 lists all of these files as inputs, but nothing states what
  the sample IDs will be or asks the reader to check that they agree.
- **Failure:** The reader builds `ps_relab` from `merged_species.tsv` and `ps_estcounts` from
  `merged_species_counts.tsv` against one metadata file. Where the keys differ completely,
  phyloseq or MaAsLin2 errors and the reader spends an afternoon on it; where they partly overlap
  — the common case once someone has hand-edited one header — MaAsLin2 subsets to the
  intersection with a warning that scrolls past, and the model is silently fitted on a subset of
  the cohort.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED — line 571 states its naming rule explicitly; lines 543 and 588–590
  delegate naming to two other tools; no line in Sections 11–13 reconciles them.
- **Fix:** Add at the end of § 11, immediately before "What Section 13 needs" (line 607):

  > ### **One sample-name convention across every table**
  >
  > The three merges above name their columns three different ways: from the `.profile.tsv`
  > filename, from the `.readstats.tsv` filename, and from HUMAnN's per-sample outputs, which
  > carry `_Abundance-RPKs`, `_Abundance` or `_Coverage`. Normalise them here, on the cluster,
  > where a mismatch is visible — not in R, where it shows up as missing samples rather than as
  > an error.
  >
  > ```bash
  > for f in tables/*.tsv; do
  >   sed -i '1s/\.profile//g; 1s/\.readstats//g; 1s/_Abundance-RPKs//g; 1s/_Abundance//g; 1s/_Coverage//g' "$f"
  > done
  >
  > # Every line below must list the same sample IDs, and they must be the IDs in samples.txt
  > # and in your metadata file.
  > for f in tables/merged_species.tsv tables/merged_species_counts.tsv \
  >          tables/genefamilies_cpm_unstratified.tsv tables/pathabundance_cpm_unstratified.tsv; do
  >   printf "%-45s %s\n" "$(basename "$f")" "$(head -1 "$f" | cut -f2- | tr '\t' ' ')"
  > done
  > cat samples.txt | tr '\n' ' '; echo
  > ```

### F-11 · S2 · `head -1` may take an index-tag comment as the species table's header
- **Where:** SOP_READBASED_NeSI.md:548, § 11 Taxonomy: relative abundance
- **Quote:**
  > head -1 tables/merged_taxonomy_allranks.tsv > tables/merged_species.tsv
- **Defect:** The header is taken by position, not by name. Depending on the MetaPhlAn release,
  the merged table's first line may be an index-tag comment (`#mpa_vJun23_…`) rather than the
  `clade_name<TAB>sample…` column header.
- **Failure:** `merged_species.tsv` is written with a one-field comment line where its header
  should be. Read into R with `header = TRUE` the sample names are gone and the first species row
  is promoted to the header; read with a comment-skipping reader the first species row becomes
  the header instead. Either way the reader has a table that parses without error and is wrong
  by one row and every column name. Section 11 offers no check on the file it just wrote.
- **Type:** CORRECTNESS
- **Confidence:** NEEDS-BENCH-CHECK — run `head -2 tables/merged_taxonomy_allranks.tsv` after
  `merge_metaphlan_tables.py` on your MetaPhlAn build and see whether line 1 is the column header
  or a `#mpa_…` comment. The fix below is correct either way.
- **Fix:** Replace lines 548–549 with:

  ```bash
  # Take the header by name, not by position: depending on the MetaPhlAn release, line 1 of the
  # merged table may be an index-tag comment rather than the column header.
  grep -m1 -E '^#?clade_name' tables/merged_taxonomy_allranks.tsv | sed 's/^#//' \
    > tables/merged_species.tsv
  grep -E "s__" tables/merged_taxonomy_allranks.tsv | grep -v "t__" >> tables/merged_species.tsv

  # Check it worked. The header must name every sample, and every column must sum to ~100.
  head -1 tables/merged_species.tsv
  awk -F'\t' 'NR>1{for(i=2;i<=NF;i++)s[i]+=$i}
              END{for(i=2;i<=NF;i++)printf "%.1f ",s[i]; print ""}' tables/merged_species.tsv
  ```

  A column summing to 800 means you captured the all-ranks table; a column summing to 0 means
  that sample's profile is empty and it is a failed sample, not a finding (Section 13, point 6).

### F-12 · S2 · `metaphlan/utils/` reads as the pipeline's own output directory
- **Where:** SOP_READBASED_NeSI.md:646, § 13 table
- **Quote:**
  > | **UniFrac** | **Available here, though Part 2 does not cover it.** MetaPhlAn 4 ships the SGB phylogeny with its database: `metaphlan/utils/calculate_diversity.R -d beta -m unweighted-unifrac -t <tree> -s t__`. The tree's tips are SGBs, so it needs the `t__` rows that Section 11 strips out — keep an SGB-level table as well if you want this. |
- **Defect:** `metaphlan/` is the name this SOP gives to its own MetaPhlAn *output* directory
  (created at line 128, written at lines 459 and 465). The path in this cell refers to the
  `utils/` folder inside the MetaPhlAn *installation*, which is somewhere else entirely. The
  command also has no input-table argument, `<tree>` is an unlocated placeholder, and "keep an
  SGB-level table as well" is an instruction with no command.
- **Failure:** The reader runs `ls metaphlan/utils/`, gets "No such file or directory", concludes
  the path is stale or that their MetaPhlAn install is broken, and abandons the only phylogenetic
  diversity the document offers. Even having found the script, they have no tree path, no input
  file, and no SGB table to feed it.
- **Type:** CLARITY
- **Confidence:** CONFIRMED — `metaphlan/` is created as an output directory at line 128 and used
  as one at lines 459, 462, 465, 519, 543, 560 and 767.
- **Fix:** Replace the row at line 646 with:

  > | **UniFrac** | **Available here, though Part 2 does not cover it.** MetaPhlAn 4 ships the SGB phylogeny alongside its database — find it with `ls "$DB"/metaphlan4/*.nwk`. The helper script lives inside the MetaPhlAn *installation*, not in this pipeline's `metaphlan/` output directory; locate it with `python -c "import metaphlan, os; print(os.path.join(os.path.dirname(metaphlan.__file__), 'utils'))"`, then run `calculate_diversity.R -f <sgb_table> -d beta -m unweighted-unifrac -t <tree.nwk> -s t__`. Its tips are SGBs, so it needs the `t__` rows Section 11 strips out. Build that table alongside the species one: `grep -m1 -E '^#?clade_name' tables/merged_taxonomy_allranks.tsv \| sed 's/^#//' > tables/merged_sgb.tsv; grep "t__" tables/merged_taxonomy_allranks.tsv >> tables/merged_sgb.tsv`. |

### F-13 · S2 · Provenance records only Option B's host reference, and its own check misses it
- **Where:** SOP_READBASED_NeSI.md:708-712 and 720, § 14 Provenance
- **Quote:**
  >   conda run -n humann humann_config --print; cat "$DB/human/chm13v2.0.fa.gz.md5"

  and

  > grep -i "command not found\|UNSET" versions.txt && \
  >   echo "WARNING: provenance incomplete - fix module loads and re-run" >&2

  and

  > - The host reference, and whether it was masked
- **Defect:** The only host reference the block records is `chm13v2.0.fa.gz`, which belongs to
  Option B. A reader on the **recommended** Option A path has no `chm13v2.0.fa.gz.md5`, and
  nothing records the Hostile version or the `human-t2t-hla-argos985` index. The completeness
  check greps for `command not found` and `UNSET`; a failed `cat` prints `No such file or
  directory`, so the check passes on the incomplete file. The block also writes `versions.txt`
  into the current directory, which is `$WORK` on `nobackup`.
- **Failure:** The reader follows Option A, runs Section 14, sees no warning, and files
  `versions.txt` as their methods record. It contains no host reference at all, while line 720
  and the README both list "the host reference, and whether it was masked" as required for the
  methods section. Six months later, at review, there is no record of which human index was used.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — Option A (lines 325–353) never creates `chm13v2.0.fa.gz.md5`;
  the grep pattern at line 711 does not match `No such file or directory`.
- **Fix:** Replace lines 707–712 with:

  ```bash
    echo; echo "## Databases"; echo "MetaPhlAn index: ${MPA_INDEX:-UNSET}"
    conda run -n humann humann_config --print
    echo; echo "## Host depletion"
    if conda env list | grep -qE '^hostile[[:space:]]'; then
      conda run -n hostile hostile --version
      echo "index: human-t2t-hla-argos985 (masked)"
    elif [[ -s "${DB:-/nonexistent}/human/chm13v2.0.fa.gz.md5" ]]; then
      echo "BBMap against chm13v2.0 (UNMASKED - state this in your methods)"
      cat "$DB/human/chm13v2.0.fa.gz.md5"
    else
      echo "host reference: UNSET"
    fi
    echo; echo "## Samples"; wc -l < samples.txt
  } > versions.txt
  # Written to $WORK, which is nobackup. Copy it to project, which is backed up (Section 2).
  cp versions.txt /nesi/project/<your_nesi_project_code>/readbased_versions_$(date +%F).txt
  if grep -Eqi "command not found|UNSET|No such file" versions.txt; then
    echo "WARNING: provenance incomplete - fix the module loads and re-run" >&2
  fi
  ```

  (The `if` form also stops the check aborting the block under `set -e`, which the bare
  `grep && echo` would do whenever provenance is complete.)

### F-14 · S2 · Completeness check passes on a failed MetaPhlAn profile
- **Where:** SOP_READBASED_NeSI.md:767-768, § Appendix B
- **Quote:**
  >   [[ -s "metaphlan/${S}.profile.tsv" ]] || echo "MISSING metaphlan: $S"
  >   [[ -s "humann/${S}/${S}_genefamilies.tsv" ]] || echo "MISSING humann: $S"
- **Defect:** `-s` tests only that the file is non-empty. A MetaPhlAn profile for a sample that
  classified nothing still contains its comment header, so it passes. The document knows this
  failure mode — line 680 defines it — but only says so in Section 13, after the tables are
  built, the contamination screen is done and the reader is already in R.
- **Failure:** One array task ran on a truncated or near-empty `clean/` file and produced a
  profile with no species rows. Appendix B reports nothing wrong. `merge_metaphlan_tables.py`
  merges it as a column of zeros, and it carries through Section 12 and into the phyloseq object
  as a genuine sample with zero diversity, dragging every group mean it belongs to.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — line 680 states that an empty profile is a failed sample; the check
  at line 767 cannot detect one.
- **Fix:** Replace lines 766–769 with:

  ```bash
  # -s only proves the file exists. A profile can be non-empty and still be a failed sample:
  # zero species, or one taxon above 99%. Section 13 point 6 is the rule; this is the check.
  while read -r S; do
    P="metaphlan/${S}.profile.tsv"
    [[ -s "$P" ]] || { echo "MISSING metaphlan: $S"; continue; }
    n=$(grep -c "s__" "$P" || true)
    (( n > 0 )) || { echo "FAILED metaphlan (no species): $S"; continue; }
    awk -F'\t' -v s="$S" '/s__/ && !/t__/ {if ($3+0 > m) m=$3+0}
                          END {if (m > 99) printf "FAILED metaphlan (top taxon %.1f%%): %s\n", m, s}' "$P"
    [[ -s "humann/${S}/${S}_genefamilies.tsv" ]] || echo "MISSING humann: $S"
  done < samples.txt
  ```

  Add one line to § 9, after line 466: "Run the profile check in Appendix B as soon as the array
  finishes, not after Section 11 — an empty profile merges into a column of zeros and looks like
  a real sample from then on. Negative controls are the exception: an empty profile there is the
  expected result."

### F-15 · S3 · One control per four samples given as a number with no reasoning
- **Where:** SOP_READBASED_NeSI.md:56, § 1 Controls
- **Quote:**
  > Controls are collected at the bench and cannot be added later. Aim for at least one control per four samples, sequenced in the same run and listed in `samples.txt` alongside the real samples.
- **Defect:** A 1:4 ratio is a demanding and consequential budget line, and it is the one
  threshold in the document with no justification — against the README's own rule that a
  documented threshold carries its reasoning. It is also ambiguous whether "one control" means
  one of each of the four types in the table below it, or one of any type.
- **Failure:** The reader budgets 20% of a sequencing run to controls, is asked by a supervisor
  or a grant reviewer why, and has nothing to point at. Or reads it as one blank per four samples
  and omits the mock, which Section 7 needs.
- **Type:** GAP
- **Confidence:** CONFIRMED — no reasoning or citation appears anywhere in § 1.
- **Fix:** Add after the control table: "The ratio scales with biomass, not with cohort size:
  one negative blank per extraction batch is the floor for stool, while low-biomass work
  (skin, nasal, BAL) needs enough blanks to estimate a contaminant's prevalence, which is what
  `decontam`'s prevalence method tests — roughly one per four samples. One mock community per
  sequencing run is enough regardless of biomass."

### F-16 · S3 · Manifest built with no cross-check against the file count
- **Where:** SOP_READBASED_NeSI.md:132-137, § 3.1
- **Quote:**
  > ls raw/*_R1.fastq.gz | xargs -n1 basename | sed 's/_R1\.fastq\.gz$//' > samples.txt
- **Defect:** If the naming pattern matches only some files (the case line 142 warns about), the
  manifest is silently partial. `NSAMP` is echoed but never compared to anything.
- **Failure:** Eight of twelve samples use `_R1.fastq.gz` and four use `_R1_001.fastq.gz`. The
  manifest has eight entries, the array runs eight tasks, everything succeeds, and four samples
  are absent from the final tables with no error anywhere.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — no comparison between `wc -l < samples.txt` and the number of files
  in `raw/` appears in the block.
- **Fix:** Add after line 137: `NFILE=$(ls raw/*_R1* 2>/dev/null | wc -l); [[ "$NSAMP" -eq "$NFILE" ]] || echo "MISMATCH: $NSAMP in samples.txt but $NFILE R1 files in raw/ - fix the pattern"`

### F-17 · S3 · T2T reference downloaded on the path that never uses it
- **Where:** SOP_READBASED_NeSI.md:161-166, § 3.3
- **Quote:**
  > cd "$DB/human"
  > wget https://s3-us-west-2.amazonaws.com/human-pangenomics/T2T/CHM13/assemblies/analysis_set/chm13v2.0.fa.gz
- **Defect:** `chm13v2.0.fa.gz` is used only by Option B (lines 355–386). Section 7 recommends
  Option A, which fetches its own masked index. Section 3.3 downloads it unconditionally and
  makes no mention of the Hostile fetch, so the section titled "References and databases"
  installs one database the recommended path does not need and omits the one it does.
- **Failure:** Every reader downloads a multi-gigabyte reference and later builds a 20–25 GB
  BBMap index of it that Option A never touches, on a filesystem the document says is tight.
- **Type:** STRUCTURE
- **Confidence:** CONFIRMED — `chm13v2.0.fa.gz` appears only at lines 163, 164, 364 (Option B) and
  708.
- **Fix:** Retitle the wget block "**Option B only** — the human reference for BBMap. Skip this
  if you are using Hostile (Section 7, Option A), which fetches its own masked index; come back
  here if you fall through to Option B." Add a line under the MetaPhlAn install: "Hostile's index
  is fetched in Section 7 rather than here, because it is specific to that option."

### F-18 · S3 · Section 5's scripts break the numbering convention every other script follows
- **Where:** SOP_READBASED_NeSI.md:210 and 218, § 5
- **Quote:**
  > `scripts/qc_fastqc.sl` (array job):

  and

  > `scripts/qc_multiqc.sl`:
- **Defect:** Every other script in the document is numbered to its section — `06.trim.sl`,
  `07.host_hostile.sl`, `07a`/`07b`, `08.read_counts.sl`, `09.metaphlan.sl`, `10.humann.sl`.
  These two are not, and the README states as a repository convention that "the numbered
  sections, the script filenames and the roadmap stages are deliberately aligned".
- **Failure:** The reader lists `scripts/` expecting to read the pipeline in order and finds two
  files that sort to the end and belong at the start; the alignment the README promises does not
  hold.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED — the other eight script names all carry their section number.
- **Fix:** Rename to `scripts/05.qc_fastqc.sl` and `scripts/05b.qc_multiqc.sl` at lines 210, 218
  and in Appendix A (lines 735, 736, 741, 742, 743) and Appendix C (lines 791, 792).

### F-19 · S3 · `ftm=5`, `tbo` and `tpe` given with no explanation
- **Where:** SOP_READBASED_NeSI.md:261, § 6
- **Quote:**
  >   ref=adapters ktrim=r k=23 mink=11 hdist=1 tbo tpe ftm=5 \
- **Defect:** `ftm=5` changes every read's length and `tbo`/`tpe` change which reads survive as
  pairs, yet the notes below explain only `trimq=10`, `stats=` and deduplication. The
  surrounding density of "why this number" makes their absence read as an omission rather than a
  choice.
- **Failure:** The reader sees post-trim read lengths of 150 where the run was 2×151, cannot find
  an explanation, and either assumes something went wrong or removes `ftm=5` to "fix" it.
- **Type:** GAP
- **Confidence:** CONFIRMED — no explanation of these three flags appears in § 6.
- **Fix:** Add a bullet after line 273: "**`ftm=5`, `tbo`, `tpe`.** `ftm=5` force-trims each read
  to a multiple of 5, which removes the extra low-quality base Illumina adds on a 2×151 run.
  `tbo` trims adapter by overlap detection and `tpe` trims both mates to the same length, so
  that a pair is never left with one mate carrying adapter the other had removed."

### F-20 · S3 · fastp variant leaks temp files on failure, contrary to Section 10's own reasoning
- **Where:** SOP_READBASED_NeSI.md:300-304, § 6 Alternative: fastp for pass one
- **Quote:**
  > rm -f "trim/${SAMPLE}_R1.tmp.fastq.gz" "trim/${SAMPLE}_R2.tmp.fastq.gz"
- **Defect:** Under `set -e` from the standard header, a `bbduk.sh` failure aborts before this
  line — the exact mechanism Section 10 explains at line 527 and solves with a `trap`. The
  fastp variant does not use one.
- **Failure:** A dozen array tasks fail on memory, and a full uncompressed-equivalent copy of the
  trimmed reads is left behind in `trim/` for each of them, on a filesystem the document has
  already warned is finite.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED — line 527 states the mechanism; line 304 is placed after the command
  that can trigger it.
- **Fix:** Move cleanup to a trap: insert `trap 'rm -f "trim/${SAMPLE}_R1.tmp.fastq.gz" "trim/${SAMPLE}_R2.tmp.fastq.gz"' EXIT` immediately after the `module load fastp` line, and delete line 304.

### F-21 · S3 · The 17-million gate contradicts Section 1's pathway-profiling threshold
- **Where:** SOP_READBASED_NeSI.md:438, § 8 The gates
- **Quote:**
  > | `clean_pairs` below ~17 million | Not enough for pathway completeness — drop from functional analysis, or state the limitation |
- **Defect:** Section 1 gives two separate functional thresholds: pathway profiling at ≥2 Gb
  (~7 million pairs) and pathway *completeness above 80%* at ≥5 Gb (~17 million). The gate
  collapses them and attaches "drop from functional analysis" to the higher one.
- **Failure:** A reader with 10 million clean pairs — comfortably above Section 1's pathway
  profiling floor — drops the sample from the functional analysis, losing power for no reason,
  and never sees that Section 1 said 7 million was enough.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED — lines 74 and 75 give two distinct thresholds that line 438 merges.
- **Fix:** Replace the row with two: "| `clean_pairs` below ~7 million | Below Section 1's
  pathway-profiling floor — exclude from functional analysis |" and "| `clean_pairs` between ~7
  and ~17 million | Fine for pathway profiling, but completeness will be under 80% — keep it and
  state the limitation |".

### F-22 · S3 · Python merge block silently depends on the previous block's module state
- **Where:** SOP_READBASED_NeSI.md:557, § 11 Taxonomy: estimated counts
- **Quote:**
  > python3 - <<'PY'
- **Defect:** Every other block in Section 11 opens with `module purge; module load …`; this one
  does not, and depends on the MetaPhlAn module loaded at line 542 for both `python3` and
  `pandas`. Nothing says so, and nothing states that `pandas` is required.
- **Failure:** The reader runs the three Section 11 blocks in a different order, or in a fresh
  `srun` shell, and gets `ModuleNotFoundError: No module named 'pandas'` from a block that
  carries no module line to fix.
- **Type:** CLARITY
- **Confidence:** NEEDS-BENCH-CHECK — run `module purge; module load MetaPhlAn/4.1.0-gimkl-2022a-Python-3.10.5; python3 -c "import pandas; print(pandas.__version__)"` to confirm the module supplies pandas.
- **Fix:** Prepend `module purge; module load MetaPhlAn/4.1.0-gimkl-2022a-Python-3.10.5` and a
  comment: `# this block needs python3 with pandas; the MetaPhlAn module supplies both`.

### F-23 · S3 · `versions.txt` written to nobackup, which the storage table says is wrong
- **Where:** SOP_READBASED_NeSI.md:710, § 14
- **Quote:**
  > } > versions.txt
- **Defect:** The block runs from `$WORK` on `nobackup`; the storage table at line 110 assigns
  `versions.txt` to `project`, and line 113 warns that `nobackup` deletes untouched files after
  90 days.
- **Failure:** The provenance record — the one artefact the reader most needs long after the
  analysis ends — is written to the filesystem with no backup and a 90-day timer, and is gone by
  the time a reviewer asks for it.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED — line 110 lists `versions.txt` under `project`; the block writes to
  the current directory, which Section 3.1 sets to `$WORK` on `nobackup`.
- **Fix:** Add after line 710: `cp versions.txt /nesi/project/<your_nesi_project_code>/readbased_versions_$(date +%F).txt   # project is backed up; nobackup is not (Section 2)`

### F-24 · S3 · Re-running a failed MetaPhlAn task hits its own leftover alignment file
- **Where:** SOP_READBASED_NeSI.md:765, § Appendix B
- **Quote:**
  > sbatch --array=3,17,42 scripts/09.metaphlan.sl        # re-run only failed tasks
- **Defect:** `scripts/09.metaphlan.sl` writes `--bowtie2out metaphlan/${SAMPLE}.bt2.bz2`. A task
  that failed after starting the alignment leaves that file behind, and MetaPhlAn refuses to
  overwrite an existing bowtie2out.
- **Failure:** The reader follows the triage advice, the three re-run tasks fail again for a new
  reason, and the triage section that was supposed to unblock them has added a step.
- **Type:** CORRECTNESS
- **Confidence:** NEEDS-BENCH-CHECK — run `scripts/09.metaphlan.sl` twice on one sample and see
  whether the second run refuses on the existing `.bt2.bz2`. The fix is harmless either way.
- **Fix:** Add `rm -f "metaphlan/${SAMPLE}.bt2.bz2"` immediately before the pass-1 `metaphlan`
  call at line 456, with the comment `# MetaPhlAn will not overwrite an existing bowtie2out, so a re-run of a failed task stalls without this`.

### F-25 · S3 · Triage table misdiagnoses the Section 7 path failure
- **Where:** SOP_READBASED_NeSI.md:779, § Appendix B
- **Quote:**
  > | `cd: no such file or directory` in Section 7 | Reference never downloaded (Section 3.3) |
- **Defect:** With `set -u` in the standard header, the far more likely cause of a Section 7 path
  failure is `DB: unbound variable` — `$DB` is set in a login session at line 126 and referenced
  inside the script at line 363. The table names only the other cause and does not name the
  error the reader will actually see.
- **Failure:** The reader re-downloads a reference that is already present, twice, before
  realising the variable was the problem.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED — the header sets `set -u` at line 192 and `07a.host_index.sl` uses
  `$DB` at line 363.
- **Fix:** Replace the row with two: "| `DB: unbound variable` in Section 7 | `$DB` was set in a
  login session that has ended — spell the path out in the script |" and "| `cd: no such file or
  directory` in Section 7 | Reference never downloaded (Section 3.3) |".

### F-26 · S4 · Omnibus polish
- **Where:** SOP_READBASED_NeSI.md, twelve locations listed below
- **Quote:**
  > | `ec_cpm.tsv`, `ko_cpm.tsv` | Function regrouped to enzyme commission numbers and KEGG orthologues |
- **Defect:** Twelve small inconsistencies, none individually blocking.
- **Failure:** Each costs a reader a few seconds of doubt about whether two names mean the same
  thing; collectively they erode the trust the rest of the document earns.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED — each is checkable at the line given.
- **Fix:** Apply in place:
  1. **L590** — `tables/pathcoverage.tsv` is joined and then never normalised, split, mentioned in
     the § 11 handoff table, or used in § 13. Add one clause: "`pathcoverage` is already a 0–1
     proportion, so it is not renormalised; keep it for reporting how well each pathway was
     covered, not for testing."
  2. **L613-614** — the handoff table calls one glob `*_cpm_unstratified.tsv` and its pair
     `*_stratified.tsv`. Make both `*_cpm_unstratified.tsv` / `*_cpm_stratified.tsv`.
  3. **L666 vs L669** — the code comment says `betadisper` is "REQUIRED whenever PERMANOVA is
     significant"; the prose two lines later says "Always run `betadisper`." Make the comment
     `# always run this, not only when PERMANOVA is significant`.
  4. **L664-666** — the distance object is called `dist`, which shadows `stats::dist`. Rename to
     `d_bray` throughout the three calls.
  5. **L159 vs L170** — "One-time setup, on the login node" is immediately followed by an `srun`.
     Change to "One-time setup. Run the download on the login node; the MetaPhlAn install goes
     through `srun` because it is long enough to be killed on a login node."
  6. **L794-796** — Appendix C lists `07a.host_index` and `07b.host_filter` above
     `07.host_hostile`. Put the recommended Option A row first.
  7. **L793** — Appendix C has no row for the fastp variant of § 6, which uses `-Xmx12g` and full
     threads rather than `-Xmx6g` ×2. Add `| 06.trim (fastp variant) | 16 GB | 12 | 2 h | one JVM: -Xmx12g, full threads |`.
  8. **L98** — `ls -d /opt/nesi/db || echo "no shared DB tree - install your own"` gives no
     guidance for the case where it *does* exist. Add: "If it does exist, check whether it holds a
     MetaPhlAn index; using a shared one saves 25–30 GB, but you must still pin its tag."
  9. **L276** — "`outs=` retains singletons" is offered with no reason and no downstream handling;
     Sections 9 and 10 both read paired files only. Either drop it or add "…which nothing
     downstream in this SOP uses; take it only if you plan to profile singletons separately."
  10. **L282** — "prefer a newer BBMap if `module spider BBMap` offers one" with no note that the
      module string is pinned in four scripts. Add "…and update the string in `06.trim.sl`,
      `07a.host_index.sl`, `07b.host_filter.sl` and § 14."
  11. **L634** — "because Emu output carries no tree and MetaPhlAn's does" is elliptical (it is
      MetaPhlAn's *database*, not its output). Change to "…because Emu produces no phylogeny,
      whereas MetaPhlAn's database ships one."
  12. **L804** — the closing paragraph restates § 2's preflight in full. Cut to one sentence:
      "Run § 2 before anything else, not after a failed array — every module string and database
      path in this document will drift."

## Keep list

1. **L200** — "forget it and the job runs successfully on sample 1 only, with no error to alert
   you." The single most valuable sentence in the document. A rewrite that tightens the Section 4
   prose will be tempted to compress it into "remember to set the array size"; that loses the
   whole point, which is that the failure is silent.
2. **L229** — "it runs immediately, reports on however few samples happen to have finished, and
   exits 0 — leaving you a report that looks fine and is silently incomplete." Same category. The
   `--dependency` instruction alone does not convey why it matters.
3. **L251** — the two-pass explanation ("`ktrim=r` applies to every sequence in `ref=`"). Looks
   like a candidate for merging into one bbduk call by anyone who has not read it carefully. It is
   the reason the section is shaped as it is.
4. **L273** — "`trimq=10`, not 20. Double-ended quality trimming at Q20 with `minlen=50` biases
   against GC-extreme and low-coverage genomes." A why-this-number paragraph that survives no
   compression; the value without the reason is worthless.
5. **L317** — the T2T rationale ("Human reads from those regions have nowhere to map in hg38, so
   they misalign to microbial references and appear as species that were never in your sample").
   This is the argument for the whole section, not a preamble to it.
6. **L411-412** and **L512-513** and **L140** — the three comments explaining why a defensive line
   exists (zcat under pipefail, the `trap` under `set -e`, CRLF in the manifest). Each sits above a
   line that looks redundant without it. Deleting the comment invites deleting the line.
7. **L545-547** — "a column sums to roughly 8x the classified fraction - not 100%. Never hand the
   all-ranks table to anything that expects a species table." The clearest silent-failure warning
   in Section 11.
8. **L476** — "they are **model-estimated** reads, not sequencer counts … do not use them for
   alpha diversity." Load-bearing for F-03; must survive and must be echoed in the § 13 table.
9. **L50-52** — the governance paragraph, with the Tomofuji 93.3% re-identification figure. Not
   negotiable, and the specific number is what makes it land.
10. **L680** — "An empty profile, or one where a single taxon sits above 99%, is a failed sample
    rather than a finding." Correct and important; it is in the wrong place (see F-14), not
    wrong.

## Gaps

- **SHOULD-ADD — What a good MetaPhlAn profile looks like.** § 9 gives no expected output at all.
  The reader has no way to distinguish a healthy stool profile from a failed one until § 13's
  point 6. Two sentences plus one command: typical species count by body site, typical
  `UNCLASSIFIED` fraction, and `head -20 metaphlan/<sample>.profile.tsv`. ~6 lines.
- **SHOULD-ADD — What a good HUMAnN run looks like.** § 10 likewise. HUMAnN prints an unmapped-
  reads percentage; a stool sample typically maps 50–80% at the nucleotide stage, and single-digit
  values mean the ChocoPhlAn/profile mismatch of F-09. One paragraph plus the grep. ~6 lines.
- **SHOULD-ADD — How the reader marks which samples are controls.** Controls are put in
  `samples.txt` (L56), are exempt from the depth gates (F-07), and drive § 12, but no `sample_type`
  convention is ever defined. One sentence in § 1 plus one column in the § 13 metadata paragraph.
  ~3 lines.
- **SHOULD-ADD — Runtime expectations, not just walltime requests.** Appendix C gives what to
  *request*; nothing says what to *expect*. A reader cannot tell whether a HUMAnN task at hour six
  is normal or hung. One extra column ("typical per sample at 2×150, 10 M pairs") on the Appendix C
  table. ~1 column.
- **CONSIDER — Where the raw reads come from.** § 3.1 runs `ls raw/*_R1.fastq.gz` on a directory
  created two lines earlier, with nothing on transferring data onto NeSI or concatenating lanes
  beyond "concatenate lanes first" (L142). The document assumes one prior pipeline, so this may be
  deliberate — but a one-line pointer would cost nothing. ~2 lines.
- **CONSIDER — What to do when a sample fails a gate but cannot be re-sequenced.** § 8's gates say
  "exclude or re-sequence"; in practice neither is available and the reader needs to know how to
  report a retained borderline sample. ~3 lines.
- **CONSIDER — Disk headroom check before § 10.** The document states 100–170 GB temp per sample
  and 1–1.7 TB at `%10` throttling, but never has the reader check available space before
  launching. One `nn_check_quota` line in Appendix A. ~2 lines.

## Cross-document flags

Every claim this document makes about another file, for the between-documents agent. Not resolved
here — I read only this file and the README.

| Line | Claim | To check |
|---|---|---|
| 7 | "The statistics then run on `SOP_R_Analysis.md`, with Section 13 below listing what changes" | That `SOP_R_Analysis.md` opens on inputs this SOP actually produces |
| 11 | "work through `SOP_EMU_NeSI.md` Section 1 first" — bash, modules, `sbatch` and array jobs "taken as familiar" | That EMU § 1 teaches all four, array jobs included |
| 210, 218 | `scripts/qc_fastqc.sl`, `scripts/qc_multiqc.sl` unnumbered | Against README:53, which states section/script/roadmap numbering is "deliberately aligned" in this SOP — see F-18 |
| 624 | "Screen with `decontam`, which `SOP_R_Analysis.md` already covers" | That Part 2's decontam section covers the prevalence method, and works from a relative-abundance table |
| 632 | "Follow `SOP_R_Analysis.md` for the mechanics" | That Part 2's mechanics are separable from its Emu-specific inputs |
| 634 | "Part 2 covers no phylogenetic diversity at all, because Emu output carries no tree" | Whether Part 2 is genuinely tree-free, and whether the claim holds given `SOP_CONCOMPRA_NeSI.md` builds a FastTree phylogeny |
| 640 | "SRS normalisation … Does not apply" | Part 2's SRS section, and whether Part 2 uses SRS for alpha diversity only or for beta as well |
| 644 | "Part 2 does the same to Emu's EM estimates" (rounding before ANCOM-BC2/ALDEx2) | That Part 2 actually rounds |
| 645 | "`ps_relab` and `ps_estcounts`" | Against README:52 (which lists both) and Part 2's "Key objects you'll work with" table |
| 646 | "Available here, though Part 2 does not cover it" (UniFrac) | Part 2's beta-diversity section |
| 673 | "MaAsLin 3 and MaAsLin 2 accept counts or relative abundance" | README:14 says Part 2 covers MaAsLin2; whether MaAsLin 3 appears anywhere else in the repo |
| 688 | "`SOP_R_Analysis.md` does not cover these, so this SOP owns them" (functional tables) | Against README:28, which makes the same claim |
| 716-724 | The methods checklist | Against README:102, which lists a subset; this document adds trimming parameters and the contamination threshold |
| 151-153 | "Three were confirmed present … Verify these with `module spider`" | Against README:83, which makes the same claim with the same three modules |
| 115 | "85–95 GB" of databases | Against README:42, same figure |
| 9 | "does not transfer to animal or environmental samples" | Against README:29, same scope limit |

## Rewrite plan

Ordered by dependency. Every item can proceed without touching another SOP; items 1, 3 and 7
should be done before anyone regenerates results from this document.

1. **Fix the § 1 depth arithmetic** (F-01). Replace one paragraph with the divide-by-(1−host)
   formula and the three-row worked table. ~15 lines. Independent, and the highest-priority change
   in the repository — it is the only defect here that cannot be recovered from after the fact.
2. **Give § 1 its subsampling mechanics** (F-04) and its control-ratio reasoning (F-15). ~25 lines
   added to § 1. Independent.
3. **Rebuild the end of § 11** (F-02, F-10, F-11). Split the regrouped tables, take the species
   header by name, add the sample-name normalisation and the column-sum check, and add a new
   "One sample-name convention" subsection. Then update the § 11 handoff table and § 13's
   Functional tables paragraph to name the split files. ~45 lines changed or added across
   L539–617 and L688. Independent of the other SOPs, but must land before item 4.
4. **Fix the § 13 table rows** (F-03, F-12). Rewrite the SRS row so it stops routing estimated
   counts into alpha diversity, and rewrite the UniFrac row with a real script path, a real tree
   path and the SGB-table command. ~15 lines. Depends on item 3 for the table names it references.
5. **Rewrite Option B** (F-05) and make `07a`/`07b` self-contained (F-06). Replace the Option B
   preamble with the mock-community quantification procedure, spell the `$DB` paths out in both
   scripts, and add the "every script defines its own absolute paths" note to § 4. ~35 lines
   across L355–386 and L204. Independent.
6. **Add the control exemption and split the functional gate in § 8** (F-07, F-21). One paragraph
   plus three table rows. ~12 lines. Independent.
7. **Fix § 10's two blockers** (F-08, F-09). Correct the `bash -c` quoting and export, and replace
   the compatibility bullet with the executable check and its symptom. ~25 lines. Independent.
8. **Strengthen the checks** (F-14, F-13, F-24, F-16, F-25, F-23). Appendix B's profile check, the
   § 14 host-reference branch and backup copy, the `.bt2.bz2` removal, the manifest cross-check and
   the triage table row. ~40 lines across Appendix B, § 14, § 9 and § 3.1. Independent, and worth
   doing as one pass because they are all "add the check that proves the step worked".
9. **The § 3.3 / § 5 / § 6 tidy-up** (F-17, F-18, F-19, F-20, F-22). Retitle the T2T download as
   Option B only, renumber the two QC scripts everywhere they appear, explain `ftm=5`/`tbo`/`tpe`,
   move the fastp cleanup into a trap, and give the Python block its own module load. ~30 lines,
   plus five find-and-replace edits for the script renaming. Independent.
10. **The omnibus** (F-26). Twelve one-line edits. ~15 lines. Last, because several of them touch
    tables that items 3 and 5 rewrite.

---

**Self-check**

- [x] Ledger accounts for every heading in the file — 52 rows, verified against a `^#{1,4} ` scan
- [x] Every finding has a line-anchored verbatim quote
- [x] Every finding has a concrete Failure line
- [x] Every S1 and S2 has paste-ready replacement text
- [x] Every `NEEDS-BENCH-CHECK` names the one check that settles it (F-11, F-22, F-24; F-09's
      finding is CONFIRMED, with the log-string in its fix flagged for checking)
- [x] No proposed cut touches load-bearing content — the only cut proposed is the closing
      paragraph at L804, which restates § 2 verbatim and is replaced by a pointer to it
- [x] S4 count ≤ 15 — one omnibus entry (F-26) covering twelve items
- [x] Sections match the required skeleton exactly, in order

CONTRACT: PASS
