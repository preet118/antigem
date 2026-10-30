# AntiGem Full Ubuntu ARM64 Standalone Workspace

**Implementation status: development candidate, not production verified.**

This branch starts from successful APK build #33 (`c3aafb7`) and builds the **new** `com.antigem.full` APK. It can coexist with old Build #33 (`com.antigem`) and Termux (`com.termux`).
The app uses an internal Ubuntu 24.04 ARM64 rootfs via PRoot; it does **not** uninstall or modify the external Termux app.

## What's now in the proposed full environment

- Core: Bash, APT/dpkg, curl, wget, OpenSSL, SSH client, zip/unzip, tar/xz, jq, ripgrep, fd, Git + Git LFS, useful editors/diagnostics.
- Python 3 with pip/venv and a dedicated venv for Python MCP servers (`mcp`, `uv`/`uvx`, `requests`, `pyyaml`).
- JavaScript/TypeScript: Node.js 22.16.0, npm, npx, TypeScript, tsx, the Node MCP SDK.
- Native languages: GCC/G++, Clang, CMake, Make, Ninja, pkg-config, Rust/Cargo, Go, Java JDK, Kotlin, PHP, Ruby, Lua and R.
- Coding agents: Antigravity CLI (`agy`) and compatible Node-backed Claude Code 2.1.112, without credentials.
- Skills: `/root/.claude/skills` and `/root/.agents/skills`, with a safe local project inspection example. Third-party skills must be selected and installed separately; files here are not proof that all agent versions discover them.
- Artifacts: app-side Markdown/diff/diagrams and browser preview source already present; /root/.cache/antigem-artifacts is an optional workspace output directory.

## Android/Ubuntu integration changes

- PRoot terminal and one-shot executor both mount the app-owned workspace and bridge directory. File permissions are still limited by Android sandbox.
- AGY/Claude/Python venv binaries included on PATH in Ubuntu invocations.
- Installer uses the *new* full image URL and requires release SHA-256 match before installation.
- Installer refuses to mark the full tools installed merely because Bash runs; it checks language toolchains, agent binaries and the built-in bridge asset.
- App backup/restore scripts are adapted to /usr and /root, and are executed inside PRoot for Standard; an Ubuntu bootstrap backup uses the Ubuntu backup script rather than a native-Termux backup script.
- Installer checks aarch64 and 4 GiB free space before beginning. Actual usage may require substantially more; the build must report unpacked size.
- The new Full APK has `com.antigem.full`, so the older Build #33 app (`com.antigem`) and separate Termux app (`com.termux`) and their private files are not touched.

## Build paths

Android APK #34 build:
```bash
./gradlew :app:assembleFullDebug
```

Rootfs builder:
`.github/workflows/build-preconfigured-ubuntu.yml`

Published full release tag **after CI + manual dispatch**:
`antigem-ubuntu24-full-v1`, asset `AntiGem-Ubuntu24-ARM64-Full.tar.gz`, with corresponding `.sha256`.

Important: the app's automatic download **will fail** until the new release is genuinely published. It must not silently fall back to a partial / original Termux ZIP.

## GitHub Actions build #34 — 30 October 2026

- [Build #34](https://github.com/preet118/antigem/actions/runs/41035247371): full-flavor Android APK **built successfully** (`AntiGem-Full-Ubuntu-34-APK`, artifact `12968257182`).
- Ubuntu ARM64 rootfs provisioning failed during `apt install` with exit status 100. Log: `the java command requires a mounted proc fs (/proc)`; Java 21/Kotlin packaging consequently failed.
- **Fixed in subsequent source commit:** bind-mount the GitHub runner's `/proc` before ARM64 chroot provisioning, unmount it **before** archiving to avoid bundling host process metadata, and clean up on failure.
- Also granted workflow permissions to publish the final prerelease only after tests pass.
- **Build #34 did not include the fixes.** Re-running old failed jobs uses the old commit and will not apply them. Start a **new** workflow dispatch on `feature/ubuntu-full-workspace`.
- The full Ubuntu rootfs release is not yet available; do not claim the uploaded APK alone is production-ready.

## Coverage and remaining acceptance tests

| Feature | Source / provisioning | Still needs on-device test |
| --- | --- | --- |
| App UI / settings / editor / file explorer | Android compiled in historical #33 (new changes uncompiled) | startup, storage |
| PRoot terminal + all tools | proposed full build + smoke script | Android 11/other supported devices, long-running jobs |
| Python/Node/Go/Rust/Java/C++/Kotlin/PHP/Ruby/Lua/R | packaged and CLI smoke tests | run from IDE, compile projects |
| Git clone/commit/pull/push | Git + bridge included | auth, project workspaces |
| AGY coding agent | official CLI staged | login, gRPC hub, tool permission, subagents |
| Claude Code | compatible CLI version staged | supported account, stream-json, tool approval, subagents |
| Local browser & terminal MCP | Android-side server source already exists | live MCP handshake, permission prompts, browser automation |
| Python and Node MCP SDKs | provisioned in rootfs | individual MCP server installations and client registration |
| Skills | standard folder layouts | actual provider discovery/selection/invocation |
| Artifacts | existing Android-side renderers | file attachments, Markdown, Mermaid, preview, live edits |
| Rootfs/project/chat backup restore | Ubuntu script route patched | round-trip testing, large backups |
| In-app updater | source preserved from #33 | safe signed update channel still required |

**AI auth, subscriptions, model availability, dynamic tools, downloaded third-party MCP servers and user-specific skills cannot be bundled or guaranteed for every account.**

## Security and storage

- No API keys, account tokens, passwords or previous projects are included in the prebuilt image.
- Do not install or overwrite on an important production device before inspecting the CI logs and a test device.
- Full package image may be very large (several GB once extracted). Keep extra storage for the download, unpacking, caches and projects.
- Do not merge over the user's working Ubuntu branch or `master` until APK CI, rootfs CI, and Android acceptance tests pass.
