# SOP Tutorial Conversion — Structure and Voice Review

**To run this:** open a fresh session on NeSI, `cd` into a clone of this
repository, check out the working branch, and say

> Read `prompts/SOP_TUTORIAL_PROMPT.md` and run the review in it. It is
> self-contained.

**This is not the correctness review.** `prompts/SOP_REVIEW_PROMPT.md` hunts for
wrong-but-plausible output; this one asks whether a first-time reader can follow
the document at all. Run this one. Correctness findings you happen to trip over
are welcome, but they are not the job, and sixteen open bench checks listed in
`reviews/v1/00_SYNTHESIS.md` stay open until someone runs that other prompt.

---

# THE PROBLEM, STATED

These four documents are written for people running their first analysis. One of
them behaves that way. The other three are runbooks: correct instructions,
addressed to someone who already knows what the tools are.

This was measured, not felt. Counting headings across the four files:

| Document | "What is X?" headings | "Why this choice?" headings | Action headings |
| --- | --- | --- | --- |
| `SOP_EMU_NeSI.md` | **12** | 1 *(mostly inline as bold)* | 17 |
| `SOP_READBASED_NeSI.md` | 2 | **5** | 42 |
| `SOP_CONCOMPRA_NeSI.md` | **0** | **0** | 45 |
| `SOP_R_Analysis.md` | 1 | 1 | 19 |
| `README.md` | 1 | 0 | 6 |

Two layers of explanation exist, and they are not interchangeable:

- **Layer 1 — what is this thing?** Written for a reader who has never met it.
  *"What is an amplicon?"*, *"What are quality scores?"*
- **Layer 2 — why did we choose this?** Written for a reader who knows the
  options. *"Why T2T-CHM13v2.0"*, *"Why these thresholds"*.

`SOP_EMU_NeSI.md` has both. `SOP_READBASED_NeSI.md` has layer 2 without layer 1
— which is why a previous review mistook it for the model to copy; it was
looking for justification and found plenty. `SOP_CONCOMPRA_NeSI.md` has neither.

Note the trap: **this is not about quantity of prose.** These documents have
already been through a full correctness round that tightened the writing
considerably — median paragraph is now 24 to 34 words and the longest in the set
is 101, down from 239. The heading balance did not move at all.

That is the finding. The missing layer is structural, and editing sentences does
not add it. A proposal amounting to "add more explanation", without naming which
layer is absent, is not a finding.

**The job:** bring all four to the EMU pattern — both layers, in order — and
produce a plan precise enough that the rewrite is mechanical.

`README.md` is in scope too, under different rules. It is a router, not a
tutorial: its job is to get a reader to the right file in under a minute. It is
also the densest page in the repository. `TUTORIAL_SPEC.md` §10 covers it, and
the seam agent owns it.

---

# ORCHESTRATOR INSTRUCTIONS

You will not review the documents yourself and you will not edit them. You
launch agents and check their work.

**Stage 0 — one agent, alone, first.** **AGENT PROMPT 0**. A short reality check:
does every module string, tool and file the documents name actually exist? A
restructure that carries a dead reference forward is worse than one that never
happened. It writes `reviews/structure/00_REALITY.md`. Keep it small — this is
not the correctness review, and it should take minutes, not an hour.

**Stage 1 — four agents, launched together in one message so they run
concurrently.** One per document:

| Agent | `{{FILE}}` | Writes to |
| --- | --- | --- |
| 1 | `SOP_EMU_NeSI.md` | `reviews/structure/EMU.md` |
| 2 | `SOP_CONCOMPRA_NeSI.md` | `reviews/structure/CONCOMPRA.md` |
| 3 | `SOP_READBASED_NeSI.md` | `reviews/structure/READBASED.md` |
| 4 | `SOP_R_Analysis.md` | `reviews/structure/R_ANALYSIS.md` |

Each receives, verbatim: the **COMMON BRIEF**, the full text of
**`TUTORIAL_SPEC.md`** from the repository root, and **AGENT PROMPT A** with
`{{FILE}}` and `{{OUTPUT}}` filled in. Give them the full
text. Do not summarise it and do not tell them to read this file — an agent that
reads this file reads the other agents' prompts too and drifts off its own
document.

