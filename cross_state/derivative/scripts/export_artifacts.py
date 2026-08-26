"""
Export artifacts for the temporal-derivative analysis.

Reproduces the relevant cells of cross_state/derivative/notebook/temporal_derivative.ipynb
without relying on a notebook runtime:

- combined_df            -> combined_daily_cases_<STATE>.csv
- incidence_df           -> incidence_per_100k_<STATE>.csv
- indexP + processing_df -> processing_ratio_<STATE>.csv
- deriv_incidence_df     -> derivative_incidence_<STATE>.csv (first + second derivative)
- per-season window      -> derivative_season_<STATE>_<SEASON>.csv (dt/st/mu_t/sigma_t)
- dt_kvalues_df          -> derivative_alerts_<STATE>_<SEASON>.csv
- fpr_tpr_df             -> fpr_tpr_table_<STATE>_<SEASON>.csv
- bar/p(t)/I(t)/tau line -> derivative_combined_4states.png/svg
- derivative over time   -> first_derivative_incidence.png/svg
- FPR/TPR curve          -> fpr_tpr_curve_<STATE>.png/svg

Inputs (one row per municipality/day):
  cross_state/data/extrair_defasagem_indexP.R uses consolidated state CSVs from
  <STATE>/mvse/outputs/<STATE>_indexP_combined.csv (date, geocode, indexP, ...)
  <STATE>/dlnm/data/dengue_<STATE>_consolidado.csv (date, geocode, casos, ...)

Optional outbreak ground-truth (Lab_Denv.csv) is required for FPR/TPR. If absent,
the script still exports derivative artifacts and warns the user.

Run:
  python cross_state/derivative/scripts/export_artifacts.py
"""

from __future__ import annotations

import os
import sys
import warnings
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

REPO_ROOT = Path(__file__).resolve().parents[3]
DERIV_DIR = Path(__file__).resolve().parents[1]
OUTPUTS_DIR = DERIV_DIR / "outputs"
FIGURES_DIR = OUTPUTS_DIR / "figures"
TABLES_DIR = OUTPUTS_DIR / "tables"

STATES = [
    {"abbr": "PE", "name": "Pernambuco",
     "dengue_csv": REPO_ROOT / "pernambuco/dlnm/data/dengue_pe_2015_2024.csv",
     "indexp_csv": REPO_ROOT / "pernambuco/mvse/outputs/pernambuco_indexP_combined.csv",
     "population": 9058931},
    {"abbr": "GO", "name": "Goiás",
     "dengue_csv": REPO_ROOT / "goias/dlnm/data/dengue_goias_consolidado.csv",
     "indexp_csv": REPO_ROOT / "goias/mvse/outputs/goias_indexP_combined.csv",
     "population": 7056495},
    {"abbr": "RJ", "name": "Rio de Janeiro",
     "dengue_csv": REPO_ROOT / "rio_de_janeiro/dlnm/data/dengue_rio_de_janeiro_consolidado.csv",
     "indexp_csv": REPO_ROOT / "rio_de_janeiro/dlnm/data/indexP_rj_2017_2024.csv",
     "population": 16054524},
    {"abbr": "RS", "name": "Rio Grande do Sul",
     "dengue_csv": REPO_ROOT / "rio_grande_do_sul/dlnm/data/dengue_rio_grande_do_sul_consolidado.csv",
     "indexp_csv": REPO_ROOT / "rio_grande_do_sul/dlnm/data/indexP_rs_2017_2024.csv",
     "population": 10882965},
]

TAU_BY_STATE = {"Goiás": 4, "Pernambuco": 5, "Rio Grande do Sul": 8, "Rio de Janeiro": 9}
K = 1

DEFAULT_START = "2017-01-01"
DEFAULT_END = "2024-12-31"

SEASONAL_WINDOWS = {
    "2023-2024": ("2023-06-04", "2024-06-02"),
}

K_VALUES = np.arange(0, 3, 0.125)


def load_dengue(path: Path) -> pd.DataFrame:
    df = pd.read_csv(path)
    df["date"] = pd.to_datetime(df["date"])
    df = df.dropna(subset=["casos"])
    df["casos"] = df["casos"].astype(float)
    return df


def load_indexp(path: Path) -> pd.DataFrame:
    df = pd.read_csv(path)
    df["date"] = pd.to_datetime(df["date"])
    if "indexP" not in df.columns:
        if "mean_indexP" in df.columns:
            df = df.rename(columns={"mean_indexP": "indexP"})
        else:
            raise ValueError(f"No indexP column in {path}")
    return df[["date", "geocode", "indexP"]]


def build_combined(dengue_df: pd.DataFrame, population: int) -> pd.DataFrame:
    daily = (
        dengue_df.groupby("date", as_index=False)["casos"].sum()
        .sort_values("date")
        .set_index("date")
    )
    daily["incidence_per_100k"] = (daily["casos"] / population) * 100000.0
    return daily


