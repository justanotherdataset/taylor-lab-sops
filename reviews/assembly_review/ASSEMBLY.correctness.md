# Correctness/Safety Review — `SOP_ASSEMBLY_NeSI.md` (dedicated on-cluster round)

Run 2026-08-04 on NeSI Mahuika, from `/nesi/project/uoa03769/taylor-lab-sops`.
Read in order: COMMON BRIEF + AGENT PROMPT A of `prompts/SOP_REVIEW_PROMPT.md` →
`reviews/capstone/ASSEMBLY.md`, `reviews/capstone/00_VERDICT.md` (ASSEMBLY sections),
`reviews/capstone/00_FACTS.md` → `SOP_ASSEMBLY_NeSI.md` in full (988 lines, v0.1).
The capstone's ship-blockers **C-04** (GTDB-Tk glob) and the **draft banner / suite
version** are already committed (`git log`: e8d44c2, a108693, 06d24ff); I re-verified
the C-04 fix is correct. This round settles the deep checks the capstone said needed
"a fixture run I could not do here", and finds two new S2 blockers a read-only pass
could not: `coverm genome` cannot run under §14's module set, and its `count` command
is rejected outright.

Confidence vocabulary per the orchestrator: `CONFIRMED` / `VERIFIED` / `NEEDS-BENCH-CHECK`.

## Document: SOP_ASSEMBLY_NeSI.md

A strong, teaching-first draft that is close to suite standard: Section 1 defines the
whole binning vocabulary before any command, every job block is complete with header,
`set -euo pipefail` and an empty-`$SAMPLE` guard, and the "why this number" content is
present and correct. Its correctness spine is largely sound — I verified by source or
fixture that the CheckM2 awk columns, the dRep `genomeInfo` header, the DAS_Tool
`--write_bins` extension, the GTDB-Tk parser, the Bakta `.faa` handoff, the MEGAHIT
output path, and the CoverM/§15 reshape are all correct. What is *not* sound is the
final quantification stage: **§14 (CoverM) cannot run as printed** — the module it loads
provides no mapper, the modern SAMtools it would pull is broken by CoverM's own
`LegacySystemLibs/7`, and the `count` command is rejected by CoverM whenever
`--min-covered-fraction > 0`. The single change that would most improve the document is
to fix §14 so the abundance table — the deliverable the whole SOP exists to produce and
hand to Part 2 — is actually buildable, then close the still-open non-default-fork and
submission-appendix defects the capstone flagged.

## Section ledger

Every heading in file order. Verdicts ∈ {CLEAN, TIGHTEN, REWRITE, RESTRUCTURE, EXPAND, CUT, SPLIT, MERGE}.

| § | Heading | Lines | Verdict | Findings |
|---|---|---|---|---|
| — | Title + version + draft banner | 1-9 | CLEAN (banner/suite-version already applied) | — |
| — | Before you start | 13-16 | REWRITE | F-01 |
| — | Quick Roadmap: What You'll Do | 21-41 | CLEAN | — |
| 1 | Understanding Your Data | 44-83 | TIGHTEN (heading case, jargon) | F-09 |
| 1· | Assembly versus read-based profiling | 48-52 | CLEAN | — |
| 1· | From reads to a MAG | 54-63 | TIGHTEN (heading case) | F-09 |
| 1· | Why binning uses two signals | 65-67 | TIGHTEN (k-mer gloss) | F-09 |
| 1· | Completeness, contamination and the MIMAG tiers | 69-71 | CLEAN | — |
| 1· | Dereplication and ANI | 73-75 | CLEAN | — |
| 1· | What GTDB gives you | 77-79 | CLEAN | — |
| 1· | The final table is compositional | 81-83 | CLEAN | — |
| 2 | Before You Generate Data | 87-102 | CLEAN — governance/depth, keep | — |
| 2· | Residual host sequence survives into contigs | 91-93 | CLEAN | — |
| 2· | Assembly needs more depth than profiling | 95-97 | CLEAN | — |
| 2· | Controls still matter, differently | 99-101 | CLEAN | — |
| 3 | Setup | 105 | CLEAN | — |
| 3.1 | Directories and the input contract | 107-125 | REWRITE | F-06 |
| 3.2 | The job header | 127-129 | CLEAN | — |
| 3.3 | A note on module strings | 131-133 | CLEAN | — |
| 4 | Assemble the Reads | 137-258 | REWRITE | F-02 |
| 4· | Assembler: MEGAHIT / metaSPAdes | 141-143 | CLEAN | — |
| 4· | Strategy: per-sample or co-assembly | 145-154 | CLEAN | — |
| 4· | Per-sample assembly with MEGAHIT | 156-191 | CLEAN — output path verified | — |
| 4· | Alternative: per-sample with metaSPAdes | 193-221 | REWRITE | F-02 |
| 4· | Alternative: co-assembly with MEGAHIT | 223-250 | REWRITE | F-02 |
| 4· | Checkpoint | 252-258 | CLEAN | — |
| 5 | Assess the Assembly | 262-293 | CLEAN | — |
| 5· | Filter short contigs before binning | 295-307 | REWRITE (co-assembly path) | F-02 |
| 6 | Map Reads for Coverage | 311-352 | CLEAN — combined load verified | — |
| 7 | Bin the Contigs | 356-415 | CLEAN — extensions/cut cols verified | — |
| 8 | Refine the Bins | 419-461 | CLEAN — write_bins `.fa` verified | — |
| 8· | Collect every sample's MAGs into one place | 463-478 | CLEAN — `*.fa` glob verified | — |
| 9 | Assess MAG Quality | 482-506 | CLEAN — awk cols verified | — |
| 9· | Apply the MIMAG tiers | 508-527 | CLEAN | — |
| 10 | Dereplicate Across Samples | 530-564 | CLEAN — genomeInfo header verified | — |
| 11 | Classify the MAGs | 568-599 | CLEAN — C-04 fix verified | — |
| 11· | Convert GTDB ranks to the repository vocabulary | 601-627 | CLEAN — parser verified | — |
| 12 | Annotate the MAGs | 631-671 | REWRITE | F-07, F-08 |
| 13 | Deep Functional Annotation (Optional) | 674-737 | RELABEL | F-09 |
| 13· | eggNOG-mapper | 678-710 | CLEAN — reads `.faa`, verified | — |
| 13· | DRAM — metabolic reconstruction | 712-737 | RELABEL (name the script) | F-09 |
| 14 | Build the MAG × Sample Abundance Table | 740-782 | REWRITE | F-03, F-04 |
| 15 | Handoff to the R Analysis | 785-833 | CLEAN — reshape verified | — |
| 15· | Reshape before you open the R analysis | 789-810 | CLEAN — verified on fixture | — |
| 15· | What changes in the R analysis | 812-822 | CLEAN — tree path (C-04) verified | — |
| 15· | Where MAG analysis legitimately diverges | 824-833 | CLEAN | — |
| 16 | Provenance | 836-872 | CLEAN — keep | — |
| — | Troubleshooting | 876-891 | TIGHTEN (add CoverM/bakta rows) | F-03, F-07 |
| A | Appendix A: Submission Chain | 894-918 | REWRITE | F-05 |
| B | Appendix B: Tools and Resources | 920-960 | TIGHTEN (add SAMtools row for §14) | F-03 |
| C | Appendix C: References | 962-981 | CLEAN — keep | — |
| — | Closing verify paragraph | 983-988 | CLEAN | — |

