## Test environments

- Local macOS, R 4.2.3
- GitHub Actions `R CMD check --no-manual --as-cran` passed on macOS release, Windows release,
  Ubuntu release, and Ubuntu R-devel.

## R CMD check results

- `R CMD check --no-manual agentr_0.2.8.1.tar.gz`: 0 errors, 0 warnings, 0 notes
- `R CMD check --no-manual --as-cran agentr_0.2.8.1.tar.gz`: 0 errors, 0 warnings, 2 notes
  in the local sandbox. The notes are from unavailable network-based CRAN/URL checks and inability
  to verify current time.

## Checks still required before CRAN submission

- Run PDF manual checks in an environment with LaTeX and `qpdf`.

The local R 4.2.3 environment does not have a full CRAN submission toolchain: network-based incoming
checks are sandbox-dependent, and LaTeX/`qpdf` are not installed.

## Submission notes

This is a new submission.
