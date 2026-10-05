beta_plot_settings <- function(settings=list()) {
 if(is.null(settings))settings<-list()
 extra<-list(axis_x=1L,axis_y=2L,positive_share=FALSE,group_centres=FALSE)
 s<-alpha_plot_settings(settings[setdiff(names(settings),names(extra))])
 for(n in intersect(names(settings),names(extra)))extra[[n]]<-settings[[n]]
 for(n in c("axis_x","axis_y"))if(length(extra[[n]])!=1L||!is.numeric(extra[[n]])||!is.finite(extra[[n]])||extra[[n]]<1||extra[[n]]!=floor(extra[[n]]))stop("PCoA axes must be positive integers.")
 preparation_flag(extra$positive_share,"positive_share");preparation_flag(extra$group_centres,"group_centres")
 c(s,extra)
}
beta_style <- function(beta,data,settings=beta$plot_settings) {
 s<-beta_plot_settings(settings);a<-beta;a$plot_settings<-s[setdiff(names(s),c("axis_x","axis_y","positive_share","group_centres"))]
 z<-alpha_style_data(a,data,a$plot_settings);z$beta_settings<-s;z
}
plot_beta <- function(project,settings=project$beta$plot_settings) {
 beta_current(project);b<-project$beta;o<-b$ordination
 if(o$status!="ready")stop("Ordination is undefined: ",o$reason)
 z<-beta_style(b,o$scores,settings);d<-z$data;s<-z$beta_settings;axes<-paste0("PCoA",c(s$axis_x,s$axis_y))
 if(!axes[1]%in%names(d))stop("Requested horizontal PCoA axis is unavailable.")
 one<-!axes[2]%in%names(d)&&ncol(o$scores)==2L&&s$axis_y==2L
 if(!axes[2]%in%names(d)&&!one)stop("Requested vertical PCoA axis is unavailable.")
 d$.x<-d[[axes[1]]];d$.y<-if(one)0 else d[[axes[2]]]
 label<-function(i)if(s$positive_share)paste0("PCoA",i," (",format(100*o$eigenvalues[o$eigenvalues>0][i]/o$positive_inertia,digits=3),"% of positive eigenvalue sum)") else paste0("PCoA",i)
 p<-ggplot2::ggplot(d,ggplot2::aes(x=.x,y=.y))
 if(isTRUE(s$trajectories)) {
  c<-b$comparison;ss<-c$settings
  if(is.null(c)||!c$status%in%c("ready","partial")||!ss$route%in%c("paired","within","trajectory"))stop("Trajectory lines require an applied verified within-unit or whole-trajectory hypothesis.")
  frame<-c$results$omnibus$frame;if(ss$route=="trajectory")frame<-c$results$omnibus$permutation$mapping
  ix<-match(d$sample_id,frame$sample_id);keep<-!is.na(ix);dd<-d[keep,,drop=FALSE];dd$.unit<-frame$unit[ix[keep]]
  v<-if(ss$route=="trajectory")frame$visit[ix[keep]] else as.character(frame$group[ix[keep]])
  numeric_v<-suppressWarnings(as.numeric(v));dd$.visit_order<-if(all(is.finite(numeric_v)))numeric_v else match(v,sort(unique(v),method="radix"))
  dd<-dd[order(dd$.unit,dd$.visit_order),,drop=FALSE]
  p<-p+ggplot2::geom_path(data=dd,ggplot2::aes(group=.unit),colour="grey65",linewidth=.4)
  attr(d,"trajectory_data")<-dd
 }
 p<-p+ggplot2::geom_point(ggplot2::aes(colour=.colour,fill=.colour,shape=.shape),size=3)+alpha_style_layers(z)+ggplot2::facet_wrap(ggplot2::vars(.facet))+ggplot2::coord_equal()+ggplot2::labs(x=label(s$axis_x),y=if(one)"No second positive dimension (displayed at zero)" else label(s$axis_y),title=paste(beta_metric_label(b$settings$metric),"PCoA - rank",b$rank),subtitle=paste(b$source_label,"; geometry:",o$correction),caption=paste(strwrap(paste("Named features only, no reclosure. Absolute negative inertia:",format(o$negative_inertia,digits=5),". Shapes 21-25 use selected colour for fill and outline. Group centres, if shown, are descriptive projected means; no confidence regions."),width=90),collapse="\n"))
 if(s$group_centres&&nzchar(s$group)) {
  centres<-stats::aggregate(cbind(.x,.y)~.group+.facet,data=d,FUN=mean)
  p<-p+ggplot2::geom_text(data=centres,ggplot2::aes(label=.group),inherit.aes=TRUE,colour="black",vjust=-.8,size=3);attr(p,"beta_centres")<-centres
 }
 attr(p,"beta_data")<-d;attr(p,"beta_styles")<-list(colours=z$colours,shapes=z$shapes);p
}
plot_beta_dispersion <- function(project,settings=project$beta$plot_settings) {
 beta_current(project);b<-project$beta;r<-b$dispersion
 if(is.null(r)||r$status!="ready")stop("No ready saved independent dispersion result.")
 z<-beta_style(b,data.frame(sample_id=b$sample_ids),settings);i<-match(r$distances$sample_id,z$data$sample_id)
 d<-cbind(r$distances,z$data[i,setdiff(names(z$data),"sample_id"),drop=FALSE]);d$.x<-match(d$group,sort(unique(d$group)));d$.y<-d$distance
 p<-ggplot2::ggplot(d,ggplot2::aes(x=.x,y=.y))+ggplot2::geom_point(ggplot2::aes(colour=.colour,fill=.colour,shape=.shape),size=3)+alpha_style_layers(z)+ggplot2::scale_x_continuous(breaks=seq_along(sort(unique(d$group))),labels=sort(unique(d$group)))+ggplot2::facet_wrap(ggplot2::vars(.facet))+ggplot2::labs(x=r$settings$group,y="Distance to group spatial median",title=paste(beta_metric_label(b$settings$metric),"independent dispersion"),subtitle=paste("Bias adjustment:",r$settings$bias_adjust),caption="Individual centre distances. No confidence interval or automatic homogeneity clearance. Colour and shape are independent metadata mappings.")
 attr(p,"beta_data")<-d;attr(p,"beta_styles")<-list(colours=z$colours,shapes=z$shapes);p
}
plot_beta_eigenvalues <- function(project) {
 beta_current(project);d<-project$beta$ordination$diagnostics
 if(is.null(d))stop("No nonzero eigenvalue diagnostics.")
 p<-ggplot2::ggplot(d,ggplot2::aes(x=axis,y=eigenvalue,fill=negative))+ggplot2::geom_col()+ggplot2::scale_fill_manual(values=c(`FALSE`="#147D80",`TRUE`="#B74F39"),name="Negative eigenvalue")+ggplot2::theme_bw()+ggplot2::labs(x="Eigenvalue index",y="Signed eigenvalue",title="Saved PCoA spectrum",caption="Positive-axis shares use the sum of positive eigenvalues; negative inertia is retained explicitly. Point shapes do not apply to this bar geometry.")
 attr(p,"beta_data")<-d;p
}
plot_beta_permutations <- function(project,result="omnibus",term=1L,dispersion=FALSE) {
 beta_current(project);r<-if(dispersion)project$beta$dispersion else project$beta$comparison$results[[result]]
 if(is.null(r)||r$status!="ready"||is.null(r$permuted))stop("No saved permutation statistics for this result.")
 values<-as.matrix(r$permuted);if(term<1||term>ncol(values))stop("Permutation term is unavailable.")
 d<-data.frame(permutation=seq_len(nrow(values)),F=values[,term]);observed<-r$tests$F[term]
 p<-ggplot2::ggplot(d,ggplot2::aes(x=F))+ggplot2::geom_histogram(data=d[is.finite(d$F),,drop=FALSE],bins=30,fill="#147D80",colour="white")+ggplot2::geom_vline(xintercept=observed,colour="#B74F39",linewidth=.8)+ggplot2::theme_bw()+ggplot2::labs(x="Saved permuted pseudo-F / F",y="Count",title="Applied permutation distribution",subtitle=paste("Observed:",format(observed,digits=6)),caption=paste("Saved statistics only; no permutations are generated by rendering. Red line marks observed statistic; point shapes do not apply. Nonfinite permutation values retained in exported data but omitted from histogram:",sum(!is.finite(d$F))))
 attr(p,"beta_data")<-d;p
}
beta_report <- function(project,images=character()) {
 b<-project$beta;results<-b$comparison$results
 htmltools::tagList(htmltools::tags$h1("Beta diversity"),htmltools::tags$p(paste(b$status,b$reason,b$source_label,b$normalization)),htmltools::tags$pre(paste(capture.output(str(list(calculation=b$settings,styles=b$plot_settings,versions=b$versions))),collapse="\n")),htmltools::tags$h2("Transformation diagnostics"),htmltools::tags$p(paste(b$transformation$warnings,collapse="; ")),htmltools::tags$pre(paste(capture.output(str(b$transformation[c("formula","addition_scope","affected_cells","source_zeros","optimizer")],max.level=3)),collapse="\n")),htmltools::tags$h2("Mass and geometry"),html_table(b$mass),html_table(b$ordination$diagnostics),htmltools::tags$h2("Community comparisons"),htmltools::tags$p(paste(b$comparison$status,b$comparison$reason)),html_table(b$comparison$tests),html_table(b$comparison$pairwise),lapply(names(results),function(n){r<-results[[n]];htmltools::tagList(htmltools::tags$h3(n),htmltools::tags$p(paste(r$status,r$reason,r$formula,r$R2_definition)),htmltools::tags$p(r$permutation$summary),htmltools::tags$pre(paste(r$permutation$readable_call,r$readable_call,sep="\n")),html_table(r$exclusions),html_table(r$permutation$preview),html_table(r$permutation$invariants))}),htmltools::tags$h2("Independent dispersion"),htmltools::tags$p(paste(b$dispersion$status,b$dispersion$reason)),html_table(b$dispersion$tests),html_table(b$dispersion$group_summary),htmltools::tags$p(paste("Negative squared distances truncated to zero:",b$dispersion$negative_squared_count)),htmltools::tags$p(paste(b$dispersion$warnings,collapse="; ")),htmltools::tags$p(b$dispersion$permutation$summary),htmltools::tags$pre(paste(b$dispersion$permutation$readable_call,b$dispersion$readable_call,sep="\n")),html_table(b$dispersion$exclusions),html_table(b$dispersion$permutation$preview),htmltools::tags$p("Unit/assignment declarations require analyst evidence. More permutations cannot repair invalid replication. R-squared uses stated total inertia, without invented confidence intervals; dispersion is separate from community location. Ordered time is not automatically exchangeable."),lapply(images,function(n)htmltools::tags$img(src=n,alt=n,style="max-width:100%")))
}
export_beta <- function(project,directory) {
 check_project(project);beta_current(project);new_export_path(directory)
 if(!dir.create(directory))stop("Could not create beta output directory.")
 dir.create(file.path(directory,"inputs"));for(n in names(project$input$sources))writeBin(project$input$sources[[n]]$bytes,file.path(directory,"inputs",paste0(n,if(n=="metadata")".txt" else ".tsv")))
 save_project(project,file.path(directory,"project.rds"));b<-project$beta;saveRDS(b,file.path(directory,"beta.rds"))
 write<-function(d,n)if(!is.null(d))utils::write.table(d,file.path(directory,paste0(n,".tsv")),sep="\t",quote=TRUE,row.names=FALSE,na="NA")
 write(data.frame(sample_id=attr(b$distance,"Labels"),as.matrix(b$distance),check.names=FALSE),"original-distance");write(b$mass,"mass");write(b$ordination$scores,"ordination-scores");write(b$ordination$diagnostics,"eigenvalues");write(b$comparison$tests,"comparisons");write(b$comparison$pairwise,"pairwise");write(b$dispersion$tests,"dispersion-test");write(b$dispersion$distances,"dispersion-distances");write(b$dispersion$group_summary,"dispersion-group-summary");write(b$dispersion$signed_squared_distances,"dispersion-signed-squared-distances")
 if(!is.null(b$transformation)) {
  tr<-b$transformation;saveRDS(tr,file.path(directory,"transformation.rds"))
  write_assay_table(data.frame(feature_id=rownames(tr$values),tr$values,check.names=FALSE),file.path(directory,"transformed-values.tsv"))
  write(data.frame(feature_id=rownames(tr$zero_mask),tr$zero_mask,check.names=FALSE),"source-zero-mask")
  if(!is.null(tr$observed))write_assay_table(data.frame(feature_id=rownames(tr$observed),tr$observed,check.names=FALSE),file.path(directory,"observed-rclr.tsv"))
  if(!is.null(tr$optimizer$result))write(data.frame(iteration=seq_along(tr$optimizer$result$dist)-1L,scaled_residual=as.numeric(tr$optimizer$result$dist)),"completion-history")
 }
 for(n in names(b$comparison$results)) {
  r<-b$comparison$results[[n]];write(as.data.frame(r$inertia),paste0(n,"-inertia"));write(r$permutation$visit_weights,paste0(n,"-visit-weights"));write(r$frame,paste0(n,"-model-frame"));write(r$exclusions,paste0(n,"-exclusions"));write(r$permutation$preview,paste0(n,"-permutation-preview"));write(r$permutation$indices,paste0(n,"-permutation-indices"));saveRDS(r,file.path(directory,paste0(n,"-result.rds")))
 }
 if(!is.null(b$dispersion$permutation)){write(b$dispersion$permutation$indices,"dispersion-permutation-indices");write(b$dispersion$permutation$preview,"dispersion-permutation-preview")}
 calls<-c("# Saved public calls and exact permutation plans; beta.rds includes every matrix and control.",capture.output(dput(list(calculation=b$settings,comparison=b$comparison$settings,dispersion=b$dispersion$settings))))
 for(r in b$comparison$results)calls<-c(calls,r$permutation$readable_call,r$readable_call)
 calls<-c(calls,b$transformation$readable_call,b$dispersion$permutation$readable_call,b$dispersion$readable_call)
 writeLines(calls,file.path(directory,"applied-methods.R.txt"))
 plots<-list();if(b$ordination$status=="ready"){plots$ordination<-plot_beta(project);plots$spectrum<-plot_beta_eigenvalues(project)}
 if(!is.null(b$comparison$results$omnibus)&&b$comparison$results$omnibus$status=="ready")plots$permutations<-plot_beta_permutations(project)
 if(!is.null(b$dispersion)&&b$dispersion$status=="ready"){plots$dispersion<-plot_beta_dispersion(project);plots$dispersion_permutations<-plot_beta_permutations(project,dispersion=TRUE)}
 images<-character();s<-beta_plot_settings(b$plot_settings)$figure
 for(n in names(plots)) {
  write(attr(plots[[n]],"beta_data"),paste0(n,"-plot-data"));if(!is.null(attr(plots[[n]],"beta_centres")))write(attr(plots[[n]],"beta_centres"),paste0(n,"-centres"))
  write(attr(attr(plots[[n]],"beta_data"),"trajectory_data"),paste0(n,"-trajectory-data"))
  alpha_write_figure(plots[[n]],file.path(directory,paste0(n,".",s$format)),s);preview<-paste0(n,if(s$format=="png")".png" else "-preview.png")
  if(s$format!="png")alpha_write_figure(plots[[n]],file.path(directory,preview),modifyList(s,list(format="png")));images<-c(images,preview)
 }
 htmltools::save_html(htmltools::tags$html(htmltools::tags$head(htmltools::tags$meta(charset="utf-8"),htmltools::tags$style("body{font:15px system-ui;margin:32px}table{border-collapse:collapse;font-size:12px}td,th{border:1px solid #ccc;padding:5px}pre{white-space:pre-wrap}")),htmltools::tags$body(beta_report(project,images))),file.path(directory,"beta.html"))
 libs<-normalizePath(.libPaths(),winslash="/",mustWork=FALSE)
 writeLines(c("# Prefer the active installed engine; recorded libraries are fallback only.",paste0("if (!requireNamespace('microbiomeengine', quietly=TRUE)) .libPaths(c(",paste(deparse(libs),collapse=""),", .libPaths()))"),"args<-commandArgs(TRUE)","if(length(args)!=2L)stop('Supply bundle and new output')","microbiomeengine::replay_beta(args[1],args[2])"),file.path(directory,"replay.R"))
 writeLines(capture.output(sessionInfo()),file.path(directory,"session.txt"))
 files<-list.files(directory,recursive=TRUE,full.names=TRUE);manifest<-data.frame(path=substring(files,nchar(directory)+2),sha256=vapply(files,function(f)digest::digest(file=f,algo="sha256"),character(1)))
 write(manifest,"manifest");writeLines("Beta export complete; replay is a separate verification.",file.path(directory,"COMPLETE"));invisible(directory)
}
beta_recalculate <- function(saved,p) {
 b<-saved$beta;if(is.null(b))return(p)
 p<-apply_beta(p,b$settings,b$plot_settings,b$comparison$settings,b$dispersion$settings)
 for(n in c("status","settings","fingerprint","metadata","distance","mass","versions","plot_settings","ordination","comparison","dispersion","transformation"))if(!isTRUE(all.equal(b[[n]],p$beta[[n]],tolerance=1e-9)))stop("Beta replay differs: ",n)
 p
}
replay_beta <- function(bundle,output) {
 if(!file.exists(file.path(bundle,"COMPLETE")))stop("Incomplete beta bundle.")
 manifest<-utils::read.delim(file.path(bundle,"manifest.tsv"),stringsAsFactors=FALSE)
 for(i in seq_len(nrow(manifest)))if(!identical(digest::digest(file=file.path(bundle,manifest$path[i]),algo="sha256"),manifest$sha256[i]))stop("Beta manifest hash mismatch: ",manifest$path[i])
 saved<-open_project(file.path(bundle,"project.rds"));beta_current(saved)
 x<-import_metaphlan(if("abundance"%in%names(saved$input$sources))file.path(bundle,"inputs","abundance.tsv") else NULL,file.path(bundle,"inputs","metadata.txt"),saved$input$sample_id,estimates=if("estimates"%in%names(saved$input$sources))file.path(bundle,"inputs","estimates.tsv") else NULL)
 for(n in names(x$sources))if(!identical(x$sources[[n]]$sha256,saved$input$sources[[n]]$sha256))stop("Beta input hash mismatch: ",n)
 p<-prepare_project(x,saved$declarations,saved$design,saved$settings,saved$preparation$settings);p<-beta_recalculate(saved,p)
 export_beta(p,output);writeLines("Beta distance, geometry, hypotheses, exact permutations, diagnostics and styles agree.",file.path(output,"VERIFIED"));invisible(p)
}
utils::globalVariables(c(".visit_order","axis","eigenvalue","negative","F"))