## Findings

### F-01 · S2 · Prereq "run one NeSI pipeline first" contradicts the suite's terminal-novice audience
- **Where:** SOP_ASSEMBLY_NeSI.md:16, § Before you start
- **Anchor:** `You need to have run one NeSI pipeline before`
- **Quote:**
  > - **You need to have run one NeSI pipeline before.** Bash, `module`, `sbatch` and array jobs are taken as familiar. If they are not, work through `SOP_EMU_NeSI.md` Section 1 first — it is the only document that teaches the cluster.
- **Defect:** `TUTORIAL_SPEC.md` §1 sets one audience for the whole suite — "A graduate student who has never opened a terminal" — and states the prior-pipeline assumption "is withdrawn". This line reinstates it as a hard prerequisite, and the redirect it offers ("EMU Section 1") is too narrow: the FASTQ/quality-score grounding a first-timer needs lives in EMU §2, and this SOP separately leans on `srun --pty`, `hugemem` and `nn_seff` that a single §1 pointer does not cover.
- **Failure:** The suite's stated reader lands here from the README, reads that they must already have "run one NeSI pipeline", and either stops (believing they are unqualified) or is sent to EMU §1, which does not teach the concepts they are missing → they proceed under-equipped.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED
- **Evidence:** Direct contradiction, both sides quoted — ASSEMBLY:16 ("taken as familiar") vs `TUTORIAL_SPEC.md` §1 ("A graduate student who has never opened a terminal … that assumption is withdrawn"). This is capstone C-11 / verdict C-11, re-confirmed still-present at line 16 (`grep -nF` hit). Tutorial round owns the class, but it is live in the shipped text.
- **Fix:** Replace line 16 with a redirect that matches the READBASED rewrite:
  > - **This SOP does not re-teach the cluster.** Bash, `module`, `sbatch` and array jobs are used throughout; if they are new to you, work through `SOP_EMU_NeSI.md` **Sections 1–2** first — it is the only document that teaches the cluster, starting from `pwd`, and Section 2 covers FASTQ and quality scores. You do not need to have finished another pipeline, only that grounding.

### F-02 · S2 · metaSPAdes and co-assembly forks read contig files the §4 commands never create
- **Where:** SOP_ASSEMBLY_NeSI.md:219 (metaSPAdes note) and 295-307 / 336 (§5-§6 hard-coded paths), §§ 4-6
- **Anchor:** `so downstream scripts must point at the right one`
- **Quote:**
  > metaSPAdes writes contigs to `assemblies/${SAMPLE}/contigs.fasta` — a different name and path from MEGAHIT, so downstream scripts must point at the right one.
