args<-commandArgs(TRUE)
if(length(args)>1L).libPaths(c(normalizePath(args[2],winslash="/"),file.path(normalizePath(args[1],winslash="/"),".library"),.libPaths()))
library(microbiomeengine)
eq<-function(x,y,tol=1e-9)stopifnot(isTRUE(all.equal(x,y,tolerance=tol,check.attributes=FALSE)))
fails<-function(expr)stopifnot(inherits(try(force(expr),silent=TRUE),"try-error"))
p<-example_project();before<-serialize(p,NULL)
a<-calculate_alpha(p,list(metrics=c("detected","shannon","gini_simpson","inverse_simpson","pielou")))
stopifnot(a$status=="ready",nrow(a$values)==20L,identical(before,serialize(p,NULL)))
m<-SummarizedExperiment::assay(p$experiment,"relative");q<-sweep(m,2,colSums(m),"/")
expected<-list(detected=colSums(m>0),shannon=-colSums(q*log(q)),gini_simpson=1-colSums(q*q),inverse_simpson=1/colSums(q*q),pielou=-colSums(q*log(q))/log(2))
for(n in names(expected))eq(a$values$value[a$values$metric==n],expected[[n]])
eq(a$values$value[a$values$metric=="shannon"],vegan::diversity(t(m)))
z<-p;SummarizedExperiment::assay(z$experiment,"relative")[,1]<-0;SummarizedExperiment::assay(z$experiment,"relative")[,2]<-c(.4,0)
b<-calculate_alpha(z,list(metrics=names(expected)));stopifnot(b$status=="partial",all(is.na(b$values$value[b$values$sample_id=="S1"])),is.na(b$values$value[b$values$sample_id=="S2"&b$values$metric=="pielou"]))
for(v in c(-1,Inf,NaN)){z<-p;SummarizedExperiment::assay(z$experiment,"relative")[1,1]<-v;stopifnot(calculate_alpha(z)$status=="blocked")}
stopifnot(calculate_alpha(p,list(metrics="chao1"))$status=="blocked",calculate_alpha(p,list(source="estimated_reads"))$status=="blocked")
p<-apply_alpha(p);display<-p;display$settings$top_n<-1L;stopifnot(identical(calculate_alpha(p),calculate_alpha(display)))
p2<-apply_preparation(p,list(samples=list(enabled=TRUE,ids=c("S1","S2"))));stopifnot(p2$alpha$status=="stale");fails(plot_alpha(p2))
cat("PASS metric hand values, vegan reference, invalid/zero/singleton and immutable/display/stale invariants\n")
# Inference fixture: specified numeric outcomes, independent of an alpha-generating distribution.
make_alpha<-function(y,g,unit,visit=NULL,cov=NULL){ids<-paste0("id / ",seq_along(y));meta<-data.frame(sample_id=ids,group=g,unit=unit,row.names=ids,stringsAsFactors=FALSE);if(!is.null(visit))meta$visit<-visit;if(!is.null(cov))meta$age<-cov;list(status="ready",settings=list(metrics="shannon"),fingerprint="synthetic-method-reference",metadata=meta,values=data.frame(sample_id=ids,metric="shannon",value=y,status="ready",reason=""))}
s<-list(group="group",unit="unit",reference="A",verified=TRUE,evidence="Synthetic design fixture: explicitly independent generated units",assignment="independent_units",adjust="holm")
y<-c(1,2,4,5,2,4,7,9);g<-rep(c("A","B"),each=4);a<-make_alpha(y,g,paste0("u",1:8))
c<-compare_alpha(a,s);stopifnot(c$status=="ready");delta<-mean(y[5:8])-mean(y[1:4]);se<-sqrt(var(y[1:4])/4+var(y[5:8])/4);df<-(var(y[1:4])/4+var(y[5:8])/4)^2/((var(y[1:4])/4)^2/3+(var(y[5:8])/4)^2/3)
eq(c$tests$estimate,delta);eq(c$tests$SE,se);eq(c$tests$df2,df);eq(c$tests$p_raw,2*pt(-abs(delta/se),df));eq(c$tests$lower,delta-qt(.975,df)*se)
c2<-compare_alpha(a,modifyList(s,list(method="student")));eq(c2$tests$p_raw,t.test(y[5:8],y[1:4],var.equal=TRUE)$p.value)
a$metadata$unit<-rep(paste0("u",1:4),2);stopifnot(compare_alpha(a,s)$status=="blocked")
ps<-modifyList(s,list(method="paired",assignment="independent_subjects"));c<-compare_alpha(a,ps);stopifnot(c$status=="ready");dif<-y[5:8]-y[1:4];eq(c$tests$SE,sd(dif)/sqrt(4));eq(c$tests$p_raw,t.test(dif)$p.value)
a$values$value[1]<-NA;c<-compare_alpha(a,ps);stopifnot(c$tests$n_units==3L,nrow(c$exclusions)==2L)
stopifnot(compare_alpha(a,modifyList(ps,list(verified=FALSE)))$status=="blocked")
cat("PASS manual Welch, Student reference, paired differences, incomplete pairs and design blocks\n")
set.seed(3501);n<-36;g<-rep(c("A","B","C"),each=12);age<-rnorm(n);y<-2+.3*(g=="B")-.2*(g=="C")+.15*age+rnorm(n,sd=.2);a<-make_alpha(y,g,paste0("u",1:n),cov=age)
ls<-modifyList(s,list(method="lm",covariates="age"));c<-compare_alpha(a,ls);stopifnot(c$status=="ready",nrow(c$tests)==3L)
d<-data.frame(value=y,group=factor(g),cov1=age);fit<-lm(value~group+cov1,d);reduced<-lm(value~cov1,d)
eq(c$tests$p_raw[1],anova(reduced,fit)$`Pr(>F)`[2]);eq(c$tests$estimate[2:3],coef(fit)[2:3]);eq(c$tests$p_adjusted,p.adjust(c$tests$p_raw,"holm"))
dg<-c$diagnostics$shannon;eq(dg$plot_data$standardized,rstandard(fit));eq(dg$plot_data$leverage,hatvalues(fit));eq(dg$plot_data$cooks_distance,cooks.distance(fit));stopifnot(identical(dg$plot_data$sample_id,rownames(a$metadata)))
a$metadata$alias<-as.numeric(a$metadata$group=="B");bad<-compare_alpha(a,modifyList(ls,list(covariates=c("age","alias"))));stopifnot(bad$status=="blocked",all(is.na(bad$tests$p_raw)))
a$metadata$age[1]<-NA;c<-compare_alpha(a,ls);stopifnot(c$status=="ready",nrow(c$exclusions)==1L,c$tests$n_samples[1]==35L)
a$settings$metrics<-c("shannon","pielou");v<-a$values;v$metric<-"pielou";v$value<-NA;v$status<-"undefined";a$values<-rbind(a$values,v);c<-compare_alpha(a,ls);stopifnot(c$status=="partial",all(c$tests$planned==6L));eq(c$tests$p_adjusted[1:3],p.adjust(c$tests$p_raw[1:3],"holm",n=6))
cat("PASS LM conditional F, reference contrasts, saved public diagnostics, alias/missingness and planned multiplicity\n")
set.seed(3502);u<-rep(paste0("U",1:20),each=3);g<-rep(rep(c("A","B"),each=10),each=3);t<-rep(0:2,20);y<-3+rep(rnorm(20,sd=.5),each=3)+.2*(g=="B")+.1*t+.12*(g=="B")*t+rnorm(60,sd=.12)
a<-make_alpha(y,g,u,visit=as.character(t));ms<-modifyList(s,list(method="mixed",assignment="independent_subjects",time="visit",time_mode="factor"));c<-compare_alpha(a,ms);if(c$status!="ready")print(c$tests);stopifnot(c$status=="ready",nrow(c$tests)==4L)
d<-data.frame(value=y,group=factor(g),time=factor(t),unit=u);fit<-lmerTest::lmer(value~group*time+(1|unit),d,REML=TRUE);tab<-anova(fit,type="III",ddf="Satterthwaite");eq(c$tests$p_raw[1],tab["group:time","Pr(>F)"])
em<-emmeans::emmeans(fit,~group|time,lmer.df="satterthwaite",disable.pbkrtest=TRUE);ct<-as.data.frame(summary(emmeans::contrast(em,list("B"=c(-1,1)),adjust="none"),infer=c(TRUE,TRUE),adjust="none"));eq(c$tests$estimate[-1],ct$estimate);eq(c$tests$df2[-1],ct$df);eq(c$tests$p_raw[-1],ct$p.value)
b<-a;b$metadata$visit[2]<-b$metadata$visit[1];stopifnot(compare_alpha(b,ms)$status=="blocked");b<-a;b$metadata$group[2]<-"B";stopifnot(compare_alpha(b,ms)$status=="blocked")
cnum<-compare_alpha(a,modifyList(ms,list(time_mode="numeric",at_time=1)));stopifnot(cnum$status=="ready")
b<-a;b$metadata$visit[1]<-NA;cmissing<-compare_alpha(b,ms);stopifnot(cmissing$status=="ready",nrow(cmissing$exclusions)==1L)
b<-a;b$values$value<-3+.2*(g=="B")+.1*t+rep(c(-.1,.2,-.1),20);csing<-compare_alpha(b,ms);stopifnot(csing$status=="blocked",any(grepl("Singular|convergence|warnings",csing$tests$reason)))
# Mixed quantities are explicitly conditional, with no invented LM leverage.
stopifnot(all(is.na(c$diagnostics$shannon$plot_data$leverage)),grepl("Conditional",c$diagnostics$shannon$plot_method$method))
cat("PASS mixed public fit/EMM/Satterthwaite reference, categorical/numeric time, duplicate and crossover blocks\n")
# A real imported synthetic project exercises public save/export/recompute, not substituted outcomes.
work<-tempfile("alpha-validation-",tmpdir=if(length(args))file.path(normalizePath(args[1]),".artifacts") else tempdir());dir.create(work)
ids<-paste0("Sample / ",1:36);set.seed(3503);meta<-data.frame(sample_id=ids,group=rep(c("A","B","C"),each=12),unit=paste0("unit",1:36),age=round(rnorm(36,40,7),3),colour=rep(c("red","<Missing>",""),12),shape=rep(c("one","two"),18),visit=rep(c("v1","v2"),18))
weights<-rbind(runif(36,.1,.6),runif(36,.05,.3),runif(36,.05,.2));weights<-sweep(weights,2,colSums(weights),"/")*90
ab<-data.frame(clade_name=c("UNCLASSIFIED","k__Bacteria|s__a","k__Bacteria|s__b","k__Bacteria|s__c"),rbind(rep(10,36),weights),check.names=FALSE);names(ab)[-1]<-ids
utils::write.table(ab,file.path(work,"ab.tsv"),sep="\t",row.names=FALSE,quote=FALSE);utils::write.csv(meta,file.path(work,"meta.csv"),row.names=FALSE)
x<-import_metaphlan(file.path(work,"ab.tsv"),file.path(work,"meta.csv"));p<-prepare_project(x,list(rank="s",scale="percentage",denominator_kind="including_unclassified",coverage="complete",pipeline="Synthetic alpha validation",database="synthetic"))
p<-apply_alpha(p,list(metrics="shannon"),comparison=ls);stopifnot(p$alpha$comparison$status=="ready")
fit_before<-serialize(p$alpha$comparison,NULL);values_before<-p$alpha$values
style<-list(group="group",facet="visit",colour="colour",shape="shape",colours=c(red="#AA0033","<Missing>"="#147D80","<Missing>*"="#666666"),shapes=c(one=16L,two=17L))
p$alpha$plot_settings<-microbiomeengine:::alpha_plot_settings(style);pl<-plot_alpha(p);pd<-attr(pl,"alpha_data");stopifnot(nrow(pd)==36L,identical(pd$sample_id,p$alpha$values$sample_id),length(levels(pd$.colour))==3L,length(unique(pd$.shape))==2L);invisible(ggplot2::ggplot_build(pl))
stopifnot(identical(fit_before,serialize(p$alpha$comparison,NULL)),identical(values_before,p$alpha$values))
fails(plot_alpha(p,modifyList(style,list(fixed_shape=26))));fails(plot_alpha(p,modifyList(style,list(fixed_colour="not-a-colour"))));fails(plot_alpha(p,modifyList(style,list(shapes=c(one=16,two=16)))))
cont<-plot_alpha(p,modifyList(style,list(colour="age",colour_type="continuous",colours=character())));stopifnot(is.numeric(attr(cont,"alpha_data")$.colour))
plots<-plot_alpha_diagnostics(p,"shannon");stopifnot(length(plots)==5L);for(pp in plots){stopifnot(identical(attr(pp,"alpha_data")$sample_id,p$alpha$comparison$diagnostics$shannon$frame$sample_id));invisible(ggplot2::ggplot_build(pp))}
estyle<-p;estyle$alpha$plot_settings<-microbiomeengine:::alpha_plot_settings(list(colour="group",shape="group",colours=c(A="#AA0000",B="#00AA00",C="#0000AA"),shapes=c(A=16L,B=17L,C=15L)))
eplot<-plot_alpha_estimates(estyle);stopifnot(identical(as.character(attr(eplot,"alpha_data")$.colour),c("B","C")),isTRUE(all.equal(unname(attr(eplot,"alpha_styles")$shapes[c("B","C")]),c(17,15))));invisible(ggplot2::ggplot_build(eplot));stopifnot(identical(p$alpha$comparison,estyle$alpha$comparison))
save_project(p,file.path(work,"saved.rds"));stopifnot(identical(p$alpha,open_project(file.path(work,"saved.rds"))$alpha))
bundle<-file.path(work,"alpha");export_alpha(p,bundle);stopifnot(file.exists(file.path(bundle,"COMPLETE")),length(list.files(bundle,pattern="^shannon-.*png$"))==5L)
fails(export_alpha(p,bundle));fresh<-system2(file.path(R.home("bin"),"Rscript.exe"),c("--vanilla",shQuote(file.path(bundle,"replay.R")),shQuote(bundle),shQuote(file.path(work,"replay"))),stdout=TRUE,stderr=TRUE);if(!is.null(attr(fresh,"status")))stop(paste(fresh,collapse="\n"));stopifnot(file.exists(file.path(work,"replay","VERIFIED")))
blocked<-p;blocked$alpha$comparison<-compare_alpha(p$alpha,modifyList(ls,list(verified=FALSE)));export_alpha(blocked,file.path(work,"blocked"));replay_alpha(file.path(work,"blocked"),file.path(work,"blocked-replay"))
export_project(p,file.path(work,"project"));replay_project(file.path(work,"project"),file.path(work,"project-replay"))
# PNG/PDF/SVG figure settings actually render.
for(fmt in c("pdf",if(requireNamespace("svglite",quietly=TRUE))"svg"))microbiomeengine:::alpha_write_figure(pl,file.path(work,paste0("style.",fmt)),list(format=fmt))
if(nzchar(Sys.getenv("ALPHA_EVIDENCE"))){dir.create(Sys.getenv("ALPHA_EVIDENCE"),showWarnings=FALSE);saveRDS(p,file.path(Sys.getenv("ALPHA_EVIDENCE"),"review-project.rds"));writeLines(work,file.path(Sys.getenv("ALPHA_EVIDENCE"),"test-output-path.txt"))}
cat("PASS independent/manual/missing styles, diagnostic identity, figures, saved model invariance, exports and fresh replay\nOUTPUT",work,"\n")

