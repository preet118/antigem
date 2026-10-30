#!/usr/bin/env python3
"""Read-only audit of the developer's original AntiGem rootfs archive.

Processes zip files and one nested ZIP used by the upstream bootstrap,
without extracting executables or credentials to the host.
"""
import argparse
import hashlib
import json
import pathlib
import tempfile
import zipfile

LEGACY = b"/data/data/com.termux/files/"
MAX_CHECK_SIZE = 120 * 1024 * 1024

def scan_zip(path):
    hits = []
    filenames = []
    legacy_paths = []
    with zipfile.ZipFile(path) as src:
        for item in src.infolist():
            filenames.append(item.filename)
            if item.is_dir() or item.file_size > MAX_CHECK_SIZE:
                continue
            if any(item.filename.endswith("/" + name) or item.filename == name for name in ("agy", "python3", "node", "git", "clang", "apt", "bash", "pkg", "claude", "agy_ide_bridge")):
                hits.append({"name": item.filename, "bytes": item.file_size})
            if (item.filename.endswith((".sh", ".conf", ".list", ".py", ".js", ".json", ".txt")) or item.filename.endswith(("/agy", "/bash", "/node", "/python3", "/clang", "/git"))) and LEGACY in src.read(item):
                legacy_paths.append(item.filename)
    return {"entries": len(filenames), "executables": hits, "legacy_prefix_references": legacy_paths[:100], "sample_paths": filenames[:80]}

def sha256(path):
    digest = hashlib.sha256()
    with open(path,"rb") as stream:
        for block in iter(lambda: stream.read(1024*1024), b""):
            digest.update(block)
    return digest.hexdigest()

def main():
    p = argparse.ArgumentParser()
    p.add_argument("archive", type=pathlib.Path)
    p.add_argument("--output", type=pathlib.Path, default=pathlib.Path("rootfs-audit.json"))
    args = p.parse_args()
    report = {"archive": args.archive.name, "sha256": sha256(args.archive), "size_bytes": args.archive.stat().st_size, "outer": scan_zip(args.archive), "inner": []}
    with tempfile.TemporaryDirectory() as tmp, zipfile.ZipFile(args.archive) as outer:
        for item in outer.infolist():
            if item.filename.endswith(".zip") and item.file_size > 0:
                dest = pathlib.Path(tmp) / ("nested-" + str(len(report["inner"])) + ".zip")
                with outer.open(item) as source, dest.open("wb") as target:
                    for block in iter(lambda: source.read(1024*1024), b""):
                        target.write(block)
                try:
                    report["inner"].append({"name": item.filename, "inspection": scan_zip(dest)})
                except zipfile.BadZipFile:
                    report["inner"].append({"name": item.filename, "error": "not a zip"})
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2))
    print("Saved", args.output)
    print("Candidate rootfs executable matches:",sum(len(s["inspection"]["executables"]) for s in report["inner"] if "inspection" in s))
    print("This is an inventory only. It does NOT certify any binary will run in the new package.")

if __name__ == "__main__":
    main()
