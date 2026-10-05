args<-commandArgs(TRUE)
if(length(args)>=2L) .libPaths(c(normalizePath(args[2],winslash="/"),file.path(normalizePath(args[1],winslash="/"),".library"),.libPaths()))
library(microbiomeengine)
data<-system.file("extdata",package="microbiomeengine")
if(length(args))data<-file.path(args[1],"inst","extdata")
p<-example_project();d<-modifyList(p$declarations,list(estimate_unit="estimated_reads"))
x<-import_metaphlan(file.path(data,"abundance.tsv"),file.path(data,"metadata.csv"),estimates=file.path(data,"estimated-reads.tsv"))
paired<-prepare_project(x,d,p$design)
stopifnot(identical(SummarizedExperiment::assay(paired$experiment,"relative"),SummarizedExperiment::assay(p$experiment,"relative")))
stopifnot(identical(SummarizedExperiment::assay(paired$experiment,"estimated_reads")[1,],c(S1=100,S2=200,S3=400,S4=300)))
only<-import_metaphlan(NULL,file.path(data,"metadata.csv"),estimates=file.path(data,"estimated-reads.tsv"))
blocked<-prepare_project(only,d,p$design)
stopifnot(is.null(blocked$experiment),"estimate_opt_in"%in%blocked$findings$code)
estimated<-prepare_project(only,modifyList(d,list(estimate_normalization=TRUE)),p$design)
stopifnot(!is.null(estimated$experiment),estimated$normalization$source=="estimated_contribution")
stopifnot(identical(unname(estimated$mass$denominator_total),rep(1000,4)))
stopifnot(!isTRUE(all.equal(SummarizedExperiment::assay(estimated$experiment,"relative"),SummarizedExperiment::assay(paired$experiment,"relative"))))
stopifnot(grepl("estimated read contribution",unique(estimated$table$denominator),fixed=TRUE))
cat("PASS separate measurement identity, supplied-relative preference and explicit differing estimated contribution\n")
for(kind in c("duplicate","blank","sample_mismatch","taxon_mismatch","negative","missing","infinite","database","version","bases","marker_command","unit")) {
 bad<-x;dd<-d
 if(kind=="duplicate")bad$estimated$sample_ids[2]<-bad$estimated$sample_ids[1]
 if(kind=="blank")bad$estimated$feature_ids[2]<-""
 if(kind=="sample_mismatch")bad$estimated$sample_ids[2]<-"absent"
 if(kind=="taxon_mismatch")bad$estimated$feature_ids[6]<-"k__Bacteria|s__Absent"
 if(kind=="negative")bad$estimated$values[2,1]<- -1
 if(kind=="missing")bad$estimated$values[2,1]<-NA_real_
 if(kind=="infinite")bad$estimated$values[2,1]<-Inf
 if(kind=="database"){bad$comments<-"#mpa_A";bad$estimated$comments<-"#mpa_B"}
 if(kind=="version"){bad$comments<-"#MetaPhlAn version 4.2.4";bad$estimated$comments<-"#MetaPhlAn version 3.0.1"}
 if(kind=="bases")bad$estimated$comments<-"#measurement=estimated_bases"
 if(kind=="marker_command")bad$estimated$comments<-"#metaphlan input -t marker_ab_table"
 if(kind=="unit")dd$estimate_unit<-"observed_counts"
 stopifnot(is.null(prepare_project(bad,dd,p$design)$experiment))
}
zero<-only;zero$values[,1]<-0;zero$estimated$values[,1]<-0
stopifnot("estimate_zero_total"%in%prepare_project(zero,modifyList(d,list(estimate_normalization=TRUE)),p$design)$findings$code)
top<-prepare_project(x,d,p$design,list(taxa_mode="top",top_n=1L))
stopifnot(nrow(top$experiment)==2L,length(unique(top$table$taxon))==3L)
stopifnot(all(abs(tapply(top$table$value,top$table$sample_ids,sum)-.9)<1e-12))
stopifnot(any(top$table$category=="other"),all(grepl("k__",top$membership$source_taxon)))
hidden<-prepare_project(x,d,p$design,list(taxa_mode="top",top_n=1L,show_other=FALSE,show_unclassified=FALSE))
stopifnot(all(abs(hidden$table$value+hidden$table$omitted_mass-.9)<1e-12))
alln<-prepare_project(x,d,p$design,list(taxa_mode="top",top_n=200L))
stopifnot(!any(alln$table$category=="other"),identical(SummarizedExperiment::assay(alln$experiment),SummarizedExperiment::assay(paired$experiment)))
# Ties rank by full IDs; group means do not rerank taxa or weight large groups equally.
tie<-x;tie$values[5:6,]<-40
tie$metadata$group<-c("large","large","large","small")
tie$metadata$panel<-c("P1","P1","P2","P2")
tied<-prepare_project(tie,d,p$design,list(taxa_mode="top",top_n=1,group="group",facet="panel"))
stopifnot(identical(unique(tied$table$taxon[tied$table$category=="taxon"]),sort(rownames(tied$experiment),method="radix")[1]))
stopifnot(all(abs(tapply(tied$table$value,interaction(tied$table$display,tied$table$facet,drop=TRUE),sum)-.9)<1e-12))
# Preserve canonical >500 taxa; reduction happens before upstream plotting.
large<-p$input;large$feature_ids<-paste0("k__Bacteria|s__Taxon_",sprintf("%04d",1:510))
large$values<-matrix(90/510,510,4,dimnames=list(large$feature_ids,p$input$sample_ids))
large$estimated<-NULL
limited<-prepare_project(large,p$declarations,p$design)
stopifnot(nrow(limited$experiment)==510L,is.null(limited$table),"composition_limit"%in%limited$findings$code)
reduced<-prepare_project(large,p$declarations,p$design,list(taxa_mode="top",top_n=8))
stopifnot(nrow(reduced$experiment)==510L,length(unique(reduced$table$taxon))==9L,nrow(reduced$membership)==510L)
stopifnot(all(abs(tapply(reduced$table$value,reduced$table$sample_ids,sum)-.9)<1e-12))
cat("PASS invalid inputs, topN/Other/supplied-Unclassified mass, tie/group/facet and >500 recovery invariants\n")
# Unequal groups must not determine top-taxon ranking.
unequal<-p$input;unequal$values[5,]<-c(55,55,55,0);unequal$values[6,]<-c(25,25,25,80)
unequal$metadata$group<-ifelse(unequal$metadata$sample_id=="S4","small","large")
u<-prepare_project(unequal,p$declarations,p$design,list(taxa_mode="top",top_n=1,group="group"))
stopifnot(all(grepl("Alpha",u$table$taxon[u$table$category=="taxon"])))
stopifnot(identical(sort(unique(u$table$n_samples)),c(1L,3L)))
labels<-microbiomeengine:::taxon_labels(c("k__Bacteria|s__Other_-_named_taxa","[Other - named taxa]","k__Bacteria|s__Supplied_unclassified","[Supplied unclassified]"))
stopifnot(!anyDuplicated(labels))
# Native input schemas and conflicting command/unit evidence are rejected.
for(header in c("relative_abundance","estimated_number_of_bases_from_the_clade","marker_abundance")) {
 f<-tempfile(fileext=".tsv");writeLines(c(paste("clade_name",header,sep="\t"),"k__Bacteria\t1"),f)
 stopifnot(inherits(try(import_metaphlan(f,file.path(data,"metadata.csv")),silent=TRUE),"try-error"))
}
for(change in list(list(width=0),list(height=Inf),list(dpi=20),list(units="px"),list(format="jpeg"),list(width=40,height=40,dpi=600)))stopifnot(inherits(try(microbiomeengine:::figure_settings(change),silent=TRUE),"try-error"))
run<-tempfile("controls-");dir.create(run)
for(format in c("png","pdf",if(requireNamespace("svglite",quietly=TRUE))"svg")) {
 fig<-file.path(run,paste0("composition.",format));export_figure(top,fig,list(format=format,width=16,height=12,units="cm",dpi=100))
 signature<-readBin(fig,"raw",n=8)
 if(format=="png")stopifnot(identical(signature,as.raw(c(137,80,78,71,13,10,26,10))))
 if(format=="pdf")stopifnot(rawToChar(signature[1:4])=="%PDF")
 if(format=="svg")stopifnot(any(grepl("<svg",readLines(fig,warn=FALSE),fixed=TRUE)))
 stopifnot(inherits(try(export_figure(top,fig,list(format=format)),silent=TRUE),"try-error"))
}
# Separate original byte streams, exact table and saved settings survive clean replay.
for(route in c("paired","estimated")) {
 q<-if(route=="paired")top else estimated
 q$settings$figure<-microbiomeengine:::figure_settings(list(format="pdf",width=16,height=12,units="cm",dpi=120))
 bundle<-file.path(run,route);export_project(q,bundle)
 oldlib<-Sys.getenv("R_LIBS_USER");Sys.unsetenv("R_LIBS_USER")
 result<-system2(file.path(R.home("bin"),"Rscript.exe"),c("--vanilla",shQuote(file.path(bundle,"replay.R")),shQuote(bundle),shQuote(paste0(bundle,"-replay"))),stdout=TRUE,stderr=TRUE)
 Sys.setenv(R_LIBS_USER=oldlib);cat(paste(result,collapse="\n"),"\n")
 stopifnot(is.null(attr(result,"status")),file.exists(file.path(paste0(bundle,"-replay"),"VERIFIED")))
 freshscript<-file.path(run,paste0(route,"-freshplot.R"));writeLines(c(paste0(".libPaths(",paste(deparse(.libPaths()),collapse=""),")"),paste0("p<-microbiomeengine::open_project(",deparse(file.path(bundle,"project.rds")),")"),paste0("microbiomeengine::export_figure(p,",deparse(file.path(run,paste0(route,"-freshplot.pdf"))),")")),freshscript)
 resultplot<-system2(file.path(R.home("bin"),"Rscript.exe"),c("--vanilla",shQuote(freshscript)),stdout=TRUE,stderr=TRUE);stopifnot(is.null(attr(resultplot,"status")))
 reopened<-open_project(file.path(bundle,"project.rds"));stopifnot(identical(q$settings,reopened$settings),identical(q$table,reopened$table))
 for(n in names(q$input$sources))stopifnot(identical(q$input$sources[[n]]$bytes,reopened$input$sources[[n]]$bytes))
}
legacy<-p;legacy$schema<-2L;legacy$settings<-legacy$settings[c("group","facet","order","palette","residual")]
legacy_file<-file.path(run,"schema2.rds");saveRDS(legacy,legacy_file);migrated<-open_project(legacy_file)
stopifnot(migrated$schema==4L,identical(SummarizedExperiment::assay(migrated$experiment,"relative"),SummarizedExperiment::assay(p$experiment,"relative")),identical(migrated$table,p$table))
cat("PASS reserved labels, unequal original-sample ranking, native-schema rejection, figures, migration and fresh multisource replay\n")
# Exercise >500 recovery and actual Shiny download content at an extensionless target.
seeded<-microbiomeengine:::app_server
environment(seeded)<-list2env(list(seed_project=limited),parent=environment(seeded));formals(seeded)$project<-quote(seed_project)
shiny::testServer(seeded,{
 stopifnot(is.null(state()$table),nrow(state()$experiment)==510L)
 session$setInputs(plot_group="",plot_facet="",plot_order="input",plot_palette="viridis",plot_residual=FALSE,taxa_mode="top",top_n=8,show_other=TRUE,show_unclassified=TRUE)
 session$setInputs(plot_apply=1)
 stopifnot(!is.null(state()$table),length(unique(state()$table$taxon))==9L)
 session$setInputs(figure_format="pdf",figure_width=10,figure_height=8,figure_units="in",figure_dpi=100)
 stopifnot(state()$settings$figure$format=="png",grepl("Pending",output$figure_status))
 session$setInputs(figure_apply=1)
 stopifnot(state()$settings$figure$format=="pdf",!grepl("Pending",output$figure_status),tail(state()$history,1)[[1]]$operation=="figure_settings")
 downloaded<-output$figure_download
 stopifnot(file.exists(downloaded),rawToChar(readBin(downloaded,"raw",n=4))=="%PDF")
 tabfile<-output$table_download
 stopifnot(file.exists(tabfile),nrow(read.delim(tabfile))==nrow(state()$table))
})
shiny::testServer(microbiomeengine:::app_server,{
 session$setInputs(estimates=data.frame(name="estimated-reads.tsv",datapath=file.path(data,"estimated-reads.tsv")),metadata=data.frame(name="metadata.csv",datapath=file.path(data,"metadata.csv")))
 session$setInputs(import=1)
 stopifnot(is.null(state()$experiment),is.null(state()$input$sources$abundance))
 session$setInputs(sample_id="sample_id",rank="s",estimate_unit="estimated_reads",estimate_normalization=TRUE,denominator_kind="unknown",coverage="unknown",pipeline="",database="",filtering="",unclassified="",design_group="",design_time="",design_unit="",repetition="unknown",type_1="text",type_2="text",type_3="text",type_4="text",type_5="text")
 session$setInputs(apply=1)
 stopifnot(!is.null(state()$table),state()$normalization$source=="estimated_contribution")
 stopifnot(!any(grepl("no normalization is applied",state()$findings$remedy,fixed=TRUE)))
})
cat("PASS Shiny estimated setup, applied export settings/download handlers and >500 recovery\n")
# Optional local real-pilot migration regression; package checks omit external artifact.
if(length(args)) {
 oldpath<-file.path(args[1],".artifacts","pilot-030-final","project.rds")
 if(file.exists(oldpath)) {
  old<-readRDS(oldpath);new<-open_project(oldpath)
  stopifnot(old$schema==2L,new$schema==4L)
  stopifnot(identical(old$input$sources,new$input$sources))
  for(a in SummarizedExperiment::assayNames(old$experiment))stopifnot(identical(SummarizedExperiment::assay(old$experiment,a),SummarizedExperiment::assay(new$experiment,a)))
  for(n in c("display","facet","taxon","value","n_samples","sample_ids"))stopifnot(identical(old$table[[n]],new$table[[n]]))
  cat("PASS actual feature030 schema2 pilot: preserved sources, assays and core table values\n")
 }
}
