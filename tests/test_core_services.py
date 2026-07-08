from pathlib import Path

from airmosaic_core.services import CausalDesignService, DataAccessService, DataCatalogService


def test_catalog_loads_initial_datasets():
    catalog = DataCatalogService()
    records = catalog.list_datasets()
    dataset_ids = {record.dataset_id for record in records}

    assert len(records) == 9
    assert "worldpop_population_grid" in dataset_ids
    assert "csmar_listed_company_basic" in dataset_ids
    assert "industrial_yearbook_regional_sector" in dataset_ids
    assert "ihme_gbd_mortality_rates" in dataset_ids
    assert catalog.describe_dataset("population")["dataset_id"] == "worldpop_population_grid"
    assert catalog.describe_dataset("gdp")["dataset_id"] == "industrial_yearbook_regional_sector"


def test_catalog_filters_data_acquisition_datasets():
    catalog = DataCatalogService()

    socioeconomic = catalog.list_datasets(layer="01_socioeconomic")
    worldpop = catalog.list_datasets(skill="worldpop")
    health = catalog.list_datasets(domain="health")

    assert {record.layer for record in socioeconomic} == {"01_socioeconomic"}
    assert {record.skill_id for record in worldpop} == {"worldpop"}
    assert {record.domain for record in health} == {"health"}


def test_data_access_reports_missing_cache():
    catalog = DataCatalogService()
    access = DataAccessService(catalog=catalog, local_workspace=Path("D:/AirMosaicAI/local_workspace"))

    availability = access.check_local_availability("population", "*.csv")

    assert availability.dataset_id == "worldpop_population_grid"
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
