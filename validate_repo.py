#!/usr/bin/env python3
"""
Validation script for the reorganized dengue/DLNM repository.
Checks structure, file integrity, git status, and reproducibility readiness.
"""

import os
import sys
import subprocess
from pathlib import Path

REPO_ROOT = Path(__file__).parent


passed = 0
failed = 0
errors = []

def check(name, condition, detail=""):
    global passed, failed
    if condition:
        passed += 1
        print(f"  [PASS] {name}")
    else:
        failed += 1
        msg = f"  [FAIL] {name}" + (f" -- {detail}" if detail else "")
        errors.append(msg)
        print(msg)

def section(title):
    print(f"\n{'='*60}")
    print(f"  {title}")
    print(f"{'='*60}")



def test_root_files():
    section("1. Root Files")
    check("README.md exists", (REPO_ROOT / "README.md").exists())
    check(".gitignore exists", (REPO_ROOT / ".gitignore").exists())
    check("validate_repo.py exists", (REPO_ROOT / "validate_repo.py").exists())


    readme = (REPO_ROOT / "README.md").read_text(encoding="utf-8")
    check("README has title", "# Dengue" in readme)
    check("README has structure tree", "Repository Structure" in readme or "├──" in readme)
    check("README has MVSE section", "MVSE" in readme)
    check("README has DLNM section", "DLNM" in readme)
    check("README has data sources", "Data Sources" in readme or "InfoDengue" in readme)
    check("README has reproducibility notes", "Reproducibility" in readme or "reproducibility" in readme)


    gitignore = (REPO_ROOT / ".gitignore").read_text(encoding="utf-8")
    check(".gitignore excludes geocodes", "geocodes" in gitignore)
    check(".gitignore excludes indexP_tempMed_humMed", "indexP_tempMed_humMed" in gitignore)
    check(".gitignore excludes __pycache__", "__pycache__" in gitignore)
    check(".gitignore excludes .Rhistory", ".Rhistory" in gitignore)
    check(".gitignore excludes .RData", ".RData" in gitignore)


def test_state_folders():
    section("2. State Folders Exist")

    states = {
        "goias": {"mvse": True, "dlnm": True},
        "pernambuco": {"mvse": True, "dlnm": True},
        "rio_de_janeiro": {"mvse": True, "dlnm": True},
        "rio_grande_do_sul": {"mvse": True, "dlnm": True},
        "parana": {"mvse": True, "dlnm": False},
        "santa_catarina": {"mvse": True, "dlnm": False},
    }

    for state, pipelines in states.items():
        state_path = REPO_ROOT / state
        check(f"{state}/ folder exists", state_path.exists())

        for pipeline, expected in pipelines.items():
            pipeline_path = state_path / pipeline
            check(f"{state}/{pipeline}/ exists", pipeline_path.exists() == expected,
                  f"Expected: {expected}, Got: {pipeline_path.exists()}")


def test_mvse_scripts():
    section("3. MVSE Scripts Per State")

    states_with_mvse = ["goias", "pernambuco", "rio_de_janeiro", "rio_grande_do_sul", "parana", "santa_catarina"]


    standard_scripts = ["01_executar_mvse.R", "99_combine_indexp.py"]


    full_scripts = ["00a_filter_climate.py", "00b_split_geocodes.py", "01_executar_mvse.R", "99_combine_indexp.py"]

    for state in states_with_mvse:
        scripts_dir = REPO_ROOT / state / "mvse" / "scripts"
        if not scripts_dir.exists():
            check(f"{state}/mvse/scripts/ exists", False)
            continue

        all_scripts = list(scripts_dir.glob("*"))
        check(f"{state}/mvse/scripts/ has files", len(all_scripts) > 0,
              f"Found {len(all_scripts)} files")

        for script in standard_scripts:
            check(f"{state}/mvse/scripts/{script} exists", (scripts_dir / script).exists())


        if state != "rio_de_janeiro":
            for script in full_scripts:
                check(f"{state}/mvse/scripts/{script} exists", (scripts_dir / script).exists())


