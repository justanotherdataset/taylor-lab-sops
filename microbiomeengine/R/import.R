# Original bytes are retained so uploads remain usable after Shiny temporary files vanish.
read_resource <- function(path) {
 if(!file.exists(path) || dir.exists(path)) stop("Input file does not exist: ",path)
 bytes <- readBin(path,"raw",n=file.info(path)$size)
 list(name=basename(path),path=normalizePath(path,winslash="/"),bytes=bytes,
      sha256=digest::digest(bytes,algo="sha256",serialize=FALSE))
}
read_merged <- function(path) {
 source <- read_resource(path)
 lines <- readLines(path,warn=FALSE,encoding="UTF-8")
 header <- which(grepl("^#?clade_name\t",lines))
 if(length(header)!=1L) stop("Expected one merged MetaPhlAn TSV header: clade_name followed by sample IDs.")
 body <- lines[seq.int(header,length(lines))]; body[1]<-sub("^#","",body[1])
 tab <- read.delim(text=paste(body,collapse="\n"),check.names=FALSE,comment.char="",quote="",colClasses="character",na.strings=NULL)
 annotation <- names(tab) %in% c("clade_name","NCBI_tax_id","clade_taxid")
 if(any(names(tab) %in% c("relative_abundance","additional_species","coverage","estimated_number_of_reads_from_the_clade","estimated_number_of_bases_from_the_clade","marker_name","marker_abundance"))) stop("Native per-sample/marker/read-stat profiles are unsupported. Supply an explicitly labelled merged matrix with sample-ID columns; estimated bases are not reads.")
 samples <- names(tab)[!annotation]
 if(!length(samples) || !nrow(tab)) stop("Merged table must contain taxa and sample columns.")
 vals <- suppressWarnings(matrix(as.numeric(as.matrix(tab[,!annotation,drop=FALSE])),nrow=nrow(tab),dimnames=list(tab[[1]],samples)))
 list(source=source,values=vals,feature_ids=tab[[1]],sample_ids=samples,
      annotations=tab[,annotation,drop=FALSE],comments=lines[seq_len(header-1L)])
}
import_metaphlan <- function(abundance=NULL, metadata, sample_id="sample_id", estimates=NULL) {
 has_relative<-!is.null(abundance)&&length(abundance)==1L&&nzchar(abundance)
 has_estimates<-!is.null(estimates)&&length(estimates)==1L&&nzchar(estimates)
 if(!has_relative&&!has_estimates)stop("Supply a merged relative-abundance or estimated-read table.")
 relative<-if(has_relative)read_merged(abundance) else NULL
 estimated<-if(has_estimates)read_merged(estimates) else NULL
 primary<-if(has_relative)relative else estimated
 m<-read_resource(metadata)
 sep <- if(grepl("\t",readLines(metadata,n=1L,warn=FALSE),fixed=TRUE)) "\t" else ","
 meta <- read.table(metadata,header=TRUE,sep=sep,check.names=FALSE,comment.char="",quote='"',colClasses="character",na.strings=NULL)
 sources<-list(metadata=m)
 if(has_relative)sources$abundance<-relative$source
 if(has_estimates)sources$estimates<-estimated$source
 list(sources=sources,values=primary$values,feature_ids=primary$feature_ids,sample_ids=primary$sample_ids,
      annotations=primary$annotations,metadata=meta,sample_id=sample_id,comments=primary$comments,
      measurement=if(has_relative)"supplied_relative" else "estimated_reads",estimated=estimated)
}
is_estimate_only <- function(input) identical(input$measurement,"estimated_reads")
header_provenance <- function(comments) {
 extract<-function(pattern){z<-regmatches(comments,regexpr(pattern,comments,perl=TRUE));sort(unique(z[nzchar(z)]))}
 list(database=extract("mpa_[A-Za-z0-9_]+"),pipeline=extract("(?i)MetaPhlAn(?: version)?[ =:]+[0-9]+\\.[0-9]+(?:\\.[0-9]+)?"))
}
empty_findings <- function() data.frame(code=character(),severity=character(),field=character(),details=character(),remedy=character())
validate_input <- function(input, declarations=list(), design=list()) {
 f <- empty_findings()
 add <- function(code,severity,field,details,remedy) {
  f[nrow(f)+1L,] <<- list(code,severity,field,paste(details,collapse=", "),remedy)
 }
 ids <- function(v,field) {
  bad <- which(is.na(v)|!nzchar(trimws(v)))
  if(length(bad)) add("blank_id","error",field,paste("positions",paste(bad,collapse=",")),"Supply a nonempty unique ID for every row/column.")
  dup <- unique(v[duplicated(v)])
  if(length(dup)) add("duplicate_id","error",field,dup,"Resolve duplicate IDs in the original input.")
 }
 ids(input$sample_ids,"abundance sample IDs"); ids(input$feature_ids,"feature IDs")
 if(anyDuplicated(names(input$metadata))) add("duplicate_field","error","metadata",names(input$metadata)[duplicated(names(input$metadata))],"Use unique metadata column names.")
 if(!input$sample_id %in% names(input$metadata)) add("id_field","error","metadata",input$sample_id,"Select an existing metadata sample-ID column.") else {
  mid<-input$metadata[[input$sample_id]]; ids(mid,"metadata sample IDs")
  missing<-setdiff(input$sample_ids,mid); extra<-setdiff(mid,input$sample_ids)
  if(length(missing)) add("missing_metadata","error","sample IDs",missing,"Add metadata for these abundance samples.")
  if(length(extra)) add("extra_metadata","error","sample IDs",extra,"Resolve metadata IDs absent from abundance input.")
 }
 bad<-which(!is.finite(input$values)|input$values<0,arr.ind=TRUE)
 if(nrow(bad)) add("invalid_value","error","abundance",apply(bad,1,function(z) paste(input$feature_ids[z[1]],input$sample_ids[z[2]],sep=" / ")),"Supply finite, nonnegative numeric abundance values.")
 scale<-if(is_estimate_only(input))"estimated_reads" else declarations$scale
 if(is_estimate_only(input)) {
  if(!isTRUE(declarations$estimate_normalization))add("estimate_opt_in","error","composition source","Estimated reads supplied without relative abundance.","Explicitly choose relative estimated read contribution among supplied rows.")
 } else {
 if(is.null(scale)||!scale %in% c("percentage","proportion")) add("scale_required","error","scale","Not declared","Declare percentage or proportion; scale is never inferred.") else {
  upper<-if(scale=="percentage")100 else 1
  if(any(input$values>upper,na.rm=TRUE)) add("out_of_range","error","abundance",paste("Values exceed",upper),"Correct values or the declared relative scale.")
 }
 }
 rank<-declarations$rank
 terminal<-sub(".*\\|","",input$feature_ids)
 ranks<-sub("__.*","",terminal)
 if(any(!grepl("^[kpcofgst]__.+",terminal) & input$feature_ids!="UNCLASSIFIED")) add("unsupported_taxon","error","feature IDs",input$feature_ids[!grepl("^[kpcofgst]__.+",terminal)&input$feature_ids!="UNCLASSIFIED"],"Use standard pipe-delimited MetaPhlAn clades or UNCLASSIFIED.")
 if(is.null(rank)||length(rank)!=1L||!rank %in% c("k","p","c","o","f","g","s","t")) add("rank_required","error","rank","No single rank selected","Select one explicit terminal taxonomic rank.") else if(!any(ranks==rank)) add("rank_empty","error","rank",rank,"Select a rank present in the input.")
 if(!is.null(input$estimated)) {
  e<-input$estimated
  if(!identical(declarations$estimate_unit,"estimated_reads"))add("estimate_unit","error","estimated measurement","Units must be explicitly confirmed as estimated reads.","Select estimated reads; estimated bases and observed counts are unsupported.")
  ids(e$sample_ids,"estimated sample IDs");ids(e$feature_ids,"estimated feature IDs")
  bad_est<-which(!is.finite(e$values)|e$values<0,arr.ind=TRUE)
  if(nrow(bad_est))add("estimate_invalid","error","estimated reads",apply(bad_est,1,function(z)paste(e$feature_ids[z[1]],e$sample_ids[z[2]],sep=" / ")),"Supply finite nonnegative values; missing values are not zero.")
  eranks<-sub("__.*","",sub(".*\\|","",e$feature_ids))
  if(any(!grepl("^[kpcofgst]__.+",sub(".*\\|","",e$feature_ids))&e$feature_ids!="UNCLASSIFIED"))add("estimate_taxon","error","estimated feature IDs",e$feature_ids[!grepl("^[kpcofgst]__.+",sub(".*\\|","",e$feature_ids))&e$feature_ids!="UNCLASSIFIED"],"Use standard pipe-delimited clades.")
  if(!setequal(e$sample_ids,input$sample_ids))add("paired_samples","error","paired sample IDs",paste("Relative-only:",paste(setdiff(input$sample_ids,e$sample_ids),collapse=","),"Estimate-only:",paste(setdiff(e$sample_ids,input$sample_ids),collapse=",")),"Match both sample sets exactly.")
  if(length(rank)==1L&&!is.na(rank)&&!setequal(e$feature_ids[eranks==rank],input$feature_ids[ranks==rank]))add("paired_taxa","error","selected-rank feature IDs",paste("Relative-only:",paste(setdiff(input$feature_ids[ranks==rank],e$feature_ids[eranks==rank]),collapse=", "),"Estimate-only:",paste(setdiff(e$feature_ids[eranks==rank],input$feature_ids[ranks==rank]),collapse=", ")),"Supply matching selected-rank taxa; no silent intersection or zero filling.")
  comments<-paste(e$comments,collapse="\n")
  badunit<-grepl("(?i)estimated[_ ](?:number[_ ]of[_ ])?bases|measurement[ =:]+(?!estimated_reads(?:$|[[:space:]]))[A-Za-z_]+|--long_reads|(?:^|[[:space:]])-t[ =]+(?!rel_ab_w_read_stats(?:$|[[:space:]]))[A-Za-z_]+",comments,perl=TRUE)
  if(badunit)add("estimate_header_conflict","error","estimated source headers","Header declares conflicting measurement, command or long-read units.","Supply a verified merged estimated-read matrix; do not relabel bases or marker outputs.")
  if(!is_estimate_only(input)) {
   a<-header_provenance(input$comments);b<-header_provenance(e$comments)
   for(field in names(a))if(length(a[[field]])&&length(b[[field]])&&!identical(tolower(a[[field]]),tolower(b[[field]])))add("paired_provenance","error",field,"Known relative/estimated source headers disagree.","Resolve provenance conflict before combining measurements.")
  }
  add("estimated_measurement","info","estimated reads","Estimated measurements are retained separately; they are not observed raw counts or a statistical-readiness certificate.","Supplied relative values are preferred; estimate-only contribution has a different denominator.")
 }
 for(n in c("pipeline","database")) {
  val<-declarations[[n]]
  if(is.null(val)||!nzchar(trimws(val))||tolower(trimws(val))=="unknown") add("declaration_missing","warning",n,"Missing or unknown","Declare this history; descriptive output cannot verify it.")
 }
 for(n in c("denominator_kind","coverage")) if(is.null(declarations[[n]])||declarations[[n]]=="unknown") add("history_unknown","warning",n,if(is_estimate_only(input))"Source history unknown; opted-in contribution divides selected-rank estimates by their sum plus supplied UNCLASSIFIED." else "Not known; descriptive values are shown as supplied.",if(is_estimate_only(input))"Confirm source history; normalization describes supplied rows only, not MetaPhlAn relative abundance." else "Confirm source history when available; no normalization is applied.")
 if(!is.null(declarations$denominator_kind)&&!declarations$denominator_kind %in% c("unknown","profiled","including_unclassified"))add("meaning_invalid","error","100% reference",declarations$denominator_kind,"Choose a supported reference population.")
 if(!is.null(declarations$coverage)&&!declarations$coverage %in% c("unknown","complete","removed","rescaled"))add("coverage_invalid","error","coverage",declarations$coverage,"Choose a supported coverage declaration.")
 fields<-unique(c(design$group,design$time,design$unit,design$repeated,design$covariates))
 fields<-fields[!is.na(fields)&nzchar(fields)]
 absent<-setdiff(fields,names(input$metadata))
 if(length(absent)) add("design_field","error","design",absent,"Select existing metadata fields.")
 for(n in intersect(fields,names(input$metadata))) if(any(!nzchar(trimws(input$metadata[[n]])))) add("missing_design_value","warning",n,"Blank metadata values","Resolve missing design values before any later inference.")
 if(is.null(design$unit)||!nzchar(design$unit)) add("unit_missing","warning","experimental unit","Not declared; repeated-measures readiness is not established","Declare the experimental-unit ID using study records.")
 add("descriptive_only","info","design","Input setup does not certify independence or repeated-measures readiness.","Review and declare study design separately before Alpha or Beta comparisons.")
 types<-design$types
 if(length(types)) for(n in names(types)) {
  if(!n %in% names(input$metadata)) {add("type_field","error","metadata types",n,"Select an existing field.");next}
  if(!types[[n]] %in% c("id","categorical","continuous","date","text")) {add("type_invalid","error",n,types[[n]],"Use id, categorical, continuous, date or text.");next}
  v<-input$metadata[[n]]; present<-nzchar(trimws(v))
  if(types[[n]]=="continuous" && any(!is.finite(suppressWarnings(as.numeric(v[present]))))) add("type_parse","error",n,"Nonnumeric values","Correct values or change the declared field type.")
  if(types[[n]]=="date" && any(is.na(suppressWarnings(as.Date(v[present],format="%Y-%m-%d"))))) add("type_parse","error",n,"Invalid ISO dates","Use YYYY-MM-DD or another field type.")
 }
 f
}

