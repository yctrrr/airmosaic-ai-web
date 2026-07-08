from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from .data_catalog import DataCatalogService


@dataclass(frozen=True)
class FileAvailability:
    dataset_id: str
    cache_root: Path
    existing_files: list[Path]
    missing_hint: str | None


class DataAccessService:
    """Inspect local dataset availability without exposing arbitrary paths."""

    def __init__(
        self,
        catalog: DataCatalogService | None = None,
        local_workspace: str | Path | None = None,
    ) -> None:
        self.catalog = catalog or DataCatalogService()
        workspace = local_workspace or os.environ.get(
            "AIRMOSAIC_LOCAL_WORKSPACE",
            r"D:\AirMosaicAI\local_workspace",
        )
        self.local_workspace = Path(workspace)

    def check_local_availability(
        self,
        dataset_id: str,
        pattern: str = "*",
    ) -> FileAvailability:
        dataset_id = self.catalog.resolve_dataset_id(dataset_id)
        metadata = self.catalog.describe_dataset(dataset_id)
        cache_root_template = metadata.get("cache_root") or metadata.get("default_cache_root")
        if cache_root_template is None:
            raise KeyError(f"Dataset metadata has no cache_root: {dataset_id}")
        cache_root = self._resolve_cache_root(cache_root_template)
        files = (
            sorted(
                path
                for path in cache_root.glob(pattern)
                if path.is_file() and not path.name.startswith(".")
            )
            if cache_root.exists()
            else []
        )
        acquisition_skill = metadata.get("acquisition_skill") or metadata.get("skill_path", "the related acquisition skill")
        missing_hint = None if files else f"No files found under {cache_root}. Use {acquisition_skill}."
        return FileAvailability(
            dataset_id=dataset_id,
            cache_root=cache_root,
            existing_files=files,
            missing_hint=missing_hint,
        )

    def query_files(self, dataset_id: str, pattern: str = "*") -> list[Path]:
        return self.check_local_availability(dataset_id, pattern).existing_files

    def _resolve_cache_root(self, template: str) -> Path:
        value = template.replace("${AIRMOSAIC_LOCAL_WORKSPACE}", str(self.local_workspace))
        return Path(value)