def test_mvse_inputs_outputs():
    section("4. MVSE Inputs & Outputs")


    mvse_outputs = {
        "goias": "goias_indexP_combined.csv",
        "pernambuco": "pernambuco_indexP_combined.csv",
    }

    mvse_climate_inputs = {
        "goias": "goias_climate.csv",
        "pernambuco": "pernambuco_climate.csv",
        "parana": "parana_climate.csv",
    }

    for state, filename in mvse_outputs.items():
        check(f"{state}/mvse/outputs/{filename} exists",
              (REPO_ROOT / state / "mvse" / "outputs" / filename).exists())

    for state, filename in mvse_climate_inputs.items():
        check(f"{state}/mvse/inputs/{filename} exists",
              (REPO_ROOT / state / "mvse" / "inputs" / filename).exists())


    check("pernambuco/mvse/inputs/geocodes_pernambuco.csv exists",
          (REPO_ROOT / "pernambuco" / "mvse" / "inputs" / "geocodes_pernambuco.csv").exists())


def test_dlnm_scripts():
    section("5. DLNM Scripts Per State")

    states_with_dlnm = ["goias", "pernambuco", "rio_de_janeiro", "rio_grande_do_sul"]


    core_scripts = [
        "functions_dlnm_offset",
        "run_all_models_offset.R",
        "run_individual_indexP_offset.R",
        "run_individual_temp_min_offset.R",
        "run_individual_temp_med_offset.R",
        "run_individual_temp_max_offset.R",
        "run_individual_rel_humid_med_offset.R",
        "run_individual_precip_tot_offset.R",
        "run_combined_temp_min_precip_humid_offset.R",
        "run_combined_temp_med_precip_humid_offset.R",
        "run_combined_temp_max_precip_humid_offset.R",
        "finalize_reports_offset.R",
    ]

    for state in states_with_dlnm:
        scripts_dir = REPO_ROOT / state / "dlnm" / "scripts"
        if not scripts_dir.exists():
            check(f"{state}/dlnm/scripts/ exists", False)
            continue

        all_scripts = list(scripts_dir.glob("*.R"))
        check(f"{state}/dlnm/scripts/ has .R files", len(all_scripts) >= 10,
              f"Found {len(all_scripts)} .R files")


        functions_scripts = list(scripts_dir.glob("functions_dlnm_offset_*.R"))
        check(f"{state}/dlnm/scripts/ has functions_dlnm_offset_*.R",
              len(functions_scripts) > 0, "No functions_dlnm_offset_*.R found")

        for script in core_scripts:
            if script == "functions_dlnm_offset":
                continue
            check(f"{state}/dlnm/scripts/{script} exists",
                  (scripts_dir / script).exists())


        aic_scripts = list(scripts_dir.glob("avaliar_modelos_AIC_QAIC*.R"))
        check(f"{state}/dlnm/scripts/ has avaliar_modelos_AIC_QAIC*.R",
              len(aic_scripts) > 0)


def test_dlnm_data():
    section("6. DLNM Data Files Per State")

    states_with_dlnm = ["goias", "pernambuco", "rio_de_janeiro", "rio_grande_do_sul"]

    for state in states_with_dlnm:
        data_dir = REPO_ROOT / state / "dlnm" / "data"
        if not data_dir.exists():
            check(f"{state}/dlnm/data/ exists", False)
            continue

        all_files = list(data_dir.glob("*"))
        check(f"{state}/dlnm/data/ has files", len(all_files) >= 3,
              f"Found {len(all_files)} files")


        dengue_files = list(data_dir.glob("dengue_*.csv"))
        check(f"{state}/dlnm/data/ has dengue_*.csv", len(dengue_files) > 0)


        climate_files = list(data_dir.glob("climate_*.csv"))
        check(f"{state}/dlnm/data/ has climate_*.csv", len(climate_files) > 0)


        pop_files = list(data_dir.glob("br_ibge_populacao*.csv"))
        check(f"{state}/dlnm/data/ has br_ibge_populacao*.csv", len(pop_files) > 0)


        indexp_files = list(data_dir.glob("indexP_*.csv")) + list(data_dir.glob("mvse_*consolidado*.csv"))
        check(f"{state}/dlnm/data/ has indexP/mvse data", len(indexp_files) > 0,
              "No indexP_*.csv or mvse_*consolidado*.csv found")