`SOP_EMU_NeSI.md` is reviewed like the rest. It is the closest to the target,
not the target itself, and its own gaps are the most useful in the set: whatever
is missing from the exemplar is missing from the specification.

**Stage 2 — one agent, after all four return.** **COMMON BRIEF**,
`TUTORIAL_SPEC.md`, **AGENT PROMPT B**. Writes `reviews/structure/00_PLAN.md`.

**Stage 3 — you.** Run the acceptance checks. They are scripts. Then commit
`reviews/structure/` and report: how many sections need what treatment, the
documents ranked by distance from the specification, and the first three items
of the plan.

**Stage 4 — the rewrite. Do not begin without explicit authorisation.**

Nothing outside `reviews/structure/` gets edited during Stages 0–3.

---

# COMMON BRIEF

> Give this to all six agents, verbatim, ahead of `TUTORIAL_SPEC.md` and their
> individual prompt.

## The repository

Taylor Lab bioinformatic SOPs: four Markdown standard operating procedures plus
a README index. Microbial community analysis on NeSI (New Zealand eScience
Infrastructure, a SLURM HPC cluster) and in R.

| File | What it is |
| --- | --- |
| `SOP_EMU_NeSI.md` | **Part 1.** Nanopore full-length 16S: NeSI onboarding, read QC, filtering, Emu profiling, count tables. Starts at `pwd`. The only document that teaches the cluster. |
| `SOP_CONCOMPRA_NeSI.md` | **Runs after Part 1**, same data: reference-free consensus OTUs. |
| `SOP_READBASED_NeSI.md` | **Illumina shotgun, read-based.** |
| `SOP_R_Analysis.md` | **Part 2.** Count tables to results in R. Serves all three upstream documents. |
| `README.md` | Index, routing table, conventions, tool versions. **In scope**, rewritten by the seam agent — see `TUTORIAL_SPEC.md` §10. It is a router, not a tutorial. |

## Who the reader is

`TUTORIAL_SPEC.md` §1 defines them, and you receive it. One line to carry with
you: **a graduate student who has never opened a terminal**, for all five
documents.

That overrides what a document says about itself. `SOP_READBASED_NeSI.md:11`
still tells the reader it assumes prior pipeline experience; that assumption is
withdrawn, and the line is a finding.

## Your environment is not the reader's environment

You have a NeSI shell, an R module and every package loaded, because you are
auditing these documents. The reader does not. Part 2 is documented to run on
the student's own machine — deliberate lab policy, and correct. Never let a
convenience of your session become a recommendation, and never mark a setup step
redundant because it is already satisfied for you.

## Tight, and complete. Both.

The form rules are `TUTORIAL_SPEC.md` §6. What that section does not give you is
the per-document baseline, so here it is — this is the state you are starting
from and the number you will be measured against:

| Document | Median para | Over 80 words | Longest |
| --- | --- | --- | --- |
| `README.md` | 34 | 0 | 69 |
| `SOP_R_Analysis.md` | 30 | 6 | 101 |
| `SOP_EMU_NeSI.md` | 28 | 6 | 96 |
| `SOP_READBASED_NeSI.md` | 24 | 1 | 100 |
| `SOP_CONCOMPRA_NeSI.md` | 24 | 2 | 87 |

This is already close to the target, so **you have little room to spend.** A
previous round removed the worst offenders — the longest paragraph in the set
was 239 words and is now 101.

**Your net word count should be roughly flat.** What you add in short definitions
comes back out of the fifteen remaining over-length paragraphs.
`SOP_CONCOMPRA_NeSI.md` will grow, because it is missing an entire layer rather
than carrying it badly. The others should hold.

What you are removing is *incidental* complexity — three commands where one
would do, an idea explained twice in different places, a sentence that restates
the code beneath it, an optional side-path given the same weight as the main
path, reference material sitting mid-walkthrough, a decision presented with no
default, a hedge on a hedge.

**A tutorial that is shorter but leaves the reader guessing has got worse.** Cut
words, never content. If you cannot say it shorter, say it in a table.

## Load-bearing content

**A restructure is the most likely way this repository loses its best content.**
Moving a section is how a paragraph gets dropped, and you are moving most of
them.

The never-cut list is `TUTORIAL_SPEC.md` §9, which you also receive. Read it
before you propose removing anything. Two things it does not say, which matter
here specifically:

