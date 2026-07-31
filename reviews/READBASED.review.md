## Document: SOP_READBASED_NeSI.md

A read-based Illumina shotgun pipeline (MetaPhlAn 4 + HUMAnN) for human-associated
samples on NeSI, aimed at a reader who has finished one cluster pipeline. It is
strong on the load-bearing "why" content — governance/re-identification, the
depth-budget arithmetic, the two-pass BBDuk rationale, the masked-reference and
`--index/--offline` reproducibility arguments are all present and correct, and the
depth-budget inversion flagged in the previous round is now fixed and arithmetically
right. It is 858 lines. The single most valuable change is fixing the Section 11
relative-abundance merge (F-01): the `head -1` header grab and the `.profile`
sample-ID suffix together corrupt `merged_species.tsv`, which is the compositional
table that feeds beta diversity, decontam and the reshape — the one artefact in the
document whose corruption is both provable and silent downstream.

## Section ledger

| § | Heading | Lines | Verdict | Findings |
|---|---|---|---|---|
| — | Title + scope/prereq preamble | 1-13 | CLEAN | — |
| — | Quick Roadmap | 15-41 | CLEAN | — |
| 1 | Before You Generate Data | 44-98 | CLEAN | — |
| 1· | Governance | 48-52 | CLEAN | — (keep) |
| 1· | Controls | 54-65 | CLEAN | — |
| 1· | Depth | 67-97 | CLEAN | — (calibration S1 fix verified correct) |
| 2 | Preflight and Storage | 100-135 | CLEAN | — |
| 3 | Setup | 137-193 | TIGHTEN | F-04 |
| 3.1 | Directories and manifest | 139-166 | CLEAN | — |
| 3.2 | Modules | 167-174 | CLEAN | — |
| 3.3 | References and databases | 175-193 | RESTRUCTURE | F-04 |
| 4 | The Standard Job Header | 196-221 | CLEAN | — (cross-doc: header mechanism) |
| 5 | Quality Control | 224-264 | CLEAN | — |
| 6 | Trimming and PhiX Removal | 267-326 | CLEAN | — (poly-G flag verified) |
| 7 | Host Depletion | 329-416 | REWRITE | F-02 |
| 7·A | Option A — Hostile | 343-371 | CLEAN | — |
| 7·B | Option B — BBMap unmasked T2T | 373-405 | REWRITE | F-02 |
| 8 | Read Accounting and Depth Gates | 419-460 | CLEAN | — |
| 9 | Taxonomy with MetaPhlAn 4 | 463-499 | TIGHTEN | (F-03 via App. B) |
| 10 | Function with HUMAnN | 502-553 | CLEAN | — |
| 11 | Merging, Normalising, Splitting | 556-647 | REWRITE | F-01 |
| 11· | Taxonomy: relative abundance | 564-575 | REWRITE | F-01 |
| 11· | Taxonomy: estimated counts | 577-603 | CLEAN | — |
| 11· | Function | 605-635 | CLEAN | — |
| 11· | What Section 13 needs | 637-647 | CLEAN | — |
| 12 | Contamination Screening | 650-658 | TIGHTEN | F-06 |
| 13 | Statistics: What Changes | 661-745 | CLEAN | — |
| 14 | Provenance | 748-779 | TIGHTEN | F-05 |
| A | Appendix A: Submission Chain | 782-811 | TIGHTEN | F-03 |
| B | Appendix B: Triage | 813-834 | TIGHTEN | F-03 |
| C | Appendix C: Resources | 836-854 | CLEAN | — |
| — | Closing "verify the environment" note | 856-859 | CLEAN | — |

## Findings

### F-01 · S1 · Species-table merge grabs `#mpa_` comment as header and keeps `.profile` in sample IDs
- **Where:** SOP_READBASED_NeSI.md:573-574, § 11 Taxonomy: relative abundance
- **Anchor:** `head -1 tables/merged_taxonomy_allranks.tsv > tables/merged_species.tsv`
- **Quote:**
  > head -1 tables/merged_taxonomy_allranks.tsv > tables/merged_species.tsv
  > grep -E "s__" tables/merged_taxonomy_allranks.tsv | grep -v "t__" >> tables/merged_species.tsv
