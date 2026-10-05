\name{beta}
\alias{calculate_beta}\alias{apply_beta}\alias{compare_beta}\alias{beta_dispersion}
\alias{plot_beta}\alias{plot_beta_dispersion}\alias{plot_beta_eigenvalues}\alias{plot_beta_permutations}
\alias{export_beta}\alias{replay_beta}
\title{Prepared Bray and Aitchison Distances, Explicit Permutation Plans and Saved Beta Results}
\usage{
calculate_beta(project, settings = list())
apply_beta(project, settings = list(), plot_settings = list(),
           comparison = NULL, dispersion = NULL)
compare_beta(beta, settings = list())
beta_dispersion(beta, settings = list())
plot_beta(project, settings = project$beta$plot_settings)
plot_beta_dispersion(project, settings = project$beta$plot_settings)
plot_beta_eigenvalues(project)
plot_beta_permutations(project, result = "omnibus", term = 1L,
                       dispersion = FALSE)
export_beta(project, directory)
replay_beta(bundle, output)
}
\arguments{
\item{project}{Prepared engine project.}
\item{beta}{Saved beta calculation result from \code{calculate_beta}.}
\item{settings}{Named calculation, comparison or plot settings, depending on function.}
\item{plot_settings}{Named plot settings including independent group, facet, colour and categorical shape mappings, palette, named custom colours/shapes, fixed styles, axes and figure options.}
\item{comparison}{Comparison settings or NULL.}
\item{dispersion}{Dispersion settings or NULL in apply_beta; logical choice of saved dispersion statistics in plot_beta_permutations.}
\item{result}{Saved comparison result name, such as omnibus or pair1.}
\item{term}{Column of saved permutation statistics.}
\item{directory}{New export directory inside an existing parent.}
\item{bundle}{Existing completed beta bundle.}
\item{output}{New replay output directory.}
}
\description{Computes explicit Bray, ordinary Aitchison or robust Aitchison distance on prepared named relative measurements without reclosure or display aggregation. Saves PCoA spectrum and optional separate Lingoes geometry. Inference requires explicit unit and assignment evidence and a supported hypothesis-specific permutation plan. Rendering never refits.}
\details{
Calculation settings are metric (bray, aitchison or robust.aitchison), correction (none or lingoes for Bray; none only for log-ratio methods), and max_samples (default500; quadratic storage).
Log-ratio methods require source=relative and units=proportion, at least two retained features and positive sample mass. Ordinary Aitchison uses natural-log CLR once and Euclidean distance. Its default zero_policy=positive requires pseudocount=0 and strictly positive cells. Explicit zero_policy=add requires a finite positive pseudocount in proportion units, added to every cell before logarithm. No value is universally recommended. No-add distances are invariant to sample scaling; fixed addition is scale sensitive.
Robust Aitchison uses public vegan rCLR, with zeros missing, then public optspace completion when zeros occur. Positive data bypass completion. Settings robust_rank (default3), robust_niter (default5, range2--1000), robust_tol (default1e-5, positive) are explicit; rank must fit matrix dimensions when used. No pseudocount or automatic rank is used. Entirely zero features, zero observed rCLR energy, solver errors or nonfinite results block. Completion uses deterministic SVD initialization and no RNG. It changes the whole transformed matrix and centres rows and columns. Saved optimizer output includes requested/effective settings and scaled residual history; an iteration-limit result has a warning and is not described as converged. Sparse data suitability remains an analyst decision.
Original/prepared assays and named layers are unchanged. The same saved distance supplies ordination, comparisons, dispersion and export. Transformation matrices, zero masks, versions, calls and completion diagnostics are retained and checked during replay.
Comparison settings include route (independent, conditional, paired, within, trajectory), test (overall, sequential, marginal for independent models), group, factors, covariates, nuisance, unit, visit, reference, verified, assignment, evidence, exchangeable, ordered_time, missing (fail or complete), geometry (original or ordination), permutations (budget, seed, mode), pairs (list of two-label vectors), family and adjust (holm or BH).
Independent rows must be distinct units. Conditional tests use partial dbRDA and the pinned vegan reduced-model algorithm, including version-specific nuisance permutation. Within-unit conditions require declared exchangeability and complete units. Ordered time is not automatically exchangeable. Whole trajectories require verified randomized unit-group assignment, complete matched visits and a group constant within unit; their equal-weight matched-visit squared distance is tested at unit level. Nested/crossed, irregular and unvalidated interaction schemes are blocked.
Permutation budget defaults to9999; automatic/exhaustive/sampled mode, seed, exact legal indices, source/destination previews and counts are saved. Small spaces are not padded. The observed statistic is added once under the public test's tail convention; grid resolution does not guarantee adequate precision or valid study design. Each pair rebuilds its cohort, model and restrictions. Holm/BH uses the whole planned pair family, including failures. Dispersion has its own independent one-factor spatial-median residual test and optional bias_adjust setting. No clustered dispersion or invented R-squared/dispersion confidence interval is provided.
Plots use saved scores/results and shared alpha style helpers. Shape choices0--25 are categorical;21--25 use the selected colour for fill and outline. Numeric colour requires an explicit continuous scale. Group centres are descriptive means in the displayed projection, not confidence regions. Export preserves inputs, exact plans/results/tables/plots and readable public calls; fresh replay verifies input hashes and recomputed results.}
\value{Calculation and comparison functions return saved result lists; apply_beta returns a project; plotting functions return ggplots with exact beta_data attributes; export returns its path invisibly and replay returns its verified project invisibly.}
