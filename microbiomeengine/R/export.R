check_project <- function(p) {
 if(!is.list(p)||!p$schema %in% c(1L,2L,3L,4L)||is.null(p$input$sources)) stop("Unsupported project schema.")
 for(s in p$input$sources) if(!is.raw(s$bytes)||!identical(digest::digest(s$bytes,algo="sha256",serialize=FALSE),s$sha256)) stop("Original input hash mismatch.")
 invisible(TRUE)
}
save_project <- function(project,path) {
 check_project(project)
 if(file.exists(path)||dir.exists(path)) stop("Destination exists; choose a new project filename.")
 if(!dir.exists(dirname(path))) stop("Parent directory does not exist.")
 saveRDS(project,path,version=3)
 invisible(path)
}
open_project <- function(path) {
 p<-readRDS(path);check_project(p)
 if(p$schema<4L) {
  old_schema<-p$schema;d<-p$declarations;s<-p$settings
  if(old_schema==1L){d$legacy_denominator_note<-d$denominator;d$denominator_kind<-"unknown";d$coverage<-"unknown";s$residual<-FALSE}
  old_history<-p$history
  p<-prepare_project(p$input,d,p$design,s)
  p$history<-c(list(list(operation=paste0("migrate_schema_",old_schema,"_to_4"),legacy_history=old_history,reason="Preserved measurements; disabled preparation defaults and canonical parent added.")),p$history)
  if(old_schema==1L)p$findings[nrow(p$findings)+1L,]<-list("legacy_meaning","warning","100% reference","Previous free-text denominator retained in declarations$legacy_denominator_note; meaning and coverage now unknown.","Review Data setup. No residual is plotted by default.")
 }
 p
}
figure_settings <- function(settings=list()) {
 s<-modifyList(list(format="png",width=12,height=8,units="in",dpi=150),settings)
 if(length(s$format)!=1L||!s$format%in%c("png","pdf","svg"))stop("Choose PNG, PDF or supported SVG.")
 if(s$format=="svg"&&!requireNamespace("svglite",quietly=TRUE))stop("SVG requires the optional svglite package.")
 if(length(s$units)!=1L||!s$units%in%c("in","cm","mm"))stop("Figure units must be in, cm or mm.")
 for(n in c("width","height","dpi"))if(length(s[[n]])!=1L||!is.numeric(s[[n]])||!is.finite(s[[n]])||s[[n]]<=0)stop("Figure width, height and DPI must be finite positive numbers.")
 inches<-c(s$width,s$height)/c("in"=1,cm=2.54,mm=25.4)[s$units]
 if(any(inches<.5|inches>40)||s$dpi<72||s$dpi>600||prod(inches*s$dpi)>1e8)stop("Use dimensions from 0.5 to 40 inches, DPI 72 to 600, and at most 100 million pixels.")
 s
}
new_export_path <- function(path) {
 if(length(path)!=1L||!nzchar(path)||file.exists(path)||dir.exists(path))stop("Choose an explicit new output filename; existing files are preserved.")
 if(!dir.exists(dirname(path)))stop("Output parent directory does not exist.")
 invisible(path)
}
export_figure <- function(project,path,settings=project$settings$figure) {
 s<-figure_settings(settings);new_export_path(path)
 if(tolower(tools::file_ext(path))!=s$format)stop("Figure filename extension must match the selected format.")
 device<-switch(s$format,png="png",pdf="pdf",svg=svglite::svglite)
 ggplot2::ggsave(path,plot_composition(project),device=device,width=s$width,height=s$height,units=s$units,dpi=s$dpi,limitsize=TRUE)
 invisible(path)
}
export_composition_data <- function(project,path) {
 new_export_path(path)
 if(is.null(project$table))stop("Resolve composition findings before exporting plotted data.")
 utils::write.table(project$table,path,sep="\t",row.names=FALSE,quote=TRUE)
 invisible(path)
}
html_table <- function(d) {
 if(is.null(d)||!nrow(d))return(htmltools::tags$p("None."))
 htmltools::tags$table(htmltools::tags$thead(htmltools::tags$tr(lapply(names(d),htmltools::tags$th))),
  htmltools::tags$tbody(lapply(seq_len(nrow(d)),function(i)htmltools::tags$tr(lapply(d[i,,drop=FALSE],function(x)htmltools::tags$td(as.character(x)))))))
}
render_diagnosis <- function(p,path) {
 report<-htmltools::tags$html(lang="en",htmltools::tags$head(htmltools::tags$meta(charset="utf-8"),htmltools::tags$title("Microbiome input diagnosis"),htmltools::tags$style("body{font:16px system-ui;max-width:1200px;margin:40px auto;padding:0 24px;color:#172b3a}h1{color:#147d80}table{border-collapse:collapse;width:100%;font-size:13px}td,th{border:1px solid #dce3e9;padding:8px;text-align:left;overflow-wrap:anywhere}th{background:#edf4f5}img{max-width:100%}pre{white-space:pre-wrap}")),
 htmltools::tags$body(htmltools::tags$h1("Microbiome input diagnosis"),htmltools::tags$p(paste(p$declarations$denominator,". Descriptive composition; values are not observed counts. No inferential or repeated-measures readiness is certified.")),
 htmltools::tags$h2("Declared meaning"),html_table(data.frame(field=names(p$declarations),value=unlist(p$declarations))),
 htmltools::tags$h2("Findings and actions"),html_table(p$findings),htmltools::tags$h2("Study design"),htmltools::tags$pre(paste(capture.output(str(p$design)),collapse="\n")),
 htmltools::tags$h2("Observed mass"),htmltools::tags$p("No reclosure. The difference from 100% is reported separately; its biological origin is not inferred. It is omitted from bars unless explicitly enabled for declared removed-without-rescaling data."),html_table(p$mass),
 htmltools::tags$h2("Preparation"),htmltools::tags$p("Order: select cohort, calculate prevalence on that cohort, filter named features. Choices within a category are OR; sample, group and time clauses are AND. Supplied Unclassified is exempt. No recommended universal thresholds. Named assay layers, when present, are reported separately; original prepared measurements remain unchanged. No metadata transformations."),
 htmltools::tags$pre(paste(capture.output(str(p$preparation$operation)),collapse="\n")),htmltools::tags$h3("Sample decisions"),html_table(p$preparation$samples),htmltools::tags$h3("Named-feature decisions"),html_table(p$preparation$features[,c("feature_id","numerator","denominator","prevalence","retained","reason"),drop=FALSE]),
 htmltools::tags$h2("Composition"),html_table(p$display_mass),htmltools::tags$img(src=if(p$settings$figure$format=="png")"composition.png" else "composition-preview.png",alt="Selected-rank descriptive composition"),htmltools::tags$p("Exact underlying values: composition.tsv; retained named-taxon membership: composition-membership.tsv; excluded full IDs: preparation-features.tsv. Feature-removed mass and display-hidden mass are separate from supplied Unclassified and the original unresolved difference. Other contains only non-displayed retained named taxa. Group summaries are arithmetic means, not independent-unit estimates."),
 htmltools::tags$h2("Provenance"),html_table(data.frame(input=names(p$input$sources),sha256=vapply(p$input$sources,function(x)x$sha256,character(1)))),htmltools::tags$p("See settings.rds, project.rds, versions.tsv and replay.R in this bundle. Inputs are preserved byte-for-byte under inputs/.")))
 htmltools::save_html(report,path)
}
export_project <- function(project,directory) {
 check_project(project)
 assays_current(project)
 if(!is.null(project$alpha))alpha_current(project)
 if(!is.null(project$beta))beta_current(project)
 if(is.null(project$experiment)||is.null(project$table))stop("Resolve blocking input/composition findings before exporting analysis.")
 if(!nzchar(directory))stop("Choose an explicit new export directory.")
 if(file.exists(directory)||dir.exists(directory))stop("Export destination exists; choose a new directory.")
 if(!dir.create(directory,recursive=FALSE))stop("Cannot create export directory; check its parent.")
 dir.create(file.path(directory,"inputs"))
 for(n in names(project$input$sources))writeBin(project$input$sources[[n]]$bytes,file.path(directory,"inputs",paste0(n,if(n=="metadata")".txt" else ".tsv")))
 save_project(project,file.path(directory,"project.rds"))
 saveRDS(list(declarations=project$declarations,design=project$design,settings=project$settings,preparation=project$preparation$settings,sample_id=project$input$sample_id),file.path(directory,"settings.rds"))
 saveRDS(project$preparation,file.path(directory,"preparation.rds"))
 write_table<-function(x,name)utils::write.table(x,file.path(directory,paste0(name,".tsv")),sep="\t",row.names=FALSE,quote=TRUE)
 write_matrix<-function(x,name)write_table(data.frame(feature_id=rownames(x),x,check.names=FALSE),name)
 write_matrix(project$input$values,"original-primary")
 if(!is.null(project$input$estimated))write_matrix(project$input$estimated$values,"original-estimated_reads")
 write_table(project$input$metadata,"original-metadata")
 for(layer in c("canonical","prepared")) {
  obj<-if(layer=="canonical")project$canonical else project$experiment
  saveRDS(obj,file.path(directory,paste0(layer,".rds")))
  for(n in SummarizedExperiment::assayNames(obj))write_matrix(SummarizedExperiment::assay(obj,n),paste(layer,n,sep="-"))
  write_table(as.data.frame(SummarizedExperiment::colData(obj)),paste0(layer,"-metadata"))
 }
 write_table(project$preparation$samples,"preparation-samples")
 write_table(project$preparation$features,"preparation-features")
 write_table(project$mass,"prepared-mass")
 write_table(project$canonical_mass,"canonical-mass")
 writeLines(capture.output(dput(project$preparation$operation)),file.path(directory,"preparation-operation.R"))
 export_composition_data(project,file.path(directory,"composition.tsv"))
 utils::write.table(project$membership,file.path(directory,"composition-membership.tsv"),sep="\t",row.names=FALSE,quote=TRUE)
 saveRDS(project$normalization,file.path(directory,"normalization.rds"))
 utils::write.table(project$findings,file.path(directory,"findings.tsv"),sep="\t",row.names=FALSE,quote=TRUE)
 export_figure(project,file.path(directory,paste0("composition.",project$settings$figure$format)))
 if(project$settings$figure$format!="png")export_figure(project,file.path(directory,"composition-preview.png"),modifyList(project$settings$figure,list(format="png")))
 render_diagnosis(project,file.path(directory,"diagnosis.html"))
 if(!is.null(project$alpha)) {
  export_alpha(project,file.path(directory,"alpha"))
  report<-readLines(file.path(directory,"diagnosis.html"),warn=FALSE)
  report<-sub("</body>","<h2>Alpha diversity</h2><p><a href='alpha/alpha.html'>Alpha values, comparisons, diagnostics and figures</a></p></body>",report,fixed=TRUE)
  writeLines(report,file.path(directory,"diagnosis.html"))
 }
 if(!is.null(project$beta)) {
  export_beta(project,file.path(directory,"beta"))
  report<-readLines(file.path(directory,"diagnosis.html"),warn=FALSE)
  report<-sub("</body>","<h2>Beta diversity</h2><p><a href='beta/beta.html'>Distances, geometry, permutation plans, comparisons and dispersion</a></p></body>",report,fixed=TRUE)
  writeLines(report,file.path(directory,"diagnosis.html"))
 }
 if(length(project$assay_layers)) {
  export_assay_files(project,directory)
  report<-readLines(file.path(directory,"diagnosis.html"),warn=FALSE)
  report<-sub("</body>","<h2>Named assay layers</h2><p><a href='assays.html'>Applied transformations, summaries and provenance</a>; full values in assay-*-values.tsv.</p></body>",report,fixed=TRUE)
  writeLines(report,file.path(directory,"diagnosis.html"))
 }
 ip<-utils::installed.packages();utils::write.table(ip[,c("Package","Version","License")],file.path(directory,"versions.tsv"),sep="\t",row.names=FALSE,quote=TRUE)
 writeLines(capture.output(sessionInfo()),file.path(directory,"session.txt"))
 libs<-unique(c(normalizePath(dirname(find.package("microbiomeengine")),winslash="/"),normalizePath(.libPaths(),winslash="/")))
 script<-c("# Run: Rscript --vanilla replay.R BUNDLE NEW_OUTPUT", "# Prefer the active installed engine; recorded libraries are fallback only.",paste0("if (!requireNamespace('microbiomeengine', quietly=TRUE)) .libPaths(c(",paste(deparse(libs),collapse=""),", .libPaths()))"),"args <- commandArgs(TRUE)","if (length(args) != 2L) stop('Supply bundle and new output directory')","microbiomeengine::replay_project(args[1], args[2])")
 writeLines(script,file.path(directory,"replay.R"))
 writeLines("Export completed; replay verification is a separate operation.",file.path(directory,"COMPLETE"))
 invisible(directory)
}
replay_project <- function(bundle,output) {
 if(!file.exists(file.path(bundle,"COMPLETE")))stop("Bundle incomplete.")
 saved<-open_project(file.path(bundle,"project.rds"));s<-readRDS(file.path(bundle,"settings.rds"))
 x<-import_metaphlan(if("abundance"%in%names(saved$input$sources))file.path(bundle,"inputs","abundance.tsv") else NULL,file.path(bundle,"inputs","metadata.txt"),s$sample_id,estimates=if("estimates"%in%names(saved$input$sources))file.path(bundle,"inputs","estimates.tsv") else NULL)
 for(n in names(x$sources))if(!identical(x$sources[[n]]$sha256,saved$input$sources[[n]]$sha256))stop("Bundle input hash mismatch: ",n)
 p<-prepare_project(x,s$declarations,s$design,s$settings,if(is.null(s$preparation))list() else s$preparation)
 same_assays<-!is.null(p$experiment)&&identical(SummarizedExperiment::assayNames(p$experiment),SummarizedExperiment::assayNames(saved$experiment))&&all(vapply(SummarizedExperiment::assayNames(p$experiment),function(n)identical(SummarizedExperiment::assay(p$experiment,n),SummarizedExperiment::assay(saved$experiment,n)),logical(1)))
 if(!same_assays||!identical(assay_snapshot(p$canonical),assay_snapshot(saved$canonical))||!identical(as.data.frame(SummarizedExperiment::colData(p$canonical)),as.data.frame(SummarizedExperiment::colData(saved$canonical)))||!identical(p$preparation,saved$preparation)||!identical(p$normalization,saved$normalization)||!identical(p$mass,saved$mass)||!identical(p$table,saved$table)||!identical(p$membership,saved$membership))stop("Replay differs from saved canonical/prepared measurements, decisions, fingerprints, mass, membership or plotted table.")
 p<-assays_recalculate(saved,p)
 p<-alpha_recalculate(saved,p)
 p<-beta_recalculate(saved,p)
 export_project(p,output)
 writeLines("Canonical and prepared values, preparation settings/decisions/fingerprints, mass, membership and composition table agree with the saved project.",file.path(output,"VERIFIED"))
 cat("Replay verified:",normalizePath(output,winslash="/"),"\n")
 invisible(p)
}
