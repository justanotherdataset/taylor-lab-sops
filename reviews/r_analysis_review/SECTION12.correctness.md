## Document: SOP_R_Analysis.md — SCOPED SLICE (§12 Co-occurrence Networks + the 14-figure GlobalPatterns worked example in `examples/r_analysis/run_example.R`)

This is a scoped correctness pass, not a whole-document review. It covers exactly the content flagged by capstone C-10 as added after both prior review rounds and read by no correctness or tutorial reviewer: **Section 12 (SPIEC-EASI)** (SOP_R_Analysis.md:1256–1321) and the **worked-example apparatus** — `examples/r_analysis/run_example.R`, the 14 embedded figures, and their committed stats files. I read §12 four times (correctness / tutorial / structure / consistency), reproduced the §12 pipeline end-to-end on the committed example data, probed the `spiec.easi` signature against the installed SpiecEasi 1.99.0, and cross-checked every figure caption I could settle cheaply against the committed `*_stats`/`*.tsv` outputs.

**Verdict: the SPIEC-EASI code and parameters are sound and the figures are faithful — no S1, no S2.** The §12 pipeline reproduces the embedded figure's numbers *exactly* (50 nodes, 68 edges, 63+/5−, density 0.056), the StARS/CLR/conditional-dependency claims all hold against the installed package, the object discipline (raw counts to a self-CLR'ing method) is correct, and every checkable caption number (figs 07, 08, 11, 12) matches its committed stats file. What the pass turns up is a **false methodological claim** — "stable inference needs more samples than taxa" — that the section's own worked example (50 taxa on 20 samples) contradicts, plus three lower-severity accuracy/consistency slips inherited from the fact that `run_example.R` was written *before* §12 existed and never re-labelled. The single change that would most improve the slice: correct the "more samples than taxa" rationale (F-01), because it is the one place a reader is told something about the method that is not true.

