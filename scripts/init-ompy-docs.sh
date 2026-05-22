#!/usr/bin/env bash
# Initialize a project with ompy_docs (bash). Forwards all args to ompy_docs_cli.py init.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
export OMPY_DOCS_ROOT="${REPO_ROOT}"

if command -v python3 >/dev/null 2>&1; then
  PYTHON=python3
elif command -v python >/dev/null 2>&1; then
  PYTHON=python
else
  echo "Python 3 is required on PATH." >&2
  exit 1
fi

exec "${PYTHON}" "${SCRIPT_DIR}/ompy_docs_cli.py" init "$@"
