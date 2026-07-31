# 00 · Environment probe

**Stage 0, run before all reviewers.** This records what is actually true of the
cluster and R installation the four SOPs target, so the reviewers can treat
these facts as settled. It reviews nothing and files no findings.

This cluster is **NeSI Mahuika** (New Zealand eScience Infrastructure), a SLURM
HPC. Probed **2026-07-31** from `login03.hpc.nesi.org.nz` (an AMD `zen3`/Milan
login node; Lmod modules; Slurm 25.05.7; system `python3` is 3.6-era `/usr/bin/python3`).
Every pinned software module in every SOP exists at exactly the version written,
and every command-line tool and flag on the main path is real. The single fact
most likely to surprise someone who trusted the SOPs: **`pairwise.adonis2()` has
no `p.adjust.m` argument.** Part 2 calls it as `pairwise.adonis2(dist ~ Site, p.adjust.m = "BH")`
and tells the reader that line "applies Benjamini-Hochberg correction"
(`SOP_R_Analysis.md:842-852`). It does not: `p.adjust.m` falls into the
function's `...` and is silently discarded, and `pairwise.adonis2` performs no
p-value adjustment of any kind. The reader gets **unadjusted** p-values while
believing they are corrected — wrong-but-plausible, no error. (This is the S1 the
brief flagged; the reviewer of Part 2 owns it. Settled below under Q7.)

---

## Environment

| Fact | Value |
| --- | --- |
| Cluster | NeSI Mahuika, SLURM HPC (Slurm 25.05.7) |
| Login node probed | `login03.hpc.nesi.org.nz`, arch `zen3` (AMD Milan) |
| Module system | Lmod; modules under `/opt/nesi/zen3/…` and `/opt/nesi/CS400_centos7_bdw/…` |
| Date probed | 2026-07-31 |
| Cold shell python | `/usr/bin/python3` (system; unrelated to any tool env) |

Note on architecture: the amplicon/Emu tooling lives under `/opt/nesi/zen3/`
(matches the login node). The **MetaPhlAn** module resolves to a *mahuika*
`CS400_centos7_bdw` (Broadwell) build. It runs on the login node in probing, but
its natural home is a mahuika compute node; the read-based SOP submits it via
SLURM, so this is not a problem, only a thing to know.

---

## What is on PATH, and what had to be loaded

A bare login shell has `module` and system utilities and **nothing else** — `R`,
`conda`, `emu`, `metaphlan`, `chopper` are all behind modules.

```
$ which module R conda python3 2>&1
module ()   # shell function (Lmod)
/usr/bin/which: no R in (…/home/sfar315/bin:…:/opt/nesi/bin)
/usr/bin/which: no conda in (…)
/usr/bin/python3
```

Practical note for reviewers reading my transcript: after `module load`, use
`command -v <tool>` (or the absolute path) to confirm a binary — the legacy
`/usr/bin/which` does not always see Lmod-modified PATH inside a freshly spawned
non-interactive shell, and produced spurious "not found" lines in my session
that were resolved by re-checking with `command -v`. **That is an artefact of my
probe harness, not a defect in the SOPs.** Every "not found" below that I report
as a *fact* was re-confirmed by absolute path.

What I loaded to answer each class of question:

| To answer | Module(s) loaded |
| --- | --- |
| Emu / osfclient / DB questions | `Emu/3.6.2` |
| MetaPhlAn questions | `MetaPhlAn/4.1.0-gimkl-2022a-Python-3.10.5` |
| FastTree | `FastTree/2.1.11-GCC-11.3.0` |
| chopper | `chopper/0.12.0b-GCC-12.3.0` |
| **R (my instrument — see caveat)** | `R/4.6.0-foss-2026` **+** `R-bundle-Bioconductor/3.23-foss-2026-R-4.6.0` |

**The R module is my auditing instrument, not a recommendation.** `README.md`
tells the reader "R on your own machine. Part 2 runs locally, not on NeSI," and
that is deliberate lab policy. I have R here only because I am an auditor with a
shell. Nothing in this report should be read as evidence that Part 2 belongs on
the cluster, or that any local install step is redundant.

