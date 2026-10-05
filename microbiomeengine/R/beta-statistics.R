beta_permutation_settings <- function(settings=list()) {
 d<-list(budget=9999L,seed=1L,mode="automatic")
 if(!is.list(settings)||length(setdiff(names(settings),names(d))))stop("Unknown permutation setting; arbitrary how() code is not accepted.")
 s<-modifyList(d,settings)
 for(n in c("budget","seed"))if(length(s[[n]])!=1L||!is.numeric(s[[n]])||!is.finite(s[[n]])||s[[n]]!=floor(s[[n]]))stop("Permutation budget and seed must be integers.")
 if(s$budget<1||s$budget>99999||s$seed<0||s$seed>.Machine$integer.max)stop("Budget must be 1-99999 and seed a nonnegative R integer.")
 if(length(s$mode)!=1L||!s$mode%in%c("automatic","sampled","exhaustive"))stop("Choose automatic, sampled or exhaustive permutations.")
 s
}
beta_comparison_settings <- function(settings=list()) {
 d<-list(route="independent",test="overall",group="",factors=character(),covariates=character(),nuisance=character(),unit="",visit="",reference="",verified=FALSE,assignment="unknown",evidence="",exchangeable=FALSE,ordered_time=FALSE,missing="fail",geometry="original",permutations=beta_permutation_settings(),pairs=list(),family="beta-pairs",adjust="holm")
 if(!is.list(settings)||length(setdiff(names(settings),names(d))))stop("Unknown beta comparison setting.")
 s<-modifyList(d,settings);if("pairs"%in%names(settings))s$pairs<-settings$pairs;s$permutations<-beta_permutation_settings(s$permutations)
 for(n in c("route","test","group","unit","visit","reference","assignment","evidence","missing","geometry","family","adjust"))if(!is.character(s[[n]])||length(s[[n]])!=1L||is.na(s[[n]]))stop("Comparison roles must be single strings.")
 if(!s$route%in%c("independent","conditional","paired","within","trajectory")||!s$test%in%c("overall","sequential","marginal"))stop("Unsupported beta hypothesis route or test kind.")
 if(!s$missing%in%c("fail","complete")||!s$geometry%in%c("original","ordination")||!s$adjust%in%c("holm","BH")||!nzchar(trimws(s$family)))stop("Choose missingness, geometry and a named Holm/BH family.")
 for(n in c("verified","exchangeable","ordered_time"))preparation_flag(s[[n]],n)
 for(n in c("factors","covariates","nuisance"))preparation_character(s[[n]],n)
 if(!is.list(s$pairs)||any(!vapply(s$pairs,function(z)is.character(z)&&length(z)==2L&&!anyNA(z)&&!anyDuplicated(z),logical(1))))stop("Pairs must be a list of two distinct exact group labels.")
 if(length(s$pairs)&&anyDuplicated(vapply(s$pairs,function(z)paste(sort(z),collapse="\r"),character(1))))stop("Repeated pairwise requests are not allowed.")
 s
}
beta_validate_indices <- function(indices,ids,blocks=NULL) {
 n<-length(ids)
 if(!is.matrix(indices)||ncol(indices)!=n||!nrow(indices)||anyNA(indices)||any(indices!=floor(indices)))stop("Invalid permutation matrix dimensions or values.")
 if(any(!apply(indices,1,function(z)identical(sort(as.integer(z)),seq_len(n)))))stop("Every permutation must be a full index bijection.")
 if(any(apply(indices,1,function(z)all(z==seq_len(n)))))stop("Identity must not be supplied twice; it is added once by the test convention.")
 if(anyDuplicated(as.data.frame(indices)))stop("Duplicate permutation rows are not allowed.")
 if(!is.null(blocks)&&any(!apply(indices,1,function(z)all(as.character(blocks[z])==as.character(blocks)))))stop("Illegal crossing of a held-together unit/block.")
 invisible(TRUE)
}
beta_permutation_plan <- function(frame,settings,blocks=NULL,algorithm="raw distance profiles",mapping=NULL) {
 s<-beta_permutation_settings(settings);ids<-frame$sample_id;n<-length(ids)
 if(n<2L||anyNA(ids)||anyDuplicated(ids))stop("Permutation IDs must be unique and contain at least two observations.")
 old_kind<-RNGkind();had_seed<-exists(".Random.seed",envir=.GlobalEnv,inherits=FALSE)
 if(had_seed)old_seed<-get(".Random.seed",envir=.GlobalEnv)
 on.exit({do.call(RNGkind,as.list(old_kind));if(had_seed)assign(".Random.seed",old_seed,envir=.GlobalEnv) else if(exists(".Random.seed",envir=.GlobalEnv,inherits=FALSE))rm(".Random.seed",envir=.GlobalEnv)},add=TRUE)
 set.seed(s$seed,kind="Mersenne-Twister",normal.kind="Inversion",sample.kind="Rejection")
 control<-permute::how(within=permute::Within(type="free"),blocks=if(is.null(blocks))NULL else factor(blocks),nperm=s$budget,minperm=0,maxperm=10000,observed=FALSE)
 space<-suppressWarnings(permute::numPerms(n,control=control));if(space>2^53)space<-Inf
 if(space<=1)stop("No nonidentity legal exchanges under these restrictions.")
 enumerate<-s$mode=="exhaustive"||(s$mode=="automatic"&&space<=10000)
 if(enumerate&&space>10000)stop("Exhaustive space exceeds 10000; explicitly choose automatic or sampled mode.")
 target<-if(enumerate)space-1 else min(s$budget,space-1)
 if(target*n>5e6)stop("Requested permutation matrix exceeds five million indices; lower the budget explicitly.")
 warnings<-character()
 if(enumerate) idx<-as.matrix(permute::allPerms(n,control=control)) else {
  idx<-matrix(integer(),nrow=0,ncol=n)
  for(attempt in seq_len(30L)) {
   need<-target-nrow(idx);if(need<=0)break
   part<-suppressMessages(permute::shuffleSet(n,nset=need,control=control))
   idx<-rbind(idx,part);idx<-idx[!apply(idx,1,function(z)all(z==seq_len(n))),,drop=FALSE];idx<-unique(idx)
  }
  if(nrow(idx)<target)stop("Could not obtain the requested distinct legal exchanges within the bounded generator; lower budget or enumerate a small space.")
  idx<-idx[seq_len(target),,drop=FALSE]
 }
 idx<-idx[!apply(idx,1,function(z)all(z==seq_len(n))),,drop=FALSE]
 idx<-matrix(as.integer(idx),ncol=n,dimnames=list(NULL,ids));beta_validate_indices(idx,ids,blocks)
 actual<-nrow(idx);mode<-if(is.finite(space)&&actual==space-1)"exhaustive" else "sampled"
 previews<-lapply(seq_len(min(3L,actual)),function(k){
  d<-data.frame(permutation=k,destination_id=ids,source_id=ids[idx[k,]],stringsAsFactors=FALSE)
  for(field in intersect(c("unit","visit","group"),names(frame))){d[[paste0("destination_",field)]]<-as.character(frame[[field]]);d[[paste0("source_",field)]]<-as.character(frame[[field]][idx[k,]])}
  if(!is.null(mapping)) {
   pos<-match(mapping$unit,d$destination_unit);expanded<-d[pos,,drop=FALSE]
   source<-match(paste(expanded$source_unit,mapping$visit,sep="\r"),paste(mapping$unit,mapping$visit,sep="\r"))
   if(anyNA(source))stop("Trajectory permutation lost a matched visit.")
   expanded$destination_id<-mapping$sample_id;expanded$source_id<-mapping$sample_id[source]
   expanded$destination_visit<-mapping$visit;expanded$source_visit<-mapping$visit[source];d<-expanded
  }
  d
 })
 visit_weights<-if(is.null(mapping))NULL else data.frame(visit=sort(unique(mapping$visit)),weight=1/length(unique(mapping$visit)))
 restriction<-if(is.null(blocks))"Independent rows may exchange; no unit is split." else paste("Exchanges stay within",length(unique(blocks)),"units; members cannot move between units.")
 summary<-paste("Algorithm:",algorithm,restriction,"Exchangeable rows/units:",n,"; samples:",if(is.null(mapping))n else nrow(mapping),"; possible exchanges including identity:",format(space),". Requested",s$budget,"; actual unique nonidentity",actual,";",mode,"; seed",s$seed,". Observed statistic is added once; tail uses >= with vegan numerical tolerance. Grid bound",format(1/(actual+1),digits=6),"is not a confidence interval or a guarantee of attainable significance. More permutations cannot fix invalid replication.")
 list(settings=s,indices=idx,index_hash=preparation_fingerprint(idx),ids=ids,blocks=blocks,control=control,possible_including_identity=space,requested=s$budget,actual=actual,mode=mode,rng=c("Mersenne-Twister","Inversion","Rejection"),identity="Excluded from indices; observed statistic added once by plus-one tail",grid_bound=1/(actual+1),algorithm=algorithm,summary=summary,preview=do.call(rbind,previews),mapping=mapping,invariants=data.frame(check=c("bijection","unique_nonidentity","cohort_identity","restriction"),passed=TRUE),warnings=warnings,
  visit_weights=visit_weights,readable_call=paste0("permute::how(within = permute::Within(type = 'free'), blocks = ",if(is.null(blocks))"NULL" else "factor(saved_frame$unit)",", nperm = ",s$budget,", observed = FALSE); set.seed(",s$seed,")\n# Exact saved indices are authoritative; pass saved_plan$indices to the public test."))
}
beta_inference_data <- function(beta,s,pair=NULL) {
 if(!identical(beta$status,"ready")||is.null(beta$distance))stop("Calculate current beta distances first.")
 if(!s$verified||!nzchar(trimws(s$evidence))||s$assignment=="unknown")stop("Inference needs verified unit identity, assignment and study-evidence justification; unknown HMP units remain descriptive.")
 if(!nzchar(s$unit))stop("Select the experimental unit ID.")
 md<-beta$metadata;ids<-attr(beta$distance,"Labels")
 if(!identical(rownames(md),ids))stop("Distance/metadata identity mismatch.")
 selected<-unique(c(s$group,s$factors,s$covariates,s$nuisance,s$unit,if(s$route=="trajectory")s$visit));selected<-selected[nzchar(selected)]
 if(any(!selected%in%names(md)))stop("A selected metadata role is unavailable.")
 if(length(intersect(c(s$group,s$factors),c(s$covariates,s$nuisance))))stop("A predictor cannot be both categorical tested effect and numeric/nuisance variable.")
 missing<-vapply(md[,selected,drop=FALSE],function(v)is.na(v)|!nzchar(trimws(as.character(v))),logical(nrow(md)))
 bad<-if(is.matrix(missing))rowSums(missing)>0 else missing
 if(any(bad)&&s$missing=="fail")stop("Missing model/unit metadata: choose explicit complete-case exclusion or correct inputs.")
 reason<-ifelse(bad,"missing selected model/unit metadata","")
 if(s$route%in%c("paired","within","trajectory")&&any(bad)){units<-as.character(md[[s$unit]]);bad<-bad|units%in%units[bad];reason[bad]<-"unit removed because selected metadata is missing"}
 exclusions<-data.frame(sample_id=ids[bad],reason=reason[bad],row.names=NULL)
 md<-md[!bad,,drop=FALSE];ids<-ids[!bad]
 if(!is.null(pair)){take<-as.character(md[[s$group]])%in%pair;md<-md[take,,drop=FALSE];ids<-ids[take]}
 if(length(ids)<3L)stop("Too few retained observations for an estimable community model.")
 base_distance<-if(s$geometry=="original")beta$distance else beta$ordination$distance
 if(is.null(base_distance))stop("Selected geometry is unavailable.")
 D<-as.matrix(base_distance)[ids,ids,drop=FALSE]
 frame<-data.frame(sample_id=ids,unit=as.character(md[[s$unit]]),row.names=ids,stringsAsFactors=FALSE)
 if(nzchar(s$group))frame$group<-factor(as.character(md[[s$group]]))
 repeated<-s$route%in%c("paired","within","trajectory")
 if(!repeated) {
  if(s$assignment!="independent_units"||anyDuplicated(frame$unit))stop("This hypothesis requires one observation per verified independent unit; repeated rows cannot be independent replicates.")
 } else {
  if(s$assignment!="independent_subjects")stop("Repeated routes require independently assigned/observed subjects.")
  if(!nzchar(s$group))stop("Select condition or between-unit group for this repeated hypothesis.")
 }
 mapping<-NULL;blocks<-NULL
 if(s$route%in%c("paired","within")) {
  if(!s$exchangeable||s$ordered_time)stop("Within-unit condition exchangeability must be justified. Ordered/serial time is not automatically exchangeable.")
  if(any(beta$metadata_types[s$group]%in%c("continuous","date")))stop("Within-unit shuffling of a continuous/date time role is unsupported; declare an actual exchangeable categorical condition.")
  if(length(c(s$factors,s$covariates,s$nuisance)))stop("Within-unit route supports condition with fixed unit nuisance only; additional effects are not validated.")
  if(all(vapply(split(as.character(frame$group),frame$unit),function(g)length(unique(g))==1L,logical(1))))stop("The between-unit group does not vary under within-unit swaps; this hypothesis is untestable under the requested restriction.")
  tab<-table(frame$unit,frame$group)
  if(any(tab>1L))stop("Duplicate unit/condition observation.")
  incomplete<-rownames(tab)[apply(tab,1,function(z)any(z!=1L))]
  if(length(incomplete)) {
   if(s$missing=="fail")stop("Incomplete unit/condition grid; choose explicit whole-unit exclusion.")
   drop<-frame$unit%in%incomplete;exclusions<-rbind(exclusions,data.frame(sample_id=frame$sample_id[drop],reason="incomplete condition unit"));frame<-frame[!drop,,drop=FALSE];md<-md[!drop,,drop=FALSE];D<-D[!drop,!drop,drop=FALSE]
  }
  if(length(unique(frame$unit))<2||nlevels(droplevels(frame$group))<2||(s$route=="paired"&&nlevels(droplevels(frame$group))!=2))stop("Need at least two complete independent units and valid paired/condition levels.")
  blocks<-frame$unit
 }
 if(s$route=="trajectory") {
  if(!s$exchangeable||!nzchar(s$visit))stop("Whole trajectories require verified randomized group assignment and an explicit matched visit grid.")
  if(length(c(s$factors,s$covariates,s$nuisance)))stop("Trajectory randomization supports one between-unit group only.")
  frame$visit<-as.character(md[[s$visit]])
  tab<-table(frame$unit,frame$visit)
  if(ncol(tab)<2||any(tab!=1L))stop("Whole trajectories need identical complete visit grids with one sample per unit/visit; irregular grids are unsupported.")
  if(any(vapply(split(as.character(frame$group),frame$unit),function(g)length(unique(g))!=1L,logical(1))))stop("Trajectory group must be constant within each unit.")
  units<-sort(unique(frame$unit),method="radix");visits<-sort(unique(frame$visit),method="radix")
  mapping<-frame;U<-matrix(0,length(units),length(units),dimnames=list(units,units))
  for(v in visits){rows<-match(paste(units,v,sep="\r"),paste(frame$unit,frame$visit,sep="\r"));U<-U+D[rows,rows,drop=FALSE]^2/length(visits)}
  frame<-data.frame(sample_id=units,unit=units,group=factor(as.character(frame$group[match(units,frame$unit)])),row.names=units);D<-sqrt(U)
  md<-data.frame(row.names=units);md[[s$group]]<-frame$group
 }
 if(nzchar(s$group)&&any(table(droplevels(frame$group))<2L))stop("Each compared group/condition needs at least two observations from valid independent units.")
 if(nzchar(s$group)&&nlevels(droplevels(frame$group))<2L)stop("Only one group/condition remains.")
 list(distance=stats::as.dist(D),frame=frame,metadata=md,exclusions=exclusions,blocks=blocks,mapping=mapping)
}
beta_fit <- function(beta,s,pair=NULL) {
 z<-beta_inference_data(beta,s,pair);frame<-z$frame;md<-z$metadata
 effects<-unique(c(s$group,s$factors,if(s$route=="independent")s$covariates));effects<-effects[nzchar(effects)]
 nuisance<-if(s$route=="conditional")unique(c(s$nuisance,s$covariates)) else if(s$route%in%c("paired","within"))s$unit else character()
 if(s$route=="conditional"&&!length(nuisance))stop("Select explicit nuisance/covariate terms for a conditional test.")
 if(s$route!="independent"&&s$test!="overall")stop("Sequential/marginal options are for independent models; this route tests its explicit conditional hypothesis overall.")
 if(s$route=="independent"&&length(s$nuisance))stop("Choose conditional route for explicit nuisance terms.")
 if(!length(effects))stop("Select at least one tested effect.")
 fields<-unique(c(effects,nuisance));data<-data.frame(row.names=frame$sample_id);aliases<-setNames(paste0("v",seq_along(fields)),fields)
 for(n in fields) {
  v<-if(n==s$unit&&s$route%in%c("paired","within"))frame$unit else md[[n]]
  if(n%in%c(s$group,s$factors)||n==s$unit||(n%in%nuisance&&!n%in%s$covariates&&(!is.numeric(v)||any(beta$metadata_types[n]=="categorical",na.rm=TRUE)))) {
   v<-factor(as.character(v));if(n==s$group&&nzchar(s$reference)){if(!s$reference%in%levels(v)&&is.null(pair))stop("Reference group is absent.");if(s$reference%in%levels(v))v<-stats::relevel(v,s$reference)}
   if(nlevels(v)<2)stop("A categorical predictor has fewer than two levels.")
  }else {v<-suppressWarnings(as.numeric(as.character(v)));if(any(!is.finite(v))||length(unique(v))<2)stop("Covariates/nuisance must be finite numeric values with variation.")}
  data[[aliases[[n]]]]<-v
 }
 X<-stats::model.matrix(stats::reformulate(unname(aliases)),data)
 if(qr(X)$rank<ncol(X))stop("Model is aliased/confounded; no silent term dropping is allowed.")
 df_res<-nrow(X)-qr(X)$rank;if(df_res<=0)stop("Model has no residual degrees of freedom.")
 D<-z$distance;G<--.5*(diag(nrow(X))-1/nrow(X))%*%(as.matrix(D)^2)%*%(diag(nrow(X))-1/nrow(X));total<-sum(diag(G))
 if(!is.finite(total)||total<=sqrt(.Machine$double.eps))stop("No positive total inertia for inference.")
 algorithm<-if(length(nuisance))"vegan 2.7-5 reduced partial response AND nuisance rows; fixed constraints re-residualized against permuted nuisance" else if(s$route=="trajectory")"whole randomized unit trajectories on equal-weight matched-visit distance; no visit shuffling" else "raw distance profile row/column indices relative to the fixed model"
 plan<-beta_permutation_plan(frame,s$permutations,z$blocks,algorithm,z$mapping)
 if(!is.null(z$blocks)&&!any(apply(plan$indices,1,function(i)any(as.character(frame$group[i])!=as.character(frame$group)))))stop("The tested effect does not change under requested within-unit restrictions.")
 rhs<-paste(unname(aliases[effects]),collapse=" + ");if(length(nuisance))rhs<-paste(rhs,"+ Condition(",paste(unname(aliases[nuisance]),collapse=" + "),")")
 form<-stats::as.formula(paste("D ~",rhs),env=environment());warn<-character()
 tab<-withCallingHandlers({
  if(length(nuisance)) {fit<-vegan::dbrda(form,data=data,sqrt.dist=FALSE,add=FALSE,na.action=stats::na.fail);stats::anova(fit,permutations=plan$indices,by=NULL,model="reduced",parallel=1)}
  else vegan::adonis2(form,data=data,permutations=plan$indices,sqrt.dist=FALSE,add=FALSE,by=switch(s$test,overall=NULL,sequential="terms",marginal="margin"),parallel=1,na.action=stats::na.fail)
 },warning=function(w){warn<<-c(warn,conditionMessage(w));invokeRestart("muffleWarning")})
 resid<-tab["Residual",,drop=FALSE];ss_name<-names(tab)[2];res_ss<-resid[[ss_name]]
 if(!is.finite(res_ss)||res_ss<=sqrt(.Machine$double.eps)||resid$Df<=0)stop("Nonpositive/degenerate residual inertia or degrees of freedom.")
 use<-which(!rownames(tab)%in%c("Residual","Total"));terms<-rownames(tab)[use]
 matched<-match(terms,unname(aliases));terms[!is.na(matched)]<-names(aliases)[matched[!is.na(matched)]]
 tests<-data.frame(term=terms,df=tab$Df[use],residual_df=resid$Df,SS=tab[[ss_name]][use],total_SS=total,R2=tab[[ss_name]][use]/total,F=tab$F[use],p_raw=tab$`Pr(>F)`[use],n_samples=if(is.null(z$mapping))nrow(frame) else nrow(z$mapping),n_units=length(unique(frame$unit)),status="ready",reason="",stringsAsFactors=FALSE)
 if(any(!is.finite(tests$F))||any(!is.finite(tests$p_raw))||any(tests$df<=0))stop("Upstream test returned an undefined statistic or unestimable term.")
 call<-if(length(nuisance))paste0("fit <- vegan::dbrda(",paste(deparse(form),collapse=""),", data = saved_model_frame, sqrt.dist = FALSE, add = FALSE, na.action = stats::na.fail)\nstats::anova(fit, permutations = saved_plan$indices, by = NULL, model = 'reduced', parallel = 1)") else paste0("vegan::adonis2(",paste(deparse(form),collapse=""),", data = saved_model_frame, permutations = saved_plan$indices, sqrt.dist = FALSE, add = FALSE, by = ",switch(s$test,overall="NULL",sequential="'terms'",marginal="'margin'"),", parallel = 1, na.action = stats::na.fail)")
 list(status="ready",reason="",tests=tests,inertia=list(total=total,nuisance=if(length(nuisance))fit$pCCA$tot.chi else 0,constrained=if(length(nuisance))fit$CCA$tot.chi else total-res_ss,residual=res_ss),frame=cbind(frame,data),exclusions=z$exclusions,model_matrix=X,rank=qr(X)$rank,formula=paste("distance ~",paste(effects,collapse=" + "),if(length(nuisance))paste("+ Condition(",paste(nuisance,collapse=" + "),")") else ""),coding=lapply(data,function(v)if(is.factor(v))list(levels=levels(v),contrasts=stats::contrasts(v)) else "numeric unscaled"),tested=effects,nuisance=nuisance,distance=D,distance_hash=preparation_fingerprint(D),permutation=plan,permuted=attr(tab,"F.perm"),warnings=warn,R2_definition="Term SS / original total inertia of the stated test distance; no confidence interval",readable_call=paste("D <- saved_result$distance\nsaved_model_frame <- saved_result$frame\nsaved_plan <- saved_result$permutation",call,sep="\n"),aliases=aliases)
}
compare_beta <- function(beta,settings=list()) {
 out<-list(status="blocked",reason="",settings=settings,tests=data.frame(),pairwise=data.frame(),results=list(),exclusions=data.frame())
 tryCatch({
  s<-beta_comparison_settings(settings);out$settings<-s
  run<-function(pair=NULL,request=s)tryCatch(beta_fit(beta,request,pair),error=function(e)list(status="blocked",reason=conditionMessage(e),tests=data.frame(term="Requested hypothesis",df=NA_real_,residual_df=NA_real_,SS=NA_real_,total_SS=NA_real_,R2=NA_real_,F=NA_real_,p_raw=NA_real_,n_samples=NA_integer_,n_units=NA_integer_,status="blocked",reason=conditionMessage(e))))
  main<-run();out$results$omnibus<-main;out$tests<-main$tests;out$exclusions<-main$exclusions
  out$tests$p_adjusted<-stats::p.adjust(out$tests$p_raw,method=s$adjust,n=nrow(out$tests));out$tests$family<-paste0(s$family,"-omnibus");out$tests$adjustment<-s$adjust
  if(length(s$pairs)) {
   rows<-lapply(seq_along(s$pairs),function(i){
    pair<-s$pairs[[i]];ps<-s;ps$test<-"overall"
    if(s$route%in%c("independent","conditional")&&length(c(s$factors,s$covariates,s$nuisance))){ps$route<-"conditional";ps$nuisance<-unique(c(s$factors,s$nuisance));ps$factors<-character()}
    r<-if(!nzchar(s$group))list(status="blocked",reason="Pairwise comparisons require a group column.") else run(pair,ps)
    r$pair_settings<-ps
    out$results[[paste0("pair",i)]]<<-r
    if(is.null(r$tests)||nrow(r$tests)!=1L){r$tests<-main$tests[1,,drop=FALSE];r$tests[,c("df","residual_df","SS","total_SS","R2","F","p_raw")]<-NA_real_;r$tests$status<-"blocked";r$tests$reason<-"Pairwise tests require an overall or explicit conditional hypothesis, not multiple sequential/marginal terms."}
    cbind(data.frame(pair=i,level1=pair[1],level2=pair[2]),r$tests)
   })
   out$pairwise<-do.call(rbind,rows);good<-is.finite(out$pairwise$p_raw);out$pairwise$p_adjusted<-NA_real_
   if(any(good))out$pairwise$p_adjusted[good]<-stats::p.adjust(out$pairwise$p_raw[good],s$adjust,n=length(s$pairs))
   out$pairwise$family<-s$family;out$pairwise$planned<-length(s$pairs);out$pairwise$valid<-sum(good);out$pairwise$adjustment<-s$adjust
  }
  states<-c(out$tests$status,out$pairwise$status);out$status<-if(all(states=="ready"))"ready" else if(any(states=="ready"))"partial" else "blocked";out$reason<-paste(unique(c(out$tests$reason,out$pairwise$reason)[nzchar(c(out$tests$reason,out$pairwise$reason))]),collapse="; ")
  out$parent<-beta$fingerprint;out$metadata_hash<-preparation_fingerprint(beta$metadata);out
 },error=function(e){out$status<-"blocked";out$reason<-conditionMessage(e);out})
}
beta_dispersion <- function(beta,settings=list()) {
 bias<-settings$bias_adjust;if(is.null(bias))bias<-FALSE;settings$bias_adjust<-NULL
 out<-list(status="blocked",reason="",settings=c(settings,list(bias_adjust=bias)),tests=data.frame())
 tryCatch({
  preparation_flag(bias,"bias_adjust");s<-beta_comparison_settings(settings);out$settings<-c(s,list(bias_adjust=bias))
  if(s$route!="independent"||length(c(s$factors,s$covariates,s$nuisance,s$pairs))||!nzchar(s$group))stop("Dispersion inference supports one factor with independent observations only; repeated, trajectory, adjusted and pairwise dispersion are not validated.")
  z<-beta_inference_data(beta,s);plan<-beta_permutation_plan(z$frame,s$permutations,algorithm="vegan full-model residuals of distances to group spatial medians; observed group F is compared to permuted-residual F")
  warn<-character();fit<-withCallingHandlers(vegan::betadisper(z$distance,z$frame$group,type="median",bias.adjust=bias,sqrt.dist=FALSE,add=FALSE),warning=function(w){warn<<-c(warn,conditionMessage(w));invokeRestart("muffleWarning")})
  test<-vegan::permutest(fit,permutations=plan$indices,pairwise=FALSE,parallel=1);tab<-test$tab
  if(!is.finite(tab$F[1])||!is.finite(tab$`Pr(>F)`[1])||tab$`Sum Sq`[2]<=sqrt(.Machine$double.eps))stop("Dispersion has undefined F or degenerate residual variation.")
  out$tests<-data.frame(term="Dispersion",df=tab$Df[1],residual_df=tab$Df[2],F=tab$F[1],p_raw=tab$`Pr(>F)`[1],n_samples=nrow(z$frame),n_units=length(unique(z$frame$unit)),type="spatial median",bias_adjust=bias)
  out$distances<-data.frame(sample_id=names(fit$distances),group=as.character(fit$group),distance=unname(fit$distances));out$centres<-fit$centroids;out$eigenvalues<-fit$eig;out$warnings<-warn;out$negative_distance_warning<-any(grepl("negative",warn,ignore.case=TRUE));out$permuted<-test$perm
  out$distance<-z$distance
  delta<-fit$vectors-fit$centroids[as.character(fit$group),,drop=FALSE]
  signed_squared<-rowSums(sweep(delta^2,2,sign(fit$eig),`*`))
  out$negative_squared_count<-sum(signed_squared<0)
  out$signed_squared_distances<-data.frame(sample_id=rownames(delta),signed_squared=signed_squared,truncated=signed_squared<0)
  out$group_summary<-data.frame(group=names(fit$group.distances),mean_distance=unname(fit$group.distances),n=as.integer(table(fit$group)))
  out$readable_call<-paste0("fit <- vegan::betadisper(saved_result$distance, factor(saved_result$frame$group), type = 'median', bias.adjust = ",bias,", sqrt.dist = FALSE, add = FALSE)\nvegan::permutest(fit, permutations = saved_result$permutation$indices, pairwise = FALSE, parallel = 1)")
  out$frame<-z$frame;out$exclusions<-z$exclusions;out$permutation<-plan;out$distance_hash<-preparation_fingerprint(z$distance);out$parent<-beta$fingerprint;out$status<-"ready";out$reason<-"Residual permutation of centre distances; not proof of homogeneity and not a clustered test.";out
 },error=function(e){out$status<-"blocked";out$reason<-conditionMessage(e);out})
}
