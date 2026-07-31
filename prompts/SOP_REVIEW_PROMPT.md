# SOP Review — Run Prompt (v2, on-cluster)

**To run this:** open a fresh session **on NeSI**, `cd` into a clone of this
repository, check out the branch carrying it, and say

> Read `prompts/SOP_REVIEW_PROMPT.md` and run the review in it. It is
> self-contained.

A bare NeSI login shell has `module` and little else — `R` and `conda` sit
behind modules and are not on `PATH` until loaded. Stage 0 loads them itself, so
you do not need to pre-load anything. R and the Part 2 packages are installed on
this cluster, so every R question is answerable here. Note that this is true of
the *auditor*, not of the reader: Part 2 is documented to run on the student's
own machine, and that is deliberate.

Everything below is addressed to the assistant that receives that instruction.
It is self-contained: no other file needs to be read first.

**What is different in v2, and why.** Version 1 ran in a sandbox with no cluster
and no R. Every claim about the world — does this module exist, does this flag
exist, what does this function actually return — had to be filed as
`NEEDS-BENCH-CHECK` and deferred. Sixteen were, and they blocked four items of
the work plan. This version runs where those questions can be answered, so it
answers them **first**, in Stage 0, and hands the answers to every reviewer as
fact. The other changes are listed at the end under *Changelog*; read that
section if you ran v1 and want to know what moved.

---

# ORCHESTRATOR INSTRUCTIONS

You are running an adversarial review of five documents. You will not review
them yourself and you will not edit them. You launch agents and check their
work.

**The repository has been through one round of this already.** The previous
round's five reports are archived in **`reviews/v1/`**, its work plan in
`reviews/v1/00_SYNTHESIS.md`; the four SOPs were then rewritten against them.
This round writes to `reviews/` and must not touch `reviews/v1/`.

Treat the previous round as **a hypothesis list, not as truth**. Three things
follow:

1. A fix that was applied may be wrong, or may have broken something else. A
   document that was edited in fifteen places has fifteen new chances to be
   wrong. Verify the fixes; do not assume them.
2. A finding v1 raised and v1 closed is not a result if you re-report it. A
   finding v1 raised and the rewrite got *wrong* is one of the most valuable
   things you can find.
3. v1 could not check anything about the world. Some of what it asserted
   confidently may simply be false. Stage 0 exists to find that out.

**Stage 0 — one agent, alone, before anything else.** It receives **AGENT
PROMPT 0**. It probes this cluster and this R installation and writes
`reviews/00_ENVIRONMENT.md`: a table of facts with the command that produced
each one. Nothing else starts until it has returned, because every later agent
reads its output.

**Stage 1 — four agents, launched together in one message so they run
concurrently.** One per SOP:

| Agent | `{{FILE}}` | Writes to |
| --- | --- | --- |
| 1 | `SOP_EMU_NeSI.md` | `reviews/EMU.review.md` |
| 2 | `SOP_CONCOMPRA_NeSI.md` | `reviews/CONCOMPRA.review.md` |
| 3 | `SOP_READBASED_NeSI.md` | `reviews/READBASED.review.md` |
| 4 | `SOP_R_Analysis.md` | `reviews/R_ANALYSIS.review.md` |

Each one receives, verbatim: the **COMMON BRIEF** and **AGENT PROMPT A** with
`{{FILE}}` and `{{OUTPUT}}` filled in. Give them the full text. Do not summarise
it, do not paraphrase it, and do not tell them to go and read this file — an
agent that reads this file will read the other agents' prompts too and drift off
its own document.

**Stage 2 — one agent, after all four have returned.** It receives the **COMMON
BRIEF** and **AGENT PROMPT B**. It reads all five source files itself, the
environment report, and all four reports from `reviews/`, and writes
`reviews/00_SYNTHESIS.md`.

**Stage 3 — you.** Run the acceptance checks at the end of this file. They are
scripted, not read by eye; run the scripts. Send back any report that fails.
Then commit `reviews/` and report to the user: findings at each severity, the
blocking defects, how many v1 findings were falsified by Stage 0, and the first
three items of the work plan.

**Stage 4 — the rewrite. Do not begin it without explicit authorisation.** When
the user gives it, work the plan in its stated order, commit per work item, and
run the keep-list regression in *Acceptance checks* before you report done.

Rules that bind you as well as the agents: **nothing outside `reviews/` gets
edited during Stages 0–3.** The five source documents are read-only until the
user approves the plan.

---

# COMMON BRIEF

> Give this to all six agents, verbatim, ahead of their individual prompt.

## The repository

Taylor Lab bioinformatic SOPs: four Markdown standard operating procedures plus
a README index. Microbial community analysis on NeSI (New Zealand eScience
Infrastructure, a SLURM HPC cluster) and in R.

| File | What it is |
| --- | --- |
| `SOP_EMU_NeSI.md` | **Part 1.** Nanopore full-length 16S: NeSI onboarding (bash, modules, SLURM), read QC, filtering, Emu profiling, count tables. Audience: a student or new lab member with **no** command-line experience; it starts at `pwd`. The only document that teaches the cluster itself. |
| `SOP_CONCOMPRA_NeSI.md` | **Runs after Part 1**, same Nanopore data: reference-free consensus OTUs alongside Emu's assignments. Takes Part 1's filtered reads as input. |
| `SOP_READBASED_NeSI.md` | **Illumina shotgun, read-based.** Explicitly assumes one prior pipeline; does not re-teach bash or SLURM. |
| `SOP_R_Analysis.md` | **Part 2.** Count tables to results in R: phyloseq, decontam, SRS normalisation, diversity, PERMANOVA, differential abundance, indicator species. Platform-agnostic; serves all three upstream SOPs. |
| `README.md` | Index, routing table, conventions, tool versions, contributing rules. |