---

## Modules

Every `module load` string that appears in the SOPs, checked against
`module avail`. All exist at the exact version written — **all HOLDS.**

| Claim (module) | Source | Command | Output | Verdict |
| --- | --- | --- | --- | --- |
| `BBMap/39.01-GCC-11.3.0` | READBASED | `module avail` exact match | exists | HOLDS |
| `chopper/0.12.0b-GCC-12.3.0` | EMU | ″ | exists | HOLDS |
| `Emu/3.6.2` | EMU | ″ | exists | HOLDS |
| `fastp/0.23.4-GCC-11.3.0` | READBASED | ″ | exists | HOLDS |
| `FastQC/0.12.1` | EMU/READBASED | ″ | exists | HOLDS |
| `FastTree/2.1.11-GCC-11.3.0` | CONCOMPRA | ″ | exists | HOLDS |
| `MAFFT/7.505-gimkl-2022a-with-extensions` | CONCOMPRA | ″ | exists | HOLDS |
| `MetaPhlAn/4.1.0-gimkl-2022a-Python-3.10.5` | READBASED | ″ | exists (CS400 build) | HOLDS |
| `Miniforge3/25.3.1-0` | CONCOMPRA (×8) | ″ | exists | HOLDS |
| `MultiQC/1.24.1-foss-2023a-Python-3.11.6` | READBASED | ″ | exists | HOLDS |
| `NanoPlot/1.43.0-foss-2023a-Python-3.11.6` | EMU | ″ | exists | HOLDS |
| `seqtk/1.4-GCC-11.3.0` | READBASED | ″ | exists | HOLDS |
| `VSEARCH/2.21.1-GCC-11.3.0` | CONCOMPRA | ″ | exists | HOLDS |

`R` module versions available on the cluster (for the reviewers' context only;
the reader uses local R): `3.5.3`, `3.6.1`, `3.6.2`, `4.0.1`, `4.1.0`, `4.2.1`,
`4.3.1`, `4.3.2-foss-2023a`, **`4.6.0-foss-2026`** (newest). Bioconductor bundles:
`3.11`, `3.13`, `3.15`, `3.17`, and **`3.23-foss-2026-R-4.6.0`** (newest).

---

## Command-line tools and flags

All verified by `--help`/`--version` under the loaded module (absolute path where
noted, per the PATH caveat above).

| Claim | Source | Command | Output (quoted) | Verdict |
| --- | --- | --- | --- | --- |
| `emu` present, v3.6.2 | EMU | `emu --version` | `emu v3.6.2` | HOLDS |
| `emu abundance --type lr:hq` valid | `SOP_EMU_NeSI.md:692,726` | `emu abundance --help` | `--type {map-ont,map-pb,sr,lr:hq,map-hifi,splice:hq}` … `[map-ont]` (default) | HOLDS |
| `emu abundance` flags `--keep-counts --keep-read-assignments --output-unclassified --min-abundance --threads --db --output-dir --output-basename` | EMU | `emu abundance --help` | all listed in usage | HOLDS |
| `emu combine-outputs <dir> <rank> [--counts] [--split-tables]` | `SOP_EMU_NeSI.md:775-806` | `emu combine-outputs --help` | `usage: emu combine-outputs [-h] [--split-tables] [--counts] dir_path rank` | HOLDS |
| `chopper -q/--quality`, `-l/--minlength`, `--maxlength` | EMU | `chopper --help` | `-q, --quality <MINQUAL>` · `-l, --minlength <MINLENGTH>` · `--maxlength <MAXLENGTH>` | HOLDS |
| `metaphlan` present, v4.1.0 | READBASED | `metaphlan --version` | `MetaPhlAn version 4.1.0 (23 Aug 2023)` | HOLDS |
| `FastTree` present, v2.1.11 | CONCOMPRA | `FastTree` banner | `FastTree Version 2.1.11 SSE3, OpenMP` | HOLDS |
| `nn_storage_quota` / `nn_check_quota` | EMU (quota check) | `command -v` | both `/opt/nesi/bin/…` | HOLDS (see Q2) |
| `sbatch -D/--chdir` | EMU/READBASED | `sbatch --help` | `-D, --chdir=directory  set working directory for batch script` | HOLDS (see Q1) |

