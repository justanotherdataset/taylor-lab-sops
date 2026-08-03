# SOP Release Sign-Off — The Capstone Review (v1, whole-suite)

**To run this:** open a fresh session **on NeSI**, `cd` into a clone of this
repository, check out the branch carrying it, and say

> Read `prompts/SOP_CAPSTONE_PROMPT.md` and run the review in it. It is
> self-contained.

Everything below is addressed to the assistant that receives that instruction.
It is self-contained: no other file needs to be read first. Unlike its two
siblings, this review **requires** you to read the earlier reviews' outputs
before you file anything — not to repeat them, but to stay off their ground.

**This is not the correctness review, and not the tutorial review.**
`prompts/SOP_REVIEW_PROMPT.md` asked whether a document produces a wrong result
that looks right. `prompts/SOP_TUTORIAL_PROMPT.md` asked whether a first-time
reader can follow it. Both have been run. Their findings are **settled and
off-limits here.** This review asks the one question neither could, because both
looked at a document and this one looks at the *product*: **are these five
documents one thing a lab can ship?**

---

# THE QUESTION, STATED

The two siblings each stood inside one document at a time. A whole class of
defect is invisible from there and only appears when you step back and hold the
set in one hand:

- Five documents carry five version numbers and there is no version of *the
  suite*. A reader cannot tell what they are holding or whether it is current.
- The README still says "four SOPs." There are five. The word "four" is now
  wrong in every place a count is stated.
- One document embeds figures from a remote host, one embeds local files, three
  show no figures at all. There is no house style; there is an accident.
- A section was renumbered in one document, and a cross-reference to it in
  another document now points at a heading that moved.
- A sixth of the suite — `SOP_ASSEMBLY_NeSI.md`, 985 lines, marked **v0.1** —
  was written after both reviews and **has been reviewed by no one.**

None of that is a wrong flag or an undefined term. It is the seams between the
documents, the drift between their versions, and the gap between "each file is
fine" and "the set is ready." That is your remit.

**Read it the way the lab's next new student will.** They clone the repository
cold, open the README, pick the document it routes them to, and try to get from
nothing to a result — moving between documents as the pipeline tells them to.
Every place that fails *as a product* — a figure that will not load, a
cross-reference to a section that was renumbered out from under it, a document
no one ever checked, a promise the README makes that the suite does not keep —
is yours to find, prove, and hand back a fix for.

**Two facts that govern how you work.**

1. **The suite is five documents, not four.** The correctness and tutorial
   rounds each reviewed four: `SOP_EMU_NeSI.md`, `SOP_CONCOMPRA_NeSI.md`,
   `SOP_READBASED_NeSI.md`, `SOP_R_Analysis.md`. `SOP_ASSEMBLY_NeSI.md` came
   later and neither round saw it. It gets a heavier pass than the other four
   (see Agent Prompt A, the **Assembly supplement**), and its release status is
   its own line in the verdict.

2. **Every line number in the two prior reports is stale.** The documents were
   rewritten after those rounds and all of them grew. A finding in
   `reviews/` that says "line 412" no longer points where it did. When you
   consume a prior finding, re-anchor it to a heading and a `grep -F` string
   before you trust it, and anchor your own findings the same way.

---

# ORCHESTRATOR INSTRUCTIONS

You are running a release sign-off of five documents. You will not review them
yourself and you will not edit them. You launch agents and check their work.

The shape is the same six-agent pipeline the two sibling reviews use, adapted so
the weight sits on the set, not the file.

| Stage | Agents | Concurrency | Role |
| --- | --- | --- | --- |
| **Stage 0** | 1 (**Agent Prompt 0**) | alone, first | Product-integrity probe: resolve every cross-reference, figure and script; probe the assembly modules no earlier round touched. Writes a facts file every later agent reads. Nothing else starts until it returns. |
| **Stage 1** | 5 (**Agent Prompt A**), one per SOP | launched together in one message so they run concurrently | Per-document capstone pass: does this file hold up as a shippable member of the set. One report each. |
| **Stage 2** | 1 (**Agent Prompt B**) | after all five A's return | The set as one product, and the ship verdict. One merged plan. |
| **Stage 3** | the Orchestrator (you) | — | Run the scripted acceptance checks, commit the outputs, report to the user. |
| **Stage 4** | the rewrite | on authorisation only | Work the plan in order, commit per item, run the keep-list regression. **Do not begin it without explicit authorisation.** |