- The "why this number" content **is** layer 2. The whole exercise is adding
  layer 1 *without losing it*, so a proposal that trades one for the other has
  failed at the only thing being asked.
- Where a why-this-number paragraph genuinely rambles, the verdict is **REWRITE
  TIGHTER** and you supply the tighter version carrying the whole reason across.
  Never CUT.

---

# THE SPECIFICATION

**`TUTORIAL_SPEC.md`, in the repository root.** It carries the eleven content
rules (R1–R11), the five form rules (F1–F5), the six voice rules (V1–V6), the
document and step templates, the cross-document consistency table, and the
never-cut list. Read it now; you will be pasting it verbatim to every agent.

It lives outside this prompt on purpose. Contributors adding a new SOP need it,
and it is the standard a future review checks against — including a review that
does not use this prompt.

---

# AGENT PROMPT 0 — reality check

> One agent, before all others. Prepend the COMMON BRIEF.

You are confirming that what the documents name actually exists, so the
restructure does not carry a dead reference forward. You are **not** reviewing
structure and you write no findings about it. Keep this short.

R and conda sit behind modules and are not on `PATH` in a bare login shell; load
them before concluding anything is missing. Extract the claims mechanically:

```bash
grep -ohE 'module load [A-Za-z0-9._/-]+' *.md | sort -u
grep -ohE '\b[0-9a-z_]+\.(sh|sl|py|R|tsv|csv|txt|fa|nwk)\b' *.md | sort -u
grep -ohE '^\s*[a-z]+::[A-Za-z_.]+\(' *.md | sort -u
```

For each: the claim, the command you ran, its actual output, and a verdict of
`EXISTS`, `DRIFTED` (present, different version or spelling), `ABSENT` or
`UNCHECKABLE`. Quote real output; never write down what you expect.

Write `reviews/structure/00_REALITY.md`:

```
## What I loaded to run these checks
## Modules
## Tools and flags
## R packages
## Files the documents reference
## Absent or drifted
```

Open with one paragraph: the single fact most likely to surprise someone who
trusted these documents. Return a short summary.

---

# AGENT PROMPT A — per-document structure review

> Four agents, one each. Fill `{{FILE}}` and `{{OUTPUT}}`. Prepend the COMMON
> BRIEF and `TUTORIAL_SPEC.md`.

Review `{{FILE}}` against the specification, in full, in order. Write your
report to `{{OUTPUT}}` and return a short summary: counts by severity, the S1
titles, and your self-check output.

**Read `{{FILE}}`, `README.md`, and `reviews/structure/00_REALITY.md`.** Do not
read the other SOPs — a later agent owns everything between files. You may read
`SOP_EMU_NeSI.md` **only** if you are reviewing a different document and only to
see how it handles a pattern you are proposing; do not import its content.

You are not a proofreader. You are the person who watched a student work through
this document, get stuck, and say *"but what IS this?"* — and you are writing
down every place that happened.

Read it three times, with a different question each time.

### Pass 1 — Can a beginner follow it?

Read as someone who has never opened a terminal. At every command, ask: do I
know what this tool is? Do I know what this flag does? Do I know what I should
see when it works? Would I notice if it silently did nothing?

Build the **jargon table** explicitly, because impressions miss this: every
term, tool, format and abbreviation, its first occurrence, and where it is
defined. Every row where the definition comes after the use, or does not exist,
is a finding under R2.

Then check every step against the step template (`TUTORIAL_SPEC.md` §4). Two
things are missing almost everywhere and each is a finding:

- **No checkpoint.** A command the reader runs with no way to tell it worked.
  Supply the checkpoint block — command, expected value, what a mismatch means.
- **No runtime.** Seconds, minutes or hours. Six words that stop a reader
  killing a job that was working.

### Pass 2 — Is the shape right?

Walk the headings. Where does the document teach, and where does it only
instruct? Count the pure-prose subsections. Locate every front-loaded setup
block and every piece of reference material sitting mid-walkthrough. Check the
numbering runs in performance order and that script names match their sections.

### Pass 3 — Is the voice consistent, and does it scan?

Where does the register shift? Where does the document assume more than the
reader has, and where does it re-teach something it already covered? Both are
defects.

