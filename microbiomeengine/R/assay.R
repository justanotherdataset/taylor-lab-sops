assay_settings <- function(settings=list()) {
 d<-list(name="",source="relative",method="hellinger",units="proportion",zero_policy="positive",pseudocount=0)
 if(!is.list(settings)||length(setdiff(names(settings),names(d))))stop("Unknown assay setting.")
 s<-modifyList(d,settings)
 for(n in c("name","source","method","units","zero_policy"))if(!is.character(s[[n]])||length(s[[n]])!=1L||is.na(s[[n]])||!nzchar(s[[n]]))stop("Choose a single nonblank ",n,".")
 if(!grepl("^[A-Za-z][A-Za-z0-9_]{0,63}$",s$name))stop("Layer names must start with a letter and contain at most 64 letters, digits or underscores.")
 if(!s$method%in%c("hellinger","log","clr"))stop("Choose Hellinger, natural log or CLR.")
 if(!s$zero_policy%in%c("positive","add"))stop("Choose positive-only or explicit addition.")
 c<-s$pseudocount
 if(!is.numeric(c)||length(c)!=1L||!is.finite(c)||c<0)stop("Pseudocount must be a finite nonnegative number in source units.")
 if(s$zero_policy=="positive"&&c!=0)stop("Positive-only requires pseudocount zero.")
 if(s$zero_policy=="add"&&c<=0)stop("Explicit addition requires a positive pseudocount in source units.")
 if(s$method=="hellinger"&&(s$zero_policy!="positive"||c!=0))stop("Hellinger permits zeros but requires no pseudocount; choose positive-only with zero addition.")
 s
}
assay_formula <- function(method) switch(method,hellinger="sqrt(x / sum(x)) within each retained sample; zero values allowed, zero totals blocked",log="ln(x + c); public mia log2(x + c) multiplied by ln(2)",clr="ln(x + c) - mean(ln(x + c)) within each retained sample")
assay_parent <- function(p,s) {
 if(is.null(p$experiment)||!identical(p$preparation$status,"ready"))stop("Apply valid Preparation first.")
 parent_layer<-NULL
 if(s$source%in%c("relative","estimated_reads")) {
  if(!s$source%in%SummarizedExperiment::assayNames(p$experiment))stop("Selected measurement is unavailable.")
  m<-SummarizedExperiment::assay(p$experiment,s$source)
  allowed<-if(s$source=="relative")c("proportion","percentage") else "estimated_reads"
  meaning<-if(s$source=="estimated_reads")"Estimated reads (not observed counts)" else if(is_estimate_only(p$input))"Relative estimated-read contribution" else "Supplied relative abundance"
 } else {
  z<-p$assay_layers[[s$source]]
  if(is.null(z)||z$status!="ready"||is.null(z$values))stop("Source layer is missing or stale; rebuild first.")
  if(z$settings$method!="hellinger")stop("Log and CLR layers are terminal and are not eligible abundance sources.")
  m<-z$values;allowed<-"derived";meaning<-paste("Derived Hellinger values from",s$source);parent_layer<-z$fingerprint
 }
 if(!s$units%in%allowed)stop("Source units must be ",paste(allowed,collapse=" or "),".")
 if(!is.matrix(m)||!is.numeric(m)||!nrow(m)||!ncol(m)||any(!is.finite(m))||any(m<0))stop("Transformation needs a nonempty finite nonnegative source matrix.")
 for(ids in dimnames(m))if(is.null(ids)||anyNA(ids)||any(!nzchar(trimws(ids)))||anyDuplicated(ids))stop("Unique nonblank feature and sample IDs required.")
 meta<-as.data.frame(SummarizedExperiment::colData(p$experiment))
 if(!identical(colnames(m),rownames(meta))||!identical(rownames(m),rownames(p$experiment)))stop("Source and metadata identity are not aligned.")
 sources<-p$input$sources[sort(names(p$input$sources),method="radix")]
 fp<-preparation_fingerprint(list(matrix=m,metadata=meta,rank=p$declarations$rank,recipe=p$preparation$settings,normalization=p$normalization,declarations=p$declarations,source=s$source,parent_layer=parent_layer,source_hashes=vapply(sources,function(x)x$sha256,character(1))))
 if(s$units=="percentage")m<-m*100
 list(matrix=m,metadata=meta,meaning=meaning,fingerprint=fp,parent_layer=parent_layer)
}
apply_assay <- function(project,settings=list()) {
 check_project(project);s<-assay_settings(settings)
 reserved<-unique(c("original","relative","estimated_reads",SummarizedExperiment::assayNames(project$experiment),names(project$assay_layers)))
 if(tolower(s$name)%in%tolower(reserved))stop("Layer name already exists or is reserved; choose a new name.")
 assays_current(project)
 z<-assay_parent(project,s);m<-z$matrix;c<-s$pseudocount
 if(any(!is.finite(m+c)))stop("Source plus pseudocount overflows.")
 if(s$method!="hellinger"&&any(m+c<=0))stop("Positive-only log/CLR cannot use zeros. Choose an explicit positive pseudocount in source units.")
 if(s$method=="hellinger"&&any(!is.finite(colSums(m))|colSums(m)<=0))stop("Hellinger requires positive finite totals in every sample.")
 obj<-SummarizedExperiment::SummarizedExperiment(assays=list(source=m),colData=z$metadata)
 upstream<-mia::transformAssay(obj,assay.type="source",method=if(s$method=="log")"log2" else s$method,MARGIN="samples",name="transformed",pseudocount=c,na.rm=FALSE)
 raw<-SummarizedExperiment::assay(upstream,"transformed");upstream_attributes<-attributes(raw)
 if(!identical(dimnames(raw),dimnames(m)))stop("Upstream transformation changed source identity.")
 values<-matrix(as.numeric(raw),nrow(m),ncol(m),dimnames=dimnames(m))
 if(s$method=="log")values<-values*log(2)
 if(any(!is.finite(values)))stop("Transformation returned nonfinite values.")
 versions<-vapply(c("mia","vegan","SummarizedExperiment"),function(n)as.character(utils::packageVersion(n)),character(1))
 layer<-list(settings=s,status="ready",reason="",parent=z$fingerprint,parent_layer=z$parent_layer,source_meaning=z$meaning,rank=project$declarations$rank,features=rownames(m),samples=colnames(m),metadata=z$metadata,versions=versions,formula=assay_formula(s$method),margin="samples (columns)",normalization=if(s$method=="hellinger")"Close retained named features within sample; original denominator/mass unchanged" else "No source closure; explicit addition before logarithm",upstream_attributes=upstream_attributes,values=values,
  summary=data.frame(sample_id=colnames(m),source_total=colSums(m),source_zeros=colSums(m==0),minimum=apply(values,2,min),maximum=apply(values,2,max),mean=colMeans(values),sum=colSums(values),row.names=NULL))
 layer$fingerprint<-preparation_fingerprint(layer)
 project$assay_layers[[s$name]]<-layer
 project$history[[length(project$history)+1L]]<-list(operation="named_assay",name=s$name,parent=layer$parent,result=layer$fingerprint,settings=s)
 project
}
assays_current <- function(project) {
 for(n in names(project$assay_layers)) {
  z<-project$assay_layers[[n]]
  if(z$status!="ready"||is.null(z$values)||!identical(assay_parent(project,z$settings)$fingerprint,z$parent))stop("Assay layer ",n," is stale; explicitly rebuild layers.")
  copy<-z;copy$fingerprint<-NULL
  if(!identical(preparation_fingerprint(copy),z$fingerprint))stop("Assay layer integrity mismatch: ",n)
 }
 invisible(TRUE)
}
retain_assays <- function(old,new) {
 if(is.null(old$assay_layers))return(new)
 new$assay_layers<-old$assay_layers
 for(n in names(new$assay_layers)) {
  z<-new$assay_layers[[n]];parent<-tryCatch(assay_parent(new,z$settings)$fingerprint,error=function(e)NULL)
  if(z$status!="ready"||!identical(parent,z$parent)) {
   z$status<-"stale";z$reason<-"Prepared source, rank, cohort, features or metadata changed. Explicitly rebuild layers.";z$values<-NULL;z$summary<-NULL
  }
  new$assay_layers[[n]]<-z
 }
 new
}
rebuild_assays <- function(project) {
 recipes<-lapply(project$assay_layers,function(z)z$settings);project$assay_layers<-NULL
 for(s in recipes)project<-apply_assay(project,s)
 project
}
assay_summary <- function(project) {
 if(!length(project$assay_layers))return(data.frame())
 do.call(rbind,lapply(project$assay_layers,function(z)data.frame(name=z$settings$name,status=z$status,source=z$settings$source,method=z$settings$method,units=z$settings$units,zero_policy=z$settings$zero_policy,pseudocount=z$settings$pseudocount,reason=z$reason,row.names=NULL)))
}
assay_values <- function(project,name) {
 assays_current(project);z<-project$assay_layers[[name]]
 if(is.null(z))stop("Choose an existing layer.")
 m<-z$values;data.frame(feature_id=rep(rownames(m),ncol(m)),sample_id=rep(colnames(m),each=nrow(m)),value=as.vector(m),layer=name,rank=z$rank,stringsAsFactors=FALSE)
}
assay_code <- function(project) {
 c("# Requires p: a validated prepared microbiomeengine project.","# Full standalone reconstruction: run replay.R BUNDLE NEW_OUTPUT.",unlist(lapply(project$assay_layers,function(z)c(paste0("# ",z$formula),paste0("p <- microbiomeengine::apply_assay(p, ",paste(capture.output(dput(z$settings)),collapse="\n"),")")))))
}
write_assay_table <- function(table,path) {
 # Seventeen significant digits round-trip IEEE doubles through text.
 for(n in names(table))if(is.numeric(table[[n]]))table[[n]]<-sprintf("%.17g",table[[n]])
 utils::write.table(table,path,sep="\t",row.names=FALSE,quote=TRUE)
}
export_assay_files <- function(project,directory) {
 assays_current(project)
 writeLines(assay_code(project),file.path(directory,"assay-code.R"))
 saveRDS(project$assay_layers,file.path(directory,"assay-layers.rds"))
 write_assay_table(assay_summary(project),file.path(directory,"assay-layers.tsv"))
 for(n in names(project$assay_layers)) {
  write_assay_table(assay_values(project,n),file.path(directory,paste0("assay-",n,"-values.tsv")))
  write_assay_table(project$assay_layers[[n]]$summary,file.path(directory,paste0("assay-",n,"-summary.tsv")))
 }
 report<-htmltools::tags$html(htmltools::tags$body(htmltools::tags$h1("Named assay layers"),html_table(assay_summary(project)),lapply(project$assay_layers,function(z)htmltools::tagList(htmltools::tags$h2(z$settings$name),htmltools::tags$p(z$source_meaning),htmltools::tags$p(z$formula),htmltools::tags$p(z$normalization),html_table(z$summary),htmltools::tags$pre(paste(capture.output(str(z[setdiff(names(z),c("values","summary","metadata","upstream_attributes"))])),collapse="\n"))))))
 htmltools::save_html(report,file.path(directory,"assays.html"))
}
export_assays <- function(project,directory) {
 if(!length(project$assay_layers))stop("Create a named layer first.")
 assays_current(project);project$alpha<-NULL;project$beta<-NULL
 export_project(project,directory)
}
assays_recalculate <- function(saved,p) {
 for(z in saved$assay_layers)p<-apply_assay(p,z$settings)
 if(!identical(p$assay_layers,saved$assay_layers))stop("Replay differs from saved assay layers, provenance or exact values.")
 p
}
