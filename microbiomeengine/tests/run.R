args <- commandArgs(TRUE)
root <- if(length(args)) normalizePath(args[1],winslash="/") else normalizePath(tempdir(),winslash="/")
if(length(args)) .libPaths(c(file.path(root,".library"),.libPaths()))
library(microbiomeengine)
p <- example_project()
# Real-profile decimal values can differ at machine precision across parsers.
decimal_input <- p$input
decimal_input$values[5,1] <- 34.74319
decimal_project <- prepare_project(decimal_input,p$declarations,p$design)
stopifnot(identical(SummarizedExperiment::assay(decimal_project$experiment,"original"),
 decimal_input$values[rownames(decimal_project$experiment),,drop=FALSE]))
# A real tutorial profile totals100.00001%; do not censor stacked segments.
rounding_input <- p$input
rounding_input$values[5,1] <- 70.00001
rounding_project <- prepare_project(rounding_input,p$declarations,p$design)
stopifnot("small_mass_excess" %in% rounding_project$findings$code)
geometry <- ggplot2::ggplot_build(plot_composition(rounding_project))$data[[1]]
stopifnot(all(is.finite(geometry$ymin)),all(is.finite(geometry$ymax)))
stopifnot(isTRUE(all.equal(sort(geometry$ymax-geometry$ymin),sort(rounding_project$table$value),tolerance=1e-12)))
# Missing categories must not collide with literal supplied category labels.
collision_input <- p$input
collision_input$metadata$group <- c('', '[Missing]', '[Missing] (missing values)', '[Missing] (missing values 2)')
for (field in c('group','facet')) {
 settings <- p$settings; settings[[field]] <- 'group'
 collision <- prepare_project(collision_input,p$declarations,p$design,settings)
 stopifnot(length(unique(collision$table[[if(field=='group') 'display' else 'facet']]))==4L)
 stopifnot(all(collision$table$n_samples==1L))
 for(id in p$input$sample_ids) {
  observed <- collision$table[collision$table$sample_ids==id,c('taxon','value')]
  expected <- p$table[p$table$sample_ids==id,c('taxon','value')]
  stopifnot(identical(observed$taxon,expected$taxon),identical(observed$value,expected$value))
 }
 stopifnot(identical(as.character(SummarizedExperiment::colData(collision$experiment)$group),
   collision_input$metadata$group[match(p$input$sample_ids,collision_input$metadata$sample_id)]))
 stopifnot(identical(plot_composition(collision)$data,collision$table))
}
cat('Missing-category group/facet identity and values passed\n')
stopifnot(inherits(p$experiment,"TreeSummarizedExperiment"))
stopifnot(identical(colnames(p$experiment),c("S1","S2","S3","S4")))
stopifnot(identical(as.character(SummarizedExperiment::colData(p$experiment)$sample_id),c("S1","S2","S3","S4")))
stopifnot(isTRUE(all.equal(unname(SummarizedExperiment::assay(p$experiment,"relative"))[1,],c(.6,.4,.2,.3))))
stopifnot(nrow(p$experiment)==2L, !"counts" %in% SummarizedExperiment::assayNames(p$experiment))
for(kind in c("duplicate","blank","unmatched","negative","nonfinite","range")) {
 x<-p$input
 if(kind=="duplicate") x$metadata$sample_id[2]<-x$metadata$sample_id[1]
 if(kind=="blank") x$metadata$sample_id[2]<-""
 if(kind=="unmatched") x$metadata$sample_id[2]<-"OTHER"
 if(kind=="negative") x$values[2,1]<- -1
 if(kind=="nonfinite") x$values[2,1]<-Inf
 if(kind=="range") x$values[2,1]<-101
 q<-prepare_project(x,p$declarations,p$design,p$settings)
 stopifnot(is.null(q$experiment),any(q$findings$severity=="error"))
}
q<-prepare_project(p$input,modifyList(p$declarations,list(rank="")),p$design,p$settings)
stopifnot(is.null(q$experiment))
cat("US1 invariant tests passed\n")
stopifnot(isTRUE(all.equal(p$mass$difference_from_one,rep(.1,4))))
stopifnot(identical(plot_composition(p)$data,p$table))
q<-prepare_project(p$input,p$declarations,modifyList(p$design,list(unit="")),p$settings)
stopifnot("unit_missing" %in% q$findings$code,!is.null(q$experiment))
g<-composition_table(p,list(group="group",facet="",order="alphabetical",palette="viridis"))
stopifnot(abs(g$value[g$display=="A" & grepl("s__Alpha_one$",g$taxon)]-.5)<1e-12)
stopifnot(all(g$n_samples==2))
cat("US2 composition tests passed\n")
art<-file.path(root,".artifacts");dir.create(art,showWarnings=FALSE)
run<-tempfile("verification-",tmpdir=art);dir.create(run)
original_hashes<-vapply(p$input$sources,function(s)s$sha256,character(1))
save_project(p,file.path(run,"saved.rds"));opened<-open_project(file.path(run,"saved.rds"))
stopifnot(identical(p$settings,opened$settings),identical(p$table,opened$table))
stopifnot(inherits(try(save_project(p,file.path(run,"saved.rds")),silent=TRUE),"try-error"))
bundle<-file.path(run,"export");export_project(p,bundle)
stopifnot(inherits(try(export_project(p,bundle),silent=TRUE),"try-error"))
script<-file.path(bundle,"replay.R")
result<-system2(file.path(R.home("bin"),"Rscript.exe"),c("--vanilla",shQuote(script),shQuote(bundle),shQuote(file.path(run,"replay"))),stdout=TRUE,stderr=TRUE)
cat(paste(result,collapse="\n"),"\n")
stopifnot(is.null(attr(result,"status")),file.exists(file.path(run,"replay","VERIFIED")))
stopifnot(identical(original_hashes,vapply(p$input$sources,function(s)digest::digest(s$bytes,algo="sha256",serialize=FALSE),character(1))))
cat("US3 save/export/fresh-session replay passed\nARTIFACTS:",run,"\n")