def test_dlnm_results():
    section("7. DLNM Results Per State")

    states_with_dlnm = ["goias", "pernambuco", "rio_de_janeiro", "rio_grande_do_sul"]

    for state in states_with_dlnm:
        results_dir = REPO_ROOT / state / "dlnm" / "results"
        if not results_dir.exists():
            check(f"{state}/dlnm/results/ exists", False)
            continue


        figures_dir = results_dir / "figures"
        check(f"{state}/dlnm/results/figures/ exists", figures_dir.exists())

        if figures_dir.exists():
            individuais = figures_dir / "individuais"
            combinados = figures_dir / "combinados"
            check(f"{state}/dlnm/results/figures/individuais/ exists", individuais.exists())
            check(f"{state}/dlnm/results/figures/combinados/ exists", combinados.exists())

            if individuais.exists():
                svg_files = list(individuais.rglob("*.svg"))
                check(f"{state}/ figures/individuais/ has SVG files", len(svg_files) > 0,
                      f"Found {len(svg_files)} SVG files")

            if combinados.exists():
                svg_files = list(combinados.rglob("*.svg"))
                check(f"{state}/ figures/combinados/ has SVG files", len(svg_files) > 0,
                      f"Found {len(svg_files)} SVG files")


        summaries_dir = results_dir / "summaries"
        check(f"{state}/dlnm/results/summaries/ exists", summaries_dir.exists())

        if summaries_dir.exists():
            md_files = list(summaries_dir.glob("*.md"))
            check(f"{state}/ results/summaries/ has .md reports", len(md_files) > 0,
                  f"Found {len(md_files)} .md files")

            csv_files = list(summaries_dir.glob("*.csv"))
            check(f"{state}/ results/summaries/ has .csv files", len(csv_files) > 0,
                  f"Found {len(csv_files)} .csv files")


def test_rs_sensitivity():
    section("8. Rio Grande do Sul Sensitivity Analysis")

    rs_root = REPO_ROOT / "rio_grande_do_sul" / "dlnm"


    sens_scripts = rs_root / "scripts" / "sensitivity"
    check("RS sensitivity scripts folder exists", sens_scripts.exists())
    if sens_scripts.exists():
        check("RS sensitivity has README.md",
              (sens_scripts / "README.md").exists())
        check("RS sensitivity has run_sensitivity_audit_no_plots.R",
              (sens_scripts / "run_sensitivity_audit_no_plots.R").exists())


    sens_results = rs_root / "results" / "sensitivity"
    check("RS sensitivity results folder exists", sens_results.exists())


    review = rs_root / "results" / "review_data_cleaning"
    check("RS review_data_cleaning folder exists", review.exists())


def test_pe_prediction():
    section("9. Pernambuco Prediction Analysis")

    pe_pred = REPO_ROOT / "pernambuco" / "dlnm" / "prediction"
    check("PE prediction folder exists", pe_pred.exists())

    if pe_pred.exists():
        r_files = list(pe_pred.glob("*.R"))
        check("PE prediction has .R scripts", len(r_files) > 0,
              f"Found {len(r_files)} .R files")


        validation = pe_pred / "validation"
        check("PE prediction/validation/ exists", validation.exists())
        if validation.exists():
            val_r = list(validation.glob("*.R"))
            check("PE prediction/validation/ has .R scripts", len(val_r) > 0)


