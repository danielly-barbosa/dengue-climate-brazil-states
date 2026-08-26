# Dengue Climate-Suitability and DLNM Analysis in Brazilian States

This repository contains **data and code** to reproduce all analyses in the doctoral study investigating the effects of **climate variables** and a **mosquito-borne viral suitability index (indexP)** on **dengue transmission** across multiple Brazilian states, using **Distributed Lag Non-linear Models (DLNM)** with population offset and the **MVSE** (Mosquito-borne Viral Suitability Estimator) package.

## Study Overview

The study has two main pipelines:

1. **MVSE / indexP estimation** — Estimates the empirical indexP (a transmission suitability index for *Aedes*-borne viruses) from temperature, humidity, and precipitation time series for each municipality, using the R package `MVSE 1.0.1` (Lourenco & Obolski, 2021).

2. **DLNM with Negative Binomial models** — Fits Distributed Lag Non-linear Models via `MASS::glm.nb` with a population offset (`offset = log(Pop_i / 100000)`) to quantify the non-linear and delayed effects of climate variables (temperature, humidity, precipitation) and indexP on dengue incidence, using panel data by municipality.

## Repository Structure

```
├── goias/                    # Goiás state (MVSE + DLNM)
│   ├── mvse/
│   │   ├── scripts/           # Filter, split, run MVSE, combine indexP
│   │   ├── inputs/            # State-level climate CSV
│   │   └── outputs/           # Consolidated indexP CSV
│   └── dlnm/
│       ├── scripts/           # Functions, individual & combined models, AIC/QAIC
│       ├── data/              # Dengue, climate, indexP, population CSVs
│       └── results/
│           ├── figures/       # DLNM figures (individual & combined)
│           └── summaries/      # QC reports, model rankings, diagnostics
│
├── pernambuco/               # Pernambuco state (MVSE + DLNM + prediction)
│   ├── mvse/
│   ├── dlnm/
│   └── dlnm/prediction/       # Predictive analysis & validation scripts
│
├── rio_de_janeiro/           # Rio de Janeiro state (MVSE + DLNM)
│   ├── mvse/
│   └── dlnm/
│
├── rio_grande_do_sul/        # Rio Grande do Sul state (MVSE + DLNM + sensitivity)
│   ├── mvse/
│   └── dlnm/
│       └── results/sensitivity/  # Sensitivity analysis (geocode filtering)
│
├── parana/                   # Paraná state (MVSE only)
│   └── mvse/
│
├── santa_catarina/           # Santa Catarina state (MVSE only)
│   └── mvse/
│
├── cross_state/              # Cross-state comparative analysis
│   ├── scripts/               # Combined slice/lag figure generators
│   ├── data/                   # Lag tables, national climate CSV
│   ├── figures/                # Combined contour, comparative variable figures
│   └── lag_tables/             # Lag-specific RR figures and contour data per variable
│
├── legacy/                   # Earlier script versions (temp_min & temp_med MVSE cycles)
│   ├── mvse_temp_med/
│   ├── mvse_temp_min/
│   └── mvse_old_scripts/
│
├── .gitignore
└── README.md
```

## States Covered

| State | IBGE prefix | Municipalities | MVSE | DLNM |
|---|---|---|---|---|
| Pernambuco (PE) | 26 | 185 | Yes | Yes |
| Paraná (PR) | 41 | 399 | Yes | — |
| Santa Catarina (SC) | 42 | 295 | Yes | — |
| Rio Grande do Sul (RS) | 43 | 497 | Yes | Yes |
| Rio de Janeiro (RJ) | 33 | 92 | Yes | Yes |
| Goiás (GO) | 52 | 246 | Yes | Yes |

## MVSE Pipeline

### Data format

Each municipality CSV (inside `inputs/geocodes/`, **not included** in the repo — regenerable via scripts) contains:

| Column | Description |
|---|---|
| `date` | Date (weekly, epiweek) |
| `T` | Mean temperature (°C) |
| `H` | Mean relative humidity (%) |
| `R` | Total precipitation (mm) |

### MVSE parameters

| Parameter | Value |
|---|---|
| Temperature variable | `temp_med` |
| Humidity variable | `rel_humid_med` |
| Precipitation variable | `precip_tot` |
| MCMC iterations (`nMCMC`) | 25,000 |
| Simulations (`nSample`) | 120 |
| Smoothing windows (days) | 7, 15, 30, 60 |

