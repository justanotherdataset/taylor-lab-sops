# Project-local library selection only; no installation or automatic analysis.
local({
  lib <- file.path(getwd(), ".tester-library")
  if (dir.exists(lib)) .libPaths(c(lib, .Library))
})
