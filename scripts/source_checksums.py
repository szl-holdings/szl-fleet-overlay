#!/usr/bin/env python3
"""Generate or verify the cross-platform SZL source checksum manifest."""

from __future__ import annotations

import argparse
import hashlib
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "receipts" / "checksums.txt"
EXTRA_PATHS = (
    "zarf.yaml",
    "uds-bundle.yaml",
    "tasks.yaml",
    "receipts/doctrine-pin.yaml",
    "scripts/source_checksums.py",
)
LINE_RE = re.compile(r"^([0-9a-f]{64})  ([^\x00\r\n]+)$")


def covered_paths() -> list[str]:
    paths: set[str] = set(EXTRA_PATHS)
    for directory in ("configs", "chart", "uds-packages"):
        for path in (ROOT / directory).rglob("*"):
            if path.is_file() and path.suffix in {".yaml", ".tpl"}:
                paths.add(path.relative_to(ROOT).as_posix())
    return sorted(paths)


def canonical_bytes(path: Path) -> bytes:
    """Normalize text line endings only; preserve every other source byte."""
    return path.read_bytes().replace(b"\r\n", b"\n").replace(b"\r", b"\n")


def digest(relative_path: str) -> str:
    return hashlib.sha256(canonical_bytes(ROOT / relative_path)).hexdigest()


def render() -> str:
    return "".join(f"{digest(path)}  {path}\n" for path in covered_paths())


def write_manifest() -> None:
    MANIFEST.write_text(render(), encoding="utf-8", newline="\n")
    print(f"wrote {len(covered_paths())} canonical source checksums")


def verify_manifest() -> None:
    lines = MANIFEST.read_text(encoding="utf-8").splitlines()
    expected_paths = covered_paths()
    if len(lines) != len(expected_paths):
        raise SystemExit(
            f"checksum path count mismatch: expected {len(expected_paths)}, got {len(lines)}"
        )
    actual_paths: list[str] = []
    for line in lines:
        match = LINE_RE.fullmatch(line)
        if not match:
            raise SystemExit(f"malformed checksum line: {line!r}")
        expected_digest, relative_path = match.groups()
        actual_paths.append(relative_path)
        actual_digest = digest(relative_path)
        if actual_digest != expected_digest:
            raise SystemExit(
                f"checksum mismatch for {relative_path}: "
                f"expected {expected_digest}, got {actual_digest}"
            )
    if actual_paths != expected_paths:
        raise SystemExit("checksum paths are missing, extra, duplicated, or unsorted")
    print(f"verified {len(lines)} canonical source checksums")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=("check", "write"), nargs="?", default="check")
    args = parser.parse_args()
    if args.command == "write":
        write_manifest()
    else:
        verify_manifest()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