Then run the form check, and treat every hit as a finding. Save it as
`scan.py` and run `python3 scan.py {{FILE}}`:

```python
import re, sys
f = sys.argv[1]
FENCE = chr(96) * 3          # a literal ``` would close this code block
fence = False; buf = []; out = []; start = 0
for i, l in enumerate(open(f).read().split('\n'), 1):
    if l.strip().startswith(FENCE): fence = not fence; continue
    if fence: continue
    if re.match(r'#{1,6}\s|^\s*[|>]', l):
        if buf: out.append((start, ' '.join(buf))); buf = []
        continue
    if l.strip():
        if not buf: start = i
        buf.append(l.strip())
    elif buf:
        out.append((start, ' '.join(buf))); buf = []
if buf: out.append((start, ' '.join(buf)))
over = [(n, len(p.split()), p[:60]) for n, p in out if len(p.split()) > 80]
print(f"{len(out)} paragraphs, {len(over)} over 80 words")
for n, w, t in sorted(over, key=lambda x: -x[1]):
    print(f"  L{n:<5} {w:4}w  {t}...")
```

Every paragraph it prints breaks **F1** and needs a finding with the split
version supplied. Then read for **F3**: every run of prose listing three or more
things of a kind is a table you have not written yet.

### Severity

- **S1 — Blocks a beginner.** They stop, or proceed on a guess. A command whose
  purpose is undefined, a fork with no default, a term used with no definition
  and no way to look it up.
- **S2 — They run it without understanding it.** It works, but they cannot
  adapt it, debug it, or interpret the output. Layer 2 present, layer 1 absent.
- **S3 — Wrong shape.** Right content, wrong place or order. Front-loaded setup,
  reference material mid-walkthrough, numbering that fights the run order.
- **S4 — Voice.** Register, person, spelling, heading style. **Cap: 15**; merge
  the rest into one omnibus entry.

### The finding block

```
### S-04 · S2 · Trimming justified but never explained
- **Where:** SOP_READBASED_NeSI.md:267-272, § 6
- **Anchor:** `ktrim=r applies to every sequence in`
- **Quote:**
  > This runs as **two passes, and they cannot be combined into one.** The
  > reason is that `ktrim=r` applies to every sequence in `ref=`.
- **Breaks:** R1 (layer 2 without layer 1), R2 (`ktrim`, `ref=`, PhiX undefined)
- **Reader impact:** A beginner reaches this having never been told what
  adapter trimming is or why PhiX is in their data. The paragraph explains a
  subtlety of a procedure they have not yet been told the purpose of, so they
  copy both commands without knowing what either removes — and cannot tell,
  afterwards, whether the trimming worked.
- **Fix:** Paste-ready replacement or insertion, in full.
```

**All six fields, every finding, every severity.** `Anchor` must be a literal
string that `grep -F` finds exactly once. Fix text for S1 and S2 must be the
actual prose to paste, not a description of it — you are writing the tutorial,
not commissioning it. For S3 a precise instruction ("move §2 Preflight to §5,
§7, §9 as three separate module-load blocks") is enough.

### Report skeleton

Exactly these sections, in this order.

```
## Document: {{FILE}}
## Verdict against the specification
## Jargon table
## Section ledger
## Findings
## Target outline
## Keep list
## Rewrite plan
```

- **Verdict** — one paragraph, then all eleven rules and the five form rules as a table: `| Rule | Pass /
  Partial / Fail | One-line evidence |`.
- **Jargon table** — `| Term | First used | Defined at | Verdict |`. Every term
  a beginner would not know. This is the evidence for R2 and the most useful
  thing you will produce.
- **Section ledger** — every heading in order, with the treatment it needs:
  `CLEAN` `ADD-LAYER-1` `ADD-OUTCOME` `MOVE` `SPLIT` `MERGE` `REWRITE-VOICE`
  `TIGHTEN`. `| § | Heading | Lines | Treatment | Findings |`
- **Findings** — contract blocks.
- **Target outline** — **the deliverable that makes the rewrite mechanical.**
  The full heading structure this document should have when finished, in order,
  each annotated: `KEEP` (exists, unchanged), `MOVE FROM §N`, `REWRITE`, or
  `NEW` with two lines on what it must contain and roughly how long. Someone
  should be able to build the document from this outline plus the findings,
  without re-reading the original.
- **Keep list** — content that must survive, anchored, with why a restructure
  would be tempted to lose it. This is the regression test. Fewer than fifteen
  entries.
- **Rewrite plan** — ordered, dependency-aware. What changes, which findings it
  closes, rough size, whether it can proceed independently of the other files.

End with the self-check.

### Self-check

```bash
python3 - <<'PY'
import re, subprocess
REPORT="reviews/structure/YOUR_REPORT.md"; SOURCE="SOP_YOUR_FILE.md"
F=["Where","Anchor","Quote","Breaks","Reader impact","Fix"]
txt=open(REPORT).read()
blocks=[b for b in re.split(r'\n(?=### S-)',txt) if b.startswith('### S-')]
bad=[]
for b in blocks:
    m=re.match(r'### (S-\d+) · (S\d) · (.+)',b.split('\n')[0])
    if not m: bad.append((b[:30],'malformed heading')); continue
    fid,sev,summ=m.groups()
    if miss:=[k for k in F if f'- **{k}:**' not in b]: bad.append((fid,f'missing {miss}'))
    if len(summ)>90: bad.append((fid,f'summary {len(summ)} chars > 90'))
    if not re.search(r'- \*\*Breaks:\*\*.*R\d',b): bad.append((fid,'no rule cited'))
    if a:=re.search(r'- \*\*Anchor:\*\* *`([^`]+)`',b):
        n=subprocess.run(['grep','-cF',a.group(1),SOURCE],capture_output=True,text=True).stdout.strip() or '0'
        if n!='1': bad.append((fid,f'anchor matches {n}x, must be 1'))
