composition_categories <- function(values) {
 values <- as.character(values)
 missing <- is.na(values) | !nzchar(trimws(values))
 if(any(missing)) {
  supplied <- values[!missing]
  label <- "[Missing]"
  suffix <- 0L
  while(label %in% supplied) {
   suffix <- suffix + 1L
   label <- if(suffix==1L) "[Missing] (missing values)" else paste0("[Missing] (missing values ",suffix,")")
  }
  values[missing] <- label
 }
 values
}
composition_table <- function(project, settings=project$settings) {
 if(is.null(project$experiment)) stop("Resolve blocking findings before composition.")
 s<-modifyList(list(group="",facet="",order="input",palette="viridis",residual=FALSE,taxa_mode="all",top_n=10L,show_other=TRUE,show_unclassified=TRUE),settings)
 if(!s$taxa_mode %in% c("all","top")||length(s$top_n)!=1L||!is.numeric(s$top_n)||!is.finite(s$top_n)||s$top_n<1||s$top_n!=floor(s$top_n))stop("Choose all taxa or top N with a positive whole-number N.")
 for(flag in c("show_other","show_unclassified","residual"))if(!is.logical(s[[flag]])||length(s[[flag]])!=1L||is.na(s[[flag]]))stop("Category visibility must be TRUE or FALSE.")
 if(isTRUE(s$residual) && (is_estimate_only(project$input)||project$declarations$denominator_kind=="unknown"||project$declarations$coverage!="removed"))stop("Display the unassigned difference only for supplied relative values with confirmed reference population and taxa removed without rescaling.")
 meta<-as.data.frame(SummarizedExperiment::colData(project$experiment))
 for(n in c(s$group,s$facet)) if(nzchar(n)&&!n %in% names(meta)) stop("Unknown composition metadata field: ",n)
 if(!s$order %in% c("input","alphabetical","total")) stop("Unsupported sample order.")
 if(!s$palette %in% c("viridis","Set 2","Dark 3")) stop("Unsupported palette.")
 original<-SummarizedExperiment::assay(project$experiment,"relative")
 tax<-rownames(original)
 ranked<-tax[order(-rowMeans(original),enc2utf8(tax),method="radix")]
 selected<-if(s$taxa_mode=="all")tax else head(ranked,s$top_n)
 rest<-setdiff(tax,selected)
 mat<-original[selected,,drop=FALSE]
 category<-setNames(rep("taxon",length(selected)),selected)
 members<-setNames(as.list(selected),selected)
 omitted<-rep(0,ncol(mat))
 if(length(rest)) {
  remaining<-colSums(original[rest,,drop=FALSE])
  if(s$show_other){mat<-rbind(mat,"[Other - named taxa]"=remaining);category<-c(category,"[Other - named taxa]"="other");members[["[Other - named taxa]"]]<-rest} else omitted<-omitted+remaining
 }
 if("UNCLASSIFIED" %in% project$input$feature_ids) {
  if(s$show_unclassified){mat<-rbind(mat,"[Supplied unclassified]"=project$mass$unclassified);category<-c(category,"[Supplied unclassified]"="unclassified");members[["[Supplied unclassified]"]]<-"UNCLASSIFIED"} else omitted<-omitted+project$mass$unclassified
 }
 if(isTRUE(s$residual)) {
  mat<-rbind(mat,"[Unassigned difference - display only]"=project$mass$difference_from_one)
  category<-c(category,"[Unassigned difference - display only]"="difference");members[["[Unassigned difference - display only]"]]<-character()
 }
 if(nrow(mat)>500L)stop(structure(list(message=paste(nrow(mat),"display taxa exceed the miaViz limit of 500; select a smaller top N."),call=NULL),class=c("composition_limit","error","condition")))
 display<-if(nzchar(s$group))meta[[s$group]] else colnames(mat)
 facet<-if(nzchar(s$facet))meta[[s$facet]] else rep("All samples",ncol(mat))
 display<-composition_categories(display);facet<-composition_categories(facet)
 view<-SummarizedExperiment::SummarizedExperiment(assays=list(value=mat))
 d<-as.data.frame(mia::meltSE(view,assay.type="value",row.name="taxon",col.name="sample_id",check.names=FALSE))
 d$sample_id<-as.character(d$sample_id);d$taxon<-as.character(d$taxon)
 j<-match(d$sample_id,colnames(mat));d$display<-display[j];d$facet<-facet[j]
 d$omitted_mass<-omitted[j];d$unresolved_difference<-project$mass$difference_from_one[j]
 d$feature_removed_mass<-if(is.null(project$mass$feature_removed))0 else project$mass$feature_removed[j]
 d$supplied_unclassified_mass<-project$mass$unclassified[j]
 keys<-unique(d[,c("display","facet","taxon")])
 out<-lapply(seq_len(nrow(keys)),function(i) {
  k<-keys[i,];z<-d[d$display==k$display&d$facet==k$facet&d$taxon==k$taxon,,drop=FALSE]
  data.frame(display=k$display,facet=k$facet,taxon=k$taxon,value=mean(z$value),n_samples=nrow(z),sample_ids=paste(z$sample_id,collapse=";"),category=unname(category[k$taxon]),source_taxa=paste(members[[k$taxon]],collapse="\n"),omitted_mass=mean(z$omitted_mass),feature_removed_mass=mean(z$feature_removed_mass),supplied_unclassified_mass=mean(z$supplied_unclassified_mass),unresolved_difference=mean(z$unresolved_difference))
 })
 out<-do.call(rbind,out);rownames(out)<-NULL
 levels<-unique(out$display)
 if(s$order=="alphabetical")levels<-sort(levels)
 if(s$order=="total"){
  # Order using full named mass, independent of hidden display categories.
  totals<-tapply(colSums(original),display,sum);levels<-names(sort(totals,decreasing=TRUE))
 }
 out$display<-factor(out$display,levels=levels)
 out$denominator<-project$declarations$denominator
 out$rank<-project$declarations$rank
 out$summary<-if(nzchar(s$group))"Arithmetic mean of sample relative values (descriptive)" else "Individual sample relative values"
 if(is_estimate_only(project$input))out$summary<-paste(out$summary,"- estimated read contribution among supplied rows")
 out$taxon_label<-unname(taxon_labels(unique(out$taxon))[out$taxon])
 # Membership also records hidden named taxa so display omission is auditable.
 attr(out,"membership")<-data.frame(source_taxon=tax,display_taxon=ifelse(tax%in%selected,tax,"[Other - named taxa]"),shown=tax%in%selected|s$show_other,stringsAsFactors=FALSE)
 out
}
taxon_labels <- function(ids) {
 clean<-function(x)gsub("_"," ",sub("^[a-z]+__","",x))
 labels<-clean(sub(".*\\|","",ids))
 labels[grepl("^\\[",ids)]<-gsub("[\\[\\]]","",ids[grepl("^\\[",ids)])
 dup<-duplicated(labels)|duplicated(labels,fromLast=TRUE)
 for(i in which(dup)) {
  parts<-strsplit(ids[i],"|",fixed=TRUE)[[1]]
  parent<-if(length(parts)>1L)clean(parts[length(parts)-1L]) else "taxon"
  labels[i]<-paste0(labels[i]," (",parent,"; ",substr(digest::digest(ids[i],algo="sha256",serialize=FALSE),1,8),")")
 }
 setNames(labels,ids)
}
plot_composition <- function(project) {
 d<-project$table
 if(!is.null(d))d<-d[,setdiff(names(d),c("X","Y","colour_by","panel")),drop=FALSE]
 if(is.null(d)) stop("Resolve blocking findings before plotting.")
 taxa<-sort(unique(d$taxon)); ordinary<-sort(rownames(SummarizedExperiment::assay(project$experiment,"relative")),method="radix")
 palette<-project$settings$palette
 colours<-if(palette=="viridis")grDevices::hcl.colors(length(ordinary),"viridis") else grDevices::hcl.colors(length(ordinary),palette)
 colours<-c(setNames(colours,ordinary),"[Other - named taxa]"="#697586","[Supplied unclassified]"="#A3AAB5","[Unassigned difference - display only]"="#E5E7EB")
 # Supply prepared means as display columns; disable all upstream aggregation,
 # reclosure and paired-sample completion. Retain original sample membership in d.
 bars<-unique(d[,c("display","facet")]); keys<-paste0("bar",seq_len(nrow(bars)))
 mat<-matrix(0,length(taxa),nrow(bars),dimnames=list(taxa,keys))
 for(i in seq_len(nrow(bars))) {
  z<-d[d$display==bars$display[i]&d$facet==bars$facet[i],]
  mat[match(z$taxon,taxa),i]<-z$value
 }
 view<-SummarizedExperiment::SummarizedExperiment(assays=list(relative=mat),
  colData=S4Vectors::DataFrame(panel=bars$facet,row.names=keys))
 plot<-miaViz::plotAbundance(view,assay.type="relative",group=NULL,
  as.relative=FALSE,paired=FALSE,col.levels=keys,row.levels=taxa,
  col.var="panel",facet.cols=TRUE,scales="free_x",add.x.text=TRUE,
  add.border=FALSE,bar.alpha=1,check.names=FALSE)
 # The public ggplot data is the authority: align our annotations and fail if
 # values differ. Its original X/Y/colour_by columns remain in the exact export.
 upstream<-as.data.frame(plot$data)
 index<-vapply(seq_len(nrow(upstream)),function(i){
  b<-match(as.character(upstream$X[i]),keys)
  which(d$display==bars$display[b]&d$facet==bars$facet[b]&d$taxon==as.character(upstream$colour_by[i]))
 },integer(1))
 if(!isTRUE(all.equal(upstream$Y,d$value[index],tolerance=0)))stop("miaViz plotted values differ from prepared composition.")
 exact<-cbind(d[index,,drop=FALSE],upstream);rownames(exact)<-NULL
 plot$data<-exact
 plot<-suppressMessages(plot+
  ggplot2::scale_fill_manual(values=colours,labels=function(ids)vapply(unname(taxon_labels(taxa)[ids]),function(x)paste(strwrap(x,width=36),collapse="\n"),character(1)))+
  ggplot2::scale_x_discrete(labels=setNames(as.character(bars$display),keys))+
  ggplot2::scale_y_continuous(breaks=seq(0,1,.25),labels=function(x)paste0(round(x*100),"%"))+
  ggplot2::coord_cartesian(ylim=c(0,max(1,colSums(mat))))+
  ggplot2::labs(x=if(nzchar(project$settings$group))project$settings$group else "Sample",y=if(is_estimate_only(project$input))"Relative estimated read contribution" else "Relative abundance",fill="Taxon / mass",subtitle=unique(d$summary),caption=paste("Denominator:",unique(d$denominator),"\nOmitted display mass:",paste0(format(range(d$omitted_mass)*100,digits=4),"%",collapse=" to "),"; no reclosure. Top taxa ranked by mean across retained samples/features; full-ID ties. Feature-removed mass is separate from display-hidden mass."))+
  ggplot2::guides(fill=ggplot2::guide_legend(ncol=2,byrow=TRUE))+
  ggplot2::theme_minimal(base_size=12)+ggplot2::theme(axis.text.x=ggplot2::element_text(angle=35,hjust=1),legend.position="bottom",legend.text=ggplot2::element_text(size=9)))
 plot
}

