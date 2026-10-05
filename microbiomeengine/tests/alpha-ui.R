args<-commandArgs(TRUE)
if(length(args)>1L).libPaths(c(normalizePath(args[2],winslash="/"),file.path(normalizePath(args[1],winslash="/"),".library"),.libPaths()))
library(microbiomeengine)
seeded<-microbiomeengine:::app_server
environment(seeded)<-list2env(list(seed_project=example_project()),parent=environment(seeded));formals(seeded)$project<-quote(seed_project)
shiny::testServer(seeded,{
 session$setInputs(alpha_source="relative",alpha_metrics=c("shannon","gini_simpson"),alpha_apply=1)
 stopifnot(state()$alpha$status=="ready",nrow(state()$alpha$values)==8L)
 saved<-state()$alpha$values
 session$setInputs(alpha_group="group",alpha_colour="group",alpha_shape="unit",alpha_fixed_colour="#336699",alpha_fixed_shape=17L)
 stopifnot(grepl("Unapplied",output$alpha_pending));stopifnot(inherits(try(alpha_guard(),silent=TRUE),"try-error"))
 session$setInputs(alpha_style_apply=1)
 stopifnot(identical(state()$alpha$values,saved),state()$alpha$plot_settings$shape=="unit")
 session$setInputs(alpha_cmp_group="group",alpha_cmp_reference="A",alpha_cmp_unit="unit",alpha_cmp_verified=FALSE,alpha_cmp_method="welch",alpha_cmp_evidence="Synthetic independent fixture",alpha_cmp_assignment="independent_units",alpha_compare=1)
 stopifnot(state()$alpha$comparison$status=="blocked",all(is.na(state()$alpha$comparison$tests$p_raw)))
 session$setInputs(alpha_cmp_verified=TRUE,alpha_compare=2)
 stopifnot(state()$alpha$comparison$status=="ready")
 before<-state()$alpha$comparison
 session$setInputs(alpha_fixed_colour="#990044",alpha_style_apply=2)
 stopifnot(identical(state()$alpha$comparison,before))
 session$setInputs(prep_samples_enabled=TRUE,prep_sample_ids=c("S1","S2"),prep_group_enabled=FALSE,prep_time_enabled=FALSE,prep_filter_enabled=FALSE,prep_source="relative",prep_units="proportion",prep_detection=0,prep_detection_operator=">",prep_prevalence=0,prep_prevalence_operator=">=",prep_apply=1)
 stopifnot(state()$alpha$status=="stale",inherits(try(alpha_guard(),silent=TRUE),"try-error"))
})
cat("PASS Shiny calculate, pending guard, styles, blocked/successful comparison, no refit, stale preparation\n")