def build_processing(combined_df: pd.DataFrame, indexp_df: pd.DataFrame, state_name: str) -> pd.DataFrame:
    daily_idxp = indexp_df.groupby("date", as_index=False)["indexP"].mean().set_index("date")
    aligned = combined_df[["incidence_per_100k"]].join(daily_idxp[["indexP"]], how="inner")
    tau = TAU_BY_STATE.get(state_name, 5)
    aligned["p_over_I_tau"] = aligned["indexP"].shift(tau) / (aligned["incidence_per_100k"] + K)
    aligned = aligned.fillna(0.0)
    if len(aligned) > 0:
        aligned = aligned.iloc[:-1]
    return aligned


def first_second_derivative(series: pd.Series) -> pd.DataFrame:
    out = pd.DataFrame(index=series.index)
    out["dt"] = series.diff().fillna(0.0)
    out["st"] = out["dt"].diff().fillna(0.0)
    out["mu_t"] = out["dt"].expanding().mean().fillna(0.0)
    out["sigma_t"] = out["dt"].expanding().std().fillna(0.0)
    return out


def detect_alerts(deriv: pd.DataFrame, k_values: np.ndarray) -> pd.DataFrame:
    alerts = pd.DataFrame(index=deriv.index)
    for k in k_values:
        col = f"k_{k:.3f}"
        alerts[col] = deriv["dt"] > (deriv["mu_t"] + k * deriv["sigma_t"])
    return alerts


def fpr_tpr(alerts: pd.DataFrame, outbreak: pd.Series, k_values: np.ndarray) -> pd.DataFrame:
    outbreak = outbreak.reindex(alerts.index).fillna(False).astype(bool)
    big_n = (outbreak == True).sum()
    big_n_line = (outbreak == False).sum()
    out = pd.DataFrame(index=["FPR", "TPR"],
                       columns=[f"k_{k:.3f}" for k in k_values])
    for k in k_values:
        col = f"k_{k:.3f}"
        n_true = ((outbreak == True) & (alerts[col] == True)).sum()
        n_line = ((outbreak == False) & (alerts[col] == True)).sum()
        out.at["TPR", col] = n_true / big_n if big_n else 0.0
        out.at["FPR", col] = n_line / big_n_line if big_n_line else 0.0
    return out


def plot_first_derivative(deriv_df: pd.DataFrame, output_path: Path) -> None:
    fig, axes = plt.subplots(len(deriv_df.columns), 1, figsize=(14, 3 * len(deriv_df.columns)),
                             sharex=True)
    if len(deriv_df.columns) == 1:
        axes = [axes]
    for ax, col in zip(axes, deriv_df.columns):
        ax.plot(deriv_df.index, deriv_df[col], color="red", label="first derivative")
        ax.axhline(0, color="gray", linestyle="--", linewidth=1.2, alpha=0.7)
        ax.set_title(col.replace("_dt", ""), fontsize=11, fontweight="bold", loc="left")
        ax.set_ylabel("Variation")
        ax.legend(loc="upper left")
    axes[-1].set_xlabel("Date")
    fig.tight_layout()
    fig.savefig(output_path, dpi=150)
    plt.close(fig)


def plot_processing_panel(per_state: dict, output_path: Path) -> None:
    fig, axes = plt.subplots(len(per_state), 1, figsize=(14, 3.2 * len(per_state)), sharex=True)
    if len(per_state) == 1:
        axes = [axes]
    for ax, (state, proc) in zip(axes, per_state.items()):
        if proc.empty:
            ax.set_title(state, fontsize=11, fontweight="bold")
            continue
        ax.plot(proc.index, proc["p_over_I_tau"], color="red", label=r"$B_p$")
        ax.axhline(0, color="gray", linestyle="--", linewidth=1.2, alpha=0.7)
        twin = ax.twinx()
        twin.plot(proc.index, proc["incidence_per_100k"], color="black", linestyle="-", linewidth=1.6,
                  label="Incidence")
        ax.set_title(state, fontsize=11, fontweight="bold", loc="left")
        ax.set_ylabel(r"$B_p$")
        twin.set_ylabel("Incidence/100k")
        ax.legend(loc="upper left")
    axes[-1].set_xlabel("Date")
    fig.tight_layout()
    fig.savefig(output_path, dpi=150)
    plt.close(fig)


