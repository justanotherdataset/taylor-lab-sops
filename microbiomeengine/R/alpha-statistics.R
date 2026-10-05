alpha_comparison_settings <- function(settings=list()) {
 defaults<-list(method="welch",group="",reference="",unit="",verified=FALSE,evidence="",assignment="independent_units",time="",time_mode="factor",at_time=0,covariates=character(),adjust="holm",family="alpha-request",conf_level=.95)
 if(!is.list(settings)||length(setdiff(names(settings),names(defaults))))stop("Unknown comparison setting.")
 s<-modifyList(defaults,settings)
 for(n in c("method","group","reference","unit","evidence","assignment","time","time_mode","adjust","family"))if(!is.character(s[[n]])||length(s[[n]])!=1L||is.na(s[[n]]))stop("Comparison fields must be single nonmissing strings.")
 if(!nzchar(trimws(s$family)))stop("Name the planned multiplicity family.")
 if(length(s$method)!=1L||!s$method%in%c("welch","student","paired","lm","mixed"))stop("Unsupported alpha comparison design.")
 if(length(s$adjust)!=1L||!s$adjust%in%c("holm","BH","none"))stop("Choose Holm, BH or no adjustment explicitly.")
 if(!identical(s$conf_level,.95))stop("This bounded route uses pointwise 95% confidence intervals.")
 if(!is.character(s$covariates)||anyNA(s$covariates)||anyDuplicated(s$covariates))stop("Covariates must be unique numeric metadata columns.")
 s
}
alpha_test_row <- function(metric,type,comparison,reference,time=NA_character_) {
 data.frame(metric=metric,type=type,comparison=comparison,reference=reference,time=time,estimate=NA_real_,SE=NA_real_,lower=NA_real_,upper=NA_real_,statistic=NA_real_,df1=NA_real_,df2=NA_real_,p_raw=NA_real_,p_adjusted=NA_real_,n_samples=0L,n_units=0L,status="blocked",reason="",formula="",estimand=if(type=="omnibus")"joint hypothesis" else "target minus reference",effect_scale=if(metric=="shannon")"Shannon difference (nats)" else paste(metric,"difference"),ci_method="pointwise t 95%",df_method="",stringsAsFactors=FALSE)
}
alpha_model_frame <- function(a,s) {
 meta<-a$metadata
 if(is.null(meta)||anyDuplicated(rownames(meta)))stop("No aligned alpha metadata.")
 roles<-c(s$group,s$unit,if(s$method=="mixed")s$time,s$covariates)
 if(any(!nzchar(roles))||any(!roles%in%names(meta)))stop("Select existing group, unit and required time/covariate columns.")
 if(anyDuplicated(roles))stop("Group, unit, time and covariate roles must use distinct columns.")
 if(!isTRUE(s$verified)||!is.character(s$evidence)||length(s$evidence)!=1L||!nzchar(trimws(s$evidence)))stop("Inference blocked: explicitly verify experimental units/assignment and record supporting design evidence. Column selection alone is insufficient.")
 expected<-if(s$method%in%c("paired","mixed"))"independent_subjects" else "independent_units"
 if(!identical(s$assignment,expected))stop("Unsupported clustered/unknown assignment. Independent units or independent subjects must match the selected method.")
 d<-data.frame(sample_id=rownames(meta),group=as.character(meta[[s$group]]),unit=as.character(meta[[s$unit]]),stringsAsFactors=FALSE)
 missing<-function(x)is.na(x)|!nzchar(trimws(as.character(x)))
 d$exclude<-""
 add_reason<-function(idx,reason){d$exclude[idx]<<-ifelse(nzchar(d$exclude[idx]),paste(d$exclude[idx],reason,sep="; "),reason)}
 add_reason(missing(d$group),"missing group");add_reason(missing(d$unit),"missing unit")
 if(!s$reference%in%d$group)stop("Reference must be an exact observed group value.")
 levels<-c(s$reference,sort(setdiff(unique(d$group[!missing(d$group)]),s$reference),method="radix"))
 if(length(levels)<2L)stop("At least two groups are required.")
 if(s$method%in%c("welch","student","paired")&&length(levels)!=2L)stop("The selected two-group test requires exactly two groups.")
 d$group<-factor(d$group,levels=levels)
 for(i in seq_along(s$covariates)) {
  v<-meta[[s$covariates[i]]];num<-suppressWarnings(as.numeric(as.character(v)))
  if(any(!missing(v)&!is.finite(num)))stop("Covariate must contain finite numeric values or explicit missing values: ",s$covariates[i])
  d[[paste0("cov",i)]]<-num;add_reason(missing(v),paste("missing covariate",s$covariates[i]))
 }
 if(s$method%in%c("welch","student","paired")&&length(s$covariates))stop("Use linear or mixed models for covariate adjustment.")
 if(s$method=="mixed") {
  if(!s$time_mode%in%c("factor","numeric"))stop("Choose categorical visits or numeric time explicitly.")
  v<-as.character(meta[[s$time]]);add_reason(missing(v),"missing time")
  if(s$time_mode=="numeric") {
   d$time<-suppressWarnings(as.numeric(v));if(any(!missing(v)&!is.finite(d$time)))stop("Numeric time contains unusable values.")
   if(length(s$at_time)!=1L||!is.numeric(s$at_time)||!is.finite(s$at_time)||s$at_time<min(d$time,na.rm=TRUE)||s$at_time>max(d$time,na.rm=TRUE))stop("Choose a finite comparison time inside observed time support.")
  }else d$time<-factor(v,levels=sort(unique(v[!missing(v)]),method="radix"))
 }
 # Structural replication is checked before metric/missing-value exclusions.
 known<-!missing(d$unit)&!is.na(d$group)
 if(s$method%in%c("welch","student","lm")&&anyDuplicated(d$unit[known]))stop("Repeated experimental units cannot be treated as independent observations.")
 if(s$method=="paired"&&anyDuplicated(d[known,c("unit","group")]))stop("Duplicate pair/group observations; no automatic averaging.")
 if(s$method=="mixed") {
  if(any(vapply(split(as.character(d$group[known]),d$unit[known]),function(v)length(unique(v))>1L,logical(1))))stop("This mixed route requires group fixed within subject; crossover designs unsupported.")
  if(anyDuplicated(d[known&!is.na(d$time),c("unit","time")]))stop("Duplicate subject/time observations; no automatic averaging.")
 }
 d
}
compare_alpha <- function(alpha,settings=list()) {
 s<-tryCatch(alpha_comparison_settings(settings),error=function(e)e)
 if(inherits(s,"error"))return(list(status="blocked",reason=conditionMessage(s),settings=settings,tests=data.frame(),exclusions=data.frame(),diagnostics=list()))
 out<-list(status="blocked",reason="",settings=s,tests=data.frame(),exclusions=data.frame(),diagnostics=list(),fingerprint=preparation_fingerprint(list(alpha$fingerprint,alpha$metadata,s)))
 metrics<-alpha$settings$metrics
 if(!length(metrics))metrics<-"requested_alpha"
 meta<-alpha$metadata;groups<-if(!is.null(meta)&&s$group%in%names(meta))sort(unique(as.character(meta[[s$group]])),method="radix") else character()
 groups<-groups[!is.na(groups)&nzchar(trimws(groups))];targets<-setdiff(groups,s$reference);if(!length(targets))targets<-"requested comparison"
 times<-NA_character_
 if(s$method=="mixed"&&!is.null(meta)&&s$time%in%names(meta))times<-if(s$time_mode=="numeric")as.character(s$at_time) else sort(unique(as.character(meta[[s$time]])),method="radix")
 times<-if(s$method=="mixed")times[!is.na(times)&nzchar(trimws(times))] else times;if(!length(times))times<-NA_character_
 rows<-lapply(metrics,function(metric){
  r<-do.call(rbind,lapply(times,function(tm)do.call(rbind,lapply(targets,function(g)alpha_test_row(metric,"contrast",g,s$reference,tm)))))
  if(s$method%in%c("lm","mixed"))r<-rbind(alpha_test_row(metric,"omnibus",if(s$method=="lm")"group conditional on covariates" else "group:time interaction",s$reference),r)
  r
 });out$tests<-do.call(rbind,rows)
 fatal<-function(message){out$reason<-message;out$tests$reason<-message;out$tests$family<-s$family;out$tests$adjustment<-s$adjust;out$tests$planned<-nrow(out$tests);out$tests$tested<-0L;out}
 if(!alpha$status%in%c("ready","partial"))return(fatal("Current metric-ready alpha result required."))
 frame<-tryCatch(alpha_model_frame(alpha,s),error=function(e)e)
 if(inherits(frame,"error"))return(fatal(conditionMessage(frame)))
 results<-list();excluded<-list()
 for(metric in metrics) {
  ix<-which(out$tests$metric==metric);r<-out$tests[ix,,drop=FALSE];d<-frame
  v<-alpha$values[alpha$values$metric==metric,,drop=FALSE];i<-match(d$sample_id,v$sample_id)
  if(anyNA(i)||anyDuplicated(v$sample_id)){r$reason<-"Metric/sample identity mismatch";results[[metric]]<-r;next}
  d$value<-v$value[i];bad<-!is.finite(d$value)|v$status[i]!="ready"
  d$exclude[bad]<-paste(d$exclude[bad],"undefined metric",v$reason[i][bad]);d$exclude<-trimws(d$exclude)
  if(s$method=="paired") {
   counts<-table(d$unit[d$exclude==""],d$group[d$exclude==""])
   complete<-rownames(counts)[rowSums(counts==1L)==2L]
   lost<-!d$unit%in%complete;d$exclude[lost]<-trimws(paste(d$exclude[lost],"incomplete pair"))
  }
  excluded[[metric]]<-data.frame(metric=rep(metric,sum(d$exclude!="")),d[d$exclude!="",c("sample_id","unit","exclude"),drop=FALSE],row.names=NULL)
  d<-d[d$exclude=="",,drop=FALSE];rownames(d)<-d$sample_id
  r$n_samples<-nrow(d);r$n_units<-length(unique(d$unit))
  warnings<-character();diagnostic<-list(frame=d,settings=s)
  result<-tryCatch(withCallingHandlers({
   if(any(table(d$group)<2L))stop("Fewer than two usable observations in a requested group.")
   if(s$method%in%c("welch","student","paired")) {
    ref<-d[d$group==s$reference,,drop=FALSE];target<-d[d$group==targets[1],,drop=FALSE]
    if(s$method=="paired")target<-target[match(ref$unit,target$unit),,drop=FALSE]
    if(s$method=="paired"&&(!identical(ref$unit,target$unit)||anyNA(target$unit)))stop("Pair identity mismatch.")
    fit<-stats::t.test(target$value,ref$value,paired=s$method=="paired",var.equal=s$method=="student",alternative="two.sided",conf.level=.95)
    r$estimate<-mean(target$value)-mean(ref$value);r$SE<-fit$stderr;r$lower<-fit$conf.int[1];r$upper<-fit$conf.int[2];r$statistic<-unname(fit$statistic);r$df2<-unname(fit$parameter);r$p_raw<-fit$p.value
    r$formula<-if(s$method=="paired")"within-unit target - reference" else "value ~ group";r$df_method<-fit$method
    diagnostic$observations<-d;diagnostic$differences<-if(s$method=="paired")data.frame(unit=ref$unit,difference=target$value-ref$value) else NULL
   } else {
    covs<-if(length(s$covariates))paste0("cov",seq_along(s$covariates)) else character();fixed<-paste(c(if(s$method=="mixed")"group * time" else "group",covs),collapse=" + ")
    f<-stats::as.formula(paste("value ~",fixed),env=baseenv());X<-stats::model.matrix(f,d)
    r$formula<-paste("value ~",fixed,if(s$method=="mixed")"+ (1 | unit)" else "")
    if(qr(X)$rank<ncol(X)||nrow(X)<=ncol(X))stop("Fixed-effect design is aliased or has no residual degrees of freedom.")
    if(s$method=="mixed") {
     if(nrow(d)>3000L)stop("Mixed route limited to 3000 observations for explicit Satterthwaite inference.")
     units<-unique(d[,c("unit","group")]);if(nrow(units)<6L||any(table(units$group)<3L))stop("Mixed route requires at least six independent subjects and three per group.")
     if(length(unique(d$time))<2L||sum(table(d$unit)>=2L)<3L)stop("Insufficient within-subject time replication.")
     if(s$time_mode=="numeric"&&any(vapply(split(d$time,d$group),function(t)s$at_time<min(t)||s$at_time>max(t),logical(1))))stop("Comparison time lies outside a group's observed support.")
     fit<-lmerTest::lmer(stats::as.formula(paste("value ~",fixed,"+ (1 | unit)"),env=baseenv()),data=d,REML=TRUE,na.action=stats::na.fail)
     summary_fit<-summary(fit,ddf="Satterthwaite")
     diagnostic$singular<-lme4::isSingular(fit,tol=1e-4);diagnostic$optimizer<-summary_fit$optinfo;diagnostic$fit_messages<-summary_fit$fitMsgs
     diagnostic$variance_components<-as.data.frame(lme4::VarCorr(fit))
     if(diagnostic$singular)stop("Singular random-intercept fit; inference withheld.")
     messages<-unlist(summary_fit$optinfo$conv$lme4$messages)
     if(length(messages)||any(unlist(summary_fit$optinfo$conv$opt)!=0)||length(warnings))stop("Mixed fit has convergence or fitting warnings; inference withheld.")
     if(length(attr(lme4::getME(fit,"X"),"col.dropped")))stop("Mixed fit dropped fixed-effect columns.")
     tab<-stats::anova(fit,type="III",ddf="Satterthwaite");j<-match("group:time",rownames(tab))
     if(is.na(j))stop("Interaction omnibus is unavailable.")
     r$statistic[1]<-tab[j,"F value"];r$df1[1]<-tab[j,"NumDF"];r$df2[1]<-tab[j,"DenDF"];r$p_raw[1]<-tab[j,"Pr(>F)"]
     at<-if(s$time_mode=="numeric")list(time=s$at_time) else list()
     emm<-emmeans::emmeans(fit,~group|time,at=at,weights="equal",lmer.df="satterthwaite",disable.lmerTest=FALSE,disable.pbkrtest=TRUE,lmerTest.limit=3000)
     r$df_method<-"Satterthwaite; omnibus Type III interaction"
    }else{
     fit<-stats::lm(f,data=d,na.action=stats::na.fail,x=TRUE,y=TRUE)
     reduced<-stats::lm(stats::as.formula(paste("value ~",if(length(covs))paste(covs,collapse=" + ") else "1"),env=baseenv()),data=d,na.action=stats::na.fail)
     tab<-stats::anova(reduced,fit,test="F")
     r$statistic[1]<-tab$F[2];r$df1[1]<-tab$Df[2];r$df2[1]<-stats::df.residual(fit);r$p_raw[1]<-tab$`Pr(>F)`[2]
     emm<-emmeans::emmeans(fit,~group,weights="equal");r$df_method<-"LM residual df; same-frame nested F"
    }
    # Public EMM table establishes group order; explicit weights preserve direction.
    grid<-as.data.frame(emm);lev<-levels(d$group);weights<-lapply(targets,function(g){w<-rep(0,length(lev));w[match(g,lev)]<-1;w[match(s$reference,lev)]<--1;w});names(weights)<-targets
    ct<-as.data.frame(summary(emmeans::contrast(emm,method=weights,adjust="none"),infer=c(TRUE,TRUE),level=.95,adjust="none"))
    for(k in which(r$type=="contrast")) {
     hit<-as.character(ct$contrast)==r$comparison[k]
     if(s$method=="mixed")hit<-hit&as.character(ct$time)==r$time[k]
     if(sum(hit)!=1L)stop("Contrast/reference-grid alignment failed.")
     z<-ct[hit,,drop=FALSE];r[k,c("estimate","SE","lower","upper","statistic","df2","p_raw")]<-list(z$estimate,z$SE,z$lower.CL,z$upper.CL,z$t.ratio,z$df,z$p.value)
    }
    r$formula<-paste(deparse(stats::formula(fit)),collapse=" ");r$ci_method[r$type=="omnibus"]<-"not applicable"
    diagnostic$fixed_matrix<-X;diagnostic$rank<-qr(X)$rank;diagnostic$reference_grid<-grid;diagnostic$contrast_weights<-weights
    diagnostic$residuals<-data.frame(sample_id=d$sample_id,fitted=as.numeric(stats::fitted(fit)),residual=as.numeric(stats::residuals(fit)))
    diagnostic$coefficients<-as.data.frame(stats::coef(summary(fit)))
    diagnostic$fit<-fit
    diagnostic$plot_data<-alpha_diagnostic_data(fit,d$sample_id,s$method)
    diagnostic$plot_method<-list(method=if(s$method=="lm")"stats::rstandard, hatvalues, cooks.distance; stats::qqnorm; Cook contours from inspected stats::plot.lm" else "Conditional residuals/fitted and normal Q-Q; no LM leverage",cook_levels=c(.5,1),qq_line="quartiles",refit=FALSE)
   }
   if(any(!is.finite(r$p_raw))||any(!is.finite(r$df2))||any(!is.finite(r$statistic)))stop("Nonfinite test or degrees of freedom; inference withheld.")
   ci<-r$type=="contrast";if(any(!is.finite(as.matrix(r[ci,c("estimate","SE","lower","upper")]))))stop("Contrast is non-estimable or interval unavailable.")
   r$status<-"computed";r$reason<-"";r
  },warning=function(w){warnings<<-c(warnings,conditionMessage(w));invokeRestart("muffleWarning")}),error=function(e){
   r[,c("estimate","SE","lower","upper","statistic","df1","df2","p_raw")]<-NA_real_;r$status<-"blocked";r$reason<-conditionMessage(e);r
  })
  diagnostic$warnings<-unique(warnings);out$diagnostics[[metric]]<-diagnostic;results[[metric]]<-result
 }
 out$tests<-do.call(rbind,results);rownames(out$tests)<-NULL;out$exclusions<-do.call(rbind,excluded)
 n<-nrow(out$tests);ok<-out$tests$status=="computed"
 out$tests$p_adjusted[ok]<-stats::p.adjust(out$tests$p_raw[ok],method=s$adjust,n=n)
 out$tests$family<-s$family;out$tests$adjustment<-s$adjust;out$tests$planned<-n;out$tests$tested<-sum(ok)
 out$versions<-vapply(c("stats",if(s$method%in%c("lm","mixed"))"emmeans",if(s$method=="mixed")c("lme4","lmerTest")),function(n)as.character(utils::packageVersion(n)),character(1))
 out$status<-if(all(ok))"ready" else if(any(ok))"partial" else "blocked"
 out$reason<-paste(unique(out$tests$reason[nzchar(out$tests$reason)]),collapse="; ");out
}


