args<-commandArgs(TRUE)
if(length(args)>1L).libPaths(c(normalizePath(args[2],winslash="/"),file.path(normalizePath(args[1],winslash="/"),".library"),.libPaths()))
library(microbiomeengine)
seeded<-microbiomeengine:::app_server
environment(seeded)<-list2env(list(seed_project=example_project()),parent=environment(seeded));formals(seeded)$project<-quote(seed_project)
shiny::testServer(seeded,{
 original<-state()$input;allids<-original$sample_ids
 session$setInputs(prep_samples_enabled=TRUE,prep_sample_ids=allids[1:2],prep_group_enabled=FALSE,prep_time_enabled=FALSE,prep_filter_enabled=TRUE,prep_source="relative",prep_units="percentage",prep_detection=20,prep_detection_operator=">",prep_prevalence=.5,prep_prevalence_operator=">=")
 session$setInputs(prep_apply=1)
 stopifnot(identical(colnames(state()$experiment),allids[1:2]),identical(state()$input,original),grepl("2 of 4",output$preparation_summary),!is.null(state()$table))
 applied<-state()$preparation$settings
 s<-state()$settings
 session$setInputs(plot_rank="g",plot_group=s$group,plot_facet=s$facet,plot_order=s$order,plot_palette=s$palette,plot_residual=s$residual,taxa_mode="top",top_n=1L,show_other=FALSE,show_unclassified=TRUE)
 session$setInputs(plot_apply=1)
 stopifnot(identical(state()$preparation$settings,applied),all(state()$table$rank=="g"),identical(colnames(state()$experiment),allids[1:2]))
 session$setInputs(prep_sample_ids=character(),prep_apply=2)
 stopifnot(is.null(state()$table),is.null(state()$experiment),grepl("No samples",output$preparation_findings),grepl("prep_apply",as.character(microbiomeengine:::app_ui()),fixed=TRUE))
 session$setInputs(prep_sample_ids=allids[1:2],prep_apply=3)
 stopifnot(!is.null(state()$table),identical(colnames(state()$experiment),allids[1:2]))
 session$setInputs(prep_reset=1)
 stopifnot(identical(colnames(state()$experiment),allids),!state()$preparation$settings$filter$enabled,identical(state()$input,original))
 session$setInputs(prep_group_field="group",prep_time_field="time")
 stopifnot(grepl("Exact group values",output$prep_group_choices$html,fixed=TRUE),grepl("Inclusive typed range",output$prep_time_choices$html,fixed=TRUE))
})
cat("PASS actual Shiny preparation apply, empty failure/recovery, rank recalculation and reset\n")