**Dispatch.** Each agent receives, verbatim: the **COMMON BRIEF** and its own
**AGENT PROMPT** with `{{FILE}}` and `{{OUTPUT}}` filled in. Give them the full
text. Do not summarise it, do not paraphrase it, and do not tell them to go and
read this file — an agent that reads this file reads the other agents' prompts
too and drifts off its own document.

**Stage-1 dispatch table** (fill and hand out):

| Agent | `{{FILE}}` | Writes to |
| --- | --- | --- |
| 1 | `SOP_EMU_NeSI.md` | `reviews/capstone/EMU.md` |
| 2 | `SOP_CONCOMPRA_NeSI.md` | `reviews/capstone/CONCOMPRA.md` |
| 3 | `SOP_READBASED_NeSI.md` | `reviews/capstone/READBASED.md` |
| 4 | `SOP_R_Analysis.md` | `reviews/capstone/R_ANALYSIS.md` |
| 5 | `SOP_ASSEMBLY_NeSI.md` | `reviews/capstone/ASSEMBLY.md` |

**Isolation, and the one exception to it.** An Agent A does not read the other
SOPs and does not read another Agent A's report — reading a neighbour biases you
toward confirming it. The exception is deliberate and load-bearing: **every
agent reads the prior reviews' outputs** (`reviews/00_SYNTHESIS.md`,
`reviews/structure/00_PLAN.md`, and the per-document reports beside them), and
the compact settled-list in the COMMON BRIEF, *before* filing anything — because
this review's whole value is not re-filing what those rounds already closed.
Agent B is the only agent that reads all five source files; it owns everything
between them.

**Write scope.** Nothing outside `reviews/capstone/` is edited during Stages
0–3. The five SOPs, the README and the spec stay read-only until a plan is
approved.

---

# COMMON BRIEF

Give this to all seven agents, verbatim, ahead of their individual prompt.

## The repository

Taylor Lab bioinformatic SOPs: five Markdown standard operating procedures plus
a README index and a specification the documents are written against. Microbial
community analysis on NeSI (New Zealand eScience Infrastructure, a SLURM HPC
cluster) and in R.

| File | What it is |
| --- | --- |
| `README.md` | The router. Sends a reader to the right document and lists tool versions. |
| `SOP_EMU_NeSI.md` | Nanopore full-length 16S → count tables. The only document that teaches the cluster. Titled "Part 1". |
| `SOP_CONCOMPRA_NeSI.md` | Consensus OTUs from the same Nanopore data. Assumes the EMU document's cluster section. |
| `SOP_READBASED_NeSI.md` | Illumina shotgun, read-based taxonomy and function. Governance-heavy. |
| `SOP_ASSEMBLY_NeSI.md` | Illumina shotgun → assembled MAGs. **v0.1, never reviewed.** |
| `SOP_R_Analysis.md` | Count tables → results, in R. Titled "Part 2". The longest document. |
| `TUTORIAL_SPEC.md` | The contract every SOP is meant to meet. |

**Check the current line counts, versions and dates yourself. Do not trust a
length, a version, or a count quoted anywhere — including here, including in the
README, including in the prior reviews.** A count being wrong is one of the
things you are here to find.

## What this review is for

The standard is not "is this document correct" and not "can a beginner follow
it" — both have been judged. The standard is: **could the lab hand this
repository to a new student tomorrow and walk away?** A product that ships is
internally consistent about what it is, resolves every promise it makes to the
reader, renders for anyone who clones it, and reads as one manual with one voice
and one set of conventions — not five files that happen to share a folder.

## Who the reader is

Not you. The lab's next new student: a graduate student who has never opened a
terminal, who clones the repository cold with no context, and who trusts every
word because they cannot tell a wrong one from a right one. They read the README
first. They follow its links. When a document says "see Part 2, Section 13" they
go looking for Part 2, Section 13, and if it is not there they stop. When a
figure does not load they assume they broke something. **A promise the suite
makes and does not keep is, to this reader, indistinguishable from their own
mistake** — and that is the failure mode this review outranks everything else to
prevent.

## You are on the cluster. Use it.

Your environment is not the reader's environment, but this review's claims are
mostly checkable and you must check them:

- **A cross-reference either resolves or it does not.** "See Section 13" is
  `CONFIRMED` true or `CONFIRMED` false the moment you search the target
  document for a Section 13. There is no "I think this is broken."
- **A figure either renders or it does not.** A local path either exists on disk
  or it does not (`ls` it). A remote URL either returns an image or it does not
  (`curl -sI` it) — and even a `200` is a finding if the asset lives outside the
  repository, because it will not survive a clone offline.
