alpha_plot_settings <- function(settings=list()) {
 defaults<-list(group="",facet="",colour="",colour_type="categorical",fixed_colour="#147D80",palette="Dark 3",colours=character(),shape="",fixed_shape=16L,shapes=integer(),order=character(),trajectories=FALSE,figure=list(format="png",width=12,height=8,units="in",dpi=150))
 if(!is.list(settings)||length(setdiff(names(settings),names(defaults))))stop("Unknown alpha plot setting.")
 s<-modifyList(defaults,settings)
 for(n in c("group","facet","colour","shape","fixed_colour","palette","colour_type"))if(!is.character(s[[n]])||length(s[[n]])!=1L||is.na(s[[n]]))stop("Plot roles must be single strings.")
 if(!s$colour_type%in%c("categorical","continuous"))stop("Choose categorical or continuous colour.")
 if(!s$palette%in%grDevices::hcl.pals())stop("Choose a supported HCL palette.")
 if(length(s$fixed_shape)!=1L||!is.numeric(s$fixed_shape)||is.na(s$fixed_shape)||!s$fixed_shape%in%0:25)stop("Point shape must be an integer from 0 to 25.")
 for(n in c("colours","shapes"))if(length(s[[n]])&&(is.null(names(s[[n]]))||anyNA(names(s[[n]]))||anyDuplicated(names(s[[n]]))||any(!nzchar(names(s[[n]])))))stop("Manual styles need unique exact level names.")
 if(length(s$shapes)&&(!is.numeric(s$shapes)||anyNA(s$shapes)||any(!s$shapes%in%0:25)))stop("Manual shapes must be integers from 0 to 25.")
 tryCatch(grDevices::col2rgb(c(s$fixed_colour,s$colours)),error=function(e)stop("Invalid colour name or hexadecimal value."))
 if(!is.character(s$order)||anyNA(s$order)||anyDuplicated(s$order))stop("Order must list unique exact group labels.")
 s$figure<-figure_settings(s$figure);s
}
alpha_levels <- function(v) {
 v<-as.character(v);missing<-is.na(v)|!nzchar(trimws(v));label<-"<Missing>"
 while(label%in%v[!missing])label<-paste0(label,"*")
 v[missing]<-label;factor(v,levels=sort(unique(v),method="radix"))
}
alpha_style_data <- function(alpha,data,settings=alpha$plot_settings) {
 s<-alpha_plot_settings(if(is.null(settings))list() else settings);meta<-alpha$metadata
 roles<-c(s$group,s$facet,s$colour,s$shape);if(any(!roles[roles!=""]%in%names(meta)))stop("A plot metadata role is unavailable.")
 i<-match(data$sample_id,rownames(meta));if(anyNA(i))stop("Plot sample identity mismatch.")
 field<-function(n,default)if(nzchar(n))meta[[n]][i] else default
 data$.group<-alpha_levels(field(s$group,data$sample_id));data$.facet<-alpha_levels(field(s$facet,rep("All samples",nrow(data))))
 if(length(s$order)){if(!setequal(s$order,levels(data$.group)))stop("Order must contain every exact displayed group level.");data$.group<-factor(data$.group,levels=s$order)}
 data$.colour<-if(s$colour_type=="continuous"&&nzchar(s$colour)) {
  v<-field(s$colour,NULL);num<-suppressWarnings(as.numeric(as.character(v)))
  if(any(!is.na(v)&nzchar(trimws(as.character(v)))&!is.finite(num)))stop("Continuous colour requires finite numeric values or missing values.")
  num
 }else alpha_levels(field(s$colour,rep("Fixed",nrow(data))))
 data$.shape<-alpha_levels(field(s$shape,rep("Fixed",nrow(data))))
 if(nzchar(s$shape)&&(is.numeric(meta[[s$shape]])||any(alpha$metadata_types[s$shape]%in%c("continuous","date"))))stop("Shape mapping is categorical only; select a categorical column.")
 shape_levels<-levels(data$.shape);available<-unique(c(16,17,15,18,3,7,8,0:25))
 if(length(shape_levels)>length(available))stop("Too many shape levels: at most 26 supported. Choose another categorical field.")
 shapes<-setNames(if(nzchar(s$shape))available[seq_along(shape_levels)] else s$fixed_shape,shape_levels)
 if(length(setdiff(names(s$shapes),shape_levels)))stop("A manual shape level is absent from this plotted cohort.")
 shapes[names(s$shapes)]<-s$shapes
 if(anyDuplicated(shapes))stop("Use a distinct shape for every mapped level.")
 colours<-NULL
 if(is.factor(data$.colour)) {
  lev<-levels(data$.colour);colours<-setNames(if(nzchar(s$colour))grDevices::hcl.colors(length(lev),s$palette) else s$fixed_colour,lev)
  if(length(setdiff(names(s$colours),lev)))stop("A manual colour level is absent from this plotted cohort.")
  colours[names(s$colours)]<-s$colours
 }else if(length(s$colours))stop("Manual level colours apply only to categorical colour.")
 list(data=data,settings=s,colours=colours,shapes=shapes)
}
alpha_style_layers <- function(z) {
 s<-z$settings
 colour<-if(is.null(z$colours))list(ggplot2::scale_colour_gradientn(colours=grDevices::hcl.colors(20,s$palette),na.value="grey60",name=paste(s$colour,"(continuous; missing = grey)")),ggplot2::scale_fill_gradientn(colours=grDevices::hcl.colors(20,s$palette),na.value="grey60",guide="none")) else list(ggplot2::scale_colour_manual(values=z$colours,drop=FALSE,name=if(nzchar(s$colour))s$colour else "Colour",guide=if(nzchar(s$colour))"legend" else "none"),ggplot2::scale_fill_manual(values=z$colours,drop=FALSE,guide="none"))
 c(colour,list(ggplot2::scale_shape_manual(values=z$shapes,drop=FALSE,name=if(nzchar(s$shape))s$shape else "Shape",guide=if(nzchar(s$shape))"legend" else "none"),ggplot2::theme_bw(base_size=12),ggplot2::theme(axis.text.x=ggplot2::element_text(angle=45,hjust=1))))
}
plot_alpha <- function(project,settings=project$alpha$plot_settings) {
 alpha_current(project);a<-project$alpha;z<-alpha_style_data(a,a$values,settings);d<-z$data;s<-z$settings
 d$.x<-as.numeric(d$.group)
 # Stable small offsets are saved in plot data; no random jitter or averaging.
 if(nzchar(s$group))for(k in unique(paste(d$metric,d$.group,d$.facet,sep="\r"))) {
  ix<-which(paste(d$metric,d$.group,d$.facet,sep="\r")==k);o<-order(d$sample_id[ix],method="radix");d$.x[ix[o]]<-d$.x[ix[o]]+if(length(ix)>1L)seq(-.12,.12,length.out=length(ix)) else 0
 }
 d$.y<-d$value;z$data<-d
 breaks<-seq_along(levels(d$.group));labels<-levels(d$.group)
 if(isTRUE(s$trajectories)&&identical(a$comparison$settings$method,"mixed")&&identical(a$comparison$settings$time_mode,"numeric")&&identical(s$group,a$comparison$settings$time)) {
  d$.x<-as.numeric(as.character(a$metadata[[s$group]][match(d$sample_id,rownames(a$metadata))]))
  breaks<-sort(unique(d$.x[is.finite(d$.x)]));labels<-as.character(breaks)
 }
 p<-ggplot2::ggplot(d,ggplot2::aes(x=.x,y=.y))
 if(isTRUE(s$trajectories)) {
  c<-a$comparison
  if(is.null(c)||!c$settings$method%in%c("paired","mixed")||!c$status%in%c("ready","partial"))stop("Trajectories require an applied verified paired or mixed comparison.")
  required<-if(c$settings$method=="paired")c$settings$group else c$settings$time
  if(s$group!=required)stop("For trajectories, use the verified condition/time column as the x grouping.")
  d$.unit<-a$metadata[[c$settings$unit]][match(d$sample_id,rownames(a$metadata))]
  eligible<-do.call(rbind,lapply(names(c$diagnostics),function(m){f<-c$diagnostics[[m]]$frame;data.frame(metric=rep(m,nrow(f)),sample_id=f$sample_id)}))
  keep<-paste(d$metric,d$sample_id,sep="\r")%in%paste(eligible$metric,eligible$sample_id,sep="\r")
  p<-p+ggplot2::geom_line(data=d[keep,,drop=FALSE],ggplot2::aes(group=.unit),colour="grey65",linewidth=.4,na.rm=TRUE)
 }
 p<-p+ggplot2::geom_point(ggplot2::aes(colour=.colour,fill=.colour,shape=.shape),size=2.8,na.rm=TRUE)+alpha_style_layers(z)+ggplot2::scale_x_continuous(breaks=breaks,labels=labels)+ggplot2::facet_wrap(ggplot2::vars(metric,.facet),scales="free_y")+ggplot2::labs(x=if(nzchar(s$group))s$group else "Sample ID",y="Individual alpha value",title=paste("Alpha diversity \u2014 rank",a$rank),subtitle=a$source_label,caption="Named features only. Shannon in nats; other indices dimensionless except detected taxa. Undefined values retained in data. Shapes 21\u201325: selected colour supplies both fill and outline.")
 attr(p,"alpha_data")<-d;attr(p,"alpha_styles")<-list(colours=z$colours,shapes=z$shapes);p
}
plot_alpha_estimates <- function(project) {
 alpha_current(project);d<-project$alpha$comparison$tests
 if(is.null(d)||!nrow(d))stop("Apply a comparison first.")
 d<-d[d$type=="contrast",,drop=FALSE];d$.label<-paste(d$comparison,"minus",d$reference,ifelse(is.na(d$time),"",paste("at",d$time)))
 s<-alpha_plot_settings(project$alpha$plot_settings)
 # A contrast can inherit its target group's style, but not arbitrary sample metadata.
 group<-project$alpha$comparison$settings$group
 lev<-levels(alpha_levels(project$alpha$metadata[[group]]))
 mapped_colour<-nzchar(s$colour)&&identical(s$colour,group)&&s$colour_type=="categorical"
 mapped_shape<-nzchar(s$shape)&&identical(s$shape,group)
 d$.colour<-factor(if(mapped_colour)d$comparison else rep("Fixed",nrow(d)),levels=if(mapped_colour)lev else "Fixed")
 d$.shape<-factor(if(mapped_shape)d$comparison else rep("Fixed",nrow(d)),levels=if(mapped_shape)lev else "Fixed")
 colours<-setNames(if(mapped_colour)grDevices::hcl.colors(length(lev),s$palette) else s$fixed_colour,levels(d$.colour))
 if(mapped_colour){if(length(setdiff(names(s$colours),lev)))stop("Unknown target-group colour level.");colours[names(s$colours)]<-s$colours}
 available<-unique(c(16,17,15,18,3,7,8,0:25));if(mapped_shape&&length(lev)>length(available))stop("Too many target-group shape levels.")
 shapes<-setNames(if(mapped_shape)available[seq_along(lev)] else s$fixed_shape,levels(d$.shape))
 if(mapped_shape){if(length(setdiff(names(s$shapes),lev)))stop("Unknown target-group shape level.");shapes[names(s$shapes)]<-s$shapes;if(anyDuplicated(shapes))stop("Target groups need distinct shapes.")}
 p<-ggplot2::ggplot(d,ggplot2::aes(x=.label,y=estimate))+ggplot2::geom_hline(yintercept=0,colour="grey60")+ggplot2::geom_errorbar(ggplot2::aes(ymin=lower,ymax=upper,colour=.colour),width=.1,na.rm=TRUE)+ggplot2::geom_point(ggplot2::aes(colour=.colour,fill=.colour,shape=.shape),size=3,na.rm=TRUE)+ggplot2::scale_colour_manual(values=colours,name=paste("Target",group),guide=if(mapped_colour)"legend" else "none")+ggplot2::scale_fill_manual(values=colours,guide="none")+ggplot2::scale_shape_manual(values=shapes,name=paste("Target",group),guide=if(mapped_shape)"legend" else "none")+ggplot2::facet_wrap(ggplot2::vars(metric),scales="free")+ggplot2::theme_bw()+ggplot2::theme(axis.text.x=ggplot2::element_text(angle=35,hjust=1))+ggplot2::labs(x="Saved target minus reference contrast",y="Effect and pointwise 95% CI",caption="Colour/shape map to the target group when that group column is selected; other sample metadata uses fixed estimate styles. Failed contrasts remain in exported data.")
 attr(p,"alpha_styles")<-list(colours=colours,shapes=shapes)
 attr(p,"alpha_data")<-d;p
}
alpha_diagnostic_data <- function(fit,ids,method) {
 d<-data.frame(sample_id=ids,fitted=as.numeric(stats::fitted(fit)),residual=as.numeric(stats::residuals(fit)),stringsAsFactors=FALSE)
 if(method=="lm") {
  d$standardized<-as.numeric(stats::rstandard(fit));d$leverage<-as.numeric(stats::hatvalues(fit));d$cooks_distance<-as.numeric(stats::cooks.distance(fit));d$scale_location<-sqrt(abs(d$standardized));q<-d$standardized
 }else {d$standardized<-NA_real_;d$leverage<-NA_real_;d$cooks_distance<-NA_real_;d$scale_location<-NA_real_;q<-d$residual}
 d$theoretical<-NA_real_;ok<-is.finite(q)
 if(any(ok))d$theoretical[ok]<-stats::qqnorm(q[ok],plot.it=FALSE)$x
 d$reason<-if(method=="lm")ifelse(is.finite(d$standardized)&is.finite(d$leverage)&is.finite(d$cooks_distance),"","Diagnostic quantity undefined (e.g. leverage one or zero residual variance)") else "LM standardized residual, leverage and Cook quantities do not apply to mixed fits"
 d
}
plot_alpha_diagnostics <- function(project,metric,settings=project$alpha$plot_settings) {
 alpha_current(project);a<-project$alpha;diag<-a$comparison$diagnostics[[metric]]
 if(is.null(diag$plot_data))stop("No saved fitted diagnostic data for this metric.")
 # Diagnostics are about the fit cohort, but palette validation uses the full alpha cohort.
 z<-alpha_style_data(a,a$values[a$values$metric==metric,,drop=FALSE],settings)
 idx<-match(diag$plot_data$sample_id,z$data$sample_id);d<-cbind(diag$plot_data,z$data[idx,c(".colour",".shape",".group",".facet"),drop=FALSE]);rownames(d)<-NULL
 lm<-a$comparison$settings$method=="lm"
 definitions<-if(lm)list(residual_fitted=c("fitted","residual"),normal_qq=c("theoretical","standardized"),scale_location=c("fitted","scale_location"),residual_leverage=c("leverage","standardized"),cooks_distance=c("observation","cooks_distance")) else list(conditional_residual_fitted=c("fitted","residual"),conditional_normal_qq=c("theoretical","residual"))
 d$observation<-seq_len(nrow(d));plots<-list()
 for(n in names(definitions)) {
  axes<-definitions[[n]];dd<-d;dd$.x<-dd[[axes[1]]];dd$.y<-dd[[axes[2]]]
  p<-ggplot2::ggplot(dd,ggplot2::aes(x=.x,y=.y))+ggplot2::geom_point(ggplot2::aes(colour=.colour,fill=.colour,shape=.shape),size=2.3,na.rm=TRUE)+alpha_style_layers(z)+ggplot2::labs(x=axes[1],y=axes[2],title=paste(metric,gsub("_"," ",n)),subtitle=if(lm)"Saved LM diagnostics" else "Saved mixed-model conditional diagnostics",caption="Assumption/influence review only; no refit or automatic model validation. Exact sample IDs and undefined reasons in diagnostic data.")
  if(grepl("qq",n)) {
   q<-dd$.y[is.finite(dd$.y)];if(length(q)>1L){y<-stats::quantile(q,c(.25,.75),names=FALSE);x<-stats::qnorm(c(.25,.75));slope<-diff(y)/diff(x);p<-p+ggplot2::geom_abline(intercept=y[1]-slope*x[1],slope=slope,linetype=2,colour="grey50")}
  }else if(n!="scale_location")p<-p+ggplot2::geom_hline(yintercept=0,linetype=2,colour="grey65")
  if(n=="residual_leverage") {
   h<-dd$leverage[is.finite(dd$leverage)&dd$leverage>0&dd$leverage<1]
   if(length(h)) {
    h<-seq(max(min(h)/10,1e-5),min(max(h)*1.1,.999),length.out=150)
    contours<-do.call(rbind,lapply(c(.5,1),function(crit){y<-sqrt(crit*diag$rank*(1-h)/h);data.frame(h=rep(h,2),y=c(y,-y),curve=rep(c(paste(crit,"+"),paste(crit,"-")),each=length(h)))}))
    p<-p+ggplot2::geom_line(data=contours,ggplot2::aes(x=h,y=y,group=curve),inherit.aes=FALSE,linetype=2,colour="grey60")+ggplot2::coord_cartesian(ylim=range(c(-2,2,dd$standardized[is.finite(dd$standardized)])))+ggplot2::labs(caption="Cook reference contours 0.5 and 1 from stats::plot.lm formula. Quantities from public stats methods; undefined cases retained in table.")
   }
  }
  attr(p,"alpha_data")<-dd;plots[[n]]<-p
 }
 plots
}
alpha_write_figure <- function(plot,path,settings) {
 s<-figure_settings(settings);new_export_path(path)
 ggplot2::ggsave(path,plot,device=switch(s$format,png="png",pdf="pdf",svg=svglite::svglite),width=s$width,height=s$height,units=s$units,dpi=s$dpi,limitsize=TRUE)
 invisible(path)
}
alpha_report <- function(project,images=character()) {
 a<-project$alpha
 htmltools::tagList(htmltools::tags$h1("Alpha diversity"),htmltools::tags$p(paste(a$status,a$reason)),htmltools::tags$p(a$normalization),htmltools::tags$pre(paste(capture.output(str(list(settings=a$settings,plot=a$plot_settings,comparison=a$comparison$settings,versions=a$versions))),collapse="\n")),html_table(a$values),htmltools::tags$h2("Comparisons"),htmltools::tags$p(paste(a$comparison$status,a$comparison$reason)),htmltools::tags$p("Design declarations are supplied by the analyst. Diagnostics inform assumption review; they do not certify the model. CI are pointwise; p-values use the saved planned family."),html_table(a$comparison$tests),htmltools::tags$h3("Exclusions"),html_table(a$comparison$exclusions),lapply(names(a$comparison$diagnostics),function(m)htmltools::tagList(htmltools::tags$h3(paste(m,"diagnostic data")),html_table(a$comparison$diagnostics[[m]]$plot_data))),lapply(images,function(n)htmltools::tagList(htmltools::tags$h3(n),htmltools::tags$img(src=n,alt=n,style="max-width:100%"))))
}
export_alpha <- function(project,directory) {
 check_project(project);alpha_current(project);new_export_path(directory)
 if(!dir.create(directory))stop("Could not create alpha output directory.")
 dir.create(file.path(directory,"inputs"))
 for(n in names(project$input$sources))writeBin(project$input$sources[[n]]$bytes,file.path(directory,"inputs",paste0(n,if(n=="metadata")".txt" else ".tsv")))
 save_project(project,file.path(directory,"project.rds"));a<-project$alpha
 write<-function(d,n)if(!is.null(d))utils::write.table(d,file.path(directory,paste0(n,".tsv")),sep="\t",quote=TRUE,row.names=FALSE,na="NA")
 write(a$values,"alpha-values");write(a$mass,"mass");write(a$comparison$tests,"comparisons");write(a$comparison$exclusions,"exclusions")
 saveRDS(a,file.path(directory,"alpha.rds"));plots<-list(observations=plot_alpha(project))
 if(!is.null(a$comparison)&&nrow(a$comparison$tests))plots$estimates<-plot_alpha_estimates(project)
 for(m in names(a$comparison$diagnostics)) {
  d<-a$comparison$diagnostics[[m]];write(d$frame,paste0(m,"-model-frame"));write(d$plot_data,paste0(m,"-diagnostics"))
  if(!is.null(d$plot_data)){pp<-plot_alpha_diagnostics(project,m);names(pp)<-paste(m,names(pp),sep="-");plots<-c(plots,pp)}
 }
 images<-character();s<-alpha_plot_settings(a$plot_settings)$figure
 for(n in names(plots)) {
  write(attr(plots[[n]],"alpha_data"),paste0(n,"-plot-data"))
  alpha_write_figure(plots[[n]],file.path(directory,paste0(n,".",s$format)),s)
  preview<-paste0(n,if(s$format=="png")".png" else "-preview.png")
  if(s$format!="png")alpha_write_figure(plots[[n]],file.path(directory,preview),modifyList(s,list(format="png")))
  images<-c(images,preview)
 }
 htmltools::save_html(htmltools::tags$html(htmltools::tags$head(htmltools::tags$meta(charset="utf-8"),htmltools::tags$style("body{font:15px system-ui;margin:32px}table{border-collapse:collapse;font-size:12px}td,th{border:1px solid #ccc;padding:5px}pre{white-space:pre-wrap}")),htmltools::tags$body(alpha_report(project,images))),file.path(directory,"alpha.html"))
 libs<-normalizePath(.libPaths(),winslash="/",mustWork=FALSE)
 writeLines(c("# Prefer the active installed engine; recorded libraries are fallback only.",paste0("if (!requireNamespace('microbiomeengine', quietly=TRUE)) .libPaths(c(",paste(deparse(libs),collapse=""),", .libPaths()))"),"args<-commandArgs(TRUE)","if(length(args)!=2L)stop('Supply bundle and new output')","microbiomeengine::replay_alpha(args[1],args[2])"),file.path(directory,"replay.R"))
 writeLines(capture.output(sessionInfo()),file.path(directory,"session.txt"));writeLines("Alpha export complete; replay is a separate verification.",file.path(directory,"COMPLETE"));invisible(directory)
}
alpha_recalculate <- function(saved,p) {
 a<-saved$alpha;if(is.null(a))return(p)
 p<-apply_alpha(p,a$settings,a$plot_settings,if(is.null(a$comparison))NULL else a$comparison$settings)
 b<-p$alpha
 for(n in c("status","settings","fingerprint","metadata","values","mass","versions","plot_settings"))if(!isTRUE(all.equal(a[[n]],b[[n]],tolerance=1e-10)))stop("Alpha replay differs: ",n)
 for(n in c("status","settings","tests","exclusions","versions"))if(!isTRUE(all.equal(a$comparison[[n]],b$comparison[[n]],tolerance=1e-8)))stop("Comparison replay differs: ",n)
 for(m in names(a$comparison$diagnostics))for(n in c("frame","plot_data","plot_method","reference_grid","contrast_weights","coefficients"))if(!isTRUE(all.equal(a$comparison$diagnostics[[m]][[n]],b$comparison$diagnostics[[m]][[n]],tolerance=1e-8)))stop("Diagnostic replay differs: ",m,"/",n)
 p
}
replay_alpha <- function(bundle,output) {
 if(!file.exists(file.path(bundle,"COMPLETE")))stop("Incomplete alpha bundle.")
 saved<-open_project(file.path(bundle,"project.rds"));alpha_current(saved)
 x<-import_metaphlan(if("abundance"%in%names(saved$input$sources))file.path(bundle,"inputs","abundance.tsv") else NULL,file.path(bundle,"inputs","metadata.txt"),saved$input$sample_id,estimates=if("estimates"%in%names(saved$input$sources))file.path(bundle,"inputs","estimates.tsv") else NULL)
 for(n in names(x$sources))if(!identical(x$sources[[n]]$sha256,saved$input$sources[[n]]$sha256))stop("Alpha bundle input hash mismatch: ",n)
 p<-prepare_project(x,saved$declarations,saved$design,saved$settings,saved$preparation$settings)
 p<-alpha_recalculate(saved,p);export_alpha(p,output);writeLines("Alpha, comparisons, diagnostic quantities and styles agree with recomputation.",file.path(output,"VERIFIED"));invisible(p)
}
utils::globalVariables(c(".x",".y",".group",".facet",".colour",".shape",".unit",".label","metric","estimate","lower","upper","h","y","curve"))





