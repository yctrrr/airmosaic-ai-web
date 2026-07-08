from __future__ import annotations

import argparse
import json
from pathlib import Path

from .services.causal_design import CausalDesignService
from .services.data_access import DataAccessService
from .services.data_catalog import DataCatalogService


def main() -> None:
    parser = argparse.ArgumentParser(prog="airmosaic")
    subparsers = parser.add_subparsers(dest="command", required=True)

    list_datasets = subparsers.add_parser("list-datasets")
    list_datasets.add_argument("--layer")
    list_datasets.add_argument("--skill")
    list_datasets.add_argument("--domain")

    describe = subparsers.add_parser("describe-dataset")
    describe.add_argument("dataset_id")

    search = subparsers.add_parser("search-datasets")
    search.add_argument("query")

    availability = subparsers.add_parser("check-availability")
    availability.add_argument("dataset_id")
    availability.add_argument("--pattern", default="*")

    causal = subparsers.add_parser("draft-causal-plan")
    causal.add_argument("--question", required=True)
    causal.add_argument("--treatment", required=True)
    causal.add_argument("--outcome", required=True)
    causal.add_argument("--unit", default="county-year")

    args = parser.parse_args()
    catalog = DataCatalogService()

    if args.command == "list-datasets":
        payload = [
            {
                "dataset_id": item.dataset_id,
                "name": item.name,
                "domain": item.domain,
                "layer": item.layer,
                "skill_id": item.skill_id,
                "skill_path": item.skill_path,
                "access_mode": item.access_mode,
                "description": item.description,
            }
            for item in catalog.list_datasets(
                layer=args.layer,
                skill=args.skill,
                domain=args.domain,
            )
        ]
    elif args.command == "describe-dataset":
        payload = catalog.describe_dataset(args.dataset_id)
    elif args.command == "search-datasets":
        payload = [
            {
                "dataset_id": item.dataset_id,
                "name": item.name,
                "domain": item.domain,
                "layer": item.layer,
                "skill_id": item.skill_id,
            }
            for item in catalog.search_datasets(args.query)
        ]
    elif args.command == "check-availability":
        access = DataAccessService(catalog=catalog)
        result = access.check_local_availability(args.dataset_id, args.pattern)
        payload = {
            "dataset_id": result.dataset_id,
            "cache_root": str(result.cache_root),
            "existing_files": [str(Path(path)) for path in result.existing_files],
            "missing_hint": result.missing_hint,
        }
    elif args.command == "draft-causal-plan":
        payload = CausalDesignService().draft_plan(
            question=args.question,
            treatment=args.treatment,
            outcome=args.outcome,
            unit=args.unit,
        ).to_dict()
    else:
        raise ValueError(f"Unhandled command: {args.command}")

    print(json.dumps(payload, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
