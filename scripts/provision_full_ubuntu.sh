#!/usr/bin/env bash
# Provision the official Ubuntu 24.04 arm64 rootfs inside a GitHub ARM64 chroot.
# Requires networking and genuine root privileges. No Android user data is touched.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update -qq

# Code editor run buttons, git source control, build systems, backups and MCP dependencies.
apt-get install -y --no-install-recommends \
  bash ca-certificates curl wget openssl gnupg \
  procps psmisc lsof iproute2 net-tools \
  xz-utils bzip2 gzip tar zip unzip p7zip-full rsync \
  nano vim-tiny less file jq ripgrep fd-find tmux zsh screen sqlite3 \
  git git-lfs openssh-client \
  python3 python3-pip python3-venv python3-dev python-is-python3 \
  build-essential clang cmake ninja-build pkg-config \
  golang-go default-jdk-headless \
  rustc cargo \
  php-cli ruby lua5.4 r-base-core \
  kotlin

# Python's system site-packages are externally managed; install skill/MCP dependencies in a venv.
python3 -m venv /root/.venvs/workspace
/root/.venvs/workspace/bin/python -m pip install --disable-pip-version-check --no-cache-dir --upgrade pip setuptools wheel
# Common MCP server runtimes (users can add individual MCP servers later).
/root/.venvs/workspace/bin/python -m pip install --disable-pip-version-check --no-cache-dir mcp uv requests pyyaml

# Familiar CLI names used by AntiGem's run configurations and agents.
if ! command -v lua >/dev/null 2>&1; then
  ln -s /usr/bin/lua5.4 /usr/local/bin/lua
fi
if ! command -v fdfind >/dev/null 2>&1; then
  echo "fdfind missing" >&2
  exit 1
fi
if ! command -v fd >/dev/null 2>&1; then
  ln -s /usr/bin/fdfind /usr/local/bin/fd
fi
git lfs install --system

# Match the previously successful rootfs's Node & Claude versions.
NODE_VERSION=22.16.0
curl -fLsS --retry 3 "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-arm64.tar.xz" -o /tmp/antigem-node.tar.xz
tar -xJf /tmp/antigem-node.tar.xz -C /usr/local --strip-components=1
node --version
npm --version
npm install -g --no-audit --no-fund typescript tsx @modelcontextprotocol/sdk@1
# AntiGem's bundled bridge explicitly looks for /root/.local/bin/claude.
mkdir -p /root/.local
npm install -g --prefix /root/.local --no-audit --no-fund @anthropic-ai/claude-code@2.1.112
test -x /root/.local/bin/claude
mkdir -p /root/.local/bin
curl -fLsS --retry 3 https://antigravity.google/cli/install.sh -o /tmp/antigem-agy-install.sh
bash /tmp/antigem-agy-install.sh
test -x /root/.local/bin/agy

# No credentials in the image; support the standard user-configurable skill directories.
mkdir -p /root/.claude/skills /root/.agents/skills /root/projects /root/.cache/antigem-artifacts
cat >/etc/profile.d/antigem-workspace.sh <<'EOF'
export PATH="/root/.local/bin:/root/.venvs/workspace/bin:$PATH"
export PIP_DISABLE_PIP_VERSION_CHECK=1
EOF
cat >/root/.bashrc <<'EOF'
[ -f /etc/profile.d/antigem-workspace.sh ] && . /etc/profile.d/antigem-workspace.sh
export PS1='[AntiGem Ubuntu] \w $ '
EOF

# Skill installed as a plain Markdown document; no untrusted MCP server is auto-started.
mkdir -p /root/.claude/skills/project-check
cat >/root/.claude/skills/project-check/SKILL.md <<'EOF'
---
name: project-check
description: Inspect a workspace, identify build tools and recommend safe verification commands.
---
When asked to inspect a project, first list its files and read manifest files.
Never run destructive commands. Check the available tooling before suggesting tests.
Ask permission before installing dependencies or changing project files.
EOF
mkdir -p /root/.agents/skills/project-check
cp /root/.claude/skills/project-check/SKILL.md /root/.agents/skills/project-check/SKILL.md

# Remove build caches and temporary credential-free installers.
rm -f /tmp/antigem-node.tar.xz /tmp/antigem-agy-install.sh
apt-get clean
rm -rf /var/lib/apt/lists/* /root/.npm /root/.cache/pip
echo "AntiGem full Ubuntu toolchain installed. Login and Android-specific testing still required."
