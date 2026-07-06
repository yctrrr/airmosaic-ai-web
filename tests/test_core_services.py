from pathlib import Path

from airmosaic_core.services import CausalDesignService, DataAccessService, DataCatalogService


def test_catalog_loads_initial_datasets():
    catalog = DataCatalogService()
    records = catalog.list_datasets()
    dataset_ids = {record.dataset_id for record in records}

    assert len(records) == 4
    assert "admin_boundary" in dataset_ids
    assert "population" in dataset_ids
    assert "gdp" in dataset_ids


def test_data_access_reports_missing_cache():
    catalog = DataCatalogService()
    access = DataAccessService(catalog=catalog, local_workspace=Path("D:/AirMosaicAI/local_workspace"))

    availability = access.check_local_availability("population", "*.csv")

    assert availability.dataset_id == "population"
    assert "data_cache" in str(availability.cache_root)


def test_causal_design_plan_is_structured():
    plan = CausalDesignService().draft_plan(
        question="Did clean air policy reduce mortality?",
        treatment="clean air policy",
        outcome="mortality",
    )

    payload = plan.to_dict()
    assert payload["treatment"] == "clean air policy"
    assert payload["outcome"] == "mortality"
    assert payload["identification_strategies"]
    assert payload["refutation_tests"]
