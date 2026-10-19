#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PACKAGE_DIR="${1:-${ROOT_DIR}/fnos/picoclaw}"
OUT_DIR="${PICOCLAW_FNOS_DIST_DIR:-${ROOT_DIR}/dist/fnos}"
FNPACK_BIN="${FNPACK_BIN:-fnpack}"

if [[ ! -d "${PACKAGE_DIR}" ]]; then
    echo "error: package directory does not exist: ${PACKAGE_DIR}" >&2
    echo "hint: run 'fnpack create picoclaw' first" >&2
    exit 1
fi

if ! command -v "${FNPACK_BIN}" >/dev/null 2>&1; then
    echo "error: fnpack not found in PATH" >&2
    echo "hint: download fnpack from https://developer.fnnas.com/docs/cli/fnpack/" >&2
    exit 1
fi

mkdir -p "${OUT_DIR}"

echo "==> Building fpk from ${PACKAGE_DIR}"
"${FNPACK_BIN}" build --directory "${PACKAGE_DIR}"

PACKAGE_BASENAME="$(basename "${PACKAGE_DIR}")"

# fnpack writes the output into its current working directory, which is the
# repository root when this script is called as documented.
FPK_SOURCE="${PWD}/${PACKAGE_BASENAME}.fpk"
if [[ ! -f "${FPK_SOURCE}" ]]; then
    FPK_SOURCE="$(find "${PACKAGE_DIR}" -maxdepth 2 -type f -name '*.fpk' -print -quit)"
fi
if [[ ! -f "${FPK_SOURCE}" ]]; then
    FPK_SOURCE="$(find "${PWD}" -maxdepth 1 -type f -name '*.fpk' -print -quit)"
fi

if [[ -z "${FPK_SOURCE}" || ! -f "${FPK_SOURCE}" ]]; then
    echo "error: fnpack completed but no .fpk file was found" >&2
    exit 1
fi

cp -f "${FPK_SOURCE}" "${OUT_DIR}/"

# fnpack writes into its working directory; keep the canonical output in the
# ignored dist directory instead of leaving an untracked artifact at the repo
# root.
if [[ "${FPK_SOURCE}" != "${OUT_DIR}/$(basename "${FPK_SOURCE}")" ]]; then
    rm -f "${FPK_SOURCE}"
fi

echo "==> fpk copied to ${OUT_DIR}/$(basename "${FPK_SOURCE}")"
