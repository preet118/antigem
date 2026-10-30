#!/usr/bin/env bash
# Checks reproducible CLI dependencies without authentication or destructive operations.
# Run inside the Ubuntu ARM64 rootfs (chroot in CI or PRoot on Android).
set -euo pipefail
export PATH="/root/.local/bin:/root/.venvs/workspace/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
for executable in \
  bash curl python3 pip git git-lfs gcc g++ clang cmake make ninja \
  go javac java rustc cargo node npm npx tsx tsc \
  php ruby lua Rscript kotlinc zip unzip tar ssh uv uvx \
  jq rg fd agy claude; do
  command -v "$executable" >/dev/null || { echo "MISSING: $executable" >&2; exit 30; }
done
python3 -c 'import json,venv,ssl,sqlite3,subprocess,sys; assert sys.version_info.major == 3'
/root/.venvs/workspace/bin/python -c 'import mcp,requests,yaml; assert requests.__version__'
/root/.venvs/workspace/bin/python -m pip --version
node -e 'if (!process.versions.node) process.exit(1)'
npm --version
git --version
gcc --version >/dev/null
g++ --version >/dev/null
clang --version >/dev/null
go version
javac -version
java -version
rustc --version
cargo --version
php --version >/dev/null
ruby --version
lua -v
Rscript --version
kotlinc -version
tsx --version
tsc --version
agy --version
claude --version
test -s /root/.claude/skills/project-check/SKILL.md
test -f /root/.agents/skills/project-check/SKILL.md
test -d /root/.cache/antigem-artifacts
test -d /root/projects
git lfs version
echo "PASS: packaged language runtimes, build tools, basic skill layout, agent CLI versions"
echo "NOT TESTED: Android PRoot, AGY login/hub/subagents, Claude account, MCP calls, interactive app features"
