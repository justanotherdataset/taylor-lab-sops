\name{microbiomeengine}
\alias{microbiomeengine}
\alias{import_metaphlan}
\alias{validate_input}
\alias{prepare_project}
\alias{apply_preparation}
\alias{composition_table}
\alias{plot_composition}
\alias{save_project}
\alias{open_project}
\alias{export_project}
\alias{export_figure}
\alias{export_composition_data}
\alias{replay_project}
\alias{example_project}
\alias{run_app}
\title{Declared MetaPhlAn projects and reproducible composition}
\description{Import merged MetaPhlAn relative profiles, diagnose identities and declarations, prepare a TreeSummarizedExperiment, plot composition, and save or replay a project.}
\usage{
import_metaphlan(abundance = NULL, metadata, sample_id = "sample_id", estimates = NULL)
validate_input(input, declarations = list(), design = list())
prepare_project(input, declarations = list(), design = list(), settings = list(),
  preparation = list())
apply_preparation(project, preparation = list())
composition_table(project, settings = project$settings)
plot_composition(project)
save_project(project, path)
open_project(path)
export_project(project, directory)
export_figure(project, path, settings = project$settings$figure)
export_composition_data(project, path)
replay_project(bundle, output)
example_project()
run_app(port = 7349, launch.browser = interactive(), project = NULL)
}
\arguments{
\item{abundance}{Path to a merged MetaPhlAn TSV.}
\item{estimates}{Optional merged estimated-read TSV; explicit estimated-read unit declaration required.}
\item{metadata}{Path to CSV or TSV metadata; fields remain character values.}
\item{sample_id}{Exact metadata sample-ID column.}
\item{input}{Preserved input record from import_metaphlan.}
\item{declarations}{Named list: rank (k,p,c,o,f,g,s,t), scale (percentage or proportion), denominator_kind (profiled, including_unclassified, unknown), coverage (complete, removed, rescaled, unknown), pipeline, database, filtering, unclassified, estimate_unit (estimated_reads), estimate_normalization (explicit TRUE for estimate-only contribution).}
\item{design}{Named list: types (named character vector of id, categorical, continuous, date or text), group, time, unit, repeated, repetition (yes, no, unknown) and covariates.}
\item{settings}{Named list: group/facet metadata fields or empty strings, order (input, alphabetical, total), palette (viridis, Set 2, Dark 3), residual (FALSE by default; TRUE requires known denominator and removed coverage), taxa_mode (all or top), top_n (positive integer), show_other and show_unclassified (logical), figure (format png/pdf/svg, width, height, units in/cm/mm, dpi). For export_figure, settings is that figure list.}
\item{project}{Project record from prepare_project or example_project.}
\item{preparation}{Optional recipe. samples: enabled and exact ids; group/time: enabled, field, mode (values/range), values, include_missing, lower/upper. Group requires categorical type; range requires continuous/date type with inclusive bounds. filter: enabled, source (relative/estimated_reads), units (proportion/percentage/estimated_reads), detection, detection_operator (> or >=), prevalence (0 to 1), prevalence_operator (> or >=). Clauses are AND, values within clauses OR; enabled empty selections retain none. Default disables all restrictions. Order is cohort, prevalence, feature filter. apply_preparation with defaults resets. Invalid preparation returns a blocked project with no active view.}
\item{path}{New output filename for save/figure/data, or existing trusted project for open.}
\item{directory}{New export directory with an existing parent.}
\item{bundle}{Complete exported bundle directory.}
\item{output}{New directory for verified replay outputs.}
\item{port}{Local Shiny port.}
\item{launch.browser}{Whether to open a browser automatically.}
}
\value{Import returns an input record; validation a findings data.frame; preparation/open/example a project list; composition_table a data.frame; plotting a ggplot; save/export paths invisibly; replay a verified project invisibly; run_app runs Shiny.}
\details{Only descriptive relative composition is supported. Identity or numeric errors block preparation. Rank and scale must be explicit. Missing scientific history or unit declarations produce limitations. Original bytes and full lineage IDs are retained. mia imports rank-specific experiments; miaViz plots explicit prepared values without reclosure. Save/export refuse existing destinations. Replay checks input hashes, canonical assay and exact plotted data. Exported R code uses the installed local package library; on another machine install recorded dependencies and adjust its library path.}
\examples{
p <- example_project()
p$mass
}

