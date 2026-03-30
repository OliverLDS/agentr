#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
LOCAL_LIB="${AGENTR_LOCAL_LIB:-/tmp/agentr-r-lib}"

if [ ! -d "$LOCAL_LIB" ]; then
  echo "Missing local verification library: $LOCAL_LIB" >&2
  echo "Install local verification packages first." >&2
  exit 1
fi

export LC_ALL=C
export R_LIBS="$LOCAL_LIB${R_LIBS+:$R_LIBS}"

cd "$ROOT_DIR"

Rscript -e 'roxygen2::roxygenise()'
Rscript -e 'testthat::test_local()'
rm -rf agentr.Rcheck
R CMD build .
PKG_TARBALL=$(ls -t agentr_*.tar.gz | head -n 1)
R CMD check "$PKG_TARBALL" --no-manual