sev=[re.match(r'### S-\d+ · (S\d)',b).group(1) for b in blocks if re.match(r'### S-\d+ · (S\d)',b)]
print(f"findings={len(blocks)} "+" ".join(f"{s}={sev.count(s)}" for s in ['S1','S2','S3','S4']))
if sev.count('S4')>15: print(f"!! S4 cap exceeded: {sev.count('S4')}")
for f,w in bad: print(f"!! {f}: {w}")
print("CLEAN" if not bad else f"{len(bad)} violations")
PY
```

Then confirm by hand: the ledger accounts for every heading; the target outline
covers every section in the ledger; nothing on the keep list is proposed for
removal. Write `CONTRACT: PASS` or state the shortfall.

---

# AGENT PROMPT B — set-level shape and plan

> One agent, after all four A reports exist. Prepend the COMMON BRIEF and
> `TUTORIAL_SPEC.md`.

**Read all five source files yourself** — including `README.md`, which you own
— then `reviews/structure/00_REALITY.md`, then the four reports. Write `reviews/structure/00_PLAN.md`. Return a short
summary.

## Job 1 — The set as one manual

1. **One shape for four documents.** Reconcile the four target outlines into a
   single skeleton every document follows, and say for each where it deviates
   and whether the deviation is earned. A reader moving from Part 1 to Part 2
   should not have to relearn where things live.

2. **The shared teaching layer.** Several concepts are needed by more than one
   document: SLURM and array jobs, conda, FASTQ, sample manifests, compositional
   data, what a count table is.

   For each, answer three things — which document teaches it, which link to it,
   and does the linking document survive being read on its own?

   `SOP_EMU_NeSI.md` owns the cluster material. Check that every other
   document's assumed knowledge is actually satisfied by what EMU teaches, and
   list what is assumed but taught nowhere. **That list is the most valuable
   thing in your report**: it is what makes a beginner give up.

3. **Jargon across the set.** Merge the four jargon tables. Any term defined in
   two places must agree; any term used in three documents and defined in none
   is an S1 for whichever document uses it first.

4. **Preflight and front-loaded setup.** `SOP_READBASED_NeSI.md` §2 is the worst
   instance but check all four. For each block: which step actually needs each
   check, and what the reader should do when it fails. Produce the distribution
   map. Do not simply delete: the module-drift warning and the compute-node
   internet check are load-bearing and must land somewhere they can be acted on.

5. **Numbering and scripts.** If sections move, script filenames move with them.
   Produce the full old-to-new mapping, and list every cross-reference in every
   file that has to change with it.

6. **The canonical job header (R11).** Every script now carries its own full
   header, so every copy must start identical. Produce two things:

   - **The header template**, written out once, exactly as it will appear at the
     top of every script: shebang, directive order, directive style, log paths,
     `set -euo pipefail`, and the array boilerplate as a clearly marked optional
     block. Resolve the style disagreement between the documents and say which
     you chose and why.
   - **The per-script table** — `| Script | Document | Job name | Time | Mem |
     CPUs | Array? |` — covering every script in all four documents. These are
     the values that get pasted into each header. Take them from the existing
     text where it states them, and flag any script whose resources are stated
     nowhere as `UNSTATED`; that is a gap, not something to invent.

   Note where a document's current figures disagree with each other. Do not
   guess a number: an unstated walltime is an open question for the lab.

6. **Consistency.** Placeholders, object names, rank vocabulary, job headers,
   register. One row per item that varies, with the decision.

7. **The README.** You own its rewrite, because you are the only agent that
   reads all five files and its every claim is about the other four. Apply
   `TUTORIAL_SPEC.md` §10, which covers it specifically.

   Three jobs, in order:

   - **Verify every claim.** Audience, contents, tool versions, storage figures,
     what each SOP does and does not cover, and whether the routing table sends a
     reader with given data to the right file. Check each against the SOP it
     describes. Quote both sides of any disagreement. This is N3 and it is the
     commonest way the README rots.
   - **Check for duplication.** A previous round already removed the conventions
     block that restated `TUTORIAL_SPEC.md` §8. Confirm nothing else on the page
     duplicates the spec, and that what remains links rather than restates (N2).
   - **Check the form.** It is now the cleanest document in the set — median 34
     words, nothing over 80 — so this should be quick. Confirm bullets are one
     sentence under 30 words (N4) and leave the rest alone.

   Produce a **target README in full**, ready to paste — not a list of changes.
   It is 114 lines. If verification turns up no false claims and the form is
   clean, say so and reproduce it unchanged rather than inventing work.

## Job 2 — The plan

1. **Rank the four documents by distance from the specification**, with the
   measurement. Say which to do first and why. The default is worst-first, but
   argue it if the dependencies say otherwise.
2. **De-duplicate** findings that appear in several reports.
3. **Audit every proposed cut** against the load-bearing list. Report how many
   you struck.
4. **Sequence the work** so shared conventions and the shared teaching layer
   land before the per-document rewrites that depend on them, and so no two
   items collide in the same lines. Mark what runs in parallel.
5. **Size it honestly.** These are 3,800 lines plus the README, and the answer is
   likely to be longer. Estimate the added length per document and say plainly if the plan is
   more work than it looks.

## Report skeleton

```
## State of the set
## The target shape
## The canonical job header
## Per-script resources
## README: false claims found
## README: the replacement
## Assumed but taught nowhere
## Shared teaching layer and ownership
## Merged jargon table
## Preflight distribution map
## Section and script renumbering map
## Consistency matrix
## Work plan
## Consolidated keep list
## Open questions for the lab
```

- **State of the set** — half a page for someone deciding how much time to
  spend. Which document is furthest from the target, what the single highest-
  value change is, and what it will cost.
- **Assumed but taught nowhere** — the gap list from Job 1.2. Each entry: the
  concept, which documents assume it, and which should own teaching it.
- **Work plan** — `| # | Item | Files | Closes | Size | Depends on |`, sequenced,
  parallelism marked.
