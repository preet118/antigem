# AntiGem Native Standalone — coexistence development status

**Status: IN DEVELOPMENT — NOT a verified finished APK.** Do not uninstall the existing Termux app, erase data, or treat a debug artifact as complete.

## Goal

Build a new Android package `com.antigem.shell` that runs an **independently owned native Termux-compatible Linux environment**, retaining AntiGem's Android UI, workspace, editor, browser/MCP, agent backends and other features. The original `com.termux` installed on the device stays untouched.

## Done in this development branch

- Added a third `standalone` Android flavor, with isolated applicationId and loopback ports.
- Switched this flavor to native Termux shell mode rather than Ubuntu PRoot.
- Added a separate bootstrap URL and **refused unlabelled legacy `com.termux` archives**.
- Added a checksum and package-prefix/arch marker check to the installer.
- Changed native Linux prefix to `/data/data/com.antigem.shell/files/usr` for primary Android user.
- Improved installer verification: required tools include bash, python3, node, npm, git, clang, agy, apt, pkg.
- Fixed a Termux API dispatcher hardcoding `com.termux`.
- Added a Linux/Docker helper for re-building a custom Termux bootstrap and Python packaging helper.
- Added Android debug build workflow.

## Additional patches made during review

- Fixed an installer ordering bug: package-specific outer ZIP validation now runs **before** the installer deletes the outer ZIP when unwrapping a nested bootstrap.
- Fixed native AGY/Go Bridge/Claude binary default paths in AuthPreferences.
- Rewrites only the copied **text** backup/restore scripts to use the new app-owned prefix, leaving executable binaries untouched.
- Prevents custom standalone from offering an upstream **standard** APK as an update until a signed custom update channel is operational.
- Added read-only `scripts/native_feature_smoke.sh` for command-line smoke checks on Android.
- Added `scripts/audit_original_rootfs.py` and `.github/workflows/audit-original-rootfs.yml` to inventory official source ZIP contents before claiming feature parity.
- GitHub Actions has **not** run on this branch yet; there is no proven successful APK or runtime bootstrap from these changes.

## Still required before this project can be called complete

1. Build aarch64 Termux packages **from source for the new prefix**. Stock Termux package repository is compiled for `com.termux`, so updating packages from stock mirrors would break this standalone. A compatible custom package repository (or locked prebuilt base) is needed.
2. Analyze original AntiGem bootstrap and AGY binary, including hardcoded paths, architecture, dependent libraries, permissions and shell scripts. The packager refuses an AGY binary containing the old hardcoded prefix; it does **not** prove every transitive dependency is safe.
3. Produce & publish verified `native-rootfs-v1/antigem-native-bootstrap-aarch64.zip`. The auto-download link will fail until that real release exists.
4. Verify correct executable installation, Node, Python, package manager, Antigravity login/gRPC bridge, Claude (when supported), MCP, project access, browser, backups, tools and updates on real Android 11+ hardware.
5. Review hardcoded `com.termux` occurrences in the rest of the app's integrations and scripts. Terms that are **class names** can stay; absolute paths/explicit component targets may not.
6. Add reliable sign/release strategy for update compatibility, and implement authenticated/bootstrap rollback across failed installs.

## Development commands

To build the Android package *only*:

```bash
./gradlew :app:assembleStandaloneDebug
```

To attempt the custom prefix Termux bootstrap on a Linux machine with Docker and ample storage, once AGY has been audited:

```bash
AGY_BIN=/path/to/verified/arm64/agy bash scripts/build_native_bootstrap.sh
```

This is a **candidate**, not a full original AntiGem environment or production-ready package. Do not publish until runtime testing and any dependencies are complete.

## Why this cannot be fixed by changing Android applicationId only

Termux packages, shebangs, executables, native libraries and package managers reference fixed filesystem paths. The package builder must be configured for the new app ID and binaries rebuilt. A relabelled copy of the original 351MB rootfs does not satisfy this requirement.

References:
- https://github.com/termux/termux-packages/wiki/For-maintainers
- https://github.com/termux/termux-packages/wiki/Termux-file-system-layout
- https://github.com/Santoshkurmi/antigem/releases/tag/rootfs-v1