Note: Emu's own `--db` help text contains an upstream typo (`unqiue_taxids.tsv`).
That is Emu's, not the SOP's — recorded only so a reviewer does not chase it.

---

## R packages and function signatures

**Instrument:** `module load R/4.6.0-foss-2026 R-bundle-Bioconductor/3.23-foss-2026-R-4.6.0`
→ `R version 4.6.0 (2026-04-24)`.

Package set the Part-2 SOP relies on, checked verbatim with the brief's snippet:

```
phyloseq         1.56.0
decontam         1.32.0
SRS              0.2.3
vegan            2.7.3
pairwiseAdonis   NOT INSTALLED
ANCOMBC          NOT INSTALLED
Maaslin2         NOT INSTALLED
indicspecies     1.8.0
microbiome       NOT INSTALLED
mia              1.20.0
ggpubr           NOT INSTALLED
```

Where each installed package lives (from `find.package`):

| Package | Location | Provided by |
| --- | --- | --- |
| phyloseq, decontam, mia | `/opt/nesi/zen3/R-bundle-Bioconductor/3.23-foss-2026-R-4.6.0/` | Bioconductor bundle module |
| vegan | `/opt/nesi/zen3/R/4.6.0-foss-2026/lib64/R/library/` | base R module |
| SRS, indicspecies | `/home/sfar315/R/foss-2026/4.6/` | **my personal user library** (installed by this account, not a module) |

**Five packages are not installed anywhere reachable on this cluster:**
`pairwiseAdonis`, `ANCOMBC`, `Maaslin2`, `microbiome`, `ggpubr`. This is not a
"wrong R module" situation — `module spider` returns nothing for any of them, no
Bioconductor bundle (3.11–3.23) provides `ANCOMBC`/`Maaslin2`/`microbiome`, and
`ggpubr` is absent from the `R/4.6.0` extension set. Their questions are handled
under **Unreachable**. This has **no bearing on the SOP**, which runs Part 2 on
the reader's own laptop where they install these themselves; it only bounds what
I could execute here. (`SRS` and `indicspecies` show as installed only because
this account previously `install`ed them into its home library — same category of
convenience; do not read it as a module guarantee.)

Function signatures probed (all under the instrument module):

| Signature | Command | Output (quoted) |
| --- | --- | --- |
| `vegan::adonis2` | `args(vegan::adonis2)` | `function (formula, data, permutations = 999, method = "bray", sqrt.dist = FALSE, add = FALSE, by = NULL, parallel = …, na.action = na.fail, strata = NULL, ...)` |
| `SRS::SRS.shiny.app` | `args(SRS::SRS.shiny.app)` | `function (data)` |
| `base::symnum` | `args(symnum)` | `function (x, cutpoints = c(0.3,0.6,0.8,0.9,0.95), symbols = … , …)` |
| `permute::how` | `args(permute::how)` | `function (within = Within(), plots = Plots(), blocks = NULL, nperm = 199, …)` |
| `indicspecies::multipatt` | `args(indicspecies::multipatt)` | `function (x, cluster, func = "IndVal.g", duleg = FALSE, restcomb = NULL, min.order = 1, max.order = NULL, allow.negative = FALSE, control = how(), permutations = NULL, print.perm = FALSE)` |

---

## Databases and filesystem