- **Consolidated keep list** — merged and anchored. If the rewritten documents
  lose anything on this list, the rewrite failed.
- **Open questions for the lab** — anywhere the answer is a lab decision rather
  than yours. Options and a recommendation, then stop.

End with the self-check.

---

# ACCEPTANCE CHECKS

Run these as scripts, not by eye.

**1. Contract compliance.** Run each report's self-check. All must print
`CLEAN`.

**2. Ledger completeness.** Every heading in each source file appears in its
report's ledger:

```bash
python3 - <<'PY'
import re
for rep,src in [('reviews/structure/EMU.md','SOP_EMU_NeSI.md'),
                ('reviews/structure/CONCOMPRA.md','SOP_CONCOMPRA_NeSI.md'),
                ('reviews/structure/READBASED.md','SOP_READBASED_NeSI.md'),
                ('reviews/structure/R_ANALYSIS.md','SOP_R_Analysis.md')]:
    led=open(rep).read().split('## Section ledger')[1].split('## Findings')[0]
    rows=[r for r in led.split('\n') if r.strip().startswith('|') and not set(r)<=set('|- :')]
    fence=False; heads=0
    for l in open(src):
        if l.strip().startswith('```'): fence=not fence; continue
        if not fence and re.match(r'#{1,6}\s',l): heads+=1
    flag='  <-- SHORT' if len(rows)-1<heads else ''
    print(f"{rep}: {len(rows)-1} ledger rows vs {heads} headings{flag}")
