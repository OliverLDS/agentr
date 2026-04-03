.libPaths(c("/tmp/agentr-r-lib", .libPaths()))

library(testthat)
library(agentr)

test_check("agentr")