Check the current line counts yourself. Do not trust a length quoted anywhere,
including here.

## What this review is for

These are tutorials. A reader with the stated experience level should be able to
work top to bottom and get correct results without needing a second source.

## Who the reader is

Not you. Not an experienced bioinformatician. For the amplicon SOPs: a graduate
student who has never opened a terminal. For the read-based SOP: someone who has
finished one pipeline, once. They are running real data, under time pressure,
often alone, and **they cannot tell a wrong answer from a right one.** That is
why *looks plausible, is wrong* is the worst failure mode available in this
repository, and why it outranks everything else in your severity judgements.

---

## You are on the cluster. Use it.

This is the defining difference from the previous round. You can run things.

**Your environment is not the reader's environment.** You have a NeSI shell, an
R module and every package loaded because you are auditing these documents. The
reader of Part 2 is on their own laptop, by deliberate lab policy, and the
reader of Part 1 has never opened a terminal. Never let a convenience of your
session become a recommendation:

- Do not propose moving Part 2 onto the cluster because R happens to be there.
- Do not mark an install step redundant because it is already satisfied for you.
- Do not treat a module that loads for you as proof it loads for a new student
  on a different allocation — but do record the version you saw.
- Do not simplify a path, quota or setup step because your account has access
  the reader may not.

A finding that improves the document *for you* and degrades it for a student who
has never opened a terminal is a defect in your report, and it is the specific
way an on-cluster reviewer gets this wrong.

**Before you assert that something is wrong with the world, check.** Before you
assert that something is *right*, check that too — the more dangerous error is
reading a plausible command and moving on. `module spider`, `--help`, `args()`,
`tar -tf`, `head -1` and a three-line fixture will settle most questions in
seconds.

### Build a fixture and run it

The highest-value technique available to you, and the one most often skipped.
When a command's behaviour is the question, construct the smallest input that
distinguishes right from wrong and run both versions. From the previous round,
a real example, start to finish in under a minute:

```bash
mkdir -p t/bc01 && cd t
printf '@r1\nACGT\n+\n!!!!\n@r2\nACGT\n+\n@@@@\n' > bc01/a.fastq
grep -c "^@" bc01/a.fastq      # 3  <- wrong: the @@@@ quality line counted as a read
echo $(( $(wc -l < bc01/a.fastq) / 4 ))   # 2  <- right
```

That converted an argument about Phred encoding into a demonstration. A finding
carrying a reproduction like this cannot be argued with, and it takes less time
than writing the paragraph that argues for it.

Work in a scratch directory, never in the repository, and never against real
sequencing data. Clean up after yourself.

### What you still cannot check

Some things remain out of reach even here: whether a 48-hour run completes,
what real data does, how long an `ancombc2` fit takes on a full dataset,
whether a database download succeeds over a link you should not saturate. Mark
those `NOT-VERIFIABLE-HERE` and name what would settle them and roughly what it
would cost. Do not burn an hour of cluster time to close an S4.

### Three confidence levels, and the rule for using them

| Level | Means | Requires |
| --- | --- | --- |
| `CONFIRMED` | Provable from the text in front of you, or demonstrated by a command you ran | The contradiction, or the command and its output |
| `VERIFIED` | You ran a probe against this cluster or this R install and it settled the question | The exact command and its exact output, quoted |
| `NOT-VERIFIABLE-HERE` | Needs real data, a long run, or something you should not do | The single check that would settle it, and its rough cost |

**There is no fourth level, and "I believe this is wrong" is not a finding.** If
you can check it, check it. An unchecked claim about the world, in a session
that could have checked it, is worse than not raising it at all.

---

## Straightforwardness, not brevity

The target is **straightforward**, not **short**. A tutorial that is shorter but
leaves the reader guessing has got worse, not better. A five-line explanation
that lands the first time beats a two-line one that does not.

What you are attacking is *incidental* complexity — complexity in how something
is presented rather than in what it is:

- three commands where one would do
- an idea explained twice, in different words, in different places
- a sentence that restates the code beneath it
- a hedge on a hedge, a caveat on a caveat
- an optional side-path given the same visual weight as the main path
- a branching conditional in the narrative where a default plus a footnote would
  carry the same information
- the same object called two different things
- a paragraph that has to be read twice to be parsed
- reference material sitting in the middle of a walkthrough
- a decision presented with no default, forcing the reader to stop and research
  something before they can continue

None of that is about length.

### Load-bearing content

The following is load-bearing. Removing it is a **regression**, and proposing to
remove it is itself a defect in your report.

1. **Justification for a threshold, parameter, cutoff or tool choice** — the
   "why this number" paragraphs. Repository policy, from the README: *"If you
   are documenting a threshold or a tool choice, write down the reasoning, not
   just the value."* That reasoning is the main value of these documents.
2. **Warnings about silent failure** — anywhere the text says a mistake produces
   no error message, wrong-but-plausible output, or a number that looks fine.
3. **Expected output** — what the reader should see when a step works, and how
   to tell when it did not.