- **Defect:** Every step from §5 on hard-codes the MEGAHIT per-sample artefact (`assemblies/${SAMPLE}/${SAMPLE}.contigs.fa` → `…min1500.fa`). The doc flags that metaSPAdes writes `contigs.fasta` but never resolves it, and the co-assembly path §6 references (`coassembly/all/coassembly.min1500.fa`, line 336) is never produced — §5's metaQUAST and the min1500 filter loop run per-sample only. Both non-default forks carry "choose when" guidance and are wired into Appendix A, yet either one strands the reader at §5/§6.
- **Failure:** A reader who correctly picks metaSPAdes (line 193) or co-assembly (line 223) finishes §4, then §5's `seqkit seq -m 1500 assemblies/${S}/${S}.contigs.fa …` and §6's mapping fail on a missing file with no bridge command → hard stop with a bare "file not found".
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED
- **Evidence:** §5 filter reads `assemblies/${S}/${S}.contigs.fa` (line 303); §6 sets `ASM="assemblies/${SAMPLE}/${SAMPLE}.min1500.fa"` with co-assembly comment `coassembly/all/coassembly.min1500.fa` (line 336); metaSPAdes writes `contigs.fasta` (line 219, the doc's own words); co-assembly writes `coassembly/all/coassembly.contigs.fa` (line 250) and no §5 step filters it. Capstone C-12 / verdict C-12, re-confirmed present.
- **Fix:** Normalise each alternative to the canonical MEGAHIT path so the rest of the SOP is untouched.
  (a) In `scripts/04b.assemble_metaspades.sl`, add after the `spades.py` command:
  ```bash
  ln -sf contigs.fasta "assemblies/${SAMPLE}/${SAMPLE}.contigs.fa"   # canonical name for §5–§8
  ```
  (b) For co-assembly, add a one-off block at the end of §5 (before §6), and state that `$ASM` for §6–§8 is then `coassembly/all/coassembly.min1500.fa` (the mapping array still runs `1-${NSAMP}`, mapping every sample to the one assembly):
  ```bash
  # Co-assembly only: QC and filter the single assembly to the canonical min1500 name.
  module purge; module load QUAST/5.2.0-gimkl-2022a
  metaquast.py coassembly/all/coassembly.contigs.fa -o qc_assembly/coassembly \
    --min-contig 1000 --max-ref-number 0 --threads 8
  module purge; module load SeqKit/2.4.0
  seqkit seq -m 1500 coassembly/all/coassembly.contigs.fa > coassembly/all/coassembly.min1500.fa
  ```

### F-03 · S2 · §14 CoverM job loads only CoverM; `coverm genome` aborts with no minimap2/samtools on PATH
- **Where:** SOP_ASSEMBLY_NeSI.md:758, § 14 (the `scripts/14.coverm.sl` module-load line)
- **Anchor:** `module purge; module load CoverM/0.7.0-GCC-12.3.0`
- **Quote:**
  > module purge; module load CoverM/0.7.0-GCC-12.3.0
- **Defect:** `coverm genome` maps reads with minimap2 (its default mapper) and post-processes with samtools, but the `CoverM/0.7.0-GCC-12.3.0` module provides *neither* on `PATH` and bundles neither. CoverM panics on the first missing tool. Worse, the obvious fix — add `SAMtools/1.23.1-GCC-12.3.0` as used in §6 — does not work: CoverM auto-loads `LegacySystemLibs/7`, which breaks SAMtools 1.23.1 with a krb5 symbol clash, so samtools dies before CoverM can call it. The abundance table (the SOP's final deliverable, feeding Part 2) is never built.
- **Failure:** Reader submits §14 as printed → job exits non-zero with `Cannot continue without minimap2. Testing for presence with 'which minimap2' failed`; if they add the §6 SAMtools they instead get `samtools: symbol lookup error: /lib64/libkrb5.so.3: undefined symbol: krb5int_c_deprecated_enctype` → no `coverm/mag_relabund.tsv` or `mag_counts.tsv`, so §15 and the entire R handoff cannot proceed.
- **Type:** CORRECTNESS
- **Confidence:** VERIFIED
- **Evidence:** Built a 2-genome / 2-sample fixture and ran §14's exact command.
  ```
  # (1) CoverM alone (as the SOP loads it):
  $ module purge; module load CoverM/0.7.0-GCC-12.3.0
  $ coverm genome --coupled clean/S1_R1.fastq.gz ... --methods relative_abundance ...
  [ERROR external_command_checker] Could not find an available minimap2 executable.
  thread 'main' panicked: "Cannot continue without minimap2..."   # exit 101, no output file
  $ module list  ->  only GCCcore, GCC, CoverM  (no minimap2/samtools)
  # (2) add SAMtools/1.23.1 (the §6 version):
  $ module load CoverM/... minimap2/2.30-GCC-12.3.0 SAMtools/1.23.1-GCC-12.3.0
  $ samtools --version
  samtools: symbol lookup error: /lib64/libkrb5.so.3: undefined symbol: krb5int_c_deprecated_enctype
  $ module show CoverM/0.7.0-GCC-12.3.0  ->  load("LegacySystemLibs/7")   # the culprit
  # (3) working combo (minimap2 + the older SAMtools MetaBAT also pulls):
  $ module load CoverM/... minimap2/2.30-GCC-12.3.0 SAMtools/1.19-GCC-12.3.0
  $ coverm genome --coupled ... --methods relative_abundance --min-covered-fraction 0.10 ...
  # exit 0; wrote:  Genome / S1_R1.fastq.gz Relative Abundance (%) / S2_... ; gA=100 gB=100
  ```
- **Fix:** Load the mapper and a CoverM-compatible samtools on the §14 command path (replace line 758):
  ```bash
  # CoverM's genome mode shells out to minimap2 (mapper) and samtools; the module bundles
  # neither. Note SAMtools 1.23.1 (§6) is broken here by CoverM's LegacySystemLibs/7 — use 1.19.
  module purge; module load CoverM/0.7.0-GCC-12.3.0 minimap2/2.30-GCC-12.3.0 SAMtools/1.19-GCC-12.3.0
  ```
  Add a `CoverM: "Cannot continue without minimap2" / samtools krb5 error` row to Troubleshooting, and add `SAMtools/1.19-GCC-12.3.0` beside CoverM in the Appendix B row. (An alternative that avoids the version pin is to feed CoverM the §6 BAMs via `--bam-files mapping/*.bam` instead of re-mapping, but that is a larger rewrite.)

### F-04 · S2 · §14 count table never written: `coverm count` rejects `--min-covered-fraction 0.10`
- **Where:** SOP_ASSEMBLY_NeSI.md:773, § 14 (the second `coverm genome` call)
- **Anchor:** `Read counts for differential abundance (integer-like`
- **Quote:**
  > coverm genome --coupled "${READS[@]}" \
  >   --genome-fasta-directory drep/dereplicated_genomes -x fa \
  >   --methods count --min-covered-fraction 0.10 \
  >   --threads "${SLURM_CPUS_PER_TASK}" -o coverm/mag_counts.tsv
- **Defect:** CoverM's `count` estimator cannot be combined with `--min-covered-fraction > 0` — it refuses and exits non-zero without writing the file, because `count` does not compute a covered fraction. Under the script's `set -euo pipefail`, this aborts §14. The relative-abundance table is written first, but `coverm/mag_counts.tsv` never is, so the differential-abundance branch of the R handoff (`part2_counts.tsv`, §15) has no input.
- **Failure:** Reader runs §14 → the first (relabund) command succeeds, the second (count) errors, the job fails; reader sees `mag_relabund.tsv` present but the job "failed" and `mag_counts.tsv` absent, then §15's `pd.read_csv("coverm/mag_counts.tsv")` raises → no DA analysis.
- **Type:** CORRECTNESS
- **Confidence:** VERIFIED
- **Evidence:** Ran §14's count command on the fixture:
  ```
  $ coverm genome --coupled ... --methods count --min-covered-fraction 0.10 -o mag_counts.tsv
  [ERROR coverm] The 'counts' coverage estimator cannot be used when --min-covered-fraction
  is > 0 as it does not calculate the covered fraction. You may wish to set the
  --min-covered-fraction to 0 ...   # exit 1, mag_counts.tsv NOT written
  $ coverm genome --coupled ... --methods count --min-covered-fraction 0 -o mag_counts.tsv   # exit 0
  Genome<TAB>S1_R1.fastq.gz Read Count<TAB>S2_R1.fastq.gz Read Count
  gA  800  0
  gB  0    800        # note: count table has NO 'unmapped' row (unlike relative_abundance)
  ```
- **Fix:** Set `--min-covered-fraction 0` on the count command (line 773):
  ```bash
  # Read counts for differential abundance (count cannot take a min-covered-fraction filter;
  # presence is already gated by the relative_abundance table above).
  coverm genome --coupled "${READS[@]}" \
    --genome-fasta-directory drep/dereplicated_genomes -x fa \
    --methods count --min-covered-fraction 0 \
    --threads "${SLURM_CPUS_PER_TASK}" -o coverm/mag_counts.tsv
  ```
  Also correct the §14 checkpoint (line 781): only the relative-abundance table carries an `unmapped` row; the count table does not — reword "(plus an `unmapped`/`Genome` row)" to "(the relative-abundance table also carries an `unmapped` row)".

### F-05 · S2 · Appendix A says submit-at-once but wires jobs past manual steps and uses unset `$NMAG`
- **Where:** SOP_ASSEMBLY_NeSI.md:896-918, § Appendix A: Submission Chain
- **Anchor:** `submit the pipeline at once and let SLURM sequence it`
- **Quote:**
  > Each job waits on the one it depends on, so you can submit the pipeline at once and let SLURM sequence it.
- **Defect:** The appendix contradicts itself and cannot run as printed. It later says "The two interactive steps (contig filtering, bin collection) break the chain deliberately", yet the block wires `MAP` to `afterok:$ASM` (mapping auto-starts before the manual min1500 filter has run) and `CM2` to `afterok:$DAS` (CheckM2 auto-starts before the manual `mags/` collection). It also submits `12.bakta.sl --array=1-${NMAG}%10` while `$NMAG` is unset — `mags_derep.txt`, the file it counts, is not built until §12, after dRep — so that line errors at submit with an invalid array spec.
- **Failure:** A reader who pastes the block "at once" queues assembly and metaQUAST, then map_coverage and every later job fire on their dependencies before the human has run the filter/collect steps → cascading missing-file failures; the bakta line additionally rejects on an empty `--array=1-%10`. The reader believes the pipeline is sequencing when key stages never ran.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED
- **Evidence:** Line 896 "submit the pipeline at once" vs line 918 "break the chain deliberately"; MAP/CM2 dependencies (lines 904/908) point at `$ASM`/`$DAS`, not the interactive steps commented at 903/907; `$NMAG` is never set in the block (only `NSAMP`, line 899) yet used at line 912. Capstone C-13 / verdict C-13, re-confirmed present (`grep -nF 'array=1-${NMAG}%10 scripts/12.bakta.sl'` → 654 and 912).
- **Fix:** Present the chain in three submit-phases with the interactive steps between, and defer bakta's array until `mags_derep.txt` exists:
  ```bash
  cd "$WORK"; NSAMP=$(wc -l < samples.txt)

  # Phase 1 — assemble, then STOP: filter to min1500 (Section 5) interactively.
  ASM=$(sbatch --parsable --array=1-${NSAMP}%4 scripts/04a.assemble_megahit.sl)
  QC=$(sbatch  --parsable --dependency=afterok:$ASM --array=1-${NSAMP} scripts/05.metaquast.sl)

  # → wait for $ASM, run the Section 5 filter loop, THEN Phase 2:
  MAP=$(sbatch  --parsable --array=1-${NSAMP}%8 scripts/06.map_coverage.sl)
  BIN=$(sbatch  --parsable --dependency=afterok:$MAP --array=1-${NSAMP}%6 scripts/07.bin.sl)
  DAS=$(sbatch  --parsable --dependency=afterok:$BIN --array=1-${NSAMP}%6 scripts/08.dastool.sl)

  # → wait for $DAS, run the Section 8 collection loop, THEN Phase 3:
  CM2=$(sbatch  --parsable scripts/09.checkm2.sl)
  DREP=$(sbatch --parsable --dependency=afterok:$CM2 scripts/10.drep.sl)
  GTDB=$(sbatch --parsable --dependency=afterok:$DREP scripts/11.gtdbtk.sl)

  # → wait for $DREP, build mags_derep.txt (Section 12), THEN:
  NMAG=$(wc -l < mags_derep.txt)
  sbatch --dependency=afterok:$GTDB --array=1-${NMAG}%10 scripts/12.bakta.sl
  sbatch scripts/14.coverm.sl
  squeue --me
  ```

### F-06 · S3 · samples.txt with no trailing newline silently drops the last sample
- **Where:** SOP_ASSEMBLY_NeSI.md:122, § 3.1 Directories and the input contract
- **Anchor:** `NSAMP=$(wc -l < samples.txt); echo "samples: $NSAMP"`
- **Quote:**
  > NSAMP=$(wc -l < samples.txt); echo "samples: $NSAMP"
- **Defect:** `NSAMP` is set with `wc -l`, which counts newline characters; and §5's filter loop and §14's READS array both iterate with `while read -r S … done < samples.txt`. If the copied `samples.txt` lacks a trailing newline on its last line, all three undercount by one: `wc -l` returns N−1 (so `--array=1-${NSAMP}` never schedules the last sample) and the `while read` loops skip the last sample. The §3.1 `sed 's/\r$//; /^$/d'` sanitises CRLF and blank lines but does not guarantee a final newline. The failure is silent — a cohort one sample short with no error.
- **Failure:** Reader whose upstream `samples.txt` (from READBASED) ends without a newline runs §3.1, sees a plausible `samples: N-1`, and assembles/filters/quantifies N−1 samples; the missing sample surfaces nowhere until they notice a MAG × sample table with a column missing.
- **Type:** CORRECTNESS
- **Confidence:** VERIFIED
- **Evidence:** Reproduced on a 3-line file with no trailing newline:
  ```
  $ printf 'S1\nS2\nS3' > s.txt
  $ wc -l < s.txt                 # 2   <- undercounts; there are 3 samples
  $ sed -n '3p' s.txt             # S3  <- sed DOES see line 3 (so sbatch -n Np would work)
  $ while read -r S; do echo "$S"; done < s.txt   # prints S1, S2 only  <- drops S3
  ```
- **Fix:** Make the sample count robust to a missing final newline; count non-empty lines instead of newlines, and normalise the file. In §3.1, change the sanitise+count lines to:
  ```bash
  sed -i 's/\r$//; /^$/d' samples.txt              # CRLF / blank lines become an empty $SAMPLE
  [ -n "$(tail -c1 samples.txt)" ] && echo >> samples.txt   # guarantee a trailing newline
  NSAMP=$(grep -c . samples.txt); echo "samples: $NSAMP"    # counts lines, newline or not
  ```

### F-07 · S3 · §12 bakta has no --force guard; re-running a failed array aborts on the existing dir
- **Where:** SOP_ASSEMBLY_NeSI.md:661, § 12 Annotate the MAGs
- **Anchor:** `bakta --db /opt/nesi/db/bakta/v5.1/db`
- **Quote:**
  > bakta --db /opt/nesi/db/bakta/v5.1/db \
  >   --output "annotation/bakta/${MAG}" --prefix "${MAG}" \
- **Defect:** Bakta refuses to write into an existing output directory unless `--force` is given, and §12 supplies neither `--force` nor a preceding `rm -rf "annotation/bakta/${MAG}"`. This is inconsistent with the SOP's own re-run guards (§4 MEGAHIT `rm -rf`, §9 CheckM2 `--force`). Re-running the bakta array after some tasks failed (walltime, node) re-runs the *succeeded* tasks too, and each aborts on its existing directory.
- **Failure:** Reader re-submits the bakta array to pick up a few failed MAGs; the already-annotated MAGs immediately exit with `ERROR: output path (annotation/bakta/<MAG>) already exists! … force overwriting it via '--force'` → the array looks broadly broken and the reader cannot tell the real failures from the guard trips.
- **Type:** CORRECTNESS
- **Confidence:** VERIFIED
- **Evidence:** From the installed bakta source, `bakta/config.py:350-351`:
  ```
  elif(force_override is False):
      sys.exit(f'ERROR: output path ({output_path}) already exists! Either provide a
      non-existent new path or force overwriting it via \'--force\'')
  ```
  `bakta --help` confirms `--force, -f  Force overwriting existing output folder`.
- **Fix:** Add `--force` to the bakta command (one line), matching the CheckM2 pattern:
  ```bash
  bakta --db /opt/nesi/db/bakta/v5.1/db --force \
    --output "annotation/bakta/${MAG}" --prefix "${MAG}" \
    --threads "${SLURM_CPUS_PER_TASK}" \
    "drep/dereplicated_genomes/${MAG}.fa"
  ```

### F-08 · S3 · §12 checkpoint wrong: bakta writes three `.tsv` per MAG, so the count is ~3×NMAG not NMAG
- **Where:** SOP_ASSEMBLY_NeSI.md:670, § 12 checkpoint
- **Anchor:** `ls annotation/bakta/*/*.tsv | wc -l`
- **Quote:**
  > **Checkpoint:** `ls annotation/bakta/*/*.tsv | wc -l` should equal `$NMAG`. A MAG with **zero coding sequences** is not a real genome — cross-check it against its CheckM2 completeness.
- **Defect:** Bakta writes three `.tsv` files per genome — `${MAG}.tsv`, `${MAG}.inference.tsv` and (with CDS calling on, the default) `${MAG}.hypotheticals.tsv`. So `ls annotation/bakta/*/*.tsv | wc -l` returns roughly `3 × NMAG`, never `NMAG`. The checkpoint's stated pass condition can never be met on a successful run.
- **Failure:** Reader runs the checkpoint after a *successful* bakta array, sees ~3× their MAG count against "should equal `$NMAG`", and concludes something is wrong (bakta ran multiple times, or the count is corrupt) — a false alarm on correct output.
- **Type:** CORRECTNESS
- **Confidence:** VERIFIED
- **Evidence:** From bakta source `bakta/main.py`: `{prefix}.tsv` (line 534, unconditional), `{prefix}.inference.tsv` (line 559, unconditional), `{prefix}.hypotheticals.tsv` (line 571, under `if cfg.skip_cds is False:` — the default). Three `.tsv` per MAG.
- **Fix:** Count one file per MAG. Change the checkpoint to glob the single `.gff3` (one per MAG) or the primary `.tsv` explicitly:
  ```
  > **Checkpoint:** `ls annotation/bakta/*/*.gff3 | wc -l` should equal `$NMAG` (bakta writes one GFF3 per MAG; note it also writes three `.tsv` files each). A MAG with **zero coding sequences** is not a real genome — cross-check it against its CheckM2 completeness.
  ```

### F-09 · S4 · Cosmetics: DRAM block unnamed, sentence-case subheads, un-glossed jargon
- **Where:** SOP_ASSEMBLY_NeSI.md: §13 DRAM block (before line 719) and Appendix B row 959; `###` subheads (46/54/65/295 …); first-use jargon (65 k-mer, 143/205 hugemem, 226 diamond, 454 diamond, 716/943 nn_seff)
- **Anchor:** `13b.dram`
- **Quote:**
  > | `13b.dram` | 200 GB | 20 | 24 h | Optional; validate on 1–2 MAGs first |
- **Defect:** ASSEMBLY-local polish the full review round will also sweep: (a) the §13 DRAM code block is the only reader-created block with no `scripts/…` intro line, though Appendix B (line 959) lists a `13b.dram` script; (b) most `###` subheads are bold sentence case ("From reads to a MAG") against `TUTORIAL_SPEC.md` §8's title-case rule; (c) `k-mer`, `hugemem`, `nn_seff`, `diamond` appear before any first-use gloss for a terminal-novice reader.
- **Failure:** Reader building from the Appendix B table looks for the `13b.dram` script, finds no heading to save it under; and a first-timer meets `hugemem`/`nn_seff` with no idea what to run or request — small frictions, no wrong result.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED
- **Evidence:** `grep -cF '13b.dram'` → 1 (Appendix B table only; no `scripts/13b.dram.sl` intro exists); subheads at 46/54/65/295 are sentence case vs spec §8 "Bold, title case"; first uses of k-mer/hugemem/nn_seff/diamond carry no gloss. Capstone C-22 / verdict C-22, re-confirmed present.
- **Fix:** (a) Insert `` `scripts/13b.dram.sl` (single job): `` immediately before the DRAM code fence. (b) Title-case the `###` subheads, leaving tool tokens (`metaSPAdes`, `eggNOG-mapper`) as-is. (c) One-clause glosses at first use — "k-mers (short sub-sequences of fixed length)", "`hugemem` (NeSI's large-memory partition)", "`nn_seff <jobid>` (NeSI's job-efficiency report — peak memory and CPU used)", "diamond (a fast protein aligner)".

## Verified against the cluster

Every claim I checked by running something, including the ones that **held**. Probes on
2026-08-04 (Mahuika login), `module purge; module load` (plain purge, sticky base kept),
fixtures in a scratch dir under `/nesi/nobackup`, cleaned up after.

| # | Claim in the SOP | Command / method | Outcome |
|---|---|---|---|
| 1 | §11 C-04 fix: GTDB-Tk summary is under `gtdbtk/classify/` | read `gtdbtk/config/output.py`, `files/classify_summary.py` | HELD — `DIR_CLASSIFY='classify'`; summary at `classify/{prefix}.bac120.summary.tsv`; the committed `glob("gtdbtk/classify/*.summary.tsv")` and the `gtdbtk/classify/*.classify.tree` note are correct |
| 2 | §11 parser reads `user_genome` + 7-rank `classification` | `classify_summary.py:79-80,128-130` | HELD — columns are `user_genome`, `classification`; classification is a 7-rank `d__…;s__…` string; the `d/p/c/o/f/g/s` parse is correct |
| 3 | §8 DAS_Tool `--write_bins` writes `.fa` to `${out}_DASTool_bins/` | read `DAS_Tool.R:607-613` + `src/extract_bins.sh` | HELD — `binDir=${out}_DASTool_bins`; `extract_bins.sh` writes `> $bin_id.fa`; §8 collector `for f in "$d"/*.fa` matches |
| 4 | §9 awk `$2>=50 && $3<10` = Completeness, Contamination | read `checkm2/predictQuality.py:257-268`; default `mode='auto'` (line 83) | HELD — auto mode columns are `Name, Completeness, Contamination, …`; `$2`/`$3` correct |
| 5 | §10 genomeInfo `$1".fa",$2,$3` header `genome,completeness,contamination` | read `drep/d_filter.py:34` and `_validate_genomeInfo` | HELD — dRep requires exactly `['completeness','contamination','genome']`; matches basenames of `-g mags/*.fa`; providing it does bypass CheckM (the "stops dRep running CheckM" claim holds) |
| 6 | §12 eggNOG reads `annotation/bakta/${MAG}/${MAG}.faa` | read `bakta/main.py:555` | HELD — bakta writes `{prefix}.faa`; also `{prefix}.tsv`, `{prefix}.gff3` |
| 7 | §4 "contigs land at `assemblies/${SAMPLE}/${SAMPLE}.contigs.fa`" | ran MEGAHIT on fixture reads, `--out-prefix S1 -o asm_S1` | HELD — wrote `asm_S1/S1.contigs.fa`; header `>k21_1 flag=1 multi=… len=…` (standard, consumed by name only downstream) |
| 8 | §14/§15 CoverM genome column headers → §15 reshape yields clean sample IDs | ran `coverm genome` on fixture; inspected header | HELD (reshape) — relabund header `Genome`, `S1_R1.fastq.gz Relative Abundance (%)`; `c.split(" ")[0].split("/")[-1].replace("_R1.fastq.gz","")` → `S1`; genome names `gA`/`gB` (no ext) match GTDB `user_genome`; `unmapped` row present and filtered by §15 |
| 9 | §14 module set runs `coverm genome` | ran with CoverM-only, +SAMtools/1.23.1, +SAMtools/1.19 | **FALSE as written** — needs minimap2 + samtools; 1.23.1 broken by `LegacySystemLibs/7`; only `SAMtools/1.19-GCC-12.3.0` works → **F-03** |
| 10 | §14 count command runs | ran `coverm genome --methods count --min-covered-fraction 0.10` | **FALSE** — CoverM rejects count with mcf>0, exit 1, no file; `--min-covered-fraction 0` works → **F-04** |
| 11 | §12 checkpoint `ls …/*.tsv \| wc -l` == NMAG | read `bakta/main.py:534,559,571` | **FALSE** — 3 `.tsv` per MAG → **F-08** |
| 12 | §12 bakta re-runs cleanly | read `bakta/config.py:350-351`, `bakta --help` | **FALSE** — aborts on existing dir without `--force` → **F-07** |
| 13 | §3.1 `NSAMP=wc -l` / `while read` robust to input format | fixture with no trailing newline | **FRAGILE** — drops last sample silently → **F-06** |
| 14 | 17 module strings + 3 `/opt/nesi/db` databases | (relied on capstone 00_FACTS + ASSEMBLY.md; spot re-loaded CoverM, DAS_Tool, CheckM2, drep, GTDB-Tk, bakta, MEGAHIT) | HELD — all load rc=0; consistent with 00_FACTS 17/17 HOLDS |

## Keep list

Load-bearing content the Stage-4 rewrite must not lose. Each `grep -F`s once in the file.

1. Depth-budget floor / scope — `≥5 Gb of clean sequence per sample`
2. Governance, host-in-contigs — `Treat a MAG carrying human contigs as controlled data`
3. metaQUAST silent-download warning — `Zero turns off reference downloading`
4. MEGAHIT memory headroom "why" — `caps MEGAHIT at 90% of the memory it detects`
5. GTDB-Tk OOM guard — `The unsplit bacterial tree needs more than 320 GB`
6. dRep silent-disagreement guard — `Providing` (…`--genomeInfo` is what stops dRep running CheckM itself)
7. CheckM2 expected-output caveat — `CheckM2 does not check rRNA/tRNA genes`
8. CoverM presence threshold "why" — `suppresses spurious low-level cross-mapping` (keep the reasoning; F-04 changes only the *count* command's value, not the relabund threshold)
9. Compositional handoff guard — `never round it or pass it through SRS`

## Gaps

What is missing rather than wrong.

- **SHOULD-ADD — §14 working-module note in Troubleshooting and Appendix B.** F-03 shows the single most surprising fact about this SOP (CoverM needs an *older* samtools than the rest of the pipeline). A one-row Troubleshooting entry and an Appendix B annotation would stop the next reader losing an afternoon. (~2 lines.)
- **SHOULD-ADD — inline `**How long:**` on §§8, 10, 12, 13, 14.** These heavy steps (dRep ~6 h, CoverM ~8 h, DRAM ~24 h) have runtimes in Appendix B but not in the step, so a reader cannot tell a slow job from a hung one without leaving the section. Capstone C-06; a tutorial-round item, noted here for completeness. (~5 short lines.)
- **CONSIDER — re-run guards on §10 dRep, §11 GTDB-Tk, §13 DRAM/eggNOG.** Like bakta (F-07), these single/array jobs write into fixed output dirs; dRep and DRAM in particular error or misbehave on a pre-existing work dir. A one-line note on how to safely re-run each would match the §4/§9 pattern. (~1 line each.)
- **CONSIDER — what to do when GTDB-Tk classifies zero archaea (or zero bacteria).** The §11 glob handles "bac120 and/or ar53", but the checkpoint does not tell the reader that a missing `ar53.summary.tsv` is normal for an all-bacterial cohort. (~1 line.)

## Cross-document flags

Claims about other files; I can see only ASSEMBLY, so these are for the seam owner.

- **F-01 / TUTORIAL_SPEC.md §1.** The audience contradiction is a seam: the spec withdraws the prior-pipeline assumption that ASSEMBLY:16 reinstates. Tutorial round owns the fix; flagged here as still-live.
- **F-06 / READBASED `samples.txt`.** Whether the trailing-newline drop can trigger depends on how `SOP_READBASED_NeSI.md` writes `samples.txt` (does it end with a newline?). The fix belongs in ASSEMBLY §3.1 regardless (it should not trust the input's format), but the seam owner should confirm READBASED's output.
- **F-03 / Appendix B + README tool table.** The §14 fix introduces `SAMtools/1.19-GCC-12.3.0` as a required module for CoverM; Appendix B currently lists only `CoverM/0.7.0-GCC-12.3.0` for that stage. Keep the two documents' tool tables in sync.
- **§15 handoff to `SOP_R_Analysis.md`.** The reshape emits `part2_relab.tsv` / `part2_counts.tsv` with taxa in rows, 7 rank columns, then sample columns — verified in shape against §15's own description. Whether R_Analysis opens on exactly that layout is a seam check the synthesis owns; the ASSEMBLY side is internally consistent.

## Rewrite plan

Ordered, dependency-aware. Items 1–3 are independent and can proceed in parallel; 4 is the appendix that depends on 1's phase structure being settled.

| # | Change | Closes | Size | Independent? |
|---|---|---|---|---|
| 1 | **Fix §14 CoverM** — module-load line (add minimap2 + SAMtools/1.19; note the krb5 reason), count command `--min-covered-fraction 0`, checkpoint wording; add Troubleshooting row + Appendix B annotation | F-03, F-04 | ~10 lines | Yes — highest priority; it is the only path that fails silently-then-hard on the SOP's final deliverable |
| 2 | **Normalise the assembly forks** — `ln -sf` for metaSPAdes, co-assembly QC+filter block in §5, canonical `$ASM` note | F-02 | ~12 lines | Yes |
| 3 | **§12 bakta** — add `--force`; fix the checkpoint to `*.gff3`/`$NMAG` | F-07, F-08 | ~3 lines | Yes |
| 4 | **§3.1 sample-count hardening** — trailing-newline guard + `grep -c .` | F-06 | ~2 lines | Yes |
| 5 | **Rewrite Appendix A** as three submit-phases; defer bakta array until `mags_derep.txt` exists | F-05 | ~15 lines | Depends on §12 (item 3) landing so the bakta line is final |
| 6 | **Audience prerequisite** — reframe line 16 as a redirect (tutorial round may own) | F-01 | ~3 lines | Yes |
| 7 | **Cosmetics sweep** — name the DRAM block, title-case `###` heads, gloss jargon | F-09 | ~10 edits | Yes; do last with the tutorial round |

## Self-check

```
findings=9 S1=0 S2=5 S3=3 S4=1
CLEAN
```

Hand-checked, the three the script cannot:
- [x] Ledger accounts for every heading in the file — all 51 `#`/`##`/`###` headings enumerated (including each §1/§4/§13/§15 subhead), verified against `awk '/^```/{f=!f} !f && /^#{1,6} /'`.
- [x] No proposed cut touches load-bearing content — no finding proposes a CUT; all verdicts are REWRITE/TIGHTEN/RELABEL/CLEAN, and the Keep list is preserved.
- [x] Every `NEEDS-BENCH-CHECK` is genuinely not verifiable here — there are none; every question the capstone deferred was settled by source-read or fixture (see *Verified against the cluster*). The only truly bench-gated items (full GTDB-Tk/Bakta/DRAM cohort timings) are not filed as findings.

CONTRACT: PASS
