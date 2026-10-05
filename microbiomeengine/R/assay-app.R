assay_ui <- function() shiny::tagList(shiny::hr(),shiny::h3("Named assay layers"),
 shiny::p("Create a separate transformed layer from the applied prepared measurements. Alpha, Beta and Composition keep their existing inputs."),
 shiny::uiOutput("assay_controls"),shiny::textOutput("assay_formula"),shiny::actionButton("assay_apply","Create named layer",class="btn-primary"),shiny::actionButton("assay_rebuild","Rebuild stale layers"),shiny::textOutput("assay_status"),
 shiny::div(class="table-wrap",shiny::tableOutput("assay_registry")),shiny::uiOutput("assay_selection"),shiny::verbatimTextOutput("assay_provenance"),
 shiny::tableOutput("assay_summary"),shiny::tags$details(shiny::tags$summary("Inspect transformed values (first 200 rows; download contains all)"),shiny::div(class="table-wrap",shiny::tableOutput("assay_values"))),
 shiny::downloadButton("assay_values_download","Download layer values"),shiny::downloadButton("assay_code_download","Download applied R code"),
 shiny::tags$details(shiny::tags$summary("Code and standalone bundle"),shiny::verbatimTextOutput("assay_code"),shiny::textInput("assay_export_path","New assay bundle folder (full path)",""),shiny::actionButton("assay_export","Export assay bundle")),
 shiny::helpText("Hellinger closes only its new layer over retained named features. Original denominator, removed mass and supplied Unclassified remain unchanged. Log/CLR values are not abundance or counts. Metadata transformations are a later chunk."))
assay_server <- function(input,output,session,state,status) {
 message<-shiny::reactiveVal("Choose settings, review the formula, then create a new named layer.")
 applied<-shiny::reactiveVal(NULL)
 settings<-shiny::reactive(list(name=input$assay_name,source=input$assay_source,method=input$assay_method,units=input$assay_units,zero_policy=input$assay_zero,pseudocount=input$assay_pseudocount))
 safe<-function(expr)tryCatch(force(expr),error=function(e){message(paste("Blocked:",conditionMessage(e)));status(conditionMessage(e))})
 output$assay_controls<-shiny::renderUI({p<-state();shiny::req(p)
  sources<-intersect(c("relative","estimated_reads"),if(is.null(p$experiment))character() else SummarizedExperiment::assayNames(p$experiment))
  layers<-names(Filter(function(z)z$status=="ready"&&z$settings$method=="hellinger",p$assay_layers));sources<-c(sources,layers)
  shiny::tagList(shiny::fluidRow(shiny::column(4,shiny::textInput("assay_name","New layer name","")),shiny::column(4,shiny::selectInput("assay_source","Transformation source",sources,selectize=FALSE)),shiny::column(4,shiny::selectInput("assay_method","Transformation",c("Hellinger"="hellinger","Natural log"="log","CLR"="clr"),selectize=FALSE))),
   shiny::fluidRow(shiny::column(4,shiny::uiOutput("assay_units_control")),shiny::column(4,shiny::selectInput("assay_zero","Zero policy",c("No addition (log/CLR require positive values)"="positive","Add explicit pseudocount to every value"="add"),selectize=FALSE)),shiny::column(4,shiny::numericInput("assay_pseudocount","Pseudocount in selected source units",0,min=0,step=.001))))
 })
 output$assay_units_control<-shiny::renderUI({source<-input$assay_source;shiny::req(source);shiny::selectInput("assay_units","Source units",if(source=="relative")c("Proportion"="proportion","Percentage"="percentage") else if(source=="estimated_reads")c("Estimated reads"="estimated_reads") else c("Derived Hellinger units"="derived"),selectize=FALSE)})
 output$assay_formula<-shiny::renderText({shiny::req(input$assay_method);paste("Pending formula:",assay_formula(input$assay_method),"; c =",input$assay_pseudocount,input$assay_units)})
 shiny::observeEvent(input$assay_apply,safe({s<-settings();p<-apply_assay(state(),s);state(p);applied(s);message(paste("Applied layer",s$name,". Values below are saved results."))}))
 shiny::observeEvent(input$assay_rebuild,safe({state(rebuild_assays(state()));message("All saved layer recipes rebuilt on the current prepared source.")}))
 output$assay_status<-shiny::renderText({s<-settings();a<-applied();stale<-sum(vapply(state()$assay_layers,function(z)z$status!="ready",logical(1)));if(stale)return(paste(stale,"stale layers: values and exports are unavailable until an explicit rebuild succeeds."));paste(message(),if(!is.null(a)&&!identical(s,a))"Creation controls are pending; existing layers below are unchanged." else "")})
 output$assay_registry<-shiny::renderTable({shiny::req(state());assay_summary(state())},digits=8)
 output$assay_selection<-shiny::renderUI({shiny::req(state());shiny::selectInput("assay_selected","Inspect applied layer",names(state()$assay_layers),selectize=FALSE)})
 layer<-shiny::reactive({p<-state();shiny::req(p,input$assay_selected);z<-p$assay_layers[[input$assay_selected]];shiny::req(z);z})
 output$assay_provenance<-shiny::renderText({z<-layer();paste(z$status,z$source_meaning,paste("Rank",z$rank,"|",length(z$samples),"samples |",length(z$features),"named features"),z$formula,z$normalization,paste("Parent:",z$parent),z$reason,sep="\n")})
 output$assay_summary<-shiny::renderTable({z<-layer();shiny::req(z$status=="ready");z$summary},digits=8)
 output$assay_values<-shiny::renderTable({z<-layer();shiny::req(z$status=="ready");utils::head(assay_values(state(),input$assay_selected),200)},digits=10)
 output$assay_code<-shiny::renderText({shiny::req(state());paste(assay_code(state()),collapse="\n")})
 output$assay_values_download<-shiny::downloadHandler(filename=function()paste0(input$assay_selected,"-values.tsv"),content=function(file)write_assay_table(assay_values(state(),input$assay_selected),file))
 output$assay_code_download<-shiny::downloadHandler(filename=function()"assay-code.R",content=function(file){assays_current(state());writeLines(assay_code(state()),file)})
 shiny::observeEvent(input$assay_export,safe({export_assays(state(),input$assay_export_path);message(paste("Assay export complete:",input$assay_export_path))}))
 invisible(NULL)
}
