# Third-party notices and source references

The engine source, accompanying engine documentation and microbiome-engine feedback templates are distributed under GPL-3. This includes the two engine templates under .github/ISSUE_TEMPLATE in the SOP repository. No dependency source/binary packages, downloaded source-audit archives or real-study pilot data are bundled in this subtree. The installer retrieves dependencies from their public package repositories; their original licences and notices remain applicable. Original synthetic fixtures are supplied under the engine licence.

## Public APIs reused

| Package (inspected development version) | Public reuse |
| --- | --- |
| mia 1.20.0 | importMetaPhlAn, meltSE, getPrevalence, getAlpha, transformAssay and getDissimilarity, with explicit input/parameter checks |
| miaViz 1.20.0 | plotAbundance on prepared display data with controlled aggregation/normalisation |
| TreeSummarizedExperiment / SummarizedExperiment / S4Vectors / SingleCellExperiment | Public experiment containers and accessors |
| vegan 2.7-5 | wcmdscale, decostand, optspace, adonis2, dbrda, betadisper and permutest |
| permute 0.9-10 | how, Within, numPerms, allPerms and shuffleSet |
| stats / lme4 / lmerTest / emmeans | Public test, model, diagnostic and contrast functions |
| shiny / ggplot2 / htmltools / digest / svglite | Local interface, plotting/HTML, hashing and optional SVG output |

The engine adds original scientific declarations, identity checks, provenance/state handling, display summaries, export/replay and design restrictions. It does not vendor an upstream optimizer or private Shiny observer. Diagnostic reference conventions were informed by stats::plot.lm in R 4.6.0, R Core Team. The engine computes quantities through public stats methods and renders its own ggplot2 figures; it does not distribute the upstream plot.lm implementation. R offers GPL-2 or GPL-3 licensing.

## Dependency licence boundary

The inspected mia/miaViz licences are Artistic-2.0 with their LICENSE files; shiny/ggplot2 use MIT; htmltools/digest/lme4/lmerTest/svglite declare GPL (>= 2); emmeans declares GPL-2 | GPL-3; SingleCellExperiment declares GPL-3. **vegan 2.7-5 and permute 0.9-10 declare GPL-2**, which R's licence database identifies as GPL-2.0-only. Their presence is not proof that every dependency can be relicensed as GPL-3. Attribution alone does not resolve GPL-version compatibility.

This release distributes the engine source separately and does not relicense or redistribute those dependencies. Compatibility of a downstream combined binary/application distribution, including same-process GPL-2-only/GPL-3 components, has not been legally resolved by this source audit. Review that boundary before repackaging or asserting compatibility; no blanket compatibility certification is made. [GNU GPL-version guidance](https://www.gnu.org/licenses/quick-guide-gplv3.html) and [aggregation guidance](https://www.gnu.org/licenses/gpl-faq.html#MereAggregation).

The versions/licence strings above describe inspected development packages, not an exact installation lock. Check installed-versions.tsv and each installed package's DESCRIPTION/LICENSE/COPYRIGHTS for the actual tester environment. This selective direct-dependency review is not a certification of every transitive dependency.

## Workflow/research references

[miaDash](https://microbiome.github.io/miaDash/), [OMA](https://bioconductor.org/books/release/OMA/), [miaViz](https://microbiome.github.io/miaViz/), [iSEE](https://isee.github.io/iSEE/) and other miaverse resources informed the workflow and source review. miaDash, iSEE/iSEEtree, miaTime and miaSim implementations are not bundled or claimed as engine dependencies. MetaPhlAn is an input-format/method reference; its profiling/merger implementation is not copied into this package. Existing study scripts informed reusable patterns, but their study-specific settings and results are not engine defaults or distributed here.

Use citation("package") for primary method references relevant to the analyses actually used. Record package versions and the input pipeline/database provenance. The SOP repository's existing CC BY 4.0 licence remains applicable to its SOP documents; GPL-3 governs this engine subtree.
