from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
from urllib.parse import urljoin

import requests


DATA_API = "https://www.worldpop.org/rest/data"
DATA_HOST = "https://data.worldpop.org/"


def records_from_payload(payload: object) -> list[dict]:
    if isinstance(payload, list):
        return [item for item in payload if isinstance(item, dict)]
    if isinstance(payload, dict):
        for key in ("data", "records", "files", "results"):
            value = payload.get(key)
            if isinstance(value, list):
                return [item for item in value if isinstance(item, dict)]
        return [payload]
    return []


def discover(project: str, iso3: str | None = None, timeout: int = 60) -> list[dict]:
    url = f"{DATA_API}/pop/{project}"
    params = {"iso3": iso3.upper()} if iso3 else None
    response = requests.get(url, params=params, timeout=timeout)
    response.raise_for_status()
    return records_from_payload(response.json())


def matches(record: dict, year: int | None, contains: list[str], extensions: list[str]) -> bool:
    haystack = json.dumps(record, ensure_ascii=False).lower()
    if year is not None and str(year) not in haystack:
        return False
    if contains and not all(term.lower() in haystack for term in contains):
        return False
    data_file = str(record.get("data_file") or record.get("url") or record.get("download_url") or "")
    if extensions and not any(data_file.lower().endswith(ext.lower()) for ext in extensions):
        return False
    return True


def file_url(record: dict) -> str | None:
    value = record.get("download_url") or record.get("url") or record.get("data_file")
    if not value:
        return None
    value = str(value)
    if value.startswith(("http://", "https://")):
        return value
    return urljoin(DATA_HOST, value.lstrip("/"))


def safe_name(url: str) -> str:
    return url.rstrip("/").split("/")[-1] or "worldpop_download.dat"


def write_manifest(records: list[dict], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding="utf-8")
    csv_path = path.with_suffix(".csv")
    keys = sorted({key for record in records for key in record.keys()})
    with csv_path.open("w", newline="", encoding="utf-8-sig") as handle:
        writer = csv.DictWriter(handle, fieldnames=keys)
        writer.writeheader()
        for record in records:
            writer.writerow({key: record.get(key, "") for key in keys})


def download(url: str, out: Path, timeout: int = 300) -> None:
    out.parent.mkdir(parents=True, exist_ok=True)
    if out.exists() and out.stat().st_size > 0:
        return
    with requests.get(url, stream=True, timeout=timeout) as response:
        response.raise_for_status()
        tmp = out.with_suffix(out.suffix + ".part")
        with tmp.open("wb") as handle:
            for chunk in response.iter_content(chunk_size=1024 * 1024):
                if chunk:
                    handle.write(chunk)
        tmp.replace(out)


def main() -> None:
    parser = argparse.ArgumentParser(description="Discover and optionally download WorldPop files.")
    parser.add_argument("--project", required=True, help="WorldPop project/product alias, for example wpgp.")
    parser.add_argument("--iso3", help="ISO3 country code such as CHN.")
    parser.add_argument("--year", type=int, help="Filter metadata by year text.")
    parser.add_argument("--contains", default="", help="Comma-separated terms that must appear in metadata.")
    parser.add_argument("--extensions", default=".tif,.tiff,.zip", help="Comma-separated allowed file extensions.")
    parser.add_argument("--root", required=True, help="Local WorldPop cache root.")
    parser.add_argument("--download", action="store_true", help="Download matched files.")
    parser.add_argument("--limit", type=int, help="Optional maximum number of matched records.")
    args = parser.parse_args()

    terms = [item.strip() for item in args.contains.split(",") if item.strip()]
    extensions = [item.strip() for item in args.extensions.split(",") if item.strip()]
    records = [
        record for record in discover(args.project, args.iso3)
        if matches(record, args.year, terms, extensions)
    ]
    if args.limit is not None:
        records = records[: args.limit]

    root = Path(args.root)
    label_iso = (args.iso3 or "all").upper()
    label_year = str(args.year or "all_years")
    manifest = root / "metadata" / f"{args.project}_{label_iso}_{label_year}_manifest.json"
    write_manifest(records, manifest)

    downloaded: list[str] = []
    if args.download:
        for record in records:
            url = file_url(record)
            if not url:
                continue
            out = root / "raw" / label_iso / args.project / label_year / safe_name(url)
            download(url, out)
            downloaded.append(str(out))

    print(json.dumps({
        "manifest": str(manifest),
        "records": len(records),
        "downloaded": downloaded,
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