def test_cross_state():
    section("10. Cross-State Analysis")

    cs = REPO_ROOT / "cross_state"

    # Scripts
    cs_scripts = cs / "scripts"
    check("cross_state/scripts/ exists", cs_scripts.exists())
    if cs_scripts.exists():
        check("cross_state/scripts/ has .py file",
              len(list(cs_scripts.glob("*.py"))) > 0)
        check("cross_state/scripts/ has .R file",
              len(list(cs_scripts.glob("*.R"))) > 0)

    # Data
    cs_data = cs / "data"
    check("cross_state/data/ exists", cs_data.exists())
    if cs_data.exists():
        check("cross_state/data/ has lag table CSV",
              len(list(cs_data.glob("*.csv"))) > 0)

    # Figures
    cs_figures = cs / "figures"
    check("cross_state/figures/ exists", cs_figures.exists())
    if cs_figures.exists():
        all_png = list(cs_figures.rglob("*.png"))
        check("cross_state/figures/ has PNG files", len(all_png) > 0,
              f"Found {len(all_png)} PNG files")

    # Lag tables
    cs_lags = cs / "lag_tables"
    check("cross_state/lag_tables/ exists", cs_lags.exists())
    if cs_lags.exists():
        lag_subdirs = [d for d in cs_lags.iterdir() if d.is_dir()]
        check("cross_state/lag_tables/ has subfolders",
              len(lag_subdirs) >= 5,
              f"Found {len(lag_subdirs)} subfolders (expected >=5)")

        expected_vars = ["indexP", "temp_min", "temp_med", "temp_max", "rel_humid_med", "precip_tot"]
        for var in expected_vars:
            var_dir = cs_lags / var
            check(f"cross_state/lag_tables/{var}/ exists", var_dir.exists())
            if var_dir.exists():
                contour_csv = list(var_dir.glob("contour_data_*.csv"))
                check(f"cross_state/lag_tables/{var}/ has contour_data CSV",
                      len(contour_csv) > 0)
                lag_pngs = list((var_dir / "graficos_lags").glob("*.png"))
                check(f"cross_state/lag_tables/{var}/ has lag PNG figures",
                      len(lag_pngs) >= 10,
                      f"Found {len(lag_pngs)} PNGs (expected >=10)")

    # Derivative module
    cs_deriv = cs / "derivative"
    check("cross_state/derivative/ exists", cs_deriv.exists())
    if cs_deriv.exists():
        nb_dir = cs_deriv / "notebook"
        check("cross_state/derivative/notebook/ exists", nb_dir.exists())
        if nb_dir.exists():
            check("cross_state/derivative/notebook/ has temporal_derivative.ipynb",
                  (nb_dir / "temporal_derivative.ipynb").exists())

        scripts_dir = cs_deriv / "scripts"
        check("cross_state/derivative/scripts/ exists", scripts_dir.exists())
        if scripts_dir.exists():
            check("cross_state/derivative/scripts/ has export_artifacts.py",
                  (scripts_dir / "export_artifacts.py").exists())
            check("cross_state/derivative/scripts/ has README.md",
                  (scripts_dir / "README.md").exists())

        outputs_dir = cs_deriv / "outputs"
        check("cross_state/derivative/outputs/ exists", outputs_dir.exists())
        if outputs_dir.exists():
            check("cross_state/derivative/outputs/figures/ exists",
                  (outputs_dir / "figures").exists())
            check("cross_state/derivative/outputs/tables/ exists",
                  (outputs_dir / "tables").exists())


def test_legacy():
    section("11. Legacy Folder")

    legacy = REPO_ROOT / "legacy"
    check("legacy/ exists", legacy.exists())


    temp_med = legacy / "mvse_temp_med"
    check("legacy/mvse_temp_med/ exists", temp_med.exists())
    if temp_med.exists():
        check("legacy/mvse_temp_med/scripts/ has files",
              len(list((temp_med / "scripts").glob("*"))) > 0)


    temp_min = legacy / "mvse_temp_min"
    check("legacy/mvse_temp_min/ exists", temp_min.exists())
    if temp_min.exists():
        check("legacy/mvse_temp_min/scripts/ has files",
              len(list((temp_min / "scripts").glob("*"))) > 0)


    old = legacy / "mvse_old_scripts"
    check("legacy/mvse_old_scripts/ exists", old.exists())
    if old.exists():
        check("legacy/mvse_old_scripts/ has files",
              len(list(old.glob("*"))) > 0)


def test_no_old_folders():
    section("12. Old Folders Removed")

    old_folders = [
        "DLNM MASS + OFFSET",
        "mvse",
    ]

    for folder in old_folders:
        check(f"'{folder}' removed", not (REPO_ROOT / folder).exists())


def test_no_spaces_in_paths():
    section("13. No Spaces in Folder Names")

    for root, dirs, files in os.walk(REPO_ROOT):

        if ".git" in root:
            continue
        for d in dirs:
            if " " in d:
                check(f"No spaces in folder: {d}", False,
                      f"Found space in: {os.path.join(root, d)}")
                return
    check("No spaces in any folder name", True)


