args<-commandArgs(TRUE)
if(length(args)>1L).libPaths(c(normalizePath(args[2],winslash="/"),file.path(normalizePath(args[1],winslash="/"),".library"),.libPaths()))
library(microbiomeengine)
seeded<-microbiomeengine:::app_server
environment(seeded)<-list2env(list(seed_project=example_project()),parent=environment(seeded));formals(seeded)$project<-quote(seed_project)
shiny::testServer(seeded,{
 session$setInputs(beta_correction="none",beta_max_samples=500,beta_apply=1)
 stopifnot(state()$beta$status=="ready");D<-state()$beta$distance
 session$setInputs(beta_group="group",beta_colour="group",beta_shape="unit",beta_fixed_colour="#336699",beta_fixed_shape=17L)
 stopifnot(grepl("Unapplied",output$beta_pending),inherits(try(beta_guard(),silent=TRUE),"try-error"))
 session$setInputs(beta_style_apply=1);stopifnot(identical(state()$beta$distance,D),state()$beta$plot_settings$shape=="unit")
 session$setInputs(beta_cmp_group="group",beta_cmp_unit="unit",beta_cmp_route="independent",beta_cmp_test="overall",beta_cmp_verified=FALSE,beta_cmp_assignment="independent_units",beta_cmp_evidence="Synthetic independent unit fixture",beta_perm_budget=17,beta_perm_seed=81,beta_perm_mode="sampled",beta_compare=1)
 stopifnot(state()$beta$comparison$status=="blocked")
 session$setInputs(beta_cmp_verified=TRUE,beta_preview=1,beta_plan_selected="draft")
 stopifnot(grepl("Draft",output$beta_plan_summary),grepl("source_id",output$beta_plan_preview))
 session$setInputs(beta_compare=2,beta_plan_selected="omnibus")
 stopifnot(state()$beta$comparison$status=="ready",state()$beta$comparison$results$omnibus$permutation$actual==17,state()$beta$comparison$settings$permutations$seed==81)
 old<-state()$beta$comparison
 session$setInputs(beta_fixed_colour="#770033",beta_style_apply=2);stopifnot(identical(state()$beta$comparison,old))
 session$setInputs(beta_perm_budget=9999,beta_perm_seed=82,beta_perm_mode="automatic")
 stopifnot(grepl("Unapplied",output$beta_pending));session$setInputs(beta_compare=3)
 stopifnot(state()$beta$comparison$results$omnibus$permutation$actual==23,state()$beta$comparison$results$omnibus$permutation$mode=="exhaustive")
 session$setInputs(beta_cmp_route="paired",beta_cmp_assignment="independent_subjects",beta_cmp_exchangeable=FALSE,beta_compare=4)
 stopifnot(state()$beta$comparison$status=="blocked")
 session$setInputs(beta_cmp_route="independent",beta_cmp_assignment="independent_units",beta_compare=5)
 stopifnot(state()$beta$comparison$status=="ready")
 session$setInputs(beta_disp_group="group",beta_disp_unit="unit",beta_disp_verified=TRUE,beta_disp_evidence="Synthetic independent dispersion units",beta_dperm_budget=17,beta_dperm_seed=99,beta_dperm_mode="sampled",beta_disp_apply=1)
 # Two observations per group have identical median distances within each group.
 # This tiny UI fixture must expose the degeneracy, not fabricate a dispersion test.
 stopifnot(state()$beta$dispersion$status=="blocked",grepl("degenerate",state()$beta$dispersion$reason),state()$beta$dispersion$settings$permutations$seed==99)
 session$setInputs(prep_samples_enabled=TRUE,prep_sample_ids=c("S1","S2"),prep_group_enabled=FALSE,prep_time_enabled=FALSE,prep_filter_enabled=FALSE,prep_source="relative",prep_units="proportion",prep_detection=0,prep_detection_operator=">",prep_prevalence=0,prep_prevalence_operator=">=",prep_apply=1)
 stopifnot(state()$beta$status=="stale",inherits(try(beta_guard(),silent=TRUE),"try-error"))
})
cat("PASS Shiny calculation/style invariance, pending guard, customized budget/seed/mode, legal preview, blocked/recovery, separate dispersion and stale Preparation\n")