# Additional identity/rank/scale cases exercise upstream wrappers rather than names.
x<-p$input
x$sample_ids<-c("sample_id","A B","A.B","taxonomyID")
colnames(x$values)<-x$sample_ids
x$metadata$sample_id<-x$sample_ids[match(x$metadata$sample_id,p$input$sample_ids)]
q<-prepare_project(x,p$declarations,p$design,p$settings)
stopifnot(identical(colnames(q$experiment),x$sample_ids))
for(rank in c("k","g","s")) {
 q<-prepare_project(p$input,modifyList(p$declarations,list(rank=rank)),p$design,p$settings)
 stopifnot(all(sub("__.*","",sub(".*\\|","",rownames(q$experiment)))==rank))
}
x<-p$input;x$values<-x$values/100
q<-prepare_project(x,modifyList(p$declarations,list(scale="proportion")),p$design,p$settings)
stopifnot(identical(SummarizedExperiment::assay(q$experiment,"relative"),SummarizedExperiment::assay(p$experiment,"relative")))
q<-prepare_project(p$input,p$declarations,p$design,list(group="group",facet="time",order="alphabetical",palette="Set 2"))
stopifnot(identical(plot_composition(q)$data,q$table),all(q$table$n_samples==1))
stopifnot(inherits(try(composition_table(p,list(group="missing")),silent=TRUE),"try-error"))
x<-p$input;x$values[grepl("s__",x$feature_ids),1]<-60
stopifnot(is.null(prepare_project(x,p$declarations,p$design)$experiment))
x<-p$input;x$feature_ids[2]<-x$feature_ids[3]
stopifnot("duplicate_id" %in% validate_input(x,p$declarations,p$design)$code)
x<-p$input;x$metadata$age[1]<-"bad"
stopifnot("type_parse" %in% validate_input(x,p$declarations,p$design)$code)
bad<-p;bad$input$sources$abundance$bytes[1]<-as.raw(0)
stopifnot(inherits(try(save_project(bad,file.path(run,"bad.rds")),silent=TRUE),"try-error"))
# The actual source files remain byte-for-byte unchanged.
for(s in p$input$sources)stopifnot(identical(digest::digest(file=s$path,algo="sha256"),s$sha256))
cat("Upstream wrapper, identity, rank, scale, facet and preservation tests passed\n")

# Display labels preserve distinct full lineage keys, including collisions and SGBs.
ids<-c("k__Bacteria|g__One|s__Shared_name","k__Bacteria|g__Two|s__Shared_name","k__Bacteria|g__Three|s__Unnamed_sp|t__SGB123")
labels<-microbiomeengine:::taxon_labels(ids)
stopifnot(!anyDuplicated(labels),grepl("Shared name",labels[1]),grepl("One",labels[1]),labels[3]=="SGB123")
stopifnot(identical(unname(microbiomeengine:::taxon_labels("k__Bacteria|g__Faecalibacterium|s__Faecalibacterium_prausnitzii")),"Faecalibacterium prausnitzii"))
stopifnot(!any(grepl("Unassigned difference",p$table$taxon)),abs(sum(p$table$value[p$table$display=="S1"])-.9)<1e-12)
q<-prepare_project(p$input,modifyList(p$declarations,list(denominator_kind="unknown",coverage="unknown")),list(),p$settings)
stopifnot(!is.null(q$experiment),"history_unknown" %in% q$findings$code,!any(grepl("difference",q$table$taxon)))
stopifnot(inherits(try(composition_table(q,list(residual=TRUE)),silent=TRUE),"try-error"))
q<-prepare_project(p$input,p$declarations,p$design,modifyList(p$settings,list(residual=TRUE)))
stopifnot(any(grepl("Unassigned difference",q$table$taxon)),abs(sum(q$table$value[q$table$display=="S1"])-1)<1e-12)
legacy<-p;legacy$schema<-1L;legacy$declarations$denominator<-"arbitrary legacy meaning"
saveRDS(legacy,file.path(run,"legacy.rds"));migrated<-open_project(file.path(run,"legacy.rds"))
stopifnot(migrated$schema==4L,migrated$declarations$denominator_kind=="unknown",migrated$declarations$legacy_denominator_note=="arbitrary legacy meaning",!migrated$settings$residual)
cat("Schema migration, unknown history, residual policy and readable-label tests passed\n")


