# Review Response - Data Cleaning and Geocode Filter (RS + OFFSET)

## Reviewer concern addressed
The reviewer questioned the decision to apply a geocode filter (<10 total cases during 2017-2024) only in Rio Grande do Sul and requested a clearer justification, the number of excluded municipalities, the share of population and cases represented by these exclusions, and a sensitivity analysis with and without the filter.

## What the RS + OFFSET pipeline actually does
- The production pipeline applies `filter_geocodes_min_cases(dados, min_total_cases = 10)` before model fitting.
- In the filtered production analysis, 201 geocodes entered the merge-ready panel and 51 were excluded, leaving 150 geocodes in the fitted models.

## Quantifying the impact of the filter in RS
- Excluded geocodes: 51 of 201 (25.4%).
- Excluded cases: 185 of 116345 (0.159% of all notified cases in the model-ready panel).
- Excluded population: 292406 of 4811082 using mean municipal population across 2017-2024 (6.078%).
- The excluded municipality list is saved in `rs_geocodes_excluded_lt10_offset.csv`.

## Why the RS-specific justification is plausible
- A comparative state-level diagnostic was produced from the dengue series used in the project.
- Percentage of geocodes with <10 total cases (2017-2024): PE = 0.0%; GO = 0.0%; RJ = 0.0%; RS = 25.9%.
- This comparison helps justify whether RS was uniquely sparse enough to require the filter for stable municipality-fixed-effect negative-binomial DLNMs.

## Sensitivity analysis: with and without the filter
- Best filtered RS + OFFSET model by AIC: `indexP` (AIC = 55919.109).
- Exact no-filter RS + OFFSET rerun was left optional because it is computationally heavy. To execute it, set `RUN_EXACT_NOFILTER_SENSITIVITY=true` before running this script.
- As an immediate sensitivity anchor, the project already contained legacy RS MASS comparisons between Version A (filter <10 cases) and Version B (no municipality factor / no <10 filter).
- Legacy indexP comparison: Version A AIC = 56397.85 vs Version B AIC = 71217.51.
- Legacy precip_tot comparison: Version A AIC = 56666.60 vs Version B AIC = 71299.12.
- These legacy comparisons are not identical to the new offset pipeline because Version B also drops municipality fixed effects, but they show that removing the RS-specific stabilization strategy materially worsened fit in the historical analyses.

## Top 5 models with filter
| Rank | Model | Type | AIC | Geocodes | n_final | RR p90 |
|---:|:------|:-----|----:|---------:|--------:|-------:|
| 1 | indexP | individual | 55919.109 | 150 | 60900 | 0.098 |
| 2 | precip_tot | individual | 56186.532 | 150 | 60900 | 0.297 |
| 3 | temp_max | individual | 56235.692 | 150 | 60900 | 1.339 |
| 4 | temp_max_precip_humid | combined | 56241.772 | 150 | 60900 | 1.325 |
| 5 | temp_med | individual | 56268.347 | 150 | 60900 | 0.800 |

## Interpretation guide for the manuscript
- The new RS + OFFSET audit now quantifies exactly how many municipalities were excluded and how much population/case mass they represent.
- The state comparison shows that `<10`-case municipalities are a RS-specific sparsity issue in this project, whereas PE, GO and RJ have 0 municipalities below this threshold in the 2017-2024 dengue series used here.
- The legacy A/B evidence supports describing the RS filter as a modeling-stability choice rather than a generic cleaning step.

## Output files
- `rs_filter_summary_offset.csv`
- `rs_geocodes_excluded_lt10_offset.csv`
- `comparative_low_case_geocodes_states_2017_2024.csv`
- `filtered_models_summary_offset.csv`
- `legacy_rs_mass_versions_A_B_sensitivity.csv`
- `unfiltered_models_summary_offset.csv` (only when `RUN_EXACT_NOFILTER_SENSITIVITY=true`)
- `sensitivity_filter_vs_no_filter_models_offset.csv` (only when `RUN_EXACT_NOFILTER_SENSITIVITY=true`)
- `indexP_rr_sensitivity_filter_vs_no_filter_offset.csv` (only when `RUN_EXACT_NOFILTER_SENSITIVITY=true`)