def test_no_geocode_csvs_tracked():
    section("14. No Per-Geocode CSVs (should be gitignored)")

    geocode_dirs = []
    for state in ["goias", "pernambuco", "rio_de_janeiro", "rio_grande_do_sul", "parana", "santa_catarina"]:
        geocode_dir = REPO_ROOT / state / "mvse" / "inputs" / "geocodes"
        if geocode_dir.exists():
            csvs = list(geocode_dir.glob("*.csv"))
            check(f"{state}/mvse/inputs/geocodes/ has no CSVs", len(csvs) == 0,
                  f"Found {len(csvs)} CSV files")

        indexP_dir = REPO_ROOT / state / "mvse" / "outputs" / "indexP_tempMed_humMed"
        if indexP_dir.exists():
            subdirs = [d for d in indexP_dir.iterdir() if d.is_dir()]
            check(f"{state}/mvse/outputs/indexP_tempMed_humMed/ has no subdirs", len(subdirs) == 0,
                  f"Found {len(subdirs)} subdirs")


def test_git_status():
    section("15. Git Status")

    try:
        result = subprocess.run(
            ["git", "status", "--short"],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
            timeout=10
        )
        uncommitted = [l for l in result.stdout.strip().split("\n") if l.strip()]
        check("Git working tree is clean", len(uncommitted) == 0,
              f"{len(uncommitted)} uncommitted files" + (f": {uncommitted[:3]}" if uncommitted else ""))
    except Exception as e:
        check("Git status command works", False, str(e))

    try:
        result = subprocess.run(
            ["git", "log", "--oneline", "-1"],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
            timeout=10
        )
        check("Git has at least 1 commit", "Initial commit" in result.stdout or len(result.stdout.strip()) > 0,
              result.stdout.strip())
    except Exception as e:
        check("Git log command works", False, str(e))


def test_gitignore_effectiveness():
    section("16. .gitignore Effectiveness")

    gitignore = (REPO_ROOT / ".gitignore").read_text(encoding="utf-8")


    patterns = {
        "geocodes/*.csv": "Per-geocode CSVs",
        "indexP_tempMed_humMed/": "MVSE per-municipality outputs",
        "__pycache__/": "Python cache",
        ".Rhistory": "R history",
        "*.log": "Log files",
        ".DS_Store": "macOS files",
    }

    for pattern, desc in patterns.items():
        check(f".gitignore blocks {desc}", pattern in gitignore)


def test_file_encoding():
    section("17. File Encoding (UTF-8)")


    try:
        (REPO_ROOT / "README.md").read_text(encoding="utf-8")
        check("README.md is valid UTF-8", True)
    except Exception as e:
        check("README.md is valid UTF-8", False, str(e))


    try:
        (REPO_ROOT / ".gitignore").read_text(encoding="utf-8")
        check(".gitignore is valid UTF-8", True)
    except Exception as e:
        check(".gitignore is valid UTF-8", False, str(e))


def test_script_count():
    section("18. Script Count Summary")

    r_count = len(list(REPO_ROOT.rglob("*.R")))
    py_count = len(list(REPO_ROOT.rglob("*.py")))


    py_count -= 1

    check(f"R scripts: {r_count} (expected >=60)", r_count >= 60,
          f"Found {r_count}")
    check(f"Python scripts: {py_count} (expected >=15)", py_count >= 15,
          f"Found {py_count}")

    print(f"\n  Total R scripts: {r_count}")
    print(f"  Total Python scripts: {py_count}")




if __name__ == "__main__":
    print("\n" + "=" * 60)
    print("  REPOSITORY VALIDATION SUITE")
    print("  Dengue Climate-Suitability & DLNM Analysis")
    print("=" * 60)

    tests = [
        test_root_files,
        test_state_folders,
        test_mvse_scripts,
        test_mvse_inputs_outputs,
        test_dlnm_scripts,
        test_dlnm_data,
        test_dlnm_results,
        test_rs_sensitivity,
        test_pe_prediction,
        test_cross_state,
        test_legacy,
        test_no_old_folders,
        test_no_spaces_in_paths,
        test_no_geocode_csvs_tracked,
        test_git_status,
        test_gitignore_effectiveness,
        test_file_encoding,
        test_script_count,
    ]

    for test in tests:
        try:
            test()
        except Exception as e:
            failed += 1
            errors.append(f"  [ERROR] {test.__name__} -- {e}")
            print(f"  [ERROR] {test.__name__} -- {e}")


    total = passed + failed
    print(f"\n{'='*60}")
    print(f"  SUMMARY: {passed}/{total} passed, {failed} failed")
    print(f"{'='*60}")

    if failed > 0:
        print(f"\n  Failed tests:")
        for err in errors:
            print(err)

    print()
    sys.exit(0 if failed == 0 else 1)