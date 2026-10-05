args<-commandArgs(TRUE)
if(length(args)>1L).libPaths(c(normalizePath(args[2],winslash="/"),file.path(normalizePath(args[1],winslash="/"),".library"),.libPaths()))
library(microbiomeengine)
p<-example_project();SummarizedExperiment::assay(p$experiment,"relative")[1,1]<-0
seeded<-microbiomeengine:::app_server
environment(seeded)<-list2env(list(seed_project=p),parent=environment(seeded));formals(seeded)$project<-quote(seed_project)
shiny::testServer(seeded,{
 session$setInputs(beta_metric="bray",beta_correction="none",beta_max_samples=500,beta_apply=1)
 stopifnot(state()$beta$status=="ready");old<-state()$beta$distance
 session$setInputs(beta_metric="aitchison",beta_zero_policy="positive",beta_pseudocount=0)
 stopifnot(grepl("Unapplied",output$beta_pending),inherits(try(beta_guard(),silent=TRUE),"try-error"),identical(old,state()$beta$distance))
 session$setInputs(beta_apply=2);stopifnot(state()$beta$status=="blocked",grepl("zeros",output$beta_status))
 session$setInputs(beta_zero_policy="add",beta_pseudocount=.001,beta_apply=3)
 stopifnot(state()$beta$status=="ready",grepl("Aitchison",plot_beta(state())$labels$title));beta_guard()
 session$setInputs(beta_pseudocount=.002);stopifnot(inherits(try(beta_guard(),silent=TRUE),"try-error"))
 session$setInputs(beta_apply=4);beta_guard()
 session$setInputs(beta_metric="robust.aitchison",beta_robust_rank=1,beta_robust_niter=5,beta_robust_tol=1e-5,beta_apply=5)
 stopifnot(state()$beta$settings$metric=="robust.aitchison",is.null(state()$beta$settings$pseudocount))
 # A tiny sparse example may fail optimization; the saved status must be truthful.
 if(state()$beta$status=="ready")stopifnot(grepl("Robust Aitchison",plot_beta(state())$labels$title)) else stopifnot(nzchar(state()$beta$reason))
 session$setInputs(beta_metric="bray",beta_apply=6);stopifnot(state()$beta$status=="ready",identical(old,state()$beta$distance),length(state()$beta$settings)==3L);beta_guard()
})
cat("PASS three-metric controls, pending/export guard, zero block/add recovery, robust separate settings and Bray restoration\n")
