# Tutorial Specification

What every SOP in this repository should be. Written for whoever rewrites one,
reviews one, or adds a new one.

Rules are numbered so they can be cited. `R` rules govern content, `F` rules
govern the page, `V` rules govern voice. Where a rule was derived by measuring
`SOP_EMU_NeSI.md`, the measurement is given — these are not preferences.

---

## 1. Who these are for

**A graduate student who has never opened a terminal.** One reader, all four
documents.

This overrides what a document says about itself. `SOP_READBASED_NeSI.md`
currently claims prior pipeline experience; that assumption is withdrawn.
Someone who followed one pipeline six months ago does not thereby know what PhiX
is or why `ktrim=r` matters.

They are running real data, under time pressure, often alone, and **they cannot
tell a wrong answer from a right one.** Everything below follows from that.

Assume they have ADHD, because some do and the rest are tired. They scan before
they read, and they lose the thread and re-enter halfway down.

---

## 2. What a tutorial is here

Two layers of explanation. They are not interchangeable, and most defects in
this repository are one present without the other.

| Layer | Answers | For a reader who | Length |
| --- | --- | --- | --- |
| **1** | *What is this thing?* | has never met it | ~100 words, or one sentence for a tool |
| **2** | *Why this value, this tool?* | knows the options | a bullet or a bold run-in |

Measured across the four documents by heading type:

| Document | Layer-1 headings | Layer-2 headings | Action headings |
| --- | --- | --- | --- |
| `SOP_EMU_NeSI.md` | **12** | 1 *(mostly inline)* | 17 |
| `SOP_READBASED_NeSI.md` | 2 | **5** | 42 |
| `SOP_CONCOMPRA_NeSI.md` | **0** | **0** | 45 |
| `SOP_R_Analysis.md` | 1 | 1 | 19 |
| `README.md` | 1 | 0 | 6 |

`SOP_EMU_NeSI.md` is the pattern. It is not exempt from this spec — it still
carries six paragraphs over the form limit.

These counts survived a full correctness round, which tightened the prose
considerably without moving the heading balance. That is the point: the missing
layer is structural, and no amount of editing sentences adds it.

---

## 3. Document template

```
*Taylor Lab | <one-line descriptor>*
# **<Title>**
**vN.N** | last updated <Month Year> | <environment> | <data type>

<One paragraph: what this does, what it produces.>

### Before you start
  - what you need
  - what this does not cover
  - where to go first if you lack the prerequisites

## Quick roadmap            ASCII block, stages in run order
## 1. Understanding your data     concepts only, no commands
## 2. …n  numbered steps in the order performed
## Troubleshooting
## Appendices                references, resource tables, provenance
```

Reference material lives at the back. Nothing that is looked up rather than
performed belongs in the walkthrough.

---

## 4. Step template

Every action step, in this order:

1. **What it does** — one or two sentences, plain words.
2. **Why** — the parameter reasoning, skippable (V4).
3. **The command** — complete and runnable (R11).
4. **How long it takes** — an order of magnitude. Seconds, minutes, hours.
5. **The checkpoint** — see below.

Item 5 is not optional. A command with no success criterion is a defect however
correct the command is. Item 4 costs six words and stops the reader wondering
whether the job has hung.

### The checkpoint block

One or two lines the reader can run, with the expected answer and the meaning of
a mismatch. Three parts, always:

```bash
ls -1 filtered/*.fastq | wc -l
```

> **Expect** the same number as your barcode sheet. **Fewer** means a barcode was
> dropped at import — go back to Step 1 and check the loop's warnings.

Command, expected value, what a mismatch means. Without the third part the
reader knows something is wrong and not what to do, which is where they stop.

---

## 5. Content rules

**R1 — Both layers, in order.** Layer 1 before the first command; layer 2 beside
the parameter it justifies. Layer 2 without layer 1 is the commonest defect
here.

**R2 — Nothing is used before it is introduced.** First appearance of any term,
tool, format, flag or abbreviation carries its definition. Real offenders:
`PhiX`, `ktrim`, `chimera`, `CPM`, `stratified`, `rCLR`, `prevalence method`.

**R3 — Concepts before commands.** A section introducing new science or tooling
opens with prose carrying no commands. EMU has ten such subsections; a document
with none is a runbook.

**R4 — Setup happens where it is needed.** No front-loaded block of environment
checks. Module loads, downloads, quota checks and directory creation appear at
the first step that needs them, where failure is legible.

