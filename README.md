# Dengue Climate-Suitability and DLNM Analysis in Brazilian States

**Author:** Danielly Alves Mendes Barbosa
**ORCID:** (0000-0003-4540-0334)

This repository contains **data and code** to reproduce analyses in the doctoral study
investigating the effects of **climate variables** and a **mosquito-borne viral suitability
index (indexP)** on **dengue transmission** across multiple Brazilian states, using
**Distributed Lag Non-linear Models (DLNM)** 

---

## Study period

**2017-01 to 2024-06**.
---

## Study overview

The study has two main pipelines:

1. **MVSE / indexP estimation** — Estimates the  indexP (a transmission suitability
   index for *Aedes*-borne viruses) from temperature, humidity, and precipitation time series
   for each municipality, using the R package `MVSE 1.0.1` (Lourenco & Obolski, 2021).

2. **DLNM with Negative Binomial models** — Fits Distributed Lag Non-linear Models via
   `MASS::glm.nb` with a population offset (`offset = log(Pop_i / 100000)`) to quantify the
   non-linear and delayed effects of climate variables (temperature, humidity, precipitation)
   and indexP on dengue incidence, using panel data by municipality.

A complementary **cross-state derivative analysis** investigates the rate of change of daily
dengue incidence and is provided under `cross_state/derivative/`.

---

## Repository structure

```
github/
├── LICENSE                  # MIT license
├── CITATION.cff             # GitHub-native citation metadata
├── README.md                # This file
├── .gitignore
├── validate_repo.py         # Self-test: 250+ integrity assertions
│
├── goias/                   # Goiás (MVSE + DLNM)
├── pernambuco/              # Pernambuco (MVSE + DLNM + predictive validation)
├── rio_de_janeiro/          # Rio de Janeiro (MVSE + DLNM)
├── rio_grande_do_sul/       # Rio Grande do Sul (MVSE + DLNM + sensitivity)
│
├── cross_state/             # Cross-state comparative figures and derivative analysis
│   ├── scripts/             # Combined slice/lag figure generators
│   ├── data/                # Lag tables, national CSV reference
│   ├── figures/             # Combined contour + comparative RR plots
│   ├── lag_tables/          # Per-variable lag 0–12 RR figures and contour data
│   └── derivative/          # Temporal-derivative diagnostic (notebook + export_artifacts.py)
│
└── legacy/                  # Earlier MVSE iterations (temp_min and temp_med cycles)
    ├── mvse_temp_med/       # Superseded by current default (temp_med)
    ├── mvse_temp_min/       # Superseded by current default (temp_med)
    └── mvse_old_scripts/    # Standalone dev scripts, no longer executed
```

### Per-state layout

```
<state>/
├── mvse/
│   ├── scripts/             # 00a_filter_climate, 00b_split_geocodes, 01_executar_mvse, 99_combine_indexp
│   ├── inputs/              # <state>_climate.csv (for PE, GO, PR; others regenerate locally)
│   └── outputs/             # <state>_indexP_combined.csv (consolidated MVSE result)
└── dlnm/
    ├── scripts/
    │   ├── functions_dlnm_offset_<state>.R     # Core engine (data, cross-basis, fit, plot)
    │   ├── run_all_models_offset.R             # Run all individual + combined models
    │   ├── run_individual_<variable>_offset.R  # Individual model wrapper
    │   ├── run_combined_temp_*_precip_humid_offset.R  # Combined model wrapper
    │   ├── finalize_reports_offset.R           # Consolidate QC and summary reports
    │   └── avaliar_modelos_AIC_QAIC_<state>_offset.R  # Model selection
    ├── data/                # Dengue, climate, indexP, population CSVs
    └── results/
        ├── figures/         # DLNM figures (individual & combined: contour, slice, 3D)
        └── summaries/       # QC reports, model rankings, diagnostics
```

---

## States covered

| State | IBGE prefix | Municipalities | MVSE | DLNM | Notes |
|---|---|---|---|---|---|
| Pernambuco (PE) | 26 | 185 | Yes | Yes | Includes predictive validation (PE 2017-2022 → 2023-2024) |
| Goiás (GO) | 52 | 246 | Yes | Yes | |
| Rio de Janeiro (RJ) | 33 | 92 | Yes | Yes | |
| Rio Grande do Sul (RS) | 43 | 497 | Yes | Yes | Sensitivity analysis on geocode case-filtering |

