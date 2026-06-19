## Test environments

- Local macOS, R 4.2.3
- GitHub Actions `R CMD check --no-manual --as-cran` passed on macOS release, Windows release,
  Ubuntu release, and Ubuntu R-devel.

## R CMD check results

- `R CMD check --no-manual agentr_0.2.8.2.tar.gz`: not rerun separately
- `R CMD check --no-manual --as-cran agentr_0.2.8.2.tar.gz`: not rerun separately
- `R CMD check --as-cran agentr_0.2.8.2.tar.gz`: 0 errors, 0 warnings, 2 notes
  in the local sandbox. The notes are from unavailable network-based CRAN/URL checks and inability
  to verify current time.

## Checks still required before CRAN submission

- None known from local and GitHub Actions checks.

The local R 4.2.3 environment uses TinyTeX for PDF manual checks. Network-based incoming checks are
sandbox-dependent.

## Submission notes

This is a resubmission fixing CRAN incoming notes from version 0.2.8.1:

- replaced README relative file links with absolute HTTPS links
- replaced the MIT `LICENSE` text with the CRAN-required DCF stub for `MIT + file LICENSE`
- simplified DESCRIPTION title/wording to avoid spell-check notes in incoming pretests