- **A module either loads or it does not.** The assembly document names roughly
  fifteen modules no earlier round probed. `module load` each one and record the
  result. Do not mark a module fine because its name looks plausible.
- **A script either exists at the path claimed or it does not.** `ls` it.

The four "never" rules the sibling reviews carry apply here too: do not propose
moving the R work onto the cluster; do not mark an install step redundant
because your session already has the tool; do not treat a module that loads for
you as proof it is pinned correctly for the reader; do not simplify a path or a
quota you cannot see.

## What is already settled — do not re-file

**Read these before you file anything:**

- `reviews/00_SYNTHESIS.md` and `reviews/00_ENVIRONMENT.md` — the correctness
  round, run on the cluster.
- `reviews/structure/00_PLAN.md` and `reviews/structure/00_REALITY.md` — the
  tutorial/structure round.
- The per-document reports beside them.

Everything filed there is **closed.** You do not re-raise it, re-word it, or
re-rank it. The compact list of what those rounds already own:

- **Correctness / silent failure** — wrong-but-plausible or silently-empty
  output. (`pairwise.adonis2` dropping `p.adjust.m`; CONCOMPRA sourcing a path
  list as config; READBASED's `head -1` grabbing a comment line; module-load
  gaps; re-run guards.) **Not yours.**
- **Cross-document *content* consistency already filed** — the canonical SLURM
  header mandate, the Emu Option-A/B filename hardcode, retention-value vs
  worked-example mismatches, placeholder-and-naming rules. **Not yours** *as
  already stated* — but see the regression rule below.
- **Pedagogy / teaching order** — define-before-use for `phyloseq`, CLR,
  Aitchison, "compositional", "chimera", "conda"; missing "understanding your
  data" layer; per-step runtime and success checkpoints. **Not yours.**
- **Voice / scannability** — paragraphs over 80 words, banned-word sweeps, `we`
  vs `you` discipline, heading-weight for optional side-paths. **Not yours.**

**Three things that look like re-filing but are not, and are squarely yours:**

1. **A prior fix that did not land, or landed wrong.** The structure round's
   rewrites were *applied*. If a finding was marked fixed and the fix is not in
   the document, or was applied to one document and not its twin, that is a new
   defect — a **regression** — not a re-file. Verifying the rewrites landed is
   your job.
2. **The same class of defect in the un-reviewed document.**
   `SOP_ASSEMBLY_NeSI.md` was never reviewed, so nothing in it is settled.
3. **A seam the prior rounds left open on purpose.** Their "open questions for
   the lab" and "deferred" and "NOT-VERIFIABLE-HERE" items (image hosting on
   `github.com/user-attachments`, the missing `LICENSE`, Emu Option A vs B
   billing, the "four documents" language) are *not closed*. Where one blocks
   shipping, it is yours to raise as a ship-gate, crediting the round that first
   noted it.

## Straightforwardness, not brevity

The target is a suite that is **straightforward**, not one that is **short**. A
document made shorter but left contradicting its neighbour has got worse, not
better. The following is load-bearing; removing it is a regression, and
proposing to remove it is itself a defect in your report:

1. **Justification for a threshold, parameter, cutoff or tool choice** — the
   "why this number" paragraphs.
2. **Warnings about silent failure.**
3. **Expected output** — what a step should produce.
4. **Primary literature citations** backing a methodological choice.
5. **Scope limits** — what a workflow does not cover, and who it is not for.
6. **Governance, ethics and human-data handling** content.
7. Anything explaining a concept the stated audience genuinely lacks.

Where a load-bearing passage genuinely rambles, the verdict is **REWRITE
TIGHTER** and you supply the tighter version, carrying the whole reason across.
**Never CUT.**

## The three lenses

Every finding you file sits in one of three lenses. Name it (it is the `Type`
field). If a finding fits none of them, it is probably a correctness or tutorial
finding and belongs to a sibling review, not this one.

- **CONTENT** — the suite promises the reader something and does not deliver it,
  or ships something no one cleared. A cross-reference to nothing. A figure that
  will not load. A section added after the reviews that no round has seen. A
  missing `LICENSE` the README points at. A "how to cite" or data-availability
  statement a publishable protocol needs and lacks. An appendix named in the
  back-matter that is not there.
- **LAYOUT** — how a document presents and navigates. Heading hierarchy and
  granularity, tables versus prose, code-block and copy-paste hygiene, figure
  and caption discipline, back-matter ordering, document length and where a
  1400-line file should be split, the presence or absence of a table of
  contents.