PY
```

**3. Target outline covers the ledger.** Every section in the ledger is either
in the target outline or explicitly marked for deletion with a reason. A section
that silently vanishes between the two is how content gets lost.

**4. Keep list is anchored and intact.** Every keep-list entry's anchor still
`grep -F`s to exactly one hit in its source file, and none appears in a proposed
deletion.

**5. Fix text is real.** Sample five S1/S2 findings. Each `Fix` must be prose
you could paste into the document, not an instruction to write prose.

**6. Rules are cited.** Every finding names at least one specification rule. A
finding citing none is an opinion.

**7. Form rules are enforced.** Run the paragraph scan from Pass 3 against each
source file. Every paragraph it reports must appear in that document's report,
either as an F1 finding with a split supplied, or in the target outline as
content being restructured away. An unaccounted monster paragraph means the form
pass was skipped. Expected counts, as measured before this run: EMU 6,
R_Analysis 6, CONCOMPRA 2, READBASED 1, README 0.

**8. Every script has a complete header (R11).** Before the rewrite this
confirms the reports found the gap; after it, that the gap is closed. Run
against the source files:

```python
import re, sys
FENCE = chr(96) * 3
for f in sys.argv[1:]:
    blocks, cur, inb = [], [], False
    for l in open(f).read().split('\n'):
        if l.strip().startswith(FENCE):
            if inb: blocks.append('\n'.join(cur)); cur = []
            inb = not inb; continue
        if inb: cur.append(l)
    jobs = [b for b in blocks if 'SBATCH' in b or 'SLURM_ARRAY_TASK_ID' in b
            or 'SLURM_CPUS_PER_TASK' in b]
    print(f"\n{f}: {len(jobs)} job-script blocks")
    for i, b in enumerate(jobs, 1):
        miss = [n for n, ok in [
            ('shebang',   b.lstrip().startswith('#!')),
            ('--account', '--account' in b),
            ('--time',    '--time' in b),
            ('set -e',    'set -euo pipefail' in b or 'bash -e' in b),
        ] if not ok]
        uses_sample = 'SAMPLE' in b and 'SAMPLE=' not in b
        if uses_sample: miss.append('$SAMPLE never assigned')
        print(f"   block {i}: {'COMPLETE' if not miss else 'missing ' + ', '.join(miss)}")
```

Any block reporting `missing` must be covered by an R11 finding in that
document's report. After the rewrite, every block must print `COMPLETE`.

**9. The README replacement is complete and true.** The plan must contain a
full README, ready to paste, not a change list. Check three things: it opens
with the routing table (N1), it links to `TUTORIAL_SPEC.md` for conventions
rather than restating them (N2), and every claim it makes about a SOP is
verified against that SOP with a quote (N3). Run the paragraph scan against it —
median must be under 35 and no bullet over 30 words (N4).

**The tell for a skimmed report** is a long S4 list beside a thin S1 list, a
jargon table with fewer rows than the document has tools, or zero F1 findings
against a file the scan says has nine.

---

# AFTER THE REVIEW

Do not start the rewrite without authorisation. When it comes:

1. Work the plan in its stated order. Shared teaching layer and conventions
   first, then per-document.

2. **Commit per work item**, so a bad call can be backed out without losing the
   rest.

3. **Run the keep-list regression before reporting done.** Grep every anchor in
   the consolidated keep list against the rewritten files. Any miss is a
   regression, not a judgement call.

4. **Re-run all three scans** from `TUTORIAL_SPEC.md` §11. Two things must both
   hold: layer-1 heading counts have gone up, and no document has more
   over-80-word paragraphs than it started with.

   Passing the first while failing the second means the missing layer was added
   as more wall-of-text. That is the specific way this rewrite fails.
