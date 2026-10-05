alpha_metrics <- function() c(detected="observed_richness",shannon="shannon_diversity",gini_simpson="gini_simpson_diversity",inverse_simpson="inverse_simpson_diversity",pielou="pielou_evenness")
alpha_settings <- function(settings=list()) {
 s<-modifyList(list(source="relative",metrics=names(alpha_metrics())[1:4]),settings)
 if(length(setdiff(names(s),c("source","metrics"))))stop("Unknown alpha setting.")
 if(length(s$source)!=1L||!s$source%in%c("relative","estimated_reads"))stop("Choose relative or estimated_reads explicitly.")
 if(!is.character(s$metrics)||!length(s$metrics)||anyNA(s$metrics)||anyDuplicated(s$metrics)||any(!s$metrics%in%names(alpha_metrics())))stop("Choose unique supported alpha metrics.")
 s
}
alpha_parent <- function(project,settings) {
 if(is.null(project$experiment)||!identical(project$preparation$status,"ready"))stop("Apply valid Preparation before alpha calculation.")
 if(!settings$source%in%SummarizedExperiment::assayNames(project$experiment))stop("Requested alpha measurement is unavailable.")
 m<-SummarizedExperiment::assay(project$experiment,settings$source)
 if(!is.numeric(m)||!nrow(m)||!ncol(m)||any(!is.finite(m))||any(m<0))stop("Alpha needs a nonempty finite nonnegative analytical assay.")
 for(ids in dimnames(m))if(is.null(ids)||anyNA(ids)||any(!nzchar(trimws(ids)))||anyDuplicated(ids))stop("Alpha requires unique nonblank sample and feature IDs.")
 if(any(!is.finite(colSums(m))))stop("Alpha sample totals overflow.")
 meta<-as.data.frame(SummarizedExperiment::colData(project$experiment))
 if(!identical(rownames(meta),colnames(m)))stop("Alpha metadata identity is not aligned.")
 sources<-project$input$sources[sort(names(project$input$sources),method="radix")]
 versions<-vapply(c("mia","vegan"),function(n)as.character(utils::packageVersion(n)),character(1))
 list(matrix=m,metadata=meta,fingerprint=preparation_fingerprint(list(assay=m,rank=project$declarations$rank,settings=settings,
  sources=vapply(sources,function(z)z$sha256,character(1)),recipe=project$preparation$settings,normalization=project$normalization,versions=versions,design=project$design,definition="named-alpha-v1")),versions=versions)
}
calculate_alpha <- function(project,settings=list()) {
 result<-list(status="blocked",reason="",settings=settings,values=data.frame(),fingerprint=NULL,metadata=NULL,mass=project$mass)
 tryCatch({
  s<-alpha_settings(settings);result$settings<-s;z<-alpha_parent(project,s);m<-z$matrix;ids<-colnames(m)
  result$fingerprint<-z$fingerprint;result$metadata<-z$metadata;result$versions<-z$versions
  result$metadata_types<-project$design$types;result$rank<-project$declarations$rank;result$features<-rownames(m)
  result$source_label<-if(s$source=="estimated_reads")"Estimated reads (not observed counts)" else if(is_estimate_only(project$input))"Relative estimated-read contribution" else "Supplied relative abundance"
  result$normalization<-"Within each metric: divide by retained named-feature mass. Supplied Unclassified excluded; stored assays unchanged. Detected taxa uses value > 0. Shannon natural log (nats)."
  valid<-colSums(m)>0;v<-matrix(NA_real_,length(ids),length(s$metrics),dimnames=list(ids,s$metrics))
  if(any(valid)) {
   obj<-project$experiment[,valid,drop=FALSE]
   res<-mia::getAlpha(obj,assay.type=s$source,index=unname(alpha_metrics()[s$metrics]),name=s$metrics,niter=NULL,detection=0,threshold=0)
   if(!identical(rownames(res),ids[valid])||!identical(colnames(res),s$metrics))stop("Upstream alpha changed requested identity/schema.")
   v[valid,]<-as.matrix(res)
  }
  detected<-colSums(m>0)
  rows<-lapply(s$metrics,function(metric){
   status<-ifelse(valid,"ready","undefined");reason<-ifelse(valid,"","zero_retained_mass")
   if(metric=="pielou"){status[detected<=1]<-"undefined";reason[valid&detected<=1]<-"undefined_evenness_singleton";v[detected<=1,metric]<-NA_real_}
   if(any(!is.finite(v[status=="ready",metric])))stop("Unexpected nonfinite upstream alpha result.")
   data.frame(sample_id=ids,metric=metric,value=v[,metric],units=if(metric=="shannon")"nats" else if(metric=="detected")"detected named taxa" else "dimensionless",status=status,reason=reason,
    rank=result$rank,source=s$source,retained_mass=colSums(m),detected=detected,stringsAsFactors=FALSE,row.names=NULL)
  })
  result$values<-do.call(rbind,rows);result$status<-if(all(result$values$status=="ready"))"ready" else "partial";result
 },error=function(e){result$status<-"blocked";result$reason<-conditionMessage(e);result})
}
apply_alpha <- function(project,settings=list(),plot_settings=list(),comparison=NULL) {
 project$alpha<-calculate_alpha(project,settings)
 project$alpha$plot_settings<-alpha_plot_settings(plot_settings)
 project$alpha$comparison<-if(is.null(comparison))NULL else compare_alpha(project$alpha,comparison)
 project
}
alpha_current <- function(project) {
 a<-project$alpha
 if(is.null(a)||a$status%in%c("stale","blocked")||isTRUE(a$pending))stop("Apply valid current alpha settings before export.")
 z<-alpha_parent(project,a$settings)
 if(!identical(z$fingerprint,a$fingerprint)||!identical(z$metadata,a$metadata))stop("Alpha result is stale; apply alpha again.")
 invisible(TRUE)
}
retain_alpha <- function(old,new) {
 if(is.null(old$alpha))return(new)
 a<-old$alpha
 same<-tryCatch({z<-alpha_parent(new,a$settings);identical(z$fingerprint,a$fingerprint)&&identical(z$metadata,a$metadata)},error=function(e)FALSE)
 if(!same){a$status<-"stale";a$reason<-"Analytical source, cohort, features, rank or metadata changed. Apply alpha again."}
 new$alpha<-a;new
}

