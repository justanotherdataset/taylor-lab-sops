beta_settings <- function(settings=list()) {
 d<-list(metric="bray",correction="none",max_samples=500L)
 if(!is.list(settings))stop("Beta settings must be a named list.")
 metric<-if(is.null(settings$metric))"bray" else settings$metric
 if(!is.character(metric)||length(metric)!=1L||is.na(metric)||!metric%in%c("bray","aitchison","robust.aitchison"))stop("Choose Bray, Aitchison or robust Aitchison.")
 if(metric!="bray")d<-c(d,list(source="relative",units="proportion"),if(metric=="aitchison")list(zero_policy="positive",pseudocount=0) else list(robust_rank=3L,robust_niter=5L,robust_tol=1e-5))
 if(!is.list(settings)||length(setdiff(names(settings),names(d))))stop("Unknown beta calculation setting.")
 s<-modifyList(d,settings)
 if(length(s$correction)!=1L||is.na(s$correction)||!s$correction%in%c("none","lingoes"))stop("Choose original geometry or Lingoes correction.")
 if(metric!="bray") {
  if(!identical(s$source,"relative")||!identical(s$units,"proportion"))stop("Log-ratio distances require prepared relative proportions, not derived layers.")
  if(s$correction!="none")stop("Aitchison methods use original Euclidean geometry; correction must be none.")
  if(metric=="aitchison")assay_settings(list(name="beta_clr",method="clr",zero_policy=s$zero_policy,pseudocount=s$pseudocount))
  else {
   for(n in c("robust_rank","robust_niter"))if(!is.numeric(s[[n]])||length(s[[n]])!=1L||!is.finite(s[[n]])||s[[n]]!=floor(s[[n]])||s[[n]]<(if(n=="robust_rank")1 else 2)||s[[n]]>1000)stop("Robust rank must be an integer 1..1000 and iterations 2..1000.")
   if(!is.numeric(s$robust_tol)||length(s$robust_tol)!=1L||!is.finite(s$robust_tol)||s$robust_tol<=0)stop("Robust tolerance must be finite and positive.")
  }
 }
 if(length(s$max_samples)!=1L||!is.numeric(s$max_samples)||!is.finite(s$max_samples)||s$max_samples<2||s$max_samples>2000||s$max_samples!=as.integer(s$max_samples))stop("Sample limit must be an integer from 2 to 2000; distance/eigen storage grows quadratically.")
 s
}
beta_parent <- function(project,settings) {
 if(is.null(project$experiment)||!identical(project$preparation$status,"ready"))stop("Apply valid Preparation before beta calculation.")
 m<-SummarizedExperiment::assay(project$experiment,"relative")
 if(!is.numeric(m)||!nrow(m)||ncol(m)<2L||ncol(m)>settings$max_samples||any(!is.finite(m))||any(m<0))stop("Beta needs finite nonnegative named measurements, at least two samples, and a cohort within the configured sample limit.")
 for(ids in dimnames(m))if(is.null(ids)||anyNA(ids)||any(!nzchar(trimws(ids)))||anyDuplicated(ids))stop("Beta requires unique nonblank feature and sample IDs.")
 if(any(!is.finite(colSums(m)))||any(colSums(m)<=0))stop("Every beta sample needs positive finite retained named-feature mass.")
 meta<-as.data.frame(SummarizedExperiment::colData(project$experiment))
 if(!identical(rownames(meta),colnames(m)))stop("Beta metadata is not aligned by full sample ID.")
 sources<-project$input$sources[sort(names(project$input$sources),method="radix")]
 versions<-vapply(c("mia","vegan","permute"),function(n)as.character(utils::packageVersion(n)),character(1))
 fp<-preparation_fingerprint(list(assay=m,rank=project$declarations$rank,settings=settings,sources=vapply(sources,function(z)z$sha256,character(1)),preparation=project$preparation$settings,normalization=project$normalization,versions=versions,definition=if(settings$metric=="bray")"beta-bray-v1" else paste0("beta-",settings$metric,"-v1")))
 list(matrix=m,metadata=meta,fingerprint=fp,versions=versions)
}
beta_ordination <- function(distance,correction="none") {
 out<-list(status="undefined",reason="No positive ordination dimensions.",correction=correction,constant=0,distance=distance,scores=data.frame(),eigenvalues=numeric(),negative_scores=NULL,warnings=character())
 if(all(distance==0))return(out)
 fit<-withCallingHandlers(vegan::wcmdscale(distance,eig=TRUE,add=if(correction=="none")FALSE else "lingoes"),warning=function(w){out$warnings<<-c(out$warnings,conditionMessage(w));invokeRestart("muffleWarning")})
 out$eigenvalues<-fit$eig;out$constant<-if(is.null(fit$ac))0 else fit$ac;out$negative_scores<-fit$negaxes;out$gof<-fit$GOF
 if(correction=="lingoes")out$distance<-sqrt(distance^2+2*out$constant)
 eig<-fit$eig;tol<-max(abs(eig),0)*sqrt(.Machine$double.eps);out$tolerance<-tol
 out$positive_inertia<-sum(eig[eig>0]);out$negative_inertia<-sum(abs(eig[eig<0]));out$largest_negative<-abs(min(c(0,eig)))
 out$diagnostics<-data.frame(axis=seq_along(eig),eigenvalue=eig,positive_share=ifelse(eig>0,eig/out$positive_inertia,NA_real_),negative=eig<0)
 if(!is.null(fit$points)&&ncol(as.matrix(fit$points))>0L) {
  points<-as.matrix(fit$points);colnames(points)<-paste0("PCoA",seq_len(ncol(points)))
  out$scores<-data.frame(sample_id=rownames(points),points,row.names=NULL,check.names=FALSE);out$status<-"ready";out$reason<-""
 }
 out$fingerprint<-preparation_fingerprint(list(distance=out$distance,correction=correction,constant=out$constant));out
}
beta_metric_label <- function(metric)switch(metric,bray="Bray",aitchison="Aitchison",robust.aitchison="Robust Aitchison",metric)
beta_logratio <- function(project,s) {
 z<-assay_parent(project,list(source=s$source,units=s$units));m<-z$matrix
 out<-list(status="blocked",reason="",settings=s,source_meaning=z$meaning,source_hash=preparation_fingerprint(m),rank=project$declarations$rank,features=rownames(m),samples=colnames(m),zero_mask=m==0,source_zeros=sum(m==0),margin="samples (columns)",warnings=character(),values=NULL)
 tryCatch(withCallingHandlers({
  if(nrow(m)<2L)stop("Log-ratio distances require at least two retained named features.")
  if(s$metric=="aitchison") {
   if(any(!is.finite(m+s$pseudocount)))stop("Source plus pseudocount overflows.")
   if(any(m+s$pseudocount<=0))stop("Positive-only CLR cannot use zeros. Choose explicit addition in proportion units.")
   obj<-SummarizedExperiment::SummarizedExperiment(assays=list(source=m))
   obj<-mia::transformAssay(obj,assay.type="source",method="clr",MARGIN="samples",name="transformed",pseudocount=s$pseudocount,na.rm=FALSE)
   raw<-SummarizedExperiment::assay(obj,"transformed")
   out$formula<-assay_formula("clr");out$addition_scope<-if(s$pseudocount>0)"Every retained cell, including positive values, before log" else "No addition"
   out$affected_cells<-if(s$pseudocount>0)length(m) else 0L
   out$readable_call<-"mia::transformAssay(source, assay.type='source', method='clr', MARGIN='samples', name='transformed', pseudocount=settings$pseudocount, na.rm=FALSE)"
  } else {
   out$formula<-"ln(x) minus mean ln(x) over positive features within sample; zeros missing; optspace completion and double centering when missing"
   observed<-vegan::decostand(t(m),method="rclr",MARGIN=1,na.rm=FALSE,impute=FALSE)
   out$observed<-t(observed);out$optimizer<-list(status="not_needed",impute=TRUE,used=anyNA(observed),requested=list(rank=s$robust_rank,niter=s$robust_niter,tol=s$robust_tol),effective_rank=NA_integer_,iterations=0L,initialization="Deterministic SVD; no RNG or seed",result=NULL)
   out$readable_call<-"observed <- vegan::decostand(t(source), method='rclr', MARGIN=1, na.rm=FALSE, impute=FALSE)"
   if(anyNA(observed)) {
    out$optimizer$status<-"failed"
    if(any(rowSums(m>0)==0))stop("Robust completion cannot estimate an entirely zero feature; review Preparation explicitly.")
    if(s$robust_rank>min(dim(observed)))stop("Robust rank exceeds the sample/feature dimensions; choose an explicit smaller rank.")
    if(sum(observed[is.finite(observed)]^2)==0)stop("Observed rCLR has zero energy; robust completion is undefined.")
    fit<-vegan::optspace(observed,ropt=s$robust_rank,niter=s$robust_niter,tol=s$robust_tol,verbose=FALSE)
    out$optimizer$result<-fit;out$optimizer$effective_rank<-ncol(fit$X);out$optimizer$iterations<-length(fit$dist)-1L
    out$optimizer$status<-if(is.finite(utils::tail(as.numeric(fit$dist),1))&&utils::tail(as.numeric(fit$dist),1)<s$robust_tol)"converged" else "iteration_limit"
    if(out$optimizer$status=="iteration_limit")warning("Robust completion reached the iteration limit without meeting tolerance; inspect the saved scaled residual history.")
    raw<-t(fit$M)
    out$readable_call<-c(out$readable_call,"fit <- vegan::optspace(observed, ropt=settings$robust_rank, niter=settings$robust_niter, tol=settings$robust_tol, verbose=FALSE); transformed <- t(fit$M)")
   } else raw<-t(observed)
  }
  if(!identical(dimnames(raw),dimnames(m))||any(!is.finite(raw)))stop("Log-ratio transform changed identity or returned nonfinite values.")
  out$values<-matrix(as.numeric(raw),nrow(m),ncol(m),dimnames=dimnames(m))
  out$versions<-vapply(c("mia","vegan","SummarizedExperiment"),function(n)as.character(utils::packageVersion(n)),character(1))
  out$readable_call<-c(out$readable_call,"mia::getDissimilarity(transformed_se, assay.type='transformed', method='euclidean', binary=FALSE, niter=NULL, transposed=FALSE, na.rm=FALSE)")
  out$status<-"ready";out$fingerprint<-preparation_fingerprint(out);out
 },warning=function(w){out$warnings<<-c(out$warnings,conditionMessage(w));invokeRestart("muffleWarning")}),error=function(e){out$reason<-conditionMessage(e);out})
}
calculate_beta <- function(project,settings=list()) {
 out<-list(status="blocked",reason="",settings=settings,distance=NULL,ordination=NULL,metadata=NULL,mass=project$mass)
 tryCatch({
  s<-beta_settings(settings);out$settings<-s;z<-beta_parent(project,s);out$fingerprint<-z$fingerprint;out$metadata<-z$metadata;out$metadata_types<-project$design$types;out$versions<-z$versions
  out$rank<-project$declarations$rank;out$features<-rownames(z$matrix);out$sample_ids<-colnames(z$matrix)
  out$source_label<-if(is_estimate_only(project$input))"Relative estimated-read contribution (not observed counts)" else "Supplied relative abundance"
  out$normalization<-"Bray on retained named measurements; no reclosure, rarefaction, top-N or display aggregation. Supplied Unclassified is outside the analytical feature matrix."
  if(s$metric=="bray")d<-mia::getDissimilarity(project$experiment,assay.type="relative",method="bray",binary=FALSE,niter=NULL,transposed=FALSE,na.rm=FALSE)
  else {
   out$normalization<-paste(beta_metric_label(s$metric),"on prepared named-feature proportions; natural log ratios, no reclosure or display aggregation. Supplied Unclassified is outside the analytical matrix.")
   out$transformation<-beta_logratio(project,s)
   if(out$transformation$status!="ready")stop(out$transformation$reason)
   obj<-SummarizedExperiment::SummarizedExperiment(assays=list(transformed=out$transformation$values))
   d<-mia::getDissimilarity(obj,assay.type="transformed",method="euclidean",binary=FALSE,niter=NULL,transposed=FALSE,na.rm=FALSE)
  }
  if(!inherits(d,"dist")||!identical(attr(d,"Labels"),out$sample_ids)||any(!is.finite(d))||any(d<0))stop("Upstream distance changed identity or returned invalid values.")
  out$distance<-d;out$distance_hash<-preparation_fingerprint(d);out$ordination<-beta_ordination(d,s$correction);out$status<-"ready";out
 },error=function(e){out$status<-"blocked";out$reason<-conditionMessage(e);out})
}
apply_beta <- function(project,settings=list(),plot_settings=list(),comparison=NULL,dispersion=NULL) {
 project$beta<-calculate_beta(project,settings);project$beta$plot_settings<-beta_plot_settings(plot_settings)
 project$beta$comparison<-if(is.null(comparison))NULL else compare_beta(project$beta,comparison)
 project$beta$dispersion<-if(is.null(dispersion))NULL else beta_dispersion(project$beta,dispersion);project
}
beta_current <- function(project,inference=TRUE) {
 b<-project$beta
 if(is.null(b)||b$status!="ready"||isTRUE(b$pending))stop("Apply valid current beta calculation before export.")
 z<-beta_parent(project,b$settings)
 if(!identical(z$fingerprint,b$fingerprint)||!identical(z$metadata,b$metadata))stop("Beta is stale; apply calculation again.")
 if(inference)for(n in c("comparison","dispersion"))if(!is.null(b[[n]])&&b[[n]]$status=="stale")stop("Apply the stale beta ",n," before export.")
 invisible(TRUE)
}
retain_beta <- function(old,new) {
 if(is.null(old$beta))return(new)
 b<-old$beta;z<-tryCatch(beta_parent(new,b$settings),error=function(e)NULL)
 if(is.null(z)||!identical(z$fingerprint,b$fingerprint)){b$status<-"stale";b$reason<-"Prepared measurements, source, rank or cohort changed. Apply beta again."}
 else if(!identical(z$metadata,b$metadata)||!identical(new$design$types,b$metadata_types)) {
  b$metadata<-z$metadata;b$metadata_types<-new$design$types
  for(n in c("comparison","dispersion"))if(!is.null(b[[n]])){b[[n]]$status<-"stale";b[[n]]$reason<-"Metadata/design changed. Reapply this inference request."}
 }
 new$beta<-b;new
}
retain_analysis <- function(old,new)retain_assays(old,retain_beta(old,retain_alpha(old,new)))