# Exercise file import, required setup, optional design and reopen through the Shiny server.
shiny::testServer(microbiomeengine:::app_server, {
 session$setInputs(abundance=data.frame(name="abundance.tsv",datapath=p$input$sources$abundance$path),metadata=data.frame(name="metadata.csv",datapath=p$input$sources$metadata$path))
 session$setInputs(import=1)
 stopifnot(is.null(state()$experiment),state()$input$sample_id=="")
 session$setInputs(sample_id="sample_id",rank="s",scale="percentage",denominator_kind="unknown",coverage="unknown",pipeline="",database="",filtering="",unclassified="",design_group="",design_time="",design_unit="",repetition="unknown",type_1="text",type_2="text",type_3="text",type_4="text",type_5="text")
 session$setInputs(apply=1)
 stopifnot(!is.null(state()$experiment),"unit_missing" %in% state()$findings$code)
 session$setInputs(reopen=data.frame(name="saved.rds",datapath=file.path(run,"saved.rds")))
 stopifnot(identical(state()$settings,p$settings),identical(state()$design,p$design))
})
# Recognized source headers provide evidence, not an inferred scale.
x<-p$input;x$comments<-c("#MetaPhlAn version 4.2.4","#mpa_vOct22_CHOCOPhlAnSGB_202403")
e<-microbiomeengine:::source_evidence(x)
stopifnot(grepl("4.2.4",e$pipeline),grepl("mpa_v",e$database),!"scale" %in% names(e))
cat("Shiny import/setup/reopen and header-evidence tests passed\n")
# TSV metadata, historical taxonomy annotation and commented headers retain identity.
meta_tsv<-file.path(run,"metadata.tsv")
utils::write.table(p$input$metadata,meta_tsv,sep="\t",quote=FALSE,row.names=FALSE)
annotated<-data.frame(clade_name=p$input$feature_ids,NCBI_tax_id=seq_along(p$input$feature_ids),p$input$values,check.names=FALSE)
ab_tsv<-file.path(run,"annotated.tsv")
utils::write.table(annotated,ab_tsv,sep="\t",quote=FALSE,row.names=FALSE)
lines<-readLines(ab_tsv);lines[1]<-paste0("#",lines[1]);writeLines(c("#mpa_vOct22_CHOCOPhlAnSGB_202403",lines),ab_tsv)
z<-import_metaphlan(ab_tsv,meta_tsv,"sample_id")
q<-prepare_project(z,p$declarations,p$design,p$settings)
stopifnot(identical(z$sample_ids,p$input$sample_ids),identical(q$table,p$table),"NCBI_tax_id" %in% names(z$annotations))
cat("CSV/TSV metadata and historical/commented merged-table format tests passed\n")

# Replay must start from actual preserved metadata bytes, not an in-memory edit.
collision_csv <- file.path(run,'collision-metadata.csv')
utils::write.table(collision_input$metadata,collision_csv,sep=',',quote=TRUE,row.names=FALSE)
collision_source <- import_metaphlan(p$input$sources$abundance$path,collision_csv)
collision <- prepare_project(collision_source,p$declarations,p$design,
 modifyList(p$settings,list(group='group',facet='group')))
collision_bundle <- file.path(run,'collision-export')
export_project(collision,collision_bundle)
result <- system2(file.path(R.home('bin'),'Rscript.exe'),
 c('--vanilla',shQuote(file.path(collision_bundle,'replay.R')),shQuote(collision_bundle),
   shQuote(file.path(run,'collision-replay'))),stdout=TRUE,stderr=TRUE)
cat(paste(result,collapse='\n'),'\n')
stopifnot(is.null(attr(result,'status')),file.exists(file.path(run,'collision-replay','VERIFIED')))
stopifnot(identical(collision$table,open_project(file.path(collision_bundle,'project.rds'))$table))
cat('Missing-category fresh-session replay and save/reopen passed\n')
seeded_server <- microbiomeengine:::app_server
environment(seeded_server) <- list2env(list(seed_project=p),parent=environment(seeded_server))
formals(seeded_server)$project <- quote(seed_project)
shiny::testServer(seeded_server,{
 stopifnot(identical(state(),p))
 stopifnot(grepl("2 selected taxa",output$summary,fixed=TRUE))
})
cat('Seeded saved-project app state passed\n')