| Claim | Source | Command | Output | Verdict |
| --- | --- | --- | --- | --- |
| Emu ships a default DB dir | Emu module | `module show Emu/3.6.2` | `setenv EMU_DATABASE_DIR /opt/nesi/zen3/Emu/3.6.2/database` | HOLDS (SOP does **not** use it; it downloads SILVA/RDP to `nobackup`) |
| SILVA/RDP fetched from OSF project `56uf7` via `osf … fetch` | `SOP_EMU_NeSI.md:617` | (download not run — read-only) | — | see Q5 (tar structure NOT-VERIFIABLE) |
| `osf` entrypoint available after `pip install osfclient` | `SOP_EMU_NeSI.md:607` | `ls ~/.local/bin/osf` | `/home/sfar315/.local/bin/osf` (user-site, on PATH) | see Q6 |
| SILVA SINTAX DB built from Emu's `species_taxid.fasta` | `SOP_CONCOMPRA_NeSI.md:126,637` | n/a (needs the downloaded bundle) | — | NOT-VERIFIABLE-HERE |

Home library `.libPaths()` under the instrument module, for reference:
`/home/sfar315/R/foss-2026/4.6`, the Bioconductor bundle, `/opt/nesi/zen3/R-Geo/4.6.0-foss-2026`,
and the base R library.

---

## Answers to the sixteen open questions

Each is settled below. Verdicts: **VERIFIED** (ran a probe here), **CONFIRMED**
(provable from text/authoritative source), **NOT-VERIFIABLE-HERE** (needs a
download, a real run, or a package this cluster lacks — with the check that would
settle it and its cost).

### Q1 · `--chdir` log-path behaviour — VERIFIED (flag), standard Slurm (path resolution)
`sbatch --help` gives `-D, --chdir=directory  set working directory for batch
script` and `-o, --output=out  file for batch script's standard output`. A
**relative** `-o`/`-e` path (including `%x`/`%j` patterns) is resolved by Slurm
relative to the `--chdir` directory, not the submit directory — so logs land
under `--chdir`. The flag and descriptions are confirmed here; the relative-path
resolution is documented Slurm behaviour I could not fully close without
submitting a job (which the rules forbid). To confirm to the letter: submit a
one-line job with `--chdir=/tmp/x -o out-%j.log` and see the log appear in
`/tmp/x`. Cost: one trivial job, seconds.

### Q2 · `nn_storage_quota` vs `nn_check_quota` — VERIFIED, identical
Both are on PATH and **`nn_check_quota` is a symlink to `nn_storage_quota`**:
```
$ ls -la /opt/nesi/bin/nn_check_quota
… nn_check_quota -> ./nn_storage_quota
$ md5sum /opt/nesi/bin/nn_storage_quota /opt/nesi/bin/nn_check_quota
cfbfac265b40236fe91938a49b6a4b3b  nn_storage_quota
cfbfac265b40236fe91938a49b6a4b3b  nn_check_quota
```
Same usage (`[-h] [-p <project>] [-u <user>]`, no-arg reports all the user's
projects + `$HOME`). Whichever name a SOP uses is correct and equivalent.

### Q3 · CONCOMPRA `otu_table.csv` header form — NOT-VERIFIABLE-HERE
CONCOMPRA is not installed as a module and its output-writing script was not
locatable at a guessed path. The SOP's own *consumption* is internally
consistent: comma-separated, one header row, first column = OTU id, remaining
columns = per-sample counts — see `head -1 … | awk -F, '{print NF-1}'`
(`:332`), `tail -n +2 … | cut -d',' -f1` (`:420`), and
`read.csv("otu_table.csv", row.names = 1, check.names = FALSE)` (`:536`). The
exact *label* of the first column is what remains open. Settle: run CONCOMPRA on
the tutorial data and `head -1 results/otu_table.csv`, or read the line in the
CONCOMPRA source that writes it. Cost: one CONCOMPRA run (minutes) or a source read.

### Q4 · `emu abundance --type lr:hq` — VERIFIED, valid
`emu abundance --help`:
```
[--type {map-ont,map-pb,sr,lr:hq,map-hifi,splice:hq}]
--type … [map-ont]        (default)
```
`lr:hq` is an accepted choice; default is `map-ont`. The SOP's guidance (`:726`)
— `lr:hq` for SUP/Q20+ Nanopore, `map-ont` for older HAC data — matches the tool.

