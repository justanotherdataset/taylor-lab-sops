prepare_project <- function(input, declarations=list(), design=list(), settings=list(), preparation=list()) {
 declarations<-modifyList(list(denominator_kind="unknown",coverage="unknown"),declarations)
 declarations$denominator<-switch(declarations$denominator_kind,profiled="Profiled / classified community",including_unclassified="Profile including supplied estimated unclassified fraction","Unknown reference population")
 settings<-modifyList(list(group="",facet="",order="input",palette="viridis",residual=FALSE,taxa_mode="all",top_n=10L,show_other=TRUE,show_unclassified=TRUE,figure=list()),settings)
 settings$figure<-figure_settings(settings$figure)
 if(is_estimate_only(input))declarations$denominator<-"Relative estimated read contribution among supplied rows (selected rank plus supplied UNCLASSIFIED)"
 p<-list(schema=4L,input=input,declarations=declarations,design=design,settings=settings,
         findings=validate_input(input,declarations,design),history=list(),experiment=NULL,canonical=NULL,table=NULL,
         preparation=list(settings=preparation,status="blocked"))
 if(any(p$findings$severity=="error")) return(p)
 keep<-sub("__.*","",sub(".*\\|","",input$feature_ids))==declarations$rank
 experiment<-import_rank(input,declarations$rank)
 original<-SummarizedExperiment::assay(experiment,"original")
 factor<-if(identical(declarations$scale,"percentage"))100 else 1
 supplied_unclassified<-if("UNCLASSIFIED" %in% input$feature_ids) input$values["UNCLASSIFIED",] else rep(0,ncol(original))
 if(is_estimate_only(input)) {
  denominator<-colSums(original)+supplied_unclassified
  if(any(!is.finite(denominator)|denominator<=0)) {
   p$findings[nrow(p$findings)+1L,]<-list("estimate_zero_total","error","normalization denominator",paste(input$sample_ids[!is.finite(denominator)|denominator<=0],collapse=", "),"Selected-rank estimates plus supplied UNCLASSIFIED must have a finite positive total for every sample.")
   return(p)
  }
  rel<-sweep(original,2,denominator,"/");unclassified<-supplied_unclassified/denominator
  p$normalization<-list(source="estimated_contribution",denominator=declarations$denominator,totals=setNames(denominator,input$sample_ids),operation="divide_by_selected_rank_plus_supplied_unclassified")
 } else {
  rel<-original/factor;unclassified<-supplied_unclassified/factor
  denominator<-rep(NA_real_,ncol(original))
  p$normalization<-list(source="supplied_relative",denominator=declarations$denominator,divisor=factor,operation=if(factor==100)"percentage_to_proportion" else "retain_proportion")
 }
 totals<-colSums(rel)+unclassified
 if(any(totals>1+1e-6)) {
  p$findings[nrow(p$findings)+1L,]<-list("mass_excess","error","selected rank",paste(input$sample_ids[totals>1+1e-6],collapse=", "),"Selected rank plus supplied UNCLASSIFIED exceeds declared relative mass; check overlapping taxa, scale and denominator.")
  return(p)
 }
 if(any(totals>1+1e-12)) p$findings[nrow(p$findings)+1L,]<-list("small_mass_excess","info","selected rank",paste0("Supplied totals slightly exceed 100% (maximum ",format(max(totals)*100,digits=12),"%). Within the 0.0001 percentage-point tolerance; may reflect reported precision. Values are retained exactly."),"Review source precision. No rescaling is applied; plotted segments are preserved.")
 meta<-input$metadata[match(input$sample_ids,input$metadata[[input$sample_id]]),,drop=FALSE]
 rownames(meta)<-input$sample_ids
 SummarizedExperiment::assay(experiment,"relative")<-rel
 if(!is.null(input$estimated))SummarizedExperiment::assay(experiment,"estimated_reads")<-input$estimated$values[match(rownames(experiment),input$estimated$feature_ids),match(input$sample_ids,input$estimated$sample_ids),drop=FALSE] |> `dimnames<-`(dimnames(original))
 SummarizedExperiment::colData(experiment)<-S4Vectors::DataFrame(meta)
 S4Vectors::metadata(experiment)<-list(declarations=declarations,design=design)
 p$experiment<-experiment
 p$mass<-data.frame(sample_id=input$sample_ids,selected=colSums(rel),unclassified=unclassified,
                    difference_from_one=pmax(0,1-totals),denominator_total=denominator,row.names=NULL)
 if(any(p$mass$difference_from_one>1e-6)) p$findings[nrow(p$findings)+1L,]<-list("unassigned_difference","info","relative mass","Selected taxa and supplied unclassified values do not reach 100%. The difference is not identified as a taxon or unclassified abundance.","Review table coverage and source processing. Values are not rescaled.")
 p$history<-list(list(operation="align_metadata_by_id",field=input$sample_id,order=input$sample_ids),
  list(operation="mia_import_and_select_rank",package_version=as.character(utils::packageVersion("mia")),rank=declarations$rank,retained=input$feature_ids[keep],excluded=input$feature_ids[!keep]),
  p$normalization,
  list(operation="declare_metadata_and_design",design=design))
 p$canonical<-experiment;p$canonical_mass<-p$mass
 p<-prepare_view(p,preparation)
 if(is.null(p$experiment))return(p)
 p$table<-tryCatch(composition_table(p,settings),composition_limit=function(e){
  p$findings[nrow(p$findings)+1L,]<<-list("composition_limit","warning","display",conditionMessage(e),"Select top N with fewer taxa. Canonical measurements remain available and unchanged.");NULL
 })
 if(!is.null(p$table)) {
  p$membership<-attr(p$table,"membership")
  p$display_mass<-unique(p$table[,c("display","facet","omitted_mass","feature_removed_mass","supplied_unclassified_mass","unresolved_difference"),drop=FALSE])
  p$table<-plot_composition(p)$data
 }
 p$history[[length(p$history)+1L]]<-list(operation="composition",settings=settings)
 p
}
example_project <- function() {
 d<-system.file("extdata",package="microbiomeengine")
 x<-import_metaphlan(file.path(d,"abundance.tsv"),file.path(d,"metadata.csv"))
 prepare_project(x,list(rank="s",scale="percentage",denominator_kind="including_unclassified",coverage="removed",pipeline="Synthetic MetaPhlAn-style fixture v1",database="synthetic_database_v1",filtering="10% omitted at selected rank by construction",unclassified="Supplied UNCLASSIFIED row retained"),
 list(types=c(sample_id="id",group="categorical",time="continuous",unit="id",age="continuous"),group="group",time="time",unit="unit",repeated="",covariates="age"))
}


