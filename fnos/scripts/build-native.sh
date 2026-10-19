#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${PICOCLAW_FNOS_OUT_DIR:-${ROOT_DIR}/build/fnos}"
GOOS="${GOOS:-linux}"
GOARCH="${GOARCH:-amd64}"
VERSION="${VERSION:-0.2.9}"
FRONTEND_DIR="${ROOT_DIR}/web/frontend"

BIN_DIR="${OUT_DIR}/app/bin"
PACKAGE_DIR="${PICOCLAW_FNOS_PACKAGE_DIR:-${ROOT_DIR}/fnos/picoclaw}"
mkdir -p "${BIN_DIR}"

echo "==> Building PicoClaw native binaries"
echo "    output: ${BIN_DIR}"
echo "    target: ${GOOS}/${GOARCH}"
echo "    version: ${VERSION}"

if ! command -v go >/dev/null 2>&1; then
    echo "error: go not found in PATH (Go 1.25+ is required)" >&2
    exit 1
fi

if ! command -v pnpm >/dev/null 2>&1; then
    echo "error: pnpm not found in PATH" >&2
    exit 1
fi

VERSION_VALUE="${VERSION}"
GIT_COMMIT_VALUE="$(git -C "${ROOT_DIR}" rev-parse --short=8 HEAD 2>/dev/null || echo dev)"
BUILD_TIME_VALUE="$(date +%FT%T%z)"
GO_VERSION_VALUE="$(go env GOVERSION 2>/dev/null || echo unknown)"
CONFIG_PKG="github.com/sipeed/picoclaw/pkg/config"
LDFLAGS="-X ${CONFIG_PKG}.Version=${VERSION_VALUE} -X ${CONFIG_PKG}.GitCommit=${GIT_COMMIT_VALUE} -X ${CONFIG_PKG}.BuildTime=${BUILD_TIME_VALUE} -X ${CONFIG_PKG}.GoVersion=${GO_VERSION_VALUE} -s -w"

export CGO_ENABLED=0
export GOOS
export GOARCH
export GOTOOLCHAIN="${GOTOOLCHAIN:-local}"
export GOCACHE="${GOCACHE:-${ROOT_DIR}/.cache/go-build}"
export GOMODCACHE="${GOMODCACHE:-${ROOT_DIR}/.cache/go-mod}"

echo "==> Building frontend assets"
(
    cd "${FRONTEND_DIR}"
    if [[ ! -d node_modules ]]; then
        pnpm install --frozen-lockfile
    fi
    pnpm build:backend
)

echo "==> Building picoclaw"
(
    cd "${ROOT_DIR}"
    go build -tags goolm,stdjson \
        -ldflags "${LDFLAGS}" \
        -o "${BIN_DIR}/picoclaw" \
        ./cmd/picoclaw
)

echo "==> Building picoclaw-launcher"
(
    cd "${ROOT_DIR}"
    go build -tags goolm,stdjson \
        -ldflags "${LDFLAGS}" \
        -o "${BIN_DIR}/picoclaw-launcher" \
        ./web/backend
)

chmod +x "${BIN_DIR}/picoclaw" "${BIN_DIR}/picoclaw-launcher"

if [[ -d "${PACKAGE_DIR}/app" ]]; then
    mkdir -p "${PACKAGE_DIR}/app/bin"
    cp -f "${BIN_DIR}/picoclaw" "${PACKAGE_DIR}/app/bin/picoclaw"
    cp -f "${BIN_DIR}/picoclaw-launcher" "${PACKAGE_DIR}/app/bin/picoclaw-launcher"
    chmod +x "${PACKAGE_DIR}/app/bin/picoclaw" "${PACKAGE_DIR}/app/bin/picoclaw-launcher"
    echo "==> Binaries copied to ${PACKAGE_DIR}/app/bin"
else
    echo "warning: fnOS package directory not found: ${PACKAGE_DIR}" >&2
    echo "hint: run 'cd fnos && fnpack create picoclaw' first" >&2
fi

echo "==> Native build complete"
ls -lh "${BIN_DIR}"
