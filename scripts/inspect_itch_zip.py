"""Read ZIP metadata and hand the observed metrics to the MoonBit rule engine."""
import argparse
import hashlib
from pathlib import Path
import subprocess
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]


def inspect(path):
    with ZipFile(path) as archive:
        files = [item for item in archive.infolist() if not item.is_dir()]
    names = [item.orig_filename for item in files]
    if len(names) != len(set(names)):
        raise ValueError("ZIP contains duplicate file paths")
    for name in names:
        if "\\" in name or ":" in name or any(piece in ("", ".", "..") for piece in name.split("/")):
            raise ValueError("Unsafe or malformed archive path")
    for item in files:
        if not item.orig_filename.isascii() and not item.flag_bits & 0x800:
            raise ValueError("Non-ASCII ZIP paths must be marked UTF-8")
        if item.flag_bits & 1 or (item.external_attr >> 16) & 0o170000 == 0o120000:
            raise ValueError("Encrypted entries and symbolic links are unsupported")
    sizes = [item.file_size for item in files]
    return len(files), sum(sizes), max(sizes, default=0), max(map(len, names), default=0), int("index.html" in names)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("zip", type=Path)
    args = parser.parse_args()
    stats = inspect(args.zip)
    with args.zip.open("rb") as file:
        print(f"ZIP SHA-256: {hashlib.file_digest(file, 'sha256').hexdigest()}", flush=True)
    print(f"files={stats[0]} total={stats[1]} largest={stats[2]} path={stats[3]} root_index={stats[4]}", flush=True)
    result = subprocess.run(["moon", "run", "cmd/main", "--", "itch-zip", *map(str, stats)], cwd=ROOT)
    raise SystemExit(result.returncode)
