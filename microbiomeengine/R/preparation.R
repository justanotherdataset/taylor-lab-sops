preparation_settings <- function(settings=list()) {
 clause<-list(enabled=FALSE,field="",mode="values",values=character(),include_missing=FALSE,lower="",upper="")
 defaults<-list(samples=list(enabled=FALSE,ids=character()),group=clause,time=clause,
  filter=list(enabled=FALSE,source="relative",units="proportion",detection=0,detection_operator=">",prevalence=0,prevalence_operator=">="))
 if(!is.list(settings))stop("Preparation settings must be a named list.")
 if(length(setdiff(names(settings),names(defaults))))stop("Unknown preparation setting.")
 for(n in names(settings))if(!is.list(settings[[n]])||length(setdiff(names(settings[[n]]),names(defaults[[n]]))))stop("Unknown preparation fields in ",n,".")
 modifyList(defaults,settings,keep.null=TRUE)
}
preparation_flag <- function(x,label) {
 if(!is.logical(x)||length(x)!=1L||is.na(x))stop(label," must be TRUE or FALSE.")
 x
}
preparation_character <- function(x,label) {
 if(!is.character(x)||anyNA(x)||anyDuplicated(x))stop(label," must contain unique, nonmissing exact values.")
 x
}
preparation_clause <- function(clause,meta,types,role) {
 n<-nrow(meta)
 if(!preparation_flag(clause$enabled,paste(role,"enabled")))return(rep(TRUE,n))
 field<-clause$field
 if(length(field)!=1L||is.na(field)||!field%in%names(meta))stop("Choose an existing ",role," column.")
 if(length(clause$mode)!=1L||!clause$mode%in%c("values","range"))stop("Choose values or range for ",role,".")
 type<-unname(types[field]);if(!length(type)||is.na(type))type<-"text"
 if(role=="group"&&!identical(type,"categorical"))stop("Group selection requires an explicitly categorical column.")
 v<-as.character(meta[[field]]);missing<-is.na(v)|!nzchar(trimws(v))
 include<-preparation_flag(clause$include_missing,paste(role,"include missing"))
 if(clause$mode=="values") {
  values<-preparation_character(clause$values,paste(role,"selection"))
  if(any(!nzchar(trimws(values))))stop("Use the include-missing choice for blank ",role," values.")
  if(length(setdiff(values,v[!missing])))stop("Unknown exact ",role," values: ",paste(setdiff(values,v[!missing]),collapse=", "))
  result<-!missing&v%in%values
 } else {
  if(is.null(type)||!type%in%c("continuous","date"))stop("Ranges require an explicitly typed usable continuous or date column.")
  if(length(clause$lower)!=1L||length(clause$upper)!=1L)stop("Supply both range bounds.")
  parse<-if(type=="date")function(x){
   z<-suppressWarnings(as.Date(x,format="%Y-%m-%d"));z[is.na(x)|is.na(z)|format(z,"%Y-%m-%d")!=x]<-as.Date(NA);as.numeric(z)
  } else function(x)suppressWarnings(as.numeric(x))
  vv<-parse(v);lo<-parse(as.character(clause$lower));hi<-parse(as.character(clause$upper))
  if(any(!is.finite(vv[!missing]))||!is.finite(lo)||!is.finite(hi)||lo>hi)stop("Use a valid ordered ",type," range and usable nonmissing column values.")
  result<-!missing&vv>=lo&vv<=hi
 }
 result[missing]<-include
 result
}
preparation_fingerprint <- function(x)digest::digest(x,algo="sha256",serialize=TRUE)
assay_snapshot <- function(x) {
 if(is.null(x))return(NULL)
 setNames(lapply(SummarizedExperiment::assayNames(x),function(n)SummarizedExperiment::assay(x,n)),SummarizedExperiment::assayNames(x))
}
prepare_view <- function(p,settings) {
 # All state is rebuilt from the canonical parent. Failure cannot retain an old view.
 p$experiment<-NULL;p$table<-NULL;p$membership<-NULL;p$display_mass<-NULL;p$mass<-NULL
 p$preparation<-list(settings=settings,status="blocked",samples=NULL,features=NULL,operation=NULL)
 tryCatch({
  s<-preparation_settings(settings);p$preparation$settings<-s
  parent<-p$canonical;ids<-colnames(parent);taxa<-rownames(parent)
  meta<-as.data.frame(SummarizedExperiment::colData(parent))
  sample_ok<-rep(TRUE,length(ids))
  if(preparation_flag(s$samples$enabled,"Sample selection enabled")) {
   selected<-preparation_character(s$samples$ids,"Sample IDs")
   if(length(setdiff(selected,ids)))stop("Unknown sample IDs: ",paste(setdiff(selected,ids),collapse=", "))
   sample_ok<-ids%in%selected
  }
  clauses<-cbind(samples=sample_ok,group=preparation_clause(s$group,meta,p$design$types,"group"),time=preparation_clause(s$time,meta,p$design$types,"time"))
  keep<-rowSums(clauses)==ncol(clauses)
  reasons<-apply(clauses,1,function(z)if(all(z))"retained" else paste(paste0(names(z)[!z]," clause not matched"),collapse="; "))
  p$preparation$samples<-data.frame(sample_id=ids,retained=keep,reason=reasons,row.names=NULL)
  if(!any(keep))stop("No samples retained: sample, group and time clauses are combined with AND. Select at least one matching sample or reset preparation.")
  cohort<-parent[,keep,drop=FALSE];f<-s$filter
  enabled<-preparation_flag(f$enabled,"Feature filter enabled")
  prevalence<-rep(NA_real_,length(taxa));numerator<-rep(NA_integer_,length(taxa));retained<-rep(TRUE,length(taxa))
  source_label<-if(is_estimate_only(p$input))"Relative estimated-read contribution among supplied rank rows" else "Supplied relative abundance"
  threshold<-NA_real_
  if(enabled) {
   if(length(f$source)!=1L||!f$source%in%c("relative","estimated_reads")||!f$source%in%SummarizedExperiment::assayNames(cohort))stop("Select an available named source: relative or estimated_reads.")
   units<-if(f$source=="relative")c("proportion","percentage") else "estimated_reads"
   if(length(f$units)!=1L||!f$units%in%units)stop("Choose units matching the selected measurement source.")
   for(n in c("detection","prevalence"))if(!is.numeric(f[[n]])||length(f[[n]])!=1L||!is.finite(f[[n]])||f[[n]]<0)stop("The ",n," threshold must be a finite nonnegative number.")
   if(f$prevalence>1)stop("Prevalence must be a proportion from 0 to 1.")
   for(n in c("detection_operator","prevalence_operator"))if(length(f[[n]])!=1L||!f[[n]]%in%c(">",">="))stop("Choose > or >= independently for detection and prevalence.")
   threshold<-f$detection/if(f$units=="percentage")100 else 1
   if(f$source=="relative"&&threshold>1)stop("Relative detection must be from 0 to 1 proportion (0 to 100 percent).")
   prevalence<-mia::getPrevalence(cohort,assay.type=f$source,rank=NULL,as.relative=FALSE,
    detection=threshold,include.lowest=f$detection_operator==">=",sort=FALSE,na.rm=FALSE)
   if(!identical(names(prevalence),taxa))stop("Upstream prevalence changed feature identity.")
   numerator<-as.integer(round(prevalence*ncol(cohort)))
   retained<-unname(if(f$prevalence_operator==">=")prevalence>=f$prevalence else prevalence>f$prevalence)
   if(f$source=="estimated_reads")source_label<-"Estimated reads (not observed counts)"
  }
  p$preparation$features<-data.frame(feature_id=taxa,numerator=numerator,denominator=ncol(cohort),prevalence=unname(prevalence),retained=retained,
   reason=if(!enabled)"filter disabled" else ifelse(retained,"prevalence threshold met","prevalence threshold not met"),source=if(enabled)f$source else "not applied",source_label=if(enabled)source_label else "not applied",units=if(enabled)f$units else "not applied",detection=if(enabled)f$detection else NA_real_,detection_operator=if(enabled)f$detection_operator else "not applied",effective_detection=threshold,prevalence_threshold=if(enabled)f$prevalence else NA_real_,prevalence_operator=if(enabled)f$prevalence_operator else "not applied",row.names=NULL)
  p$mass<-p$canonical_mass[match(colnames(cohort),p$canonical_mass$sample_id),,drop=FALSE];rownames(p$mass)<-NULL
  p$mass$canonical_selected<-p$mass$selected
  p$mass$feature_removed<-colSums(SummarizedExperiment::assay(cohort,"relative")[!retained,,drop=FALSE])
  p$mass$selected<-colSums(SummarizedExperiment::assay(cohort,"relative")[retained,,drop=FALSE])
  p$mass$feature_removed_estimated_reads<-if("estimated_reads"%in%SummarizedExperiment::assayNames(cohort))colSums(SummarizedExperiment::assay(cohort,"estimated_reads")[!retained,,drop=FALSE]) else NA_real_
  versions<-vapply(c("microbiomeengine","mia","TreeSummarizedExperiment"),function(n)as.character(utils::packageVersion(n)),character(1))
  # Named source identity is independent of legacy/current list insertion order.
  sources<-p$input$sources[sort(names(p$input$sources),method="radix")]
  parent_hash<-preparation_fingerprint(list(source_hashes=vapply(sources,function(z)z$sha256,character(1)),original_values=p$input$values,original_metadata=p$input$metadata,assays=assay_snapshot(parent),metadata=meta,declarations=p$declarations,design=p$design,normalization=p$normalization))
  op<-list(operation="prepare_view",order=c("select_cohort","calculate_prevalence_on_cohort","filter_named_features"),parent=parent_hash,rank=p$declarations$rank,source=if(enabled)f$source else "not applied",units=if(enabled)f$units else "not applied",settings=s,versions=versions,normalization=p$normalization,unclassified_policy="exempt; align to retained sample IDs",retained_samples=ids[keep],excluded_samples=ids[!keep],retained_features=taxa[retained],excluded_features=taxa[!retained],cohort_fingerprint=preparation_fingerprint(ids[keep]),feature_fingerprint=preparation_fingerprint(taxa[retained]))
  op$result_fingerprint<-preparation_fingerprint(assay_snapshot(cohort[retained,,drop=FALSE]))
  op$fingerprint<-preparation_fingerprint(list(op,p$preparation$samples,p$preparation$features,p$mass))
  p$preparation$operation<-op
  p$history[[length(p$history)+1L]]<-op
  if(!any(retained))stop("No named features retained at this rank: review the detection/prevalence choices or disable the feature filter. Supplied Unclassified is exempt; no stale composition is available.")
  p$experiment<-cohort[retained,,drop=FALSE]
  p$preparation$status<-"ready"
  p
 },error=function(e){
  p$experiment<-NULL;p$table<-NULL;p$membership<-NULL;p$display_mass<-NULL
  p$preparation$status<-"blocked"
  p$findings[nrow(p$findings)+1L,]<-list("preparation_blocked","error","Preparation",conditionMessage(e),"Edit the retained controls and apply again, or reset preparation. Current analysis exports are blocked.")
  p
 })
}
apply_preparation <- function(project,preparation=list()) {
 check_project(project)
 retain_analysis(project,prepare_project(project$input,project$declarations,project$design,project$settings,preparation))
}