4. **Primary literature citations** backing a methodological choice.
5. **Scope limits** — what a workflow does not cover, and who it is not for.
6. **Governance, ethics and human-data handling** content.
7. Anything explaining a concept the stated audience genuinely lacks.

Where both apply — a why-this-number paragraph that genuinely rambles — the
verdict is **REWRITE TIGHTER** and you supply the tighter version, carrying the
whole reason across. Never CUT.

---

## Consistency

Inconsistency is not a style problem in a tutorial. A reader who cannot tell
whether two names refer to the same thing stops being able to follow the
document; a reader who follows a drifted duplicate of an instruction gets a
wrong result. **Grade a consistency finding as a correctness finding whenever
the drift could change what the reader does.**

### Within a document

| Check | What to verify |
| --- | --- |
| **Naming** | Is every file, variable, directory, object, sample ID, script and tool called exactly one thing throughout? List every alias. Capitalisation and punctuation count: `ps_raw` vs `ps.raw`, `Site` vs `site`. |
| **Continuity** | For every artefact written by one step and read by a later one, do the name, path and extension match at both ends? Trace each end to end. This is where silent breakage lives. |
| **Placeholders** | One spelling per slot, matching the README's convention. |
| **Numbers** | A threshold, depth, memory figure, walltime, thread count or version string stated more than once — do the statements agree with each other, and with the code blocks that use them? |
| **Structure** | Heading levels, section numbering, and whether the numbering matches the roadmap block and the script filenames. One `#`-level title per document. |
| **Instructions** | The same instruction given in two places — have the copies drifted? Drift is a correctness finding. |
| **Format** | Code-fence language tags, comment density and style inside code blocks, table layout, callout style, how commands versus output are shown. |
| **Register** | Person and tense, UK vs US spelling, terminology for the same concept, and whether the level of assumed knowledge shifts between sections. |
| **Depth** | Do comparable steps get comparable treatment, or does one step get four paragraphs while an equally risky one gets a bare command? |

### Between documents *(Agent B only)*

Everything above, applied across all five files, plus:

- **References** — does every cross-document pointer name a file that exists,
  and a section that exists under that number?
- **Contradiction** — where two documents cover the same ground, do they agree?
- **Boundaries** — is each document's stated assumption about what the reader
  already knows actually honoured by the documents upstream of it?
- **Handoffs** — does the artefact one document produces match what the next one
  opens on?
- **README** — does the index describe the SOPs as they now are?

---

## Evidence rules

1. **Every finding quotes the text it is about, verbatim, with a line number
   and a search string.** No quote, no finding. See *Anchors* below for why the
   search string is not optional.
2. **Check what you can check.** See *You are on the cluster* above. The
   division between `CONFIRMED`, `VERIFIED` and `NOT-VERIFIABLE-HERE` is
   binding, and `NOT-VERIFIABLE-HERE` on something you could have run in ten
   seconds is a defect in your report.
3. Internal contradiction is your strongest evidence type and costs nothing to
   find. Hunt for it deliberately.
4. Before reporting anything absent, search the whole document for it. Most
   false "missing X" findings are X present under a different heading.
5. Do not invent severity to fill a tier. **An empty S1 list is a legitimate
   result and will be believed.** A padded one destroys the report's usefulness.
6. If you disagree with a documented choice on scientific grounds, raise it as
   an explicit `CHALLENGE` with reasoning — do not silently rewrite it. The lab
   decides; you argue.
7. **Read the whole file before writing a single finding.** Findings written
   while still reading are the ones answered three sections later.
8. Read files in a way that gives you real line numbers, and quote them
   accurately.

### Anchors

The previous round anchored findings to `file:line` alone. Every fix applied
shifted the line numbers under every later finding, and the rewrite spent real
time re-locating them. So:

**Every finding carries an `**Anchor:**` field: a short, unique, literal string
from the target text that `grep -F` will find exactly once.** Line numbers go
stale the moment anyone edits; anchors do not. Check uniqueness before you write
it down:

```bash
grep -cF 'your anchor string' SOP_EMU_NeSI.md   # must print 1
```

---

## Output contract

Binding. A report that violates this is re-run, not worked from.

### The finding block

```
### F-07 · S2 · Filtered reads written as .fq, read back as .fastq
- **Where:** SOP_EMU_NeSI.md:412-418, § 3 Step 3
- **Anchor:** `chopper -q 10 -l 1000 < raw/$SAMPLE.fastq`
- **Quote:**
  > chopper -q 10 -l 1000 < raw/$SAMPLE.fastq > filtered/$SAMPLE.fq
- **Defect:** One sentence. What is wrong, stated flatly.
- **Failure:** Reader does X → gets Y → believes Z. One concrete path, no
  hedging.
- **Type:** CORRECTNESS | CONSISTENCY | CLARITY | STRUCTURE | GAP | CHALLENGE
- **Confidence:** CONFIRMED | VERIFIED | NOT-VERIFIABLE-HERE
- **Evidence:** The contradiction, or the command you ran and its output, or
  the check that would settle it and its cost. One of the three, always.
- **Fix:** Paste-ready replacement text.
```

**All nine fields, in that order, on every finding, whatever its severity.** In
the previous round two of five reports omitted fields on their S3 and S4 blocks
and still declared the contract satisfied, because the self-check was done by
impression. Yours will be scanned mechanically. The command is in *Self-check*.

**Field rules**

