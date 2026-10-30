#!/usr/bin/env python3
"""Package a new-prefix aarch64 Termux bootstrap with a verified AGY candidate.

The output format is intentionally strict: the APK rejects ordinary com.termux
bootstraps rather than pretending their hardcoded paths work in this application.
This script cannot certify actual Android runtime behavior; device tests remain required.
"""
import argparse
import hashlib
import json
import pathlib
import tempfile
import zipfile

EXPECTED_PACKAGE = "com.antigem.native"
EXPECTED_PREFIX = "/data/data/com.antigem.native/files/usr"
OLD_PREFIX = b"/data/data/com.termux/files/usr"

def digest_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as stream:
        for piece in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(piece)
    return h.hexdigest()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--bootstrap", type=pathlib.Path, required=True)
    parser.add_argument("--agy", type=pathlib.Path, required=True)
    parser.add_argument("--output", type=pathlib.Path, required=True)
    args = parser.parse_args()
    if not args.bootstrap.is_file() or not args.agy.is_file():
        parser.error("A freshly built new-prefix Termux bootstrap and AGY executable are required.")
    agent = args.agy.read_bytes()
    if not agent or OLD_PREFIX in agent:
        parser.error("AGY missing or embeds original com.termux prefix. Rebuild or audit AGY first.")
    if agent.startswith(b"#!") and b"com.termux" in agent[:512]:
        parser.error("AGY script has the old Termux shebang.")
    if agent.startswith(b"\x7fELF") and (len(agent) < 20 or agent[4] != 2 or int.from_bytes(agent[18:20], "little") != 183):
        parser.error("AGY ELF is not a 64-bit AArch64 executable.")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as temp:
        candidate = pathlib.Path(temp) / "bootstrap-aarch64.zip"
        with zipfile.ZipFile(args.bootstrap) as src, zipfile.ZipFile(candidate, "w") as dst:
            names = set(src.namelist())
            if "bin/bash" not in names:
                parser.error("Malformed bootstrap: bin/bash not found.")
            for item in src.infolist():
                if item.filename == "bin/agy":
                    continue
                dst.writestr(item, src.read(item.filename))
            info = zipfile.ZipInfo("bin/agy")
            info.create_system = 3
            info.external_attr = 0o100755 << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            dst.writestr(info, agent)
        sha = digest_file(candidate)
        manifest = {
            "package_id": EXPECTED_PACKAGE,
            "architecture": "aarch64",
            "prefix": EXPECTED_PREFIX,
            "bootstrap_sha256": sha,
            "agent_candidate_sha256": hashlib.sha256(agent).hexdigest(),
            "device_verified": False,
            "notice": "Candidate only. Agent, package manager, and MCP require device verification.",
        }
        with zipfile.ZipFile(args.output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=4) as out:
            out.write(candidate, "bootstrap-aarch64.zip")
            out.writestr("antigem-native.json", json.dumps(manifest, indent=2))
    print(args.output)
    print("Archive SHA256:", digest_file(args.output))
    print("Not production-certified: real device tests are mandatory.")

if __name__ == "__main__":
    main()
