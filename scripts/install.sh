#!/usr/bin/env bash
# Install ompy_docs CLI wrappers into ~/.local/bin (Unix) or print PATH hint.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BIN_DIR="${HOME}/.local/bin"
mkdir -p "${BIN_DIR}"

link_or_copy() {
  local src="$1"
  local name="$2"
  local dest="${BIN_DIR}/${name}"
  if [[ -L "${dest}" || -f "${dest}" ]]; then
    rm -f "${dest}"
  fi
  ln -sf "${src}" "${dest}"
  chmod +x "${src}" 2>/dev/null || true
}

link_or_copy "${SCRIPT_DIR}/init-ompy-docs.sh" "init-ompy-docs"
link_or_copy "${SCRIPT_DIR}/build-ompy-docs.sh" "build-ompy-docs"
link_or_copy "${SCRIPT_DIR}/ompy_docs_cli.py" "ompy-docs"

cat <<EOF

Installed ompy_docs wrappers to:
  ${BIN_DIR}

Commands (add to PATH if needed):
  init-ompy-docs --project-path . --package-name mypkg
  build-ompy-docs
  ompy-docs init|build ...

Repo (templates): ${REPO_ROOT}
Ensure ~/.local/bin is on your PATH.

EOF
