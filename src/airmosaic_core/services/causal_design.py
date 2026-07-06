from __future__ import annotations

from dataclasses import dataclass, asdict


@dataclass(frozen=True)
class CausalDesign:
    question: str
    treatment: str
    outcome: str
    unit: str
    candidate_confounders: list[str]
    identification_strategies: list[str]
    estimators: list[str]
    refutation_tests: list[str]
    notes: list[str]

    def to_dict(self) -> dict[str, object]:
        return asdict(self)


class CausalDesignService:
    """Draft causal-analysis designs for external agents and analysts."""

    def draft_plan(
        self,
        question: str,
        treatment: str,
        outcome: str,
        unit: str = "county-year",
    ) -> CausalDesign:
        return CausalDesign(
            question=question,
            treatment=treatment,
            outcome=outcome,
            unit=unit,
            candidate_confounders=[
                "baseline pollution",
                "population structure",
                "GDP or income",
                "industrial structure",
                "meteorology",
                "urbanization",
                "co-occurring policies",
            ],
            identification_strategies=[
                "difference-in-differences",
                "event study",
                "panel fixed effects",
                "instrumental variables when a defensible instrument exists",
                "double machine learning for high-dimensional controls",
            ],
            estimators=[
                "two-way fixed effects with sensitivity checks",
                "modern DID/event-study estimator when treatment timing varies",
                "double robust / DML estimator for heterogeneous effects",
            ],
            refutation_tests=[
                "placebo treatment timing",
                "placebo outcome",
                "pre-trend assessment",
                "alternative spatial aggregation",
                "alternative exposure windows",
            ],
            notes=[
                "This service drafts a causal design only; it does not assert a causal effect.",
                "The analyst or external agent must verify assumptions and data availability.",
            ],
        )

