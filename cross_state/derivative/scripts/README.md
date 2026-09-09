# Cross-State Derivative Analysis

This module complements the DLNM pipeline with a complementary **temporal-derivative analysis**
of daily dengue incidence.

It reproduces the logic of `notebook/temporal_derivative.ipynb` as a plain Python script,
exporting tables and figures into `outputs/`.

## Layout

```
cross_state/derivative/
├── notebook/
│   └── temporal_derivative.ipynb     # original exploratory notebook
├── scripts/
│   ├── export_artifacts.py           # reusable Python pipeline
│   └── README.md                     # this file
└── outputs/
    ├── tables/                       # derivative, alerts, FPR/TPR tables (CSV)
    └── figures/                      # first derivative, processing panel, FPR/TPR curves
```

## Pipeline overview

The notebook investigates the **rate of change** of daily dengue incidence per state
(PE, GO, RJ, RS) and compares it with:

- **Index P** (`indexP`) — climate-suitability derived from MVSE
- **B_p = indexP(t - τ) / (Incidence + 1)** — the "barrier" processing ratio
- Lab-confirmed outbreaks (optional, via `Lab_Denv.csv`)

The script exports:

- `derivative_incidence_all_states.csv` — first derivative (`_dt`) and second derivative (`_st`)
- `derivative_season_<STATE>_<SEASON>.csv` — `_dt`, `_st`, expanding mean (`_mu_t`),
  expanding standard deviation (`_sigma_t`) restricted to a seasonal window
- `derivative_alerts_<STATE>_<SEASON>.csv` — boolean alert matrix for k ∈ [0, 3] step 0.125
- `fpr_tpr_table_<STATE>_<SEASON>.csv` — alert precision/recall vs. outbreaks
- `first_derivative_incidence.png` — 4-state stacked panel
- `processing_panel_4states.png` — barrier ratio + incidence overlay
- `fpr_tpr_curve_<STATE>.png` — k-sweep diagnostic

## Reproduce

```bash
python cross_state/derivative/scripts/export_artifacts.py
```

Inputs are read directly from the consolidated state CSVs in the main repo
(no additional preprocessing required). To use real lab outbreak ground-truth,
place a `Lab_Denv.csv` file at `cross_state/data/Lab_Denv.csv` before running.

## Notes

- The temporal-derivative analysis is **complementary** to the DLNM risk models in
  `<STATE>/dlnm/`. It is not used as input to the DLNM, only as visual / diagnostic
  validation of outbreak timing.
- The default seasonal window is **2023-06-04 to 2024-06-02** (largest Brazilian dengue
  season in the analysis window). Edit `SEASONAL_WINDOWS` to add more.
- `Lab_Denv.csv` is **not** tracked in this repo (sensitive/raw data). Without it, the
  FPR/TPR tables are still produced but use a placeholder outbreak ground-truth.
