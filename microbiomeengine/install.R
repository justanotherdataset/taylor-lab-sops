# Run source("install.R") from the microbiomeengine RStudio project.
(function() {
  root <- normalizePath(getwd(), winslash="/", mustWork=TRUE)
  description <- file.path(root, "DESCRIPTION")
  if (!file.exists(description) || read.dcf(description)[1,"Package"] != "microbiomeengine")
    stop("Open microbiomeengine.Rproj, then run source('install.R') in its R console.")
  if (getRversion() < "4.6.0" || getRversion() >= "4.7.0")
    stop("This tester release requires R 4.6.x with Bioconductor 3.23. Install that R version and select it in RStudio before retrying.")
  lib <- file.path(root, ".tester-library")
  if (!dir.exists(lib) && !dir.create(lib)) stop("Cannot create the project library: ", lib)
  previous <- .libPaths()
  .libPaths(c(lib, .Library))
  repos <- getOption("repos"); timeout <- getOption("timeout")
  old_user <- Sys.getenv("R_LIBS_USER", unset=NA_character_)
  on.exit({
    options(repos=repos, timeout=timeout)
    if (is.na(old_user)) Sys.unsetenv("R_LIBS_USER") else Sys.setenv(R_LIBS_USER=old_user)
  }, add=TRUE)
  options(repos=c(CRAN="https://cloud.r-project.org"), timeout=max(600, timeout))
  Sys.setenv(R_LIBS_USER=lib)
  type <- if (.Platform$OS.type=="windows" || Sys.info()[["sysname"]]=="Darwin") "binary" else "source"
  started <- Sys.time()
  tryCatch({
    if (!file.exists(file.path(lib, "BiocManager", "DESCRIPTION")))
      install.packages("BiocManager", lib=lib, type=type)
    if (!requireNamespace("BiocManager", quietly=TRUE)) stop("BiocManager installation failed.")
    d <- read.dcf(description)
    fields <- intersect(c("Depends","Imports","LinkingTo","Suggests"), colnames(d))
    deps <- unique(trimws(sub("\\s*\\(.*", "", unlist(strsplit(paste(d[1,fields], collapse=","), ",")))))
    base <- installed.packages(lib.loc=.Library)
    base <- rownames(base)[!is.na(base[,"Priority"])]
    deps <- setdiff(deps[nzchar(deps)], c("R", base))
    message("Installing dependencies from public repositories into ", lib)
    BiocManager::install(deps, lib=lib, version="3.23", ask=FALSE,
                         update=FALSE, type=type, Ncpus=1L)
    missing <- deps[!vapply(deps, requireNamespace, logical(1), quietly=TRUE)]
    if (length(missing)) stop("Dependencies not available: ", paste(missing, collapse=", "))
    install.packages(root, lib=lib, repos=NULL, type="source")
    if (!requireNamespace("microbiomeengine", quietly=TRUE) ||
        normalizePath(dirname(find.package("microbiomeengine")), winslash="/") != normalizePath(lib, winslash="/"))
      stop("The engine did not install into the project library.")
    ip <- installed.packages(lib.loc=lib)
    write.table(ip[,c("Package","Version","License","Built"),drop=FALSE],
                file.path(root,"installed-versions.tsv"), sep="\t", quote=TRUE, row.names=FALSE)
    message("Setup completed in ", round(as.numeric(difftime(Sys.time(),started,units="mins")),1),
            " minutes. Run microbiomeengine::run_app().")
    message("installed-versions.tsv records this installation; it is not an exact-version restore lock.")
  }, error=function(e) {
    .libPaths(previous)
    stop("Setup did not complete: ", conditionMessage(e),
         "\nCheck internet access, free disk space, R 4.6.x and Bioconductor 3.23. Binary dependencies are requested on Windows/macOS; source dependencies on Linux require their system build tools. Keep the full console output when reporting the failure. Existing packages were not deleted.", call.=FALSE)
  })
})()