def plot_fpr_tpr(fpr_tpr_df: pd.DataFrame, state: str, output_path: Path) -> None:
    fig, ax = plt.subplots(figsize=(7, 5))
    x = np.arange(len(fpr_tpr_df.columns))
    labels = [c.replace("k_", "") for c in fpr_tpr_df.columns]
    ax.plot(labels, fpr_tpr_df.loc["FPR"].astype(float).values, "-or", label="FPR")
    ax.plot(labels, fpr_tpr_df.loc["TPR"].astype(float).values, "-ob", label="TPR")
    ax.set_xlabel("k")
    ax.set_ylabel("FPR / TPR")
    ax.set_title(state)
    ax.grid(alpha=0.3)
    ax.legend()
    fig.tight_layout()
    fig.savefig(output_path, dpi=150)
    plt.close(fig)


def main() -> int:
    OUTPUTS_DIR.mkdir(parents=True, exist_ok=True)
    FIGURES_DIR.mkdir(parents=True, exist_ok=True)
    TABLES_DIR.mkdir(parents=True, exist_ok=True)

    deriv_all = []
    processing_panels = {}
    for state in STATES:
        abbr = state["abbr"]
        name = state["name"]
        print(f"[INFO] Processing {abbr} - {name}")
        try:
            dengue = load_dengue(state["dengue_csv"])
        except FileNotFoundError:
            print(f"[WARN] dengue csv not found: {state['dengue_csv']}")
            continue
        dengue = dengue[(dengue["date"] >= DEFAULT_START) & (dengue["date"] <= DEFAULT_END)]

        try:
            indexp = load_indexp(state["indexp_csv"])
        except FileNotFoundError:
            print(f"[WARN] indexP csv not found: {state['indexp_csv']}")
            indexp = pd.DataFrame(columns=["date", "geocode", "indexP"])

        combined = build_combined(dengue, state["population"])
        combined.to_csv(TABLES_DIR / f"combined_daily_cases_{abbr}.csv", index_label="date")

        proc = build_processing(combined, indexp, name)
        proc.to_csv(TABLES_DIR / f"processing_ratio_{abbr}.csv", index_label="date")
        processing_panels[name] = proc

        deriv_state = first_second_derivative(combined["incidence_per_100k"])
        deriv_state.columns = [f"{name}_{c}" for c in deriv_state.columns]
        deriv_all.append(deriv_state)

    if deriv_all:
        deriv_full = pd.concat(deriv_all, axis=1)
        deriv_full.to_csv(TABLES_DIR / "derivative_incidence_all_states.csv", index_label="date")

        fig_path = FIGURES_DIR / "first_derivative_incidence.png"
        plot_first_derivative(
            deriv_full[[c for c in deriv_full.columns if c.endswith("_dt")]],
            fig_path,
        )
        print(f"[OK] Figure -> {fig_path}")

        proc_path = FIGURES_DIR / "processing_panel_4states.png"
        plot_processing_panel(processing_panels, proc_path)
        print(f"[OK] Figure -> {proc_path}")

    seasonal_tables = []
    for label, (start, end) in SEASONAL_WINDOWS.items():
        for state in STATES:
            abbr = state["abbr"]
            name = state["name"]
            season_path = TABLES_DIR / f"derivative_season_{abbr}_{label}.csv"
            if not (TABLES_DIR / f"combined_daily_cases_{abbr}.csv").exists():
                continue
            season = pd.read_csv(TABLES_DIR / f"combined_daily_cases_{abbr}.csv",
                                 parse_dates=["date"]).set_index("date")
            season = season.loc[start:end]
            deriv = first_second_derivative(season["incidence_per_100k"])
            deriv.to_csv(season_path, index_label="date")

            alerts = detect_alerts(deriv, K_VALUES)
            alerts.to_csv(TABLES_DIR / f"derivative_alerts_{abbr}_{label}.csv", index_label="date")

            lab_path = REPO_ROOT / "cross_state" / "data" / "Lab_Denv.csv"
            outbreak = pd.Series(False, index=alerts.index)
            if lab_path.exists():
                lab = pd.read_csv(lab_path, parse_dates=["date"]).set_index("date")
                col = f"pos_pcr_{name}"
                if col in lab.columns:
                    outbreak = (lab[col].fillna(0) >= max(1, lab[col].fillna(0).max() * 0.2))
            fpr_tpr_df = fpr_tpr(alerts, outbreak, K_VALUES)
            fpr_tpr_df.to_csv(TABLES_DIR / f"fpr_tpr_table_{abbr}_{label}.csv")

            fpr_path = FIGURES_DIR / f"fpr_tpr_curve_{abbr}_{label}.png"
            plot_fpr_tpr(fpr_tpr_df, name, fpr_path)
            seasonal_tables.append((abbr, label, season_path))

    if seasonal_tables:
        print(f"[OK] Generated {len(seasonal_tables)} seasonal derivative tables.")

    print("[DONE] derivative artifacts exported to", OUTPUTS_DIR)
    return 0


if __name__ == "__main__":
    warnings.filterwarnings("ignore")
    sys.exit(main())
