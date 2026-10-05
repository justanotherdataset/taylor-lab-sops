args<-commandArgs(TRUE)
if(length(args)>1L).libPaths(c(normalizePath(args[2],winslash="/"),file.path(normalizePath(args[1],winslash="/"),".library"),.libPaths()))
library(microbiomeengine)
p<-example_project();stopifnot(!"p"%in%microbiomeengine:::rank_choices(p$input),all(c("k","g","s")%in%microbiomeengine:::rank_choices(p$input)));run<-tempfile("rank-check-");dir.create(run)
# Supply actual terminal phylum rows; descendants are not synthesized into them.
x<-p$input;phy<-"k__Bacteria|p__Firmicutes"
x$values<-rbind(x$values,setNames(c(50,60,70,40),x$sample_ids));x$feature_ids<-c(x$feature_ids,phy);rownames(x$values)<-x$feature_ids
f<-file.path(run,"relative.tsv");utils::write.table(data.frame(clade_name=x$feature_ids,x$values,check.names=FALSE),f,sep="\t",row.names=FALSE,quote=FALSE)
x<-import_metaphlan(f,p$input$sources$metadata$path)
s<-modifyList(p$settings,list(group="group",facet="time",order="alphabetical",palette="Set 2",taxa_mode="top",top_n=1L,show_other=FALSE,show_unclassified=TRUE,figure=list(format="png",width=9,height=6,units="in",dpi=120)))
original<-x
for(rank in c("s","g","p","s")) {
 q<-prepare_project(x,modifyList(p$declarations,list(rank=rank)),p$design,s)
 ids<-x$feature_ids[sub("__.*","",sub(".*\\|","",x$feature_ids))==rank]
 stopifnot(identical(rownames(q$experiment),ids),identical(SummarizedExperiment::assay(q$experiment,"original"),x$values[ids,,drop=FALSE]),identical(q$settings,s),identical(q$input,original))
 stopifnot(identical(SummarizedExperiment::assay(q$experiment,"relative"),x$values[ids,,drop=FALSE]/100),all(q$table$rank==rank),identical(q$table,plot_composition(q)$data))
 stopifnot(all(abs(q$mass$selected-colSums(x$values[ids,,drop=FALSE]/100))<1e-12))
 for(sample in x$sample_ids){z<-q$table[q$table$sample_ids==sample,];stopifnot(abs(sum(z$value)+unique(z$omitted_mass)-sum(x$values[ids,sample])/100-.1)<1e-12)}
}
missing<-prepare_project(x,modifyList(p$declarations,list(rank="f")),p$design,s)
stopifnot(is.null(missing$table),"rank_empty"%in%missing$findings$code)
# Estimated rank totals differ, exercising recomputation rather than old denominator reuse.
e<-x$values*10;e[grepl("g__[^|]+$",rownames(e)),]<-e[grepl("g__[^|]+$",rownames(e)),]/2;e[phy,]<-c(200,300,400,500)
ef<-file.path(run,"estimates.tsv");utils::write.table(data.frame(clade_name=rownames(e),e,check.names=FALSE),ef,sep="\t",row.names=FALSE,quote=FALSE)
only<-import_metaphlan(NULL,p$input$sources$metadata$path,estimates=ef)
d<-modifyList(p$declarations,list(estimate_unit="estimated_reads",estimate_normalization=TRUE))
for(rank in c("s","g","p","s")) {
 q<-prepare_project(only,modifyList(d,list(rank=rank)),p$design,s)
 ids<-rownames(e)[sub("__.*","",sub(".*\\|","",rownames(e)))==rank];total<-colSums(e[ids,,drop=FALSE])+e["UNCLASSIFIED",]
 stopifnot(identical(unname(q$mass$denominator_total),unname(total)),identical(SummarizedExperiment::assay(q$experiment,"relative"),sweep(e[ids,,drop=FALSE],2,total,"/")),identical(q$input,only))
}
paired<-import_metaphlan(f,p$input$sources$metadata$path,estimates=ef)
bad<-paired;bad$estimated$feature_ids[match(phy,bad$estimated$feature_ids)]<-"k__Bacteria|p__Different"
stopifnot(!is.null(prepare_project(bad,d,p$design,s)$table))
blocked<-prepare_project(bad,modifyList(d,list(rank="p")),p$design,s)
stopifnot(is.null(blocked$table),"paired_taxa"%in%blocked$findings$code)
# Actual Composition observer must change the authoritative declaration, expose recovery,
# and keep Data setup's selected option synchronized after every successful or blocked apply.
seeded<-microbiomeengine:::app_server
environment(seeded)<-list2env(list(seed_project=prepare_project(bad,d,p$design,s)),parent=environment(seeded));formals(seeded)$project<-quote(seed_project)
shiny::testServer(seeded,{
 session$setInputs(plot_group=s$group,plot_facet=s$facet,plot_order=s$order,plot_palette=s$palette,plot_residual=FALSE,taxa_mode=s$taxa_mode,top_n=s$top_n,show_other=s$show_other,show_unclassified=s$show_unclassified)
 for(i in seq_along(c("g","p","s"))) {
  rank<-c("g","p","s")[i];session$setInputs(plot_rank=rank);session$setInputs(plot_apply=i)
  stopifnot(identical(state()$declarations$rank,rank),identical(state()$settings,s),identical(state()$input,bad))
  html<-output$setup$html;stopifnot(grepl(paste0('value="',rank,'" selected'),html,fixed=TRUE))
  if(rank=="p")stopifnot(is.null(state()$table),grepl("paired",output$composition_findings,ignore.case=TRUE)) else stopifnot(all(state()$table$rank==rank))
 }
 session$setInputs(plot_rank="f",plot_apply=4)
 stopifnot(is.null(state()$table),"rank_empty"%in%state()$findings$code)
 session$setInputs(plot_rank="g",plot_apply=5)
 stopifnot(!is.null(state()$table),state()$declarations$rank=="g")
})
cat("PASS rank-specific originals, mass, estimates denominators, absent/paired recovery and Shiny shared rank/settings\n")
q<-prepare_project(paired,modifyList(d,list(rank="p")),p$design,s)
bundle<-file.path(run,"phylum-export");export_project(q,bundle)
reopened<-open_project(file.path(bundle,"project.rds"));stopifnot(reopened$declarations$rank=="p",identical(q$table,reopened$table),identical(q$input,reopened$input),identical(q$settings,reopened$settings))
result<-system2(file.path(R.home("bin"),"Rscript.exe"),c("--vanilla",shQuote(file.path(bundle,"replay.R")),shQuote(bundle),shQuote(file.path(run,"phylum-replay"))),stdout=TRUE,stderr=TRUE)
cat(paste(result,collapse="\n"),"\n");stopifnot(is.null(attr(result,"status")),file.exists(file.path(run,"phylum-replay","VERIFIED")))
cat("PASS selected phylum save/reopen and fresh-script replay\n")
if(length(args)) {
 hmp<-open_project(file.path(args[1],".artifacts/pilot-030-final/project.rds"));orig<-hmp$input;counts<-integer()
 for(rank in c("s","g","p","s")) {
  z<-prepare_project(orig,modifyList(hmp$declarations,list(rank=rank)),hmp$design,hmp$settings)
  ids<-orig$feature_ids[sub("__.*","",sub(".*\\|","",orig$feature_ids))==rank]
  stopifnot(identical(z$input,orig),identical(SummarizedExperiment::assay(z$experiment,"original"),orig$values[ids,,drop=FALSE]),all(z$table$rank==rank),identical(z$table,plot_composition(z)$data),identical(z$settings,hmp$settings))
  counts<-c(counts,length(ids))
 }
 cat("PASS real HMP species/genus/phylum/species counts:",paste(counts,collapse=","),"\n")
}