### How to run MVSE for a state

```bash
cd <state>/mvse
python scripts/00a_filter_climate.py     # Filter state from national CSV
python scripts/00b_split_geocodes.py     # Split into per-municipality CSVs
Rscript scripts/01_executar_mvse.R       # Run MVSE (estimates indexP)
python scripts/99_combine_indexp.py     # Consolidate into single CSV
```

**Output**: `<state>_indexP_combined.csv` with columns `geocode, date, indexP`.

### R dependencies (MVSE)

- `MVSE (>= 1.0.1)`
- `data.table`
- `parallel`, `doParallel`, `foreach`
- `pbapply`
- `scales`
- `genlasso`

## DLNM Pipeline

### Data files (per state)

| File | Description |
|---|---|
| `dengue_<state>_consolidado.csv` | Weekly dengue case counts by municipality |
| `climate_<state>_<years>.csv` | Climate variables (temp, humidity, precip) by municipality |
| `indexP_<state>_<years>.csv` | MVSE-estimated indexP by municipality |
| `br_ibge_populacao_municipio_filtrado.csv` | IBGE population estimates |

### Model specification

- **Model**: Negative Binomial GLM (`MASS::glm.nb`)
- **Offset**: `log(Pop_i / 100000)` (population standardized rate)
- **Cross-basis**: `dlnm::crossbasis` with natural cubic splines for exposure and lag dimensions
- **Panel**: grouped by municipality (`geocode`)
- **Variables modeled**: `indexP`, `temp_min`, `temp_med`, `temp_max`, `rel_humid_med`, `precip_tot` (individual), and `temp_* + precip + humid` (combined)

### Scripts per state

| Script | Purpose |
|---|---|
| `functions_dlnm_offset_<state>.R` | Core functions: data loading, cross-basis, model fitting, plotting |
| `run_all_models_offset.R` | Run all individual + combined models |
| `run_individual_<variable>_offset.R` | Individual model for a single variable |
| `run_combined_temp_*_precip_humid_offset.R` | Combined model (temp + precip + humidity) |
| `finalize_reports_offset.R` | Consolidate QC and summary reports |
| `avaliar_modelos_AIC_QAIC_<state>_offset.R` | Model selection via AIC/QAIC |

### How to run DLNM for a state

```bash
cd <state>/dlnm/scripts
Rscript run_all_models_offset.R      # Fit all models
Rscript finalize_reports_offset.R    # Generate reports
Rscript avaliar_modelos_AIC_QAIC_<state>_offset.R  # Model comparison
```

### R dependencies (DLNM)

- `dlnm`
- `splines`
- `MASS`
- `ggplot2`
- `dplyr`
- `lubridate`

## Cross-State Analysis

The `cross_state/` folder contains scripts and figures that combine results across all four DLNM states (PE, GO, RJ, RS):

- **Combined slice/lag figures**: `indexP_slices_lags_0_12_offset_*.png/.svg`
- **Combined contour plots**: `Contorno_Combinado_*.png`
- **Comparative RR by variable**: `RR_Variaveis_Lag_*.png` and `RR_Variaveis_e_IndexP_*.png`
- **Lag tables**: Per-variable lag-specific RR figures (lag 0–12) and contour data

## Data Sources

- **Climate data**: [InfoDengue Sprint 2024–2025](https://github.com/AlertaDengue/AlertaDengue) — climate CSV (temperature, humidity, precipitation by municipality, weekly)
- **Dengue data**: InfoDengue passive surveillance system
- **Population data**: IBGE (`br_ibge_populacao_municipio`)
- **MVSE package**: Lourenco & Obolski (2021), *PLOS Neglected Tropical Diseases*

## Reproducibility Notes

- Per-municipality geocode CSVs (~1,800+ files total) are **not included** in this repository. They can be regenerated by running `00a_filter_climate.py` and `00b_split_geocodes.py` with the national climate CSV.
- Per-municipality `estimated_indexP.csv` files (MVSE outputs) are also **not included** — run the MVSE pipeline to regenerate.
- Only **consolidated** CSVs (`*_combined.csv`, `*_consolidado.csv`) and all **scripts** are version-controlled.
- MVSE 1.0.1 must be installed locally in R. See [MVSE on GitHub](https://github.com/aldomann/MVSE).

## License

This repository is intended for academic reproducibility. Data usage is subject to the terms of the original data sources (InfoDengue, IBGE).