# Analytical feature count is independent of Composition's display guard.
small<-example_project();large<-matrix(90/601,601,4,dimnames=list(paste0('k__Bacteria|s__named_',1:601),small$input$sample_ids))
largefile<-file.path(work,'large.tsv');utils::write.table(data.frame(clade_name=c('UNCLASSIFIED',rownames(large)),rbind(rep(10,4),large),check.names=FALSE),largefile,sep='\t',quote=FALSE,row.names=FALSE)
largeinput<-import_metaphlan(largefile,small$input$sources$metadata$path)
largeproject<-prepare_project(largeinput,small$declarations,small$design)
largeproject<-apply_alpha(largeproject);stopifnot(largeproject$alpha$status=='ready',length(largeproject$alpha$features)==601L,all(largeproject$alpha$values$value[largeproject$alpha$values$metric=='detected']==601))
export_alpha(largeproject,file.path(work,'large-alpha'))
# Estimated measurements use their own named-feature totals and remain labelled estimates.
e<-small$input$values*10;ef<-file.path(work,'estimated.tsv');utils::write.table(data.frame(clade_name=rownames(e),e,check.names=FALSE),ef,sep='\t',quote=FALSE,row.names=FALSE)
ei<-import_metaphlan(NULL,small$input$sources$metadata$path,estimates=ef)
ep<-prepare_project(ei,modifyList(small$declarations,list(estimate_unit='estimated_reads',estimate_normalization=TRUE)),small$design)
ea<-calculate_alpha(ep,list(source='estimated_reads'));er<-calculate_alpha(ep)
stopifnot(ea$status=='ready',grepl('not observed counts',ea$source_label));eq(ea$values$value,er$values$value)
# Real HMP profile remains descriptive unless independent-unit evidence is supplied.
if(length(args)) {
 pilotpath<-file.path(normalizePath(args[1]),'.artifacts','pilot-030-final','project.rds')
 if(file.exists(pilotpath)){hp<-open_project(pilotpath);ha<-calculate_alpha(hp);stopifnot(ha$status%in%c('ready','partial'));hc<-compare_alpha(ha);stopifnot(hc$status=='blocked');cat('PASS original HMP pilot alpha calculation with inference blocked\n')}
}
cat('PASS >500 named features and standalone export; estimate-only semantics and equivalent named normalization\n')