- **Defect:** `merge_metaphlan_tables.py` writes the `#mpa_vJun23_CHOCOPhlAnSGB_202403`
  version line as line 1 and the real `clade_name<TAB>sample…` header as line 2, and
  it tags every sample column with a `.profile` suffix taken from the input filename
  (`metaphlan/<sample>.profile.tsv`). `head -1` therefore captures the comment, not
  the header: `merged_species.tsv` ends up with the `#mpa_` string as its first line,
  no `clade_name`/sample-name header at all, and — had the header survived — sample
  IDs of the form `<sample>.profile`. The estimated-counts merge below it (§11) does
  this correctly (it strips to `<sample>` and writes a real header), so the two
  tables that are supposed to describe the same samples disagree on both header shape
  and sample IDs.
- **Failure:** Reader runs §13's reshape on `merged_species.tsv` → `pd.read_csv(...,
  index_col=0)` raises `IndexError: list index out of range` (1-field header line,
  3-field data rows), so `part2_relab.tsv` and `part2_counts.tsv` are never written
  and the reader is stuck with a cryptic error pointing nowhere near the cause. A
  reader who "fixes" the crash the obvious way (take line 2, `sed -n 2p`) then inherits
  `.profile`-suffixed IDs on the relative-abundance table while the counts table and
  metadata use the bare `<sample>` ID; the Part 2 join silently drops every sample or
  mis-aligns them, and the compositional analyses (beta diversity, decontam) run on
  wrong-but-plausible data with no error. Loading the raw file into R is worse:
  `read.table`/`read.csv` treat `#mpa_` as a comment, skip it, and promote the first
  species row to the header — silently.
- **Type:** CORRECTNESS
- **Confidence:** VERIFIED
- **Evidence:** Ran the SOP's own commands on merge output built with the pinned
  module:
  ```
  $ merge_metaphlan_tables.py metaphlan/*.profile.tsv | sed -n '1,2p' | cat -A
  #mpa_vJun23_CHOCOPhlAnSGB_202403$
  clade_name^ISmpX.profile^ISmpY.profile$
  $ head -1 merged_taxonomy_allranks.tsv > merged_species.tsv   # SOP line 573
  $ grep -E "s__" merged_taxonomy_allranks.tsv | grep -v "t__" >> merged_species.tsv
  $ head -1 merged_species.tsv | cat -A
  #mpa_vJun23_CHOCOPhlAnSGB_202403$          # <- no clade_name, no sample names
  # §13 reshape on it:
  READ ERROR: IndexError list index out of range
  # §13 reshape on the properly-headed counts table: succeeds, columns ['sampleA','sampleB']
  ```
  The proposed fix below was run end-to-end: it restores `clade_name<TAB>sampleA<TAB>sampleB`,
  the reshape succeeds, and the relab sample IDs match the counts table.
- **Fix:** Replace the two lines with a header taken from the `clade_name` row and the
  `.profile` suffix stripped, so both taxonomy tables share byte-identical sample IDs:
  ```bash
  # merge_metaphlan_tables.py puts the #mpa_ version line FIRST and the real
  # 'clade_name<TAB>samples' header on the SECOND line, and suffixes each sample
  # column with '.profile' from the input filename. Take the header from the
  # clade_name line (NOT head -1) and strip the suffix so sample IDs stay identical
  # to merged_species_counts.tsv and your metadata.
  grep -m1 '^clade_name' tables/merged_taxonomy_allranks.tsv \
    | sed 's/\.profile\(\t\|$\)/\1/g' > tables/merged_species.tsv
  grep -E "s__" tables/merged_taxonomy_allranks.tsv | grep -v "t__" >> tables/merged_species.tsv
  ```