Storage layout and quota planning are the exception — they cannot be undone
later — but they go in prose and a table, not a shell block.

**R5 — Every step states its outcome.** See §4.

**R6 — One numbered spine.** Sections numbered from 1 in performance order.
Sub-steps numbered within. Script filenames carry their section number
(`05a.qc_fastqc.sl`). A bare section number always means the current document; a
cross-document reference names the file.

**R7 — Every fork has a default.** One option named as the default, with the
reason. A reader must never stop to research something before continuing.

**R8 — Plain words first, jargon second.** *"artificial hybrids formed during PCR
when an incomplete amplicon primes another species' template"* → then
**chimeras**. Never the term alone.

**R9 — One voice.** See §7.

**R10 — Explain the failure, not just the action.** Where a step can go wrong
silently, say so where it can be acted on. This is the strongest content in the
set and must not thin.

**R11 — Every script is complete and runnable as shown.** Shebang, every
`#SBATCH` directive with its real value, `set -euo pipefail`, array boilerplate
where relevant. The reader copies one block, substitutes placeholders, submits.

No "add the header yourself". A completeness scan of the current set finds 7 of
8 job blocks in `SOP_READBASED_NeSI.md` missing shebang, account, time and
`set -euo pipefail`, six of them using `$SAMPLE` — which the omitted header is
what assigns. Copy one as printed and MetaPhlAn silently profiles
`clean/_R1.fastq.gz`. EMU is 5 of 6 complete and CONCOMPRA 2 of 2, so this is
one document's problem.

The cost is duplication, and duplication drifts. Accepted: a header wrong in one
script is one bad job; a header the reader forgets is a silent wrong result.

---

## 6. Form rules

**F1 — No paragraph over 80 words.** Median about 30, which is where these
documents now sit. Over 80: split, bullet, or table it. Current counts — EMU 6,
R_Analysis 6, CONCOMPRA 2, READBASED 1, README 0. The longest is 101 words.

**F2 — A definition is one or two sentences.** If it needs more, it is a concept
section under R3, not a swelling paragraph.

**F3 — Anything enumerable becomes a table or a list.** Thresholds, options, file
inventories, resource figures, expected outputs, failure modes. Prose listing
three or more things of a kind is an unwritten table.

**F4 — The point comes first.** First sentence of every block carries the
operative fact. Bold what a scanner needs: the parameter, the number, the
failure. Someone reading only first sentences and bold text should still get it
right.

**F5 — The "why" is separable.** Layer 2 goes where it can be skipped on the
first pass and found on the second. Never woven through an instruction so the
reader must parse justification to extract the action.

This is what protects the "why this number" content. Skippable, it survives;
buried inside an instruction, the next person tightening the document deletes
it.

---

## 7. Voice

**V1 — "You" for the reader, "we" for the lab.** `you` is what the reader does.
`we` is a Taylor Lab decision, and marks layer 2: *"We use SRS rather than
rarefying because…"*. Never `we` for a reader action, never `the user`, never
`one should`.

This is currently inconsistent — EMU uses `we` 19 times, READBASED zero. The
rule makes the distinction do work: `we chose` versus `you run`.

**V2 — Imperative for actions, present tense, second person.** *"Create the
directory"*, not *"the directory should be created"* or *"we will now create"*.

**V3 — No words that make a beginner feel stupid.** Banned: `simply`, `just`,
`obviously`, `of course`, `easy`, `easily`, `trivial`, `clearly`, `merely`, `as
you know`. If it were obvious the sentence would not be there. The set currently
has twelve instances; that is the number to beat.

**V4 — Warn by consequence, not by volume.** *"If you `rm` something on
nobackup, it is gone."* No exclamation marks, no ALL CAPS beyond a single bolded
clause, no stacked warnings. A document where everything is urgent has nothing
urgent.

**V5 — UK spelling.** `normalise`, `visualise`, `analyse`, `behaviour`.
Tool names and flags keep their own spelling.

**V6 — Say the thing.** No throat-clearing (*"It is worth noting that…"*), no
hedging on hedges, no sentence that restates the code beneath it.

---

## 8. Consistency across documents

Mechanical choices. One answer each, across all four files.