The capstone-actioned items are correctly resolved in the current text: **C-18** (tuatara/GlobalPatterns split) is now stated at line 13; **C-21** (package count) now reads "four extra packages" at line 1264; and the figure numbering is now contiguous 01–14 with no orphan `14_core_microbiome.png` (C-05's disk-orphan concern is gone). C-10's cosmetic remainder — header still "last updated July 2026", no changelog — is unaddressed but is owned by the coherence/README track, not re-filed here.

## Section ledger

| § | Heading | Lines | Verdict | Findings |
|---|---|---|---|---|
| 12 | Co-occurrence Networks (optional) | 1256–1321 | REWRITE-TIGHTER | F-01, F-03, F-04 |
| — | Worked example — `run_example.R` SPIEC-EASI block + fig 14 | run_example.R:594–677; SOP:1318–1320 | REWRITE-TIGHTER | F-02 |
| — | Worked example — figs 01–13 (faithfulness spot-check) | run_example.R:77–553; SOP figures | CLEAN (checkable subset) | — (fig 11 ANCOM-BC2 regen: NEEDS-BENCH-CHECK) |

## Findings

### F-01 · S3 · "More samples than taxa" claim is false; the 50-taxa/20-sample example breaks it
- **Where:** SOP_R_Analysis.md:1264, § 12
- **Anchor:** `stable inference needs more samples than taxa`
- **Quote:**
  > Work at genus level and keep the most prevalent genera: stable inference needs more samples than taxa, so a smaller, readable set is both faster and sounder.
- **Defect:** SPIEC-EASI's estimators (`method = "mb"` is Meinshausen–Bühlmann neighbourhood selection; `glasso` is the graphical lasso) are sparse high-dimensional methods *designed* for the case where taxa outnumber samples — that is the premise of Kurtz et al. 2015, which §12 itself cites. "Needs more samples than taxa" is therefore not a real requirement, and the section's own worked example violates it: it keeps 50 genera from 20 samples (p = 50 > n = 20) and produces a stable, non-empty 68-edge network. The genuinely load-bearing advice — prune to a smaller, readable, well-supported set — is correct; only the *reason* given for it is wrong.
- **Failure:** A reader with, say, 18 samples reads "needs more samples than taxa," concludes their data cannot support a network, and either abandons the analysis or over-prunes to fewer than 18 taxa — discarding real associations — when SPIEC-EASI is built precisely for the p > n regime they are in. A reader who instead runs the shown code unchanged gets a correct network (50 > 20) that the same sentence tells them should be unreliable, so they distrust a valid result.
- **Type:** CORRECTNESS
- **Confidence:** VERIFIED
- **Evidence:** Ran the §12 pipeline verbatim on the committed example data (module `R/4.6.0-foss-2026 + R-bundle-Bioconductor/3.23-foss-2026`):
  ```
  otu matrix (samples x taxa): 20 x 50  -> p>n ? TRUE
  Selecting model with pulsar using stars...
  RESULT: nodes 50, edges 68 (63+/5-), density 0.056
  ```
  p = 50 taxa > n = 20 samples, yet StARS selects a stable network — directly contradicting the quoted claim, and reproducing the SOP's own Expected box (50/68/63/5/0.056) exactly.
- **Fix:** Replace the second sentence of line 1264 with a correct rationale that keeps the pruning advice:
  > Work at genus level and keep the most prevalent genera. SPIEC-EASI is built to infer networks where taxa outnumber samples — the worked example fits 50 genera from 20 samples — so you are not aiming for more samples than taxa; you prune to a smaller, well-supported set because it is faster, more readable, and less prone to spurious edges. More samples make the selected network more stable, but they are not a prerequisite.

### F-02 · S3 · §12 figure and its run_example.R block still declare "not a SOP step"
- **Where:** SOP_R_Analysis.md:1318–1320, § 12; `examples/r_analysis/run_example.R`:594–673
- **Anchor:** `![SPIEC-EASI co-occurrence network](examples/r_analysis/figures/14_spieceasi_network.png)`
- **Quote:**
  > ![SPIEC-EASI co-occurrence network](examples/r_analysis/figures/14_spieceasi_network.png)
  >
  > *Expected output. The 50 most prevalent genera, coloured by phylum and sized by degree; …*
- **Defect:** The SOP embeds this figure as the **Expected output** of Section 12 and Section 10 points forward to it ("Section 12 demonstrates SPIEC-EASI", line 1055). But the figure that renders inside §12 is titled, in its own header, **"SPIEC-EASI co-occurrence network (supplementary; not a SOP step)"** (`run_example.R`:669), because the whole `run_example.R` block was written before §12 existed and is still commented "SUPPLEMENTARY … (NOT a SOP_R_Analysis.md step)" (:594–597) and stepped as "Fig 15" (:607) though it saves as `14_spieceasi_network.png`. The image the reader sees contradicts the section that presents it.
- **Failure:** A reader reaches §12, reads "Expected output," looks at the figure, and its on-image title says this is *not* a SOP step — so they cannot tell whether §12 is a real part of the workflow or an aside the author forgot to remove, and cannot trust the "Expected output" label they were just given.
- **Type:** CONSISTENCY
- **Confidence:** CONFIRMED
- **Evidence:** SOP:1055 (`Section 12 demonstrates SPIEC-EASI`) and SOP:1256 (§12 is a numbered section) establish it as a SOP step; `grep -nF 'not a SOP' run_example.R` → `669: labs(title = "SPIEC-EASI co-occurrence network (supplementary; not a SOP step)",`; `grep -nF 'Fig 15 SPIEC-EASI' run_example.R` → `607` (saved as `14_spieceasi_network`, viewed: the rendered PNG carries that "not a SOP step" title).
- **Fix:** In `run_example.R`, retitle the figure and drop the "not a SOP step" framing, then regenerate (`Rscript run_example.R`). Change :669 to
  > `labs(title = "SPIEC-EASI co-occurrence network (Section 12) — GlobalPatterns worked example",`
  and, while in the block, correct the stale step labels so the console matches the filenames: :607 `step("Fig 14 SPIEC-EASI network", {` and :565 `step("core microbiome (supplementary, no figure)", {`. Update the block comment at :594–597 to note SPIEC-EASI is now SOP §12.

### F-03 · S4 · "so the result is reproducible" credits StARS; reproducibility actually rests on the seed
- **Where:** SOP_R_Analysis.md:1262, § 12
- **Anchor:** `so the result is reproducible`
- **Quote:**
  > It picks the network's sparsity by StARS stability selection instead of an arbitrary threshold, so the result is reproducible.
- **Defect:** StARS selects the sparsity by **random subsampling** (pulsar draws `rep.num` subsamples); it is not deterministic on its own. The result is reproducible here only because the code sets `set.seed(42)` and `seed = 42` in `pulsar.params`. Attributing reproducibility to "StARS instead of an arbitrary threshold" is a category error: what StARS buys you is a *principled, analyst-independent* choice; run-to-run reproducibility comes from the seed.
- **Failure:** A reader adapting the code drops the seed (it looks incidental), believing StARS guarantees reproducibility as stated, and then cannot reproduce their own network between runs — with no error to tell them why.
- **Type:** CORRECTNESS
- **Confidence:** VERIFIED
- **Evidence:** `formals(SpiecEasi:::spiec.easi.default)` → `sel.criterion = "stars"` (StARS is the default, confirming the method claim) and `formals(pulsar::pulsar)` → `rep.num = 20, thresh = 0.1, seed = NULL` — pulsar subsamples and seeds only if told to. With the seed set, my run reproduced the committed 50/68/63/5/0.056 exactly; the determinism is the seed's, not StARS's.
- **Fix:** Reword line 1262's last clause: "… It picks the network's sparsity by StARS stability selection rather than an arbitrary threshold — a principled, data-driven choice. StARS subsamples at random, so a given run is reproducible because the seed is fixed (`set.seed()` plus `seed = 42` in `pulsar.params`, both set below), not because StARS is deterministic."

### F-04 · S4 · "A few minutes on 50 taxa × 20 samples" over-states the runtime (~2.3 s measured)
- **Where:** SOP_R_Analysis.md:1289, § 12
- **Anchor:** `a few minutes on 50 taxa × 20 samples`
- **Quote:**
  > … so after the Bioconductor install it is the slowest step here — a few minutes on 50 taxa × 20 samples, and longer as either grows.
- **Defect:** The `spiec.easi()` call at exactly this scale (50 taxa × 20 samples, `rep.num = 20`) took **2.3 s** wall-clock, not "a few minutes." The over-estimate is in the safe direction (a reader will not interrupt), but the specific number is wrong by ~50×, and the "slowest step here" claim is doubtful at example scale (the 9,999-permutation `multipatt`/`adonis2` steps are comparable). The load-bearing part — runtime grows as taxa or samples grow — is correct and must stay.
- **Failure:** Minor: a reader budgets several minutes for a step that finishes in seconds, or doubts the section's accuracy on meeting a claim so far off. No wrong result.
- **Type:** CORRECTNESS
- **Confidence:** VERIFIED
- **Evidence:** Timed the exact call on the committed data: `spiec.easi wall time: 2.3 sec` (module `R/4.6.0-foss-2026`, SpiecEasi 1.99.0, 50×20, `pulsar.params=list(rep.num=20, seed=42)`).
- **Fix:** Reword line 1289 to keep the scaling caveat and drop the wrong number: "… so it is the step whose runtime grows fastest as taxa or samples increase. At the worked example's scale (50 taxa × 20 samples) it still finishes in well under a minute, but a real study with hundreds of taxa can run for many minutes."

## Verified against the cluster

Instrument: `module load R/4.6.0-foss-2026 R-bundle-Bioconductor/3.23-foss-2026-R-4.6.0`; SpiecEasi 1.99.0, igraph 2.3.1, ggraph 2.2.2, tidygraph 1.3.1, pulsar 0.3.13, phyloseq 1.56.0. Inputs read read-only from `examples/r_analysis/`; all outputs written to a scratch dir, repo not modified. Every §12 claim I could settle:

- **All four §12 packages install and load** — `requireNamespace` → SpiecEasi 1.99.0, igraph 2.3.1, ggraph 2.2.2, tidygraph 1.3.1 all present. HOLDS.
- **`method = "mb"` valid; StARS is the selection criterion** — `formals(spiec.easi.default)` shows `method="glasso"`, `sel.criterion="stars"`; §12 overrides method to `"mb"` and leaves `sel.criterion` default, so the "StARS stability selection" claim (line 1262) HOLDS.
- **`pulsar.params` sound** — `formals(pulsar::pulsar)`: `rep.num=20` (matches §12), `thresh=0.1` (§12 leaves default; fine), `seed=NULL` (§12 sets 42). All accepted; no swallowed/invalid arg. HOLDS.
- **`lambda.min.ratio = 1e-2, nlambda = 20`** — accepted (passed via `...` to the estimator); the full call ran to completion. HOLDS.
- **CLR / compositionality framing** — the run printed "Applying data transformations…"; SpiecEasi CLR-transforms internally, so "CLR-transforms the counts first" (1262) and "Give SPIEC-EASI counts, not proportions — it CLR's internally" (1277) HOLD. §12 correctly feeds `ps_raw` (counts), consistent with the SOP's raw-counts-for-compositional-methods rule.
- **Full §12 pipeline reproduces the Expected box exactly** — verbatim §12 code on the committed data → `nodes 50, edges 68 (63+/5-), density 0.056`, identical to line 1299 and to `spieceasi_network_stats.txt`. VERIFIED.
- **Density / mean-degree arithmetic** — 2×68/(50×49)=0.0555→0.056; 2×68/50=2.72. Matches the stats file. CONFIRMED.
- **SOP's shown (simplified, grey-node) plot block renders** — ran lines 1304–1313 verbatim; `ggsave` succeeded, no error. VERIFIED.
- **Embedded fig 14 matches its caption** — viewed the PNG: 50 nodes, phylum-coloured (Actinobacteria/Bacteroidetes/Cyanobacteria/Fusobacteria/Proteobacteria), degree-sized (legend 1–5), mostly blue (positive) with a few orange (negative) edges, ten hubs labelled — the labelled hubs (Rothia.1/.2, Acinetobacter.5, Methylibium.1, Actinobacillus, Klebsiella, Sphingomonas, Bacteroides.2/.3, Prevotella.2) exactly match `spieceasi_network_stats.txt`. CONFIRMED.
- **`spiec.easi` runtime at example scale** — 2.3 s (feeds F-04). VERIFIED.
- **Worked-example caption faithfulness (checkable subset):**
  - Fig 07 alpha: caption "Observed … p = 0.093 … Shannon … p = 0.009" vs `alpha_stats.txt` KW p = 0.09337692 / 0.009054943. MATCHES.
  - Fig 08 PERMANOVA: caption "R² = 0.28 and 0.48, both p = 0.0001" vs `permanova_results.txt` Bray R²=0.27654, Aitchison R²=0.47994, both Pr(>F)=1e-04. MATCHES.
  - Fig 11 ANCOM-BC2: caption "8 genera are significant … marine taxa higher in Saline, human commensals lower" vs `ancombc2_significant.tsv` = 8 rows (Congregibacter/HTCC/Spongiibacter/ZD0117/Methylophaga positive in Saline; Finegoldia/Streptococcus negative in Saline; Vogesella Freshwater). MATCHES.
  - Fig 12 indicators: caption "1,399 of 4,081 taxa pass FDR" vs `indicator_species.tsv` = 1,399 data rows. MATCHES (the 1,399 count is exact).

## Keep list

Load-bearing content in §12 a rewrite must not lose (each `grep -Fc` = 1 in SOP_R_Analysis.md):

1. `Do not build one by correlating relative abundances` (1260) — the compositionality warning that motivates SPIEC-EASI over Pearson/Spearman.
2. `Give SPIEC-EASI counts, not proportions` (1277) — the object/compositionality guard; pairs with the ps_raw discipline.
3. `Zero edges** means the sparsity penalty is too high` (1299) — the empty-network troubleshooting guard in the Expected box.
4. `not as proof of interaction` (1320) — the "association ≠ interaction" caution, plus the n=20/shared-habitat caveat.
5. `a map of community structure, not of proven interactions` (1258) — the same caution stated up front.
6. `and longer as either grows` (1289) — the runtime-scaling caveat (survives F-04, which only removes the wrong absolute number).

## Gaps

- **`tax_glom(ps_raw, taxrank = "genus")` assumes lowercase rank names.** SHOULD-ADD (½ line). The example taxonomy and the Emu/CONCOMPRA convention use lowercase `genus`/`phylum`, so the SOP is internally consistent; but a reader whose taxonomy uses DADA2/phyloseq-style capitalised `Genus` hits `Error … taxrank not found`, with no note that the rank name is literal and case-sensitive. A one-clause reminder ("`taxrank` must match a column of your `tax_table()` exactly, case included") would close it.
- **No note that `delete_vertices(..., degree==0)` can make the node count fall below the kept 50.** CONSIDER (½ line). In the example all 50 kept genera are connected, so "50 nodes" holds; on a reader's sparser data the plotted count can be < 50, which the caption ("The 50 most prevalent genera") would then overstate. Minor.

## Cross-document flags

- **Header still "last updated July 2026", no changelog for §12/figures** (SOP:7). This is capstone **C-10**'s cosmetic remainder and is owned by the coherence/README track — not re-filed here. Confirmed unresolved in the current text (line 7 reads `v2.1 | last updated July 2026 | … | suite v1.1 (August 2026)`); the "suite v1.1 (August 2026)" tag was added but the doc's own "July 2026" and the missing changelog remain. Flagging for that owner; the *correctness* of §12 is now established by this pass, which is the precondition C-10 set for updating the header.
- **C-18 (tuatara/GlobalPatterns split) and C-21 (package count) are correctly resolved** in the current text (lines 13 and 1264 respectively); C-05's figure-orphan/numbering concern is resolved (figures now contiguous 01–14, no `14_core_microbiome.png`). Confirmed, not re-filed.

## Rewrite plan

Ordered; all four are independent single-location edits and can proceed in parallel.

1. **F-01 — correct the "more samples than taxa" rationale** (SOP:1264, ~2 sentences). The one substantive correctness fix; closes the only false methodological claim in the slice. Independent.
2. **F-02 — retitle the SPIEC-EASI figure and regenerate** (`run_example.R`:669 + :565/:607 labels + :594 comment; then `Rscript run_example.R` to rewrite `figures/14_spieceasi_network.png`). Independent, but note it regenerates a committed figure, so run it in a clean checkout and diff. Because the network is seeded, only the title text should change.
3. **F-03 — reword the "reproducible" clause** (SOP:1262, one clause). Independent.
4. **F-04 — drop the wrong runtime number, keep the scaling caveat** (SOP:1289, one clause). Independent.

NEEDS-BENCH-CHECK (do not gate release on it): **fig 11 ANCOM-BC2 regeneration.** `ANCOMBC` is not installed on this cluster (Stage 0 confirmed), so I could not re-run `ancombc2()` to confirm the *figure pixels*; I confirmed the caption against the committed `ancombc2_significant.tsv` instead (8 rows, directions consistent). Settle by running `run_example.R` in a local R with `ANCOMBC` installed and diffing `11_ancombc2_lfc.png`. Cost: one ANCOMBC install + one worked-example run (minutes to tens of minutes on this small data).

## Self-check

```
findings=4 S1=0 S2=0 S3=2 S4=2
CLEAN
```

Hand-checked, the three the script cannot:
- [x] Ledger accounts for the reviewed slice (§12 + the worked-example apparatus); this is a scoped slice, not the whole file, per the task.
- [x] No proposed fix cuts load-bearing content — F-01 keeps the pruning advice, F-03 keeps the StARS-vs-arbitrary-threshold point, F-04 keeps the scaling caveat; all six keep-list items survive.
- [x] The one NEEDS-BENCH-CHECK (fig 11 regen) is genuinely unreachable here — `ANCOMBC` is not installed on this cluster (Stage 0), so the figure cannot be regenerated in this session; the caption was verified against committed data instead.

CONTRACT: PASS