### F-02 · S2 · Option B host scripts use `$DB` inside a batch job, which aborts under `set -u`
- **Where:** SOP_READBASED_NeSI.md:380,393, § 7 Option B (`07a.host_index.sl`, `07b.host_filter.sl`)
- **Anchor:** `path="$DB/human"`
- **Quote:**
  > bbmap.sh -Xmx26g threads=${SLURM_CPUS_PER_TASK} \
  > …
  >   path="$DB/human" \
- **Defect:** Both Option B scripts reference `$DB` (`cd "$DB/human"` in `07a`,
  `path="$DB/human"` in `07b`) but neither defines it, and they run as SLURM batch
  jobs. The README convention is explicit — *"Shell variables (`$WORK`, `$DB`) may be
  used in interactive blocks but never inside a SLURM script — a batch job does not
  inherit your login shell."* Section 9's script obeys this (it sets
  `DB=/nesi/nobackup/<your_nesi_project_code>/db` on its own first line); Section 7
  Option B does not. Under the header's `set -euo pipefail`, an unset `$DB` is a hard
  error, not an empty expansion.
- **Failure:** A reader runs host depletion in a fresh login session (very likely —
  it is days of compute after setup) where `DB` was never re-exported. `07a` and every
  task of the `07b` array die immediately with `DB: unbound variable`, exit 1, before
  any mapping happens — an error that names a variable the reader never sees in the
  script. Even when it happens to work (same session, Slurm's default `--export=ALL`),
  the script violates the stated convention and disagrees with §9.
- **Type:** CONSISTENCY
- **Confidence:** VERIFIED
- **Evidence:**
  ```
  $ bash -c 'set -euo pipefail; cd "$DB/human"; echo reached'
  bash: line 1: DB: unbound variable
  exit=1
  ```
  Contrast §9 line 473, which defines `DB=…` inline in the same situation.
- **Fix:** Add the `DB` definition to the top of both script bodies (matching §9),
  immediately after the module load. In `07a.host_index.sl`:
  ```bash
  DB=/nesi/nobackup/<your_nesi_project_code>/db
  cd "$DB/human"
  ```
  In `07b.host_filter.sl`, add the same `DB=…` line before the `bbmap.sh` call so
  `path="$DB/human"` resolves. (Substitute your project code, as elsewhere.)

### F-03 · S3 · MetaPhlAn re-run aborts on its leftover `--bowtie2out`; triage says just re-run the task
- **Where:** SOP_READBASED_NeSI.md:819, Appendix B Triage
- **Anchor:** `sbatch --array=3,17,42 scripts/09.metaphlan.sl`
- **Quote:**
  > sbatch --array=3,17,42 scripts/09.metaphlan.sl        # re-run only failed tasks
- **Defect:** MetaPhlAn refuses to overwrite an existing `--bowtie2out` file: if the
  file exists and `--force` is not given it prints `BowTie2 output file detected: … Please
  use it as input or remove it … Exiting…` and exits 1 (settled in 00_ENVIRONMENT Q16
  from `metaphlan.py`). A task that failed *after* pass 1 wrote `metaphlan/<sample>.bt2.bz2`
  (e.g. an OOM or timeout in pass 2) leaves that file behind, so the recommended
  re-run of the failed task fails again — this time for a different reason — with no
  `--force` and no cleanup mentioned anywhere.
- **Failure:** Reader re-submits the failed array indices as instructed, watches them
  fail a second time with `Exiting…`, and cannot tell that the block is a stale
  `.bt2.bz2` rather than the original fault.
- **Type:** GAP
- **Confidence:** CONFIRMED
- **Evidence:** 00_ENVIRONMENT Q16 quotes `metaphlan.py:1300-1306` — exits 1 unless
  `--force`, which deletes and re-runs. The SOP's §9 script writes a fixed
  `--bowtie2out` path per sample and Appendix B advises re-running failed tasks; the
  two combine to reproduce the hard-stop.
- **Fix:** Add a line to the triage table and a note in §9: before re-running a failed
  MetaPhlAn task, remove its saved alignment first — `rm -f metaphlan/<sample>.bt2.bz2`
  — or add `--force` to the pass-1 call.

### F-04 · S3 · Section 3.3 always downloads the chm13 reference that only the fallback Option B uses
- **Where:** SOP_READBASED_NeSI.md:180-182, § 3.3 References and databases
- **Anchor:** `wget https://s3-us-west-2.amazonaws.com/human-pangenomics/T2T/CHM13/assemblies/analysis_set/chm13v2.0.fa.gz`
- **Quote:**
  > cd "$DB/human"
  > wget https://s3-us-west-2.amazonaws.com/human-pangenomics/T2T/CHM13/assemblies/analysis_set/chm13v2.0.fa.gz
- **Defect:** §3.3 tells every reader to download chm13v2.0 (the 20-25 GB unmasked
  human reference) as one-time setup, but host depletion's recommended path is Option A
  (Hostile), which fetches its own masked index in §7 and never touches this file.
  Only Option B — flagged as a fallback "use this only if you cannot install Hostile" —
  uses chm13. Setup buried ahead of the branch that needs it, given the same weight as
  the always-needed MetaPhlAn index install right below it.
- **Failure:** A reader following the recommended path spends a large download and
  quota on a reference they never use, and cannot tell from §3.3 that it is optional.
- **Type:** STRUCTURE
- **Confidence:** CONFIRMED
- **Evidence:** §7 Option A (line 343) is "recommended" and fetches
  `human-t2t-hla-argos985` via Hostile; Option B (line 373) is the only consumer of
  `$DB/human/chm13v2.0.fa.gz`. §3.3 gates neither.
- **Fix:** Move the chm13 download into Option B, or prefix it with "Option B only —
  skip if you are using Hostile (Option A)".

### F-05 · S3 · Provenance step reads an Option-B-only file and misses the Option A host reference
- **Where:** SOP_READBASED_NeSI.md:762, § 14 Provenance
- **Anchor:** `cat "$DB/human/chm13v2.0.fa.gz.md5"`
- **Quote:**
  > conda run -n humann humann_config --print; cat "$DB/human/chm13v2.0.fa.gz.md5"
- **Defect:** The provenance block records the host reference by `cat`-ing
  `chm13v2.0.fa.gz.md5`, which exists only if the reader used Option B. An Option A
  (Hostile) user has no such file, so `cat` errors, and — more importantly — the thing
  §14 itself says the methods section needs, "the host reference, and whether it was
  masked", is never captured: the Hostile index name (`human-t2t-hla-argos985`, masked)
  goes unrecorded.
- **Failure:** The recommended-path reader generates a `versions.txt` with a
  `No such file` error where the host reference should be, and has no automatic record
  of which masked index depleted their reads.
- **Type:** GAP
- **Confidence:** CONFIRMED
- **Evidence:** Host reference provenance is required at line 773 ("The host reference,
  and whether it was masked"); the only capture of it (line 762) is the Option B md5,
  absent for Option A.
- **Fix:** Record the host reference conditionally, e.g. append
  `echo "host ref: ${HOSTILE_INDEX:-} (Option A, masked) / $(cat "$DB/human/chm13v2.0.fa.gz.md5" 2>/dev/null || echo 'Option B not used')"`,
  or branch on which option was run.

### F-06 · S4 · §12 names `merged_species.tsv` for decontam; §13 requires the reshaped `part2_relab.tsv`
- **Where:** SOP_READBASED_NeSI.md:655, § 12 Contamination Screening
- **Anchor:** `whereas the frequency method needs DNA concentrations`
- **Quote:**
  > Use the **prevalence** method: it takes `merged_species.tsv` directly, whereas the frequency method needs DNA concentrations you may not have.
- **Defect:** §12 says the prevalence method "takes `merged_species.tsv` directly", but
  §13 is explicit that Part 2 wants the reshaped `part2_relab.tsv` (rank columns, no
  `clade_name` pipe index) and that feeding Part 2 an unreshaped MetaPhlAn table
  silently rounds it. A literal reader hands decontam the wrong file.
- **Failure:** Reader passes raw `merged_species.tsv` to Part 2's decontam step instead
  of `part2_relab.tsv`, hitting the §13 rounding/format trap.
- **Type:** CLARITY
- **Confidence:** CONFIRMED
- **Evidence:** §13 line 688/697 route decontam through `part2_relab.tsv`; §12 line 655
  names `merged_species.tsv`.
- **Fix:** Reword to "the prevalence method needs only the abundance table (no DNA
  concentrations); feed it the reshaped `part2_relab.tsv` from Section 13."

## Verified against the cluster

Every claim I settled by running something (module `MetaPhlAn/4.1.0-gimkl-2022a-Python-3.10.5`
and `BBMap/39.01-GCC-11.3.0`, on `login03`, fixtures under a scratch directory, removed):

- **`merge_metaphlan_tables.py` output layout** — built two profiles, ran the merge:
  line 1 is `#mpa_vJun23_CHOCOPhlAnSGB_202403`, line 2 is `clade_name<TAB>SmpX.profile<TAB>SmpY.profile`.
  → confirms F-01 (comment-as-header + `.profile` suffix).
- **SOP §11 `head -1` + grep extraction** — ran verbatim; resulting `merged_species.tsv`
  has `#mpa_…` as line 1 and no sample-name header. → F-01.
- **§13 reshape `pd.read_csv(index_col=0)`** — crashes with `IndexError` on the broken
  relab table, succeeds on the properly-headed counts table. → F-01 severity.
- **Proposed F-01 fix** — `grep -m1 '^clade_name' | sed 's/\.profile\(\t\|$\)/\1/g'`
  restores `clade_name<TAB>sampleA<TAB>sampleB`, reshape then runs and sample IDs match
  the counts table. → F-01 fix is paste-ready and correct.
- **`set -euo pipefail; cd "$DB/human"` with `$DB` unset** — `DB: unbound variable`,
  exit 1. → F-02.
- **BBDuk 39.01 poly-G / ftm flags** — `bbduk.sh --help` lists `trimpolygright`,
  `trimpolygleft`, `trimpolyg`, `filterpolyg`, `forcetrimmod (ftm)`. → the SOP's claim
  (line 298, "39.01 module supports them"; and `ftm=5` at line 280) HOLDS.
- **`merge_metaphlan_tables.py` present in the pinned MetaPhlAn module** — resolves to
  `…/MetaPhlAn/4.1.0-…/bin/merge_metaphlan_tables.py`. → §11 command runnable.
- **Depth-budget arithmetic (§1)** — checked each row by hand: 5e6÷0.90÷0.85≈6.5 M,
  ÷0.10÷0.85≈59 M, ÷0.003÷0.85≈2 B. → the previous round's inverted-multiply S1 is
  fixed and the "divide, do not multiply" text is correct. HOLDS.

## Keep list

Load-bearing content a tightening pass must not lose:

- **Governance / re-identification** (line 50, `re-identify individuals against matched
  genotype data at 93.3% sensitivity`) — the human-data justification; do not compress
  the citation or the "controlled-access" instruction away.
- **Depth "divide, do not multiply"** (line 92, `Divide, do not multiply.`) — the fix
  to the prior round's S1; the worked table is the proof and must stay.
- **Two-pass BBDuk rationale** (line 269, `they cannot be combined into one`) — the
  `ktrim=r` truncates-PhiX reasoning; removing it invites a wrong single pass.
- **`trimq=10, not 20`** (line 291, `biases against GC-extreme and low-coverage
  genomes`) — a why-this-number the reader can't reconstruct.
- **Masked-reference reasoning** (line 341, `parameters come from JGI's recipe and
  assume a masked reference`) — pairs with the Option B mock-community requirement.
- **`--index` and `--offline` reproducibility** (line 490, `depend on when someone last
  ran the tool with internet access`) — the reproducibility argument.
- **All-ranks 8× sum warning** (line 570, `a column sums to roughly 8x the classified
  fraction`) — stops a silent misuse of the merged table.
- **HUMAnN temp-dir trap** (line 552, `any cleanup placed after the command would never
  run`) — prevents a filesystem-filling failure at cohort scale.

## Gaps

- **No "what a good MetaPhlAn profile looks like"** (`CONSIDER`, ~3 lines). §13 point 6
  mentions excluding empty/one-taxon profiles, but §9 gives no success signal for a
  profile the way §5 does for QC. A reader can't tell a failed profile from a real one
  at the point it is produced. Add a line: non-empty, species rows sum to ~100%, and a
  flag if a single taxon exceeds ~99%.
- **chm13 download is optional but ungated** (`SHOULD-ADD`, 1 line) — per F-04; the
  cleanest fix is a one-line "Option B only" gate in §3.3.
- **Metadata file format is asserted, not shown** (`CONSIDER`, ~3 lines). Line 690 says
  "metadata keyed by sample ID, with group, batch or run, and every covariate", but no
  example. Given F-01's sample-ID sensitivity, a one-row example keyed on the bare
  `<sample>` ID would prevent the join mismatch.

## Cross-document flags

Claims about other files I cannot resolve from this document alone:

- **SLURM header mechanism** — README (line 55) mandates "One SLURM job header, in
  Part 1 Section 1 … `#SBATCH --chdir <absolute workspace path>`, log paths relative to
  it". This SOP's §4 header instead uses `cd "${SLURM_SUBMIT_DIR:?}"` plus "Submit every
  job from `$WORK`" and no `--chdir`. Self-consistent here, but check it against Part 1's
  canonical header.
- **Part 2 loader behaviour** — §13 (line 669) claims Part 2's "Stage 1 loader will
  round your percentages into small integers rather than reject them". Cannot verify
  Part 2 does this; it is the premise of the reshape step and of F-06.
- **Object-naming suffixes** — §13 (line 699) tells the reader to use `ps_relab` /
  `ps_estcounts`; README (line 59) defines these in Part 2's "Key objects" table. Verify
  Part 2 actually defines both.
- **decontam prevalence method** — §12/§13 say `SOP_R_Analysis.md` "already covers"
  decontam's prevalence method. Cannot confirm it is there.
- **Sample-ID convention** — README (line 57) requires byte-identical sample IDs with
  tool-added suffixes stripped "where they are created". F-01's `.profile` suffix and
  its fix are exactly this convention; confirm the convention text is authoritative.

## Rewrite plan

1. **F-01 (§11 relative-abundance merge)** — replace the two-line `head -1`/grep block
   with the header-from-`clade_name` + `.profile`-strip version. ~4 lines. Independent;
   highest priority (S1, silent). Closes F-01.
2. **F-02 (§7 Option B)** — add `DB=/nesi/nobackup/<code>/db` to the top of
   `07a.host_index.sl` and `07b.host_filter.sl` bodies. ~2 lines. Independent. Closes F-02.
3. **F-04 + Gap (chm13 gating)** — move the chm13 `wget`+md5 into Option B, or gate it
   "Option B only". Small. Independent. Closes F-04; enables a cleaner F-05.
4. **F-05 (§14 provenance)** — branch the host-reference record on Option A vs B. ~2
   lines. Best done after F-04 so the two agree. Closes F-05.
5. **F-03 (re-run guard)** — add the `rm -f metaphlan/<sample>.bt2.bz2` note to §9 and a
   triage-table row. ~2 lines. Independent. Closes F-03.
6. **F-06 (§12 decontam file)** — one-sentence reword to point at `part2_relab.tsv`.
   Independent. Closes F-06.

## Notes against reviews/v1/READBASED.review.md

(Consulted only after the four passes above.) v1 was a 24-finding report; the current
text is a rewrite that applied some of it and left the rest. Reconciling:

- **v1 got right and the rewrite fixed** — v1 F-01 (depth multiply→divide) is fixed and
  arithmetically correct (I re-checked every row). v1 F-02 (EC/KO never split) is fixed
  (§11 lines 631-632 now split them). v1 F-03 (SRS routing estimated counts into alpha
  diversity) is fixed (§13 line 694 now says "Skip it … do **not** substitute"). v1 F-08
  (`$DB` in single-quoted `bash -c`) is fixed (§10 line 518 `export DB`). v1 F-05
  (Option B masked params on unmasked ref) is now gated by the mock-community +
  methods-statement requirement (§7 lines 373-375). Good outcomes; I did not re-file these.
- **v1 got right and the rewrite left OPEN — my findings re-confirm these:** my **F-01**
  is v1 **F-10 + F-11** (the `head -1` comment-as-header and the un-reconciled sample
  column names); my **F-02** is v1 **F-06** (`$DB` under `set -u` in Option B); my **F-03**
  is v1 **F-24** (re-run hits leftover `.bt2.bz2`); my **F-04** is v1 **F-17** (chm13 on
  the path that never uses it); my **F-05** is v1 **F-13** (provenance records only Option
  B's host reference). None of these were applied in the rewrite. I settled them here by
  running the tool rather than by inspection alone.
- **Where I disagree with v1 on severity** — I merge v1 F-10 + F-11 into one finding and
  **escalate it to S1** (v1 graded each S2). The escalation is because the `.profile`
  sample-ID suffix, once the header crash is patched, silently mis-aligns the
  relative-abundance table against the counts table and metadata — wrong-but-plausible
  compositional output, which the brief ranks S1. Conversely I grade my F-05 as **S3**
  (v1 F-13 was S2): a broken provenance record degrades the methods section but does not
  block the pipeline.
- **v1 findings I judged already-adequate in the current text, so did not re-file** — v1
  F-07 (depth gates vs controls) is softened by the current "flag it" wording rather than
  "exclude", though the gate table still never states the depth floors do not apply to
  controls (residual CONSIDER, folded into Gaps). v1 F-12 (`metaphlan/utils/` vs the
  reader's own `metaphlan/` output dir, §13 UniFrac row) and v1 F-14 (`-s` test passes on
  a non-empty-but-failed profile) remain literally true but are niche; F-14's substance
  is covered by my Gaps entry on "what a good profile looks like".

## Contract self-check

```
$ python3 <self-check script from the brief, REPORT=reviews/READBASED.review.md SOURCE=SOP_READBASED_NeSI.md>
findings=6 S1=1 S2=1 S3=3 S4=1
CLEAN
```

By-hand confirmation of the three the script cannot check:

- [x] **Ledger accounts for every heading in the file** — all `#`/`##`/`###` headings
  (title, roadmap, §1-14 with subsections, Appendices A-C, closing note) are listed in
  the Section ledger; cross-checked against `grep -nE '^(#|##|###) '`.
- [x] **No proposed cut touches load-bearing content** — no finding proposes a CUT of
  a why-this-number, silent-failure warning, expected-output, citation, scope limit,
  governance, or concept explanation. F-01/F-02 are corrections, F-03/F-05 additions,
  F-04 a relocation, F-06 a reword. The Keep list guards the load-bearing "why" content.
- [x] **Every NOT-VERIFIABLE-HERE is genuinely not verifiable** — this report contains
  no NOT-VERIFIABLE-HERE findings; every finding is CONFIRMED or VERIFIED, and the four
  runnable claims (F-01, F-02, and the poly-G/depth HOLDS) were run.

CONTRACT: PASS