- **COHERENCE** — whether the five read as one manual. One version scheme, one
  count of documents, one "Part N" logic that scales, one figure strategy, one
  home and one name for the troubleshooting section, one voice, one house style.
  This is the lens the two siblings structurally could not use, and where most
  of your S1 and S2 findings will live.

## Evidence rules

1. **Every finding quotes the text it is about, verbatim, with a heading and a
   search string.** No quote, no finding.
2. **Check what you can check.** A cross-reference, a figure path, a module, a
   script name are all checkable in seconds. `NOT-VERIFIABLE-HERE` on something
   you could have run in ten seconds is a defect in your report.
3. **Internal and cross-document contradiction is your strongest evidence type
   and costs nothing to find.** Two documents disagreeing about the same fact,
   or a document disagreeing with the README, is the heart of this review. Hunt
   for it deliberately.
4. **Before reporting anything absent, search the whole document — and, for a
   cross-reference, the whole target document — for it.** Most false "missing X"
   findings are X present under a heading you did not expect.
5. **Do not invent severity to fill a tier.** An empty S1 list is a legitimate
   result and will be believed. A padded one destroys the report's usefulness.
6. If you disagree with a documented choice on grounds the lab should weigh,
   raise it as an explicit `CHALLENGE` with reasoning — do not silently rewrite
   it. The lab decides; you argue.
7. **Read the whole file before writing a single finding.**
8. **The prior reports' line numbers are stale.** Read files in a way that gives
   you *current* line numbers, quote them accurately, and never cite a line
   number out of an old report without re-finding the text first.

### Anchors

Every finding carries an `Anchor` field: a short, unique, literal string from
the target text that `grep -F` finds exactly once. Line numbers go stale the
moment anyone edits — and in this suite they already have — anchors do not.
Check uniqueness before you write it down:

```bash
grep -cF 'your anchor string' SOP_EMU_NeSI.md   # must print 1
```

For a cross-reference finding, the anchor is the *pointer* (the "see Section 13"
string in the document that makes the promise), and the `Evidence` field records
what you found — or did not find — in the target.

## Output contract

### The finding block

```
### C-07 · S1 · README routes reader to Section 13 that no longer exists
- **Where:** README.md, § Routing table (lines 28-31)
- **Anchor:** `read-based SOP's Section 13`
- **Quote:**
  > For the statistics that change with shotgun data, see the read-based
  > SOP's Section 13.
- **Defect:** One sentence. What is wrong as a product, stated flatly.
- **Impact:** Reader does X → reaches Y → is stranded / misled / cannot ship.
  One concrete path through the suite, no hedging.
- **Type:** CONTENT | LAYOUT | COHERENCE
- **Confidence:** CONFIRMED | VERIFIED | NOT-VERIFIABLE-HERE
- **Evidence:** The contradiction between two files, or the command you ran and
  its output (the `grep` on the target, the `ls` on the path, the `curl -sI` on
  the URL), or the check that would settle it and its cost. One of the three,
  always.
- **Fix:** Paste-ready replacement text. For a coherence finding that touches
  several files, name every file the fix edits.
