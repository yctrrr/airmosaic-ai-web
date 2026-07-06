from pathlib import Path

from airmosaic_core.services import CausalDesignService, DataAccessService, DataCatalogService


def test_catalog_loads_initial_datasets():
    catalog = DataCatalogService()
    records = catalog.list_datasets()
    dataset_ids = {record.dataset_id for record in records}

    assert len(records) == 6
    assert "tap_pm25_1km" in dataset_ids
    assert "meic_emission" in dataset_ids
    assert "gbd_health" in dataset_ids


def test_data_access_reports_missing_cache():
    catalog = DataCatalogService()
    access = DataAccessService(catalog=catalog, local_workspace=Path("D:/AirMosaicAI/local_workspace"))

    availability = access.check_local_availability("tap_pm25_1km", "*.csv")

    assert availability.dataset_id == "tap_pm25_1km"
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

