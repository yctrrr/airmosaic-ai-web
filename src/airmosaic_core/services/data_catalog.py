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
    layer: str
    skill_id: str
    skill_path: str
    access_mode: str
    metadata: dict[str, Any]
    source_path: Path


class DataCatalogService:
    """Read and query AirMosaic dataset metadata."""

    DATASET_ALIASES = {
        "population": "worldpop_population_grid",
        "worldpop": "worldpop_population_grid",
        "gdp": "industrial_yearbook_regional_sector",
        "health": "ihme_gbd_mortality_rates",
        "gbd": "ihme_gbd_mortality_rates",
        "mortality": "ihme_gbd_mortality_rates",
        "ind_yearbook": "industrial_yearbook_regional_sector",
    }

    def __init__(
        self,
        catalog_dir: str | Path | None = None,
        data_acquisition_dir: str | Path | None = None,
    ) -> None:
        repo_root = Path(__file__).resolve().parents[3]
        if catalog_dir is None:
            catalog_dir = repo_root / "catalog" / "datasets"
        if data_acquisition_dir is None:
            data_acquisition_dir = repo_root / "skills" / "data_acquisition"
        self.catalog_dir = Path(catalog_dir)
        self.data_acquisition_dir = Path(data_acquisition_dir)

    def list_datasets(
        self,
        layer: str | None = None,
        skill: str | None = None,
        domain: str | None = None,
    ) -> list[DatasetRecord]:
        records: list[DatasetRecord] = []
        for path in sorted(self.data_acquisition_dir.glob("**/datasets.yaml")):
            data = self._read_yaml(path)
            skill_id = data["skill_id"]
            layer_id = data["layer"]
            skill_path = data["skill_path"]
            for item in data.get("datasets", []):
                metadata = {
                    **item,
                    "layer": layer_id,
                    "skill_id": skill_id,
                    "skill_path": skill_path,
                }
                records.append(
                    DatasetRecord(
                        dataset_id=item["dataset_id"],
                        name=item["name"],
                        domain=item["domain"],
                        description=item["description"],
                        layer=layer_id,
                        skill_id=skill_id,
                        skill_path=skill_path,
                        access_mode=item.get("access_mode", "unspecified"),
                        metadata=metadata,
                        source_path=path,
                    )
                )

        if layer is not None:
            records = [record for record in records if record.layer == layer]
        if skill is not None:
            records = [record for record in records if record.skill_id == skill]
        if domain is not None:
            records = [record for record in records if record.domain == domain]
        return records

    def describe_dataset(self, dataset_id: str) -> dict[str, Any]:
        dataset_id = self.resolve_dataset_id(dataset_id)
        for record in self.list_datasets():
            if record.dataset_id == dataset_id:
                return record.metadata
        for path in sorted(self.catalog_dir.glob("*.yaml")):
            data = self._read_yaml(path)
            if data.get("dataset_id") == dataset_id:
                return data
        raise KeyError(f"Dataset not found: {dataset_id}")

    def resolve_dataset_id(self, dataset_id: str) -> str:
        return self.DATASET_ALIASES.get(dataset_id, dataset_id)

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
                    record.layer,
                    record.skill_id,
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
