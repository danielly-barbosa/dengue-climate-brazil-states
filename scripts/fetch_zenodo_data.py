import argparse
import hashlib
import json
import sys
import urllib.request
import zipfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]

DEFAULT_ZENODO_RECORD = "22310988"
DEFAULT_DOI = "10.5281/zenodo.22310988"

ZENODO_RECORD_URL = "https://zenodo.org/api/records/{record}"
ZENODO_FILE_URL = "https://zenodo.org/records/{record}/files/{filename}"
ZENODO_DOI_URL = "https://doi.org/10.5281/zenodo.{record}"

EXPECTED_FILES = [
    {
        "name": "national_climate_zenodo.csv.zip",
        "target_path": "cross_state/data/inputs_climate_zenodo_todos_os_estados.csv",
    },
    {
        "name": "pernambuco_diagnostico_figures.zip",
        "target_path": None,
    },
    {
        "name": "other_states_diagnostico_figures.zip",
        "target_path": None,
    },
]


def sha256_of(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def download_with_progress(url: str, dest: Path):
    dest.parent.mkdir(parents=True, exist_ok=True)
    print(f"  Downloading {url}")
    print(f"             -> {dest}")
    req = urllib.request.Request(url, headers={"User-Agent": "dengue-climate-brazil-states-fetch"})
    with urllib.request.urlopen(req) as resp:
        total = int(resp.headers.get("Content-Length", 0))
        chunk = 1 << 20
        with open(dest, "wb") as f:
            downloaded = 0
            while True:
                block = resp.read(chunk)
                if not block:
                    break
                f.write(block)
                downloaded += len(block)
                if total:
                    pct = downloaded * 100 // total
                    sys.stdout.write(f"\r    {downloaded//(1<<20)} MB / {total//(1<<20)} MB ({pct}%)")
                    sys.stdout.flush()
    print()


def verify_checksum(path: Path, expected_sha256: str) -> bool:
    actual = sha256_of(path)
    return actual.lower() == expected_sha256.lower()


def unpack_zip(zip_path: Path, target_dir: Path):
    target_dir.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(zip_path) as zf:
        for name in zf.namelist():
            member_path = target_dir / name
            if name.endswith("/"):
                member_path.mkdir(parents=True, exist_ok=True)
                continue
            member_path.parent.mkdir(parents=True, exist_ok=True)
            with zf.open(name) as src, open(member_path, "wb") as dst:
                dst.write(src.read())
            print(f"    extracted: {member_path.relative_to(REPO_ROOT)}")


def fetch_record_files(record_id: str, manifest: dict | None = None, force: bool = False):
    api_url = ZENODO_RECORD_URL.format(record=record_id)
    print(f"Fetching metadata: {api_url}")
    with urllib.request.urlopen(api_url) as resp:
        metadata = json.loads(resp.read().decode("utf-8"))

    files_meta = metadata.get("files", [])
    if not files_meta:
        print("No files in the Zenodo record; aborting.")
        return False

    by_name = {f["key"]: f for f in files_meta}

    expected_manifest = {f["name"]: f for f in (manifest or {}).get("files", [])} if manifest else {}

    for spec in EXPECTED_FILES:
        fname = spec["name"]
        if fname not in by_name:
            print(f"  [SKIP] {fname} not present in this deposit")
            continue
        f_meta = by_name[fname]
        download_url = f_meta["links"]["self"]
        size_mb = round(f_meta["size"] / 1e6, 2)

        local_zip = REPO_ROOT / "_zenodo_cache" / fname
        if local_zip.exists() and not force:
            print(f"  [CACHE] {fname} already in {local_zip.parent.relative_to(REPO_ROOT)} ({size_mb} MB)")
        else:
            download_with_progress(download_url, local_zip)
            print(f"  downloaded {fname} ({size_mb} MB)")

        if fname in expected_manifest:
            expected_sha = expected_manifest[fname]["sha256"]
            print(f"  verifying SHA-256 ...")
            ok = verify_checksum(local_zip, expected_sha)
            print(f"    {'OK' if ok else 'MISMATCH'} (expected {expected_sha[:12]}...)")
            if not ok:
                return False

        print(f"  extracting {fname} ...")
        if spec["target_path"]:
            target_csv = REPO_ROOT / spec["target_path"]
            target_csv.parent.mkdir(parents=True, exist_ok=True)
            with zipfile.ZipFile(local_zip) as zf:
                inner_name = next((n for n in zf.namelist() if n.endswith(".csv")), None)
                if inner_name:
                    with zf.open(inner_name) as src, open(target_csv, "wb") as dst:
                        dst.write(src.read())
                    print(f"    extracted single CSV to {target_csv.relative_to(REPO_ROOT)}")
        else:
            unpack_zip(local_zip, REPO_ROOT)

    print(f"\nDone. DOI: {ZENODO_DOI_URL.format(record=record_id)}")
    return True


def main():
    p = argparse.ArgumentParser()
    p.add_argument(
        "--record",
        default=DEFAULT_ZENODO_RECORD,
        help=f"Zenodo record ID (default: {DEFAULT_ZENODO_RECORD}, DOI: {DEFAULT_DOI})",
    )
    p.add_argument("--manifest", help="Path to MANIFEST.json with SHA-256 sums")
    p.add_argument("--force", action="store_true", help="Re-download even if cached")
    args = p.parse_args()

    manifest = None
    if args.manifest:
        with open(args.manifest, "r", encoding="utf-8") as f:
            manifest = json.load(f)
    else:
        candidate = REPO_ROOT / "_zenodo_cache" / "MANIFEST.json"
        if candidate.exists():
            with open(candidate, "r", encoding="utf-8") as f:
                manifest = json.load(f)

    ok = fetch_record_files(args.record, manifest=manifest, force=args.force)
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
