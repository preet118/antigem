#!/usr/bin/env bash
# Build a new-prefix Termux bootstrap. Requires Linux + Docker + sufficient disk space.
# This is NOT a relabeling of the original com.termux ZIP.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKDIR="${NATIVE_WORKDIR:-$ROOT/.native-work}"
REPO="$WORKDIR/termux-packages"
PACKAGE_NAME="com.antigem.native"
AGY_BIN="${AGY_BIN:-}"
OUT="$ROOT/output/native-bootstrap"
mkdir -p "$WORKDIR" "$OUT"

for tool in git docker python3; do
    command -v "$tool" >/dev/null || { echo "Missing required build host tool: $tool" >&2; exit 1; }
done
if [[ -z "$AGY_BIN" || ! -f "$AGY_BIN" ]]; then
    echo "FAIL CLOSED: AGY_BIN must point to a verified Android arm64 Antigravity executable." >&2
    echo "It must be checked for relocation and runtime dependencies. The upstream com.termux binary is NOT assumed compatible." >&2
    exit 2
fi
if [[ ! -d "$REPO/.git" ]]; then
    git clone --depth 1 https://github.com/termux/termux-packages.git "$REPO"
fi
python3 - "$REPO/scripts/properties.sh" "$PACKAGE_NAME" <<'PY'
import pathlib,sys,re
p=pathlib.Path(sys.argv[1])
s=p.read_text()
pattern=r'(?m)^TERMUX_APP__PACKAGE_NAME="[^"]+"'
s,n=re.subn(pattern,'TERMUX_APP__PACKAGE_NAME="'+sys.argv[2]+'"',s,count=1)
if n!=1: raise SystemExit("Termux properties layout changed; stop, don't use a stock prefix")
p.write_text(s)
PY
echo "Building native $PACKAGE_NAME bootstrap for aarch64 using Termux sources."
cd "$REPO"
# Include core tools. Other agent-specific dependencies require independent verification.
./scripts/run-docker.sh ./scripts/build-bootstraps.sh -f --architectures aarch64 --add python,nodejs,git,clang,openssh,tmux
test -s bootstrap-aarch64.zip
python3 "$ROOT/scripts/package_native_bootstrap.py" \
    --bootstrap bootstrap-aarch64.zip --agy "$AGY_BIN" \
    --output "$OUT/antigem-native-bootstrap-aarch64.zip"
sha256sum "$OUT/antigem-native-bootstrap-aarch64.zip"
echo "Candidate created. Do NOT publish as complete until on-device agent, npm/pkg/apt, MCP and update checks pass."