---

## Data acquisition

### Climate data (InfoDengue)

- **Source:** “Full dataset for dengue forecasting in Brazil for Infodengue-Mosqlimate sprint 2024” (DOI: 10.5281/zenodo.13328231)
- **Format:** Single national CSV with weekly climate (temperature, humidity, precipitation) by municipality.
- **File name expected by the pipeline:** `infodengue_sprint_24-25/climate.csv/climate.csv`
  (a national weekly CSV; the path is configured in each state's `00a_filter_climate.py`).
- **Acquisition steps:**
  1. Clone or download the InfoDengue Sprint 2024-2025 release.
  2. Place the national climate CSV at `<repo-root>/infodengue_sprint_24-25/climate.csv/` (or
     edit `00a_filter_climate.py` lines 1-10 to match the source).
- **What is versioned here:** The pre-filtered per-state CSVs for PE and GO.
  (`<state>/mvse/inputs/<state>_climate.csv`) are already in the repository. For RJ and RS,
  the script will filter from the national CSV on first run.

### Dengue case data 

- **Source:** The time series of dengue notifications and climatic variables were obtained from the repository “Full dataset for dengue forecasting in Brazil for Infodengue-Mosqlimate sprint 2024” (DOI: 10.5281/zenodo.13328231), linked to the Mosqlimate Project. Dengue data are sourced from the Notifiable Diseases Information System (SINAN).
- **File per state:** `<state>/dlnm/data/dengue_<state>_consolidado.csv`
  (weekly dengue case counts by municipality).

### Population data (IBGE)

- **Source:** IBGE municipal population estimates.
- **File (per state):** `<state>/dlnm/data/br_ibge_populacao_municipio_filtrado.csv`
- **License:** Public domain.

### Restricted data (NOT versioned)

These files are sensitive or restricted and are listed in `.gitignore`. Place them locally only:

| File | Reason |
|---|---|
| `Lab_Denv.csv` | Lab PCR results from passive surveillance — restricted by InfoDengue terms |
| `df_sorotipo.csv` | Dengue serotype data — restricted by surveillance system terms |
| `infodengue_sprint_24-25/` | Large national CSV — downloaded locally |

See `.gitignore` for the full pattern list.

### Large files on Zenodo

GitHub rejects files larger than 100 MB. Three categories of large files used by this study are
hosted on **Zenodo** instead, and linked from this README.

**Deposit DOI:** [`10.5281/zenodo.22310988`](https://doi.org/10.5281/zenodo.22310988)

**Record page:** https://zenodo.org/record/22310988

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.22310988.svg)](https://doi.org/10.5281/zenodo.22310988)

| ZIP archive | Contents | Uncompressed size | Compressed size |
|---|---|---|---|
| `national_climate_zenodo.csv.zip` | `cross_state/data/inputs_climate_zenodo_todos_os_estados.csv` (national climate CSV) | 550 MB | 169 MB |
| `pernambuco_diagnostico_figures.zip` | 9 large DLNM diagnostic SVG figures for Pernambuco | ~870 MB | 108 MB |
| `other_states_diagnostico_figures.zip` | 28 large DLNM diagnostic SVG figures for Goiás, Rio de Janeiro, Rio Grande do Sul | ~2.2 GB | 298 MB |

**Automated download:** the helper script `scripts/fetch_zenodo_data.py` downloads each ZIP and
unpacks it back into the canonical repo paths. From the repo root:

```bash
python scripts/fetch_zenodo_data.py --record 22310988
```

Each ZIP is checksummed with SHA-256 (see `MANIFEST.json` next to the deposit) and verified
before extraction.

---

## MVSE pipeline

### Data format

Each municipality CSV (per-geocode, **not included** in the repo — regenerable via scripts)
contains:

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
python scripts/99_combine_indexp.py      # Consolidate into single CSV
```

**Output:** `<state>_indexP_combined.csv` with columns `geocode, date, indexP`.

### R dependencies (MVSE)

- `MVSE (>= 1.0.1)`
- `data.table`
- `parallel`, `doParallel`, `foreach`
- `pbapply`
- `scales`, `genlasso`

---

## DLNM pipeline

### Data files (per state)

| File | Description |
|---|---|
| `dengue_<state>_consolidado.csv` | Weekly dengue case counts by municipality |
| `climate_<state>_<years>.csv` | Climate variables by municipality |
| `mvse_<state>_consolidado.csv` | MVSE-estimated indexP by municipality |
| `br_ibge_populacao_municipio_filtrado.csv` | IBGE population estimates |

### Model specification

- **Model:** Negative Binomial GLM (`MASS::glm.nb`)
- **Offset:** `log(Pop_i / 100000)` (population-standardized rate)
- **Cross-basis:** `dlnm::crossbasis` with natural cubic splines for exposure and lag dimensions
- **Panel:** grouped by municipality (`geocode`)
- **Lag window:** 0–12 weeks
- **Variables modeled:**
  - **Individual:** `indexP`, `temp_min`, `temp_med`, `temp_max`, `rel_humid_med`, `precip_tot`
  - **Combined:** `temp_min + precip + humid`, `temp_med + precip + humid`, `temp_max + precip + humid`

### Scripts per state

| Script | Purpose |
|---|---|
| `functions_dlnm_offset_<state>.R` | Core engine: data loading, cross-basis, fitting, plotting |
| `run_all_models_offset.R` | Run all individual + combined models |
| `run_individual_<variable>_offset.R` | Individual model wrapper |
| `run_combined_temp_*_precip_humid_offset.R` | Combined model wrapper |
| `finalize_reports_offset.R` | Consolidate QC and summary reports |
| `avaliar_modelos_AIC_QAIC_<state>_offset.R` | Model comparison via AIC/QAIC |

### How to run DLNM for a state

```bash
cd <state>/dlnm/scripts
Rscript run_all_models_offset.R                          # Fit all models
Rscript finalize_reports_offset.R                        # Consolidate QC and summary reports
Rscript avaliar_modelos_AIC_QAIC_<state>_offset.R        # Model selection
```

To extend the study window, call the engine functions with custom `start_year`/`end_year`:

```r
source("functions_dlnm_offset_<state>.R")
prepared <- prepare_base_with_population(
  data_dir       = "<state>/dlnm/data",
  summaries_dir  = "<state>/dlnm/results/summaries",
  start_year     = 2010,   # override default 2017
  end_year       = 2024
)
```

### R dependencies (DLNM)

- `dlnm`
- `splines`
- `MASS`
- `ggplot2`
- `dplyr`
- `lubridate`

---

## Cross-state analysis

The `cross_state/` folder combines results across all four DLNM states (PE, GO, RJ, RS):

- **Combined slice/lag figures:** `indexP_slices_lags_0_12_offset_*.png/.svg`
- **Combined contour plots:** `Contorno_Combinado_*.png`
- **Comparative RR by variable:** `RR_Variaveis_Lag_*.png`, `RR_Variaveis_e_IndexP_*.png`
- **Lag tables:** Per-variable lag-specific RR figures (lag 0–12) and contour data

Run from the repo root:

```bash
cd cross_state/scripts
python combinar_indexP_slices_lags_0_12_offset_estados.py
Rscript gerar_figuras_slices_lags_0_12_offset_estados.R
```

---

## Cross-state derivative analysis

The `cross_state/derivative/` module is a **complementary** analysis that investigates the
**rate of change** of daily dengue incidence per state, alongside the IndexP barrier ratio
`B_p = indexP(t − τ) / (incidence + 1)`. It does **not** feed back into the DLNM risk models;
it provides diagnostic/visual validation of outbreak timing and detection thresholds.

It reproduces the logic of the original exploratory notebook
(`cross_state/derivative/notebook/temporal_derivative.ipynb`) as a deterministic Python pipeline
(`cross_state/derivative/scripts/export_artifacts.py`).

### Outputs produced

- `outputs/tables/derivative_incidence_all_states.csv` — first (`_dt`) and second (`_st`) derivative of daily incidence
- `outputs/tables/derivative_season_<STATE>_<SEASON>.csv` — `_dt`, `_st`, expanding mean (`_mu_t`), expanding standard deviation (`_sigma_t`)
- `outputs/tables/derivative_alerts_<STATE>_<SEASON>.csv` — boolean alert matrix for k ∈ [0, 3] (step 0.125)
- `outputs/tables/fpr_tpr_table_<STATE>_<SEASON>.csv` — alert precision/recall against outbreak ground-truth
- `outputs/figures/first_derivative_incidence.png` — 4-state stacked panel
- `outputs/figures/processing_panel_4states.png` — B_p + incidence overlay
- `outputs/figures/fpr_tpr_curve_<STATE>.png` — k-sweep diagnostic

### How to run

```bash
python cross_state/derivative/scripts/export_artifacts.py
```

Inputs are read from the consolidated state CSVs in the main repo (no preprocessing required).
To enable FPR/TPR estimated from real outbreak data, place a `Lab_Denv.csv` at
`cross_state/data/Lab_Denv.csv` before running. See `cross_state/derivative/scripts/README.md`
for details.

---

## Quick reproduction (high-level)

```bash
# 0. (one-time) Install R + Python dependencies; clone InfoDengue data into the repo

# 1. MVSE for one state (per-municipality climate CSVs needed)
cd <state>/mvse
python scripts/00a_filter_climate.py
python scripts/00b_split_geocodes.py
Rscript scripts/01_executar_mvse.R
python scripts/99_combine_indexp.py

# 2. DLNM risk models (state-level)
cd ../dlnm/scripts
Rscript run_all_models_offset.R
Rscript finalize_reports_offset.R
Rscript avaliar_modelos_AIC_QAIC_<state>_offset.R

# 3. Cross-state combined figures
cd ../../../cross_state/scripts
python combinar_indexP_slices_lags_0_12_offset_estados.py
Rscript gerar_figuras_slices_lags_0_12_offset_estados.R

# 4. Temporal-derivative diagnostic
python ../derivative/scripts/export_artifacts.py
```

---

## Reproducibility notes

- Per-municipality geocode CSVs (~1,800+ files total) are **not included** in this repository.
  They can be regenerated by running `00a_filter_climate.py` and `00b_split_geocodes.py` with
  the national climate CSV.
- Per-municipality `estimated_indexP.csv` files (MVSE outputs) are also **not included** —
  run the MVSE pipeline to regenerate.
- Only **consolidated** CSVs (`*_combined.csv`, `*_consolidado.csv`) and all **scripts** are
  version-controlled.
- `MVSE 1.0.1` must be installed locally in R. See [MVSE on GitHub](https://github.com/aldomann/MVSE).
- Self-test: `python validate_repo.py` runs ~250 integrity assertions across the repo (folder
  structure, file presence, R/Python syntax, .gitignore effectiveness).

### About the `legacy/` folder

The `legacy/` folder contains **earlier iterations** of the MVSE pipeline:

- `legacy/mvse_temp_med/` — original MVSE experiments using `temp_med` as the canonical temperature
  variable. These scripts are functionally equivalent to the current `mvse/scripts/01_executar_mvse.R`
  and are kept for reference.
- `legacy/mvse_temp_min/` — earlier experiments using `temp_min` as the canonical temperature
  variable (an alternate sensitivity setting).
- `legacy/mvse_old_scripts/` — standalone development scripts from before the current MVSE
  pipeline was finalized. Not executed by any current pipeline.

These scripts are **not** required to reproduce the results. They are versioned for historical
traceability of the methodology iterations.

---

## Python dependencies

- `pandas`, `numpy`, `matplotlib`, `Pillow`, `svgutils`, `scikit-learn`, `scipy`
- `jupyter` (only for running `temporal_derivative.ipynb` interactively)

Install with:

```bash
pip install pandas numpy matplotlib Pillow svgutils scikit-learn scipy jupyter
```

---

## How to cite

If you use this code or data, please cite:

- **Barbosa, D. A. M.** (2026). Dengue Climate-Suitability and DLNM Analysis in Brazilian States
- **Lourenço, J. & Obolski, U.** (2021). MVSE — Mosquito-borne Viral Suitability Estimator.
  *PLOS Neglected Tropical Diseases*.
- **InfoDengue / AlertaDengue** — climate and dengue surveillance data.
- **IBGE** — Brazilian municipal population estimates.

A `CITATION.cff` file at the repo root provides GitHub-native citation metadata.

---

## License

This repository is released under the **MIT License** (see [LICENSE](LICENSE)). Underlying data
remains subject to the terms of the original data sources (InfoDengue, IBGE).