```

All nine fields, in that order, on every finding, whatever its severity.

**Field rules.**

- **ID** — `C-01` upward, unique within the report, never reused.
- **Order** — S1 first, then S2, S3, S4. Within a tier, document order.
- **Summary** — the heading text after the severity, **90 characters or
  fewer**, stating the *defect* not the topic.
- **Where** — `FILENAME, § Heading (lines N-M)`. The heading is the durable
  half; the line range is your own current read, not a prior report's. A
  coherence finding that spans files names **every** file in `Where`.
- **Anchor** — a unique `grep -F` string, verified to match exactly once.
- **Quote** — verbatim, blockquoted. Elide with `…` mid-line only, never across
  the part carrying the defect.
- **Impact** — if you cannot write this line concretely — this reader, this
  path, this wrong outcome — the finding is not real. Delete it.
- **Fix** — for S1 and S2, the actual replacement text, ready to paste. Every
  fix must be independently applicable: no "see C-03". If two findings share one
  fix, they are one finding.

### Severity

Four levels, S1 worst. The ladder and the S4 cap are fixed; the meanings are
this review's.

- **S1 — Ship-blocker.** The suite cannot go to a new student in this state. A
  cross-reference that resolves to nothing. A figure that will not render for
  someone who cloned the repository. A README claim that is false about the
  current suite. A member document that no one has reviewed going out labelled
  as ready. Content the reader is promised and cannot reach.
- **S2 — Incoherence the reader will hit.** The five contradict each other as a
  set and the reader notices: five version numbers and no suite version, "four
  documents" in a five-document suite, three figure strategies, a "Part 1 /
  Part 2" scheme that no longer describes four-upstream-into-one. They can
  proceed, but the suite reads as five files, not one manual.
- **S3 — Navigation or polish that costs real time.** No table of contents in a
  1000-line document. Heading granularity that lurches between documents. An
  orphaned asset. A back-matter appendix lettering that skips B. Recoverable,
  but it costs the reader.
- **S4 — Cosmetic.** Register, a stray heading style, a formatting nit with no
  reader consequence. **Cap: 15.** Beyond that, merge into one omnibus entry.

Do not invent severity to fill a tier. An empty S1 list is a legitimate result.

### Confidence

| Level | Means | Requires |
| --- | --- | --- |
| `CONFIRMED` | Provable from the text, or from one file contradicting another | The contradiction, quoted from both sides |
| `VERIFIED` | You ran a probe — `grep` on a target, `ls` on a path, `curl -sI` on a URL, `module load` — and it settled the question | The exact command and its exact output, quoted |
| `NOT-VERIFIABLE-HERE` | Needs real data, a long run, or something you should not do | The single check that would settle it, and its rough cost |

**There is no fourth level, and "I believe this is broken" is not a finding.**
If you can check it, check it. An unchecked claim about the world, in a session
that could have checked it, is worse than not raising it at all.

### Self-check

End your report by running this over it and pasting the output. A report that
does not print `CLEAN` is re-run, not worked from.

```bash
python3 - "$OUTPUT" <<'PY'
import re, subprocess, sys
p = sys.argv[1]
t = open(p).read()
blocks = re.split(r'\n(?=### C-)', t)
blocks = [b for b in blocks if b.startswith('### C-')]
fields = ['**Where:**','**Anchor:**','**Quote:**','**Defect:**','**Impact:**',
          '**Type:**','**Confidence:**','**Evidence:**','**Fix:**']
sev_order = {'S1':1,'S2':2,'S3':3,'S4':4}
bad = []
last = 0
s4 = 0
for b in blocks:
    h = b.splitlines()[0]
    m = re.match(r'### (C-\d+) · (S[1-4]) · (.+)', h)
    if not m:
        bad.append(f'malformed header: {h}'); continue
    cid, sev, summ = m.groups()
    if len(summ) > 90:
        bad.append(f'{cid}: summary {len(summ)} chars > 90')
    if sev_order[sev] < last:
        bad.append(f'{cid}: severity {sev} out of order')
    last = sev_order[sev]
    if sev == 'S4':
        s4 += 1
    idx = -1
    for f in fields:
        j = b.find(f)
        if j == -1:
            bad.append(f'{cid}: missing {f}')
        elif j < idx:
            bad.append(f'{cid}: {f} out of order')
        else:
            idx = j
    am = re.search(r'\*\*Anchor:\*\* `(.+?)`', b)
    if am:
        anc = am.group(1)
        wm = re.search(r'\*\*Where:\*\* (\S+)', b)
        fn = wm.group(1).rstrip(',') if wm else ''
        if fn and '/' not in fn:
            n = subprocess.run(['grep','-cF',anc,fn],capture_output=True,text=True).stdout.strip()
            if n != '1':
                bad.append(f'{cid}: anchor matches {n}x in {fn} (want 1)')
    else:
        bad.append(f'{cid}: no parseable anchor')
if s4 > 15:
    bad.append(f'S4 count {s4} > cap 15')
s1 = sum(1 for b in blocks if ' · S1 · ' in b.splitlines()[0])
s2 = sum(1 for b in blocks if ' · S2 · ' in b.splitlines()[0])
print(f'findings={len(blocks)} S1={s1} S2={s2} S4={s4}')
print('\n'.join(bad) if bad else 'CLEAN')
PY
```

### Calibration

A real finding from the input work, formatted to the contract. It is a genuine
class of capstone defect; use it to calibrate the field, not to re-find (if it
is still open, it is fair game; if it has been fixed, re-finding it is not a
result).

```
### C-00 · S2 · Suite carries five version numbers and no version of itself
- **Where:** README.md, § footer; and the header of each SOP
- **Anchor:** `second review round`
- **Quote:**
  > All four SOPs and this README were checked in the second review round,
  > July 2026.
- **Defect:** The five documents are versioned independently (EMU v2.0,
  CONCOMPRA v2.1, READBASED v3.0, R_Analysis v2.1, ASSEMBLY v0.1) and the README
  footer states a suite state ("four SOPs", "July 2026") that is now false.