# A real imported repeated-subject fixture validates mixed save/export/fresh replay and trajectories.
set.seed(3504);subjects<-rep(paste0('Subject ',1:20),each=3);visits<-rep(c('0','2','10'),20);groups<-rep(rep(c('A','B'),each=10),each=3)
prop<-.25+rep(rnorm(20,0,.045),each=3)+.012*as.numeric(visits)+.035*(groups=='B')+rnorm(60,0,.008)
wm<-rbind(prop,(1-prop)*.6,(1-prop)*.4)*90; mids<-paste0('Repeated / ',1:60)
mm<-data.frame(sample_id=mids,group=groups,unit=subjects,visit=visits)
abm<-data.frame(clade_name=c('UNCLASSIFIED','k__Bacteria|s__a','k__Bacteria|s__b','k__Bacteria|s__c'),rbind(rep(10,60),wm),check.names=FALSE);names(abm)[-1]<-mids
utils::write.table(abm,file.path(work,'mixed.tsv'),sep='\t',quote=FALSE,row.names=FALSE);utils::write.csv(mm,file.path(work,'mixed-meta.csv'),row.names=FALSE)
mp<-prepare_project(import_metaphlan(file.path(work,'mixed.tsv'),file.path(work,'mixed-meta.csv')),list(rank='s',scale='percentage',denominator_kind='including_unclassified',coverage='complete'))
mp<-apply_alpha(mp,list(metrics='shannon'),list(group='visit',colour='group',shape='group',trajectories=TRUE),modifyList(ms,list(time_mode='numeric',at_time=2)))
stopifnot(mp$alpha$comparison$status=='ready');mplot<-plot_alpha(mp);eq(attr(mplot,'alpha_data')$.x,as.numeric(visits));invisible(ggplot2::ggplot_build(mplot));stopifnot(length(plot_alpha_diagnostics(mp,'shannon'))==2L)
export_alpha(mp,file.path(work,'mixed-alpha'));fresh<-system2(file.path(R.home('bin'),'Rscript.exe'),c('--vanilla',shQuote(file.path(work,'mixed-alpha','replay.R')),shQuote(file.path(work,'mixed-alpha')),shQuote(file.path(work,'mixed-replay'))),stdout=TRUE,stderr=TRUE)
if(!is.null(attr(fresh,'status')))stop(paste(fresh,collapse='\n'));stopifnot(file.exists(file.path(work,'mixed-replay','VERIFIED')))
cat('PASS real imported mixed-model trajectory/conditional diagnostic export and fresh replay\n')

# Reconstruction must use preserved input bytes, not merely the serialized parsed input.
badbundle<-file.path(work,'tampered-alpha');export_alpha(p,badbundle)
cat('\n# changed bytes\n',file=file.path(badbundle,'inputs','abundance.tsv'),append=TRUE)
fails(replay_alpha(badbundle,file.path(work,'tampered-replay')))
cat('PASS alpha replay reparses original inputs and rejects changed input bytes\n')


