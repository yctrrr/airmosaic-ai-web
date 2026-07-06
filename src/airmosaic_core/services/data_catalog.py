from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Any

import yaml


@dataclass(frozen=True)
class DatasetRecord:
    dataset_id: str
    name: str
    domain: str
    description: str
    metadata: dict[str, Any]
    source_path: Path


class DataCatalogService:
    """Read and query AirMosaic dataset metadata."""

    def __init__(self, catalog_dir: str | Path | None = None) -> None:
        if catalog_dir is None:
            catalog_dir = Path(__file__).resolve().parents[3] / "catalog" / "datasets"
        self.catalog_dir = Path(catalog_dir)

    def list_datasets(self) -> list[DatasetRecord]:
        records: list[DatasetRecord] = []
        for path in sorted(self.catalog_dir.glob("*.yaml")):
            data = self._read_yaml(path)
            records.append(
                DatasetRecord(
                    dataset_id=data["dataset_id"],
                    name=data["name"],
                    domain=data["domain"],
                    description=data["description"],
                    metadata=data,
                    source_path=path,
                )
            )
        return records

    def describe_dataset(self, dataset_id: str) -> dict[str, Any]:
        for record in self.list_datasets():
            if record.dataset_id == dataset_id:
                return record.metadata
        raise KeyError(f"Dataset not found: {dataset_id}")

    def search_datasets(self, query: str) -> list[DatasetRecord]:
        terms = [term.lower() for term in query.split() if term.strip()]
        if not terms:
            return self.list_datasets()

        matches: list[DatasetRecord] = []
        for record in self.list_datasets():
            haystack = " ".join(
                [
                    record.dataset_id,
                    record.name,
                    record.domain,
                    record.description,
                    " ".join(record.metadata.get("example_queries", [])),
                ]
            ).lower()
            if all(term in haystack for term in terms):
                matches.append(record)
        return matches

    @staticmethod
    def _read_yaml(path: Path) -> dict[str, Any]:
        with path.open("r", encoding="utf-8") as handle:
            data = yaml.safe_load(handle)
        if not isinstance(data, dict):
            raise ValueError(f"Invalid dataset metadata: {path}")
        return data

