source("functions_dlnm_offset_rio_grande_do_sul.R")

paths <- default_paths()
safe_dir(paths$summaries_dir)

result_files <- list.files(
  paths$summaries_dir,
  pattern = "^resultados_.*_offset\\.RData$",
  full.names = TRUE
)

model_results <- lapply(result_files, function(f) {
  model_id <- sub("^resultados_(.*)_offset\\.RData$", "\\1", basename(f))
  env <- new.env(parent = emptyenv())
  load(f, envir = env)

  model_type <- ifelse(grepl("_precip_humid$", model_id), "combined", "individual")
  exposure_main <- if (model_type == "combined") sub("_precip_humid$", "", model_id) else model_id

  data.frame(
    model_id = model_id,
    model_type = model_type,
    exposure_main = exposure_main,
    n_final = nrow(env$dados),
    geocodes = dplyr::n_distinct(env$dados$geocode),
    aic = AIC(env$modelo),
    bic = BIC(env$modelo),
    stringsAsFactors = FALSE
  )
}) %>% bind_rows() %>% arrange(model_type, model_id)

write.csv(
  model_results,
  file.path(paths$summaries_dir, "n_final_comparison_offset.csv"),
  row.names = FALSE
)

lag_files <- list.files(
  paths$summaries_dir,
  pattern = "^lag_crossing_summary_.*_offset\\.csv$",
  full.names = TRUE
)
lag_files <- lag_files[!grepl("all_models", lag_files)]
lag_summary_all <- bind_rows(lapply(lag_files, read.csv, stringsAsFactors = FALSE))

write.csv(
  lag_summary_all,
  file.path(paths$summaries_dir, "lag_crossing_summary_all_models_offset.csv"),
  row.names = FALSE
)

prepared <- prepare_base_with_population(paths$data_dir, paths$summaries_dir)
multicolin <- run_multicollinearity_diagnostics(prepared$data, paths$summaries_dir)

build_qc_report(
  summaries_dir = paths$summaries_dir,
  model_results = model_results,
  merge_integrity = prepared$merge_integrity,
  lag_summary_all = lag_summary_all,
  multicolin = multicolin
)

show_progress("Consolidacao final concluida.")

