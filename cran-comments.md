## Test environments

- Local macOS, R 4.2.3
- GitHub Actions is configured to run `R CMD check --as-cran` on macOS, Windows, Ubuntu, and
  Ubuntu R-devel.

## R CMD check results

- `R CMD check --no-manual agentr_0.2.8.tar.gz`: 0 errors, 0 warnings, 0 notes

## Checks still required before CRAN submission

- Confirm the GitHub Actions `R CMD check --as-cran` matrix passes on current R release and R-devel.
- Run PDF manual checks in an environment with LaTeX and `qpdf`.

The local R 4.2.3 environment can reach CRAN incoming checks when network access is available, but
the full `--as-cran` run stalls in the local `_R_LOAD_CHECK_OVERWRITE_S3_METHODS_` subprocess. The
package load path used by that subprocess succeeds when run directly, so this should be rechecked in
a current CRAN-like environment before submission.

## Submission notes

This is a new submission.