### Q5 · `tar -tf silva.tar` structure — NOT-VERIFIABLE-HERE
Requires the multi-GB OSF download (`osf -p 56uf7 fetch osfstorage/emu-prebuilt/silva.tar`),
which the rules bar (do not saturate the link). What is open: whether the tar
unpacks **flat** (files directly into the cwd) or into a **`silva/` subdirectory**.
This matters because the SOP extracts inside `…/emu_databases/silva` and then
points `--db` at `…/emu_databases/silva`; if the tar carries a top-level `silva/`,
`--db` would need to be one level deeper (`…/emu_databases/silva/silva`) or Emu
would not find `species_taxid.fasta`. Settle:
`osf -p 56uf7 fetch osfstorage/emu-prebuilt/silva.tar && tar -tf silva.tar | head`.
Cost: one multi-GB download.

### Q6 · `pip install osfclient` under the Emu module — VERIFIED (necessary, not redundant)
`osfclient` is **not** bundled in `Emu/3.6.2` (`ls …/site-packages | grep osf` →
nothing) and that module's `site-packages` is **read-only** for a normal user. So
`module load Emu/3.6.2; pip install osfclient` falls back to a `--user` install
into `~/.local/lib/python3.8/site-packages`, and the `osf` entrypoint lands in
`~/.local/bin/osf` — which is on the default PATH. The step in the SOP is
**required and works**. (On my account `pip` prints "Requirement already
satisfied … /home/sfar315/.local/…" only because this account ran it in a prior
session; a fresh reader sees it actually install to their `~/.local`.) Do not
mark this step redundant.

### Q7 · `args(pairwiseAdonis::pairwise.adonis2)` — `p.adjust.m` real or swallowed? — CONFIRMED: swallowed
`pairwiseAdonis` is not installed here, so `args()` cannot be run on-cluster; the
signature is settled from the canonical upstream source
(`pmartinezarbizu/pairwiseAdonis`, `R/pairwise.adonis2.R`):
```r
pairwise.adonis2 <- function(x, data, strata = NULL, nperm=999, ... )
```
There is **no `p.adjust.m` argument**, and the function performs **no p-value
adjustment at all** — any `p.adjust.m = "BH"` passed by a caller is absorbed into
`...` and silently discarded. This directly contradicts `SOP_R_Analysis.md:842-852`,
which calls `pairwise.adonis2(dist_bray ~ Site, … p.adjust.m = "BH")` and states
"`p.adjust.m = "BH"` applies Benjamini-Hochberg correction." It does not. The
reader gets **unadjusted** pairwise p-values believing they are BH-corrected.
(Contrast: the v1 function `pairwise.adonis` *does* take `p.adjust.m`; the "2"
variant does not — an easy and dangerous confusion.) This is the Part-2 S1; the
Part-2 reviewer should file it. To reconfirm with a local install:
`args(pairwiseAdonis::pairwise.adonis2)`.

### Q8 · `symnum()` argument length — VERIFIED, SOP is correct
The rule R enforces: **`length(cutpoints)` must be exactly one more than
`length(symbols)`.** The SOP's two calls (`:510`, `:560`) use 6 cutpoints
`c(0, 0.0001, 0.001, 0.01, 0.05, 1)` and 5 symbols `c("****","***","**","*","ns")`
— i.e. 6 = 5 + 1, valid. Ran it:
```
$ symnum(c(0.00005,0.0005,0.005,0.02,0.5), corr=FALSE,
         cutpoints=c(0,0.0001,0.001,0.01,0.05,1),
         symbols=c("****","***","**","*","ns"))
[1] "****" "***"  "**"   "*"    "ns"
```
Mapping is as intended. A mismatched 6-cutpoint/6-symbol call errors:
`Error: number of 'cutpoints' must be one more than number of symbols`. (The
package *default* looks like 5 cutpoints / 6 symbols only because default
cutpoints are treated as interior breaks; once you supply explicit 0/1 endpoints,
the n+1 rule applies — which the SOP does correctly.)

