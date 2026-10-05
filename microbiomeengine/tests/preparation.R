args<-commandArgs(TRUE)
if(length(args)>1L).libPaths(c(normalizePath(args[2],winslash="/"),file.path(normalizePath(args[1],winslash="/"),".library"),.libPaths()))
library(microbiomeengine)
run<-tempfile("preparation-check-");dir.create(run)
ids<-c("k__Bacteria|g__G|s__A","k__Bacteria|g__G|s__B","k__Bacteria|g__G|s__Zero")
# Hand fixture: A detectable >10% in S2 only, >=10% in S1/S2.
# B detectable >10% in S3/S4; zero feature never >0 but always >=0.
m<-rbind(c(10,20,0,0),c(0,0,30,40),c(0,0,0,0),c(10,10,10,10),c(10,20,30,40))
dimnames(m)<-list(c(ids,"UNCLASSIFIED","k__Bacteria|g__G"),paste0("S",1:4))
f<-file.path(run,"relative.tsv");meta<-file.path(run,"metadata.csv")
utils::write.table(data.frame(clade_name=rownames(m),m,check.names=FALSE),f,sep="\t",row.names=FALSE,quote=FALSE)
utils::write.csv(data.frame(sample_id=c("S3","S1","S4","S2"),group=c("B","A","","A"),visit=c("late","early","late","early"),day=c("3","1","","2"),date=c("2026-01-03","2026-01-01","","2026-01-02")),meta,row.names=FALSE)
x<-import_metaphlan(f,meta)
d<-list(rank="s",scale="percentage",denominator_kind="including_unclassified",coverage="removed",pipeline="fixture",database="fixture")
design<-list(types=c(sample_id="id",group="categorical",visit="categorical",day="continuous",date="date"))
p<-prepare_project(x,d,design)
stopifnot(p$schema==4L,identical(SummarizedExperiment::assay(p$canonical,"original"),m[ids,,drop=FALSE]))
legacy_order<-x;legacy_order$sources<-rev(legacy_order$sources)
reordered<-prepare_project(legacy_order,d,design)
stopifnot(identical(p$preparation,reordered$preparation),identical(p$table,reordered$table))
base<-list(filter=list(enabled=TRUE,source="relative",units="percentage",detection=10,detection_operator=">",prevalence=.25,prevalence_operator=">="))
q<-apply_preparation(p,base)
stopifnot(identical(q$input,p$input),identical(q$canonical,p$canonical),identical(q$preparation$features$numerator,c(1L,2L,0L)),identical(q$preparation$features$retained,c(TRUE,TRUE,FALSE)))
q2<-apply_preparation(p,modifyList(base,list(filter=list(detection_operator=">=",prevalence_operator=">"))))
stopifnot(identical(q2$preparation$features$numerator,c(2L,2L,0L)),identical(q2$preparation$features$retained,c(TRUE,TRUE,FALSE)))
q3<-apply_preparation(p,modifyList(base,list(filter=list(prevalence_operator=">"))))
stopifnot(identical(rownames(q3$experiment),ids[2]))
cohort<-modifyList(base,list(group=list(enabled=TRUE,field="group",values="A")))
qc<-apply_preparation(p,cohort)
stopifnot(identical(colnames(qc$experiment),c("S1","S2")),identical(rownames(qc$experiment),ids[1]),all(qc$preparation$features$denominator==2L),identical(qc$preparation$features$numerator,c(1L,0L,0L)))
stopifnot(identical(as.character(SummarizedExperiment::colData(qc$experiment)$sample_id),c("S1","S2")))
equiv<-apply_preparation(p,modifyList(base,list(filter=list(units="proportion",detection=.1))))
stopifnot(identical(SummarizedExperiment::assays(q$experiment),SummarizedExperiment::assays(equiv$experiment)),identical(q$preparation$features$prevalence,equiv$preparation$features$prevalence))
zero<-apply_preparation(p,modifyList(base,list(filter=list(detection=0,detection_operator=">=",prevalence=1))))
stopifnot(all(zero$preparation$features$numerator==4L),identical(rownames(zero$experiment),ids))
empty<-apply_preparation(p,list(samples=list(enabled=TRUE,ids=character())))
stopifnot(is.null(empty$experiment),is.null(empty$table),grepl("No samples",paste(empty$findings$details,collapse=" ")),nrow(empty$preparation$samples)==4L)
none<-apply_preparation(p,modifyList(base,list(filter=list(prevalence=1,prevalence_operator=">"))))
stopifnot(is.null(none$table),all(!none$preparation$features$retained))
missing<-apply_preparation(p,list(group=list(enabled=TRUE,field="group",values=character(),include_missing=TRUE)))
stopifnot(identical(colnames(missing$experiment),"S4"))
range<-apply_preparation(p,list(time=list(enabled=TRUE,field="day",mode="range",lower=2,upper=3)))
stopifnot(identical(colnames(range$experiment),c("S2","S3")))
date<-apply_preparation(p,list(time=list(enabled=TRUE,field="date",mode="range",lower="2026-01-02",upper="2026-01-03")))
stopifnot(identical(colnames(date$experiment),c("S2","S3")))
bad<-apply_preparation(p,list(time=list(enabled=TRUE,field="visit",mode="range",lower=1,upper=3)))
stopifnot(is.null(bad$table))
unknown<-apply_preparation(p,list(samples=list(enabled=TRUE,ids="missing")))
stopifnot(is.null(unknown$table))
reset<-apply_preparation(qc)
stopifnot(identical(reset$input,p$input),identical(reset$experiment,p$experiment),identical(reset$table,p$table))
for(z in list(q,q2,q3,qc,equiv,zero,missing,range,date)) {
 stopifnot(max(abs(z$mass$selected+z$mass$feature_removed-z$mass$canonical_selected))<1e-14)
 top<-prepare_project(z$input,z$declarations,z$design,modifyList(z$settings,list(taxa_mode="top",top_n=1L,show_other=FALSE)),z$preparation$settings)
 for(sample in colnames(top$experiment)) {
  a<-top$table[top$table$sample_ids==sample,];mass<-top$mass[top$mass$sample_id==sample,]
  stopifnot(abs(sum(a$value)+unique(a$omitted_mass)-mass$selected-mass$unclassified)<1e-14)
  stopifnot(unique(a$feature_removed_mass)==mass$feature_removed,unique(a$unresolved_difference)==mass$difference_from_one)
 }
}
cat("PASS hand prevalence, independent boundaries, cohort-before-filter, exact IDs, missing/ranges, units, reset and mass\n")
# Same source bytes with independently shuffled metadata still aligns by ID.
shuffled<-x;shuffled$metadata<-x$metadata[4:1,,drop=FALSE]
shuffled_view<-prepare_project(shuffled,d,design,preparation=cohort)
stopifnot(identical(SummarizedExperiment::assays(shuffled_view$experiment),SummarizedExperiment::assays(qc$experiment)),identical(shuffled_view$preparation$samples,qc$preparation$samples))
both<-apply_preparation(p,modifyList(cohort,list(samples=list(enabled=TRUE,ids=c("S1","S3")),time=list(enabled=TRUE,field="visit",values="early"))))
stopifnot(is.null(both$table),identical(both$preparation$samples$retained,c(TRUE,FALSE,FALSE,FALSE))) # S1 is exactly at excluded >10% boundary.
dup<-apply_preparation(p,list(samples=list(enabled=TRUE,ids=c("S1","S1"))))
stopifnot(is.null(dup$table))
for(rank in c("g","s","g","s")) {
 z<-prepare_project(x,modifyList(d,list(rank=rank)),design,preparation=cohort)
 stopifnot(all(z$table$rank==rank),all(z$preparation$features$feature_id%in%rownames(z$canonical)),identical(z$input,x))
}
# Estimates are aligned by IDs; contribution denominator is established at rank,
# before cohort selection and feature removal, and never recomputed after filtering.
e<-m*10;ef<-file.path(run,"estimates.tsv")
utils::write.table(data.frame(clade_name=rownames(e)[5:1],e[5:1,4:1],check.names=FALSE),ef,sep="\t",row.names=FALSE,quote=FALSE)
ed<-modifyList(d,list(estimate_unit="estimated_reads",estimate_normalization=TRUE))
for(relative in list(f,NULL)) {
 ix<-import_metaphlan(relative,meta,estimates=ef)
 ep<-prepare_project(ix,ed,design)
 es<-list(samples=list(enabled=TRUE,ids=c("S1","S2","S3")),filter=list(enabled=TRUE,source="estimated_reads",units="estimated_reads",detection=250,detection_operator=">",prevalence=.3,prevalence_operator=">="))
 eq<-apply_preparation(ep,es)
 stopifnot(identical(eq$input,ix),identical(eq$canonical,ep$canonical),identical(eq$normalization,ep$normalization))
 stopifnot(identical(rownames(eq$experiment),ids[2]),identical(SummarizedExperiment::assay(eq$experiment,"estimated_reads"),e[rownames(eq$experiment),colnames(eq$experiment),drop=FALSE]),sum(eq$mass$feature_removed)>0)
 if(is.null(relative)) {
  total<-colSums(e[ids,,drop=FALSE])+e["UNCLASSIFIED",]
  stopifnot(identical(unname(eq$mass$denominator_total),unname(total[colnames(eq$experiment)])),max(abs(eq$mass$selected+eq$mass$feature_removed+eq$mass$unclassified-1))<1e-14)
 }
 bundle<-file.path(run,if(is.null(relative))"estimate-bundle" else "paired-bundle")
 export_project(eq,bundle)
 reopened<-open_project(file.path(bundle,"project.rds"))
 stopifnot(identical(reopened,eq))
 result<-system2(file.path(R.home("bin"),"Rscript.exe"),c("--vanilla",shQuote(file.path(bundle,"replay.R")),shQuote(bundle),shQuote(paste0(bundle,"-replayed"))),stdout=TRUE,stderr=TRUE)
 cat(paste(result,collapse="\n"),"\n");stopifnot(is.null(attr(result,"status")),file.exists(file.path(paste0(bundle,"-replayed"),"VERIFIED")))
 for(name in c("original-primary.tsv","canonical-relative.tsv","prepared-relative.tsv","preparation-samples.tsv","preparation-features.tsv","prepared-mass.tsv","preparation-operation.R"))stopifnot(file.exists(file.path(bundle,name)))
 report<-paste(readLines(file.path(bundle,"diagnosis.html")),collapse=" ")
 stopifnot(grepl("Feature-removed mass",report,fixed=TRUE),grepl("Sample decisions",report,fixed=TRUE))
}
# Legacy migration disables preparation, while failed current projects remain recoverable.
for(schema in 1:3) {
 legacy<-p;legacy$schema<-schema;legacy$canonical<-NULL;legacy$preparation<-NULL
 path<-file.path(run,paste0("legacy",schema,".rds"));saveRDS(legacy,path)
 opened<-open_project(path)
 stopifnot(opened$schema==4L,identical(opened$input,p$input),identical(SummarizedExperiment::assays(opened$experiment),SummarizedExperiment::assays(p$experiment)))
}
blockedpath<-file.path(run,"blocked.rds");save_project(none,blockedpath)
stopifnot(identical(open_project(blockedpath),none),inherits(try(export_project(none,file.path(run,"no-export")),silent=TRUE),"try-error"),!dir.exists(file.path(run,"no-export")))
cat("PASS paired/estimate-only preservation, stable denominators, rank masks, schemas1/2/3, complete exports and fresh replay\n")
if(length(args)) {
 pilot<-open_project(file.path(args[1],".artifacts/pilot-030-final/project.rds"))
 selected<-pilot$input$sample_ids[2:3]
 pilot<-apply_preparation(pilot,list(samples=list(enabled=TRUE,ids=selected),filter=list(enabled=TRUE,source="relative",units="percentage",detection=5,detection_operator=">",prevalence=.5,prevalence_operator=">=")))
 stopifnot(ncol(pilot$experiment)==2L,nrow(pilot$experiment)==4L)
 bundle<-file.path(run,"real-pilot");export_project(pilot,bundle)
 result<-system2(file.path(R.home("bin"),"Rscript.exe"),c("--vanilla",shQuote(file.path(bundle,"replay.R")),shQuote(bundle),shQuote(file.path(run,"real-pilot-replay"))),stdout=TRUE,stderr=TRUE)
 cat(paste(result,collapse="\n"),"\n");stopifnot(is.null(attr(result,"status")),file.exists(file.path(run,"real-pilot-replay","VERIFIED")))
 cat("PASS actual migrated HMP pilot, prepared cohort/features and exact fresh replay\n")
}
