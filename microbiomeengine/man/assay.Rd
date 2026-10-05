\name{apply_assay}
\alias{apply_assay}
\alias{rebuild_assays}
\alias{assay_summary}
\alias{assay_values}
\alias{export_assays}
\title{Named transformations of prepared measurements}
\description{Create immutable named Hellinger, natural-log or centered log-ratio layers while preserving prepared measurements and existing diversity calculations.}
\usage{
apply_assay(project, settings = list())
rebuild_assays(project)
assay_summary(project)
assay_values(project, name)
export_assays(project, directory)
}
\arguments{
\item{project}{A validated prepared project.}
\item{settings}{List: unique name; source relative, estimated_reads or Hellinger layer; method hellinger, log or clr; units proportion, percentage, estimated_reads or derived; zero_policy positive or add; numeric pseudocount (default zero).}
\item{name}{An existing layer name.}
\item{directory}{New explicit bundle directory in an existing parent.}}
\details{Hellinger uses sample-wise closure and square root, with zero-total samples blocked. Log means natural logarithm, implemented using public mia log2 followed by multiplication by log(2). CLR subtracts the within-sample mean natural log. Positive-only log/CLR blocks zeros; explicit addition applies the same positive constant to all values in selected source units. Relative proportions are multiplied by100 for percentage units. No implicit pseudocount, original assay replacement or count conversion. Signed/log layers are terminal. Invalid calls throw without changing the project. Analytical changes mark layers stale; explicit rebuilding replays recipes in order. Exports include exact values, summaries, provenance, code and full fresh-session replay.}
\value{apply_assay and rebuild_assays return a project. Summary and values return data frames. Export returns its destination invisibly.}
