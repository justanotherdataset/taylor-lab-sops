# Validation of early tester release 0.1.0

Validated on 5 October 2026 on Windows with R 4.6.0 and Bioconductor 3.23. This is an early tester snapshot, not certification of every study design, platform or accessibility requirement.

## Installation and replay

The documented `source("install.R")` setup succeeded in a relocated project with a fresh `.tester-library`. Only R's base/recommended packages were initially visible; nonstandard developer packages were hidden from this validation process. Dependencies were downloaded from public repositories, not copied from the developer library. The observed setup took approximately 1.7 minutes on this machine and produced 173 package directories. Download speed and installation time elsewhere can differ.

The actual downloaded environment included mia/miaViz 1.20.0, vegan 2.7-6, permute 0.9-10, lme4 2.0-6, lmerTest 3.2-1 and emmeans 2.0.4. The installer writes the full installed version manifest. It does not pin or restore exact dependency versions.

Synthetic project, alpha and beta exports replayed successfully. A regression check exercised their actual generated R scripts with a historical library path recorded in the bundle and confirmed that the caller's active installed engine retained priority. A separate fresh R process reproduced a combined alpha/robust-Aitchison export and wrote its verification marker; an on-load check confirmed the relocated engine was used. The RStudio project profile selected the dedicated library without installing packages or starting analysis. The RStudio GUI itself was not exercised during release setup.

## Package checks

`R CMD build --no-build-vignettes` and `R CMD check --no-manual --no-vignettes` completed with all **17 test scripts passing**. These covered Aitchison reference calculations, alpha calculations/models/diagnostics, assay handling, beta outputs/design/permutations, preparation, taxonomic ranks, controls, UI server behavior, project export/replay and the new library-priority regression.

That full check reported one packaging NOTE: the top-level LICENSE file was not mentioned in DESCRIPTION. The correction preserves the full GPL-3 text as LICENSE in the GitHub source and packages the same text as COPYING, with the duplicate LICENSE excluded from the R build. A subsequent build/check with `--no-tests --no-manual --no-vignettes` returned **Status: OK**. Tests were not repeated for this licence-file-only correction; R source and test bytes were compared between the full-test and corrected packaging snapshots.

Checks were run against the downloaded tester dependencies as well as a separately installed final engine for replay. Package checking also produced repository-index connection messages in the restricted validation session; the network-enabled fresh installation itself completed successfully. Existing composition fixtures can emit an upstream plotting warning about dropped nonpositive values; plotted-data and replay assertions passed.

## Limits and next work

- macOS and Linux installation have not been tested. Linux may require compilers and system libraries for source dependencies.
- Automated Shiny server tests and prior milestone browser inspections support this release. A new full browser accessibility audit was not performed for the installer/replay changes; narrow-window and screen-reader behavior remain incompletely verified.
- Stage-specific data/code choosers and more visual colour/shape editors remain UI follow-ups. Current exports and manual styles are available.
- More input adapters, functional-data analysis and additional analytical modules remain future work. This release does not add MaAsLin2 or ANCOM-BC2.
- GPL-version compatibility for downstream combined distributions remains unresolved as explained in [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md). Dependency libraries are installed separately and are not included in this repository snapshot.

Use [TESTING.md](TESTING.md) for the synthetic walkthrough and safe feedback instructions. Scientific suitability still depends on the declared measurements, experimental units and supported design.
