# PM2.5 Health Impact Methodology

## Background

Fine particulate matter (PM2.5) is the leading environmental risk factor for premature mortality globally. The standard approach to quantifying this burden is the Population Attributable Fraction (PAF) framework, which combines exposure data, baseline disease rates, and concentration-response functions from epidemiological studies.

## PAF Framework

### Derivation

The attributable fraction of disease burden from PM2.5 exposure is:

`
PAF = (RR - 1) / RR
`

Where RR is the relative risk at a given PM2.5 concentration relative to the theoretical minimum risk exposure level (TMREL).

The attributable mortality rate per 100,000 population is:

`
MortRate_PM25 = sum_{endpoint, sex, age} [
    AgeStruc(sex, age) * BaselineMort(sex, age, endpoint) * PAF(c, endpoint, age)
]
`

The total attributable deaths in a grid cell:

`
Mort = Population * MortRate_PM25
`

### Assumptions

1. **TMREL**: The theoretical minimum risk exposure level is assumed to be 0 ug/m3, yielding RR = 1
2. **Uniform exposure**: Annual mean PM2.5 concentration represents chronic exposure
3. **Independence**: Effects across endpoints are additive (no interaction terms)
4. **Capping**: Concentrations are capped at the RR curve maximum (typically 200 ug/m3 for coarse-resolution curves, or up to 500 ug/m3 for high-exposure extensions)

## GEMM-5COD Curve

The Global Exposure Mortality Model (GEMM) with 5 Causes of Death:

**Source**: Burnett et al. (2018) PNAS, updated in Burnett & Spadaro et al. (2022)

**Endpoints**: COPD, Lung Cancer, Lower Respiratory Infections (LRI), Ischemic Heart Disease (IHD), Stroke (ischemic + hemorrhagic)

**Characteristics**:
- Derived from 41 cohort studies across 16 countries
- Models the full concentration range (0-200+ ug/m3)
- Age-modified: separate RR curves for each 5-year age group
- Accounts for differences between cohort types (e.g., occupational exposure cohorts)
- Generally produces higher estimates than IER at moderate-to-high concentrations

## IER Curve

The Integrated Exposure-Response function:

**Source**: GBD 2010 (Burnett et al., 2014 EHP), updated in GBD 2013, 2015, 2017

**Endpoints**: COPD, Lung Cancer, LRI, IHD, Stroke

**Characteristics**:
- Combines evidence from ambient air pollution, secondhand smoke, household air pollution, and active smoking
- Parametric form: RR = 1 + alpha * (1 - exp(-beta * (c - c0)^delta)) for c > c0, else RR = 1
- Age-invariant (single curve for ages 25+)
- Generally produces lower estimates than GEMM at concentrations above ~40 ug/m3

## GEMM vs IER Comparison

| Aspect | GEMM-5COD | IER |
|---|---|---|
| Cohort studies | 41 studies, 16 countries | 4 ambient + SHS/HAP/smoking |
| Concentration range | Full range (0-500+ ug/m3) | Parametric, asymptotes at high conc |
| Age modification | Yes (5-year groups) | No (25+ only) |
| RR at 50 ug/m3 (IHD, age 60) | ~1.8-2.2 | ~1.3-1.5 |
| RR at 100 ug/m3 (IHD, age 60) | ~2.5-3.5 | ~1.4-1.6 |
| Preferred for | High-exposure settings (e.g., China, India) | Conservative estimates, global comparisons |

## Uncertainty Considerations

Key sources of uncertainty not directly propagated in this implementation:

1. **Exposure measurement error**: Gridded PM2.5 estimates have spatially variable uncertainty
2. **Population data error**: Gridded population products have errors in both total counts and spatial allocation
3. **Baseline mortality**: GBD estimates have cause-specific uncertainty intervals
4. **CRF shape uncertainty**: Both GEMM and IER have uncertainty envelopes around the central estimate
5. **Age structure**: Age distribution at grid level is modeled, not observed
6. **TMREL**: The true counterfactual concentration is unknown and debated (0-5 ug/m3 range)

For full uncertainty propagation, consider Monte Carlo simulation drawing from the uncertainty distributions of each input.

## References

- Burnett R, Chen H, Szyszkowicz M, et al. (2018). Global estimates of mortality associated with long-term exposure to outdoor fine particulate matter. *PNAS*, 115(38), 9592-9597.
- Burnett RT, Spadaro JV, et al. (2022). An updated global exposure mortality model for fine particulate matter. Draft manuscript.
- Burnett RT, Pope CA III, et al. (2014). An integrated risk function for estimating the Global Burden of Disease attributable to ambient fine particulate matter exposure. *EHP*, 122(4), 397-403.
- GBD 2019 Risk Factors Collaborators. (2020). Global burden of 87 risk factors in 204 countries and territories, 1990-2019. *The Lancet*, 396(10258), 1223-1249.
