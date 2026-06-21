#!/usr/bin/env bash
set -euo pipefail

reapply=false
if [[ $# -eq 2 && "$1" == "--reapply" ]]; then
  reapply=true
  shift
fi

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 [--reapply] /path/to/RFdiffusion" >&2
  exit 2
fi

target_repo="$1"
patch_repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
patch_file="${patch_repo}/patches/px-rfdiffusion.patch"

if [[ ! -d "${target_repo}" ]]; then
  echo "Target path does not exist: ${target_repo}" >&2
  exit 2
fi

if [[ ! -f "${target_repo}/scripts/run_inference.py" ]]; then
  echo "Target path does not look like an RFdiffusion checkout: ${target_repo}" >&2
  exit 2
fi

if git -C "${target_repo}" apply --whitespace=nowarn --check "${patch_file}" 2>/dev/null; then
  git -C "${target_repo}" apply --whitespace=nowarn "${patch_file}"
  echo "Applied ${patch_file} to ${target_repo}"
  exit 0
fi

if git -C "${target_repo}" apply --whitespace=nowarn --reverse --check "${patch_file}" 2>/dev/null; then
  if [[ "${reapply}" == true ]]; then
    git -C "${target_repo}" apply --whitespace=nowarn --reverse "${patch_file}"
    git -C "${target_repo}" apply --whitespace=nowarn "${patch_file}"
    echo "Reapplied ${patch_file} to ${target_repo}"
    exit 0
  fi
  echo "Patch already appears to be applied to ${target_repo}"
  exit 0
fi

echo "Patch cannot be applied cleanly to ${target_repo}." >&2
echo "This usually means the checkout is not at the expected RFdiffusion base commit," >&2
echo "or the patch was partially applied. Inspect with:" >&2
echo "  git -C ${target_repo} status --short" >&2
echo "  git -C ${target_repo} apply --check ${patch_file}" >&2
exit 1