- **ID** — `F-01` upward, unique within the report, never reused.
- **Severity**
  - `S1` — wrong result, data loss, or a governance breach. **Any path that
    yields wrong-but-plausible output is S1**, however small the edit that fixes
    it.
  - `S2` — blocks the reader. They stop, and the document does not unblock them.
  - `S3` — costs real time or confidence, but recoverable.
  - `S4` — polish. **Cap: 15.** Beyond that, merge into one omnibus entry.
- **Summary** — the heading text after the severity. **90 characters or fewer**,
  stating the *defect*, not the topic. "Filtered reads written as .fq, read back
  as .fastq", not "filtering section". (v1 set a ten-word cap and 42% of
  findings broke it while stating the defect perfectly well. Across those 158
  summaries the median was 65 characters and the 90th percentile 85, so 90 binds
  on the genuine outliers — the worst was 121 — without punishing good output.)
- **Anchor** — unique `grep -F` string, verified to match exactly once.
- **Order** — S1 first, then S2, S3, S4. Within a tier, document order.
- **Quote** — verbatim, blockquoted. Elide with `…` mid-line only, never across
  the part carrying the defect.
- **Failure** — if you cannot write this line concretely, the finding is not
  real. Delete it. This rule removes more bad findings than any other.
- **Evidence** — for `VERIFIED`, the command and its actual output, quoted, not
  described. "I ran `module spider Emu` and it exists" is not evidence; the
  output is.
- **Fix** — for S1 and S2, the actual replacement text, ready to paste, not a
  description of a fix. For S3 and S4 a one-line instruction is enough. Every
  fix must be independently applicable: no "see F-03". If two findings share one
  fix, they are one finding.

### Self-check

Run this, paste its output at the end of your report, and then write
`CONTRACT: PASS` or list what you could not satisfy. Do not eyeball it.

