#!/usr/bin/env bash
# Read-only smoke tests; run inside new standalone AntiGem terminal.
set -u
pass=0; fail=0; skip=0
check() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then echo "PASS $name"; pass=$((pass+1)); else echo "FAIL $name"; fail=$((fail+1)); fi; }
expected=/data/data/com.antigem.shell/files/usr
check "native-prefix" test "${PREFIX:-}" = "$expected"
check "native-home" test "${HOME:-}" = /data/data/com.antigem.shell/files/home
for tool in bash python3 node npm git clang apt pkg agy agy_ide_bridge tar zip unzip; do check "$tool exists" command -v "$tool"; done
check "Python runs" python3 -c "import sys; assert sys.version_info.major==3"
check "Node runs" node -e "process.exit(process.versions.node ? 0 : 1)"
check "NPM runs" npm --version
check "Git runs" git --version
check "Clang runs" clang --version
check "Bash runs" bash --version
check "Go bridge exists" test -x "$expected/bin/agy_ide_bridge"
check "AGY exists" test -x "$expected/bin/agy"
check "Home writable" test -w "${HOME:-/nonexistent}"
check "No legacy Termux PATH" bash -c 'case ":$PATH:" in *":/data/data/com.termux/files/usr/bin:"*) exit 1;; *) exit 0;; esac'
echo "SKIP interactive AGY login, agent stream, Claude auth, editor, MCP, browser, backup restore, Android permissions"
echo "SUMMARY pass=$pass fail=$fail"
test "$fail" = 0 || exit 1
echo "CLI smoke tests passed; this is NOT a full-feature certification."