- **Impact:** A reader cannot tell what release they hold or whether it is
  current; a maintainer cannot cite "the suite as of date X". The count is
  wrong the moment the fifth SOP exists.
- **Type:** COHERENCE
- **Confidence:** CONFIRMED
- **Evidence:** Five distinct `Version:` strings across the five headers;
  README footer says "four SOPs"; `ls` shows five `SOP_*.md`.
- **Fix:** Add a single suite version and date to the README header, and a
  one-line suite changelog. Replace the footer's "four SOPs … July 2026" with
  the current count and date. (Paste-ready text supplied in the full finding.)
```

---

# AGENT PROMPT 0 — product-integrity probe

You run before every other agent. Your output is a facts file the whole review
reads, so it must be right and it must be complete. You do not file findings and
you do not judge quality — you establish what resolves and what does not, so the
later agents argue from fact.

## What to establish

1. **Every cross-reference resolves.** Sweep all five SOPs and the README for
   pointers: "Part 1", "Part 2", "Section N", "Appendix X", "see the … SOP",
   "step N", and references to another document by name. For each, go to the
   target and record whether the named section, appendix or document exists
   **with that number and heading today** — after the renumber the structure
   round applied. A pointer to a section that moved is the highest-value thing
   you can find; find them all.

2. **Every figure and asset renders.** Find every embedded image across the
   suite — markdown `![...]()`, HTML `<img>`, both. For a local path, `ls` it and
   record present/absent. For a remote URL (`github.com/user-attachments` and
   the like), `curl -sI` it, record the status, and record separately that it
   lives outside the repository and will not survive an offline clone. Also list
   every asset on disk under `examples/` that **no** document references — the
   orphans.

3. **Every referenced script exists.** For each script name a document tells the
   reader to run or create, record whether a file of that name exists at the
   claimed path (`ls`), and whether the defining section number matches the
   script name.

4. **The assembly modules.** `SOP_ASSEMBLY_NeSI.md` names roughly fifteen
   modules no prior round probed (MEGAHIT, SPAdes, QUAST, MetaBAT, MaxBin,
   CONCOCT, DAS_Tool, CheckM2, dRep, GTDB-Tk, bakta, CoverM, eggnog-mapper,
   DRAM, and any others in the document). `module load` each exact string and
   record `HOLDS` / `DRIFTED` (loads under a different version) / `FALSE` (no
   such module) / `UNREACHABLE`.

5. **The suite's stated facts.** Record the actual line count, `Version:` string
   and date of each of the five SOPs, the README's stated document count, and
   the spec's stated document count. These are inputs to the coherence findings;
   get them exact.

## Rules

Probe, do not judge. "Section 13 does not exist in the read-based SOP" is your
job; "this is an S1" is Agent A's or B's. Record the command and its output for
everything. Where a check needs data or a run you should not do, say so and give
its cost. Use the verdict vocabulary above (`HOLDS`/`DRIFTED`/`FALSE`/
`UNREACHABLE`) and, for references, `RESOLVES`/`BROKEN`/`MOVED`.

## Report skeleton

Exactly these sections, in this order, nothing before or after.

```
## What I loaded and ran
## Cross-reference resolution
## Figure and asset existence
## Referenced scripts
## Assembly modules
## Suite facts — counts, versions, dates
## Absent, drifted or unreachable
```

---

# AGENT PROMPT A — per-document capstone review

You are reviewing **one** document, `{{FILE}}`, as a shippable member of a
five-document suite. Read the COMMON BRIEF first, then the settled-list and the
prior reports, then Agent Prompt 0's facts file, then `{{FILE}}` in full. Write
to `{{OUTPUT}}`. Do not read the other SOPs and do not read another Agent A's
report.

Your question is not "is this correct" and not "can a beginner follow it" —
those are judged. Your question is: **if the lab shipped this repository
tomorrow, is this document ready to be in it?**

### Pass 1 — First-contact integrity

Read as the new student who just cloned the repository. Using Agent 0's facts:
does every cross-reference this document makes resolve? Does every figure render?
Does every script it names exist? Is the version and date current and consistent
with the document's own body? Every broken promise the document makes to the
reader is a finding — most will be S1.

### Pass 2 — Content at the seam of shipping

Not the correctness pass — that is settled. This is: what does treating the file
as a *finished deliverable* expose that reading it as a draft did not? Sections
added after the reviews that no round cleared (name them; they need review before
ship). A back-matter appendix promised and absent. A missing `LICENSE`, "how to
cite", or data-availability statement a publishable protocol needs. A load-bearing
warning or scope limit that the rewrite dropped (a **regression** — check the
keep lists in the prior reports). State each gap and what the reader loses.

### Pass 3 — Layout and presentation

Heading hierarchy and granularity. Whether a 1000-plus-line document has any way
to navigate it. Tables versus prose where the sibling reviews did not already
rule. Code-block and copy-paste hygiene. Figure and caption discipline —
numbering, captions, alt text, and whether "no figures at all" is a gap for a
document with obviously plottable output. Back-matter ordering and lettering.
Where the document is long enough to split, say where. Judge against the suite's
house style where one exists and flag divergence where it does not — Agent B
will set the standard; you supply the evidence.

### Assembly supplement — `SOP_ASSEMBLY_NeSI.md` only

This document was reviewed by no one. In addition to the three passes above:

- **Sanity-sweep correctness and safety** at the depth you can reach without
  building a full fixture: obvious wrong-result-that-looks-right, destructive
  operations, missing module loads (cross-check Agent 0), re-run guards,
  write-name-versus-read-name mismatches. File what you find; these are real S1s.
- **Sanity-sweep teachability**: define-before-use for the assembly and binning
  vocabulary, missing per-step runtime and success checkpoints on the heavy
  steps.
- **Check the audience contract.** The document requires the reader to have run
  a NeSI pipeline before. `TUTORIAL_SPEC.md` withdraws exactly that assumption.
  Raise the conflict.
- **End with a release recommendation:** does this document need a full run of
  `SOP_REVIEW_PROMPT.md` and `SOP_TUTORIAL_PROMPT.md` before it ships, or is a
  capstone pass enough? Say which, and why. Be honest — a single capstone pass
  is not a substitute for the two dedicated rounds the other four received.

### Report skeleton

Exactly these sections, in this order.

```
## Document: {{FILE}}
## Section ledger
## Findings
## Verified against the suite
## Regressions — prior fixes that did not land
## Keep list
## Divergence from the set
## Release recommendation
```

- **Section ledger** — a `| § | Heading | Lines | Treatment | Findings |` table
  covering every heading in the document. Treatment vocabulary:
  `CLEAN ADD-NAV RENUMBER RELABEL SPLIT MERGE FIX-REF FIX-FIGURE REWRITE-TIGHTER`.
- **Verified against the suite** — the probes you ran and their output.
- **Regressions** — anything a prior report marked fixed that is not in the
  document, or was applied unevenly. Cite the prior finding.
- **Keep list** — anchored, fewer than ten, the load-bearing passages a rewrite
  must not lose. This is the regression test for Stage 4.
- **Divergence from the set** — where this document's conventions (version
  scheme, figure strategy, troubleshooting placement, heading granularity)
  differ from what a single manual would use. Raw material for Agent B.
- **Release recommendation** — one paragraph. For the four reviewed documents:
  ready / ready-with-listed-fixes / not-ready. For assembly: the fuller
  recommendation above.

End with the self-check output and `CONTRACT: PASS`.

---

# AGENT PROMPT B — the set as one product, and the ship verdict

You are the only agent that sees the whole repository. Read the COMMON BRIEF,
the prior reports, Agent 0's facts file, all five Agent A reports, and all five
source documents. De-duplicate findings across the five reports keeping every
anchor, re-rank severity **globally** (a cross-file operation the per-document
agents cannot do), resolve conflicts, and produce one plan and one verdict.

## Job 1 — The set as one manual

Treat the five as chapters of one book and find every place they disagree about
what they are:

- **Version and identity.** One suite version, or five? Is there a single date
  and changelog? Is the README's document count right?
- **The "Part N" scheme.** EMU is "Part 1", R_Analysis is "Part 2". Four
  documents now feed the R analysis. Does the label scheme still describe the
  pipeline, or has it broken? Propose the scheme that scales to five.
- **Figures.** Three strategies across five documents (remote-hosted, local,
  none). Name the one strategy the suite should adopt, the caption and numbering
  convention, and what each document must change to reach it. Fold in the prior
  round's deferred image-hosting item.
- **Troubleshooting.** Three names and three positions for the same section
  across the suite. Pick one home and one name.
- **Navigation.** Which documents are long enough to need a table of contents,
  and what the suite's navigation convention should be.
- **Heading granularity.** Top-level section counts range from four to sixteen
  across the set. Say what a reader moving between documents should be able to
  assume, and which documents are outliers.
- **README fidelity.** Every claim the README makes about the suite, checked
  against the suite. Where it is false, the replacement text.
- **The spec.** `TUTORIAL_SPEC.md` still describes "four documents" and an
  audience contract the assembly document violates. Reconcile them.

## Job 2 — The verdict and the plan

- **The ship verdict** is one of exactly three values: **SHIP**,
  **SHIP-WITH-FIXES**, **NOT-READY**. State it, then list the S1 findings that
  justify it. If any member document is unreviewed and unverified, the suite is
  at best SHIP-WITH-FIXES and the assembly document's status is named
  explicitly.
- **The work plan** is sequenced, ship-blockers first, with the files each item
  edits, the findings it closes, a size, and its dependencies. Mark what can run
  in parallel.
- **Reconcile with reviews 1 and 2.** List what they left open or deferred that
  bears on shipping, and confirm what this review deliberately did not re-file.
- **Convention decisions** — the house-style calls (one version scheme, one
  figure strategy, one troubleshooting home, TOC policy). Options and a
  recommendation, then stop; the lab decides.

## Report skeleton

Exactly these sections, in this order.

```
## State of the suite
## The ship verdict
## Ship-blockers
## Suite-coherence findings
## Cross-reference integrity table
## Figure and asset audit
## Presentation and navigation decisions
## Convention decisions
## Reconciliation with reviews 1 and 2
## Assembly SOP — release gate
## Consolidated keep list
## Work plan
## Open questions for the lab
```

- **State of the suite** — a table: the five documents, their line counts,
  versions, dates, and which reviews (correctness / tutorial / this one) have
  seen each. This is where "assembly has had only this review" is made visible.
- **Cross-reference integrity table** — every inter-document, section, appendix
  and script reference and whether it resolves, from Agent 0 plus the A reports.
- **Assembly SOP — release gate** — its own status and the recommendation on
  whether it needs the two sibling prompts before ship.
- **Open questions for the lab** — options and a recommendation, then stop.

End with the self-check output and `CONTRACT: PASS`.

---

# ACCEPTANCE CHECKS

Run these as scripts at Stage 3. Read-by-eye will not catch a missing field or a
short ledger; it did not in the earlier rounds. A report failing these is
re-run, not worked from.

1. **Contract compliance.** Run every report's embedded self-check. Each must
   print `CLEAN` and carry `CONTRACT: PASS`.

2. **Ledger completeness.** For each Agent A report, count the section-ledger
   rows against the number of headings in the source document (fence-aware, so
   `#` inside code blocks does not count). A ledger with fewer rows than the
   document has headings gets `<-- SHORT`; investigate before using the report.