# Wrap public mia import after strict validation. Neutral temporary sample keys avoid
# mia 1.20.0's regex-based annotation-column detection; originals are restored.
import_rank <- function(input,rank) {
 tmp<-tempfile(fileext=".tsv");on.exit(unlink(tmp))
 tab<-data.frame(clade_name=input$feature_ids,input$values,check.names=FALSE)
 names(tab)[-1L]<-paste0("Sample",seq_along(input$sample_ids))
 utils::write.table(tab,tmp,sep="\t",quote=FALSE,row.names=FALSE)
 tse<-mia::importMetaPhlAn(tmp,col.data=NULL,tree.file=NULL,assay.type="original",remove.suffix=FALSE,prefix.rm=FALSE,set.ranks=FALSE)
 rank_name<-c(k="kingdom",p="phylum",c="class",o="order",f="family",g="genus",s="species",t="strain")[[rank]]
 if(!rank_name %in% SingleCellExperiment::altExpNames(tse))stop("Upstream import did not retain the selected rank: ",rank)
 se<-SingleCellExperiment::altExp(tse,rank_name)
 lineage<-as.character(SummarizedExperiment::rowData(se)$clade_name)
 expected<-input$feature_ids[sub("__.*","",sub(".*\\|","",input$feature_ids))==rank]
 if(!setequal(lineage,expected)||anyDuplicated(lineage))stop("Upstream import changed selected feature identity.")
 se<-se[match(expected,lineage),,drop=FALSE]
 rownames(se)<-expected;colnames(se)<-input$sample_ids
 original<-input$values[match(expected,input$feature_ids),,drop=FALSE]
 imported<-SummarizedExperiment::assay(se,"original")
 # read.table/type.convert and as.numeric can differ at machine precision.
 # Check interoperability, then retain the exact original validated parse.
 if(any(!is.finite(imported)) || any(abs(imported-original)>16*.Machine$double.eps*pmax(1,abs(original))))stop("Upstream import changed original values.")
 SummarizedExperiment::assay(se,"original")<-original
 TreeSummarizedExperiment::TreeSummarizedExperiment(assays=SummarizedExperiment::assays(se),rowData=SummarizedExperiment::rowData(se),colData=SummarizedExperiment::colData(se))
}
source_evidence <- function(input) {
 comments<-input$comments
 pipeline<-comments[grepl("MetaPhlAn.*[0-9]+\\.[0-9]+",comments,ignore.case=TRUE)]
 database<-comments[grepl("mpa_[A-Za-z0-9_]+",comments)]
 list(pipeline=if(length(pipeline))sub("^#+","",pipeline[1]) else "",
      database=if(length(database))sub("^#+","",database[1]) else "",
      source=if(length(comments))paste(comments,collapse="\n") else "No supported source headers found.")
}

