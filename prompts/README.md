# Prompts

Two review prompts. They do different jobs and should not be run at the same
time. Each is self-contained: open a session on NeSI, `cd` into the repository,
and tell the assistant to read the one you want and run it.

| Prompt | Asks | Run it when |
| --- | --- | --- |
| [`SOP_TUTORIAL_PROMPT.md`](SOP_TUTORIAL_PROMPT.md) | *Can a first-time reader follow this?* Structure, teaching order, voice. | **Now.** Three of the four documents are runbooks addressed to someone who already knows the tools. |
| [`SOP_REVIEW_PROMPT.md`](SOP_REVIEW_PROMPT.md) | *Can this produce a wrong result that looks right?* Correctness, silent failure, consistency. | **Already run**, on NeSI Mahuika, 2026-07-31. Outputs in `reviews/`. Run it again after the tutorial conversion, to re-check the rewritten documents. |

## Where the outputs go

- `reviews/v1/` — the first correctness round, run without a cluster. Read-only history.
- `reviews/` — the second correctness round, run on NeSI. Read-only history.
- `reviews/structure/` — the tutorial conversion round (`SOP_TUTORIAL_PROMPT.md`). Not yet run.

Nothing outside the relevant output directory is edited during a review. The
SOPs stay read-only until a plan is approved.

## Still open

The sixteen `NEEDS-BENCH-CHECK` items from the first round were settled by the
second, on the cluster. See [`../reviews/00_ENVIRONMENT.md`](../reviews/00_ENVIRONMENT.md)
for what was probed and what it found. The headline result: **`pairwise.adonis2()`
has no `p.adjust.m` argument**, so Part 2's claim that the line applied
Benjamini-Hochberg correction was false. That is fixed.

Anything still open from that round is in
[`../reviews/00_SYNTHESIS.md`](../reviews/00_SYNTHESIS.md).

**Image hosting.** The four images in `SOP_EMU_NeSI.md` are hosted on
`github.com/user-attachments`, not committed to this repository, so they do not
survive a clone, a fork or offline reading. Moving them to `docs/img/` and
referencing them relatively is a small self-contained job. Deliberately out of
scope for both reviews.