```bash
python3 - <<'PY'
import re, subprocess, sys
REPORT = "reviews/YOUR_REPORT.md"      # <- set this
SOURCE = "SOP_YOUR_FILE.md"            # <- set this; Agent B: set to None
F = ["Where","Anchor","Quote","Defect","Failure","Type","Confidence","Evidence","Fix"]
txt = open(REPORT).read()
blocks = [b for b in re.split(r'\n(?=### F-)', txt) if b.startswith('### F-')]
bad = []
for b in blocks:
    head = b.split('\n')[0]
    m = re.match(r'### (F-\d+) · (S\d) · (.+)', head)
    if not m: bad.append((head[:40], 'malformed heading')); continue
    fid, sev, summ = m.groups()
    present = [k for k in F if f'- **{k}:**' in b]
    if missing := [k for k in F if k not in present]:
        bad.append((fid, f'missing {missing}'))
    if [k for _, k in sorted((b.index(f'- **{k}:**'), k) for k in present)] != present:
        bad.append((fid, 'fields out of contract order'))
    if len(summ) > 90: bad.append((fid, f"summary {len(summ)} chars > 90"))
    if re.search(r'\bsee F-\d+', b.split('- **Fix:**')[-1]):
        bad.append((fid, 'Fix cross-references another finding'))
    if a := re.search(r'- \*\*Anchor:\*\* *`?([^`\n]+)`?', b):
        if SOURCE:
            n = subprocess.run(['grep','-cF',a.group(1).strip(),SOURCE],
                               capture_output=True,text=True).stdout.strip() or '0'
            if n != '1': bad.append((fid, f'anchor matches {n}x, must be 1'))
sev = [re.match(r'### F-\d+ · (S\d)', b).group(1) for b in blocks
       if re.match(r'### F-\d+ · (S\d)', b)]
rank = {'S1':1,'S2':2,'S3':3,'S4':4}
print(f"findings={len(blocks)} " + " ".join(f"{s}={sev.count(s)}" for s in rank))
if [rank[s] for s in sev] != sorted(rank[s] for s in sev): print("!! severity order wrong")
if sev.count('S4') > 15: print(f"!! S4 cap exceeded: {sev.count('S4')}")
for fid, why in bad: print(f"!! {fid}: {why}")
print("CLEAN" if not bad else f"{len(bad)} contract violations")
PY
```

Then confirm by hand the three it cannot check:

- [ ] Ledger accounts for every heading in the file *(Agent A only)*
- [ ] No proposed cut touches load-bearing content
- [ ] Every `NOT-VERIFIABLE-HERE` is genuinely not verifiable in this session

### Calibration

A real defect from the previous round, formatted as the contract requires. It
demonstrates the shape and the evidence standard. **It is already fixed, so
re-finding it is not a result** — but checking that the fix is still correct is.

```
### F-01 · S1 · Depth budget multiplies by host fraction instead of dividing
- **Where:** SOP_READBASED_NeSI.md:69, § 1 Depth
- **Anchor:** `multiply your target by the expected host fraction`
- **Quote:**
  > At a high-host site most of your data is human, so multiply your target by
  > the expected host fraction (Section 7 gives typical values) when deciding
  > what to order.
- **Defect:** The arithmetic is inverted. To end with a target number of clean
  pairs you divide by `(1 − host fraction)`; multiplying reduces the order, and
  reduces it most at exactly the sites needing the largest increase.
- **Failure:** A reader sampling saliva looks up "Oral, saliva, vaginal | >90%"
  in the Section 7 table, reads this line, and orders 5,000,000 × 0.9 = 4.5
  million read pairs instead of the ~59 million required. Every sample then
  fails the depth gate, and Section 1's own opening — "Three things cannot be
  fixed after sequencing" — means the run is unrecoverable.
- **Type:** CORRECTNESS
- **Confidence:** CONFIRMED
- **Evidence:** Contradicts the document's own host-fraction table (§7) and its
  own clean-depth targets (§1); no reading of "multiply by the host fraction"
  produces a larger number than the target.
- **Fix:** [full replacement text, omitted here for length]
```

---

# AGENT PROMPT 0 — environment probe

> One agent, before all others. Prepend the COMMON BRIEF.

You are establishing what is actually true of this cluster and this R
installation, so that the four reviewers who follow can treat those facts as
settled instead of guessing. You are **not** reviewing anything. You do not
open the review reports, you do not judge the documents, and you write no
findings.

Write `reviews/00_ENVIRONMENT.md` and return a short summary.

## First: establish what you actually have

A bare login shell has `module` and nothing else. `R` and `conda` are **not** on
`PATH` until you load them, and an agent that runs `R --version`, gets
`command not found`, and concludes "R is unavailable on this cluster" has
recorded a false fact that four reviewers will then treat as settled. Do this
before anything else, and record the result at the top of your report:

```bash
which module R conda python3 2>&1        # what is on PATH cold
module -t spider R 2>&1 | head -20       # what R versions exist
module -t spider Miniforge3 2>&1 | head  # conda comes from a module too
```

Then load the newest R and the conda module and re-check. If `module spider R`
returns nothing, R genuinely is not on this cluster — say so plainly, and mark
every R question `UNREACHABLE-HERE (needs local R)` rather than guessing at the
answer.

**R and the Part 2 packages are available on this cluster**, so the R questions
are answerable and you are expected to answer them rather than defer them. This
is a convenience of the audit, not a statement about where the analysis belongs
— see *Your environment is not the reader's environment* in the brief. Confirm
the package set first, with the R module loaded:

```r
for (p in c("phyloseq","decontam","SRS","vegan","pairwiseAdonis","ANCOMBC",
            "Maaslin2","indicspecies","microbiome","mia","ggpubr")) {
  cat(sprintf("%-16s %s\n", p,
      if (requireNamespace(p, quietly = TRUE))
          as.character(packageVersion(p)) else "NOT INSTALLED"))
}
```

Report that table verbatim, and record the module string you loaded to get it.
If a package turns out to be missing, list its questions under **Unreachable**
with the one or two lines that would settle each in an R session that has it.
Expect that to be empty or nearly so; a long list means you have not loaded the
right R module.

**Do not conclude anything about the reader from this.** `README.md` tells the
reader *"R on your own machine. Part 2 runs locally, not on NeSI."* That is
deliberate lab policy and it is correct. You have R on the cluster because you
are an auditor with a shell, not because the audience does. Record the R module
you loaded as *your instrument*, under a heading that says so, and do not file
it as evidence that the documentation is wrong.

## How to decide what to probe

Do not work from a list someone else wrote, including the one below. Extract
the claims mechanically from the documents themselves:

```bash
grep -ohE 'module load [A-Za-z0-9._/-]+' *.md | sort -u          # module strings
grep -ohE '\b[a-z_]+\.(sh|sl|py|R)\b' *.md | sort -u             # script names
grep -ohE '^\s*[a-z_]+::[A-Za-z_.]+\(' *.md | sort -u            # R package calls
grep -ohE '\-\-[a-z][a-z0-9-]+' *.md | sort -u                   # CLI flags
```

Then probe each one. Prioritise: anything whose failure is silent, anything on
the main path, anything a reader hits in the first hour.

## What to record

For every fact, three things: the claim as the documents state it, the command
you ran, and its actual output. Verdict one of `HOLDS`, `FALSE`, `DRIFTED`
(exists, different version or spelling) or `UNREACHABLE` (could not check, with
the reason). Where the reason is "this tool only exists off-cluster", say so in
those words — it is a different situation from a probe that failed.

```
| Claim | Source | Command | Output | Verdict |
```

## Known open questions

The previous round deferred these sixteen. Settle them, and say so explicitly
for each — a reviewer will be relying on your answer:

`--chdir` log-path behaviour · `nn_storage_quota` vs `nn_check_quota` ·
CONCOMPRA's `otu_table.csv` header form · `emu abundance --help` for
`--type lr:hq` · `tar -tf silva.tar` structure · `pip install osfclient` under
the Emu module · `args(pairwiseAdonis::pairwise.adonis2)` — is `p.adjust.m`
real or swallowed by `...` · `symnum()` argument length · `?adonis2` default for
`by` · `args(SRS::SRS.shiny.app)` · `ancombc2` runtime · FastTree `-boot`
semantics · `CONCOMPRA.yml`'s minimap2 pin · MetaPhlAn merged-table first line ·
pandas in the MetaPhlAn module · MetaPhlAn `bowtie2out` overwrite behaviour.

`args(pairwiseAdonis::pairwise.adonis2)` is the one to run first: an S1 in Part
2 turns on it, and it takes one line in R.

## Rules

- **Read-only.** Do not install, do not download a database, do not submit a
  batch job, do not touch anyone's data. Probing is `--help`, `spider`, `args()`,
  `head`, `tar -t`, and fixtures you made yourself in a scratch directory.
- **Quote real output.** Never paraphrase what a command printed, and never
  write down what you expect it to print.
- **Record failures as facts.** "`module spider Emu` returns nothing on this
  cluster" is a first-class result and possibly the most important line in your
  report.
- Where a version has drifted, give both: what the SOP says, what is installed.

## Report skeleton

```
## Environment
## What is on PATH, and what had to be loaded
## Modules
## Command-line tools and flags
## R packages and function signatures
## Databases and filesystem
## Answers to the sixteen open questions
## Unreachable
```

Open with one paragraph: what this cluster is, what date you probed it, and the
single fact most likely to surprise someone who trusted the SOPs.

---

# AGENT PROMPT A — per-document review

> Four agents, one each. Fill `{{FILE}}` and `{{OUTPUT}}`. Prepend the COMMON
> BRIEF.

Review `{{FILE}}` adversarially, in full, in order. Write your report to
`{{OUTPUT}}` and return only a short summary: finding counts by severity, the
S1 titles, how many claims you settled by running something, and your contract
self-check output.

**Read `{{FILE}}`, `README.md` where you need to check a stated convention, and
`reviews/00_ENVIRONMENT.md`, which is fact.** Do not read the other SOPs and do
not read any other report, this round's or the previous round's. You may read
`reviews/v1/` for *your own* document only, and only after you have finished
your own four passes and written your findings — then note which of its
findings the rewrite got wrong, which it left open, and which you disagree
with. Reading it first would bias you toward confirming it rather than
reviewing the document in front of you. A later agent owns everything between files, and a
reviewer who wanders into neighbouring documents covers its own worse.

You are not a proofreader and not a cheerleader. You are the person who has to
explain to the lab why a student's results were wrong. Assume the document
contains defects, because it does. Find them, prove them, and hand back wording
good enough to paste.

Read it four times, with a different question each time.

### Pass 1 — Correctness and safety

*Can this produce a wrong result that looks right?*

- Commands whose flags, paths, filenames or variables contradict the surrounding
  text or an earlier section. **Check the flags against the environment report.**
- A file written in one step under one name and read in a later step under
  another.
- Statistical or methodological errors: the wrong object used for a test, a
  normalisation applied at the wrong point, a test whose assumptions the
  described design violates, multiple-testing handling, compositional data
  treated as counts or the reverse.
- Steps that silently do the wrong thing on a plausible input — an empty file, a
  single sample, an unusual filename, a failed upstream step. **Build the
  plausible input and run the step on it.**
- Destructive operations with no warning: overwrite, `rm`, in-place edits.
- Ordering hazards: a step that must precede another, with nothing saying so.
- Resource claims contradicting other numbers in the same document.
- **Anything a reader could do in good faith that produces a plausible wrong
  number with no error message.** Weight these highest.

### Pass 2 — Tutorial quality

*Can the stated reader follow this, alone, first time?*

- A command with no statement of what success looks like.
- A step that can fail, with no failure branch and no way to tell it failed.
- Vocabulary, tool, file format or concept used before it is introduced.
- Explanation assuming more than the stated audience has — or the opposite,
  re-teaching what the document says it assumes. Both are defects.
- Decision points offering options but no basis for choosing. Every fork needs a
  default and a reason.
- Placeholders whose substitution is not obvious.
- Prose whose meaning changes on the second read: ambiguous antecedents, "it"
  or "this" with no clear referent, ambiguous ordering.
- Missing runtime or scale where the reader cannot tell whether to wait or
  intervene.

### Pass 3 — Structure and economy

*Is the shape right, and is any of it incidental?*

- Heading hierarchy: skipped levels, duplicate titles, numbering that does not
  match the roadmap or the script filenames.
- Content in the wrong place — reference material mid-walkthrough, setup buried
  after the step that needs it.
- Sections that should be a table; tables that should be prose.
- Everything in the incidental-complexity list from the brief — checked against
  the load-bearing list before you propose removing anything.

### Pass 4 — Internal consistency

Apply the *within a document* table from the brief, in order, mechanically.
Build the alias list and the artefact chain explicitly rather than by
impression: this pass exists precisely because impressions miss these.

For every artefact the document creates, write the chain out — *created at line
N as `<name>`, consumed at line M as `<name>`*. Any mismatch is a finding, and
it is S1 if the mismatch would fail silently.

### Report skeleton

Exactly these sections, in this order, nothing before or after.

```
## Document: {{FILE}}
## Section ledger
## Findings
## Verified against the cluster
## Keep list
## Gaps
## Cross-document flags
## Rewrite plan
```

- **Document** — one paragraph: what the document is trying to be, how close it
  is, and the single change that would most improve it. No preamble.
- **Section ledger** — every heading in the file, in order. A section with no
  findings is a real and expected result. Verdicts: `CLEAN` `TIGHTEN` `REWRITE`
  `RESTRUCTURE` `EXPAND` `CUT` `SPLIT` `MERGE`.

  | § | Heading | Lines | Verdict | Findings |
  |---|---|---|---|---|
  | 3.2 | Trimming | 245-289 | REWRITE | F-04, F-05 |

- **Findings** — contract blocks.
- **Verified against the cluster** — every claim in this document you checked by
  running something, including the ones that **held**. A command that turned out
  to be correct is a result: it tells the next reader not to re-check it. One
  line each: claim, command, outcome.
- **Keep list** — content that must survive the rewrite, and why the rewrite
  would be tempted to lose it. Anchored, fewer than ten entries.
- **Gaps** — what is missing rather than wrong. Ask it directly: *if I ran this
  document end to end and something went wrong, what would I not know?* Mark
  `SHOULD-ADD` or `CONSIDER`, and estimate the length of the addition.
- **Cross-document flags** — every claim about another SOP, the README, or a
  shared convention. Do not resolve them; you can only see one file.
- **Rewrite plan** — ordered, dependency-aware. Each item: what changes, which
  findings it closes, rough size, and whether it can proceed independently.

End with the self-check output.

---

# AGENT PROMPT B — seams and synthesis

> One agent, after all four A reports exist. Prepend the COMMON BRIEF.

You are the only agent that sees the whole repository. **Read all five source
files yourself** — the four SOPs and `README.md` — then `reviews/00_ENVIRONMENT.md`,
then this round's four reports in `reviews/`. The previous round's are in
`reviews/v1/` if you need to check whether a defect is a regression.

The seam job cannot be done from the reports alone; the four reviewers were each confined to one file, so every defect living
*between* files is yours and yours only. In the previous round the seam review
produced the second-highest-ranked defect in the repository, and no
single-file reviewer could have seen it.

Write `reviews/00_SYNTHESIS.md`. Return a short summary only.

## Job 1 — Seam review

Work through these mechanically and exhaustively, not by impression.

**1. Reference integrity.** Extract every reference to another document —
filenames, "Part 1", "Part 2", "see Section N of X", every URL. For each: does
the target file exist? Does the named section exist in it? Is the number still
right? Repository policy is that a bare section number always means the current
document and a cross-document reference always names the file — verify that
holds, in both directions. **Check the URLs resolve** — you have network access
for this in a way the previous round did not.

**2. Consistency across the set.** Apply the *within a document* table across
all five files, then the *between documents* list. Tabulate placeholder
spellings across every file and report any that denote the same slot under
different names. Check every SOP against every convention the README declares.

**3. Contradiction sweep.** Where two documents cover the same ground — cluster
basics, storage layout, job headers, database setup, QC thresholds, the handoff
into R — do they agree? Quote both sides of every disagreement. This is the
highest-value defect class available to you: the reader has no way to know which
document to trust.

**4. README fidelity.** The README makes specific factual claims about each
SOP's contents, tool versions, storage sizes, audience, and what is and is not
covered. Check each against the SOP it describes, and against the environment
report. Does the routing table send a reader with given data to the right
document, and is every document reachable from it?

**5. Handoff continuity.** Trace each upstream path into `SOP_R_Analysis.md`:
EMU → R, CONCOMPRA → R, READBASED → R. For each, does the artefact produced
upstream — exact filename, exact shape, exact column layout, counts versus
relative abundance — match what Part 2 opens on? **Where a conversion block
exists, run it on a small fixture and confirm its output is the shape Part 2
describes.** A handoff needing an undocumented reshaping step is a broken
handoff.

**6. Duplication and ownership.** Content appearing in more than one SOP. For
each: should one document own it and the others link, or is local repetition
justified because the reader is unlikely to have the other document open?
Recommend an owner.

**7. Voice and shape.** Where the four documents differ in structure or register
in ways that make the set read as four documents rather than one manual.
Recommend one target shape and list what each document needs to reach it.

## Job 2 — Synthesis

1. **De-duplicate.** The same defect will appear in several reports under
   different framings. Merge into one entry, keeping every anchor.
2. **Re-rank globally.** Severity was assigned within each document. Re-rank
   across all five files: an S1 in Part 2, which every reader reaches, outranks
   an S1 in a document nobody has run yet. Rank an irreversible defect — one
   that cannot be corrected after the fact — above everything. Say so where it
   changes the order.
3. **Resolve conflicts.** Where two reviewers disagree, or a reviewer proposes
   something the conventions forbid, decide and show the reasoning. Do not
   report both and leave it open.
4. **Audit every proposed cut** against the load-bearing list. Any proposal that
   removes load-bearing content is struck, with a note, and downgraded to
   REWRITE TIGHTER where the underlying complaint was fair. **Report how many
   you struck.**
5. **Reconcile against the environment report.** Any finding whose confidence
   rests on a claim Stage 0 marked `FALSE` is struck, and any *fix* that assumes
   a module string or flag Stage 0 could not find is rewritten. **Report the
   count** — it is the measure of how much the previous round got wrong about
   the world.
6. **Sequence.** Order the work so shared conventions land before the
   per-document rewrites that depend on them, and so no two work items collide
   in the same lines of the same file. Mark what can run in parallel.

## Report skeleton

```
## State of the repository
## Blocking defects
## Seam findings
## Reference integrity table
## Consistency matrix
## Ownership map
## Environment reconciliation
## Work plan
## Convention decisions
## Consolidated keep list
## Deferred
## Open questions for the lab
```

- **State of the repository** — half a page, for someone deciding how much time
  to spend. What is strong, what is weak, what to do first.
- **Blocking defects** — every S1 across all five files, globally ranked, each
  with its anchor and its one-line failure path. If the list is empty, say so
  plainly and mean it.
- **Seam findings** — your own, in contract format. `**Where:**` names both
  files for any cross-document defect; quote both sides of any contradiction.
- **Reference integrity table** — `| Source | Anchor | Points at | Exists? |
  Correct? | Action |`
- **Consistency matrix** — `| Item | EMU | CONCOMPRA | READBASED | R_Analysis |
  README | Target |`. The Target column is the decision, not a description of
  the variance.
- **Ownership map** — for each duplicated topic: which document owns it, which
  link to it, what each must change.
- **Environment reconciliation** — what Stage 0 falsified, what it confirmed,
  and every finding or fix you changed as a result.
- **Work plan** — `| # | Item | Files | Closes | Size | Depends on |`. Sequenced,
  parallelism marked.
- **Convention decisions** — stated once, pasteable straight into the README.
- **Consolidated keep list** — merged across all reports. This is the regression
  test for the rewrite: if the rewritten SOPs lose anything on this list, the
  rewrite failed. Give each entry an anchor so it can be grepped.
- **Deferred** — findings not worth acting on, one line of reason each.
- **Open questions for the lab** — decisions that are not yours: scientific
  disagreements, scope changes, anywhere a reviewer raised a `CHALLENGE`.
  Options and a recommendation, then stop.

End with the self-check output.

---

# ACCEPTANCE CHECKS

Run these as scripts. The previous round's orchestrator caught two reports
declaring themselves compliant while omitting required fields — by scanning,
not by reading. Read-by-eye will not catch it.

**1. Contract compliance, every report.** Run the self-check script from the
*Output contract* section against each of the five reports, with `REPORT` and
`SOURCE` set appropriately. Every one must print `CLEAN`.

**2. Ledger completeness.** For each Agent A report, the ledger must account for
every heading in its source file:

```bash
python3 - <<'PY'
import re
pairs=[('reviews/EMU.review.md','SOP_EMU_NeSI.md'),
       ('reviews/CONCOMPRA.review.md','SOP_CONCOMPRA_NeSI.md'),
       ('reviews/READBASED.review.md','SOP_READBASED_NeSI.md'),
       ('reviews/R_ANALYSIS.review.md','SOP_R_Analysis.md')]
for rep, src in pairs:
    led = open(rep).read().split('## Section ledger')[1].split('## Findings')[0]
    rows = [r for r in led.split('\n') if r.strip().startswith('|')
            and not set(r) <= set('|- :')]
    fence, heads = False, 0
    for l in open(src):
        if l.strip().startswith('```'): fence = not fence; continue
        if not fence and re.match(r'#{1,6}\s', l): heads += 1
    print(f"{rep}: {len(rows)-1} ledger rows vs {heads} source headings"
          f"{'  <-- CHECK' if len(rows)-1 < heads else ''}")
PY
```

Then spot-check three rows per report against the file. A ledger that is short
is a skimmed report.

**3. Nothing on a keep list appears in a proposed cut.** Cross-check each
report's keep-list anchors against every `CUT` verdict in its ledger.

**4. Every `VERIFIED` carries real output**, not a description of output. Sample
five at random and confirm each quotes what a command printed.

**5. Every `NOT-VERIFIABLE-HERE` is genuinely unreachable from this session.**
This is the check most likely to fail on a cluster run: it is the tier an agent
retreats to when it does not want to run the command. Sample five. If any could
have been settled in under a minute, send the report back.

**6. `CONTRACT: PASS` is present**, or the shortfall is stated.

A report failing these is re-run, not worked from.

**The tell for a skimmed report** is a long S4 list next to a thin S1 list, or a
`Verified against the cluster` section with fewer entries than the document has
module strings.

---

# CHANGELOG — what v2 changed and why

Each of these comes from something that actually went wrong or actually worked
in the v1 run.

1. **Stage 0 environment probe added.** v1 deferred sixteen checks, which
   blocked four work-plan items. Probing first turns them into inputs.
2. **`NEEDS-BENCH-CHECK` split into `VERIFIED` and `NOT-VERIFIABLE-HERE`,** with
   a rule that you must check what you can check. The old label let an agent
   defer anything it found inconvenient; on a cluster that is no longer honest.
3. **`Evidence` promoted to its own field.** It was buried inside `Confidence`
   and got compressed to nothing on lower-severity findings.
4. **`Anchor` field added.** v1 anchored to line numbers only; every applied fix
   invalidated the anchors below it, and the rewrite lost time re-locating them.
5. **Self-check is now a script, and its output is pasted into the report.** Two
   of five v1 reports declared `CONTRACT: PASS` while omitting required fields —
   19 missing `Confidence` in one, 9 missing `Defect` in another — because the
   check was done by impression. Both had to be sent back.
6. **Summary cap changed from ten words to 80 characters.** 66 of 158 v1
   summaries broke the word cap while stating the defect perfectly well. A limit
   that two thirds of good output violates is the wrong limit.
7. **All nine fields required at every severity.** v1's contract was read as
   applying mainly to S1 and S2.
8. **"Build a fixture and run it" promoted to a named technique** with a worked
   example. Two v1 findings were settled this way in under a minute each, and
   the demonstrations were more convincing than any amount of argument.
9. **`Verified against the cluster` section added to Agent A's skeleton,**
   including checks that passed — so the next round need not repeat them.
10. **Prior reports reframed as hypotheses.** The repository has been rewritten
    once against them; some of those fixes will be wrong, and a rewritten
    document has new defects a fresh reader will see and a returning one will
    not.
11. **Irreversibility promoted in the global ranking.** The top-ranked v1 defect
    was a sequencing-depth formula that could not be corrected after the money
    was spent; that property, not just blast radius, decides first place.
12. **Acceptance checks are scripts**, and a new one specifically hunts for
    `NOT-VERIFIABLE-HERE` used as an excuse.
