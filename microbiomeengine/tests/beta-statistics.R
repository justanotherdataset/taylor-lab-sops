args<-commandArgs(TRUE)
if(length(args)>1L).libPaths(c(normalizePath(args[2],winslash="/"),file.path(normalizePath(args[1],winslash="/"),".library"),.libPaths()))
library(microbiomeengine)
eq<-function(x,y,tol=1e-8)stopifnot(isTRUE(all.equal(x,y,tolerance=tol,check.attributes=FALSE)))
fails<-function(expr)stopifnot(inherits(try(force(expr),silent=TRUE),"try-error"))
mk<-function(x,group,unit=seq_along(group),visit=NULL,cov=NULL) {
 ids<-paste0("sample / ",seq_along(group));m<-if(is.matrix(x))x else cbind(x,1-x)
 rownames(m)<-ids;md<-data.frame(sample_id=ids,group=as.character(group),unit=as.character(unit),row.names=ids)
 if(!is.null(visit))md$visit<-visit;if(!is.null(cov))md$cov<-cov
 D<-outer(seq_len(nrow(m)),seq_len(nrow(m)),Vectorize(function(i,j)sum(abs(m[i,]-m[j,]))/sum(m[i,]+m[j,])));dimnames(D)<-list(ids,ids)
 list(status="ready",distance=as.dist(D),metadata=md,metadata_types=c(group="categorical",unit="id",visit="categorical",cov="continuous"),fingerprint="synthetic-independent-method-fixture")
}
s<-list(group="group",unit="unit",verified=TRUE,assignment="independent_units",evidence="Synthetic independent-unit assignment fixture",permutations=list(budget=9999,seed=36,mode="automatic"))
b<-mk(c(0,.1,.2,.8,.9,1),rep(c("A","B"),each=3))
set.seed(673);rng<-.Random.seed;c<-compare_beta(b,s);if(c$status!="ready")print(c);stopifnot(c$status=="ready",identical(rng,.Random.seed))
eq(c$tests$SS,.96);eq(c$tests$total_SS,1);eq(c$tests$F,96);eq(c$tests$R2,.96);eq(c$tests$p_raw,.1)
plan<-c$results$omnibus$permutation;stopifnot(plan$actual==719,plan$mode=="exhaustive",plan$possible_including_identity==720)
alloc<-combn(6,3);x<-c(0,.1,.2,.8,.9,1);f<-apply(alloc,2,function(i){ss<-sum((x[i]-mean(x[i]))^2)+sum((x[-i]-mean(x[-i]))^2);(sum((x-mean(x))^2)-ss)/(ss/4)})
eq(mean(f>=96-1e-8),c$tests$p_raw)
bad<-plan$indices;bad[2,]<-bad[1,];fails(microbiomeengine:::beta_validate_indices(bad,plan$ids));bad<-plan$indices;bad[1,]<-seq_len(6);fails(microbiomeengine:::beta_validate_indices(bad,plan$ids))
sampled<-modifyList(s,list(permutations=list(budget=19,mode="sampled",seed=81)));c1<-compare_beta(b,sampled);c2<-compare_beta(b,sampled);stopifnot(identical(c1$results$omnibus$permutation$indices,c2$results$omnibus$permutation$indices),c1$results$omnibus$permutation$actual==19)
cat("PASS independent hand Bray/SS/F/R2, direct label allocations, tiny-space counts, RNG and illegal-index fixtures\n")
H<-function(X){a<-svd(X);keep<-a$d>max(a$d)*1e-9;if(!any(keep))return(matrix(0,nrow(X),nrow(X)));tcrossprod(a$u[,keep,drop=FALSE])}
gram<-function(D){n<-nrow(D);J<-diag(n)-1/n;-J%*%(D^2)%*%J/2}
tr<-function(X)sum(diag(X))
b<-mk(c(.03,.2,.31,.42,.52,.74,.83,.96),rep(c("A","B"),each=4),cov=c(0,2,1,4,2,6,3,7));b$metadata$factor2<-rep(c("L","H"),4)
ss<-modifyList(s,list(factors="factor2",covariates="cov",test="sequential",permutations=list(budget=29,mode="sampled")))
c<-compare_beta(b,ss);stopifnot(c$status=="ready")
md<-b$metadata;X<-model.matrix(~group+factor2+cov,md);G<-gram(as.matrix(b$distance));h<-lapply(1:4,function(k)H(X[,seq_len(k),drop=FALSE]));increment<-diff(vapply(h,function(z)tr(z%*%G),numeric(1)))
eq(c$tests$SS,increment);eq(c$tests$F,(increment)/(tr((diag(8)-h[[4]])%*%G)/4))
cm<-compare_beta(b,modifyList(ss,list(test="marginal")));stopifnot(cm$status=="ready")
for(j in 2:4)eq(cm$tests$SS[j-1],tr((h[[4]]-H(X[,-j,drop=FALSE]))%*%G))
cp<-compare_beta(b,modifyList(s,list(route="conditional",covariates="cov",permutations=list(budget=29,mode="sampled"))));stopifnot(cp$status=="ready")
r<-cp$results$omnibus;Z<-model.matrix(~cov,md);Rz<-diag(8)-H(Z);E<-Rz%*%G%*%Rz;Xt<-model.matrix(~group,md);hx<-H(Rz%*%Xt);eq(cp$tests$SS,tr(hx%*%E))
reference<-apply(r$permutation$indices,1,function(i){Zp<-Z[i,,drop=FALSE];Rzp<-diag(8)-H(Zp);Ep<-Rzp%*%E[i,i]%*%Rzp;hp<-H(Rzp%*%Xt);tr(hp%*%Ep)/(tr((diag(8)-hp)%*%Ep)/5)})
eq(as.numeric(r$permuted),reference);eq(cp$tests$p_raw,(1+sum(reference>=cp$tests$F-sqrt(.Machine$double.eps)))/(length(reference)+1))
bad<-b;bad$metadata$cov<-as.numeric(bad$metadata$group=="B");stopifnot(compare_beta(bad,modifyList(s,list(route="conditional",covariates="cov")))$status=="blocked")
bad<-b;bad$metadata$cov[1]<-NA;stopifnot(compare_beta(bad,modifyList(ss,list(missing="fail")))$status=="blocked");cc<-compare_beta(bad,modifyList(ss,list(missing="complete")));stopifnot(cc$status=="ready",nrow(cc$exclusions)==1L)
cat("PASS independent SVD projections for sequential/marginal/conditional models, version-specific partial permutation numerators/denominators, alias and missingness\n")
bp<-mk(c(.1,.3,.2,.7,.15,.6),rep(c("A","B"),3),rep(paste0("u",1:3),each=2))
ps<-modifyList(s,list(route="paired",assignment="independent_subjects",exchangeable=TRUE));pc<-compare_beta(bp,ps);if(pc$status!="ready")print(pc);stopifnot(pc$status=="ready")
pp<-pc$results$omnibus$permutation;stopifnot(pp$actual==7,all(apply(pp$indices,1,function(i)all(bp$metadata$unit[i]==bp$metadata$unit))))
flips<-expand.grid(rep(list(c(FALSE,TRUE)),3));allidx<-t(apply(flips,1,function(q){i<-1:6;for(k in 1:3)if(q[k])i[(2*k-1):(2*k)]<-rev(i[(2*k-1):(2*k)]);i}))
eq(sort(apply(rbind(1:6,pp$indices),1,paste,collapse=",")),sort(apply(allidx,1,paste,collapse=",")))
bad<-pp$indices;bad[1,1:2]<-c(3,4);fails(microbiomeengine:::beta_validate_indices(bad,pp$ids,pp$blocks))
stopifnot(compare_beta(bp,modifyList(ps,list(exchangeable=FALSE)))$status=="blocked",compare_beta(bp,modifyList(ps,list(ordered_time=TRUE)))$status=="blocked")
bad<-bp;bad$metadata$group<-rep(c("A","B","A"),each=2);stopifnot(compare_beta(bad,ps)$status=="blocked")
bt<-mk(c(.1,.3,.2,.4,.7,.8,.8,.95),rep(c("A","A","B","B"),each=2),rep(paste0("u",1:4),each=2),rep(c("v1","v2"),4))
ts<-modifyList(ps,list(route="trajectory",visit="visit"));tc<-compare_beta(bt,ts);if(tc$status!="ready")print(tc);stopifnot(tc$status=="ready",tc$tests$residual_df==2,tc$tests$n_units==4,tc$tests$n_samples==8)
D<-as.matrix(bt$distance);DU<-sqrt((D[c(1,3,5,7),c(1,3,5,7)]^2+D[c(2,4,6,8),c(2,4,6,8)]^2)/2);eq(as.matrix(tc$results$omnibus$distance),DU)
eq(gram(DU),(gram(D[c(1,3,5,7),c(1,3,5,7)])+gram(D[c(2,4,6,8),c(2,4,6,8)]))/2);stopifnot(tc$results$omnibus$permutation$actual==23)
bad<-bt;bad$metadata$visit[1]<-"v3";stopifnot(compare_beta(bad,ts)$status=="blocked")
cat("PASS hand within-pair exchange enumeration, blocked between-unit/ordered-time tests, whole-trajectory Gram identity and independent unit df\n")
sf<-modifyList(s,list(pairs=list(c("A","B"),c("A","C")),permutations=list(budget=19,mode="sampled")));fam<-compare_beta(b,sf);stopifnot(fam$status=="partial",nrow(fam$pairwise)==2,all(fam$pairwise$planned==2),is.na(fam$pairwise$p_raw[2]));eq(fam$pairwise$p_adjusted[1],min(1,2*fam$pairwise$p_raw[1]))
eq(p.adjust(c(.01,.04,.03),"holm",n=4),c(.04,.09,.09))
# Symmetric one-dimensional clouds: spatial medians and deviations known independently.
bd<-mk(c(.05,.1,.15,.75,.85,.95),rep(c("A","B"),each=3));ds<-modifyList(s,list(permutations=list(budget=99,mode="automatic")));disp<-beta_dispersion(bd,ds);if(disp$status!="ready")print(disp);stopifnot(disp$status=="ready")
dev<-c(.05,0,.05,.1,0,.1);eq(disp$distances$distance,dev)
X<-model.matrix(~group,bd$metadata);hp<-H(X);res<-as.numeric((diag(6)-hp)%*%dev);F0<-tr(matrix(sum((hp%*%dev-mean(dev))^2),1))/(sum(res^2)/4);eq(disp$tests$F,F0)
fp<-apply(disp$permutation$indices,1,function(i){v<-res[i];f<-hp%*%v;sum((f-mean(f))^2)/(sum(((diag(6)-hp)%*%v)^2)/4)})
eq(disp$permuted,fp);eq(disp$tests$p_raw,(1+sum(fp>=F0-sqrt(.Machine$double.eps)))/(length(fp)+1))
stopifnot(beta_dispersion(bp,ps)$status=="blocked",beta_dispersion(b,modifyList(ds,list(covariates="cov")))$status=="blocked")
cat("PASS family failure accounting, spatial medians, independent residual-permutation F, and separate dispersion eligibility\n")
bf<-mk(seq(.05,.95,length.out=9),rep(c("A","B","C"),each=3));ff<-compare_beta(bf,modifyList(sf,list(pairs=list(c("A","B"),c("B","C")),permutations=list(budget=17,mode="sampled"))));stopifnot(ff$status=="ready")
for(i in 1:2){rr<-ff$results[[paste0("pair",i)]];stopifnot(ncol(rr$permutation$indices)==6,identical(colnames(rr$permutation$indices),rr$frame$sample_id),all(rr$frame$group%in%sf$pairs[[1]])||i==2)}
stopifnot(!identical(ff$results$pair1$permutation$ids,ff$results$pair2$permutation$ids))
bw<-mk(c(.1,.3,.5,.2,.4,.65,.15,.36,.75),rep(c("A","B","C"),3),rep(paste0("u",1:3),each=3));wc<-compare_beta(bw,modifyList(ps,list(route="within")));stopifnot(wc$status=="ready",wc$results$omnibus$permutation$actual==215)
bad<-bw;bad$metadata$group[1]<-NA;stopifnot(compare_beta(bad,modifyList(ps,list(route="within")))$status=="blocked");wcc<-compare_beta(bad,modifyList(ps,list(route="within",missing="complete")));stopifnot(wcc$status=="ready",wcc$tests$n_units==2,nrow(wcc$exclusions)==3)
# Illustrations only: no error-rate or power calibration claimed.
examples<-list(location=mk(c(.1,.15,.2,.7,.75,.8),rep(c("A","B"),each=3)),spread=mk(c(.45,.5,.55,.1,.5,.9),rep(c("A","B"),each=3)),unbalanced=mk(c(.4,.45,.5,.55,.6,.1,.5,.9),c(rep("A",5),rep("B",3))))
for(n in names(examples)){rr<-compare_beta(examples[[n]],modifyList(s,list(permutations=list(budget=29,mode="sampled"))));dd<-beta_dispersion(examples[[n]],modifyList(ds,list(permutations=list(budget=29,mode="sampled"))));cat("ILLUSTRATION",n,"PERMANOVA",rr$status,rr$tests$p_raw,"dispersion",dd$status,dd$tests$p_raw,"\n")}
cat("PASS rebuilt pairwise identities, balanced within-unit conditions, whole-unit exclusion and illustrative location/spread fixtures\n")
eq(unlist(r$inertia)["total"],sum(unlist(r$inertia)[c("nuisance","constrained","residual")]))
eq(tc$results$omnibus$permutation$visit_weights$weight,c(.5,.5))
tp<-tc$results$omnibus$permutation$preview;stopifnot(nrow(tp)==24,identical(tp$destination_visit,tp$source_visit))
eq(disp$group_summary$mean_distance,c(1/30,1/15));stopifnot(disp$negative_squared_count==0)
biased<-beta_dispersion(bd,modifyList(ds,list(bias_adjust=TRUE)));eq(biased$distances$distance,dev*sqrt(3/2))
set.seed(3614);found<-FALSE
for(k in 1:200){
 profiles<-matrix(sample(0:3,24,replace=TRUE),6,4)+.01
 negative<-bd;negative$distance<-vegan::vegdist(profiles,method="bray");attr(negative$distance,"Labels")<-rownames(negative$metadata)
 ref<-suppressWarnings(vegan::betadisper(negative$distance,negative$metadata$group,type="median"))
 delta<-ref$vectors-ref$centroids[ref$group,,drop=FALSE]
 squared<-as.numeric((delta^2)%*%sign(ref$eig))
 if(any(squared<0)){
  result<-beta_dispersion(negative,ds)
  if(result$status=="ready"){
   stopifnot(result$negative_squared_count==sum(squared<0),result$negative_distance_warning)
   eq(result$distances$distance,sqrt(pmax(0,squared)));found<-TRUE;break
  }
 }
}
stopifnot(found);cat("PASS inertia decomposition, matched-visit weights/preview, group means, bias multiplier and negative squared-distance truncation diagnostic\n")
