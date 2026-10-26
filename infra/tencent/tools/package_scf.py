#!/usr/bin/env python3
"""Package an already-built pnpm deploy directory for Tencent SCF Node 24.

Build/test only; this script never accesses cloud or local cloud credentials.
The artifact deliberately contains no DATABASE_URL, private keys or .env files.
"""
import argparse
import hashlib
import os
from pathlib import Path
import stat
import zipfile

BOOTSTRAP = "#!/bin/sh\ncd /var/user\nexport HOST=0.0.0.0\nexport PORT=9000\nexec node dist/main.js\n"
REQUIRED = ("dist/main.js", "dist/generated/prisma/client.js")
SKIP_DIRS = {".git", ".cache", ".pnpm-store"}


def check_path(relative: Path) -> None:
    parts = relative.parts
    name = relative.name.lower()
    if name in {".env", ".env.local", ".env.production", "credentials.json", "id_rsa", "id_ed25519"}:
        raise ValueError(f"Sensitive file name found: {relative.as_posix()}")
    if name.startswith(".env.") and not name.endswith(".example"):
        raise ValueError(f"Sensitive env file name found: {relative.as_posix()}")
    if name.endswith((".pem", ".key", ".p12", ".pfx")):
        raise ValueError(f"Potential credential material in bundle: {relative.as_posix()}")
    if any(part in SKIP_DIRS for part in parts):
        raise ValueError(f"Forbidden build path: {relative.as_posix()}")


def package(root: Path, output: Path) -> tuple[int, str]:
    stage = root.resolve(strict=True)
    if not stage.is_dir():
        raise ValueError("Staging root must be a directory")
    if output.resolve() == stage or stage in output.resolve().parents:
        raise ValueError("Output must be outside staging root")
    if output.exists():
        raise ValueError("Output already exists; choose an unused filename")
    for name in REQUIRED:
        if not (stage / name).is_file():
            raise ValueError(f"Required compiled file missing: {name}")
    output.parent.mkdir(parents=True, exist_ok=True)
    count = 0
    with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        bootstrap = zipfile.ZipInfo("scf_bootstrap")
        bootstrap.create_system = 3
        bootstrap.external_attr = (stat.S_IFREG | 0o755) << 16
        archive.writestr(bootstrap, BOOTSTRAP)
        count += 1
        for base, directories, files in os.walk(stage, followlinks=False):
            # Windows os.walk can traverse pnpm directory junctions even with
            # followlinks=False. Emit junction entries once; never descend.
            entries = sorted(directories + files)
            directories[:] = [
                name for name in directories
                if not (Path(base) / name).is_symlink()
                and not (Path(base) / name).is_junction()
                and name not in SKIP_DIRS
                and not (Path(base).relative_to(stage).parts == ("node_modules",) and name == ".bin")
            ]
            for name in entries:
                path = Path(base) / name
                relative = path.relative_to(stage)
                if relative.parts[:2] == ("node_modules", ".bin"):
                    continue
                check_path(relative)
                # pnpm relies on symlinks. Keep relative links, never follow
                # junctions or links escaping the production-only stage.
                if path.is_symlink() or path.is_junction():
                    target = path.resolve(strict=True)
                    if not target.is_relative_to(stage):
                        raise ValueError(f"Symlink escapes stage: {relative.as_posix()}")
                    # Windows pnpm directory junctions are encoded as Unix
                    # symlinks with RELATIVE in-stage targets for SCF Linux.
                    link = os.path.relpath(str(target), str(path.parent.resolve())).replace("\\", "/")
                    info = zipfile.ZipInfo(relative.as_posix())
                    info.create_system = 3
                    info.external_attr = (stat.S_IFLNK | 0o777) << 16
                    archive.writestr(info, link)
                    count += 1
                elif path.is_file():
                    archive.write(path, relative.as_posix())
                    count += 1
        names = set(archive.namelist())
        if not all(name in names for name in REQUIRED):
            raise ValueError("Required runtime files missing from ZIP")
    digest = hashlib.sha256(output.read_bytes()).hexdigest()
    return count, digest


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--stage", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    try:
        count, digest = package(args.stage, args.output)
    except (ValueError, OSError) as error:
        if args.output.exists() and "Output already exists" not in str(error):
            args.output.unlink()
        raise SystemExit(f"SCF packaging rejected: {error}") from None
    print(f"SCF_ZIP_OK count={count} bytes={args.output.stat().st_size} sha256={digest}")


if __name__ == "__main__":
    main()