### Q9 · `?adonis2` default for `by` — VERIFIED: `by = NULL`
In installed **vegan 2.7-3**, `args(adonis2)` shows `by = NULL`, and the help
reads: *"`by = NULL` will assess the overall significance of all terms together,
`by = "terms"` will assess significance for each term (sequentially from first to
last) …"* So the default is an **omnibus** test (one line for the whole model),
**not** sequential per-term. This *confirms* the SOP's own warning at
`SOP_R_Analysis.md:805` ("in recent vegan versions (2.6-8 and later) the default
is now an omnibus test (`by = NULL`) … Always pass `by = "terms"` explicitly").
The SOP does pass `by = "terms"` in its live code (`:812`, `:818`), so it is safe;
the note is accurate for the installed version.

### Q10 · `args(SRS::SRS.shiny.app)` — VERIFIED
`function (data)`. It **requires** a `data` argument; `SRS.shiny.app()` with no
argument errors on missing `data`. The SOP mentions it only parenthetically
(`SOP_R_Analysis.md:395`, `SRS::SRS.shiny.app()`) as an exploratory aside — a
reviewer should check whether that bare-call notation misleads a reader into
running it without data.

### Q11 · `ancombc2` runtime — NOT-VERIFIABLE-HERE (doubly)
Needs both a real dataset and the `ANCOMBC` package, and `ANCOMBC` is **not
installed on this cluster** (no module provides it). Runtime is data- and
size-dependent by nature. Settle: on the reader's local R with `ANCOMBC`
installed, `system.time(ancombc2(...))` on the actual `tse`. Cost: the run itself,
which is the unknown being measured. The SOP's four-per-group worked example
(`:986`) is tiny and will be fast; a full study is the open variable.

### Q12 · FastTree `-boot` semantics — VERIFIED
From `FastTree -expert`, "Support value options": *"By default, FastTree computes
local support values by resampling the site likelihoods 1,000 times and the
Shimodaira Hasegawa test … the support values are proportions ranging from 0 to
1 … Use `-nosupport` to turn off support values or `-boot 100` to use just 100
resamples."* So `-boot N` sets the **number of resamples** for FastTree's
**SH-like local support** (the default is already 1000 resamples). The values are
**proportions 0–1, not Felsenstein bootstrap percentages (0–100)**. With `-nome`
it computes minimum-evolution bootstrap instead. A reader who reads `-boot 1000`
as "1000 traditional bootstraps → percentage support" is mistaken on both the
method and the 0–1 scale.

### Q13 · `CONCOMPRA.yml`'s minimap2 pin — CONFIRMED: `minimap2==2.1.1`
Settled from the upstream file (`willem-stock/CONCOMPRA`, `CONCOMPRA.yml`, main):
the pin is exactly `- minimap2==2.1.1` (alongside `python==3.11`,
`numba==0.60.0`, `filtlong==0.2.1`; channels `conda-forge, bioconda, defaults`).
The SOP reproduces this faithfully (`SOP_CONCOMPRA_NeSI.md:110,604`, "minimap2 is
pinned to 2.1.1 by upstream; do not change it"). Two adjacent facts a reviewer
may want: (a) `2.1.1` is a genuinely old minimap2 (2017-era) — that is upstream's
choice, not a SOP transcription error, and is out of this stage's scope to judge;
(b) the yml's `defaults` channel is exactly why the SOP strips it before
`conda env create` (`:87,95`), since NeSI blocks Anaconda `defaults`.

### Q14 · MetaPhlAn merged-table first line — VERIFIED (fixture)
Built two minimal profile files and ran `merge_metaphlan_tables.py`:
```
$ sed -n '1,3p' merged.txt | cat -A
#mpa_vJun23_CHOCOPhlAnSGB_202403$
clade_name^IsampleA^IsampleB$
k__Bacteria^I100.0^I100.0$
```
**Line 1 is the database-version comment** (`#mpa_v…`), carried from the input
profiles. **The real column header — `clade_name<TAB>sample1<TAB>sample2` — is on
line 2**, tab-separated, with sample names taken from the input filenames. A
reader who treats line 1 as the header (or `read.table(header=TRUE)` without
skipping the comment) gets the `#mpa_…` string, not `clade_name`.

### Q15 · pandas in the MetaPhlAn module — VERIFIED: present
Under the module's interpreter (`Python/3.10.5-gimkl-2022a`):
```
$ python3 -c "import pandas; print(pandas.__version__)"
1.4.2
```
`pandas 1.4.2` is available. (Note: a bare `python3 -c "import pandas"` on the
*cold* login shell fails, because that resolves to system `/usr/bin/python3`; the
module's Python has it. This is the PATH caveat again, not a missing dependency.)

### Q16 · MetaPhlAn `--bowtie2out` overwrite behaviour — VERIFIED (source)
From `metaphlan/metaphlan.py:1300-1306`:
```python
if os.path.exists( pars['bowtie2out'] ) and not pars['force']:
    sys.stderr.write(
        "BowTie2 output file detected: " + pars['bowtie2out'] + "\n"
        "Please use it as input or remove it if you want to "
        "re-perform the BowTie2 run.\n"
        "Exiting...\n\n" )
    sys.exit(1)
if pars['force']:
    if os.path.exists(pars['bowtie2out']):
        os.remove( pars['bowtie2out'] )
```
If the `--bowtie2out` file already exists and `--force` is not given, MetaPhlAn
**prints "…Exiting…" and exits 1** — it does **not** silently overwrite. With
`--force` it deletes and re-runs. Consequence for the read-based SOP: re-running a
sample (e.g. a re-queued array task) onto an existing `--bowtie2out` path hard-
stops unless the reader passes `--force` or points at a fresh filename.

---

## Unreachable

Questions I could not settle on this cluster, with the one check that would, and
its cost. (`ANCOMBC`, `Maaslin2`, `microbiome`, `ggpubr`, `pairwiseAdonis` are not
installed here; the reader installs them locally, so these are unreachable *for
me*, not defects in the SOP.)

| Item | Why unreachable | Check that settles it | Cost |
| --- | --- | --- | --- |
| CONCOMPRA `otu_table.csv` exact header label (Q3) | CONCOMPRA not installed; writer script not located | run CONCOMPRA on tutorial data → `head -1 results/otu_table.csv`, or read its output-writing line | one CONCOMPRA run (min) or a source read |
| `tar -tf silva.tar` structure (Q5) | needs multi-GB OSF download (must not saturate) | `osf -p 56uf7 fetch …/silva.tar && tar -tf silva.tar \| head` | one multi-GB download |
| `ancombc2` runtime (Q11) | needs real data **and** `ANCOMBC` (not installed here) | local R w/ ANCOMBC: `system.time(ancombc2(...))` on the real `tse` | the run itself |
| `args(pairwiseAdonis::pairwise.adonis2)` local reconfirm (Q7) | `pairwiseAdonis` not installed here | local R: `args(pairwiseAdonis::pairwise.adonis2)` | seconds locally |
| `ANCOMBC` / `Maaslin2` / `microbiome` / `ggpubr` signatures | not installed on any cluster module | local R after `BiocManager::install(...)` / `install.packages("ggpubr")` | minutes locally |

`pairwiseAdonis` (Q7) and `CONCOMPRA.yml` (Q13) were nonetheless *settled* from
authoritative upstream source, not deferred — see those entries.

---

### Provenance of on-cluster probes

- Modules/tools: `module avail`, `module show`, `--help`, `--version` under each
  loaded module (2026-07-31, `login03`, Slurm 25.05.7).
- R facts: `R/4.6.0-foss-2026 + R-bundle-Bioconductor/3.23-foss-2026-R-4.6.0`,
  `requireNamespace`/`packageVersion`/`args`/`?adonis2` help/`symnum` run.
- MetaPhlAn merged-table: fixture built and run under scratch, then removed.
- Off-cluster source (clearly marked as such, not a local install): upstream
  `pairwise.adonis2.R` and `CONCOMPRA.yml`.
- Scratch used a temporary directory; fixtures cleaned up; the repository was not
  written to except this file.
