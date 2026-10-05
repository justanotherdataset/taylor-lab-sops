\name{alpha}
\alias{calculate_alpha}
\alias{apply_alpha}
\alias{compare_alpha}
\alias{plot_alpha}
\alias{plot_alpha_estimates}
\alias{plot_alpha_diagnostics}
\alias{export_alpha}
\alias{replay_alpha}
\title{Prepared named-feature alpha diversity and declared comparisons}
\description{Calculate explicit public mia indices, retain undefined values, fit bounded verified study designs, and render or export saved results without refitting.}
\usage{
calculate_alpha(project, settings = list())
apply_alpha(project, settings = list(), plot_settings = list(), comparison = NULL)
compare_alpha(alpha, settings = list())
plot_alpha(project, settings = project$alpha$plot_settings)
plot_alpha_estimates(project)
plot_alpha_diagnostics(project, metric, settings = project$alpha$plot_settings)
export_alpha(project, directory)
replay_alpha(bundle, output)
}
\arguments{
\item{project}{A prepared project with aligned samples and named features.}
\item{settings}{Calculation: source (relative or estimated_reads), metrics (detected, shannon, gini_simpson, inverse_simpson, pielou). Comparison: method (welch, student, paired, lm, mixed), group, reference, unit, verified, evidence, assignment, time, time_mode, at_time, numeric covariates, adjust (holm, BH, none), family and conf_level (0.95). Plot settings as below.}
\item{plot_settings}{Group, facet, colour and shape metadata columns (empty means fixed), colour_type (categorical or continuous), fixed_colour, fixed_shape (0--25), HCL palette, named colours/shapes vectors, exact group order, trajectories, and figure settings (format, width, height, units, dpi). Shapes are categorical; filled shapes share fill/outline colour. Estimates use target-group styles when the comparison group is mapped; other sample metadata uses fixed estimate styles.}
\item{comparison}{Optional comparison settings. NULL leaves metrics descriptive.}
\item{alpha}{A calculated alpha result with exact sample metadata.}
\item{metric}{An exact metric name with saved fitted diagnostics.}
\item{directory}{New output directory inside an existing parent.}
\item{bundle}{Completed alpha export directory.}
\item{output}{New replay output directory.}
}
\details{Alpha uses retained named features at the declared rank, excluding supplied Unclassified. Shannon uses natural logs; zero-mass samples and singleton evenness remain undefined. Estimated reads are never labelled observed counts. Explicit independent experimental units or independent subjects plus study evidence are required for inference. Paired tests use complete pairs without averaging. LM uses a conditional nested F omnibus and reference contrasts. Mixed models are restricted to group-by-time, independent subject random intercepts, Satterthwaite inference, at least six subjects and three per group. Singular, aliased or non-estimable fits are blocked. Multiplicity includes the full planned family including failed tests; CI are pointwise. Saved LM diagnostics use public stats methods; mixed diagnostics are conditional residual plots. Styling and rendering do not fit models. Exports preserve project inputs, results, settings, model frames, figures and fresh-process replay code. Existing destinations are refused.}
\value{Calculation and comparison return result lists. Application returns a project. Plot functions return ggplot objects (diagnostics: named list), with exact plotted data attributes. Export invisibly returns its path; replay invisibly returns the verified recomputed project.}