3. **Cross-reference coverage.** Grep the five SOPs and the README for the
   reference patterns (`Part [12]`, `Section \d`, `Appendix [A-Z]`, `see the .*
   SOP`). Every hit must appear as a row in Agent B's cross-reference integrity
   table. A pointer in the suite that is absent from the table means the sweep
   missed it.

4. **Figure coverage.** Grep for every `!\[` and `<img` across the suite. Every
   one must appear in Agent B's figure-and-asset audit with a rendered / absent
   / remote verdict.

5. **Verdict validity.** Agent B's ship verdict is exactly one of `SHIP`,
   `SHIP-WITH-FIXES`, `NOT-READY`, and if any document is marked unreviewed the
   verdict is not `SHIP`.

6. **No re-filing.** Spot-check five findings against the settled-list and the
   prior reports. A finding that restates a closed correctness or tutorial
   finding — rather than a regression, an assembly-only defect, or an
   open/deferred seam — is struck, and the report is re-run.

**The tell for a skimmed report** is a long S4 list beside a thin S1 list, a
cross-reference table shorter than the number of "Section N" strings in the
suite, or a figure audit that does not mention the remote-hosted EMU images.

---

# NOTES — why this review exists, and what it does not do

- **It exists** because two rounds reviewed documents and no round reviewed the
  product. Each document can be correct and teachable while the suite still
  ships with a broken cross-reference, five version numbers, and an unreviewed
  member. That gap is between the files, and only a whole-suite pass sees it.
- **It consumes, it does not repeat.** Every correctness and teaching-order
  finding the two rounds filed is settled. This review reads them so it can stay
  off them, and earns its keep only on the seams, the drift, and the gaps they
  could not reach.
- **It does not substitute for a correctness run on the assembly document.** A
  single capstone pass is not the on-cluster, fixture-building scrutiny the other
  four documents received. Where the assembly document needs that, this review
  says so and stops short of pretending to have done it.
- **It is v1.** If it is run again after a rewrite, add a changelog in the format
  the correctness prompt uses: each change, and what in this run motivated it.
