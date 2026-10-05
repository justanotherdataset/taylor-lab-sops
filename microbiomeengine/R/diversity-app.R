# Presentation of existing applied state; no calculation is performed here.
diversity_source_label <- function(project, source="relative") {
 if(identical(source,"estimated_reads"))return("Estimated reads")
 if(is_estimate_only(project$input))"Relative estimated-read contribution" else "Supplied relative abundance"
}
diversity_rank_label <- function(project, rank=project$declarations$rank) {
 choices<-rank_choices(project$input);i<-match(rank,unname(choices))
 if(length(i)!=1L||is.na(i)||!nzchar(rank))"Not selected" else names(choices)[i]
}
diversity_input_context <- function(project, stage) {
 if(is.null(project))return(shiny::div(class="input-context",shiny::p("Load and confirm an input in Data setup to begin.")))
 result<-project[[stage]]
 source<-if(stage=="alpha"&&!is.null(result$settings$source))result$settings$source else "relative"
 estimate<-source=="estimated_reads"||is_estimate_only(project$input)
 record<-project$input$sources[[if(estimate)"estimates" else "abundance"]]
 units<-if(source=="estimated_reads")"estimated reads" else "proportion (0 to 1)"
 prep<-preparation_settings(project$preparation$settings)
 active<-!is.null(project$experiment)
 dimensions<-if(active)paste(ncol(project$experiment),"samples /",nrow(project$experiment),"named features") else "No active prepared matrix"
 cohort<-c(if(prep$samples$enabled)"sample IDs",if(prep$group$enabled)"group",if(prep$time$enabled)"time/visit")
 filter<-if(prep$filter$enabled)paste("Detection",prep$filter$detection_operator,prep$filter$detection,prep$filter$units,"; prevalence",prep$filter$prevalence_operator,prep$filter$prevalence) else "Feature filter off"
 saved<-if(is.null(result))paste("No",stage,"result yet.") else paste("Saved",stage,"result:",result$status,if(stage=="beta")beta_metric_label(result$settings$metric),"|",if(is.null(result$rank))"rank unavailable" else diversity_rank_label(project,result$rank),"|",result$source_label)
 normalize<-if(stage=="alpha")"Shannon and Simpson indices normalize within retained named-feature mass; detected taxa uses value > 0. Supplied Unclassified is excluded. Stored assays are unchanged." else "Beta uses the selected distance on prepared relative measurements. Supplied Unclassified, display top-N and Other are excluded from the analytical matrix."
 mass<-if(active&&source%in%SummarizedExperiment::assayNames(project$experiment))colSums(SummarizedExperiment::assay(project$experiment,source)) else numeric()
 shiny::div(class="input-context",shiny::h4("Applied input"),
  shiny::p(shiny::strong(paste(diversity_source_label(project,source),"|",diversity_rank_label(project)))," | ",dimensions),
  shiny::p(class="context-secondary",paste("File:",if(is.null(record$name))"not available" else record$name,"| Units:",units)),
  shiny::p(class="context-secondary",paste(if(length(cohort))paste("Cohort limited by",paste(cohort,collapse=", ")) else "All supplied samples", "|",filter)),
  shiny::p(class="result-context",saved),
  shiny::tags$details(shiny::tags$summary("Measurement, retained mass and layer details"),
   shiny::p(if(is.null(result$normalization))normalize else result$normalization),shiny::p(paste("Input normalization:",project$normalization$operation)),
   if(length(mass))shiny::p(paste("Retained named mass per sample:",format(min(mass),digits=7),"to",format(max(mass),digits=7),units,". Exact per-sample values remain in the saved result/mass exports.")),
   shiny::p("Named transformed layers are separate Preparation outputs; they are not used by Alpha or Beta."),
   if(length(project$assay_layers))shiny::p(paste("Saved layers:",paste(vapply(project$assay_layers,function(z)paste(z$settings$name,paste0("(",z$status,")")),character(1)),collapse=", "))),
   if(!active)shiny::p("Resolve Data setup or Preparation findings before calculation.")))
}
diversity_rank_ui <- function(project, stage) {
 if(is.null(project))return(NULL)
 choices<-rank_choices(project$input);choices<-choices[nzchar(choices)]
 shiny::tags$details(class="rank-panel",shiny::tags$summary("Change shared taxonomic rank"),
  shiny::fluidRow(shiny::column(6,shiny::selectInput(paste0(stage,"_rank"),"Supplied taxonomic rank",choices,selected=project$declarations$rank,selectize=FALSE)),
   shiny::column(6,shiny::actionButton(paste0(stage,"_rank_apply"),"Apply shared rank"))),
  shiny::helpText(if(length(choices)==1L)"Only one terminal rank is supplied. Ancestor names in a lineage do not supply independent abundance rows." else "Only supplied terminal-rank rows are offered; parent and child rows are never added together."),
  shiny::helpText("Applies across the project using saved Preparation settings. Other unapplied edits are not included. Recalculate diversity and explicitly rebuild stale layers after a rank change."))
}
diversity_rank_pending <- function(input,project,stage) {
 rank<-input[[paste0(stage,"_rank")]]
 !is.null(project)&&!is.null(rank)&&!identical(rank,project$declarations$rank)
}
diversity_apply_rank <- function(project,rank) {
 check_project(project)
 choices<-unname(rank_choices(project$input));choices<-choices[nzchar(choices)]
 if(!is.character(rank)||length(rank)!=1L||is.na(rank)||!rank%in%choices)stop("Choose a supplied terminal rank. No absent ranks are inferred.")
 if(identical(rank,project$declarations$rank))return(project)
 declarations<-project$declarations;declarations$rank<-rank
 retain_analysis(project,prepare_project(project$input,declarations,project$design,project$settings,project$preparation$settings))
}
diversity_context_server <- function(input,output,session,state,status,stage) {
 output[[paste0(stage,"_input_context")]]<-shiny::renderUI(diversity_input_context(state(),stage))
 output[[paste0(stage,"_rank_controls")]]<-shiny::renderUI(diversity_rank_ui(state(),stage))
 output[[paste0(stage,"_rank_pending")]]<-shiny::renderText({
  p<-state();if(diversity_rank_pending(input,p,stage))paste("Rank change pending. Applied input remains",diversity_rank_label(p),"until Apply shared rank.") else ""
 })
 shiny::observeEvent(input[[paste0(stage,"_rank_apply")]],tryCatch({
  p<-state();shiny::req(p);q<-diversity_apply_rank(p,input[[paste0(stage,"_rank")]])
  if(!identical(p,q))state(q)
  status(if(is.null(q$experiment))"Rank applied, but Preparation is blocked. Review Findings or reset Preparation." else if(identical(p,q))"Shared rank is already applied; results are unchanged." else "Shared rank applied. Recalculate Alpha/Beta and rebuild any stale layers when needed.")
 },error=function(e)status(conditionMessage(e))))
 invisible(NULL)
}
diversity_result_message <- function(project,stage,pending=FALSE) {
 result<-project[[stage]]
 if(is.null(result))return(paste("No",stage,"result yet. Calculate to begin."))
 if(result$status=="stale")return("Saved result is stale. Recalculate for the current applied input; exports are blocked.")
 if(result$status=="blocked")return(paste("Calculation blocked:",result$reason))
 if(pending)return(paste("Unapplied",stage,"edits: displayed results still use saved settings; exports are blocked."))
 "Displayed results use applied settings. Plot styles do not refit models."
}
diversity_plot_available <- function(project,stage) {
 result<-project[[stage]]
 !is.null(result)&&result$status%in%c("ready","partial")
}
diversity_plot_panel <- function(project,stage) {
 if(!diversity_plot_available(project,stage))return(shiny::helpText("Calculate a current result to display its plot."))
 if(stage=="beta"&&!identical(project$beta$ordination$status,"ready"))return(shiny::helpText(project$beta$ordination$reason))
 shiny::tagList(shiny::h4(if(stage=="alpha")"Observation plot" else "Ordination plot"),
  if(stage=="alpha")shiny::plotOutput("alpha_plot",height="620px") else shiny::plotOutput("beta_plot",height="560px"))
}
