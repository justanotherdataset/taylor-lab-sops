# Microbiome Engine — early tester release 0.1.0

A local Shiny dashboard and reusable R package for microbiome tables, explicit study declarations, analysis, plots and reproducible exports.

## Why this exists

The aim is to turn an abundance table and sample metadata into a clear, inspectable workflow: understand the inputs, declare the study design, prepare the data, explore composition and diversity, and export the exact data and R code behind the results. Established mia, miaViz, Bioconductor and vegan functions supply appropriate analysis components. The engine adds identity checks, explicit measurement meaning, design checks, consistent settings and project/replay records.

The longer-term goal is one local workflow for several microbiome pipelines and study designs. This first tester version completes the MetaPhlAn route. It is an early research tool; a successful calculation does not establish that the study design or method is suitable.

## Download and run in RStudio

1. Install **R 4.6.x** and RStudio. The supported package environment is **Bioconductor 3.23**. [R downloads](https://cran.r-project.org/) · [RStudio downloads](https://posit.co/download/rstudio-desktop/) · [Bioconductor installation](https://bioconductor.org/install/).
2. On the [Taylor Lab SOP repository](https://github.com/justanotherdataset/taylor-lab-sops), choose **Code → Download ZIP**, then extract it to a folder you can write to. No Git command is required.
3. Inside `microbiomeengine/`, open **microbiomeengine.Rproj**. Confirm that RStudio is using R 4.6.x.
4. In the RStudio console, run the one-time setup:

   ```r
   source("install.R")
   ```

5. When setup reports success, run:

   ```r
   microbiomeengine::run_app()
   ```

The app opens at a localhost address in your browser. Click **Load synthetic example** to start without study files. Stop the app with RStudio's Stop button or Escape in the console. For later sessions, open the same project and run only `microbiomeengine::run_app()`.

Setup downloads dependencies into the project's `.tester-library`; it does not copy the developer's libraries. It reads the full package dependency declarations, includes the optional SVG device, and records installed versions in `installed-versions.tsv`. This is a version manifest, not an exact-version restoration lock. Existing packages are not deleted and unrelated libraries are not upgraded by this script. Keep the engine folder and its library together. Windows/macOS request binary dependencies; Linux uses source packages and may require compilers and system libraries. Tested platforms and actual installation results are in [RELEASE-VALIDATION.md](RELEASE-VALIDATION.md); untested platforms are not certified.

## What works now

| Stage | Implemented scope |
| --- | --- |
| Inputs | Merged MetaPhlAn relative-abundance TSV plus CSV/TSV metadata; optional separately merged estimated-read matrix; explicit estimate-only relative contribution route |
| Declarations | Sample-ID matching, available taxonomic rank, measurement scale and reference population, filtering/provenance, metadata types and study-design roles |
| Preparation | Sample/group/time subsets, prevalence/detection filters, separate named natural-log/CLR/Hellinger assay layers |
| Composition | Rank selection, top N/all taxa, Other and supplied Unclassified, grouping/faceting/order/palettes, exact plotted data and figure settings/export |
| Alpha | Detected named taxa, Shannon, Gini–Simpson, inverse Simpson and Pielou; eligible t/Welch/paired tests, additive LM and bounded mixed models; effects, exclusions and diagnostics |
| Beta | Bray–Curtis, Aitchison and robust Aitchison; PCoA, supported PERMANOVA/conditional/pairwise and bounded repeated-unit routes; independent dispersion assessment and explicit permutation plans |
| Reproducibility | Save/reopen, recorded settings/inputs/hashes/versions, figures/tables/diagnostics, R export and verified fresh-process replay |

Original measurements and IDs remain preserved. Taxonomic levels use supplied terminal-rank rows; parent and child taxa are not summed together. Composition top-N and Other are display choices, not alpha/beta analytical inputs. Percentages and estimated reads are not observed counts. Feature filtering, display omissions, supplied Unclassified and unresolved mass remain distinct.

Ordinary Aitchison requires positive retained values or an explicitly chosen addition to every retained cell, in proportion units. Robust Aitchison uses observed-positive rCLR and, when zeros exist, matrix completion with explicit rank/iterations/tolerance. Completion can change observed cells, fail on sparse/singular data or end before tolerance is reached; the engine reports those conditions. Neither method is universally preferable. Named preparation layers remain separate from these beta calculation inputs.

## Study design and interpretation

Selecting columns does not certify independence or exchangeability. Statistical comparisons require appropriate unit/assignment declarations and estimable designs. The UI explains the supported permutation routes and records the actual legal indices, seed, resolution and warnings. Unsupported designs remain blocked. Alpha LM diagnostics are generated from the actual fit. A significant PERMANOVA can reflect location or dispersion differences; its companion dispersion assessment is not proof of homogeneity.

The beta sample limit is an adjustable computational guard: pairwise storage grows with n(n−1)/2 and ordination also needs matrix workspace. The default of 500 is an engineering choice, not a biological threshold or a measured hardware capacity. It never silently selects or drops samples.

## What is still planned

More input adapters (EMU, generic tables/Excel and R objects), a separate HUMAnN functional route, additional diversity/ordination methods, metadata transformations and longitudinal summaries remain future work. MaAsLin2 and ANCOM-BC2 modules are deferred. Focused UI passes remain for stage-specific code/data choosers and more visual colour/shape editors; existing exports and manual styles are available. Narrow-window and screen-reader accessibility are not fully verified.

## Testing and feedback

Follow the short [tester walkthrough](TESTING.md), then report bugs or unclear controls through [GitHub Issues](https://github.com/justanotherdataset/taylor-lab-sops/issues). Include steps, expected/actual behaviour, package/R versions and a small synthetic example. Remove private paths and identifiers from logs/screenshots. Do not upload participant/study data, saved project RDS files or full exports as public issue attachments. A saved R object should only be reopened from a trusted source.

## Troubleshooting

- **Wrong R version:** install R 4.6.x, choose that installation in RStudio and restart the project.
- **Package download/installation failed:** retain the full console output; check connectivity, writable disk space and binary availability for the supported release. No successful setup is claimed until dependencies and the engine load.
- **Package not found on a later launch:** open `microbiomeengine.Rproj` from the original extracted engine folder so `.Rprofile` selects `.tester-library`; rerun setup if the library is absent.
- **Port in use:** choose another local port, for example `microbiomeengine::run_app(port=7360)`.
- **Replay differs after changing dependency versions:** compare the bundle's versions with the current installation. The manifest records versions but does not automatically restore them. Output destinations must be new folders; existing results are not overwritten.

## Licence, attribution and citation

The **engine source and accompanying engine documentation are GPL-3**, with full terms in [LICENSE](LICENSE). The existing repository SOP documents keep their **CC BY 4.0** licence; that licence does not replace the engine software licence. Dependencies retain their own licences and are downloaded separately, not bundled here. See [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md), including the GPL-version compatibility boundary for downstream combined distributions.

Maintainer: **Saif**, saiffaraj181@gmail.com. Use `citation("microbiomeengine")` for the engine and `citation("mia")`, `citation("miaViz")`, `citation("vegan")` and the relevant statistical packages for the methods actually used. No publication or DOI is claimed for the engine.