| Item | Decision |
| --- | --- |
| Placeholders | `<your_nesi_project_code>`, `<your_project>`, `<username>`, `<your_email>`, `<sample>`, `<job_id>`. Angle brackets, lowercase, underscores. |
| Code fences | Tagged `bash`, `r`, `python`. Never untagged, never `R`. |
| Commands vs output | Commands in a tagged fence. Output in a separate untagged fence, or a blockquote if short. Never mixed in one block. |
| Callouts | **Bold run-in** for emphasis inside a block. `>` blockquote reserved for a stop-and-read warning, at most a few per document. No other callout styles. |
| Headings | `## **N. Title**` for sections, `### **Title**` for subsections. Bold, title case. |
| SLURM directives | One style throughout — space-separated (`#SBATCH --time 02:00:00`). Arrays 1-based, real range set at submission (`sbatch --array=1-N%20`), never hard-coded. |
| Script names | `NN.name.sl` or `NN_name.sh`, number matching the section. Suffix `a`/`b` for several in one section. |
| Taxonomic ranks | `superkingdom, phylum, class, order, family, genus, species`, lowercase. Convert any pipeline that disagrees before Part 2. |
| phyloseq objects | `ps_raw`, `ps_srs`, `ps_relab`, `ps_estcounts`. The suffix names what it holds. |
| Sample IDs | One per sample, set upstream, never suffixed. Strip `_filtered`, `.CONCOMPRA`, `_Abundance-RPKs` where they are created. |
| Version line | `**vN.N** \| last updated <Month Year> \| …` under the title. |

---

## 9. Never cut

Removing any of this is a regression, and proposing to remove it is a defect in
a review report.

1. Justification for a threshold, parameter, cutoff or tool choice — the "why
   this number" content. This is the main value of these documents.
2. Warnings about silent failure.
3. Expected output, and how to tell a step failed.
4. Primary literature citations.
5. Scope limits — what a workflow does not cover, and who it is not for.
6. Governance, ethics and human-data handling.
7. Anything explaining a concept the reader genuinely lacks.

Where a why-this-number paragraph rambles, the verdict is **rewrite tighter**,
carrying the whole reason across. Never cut.

**Straightforward, not short.** A tutorial that is shorter but leaves the reader
guessing has got worse. Cut words, never content. If you cannot say it shorter,
say it in a table.

---

## 10. The README

`README.md` is a **router, not a tutorial**. Its job is to get a reader to the
right document in under a minute, and to tell them the few things that cannot be
discovered later. It teaches nothing.

So §3 (document template) and §4 (step template) do not apply to it. Everything
else does — the form rules especially, because it is the first page anyone sees.

A previous round already tightened it — median prose paragraph 34 words and
nothing over 80, the cleanest in the set on form. What remains is structural:
it still carries only one explanatory heading, and its claims about the SOPs
have to be re-verified every time a SOP changes.

**What it contains, in this order:**

| Section | Job | Limit |
| --- | --- | --- |
| What this is | One paragraph. What the repository covers, who it is for. | 60 words |
| Which SOP do I need? | The routing table. The single most important thing on the page. | table only |
| Before you start | What blocks you: account, storage, R. Not how to use them. | 3 short items |
| Tool versions | Module strings, with the drift warning. | table |
| Contributing | Points at this spec. Does not restate it. | 4 bullets |
| Citing | Grouped by document. | table or short list |

**Rules specific to it:**

- **N1 — The routing table comes first**, immediately after the opening
  paragraph. A reader who lands here and reads nothing else must still leave
  with the right filename.
- **N2 — It does not restate the conventions.** They live in this spec. Two
  copies drift, and the README's copy is the one that goes stale. Link, do not
  duplicate.
- **N3 — Every claim it makes about a SOP must be true of that SOP now.**
  Audience, contents, tool versions, storage figures, what is and is not
  covered. This is the commonest way the README rots.
- **N4 — Bullets are one sentence.** Under 30 words. A bullet needing more is a
  row in a table.

---

## 11. Checking

Three scans. Run them before claiming a document conforms.

**Heading census (§2).** Count layer-1, layer-2 and action headings. A document
with no layer-1 headings fails R1 and R3.

**Paragraph scan (F1).** Every paragraph over 80 words is a defect.

**Header completeness (R11).** Every job-script block must carry shebang,
`--account`, `--time` and `set -euo pipefail`, and must not use `$SAMPLE`
without assigning it.

Scripts for all three are in `prompts/SOP_TUTORIAL_PROMPT.md`. After any
rewrite, both of these must hold: the layer-1 heading count has gone **up**, and
the over-80-word paragraph count has not. Passing the first while failing the
second means the missing layer was added as more wall-of-text, which is the
specific way this rewrite fails.
