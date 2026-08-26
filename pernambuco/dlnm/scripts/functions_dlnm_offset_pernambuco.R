suppressPackageStartupMessages({
  library(dlnm)
  library(splines)
  library(ggplot2)
  library(dplyr)
  library(lubridate)
  library(MASS)
})

show_progress <- function(message) {
  cat(sprintf("[%s] %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), message))
  flush.console()
}

safe_dir <- function(path) {
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE, showWarnings = FALSE)
  }
  invisible(path)
}

normalize_geocode <- function(x) {
  x_chr <- trimws(as.character(x))
  x_chr[x_chr %in% c("", "NA", "NaN", "NULL")] <- NA_character_

  suppressWarnings(num <- as.numeric(x_chr))
  idx_num <- !is.na(num)

  if (any(idx_num)) {
    x_chr[idx_num] <- format(num[idx_num], scientific = FALSE, trim = TRUE)
  }

  x_chr <- sub("\\.0+$", "", x_chr)
  x_chr
}

summary_one_numeric <- function(x) {
  x <- suppressWarnings(as.numeric(x))
  n_non_na <- sum(!is.na(x))

  if (n_non_na == 0) {
    return(list(
      n = 0,
      mean = NA_real_,
      sd = NA_real_,
      min = NA_real_,
      p25 = NA_real_,
      median = NA_real_,
      p75 = NA_real_,
      max = NA_real_
    ))
  }

  list(
    n = n_non_na,
    mean = mean(x, na.rm = TRUE),
    sd = sd(x, na.rm = TRUE),
    min = min(x, na.rm = TRUE),
    p25 = as.numeric(quantile(x, 0.25, na.rm = TRUE)),
    median = median(x, na.rm = TRUE),
    p75 = as.numeric(quantile(x, 0.75, na.rm = TRUE)),
    max = max(x, na.rm = TRUE)
  )
}

default_paths <- function() {
  script_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  project_dir <- normalizePath(file.path(script_dir, ".."), winslash = "/", mustWork = TRUE)

  list(
    project_dir = project_dir,
    data_dir = file.path(project_dir, "dados"),
    results_dir = file.path(project_dir, "resultados"),
    figures_root = file.path(project_dir, "resultados", "figuras"),
    summaries_dir = file.path(project_dir, "resultados", "summaries")
  )
}

model_specs_individual <- function() {
  list(
    indexP = list(var = "indexP", label = "IndexP", by = 0.1),
    precip_tot = list(var = "precip_tot", label = "Total precipitation (mm)", by = 1),
    rel_humid_med = list(var = "rel_humid_med", label = "Average relative humidity (%)", by = 1),
    temp_max = list(var = "temp_max", label = "Maximum temperature (C)", by = 0.1),
    temp_med = list(var = "temp_med", label = "Average temperature (C)", by = 0.1),
    temp_min = list(var = "temp_min", label = "Minimum temperature (C)", by = 0.1)
  )
}

model_specs_combined <- function() {
  list(
    temp_max_precip_humid = list(temp_var = "temp_max", temp_label = "Maximum temperature (C)"),
    temp_med_precip_humid = list(temp_var = "temp_med", temp_label = "Average temperature (C)"),
    temp_min_precip_humid = list(temp_var = "temp_min", temp_label = "Minimum temperature (C)")
  )
}

summarize_variables <- function(df, vars, stage) {
  out <- lapply(vars, function(v) {
    s <- summary_one_numeric(df[[v]])
    data.frame(
      stage = stage,
      variable = v,
      n = s$n,
      mean = s$mean,
      sd = s$sd,
      min = s$min,
      p25 = s$p25,
      median = s$median,
      p75 = s$p75,
      max = s$max
    )
  })

  bind_rows(out)
}

standardize_population <- function(pop_raw, target_uf = "PE") {
  possible_ano <- c("ano", "year")
  possible_id <- c("id_municipio", "geocode")
  possible_pop <- c("Pop_i", "populacao", "population", "pop")

  ano_col <- possible_ano[possible_ano %in% names(pop_raw)][1]
  id_col <- possible_id[possible_id %in% names(pop_raw)][1]
  pop_col <- possible_pop[possible_pop %in% names(pop_raw)][1]

  if (is.na(ano_col) || is.na(id_col) || is.na(pop_col)) {
    stop(
      sprintf(
        paste0(
          "Colunas obrigatorias ausentes na base populacional. ",
          "Esperado: ano/year, id_municipio/geocode, Pop_i/populacao. Encontrado: %s"
        ),
        paste(names(pop_raw), collapse = ", ")
      )
    )
  }

  pop <- pop_raw %>%
    mutate(
      ano = as.integer(.data[[ano_col]]),
      geocode = normalize_geocode(.data[[id_col]]),
      Pop_i = as.numeric(.data[[pop_col]])
    )

  if ("sigla_uf" %in% names(pop) && !is.null(target_uf)) {
    pop <- pop %>% filter(sigla_uf == target_uf)
  }

  pop <- pop %>% dplyr::select(ano, geocode, Pop_i)

  if (anyNA(pop$ano) || anyNA(pop$geocode) || anyNA(pop$Pop_i)) {
    stop("A base populacional possui NA em ano/geocode/Pop_i apos padronizacao.")
  }

  dup <- pop %>% count(ano, geocode, name = "n") %>% filter(n > 1)
  if (nrow(dup) > 0) {
    stop(
      sprintf(
        "Base populacional possui %d combinacoes duplicadas de ano + geocode. Corrija antes de seguir.",
        nrow(dup)
      )
    )
  }

  list(
    population = pop,
    validation = data.frame(
      check = c(
        "col_ano_present",
        "col_id_present",
        "col_pop_present",
        "target_uf_filter",
        "n_rows_population_filtered",
        "n_duplicate_keys_ano_geocode"
      ),
      value = c(
        ano_col,
        id_col,
        pop_col,
        ifelse(is.null(target_uf), "none", target_uf),
        nrow(pop),
        nrow(dup)
      ),
      stringsAsFactors = FALSE
    )
  )
}

prepare_base_with_population <- function(data_dir, summaries_dir, start_year = 2017, end_year = 2024) {
  show_progress("Leitura das bases de dengue, clima, indexP e populacao para Pernambuco.")

  path_dengue <- file.path(data_dir, "dengue_pe_2015_2024.csv")
  path_clima <- file.path(data_dir, "climate_pe_pos_2016_2_backup.csv")
  path_index <- file.path(data_dir, "mvse_pernambuco_consolidado.csv")
  path_pop <- file.path(data_dir, "br_ibge_populacao_municipio_filtrado.csv")

  required_paths <- c(path_dengue, path_clima, path_index, path_pop)
  missing_paths <- required_paths[!file.exists(required_paths)]
  if (length(missing_paths) > 0) {
    stop(sprintf("Arquivos obrigatorios ausentes em dados/: %s", paste(missing_paths, collapse = ", ")))
  }

  dengue <- read.csv(path_dengue, stringsAsFactors = FALSE)
  clima <- read.csv(path_clima, stringsAsFactors = FALSE)
  indexp <- read.csv(path_index, stringsAsFactors = FALSE)
  pop_raw <- read.csv(path_pop, stringsAsFactors = FALSE)

  dengue$date <- as.Date(dengue$date)
  clima$date <- as.Date(clima$date)
  indexp$date <- as.Date(indexp$date)

  dengue <- dengue %>%
    mutate(geocode = normalize_geocode(geocode)) %>%
    filter(year(date) >= start_year, year(date) <= end_year)

  clima <- clima %>%
    mutate(geocode = normalize_geocode(geocode)) %>%
    filter(year(date) >= start_year, year(date) <= end_year)

  indexp <- indexp %>%
    mutate(geocode = normalize_geocode(geocode)) %>%
    filter(year(date) >= start_year, year(date) <= end_year)

  show_progress("Merge dengue + clima + indexP (sem deduplicar linhas do painel).")
  base <- merge(dengue, clima, by = c("date", "geocode"), all = FALSE)
  base <- base %>%
    left_join(
      indexp %>% dplyr::select(date, geocode, indexP),
      by = c("date", "geocode"),
      relationship = "many-to-many"
    )

  if ("epiweek.x" %in% names(base) || "epiweek.y" %in% names(base)) {
    base$epiweek <- dplyr::coalesce(base$epiweek.x, base$epiweek.y)
    if ("epiweek.x" %in% names(base)) base$epiweek.x <- NULL
    if ("epiweek.y" %in% names(base)) base$epiweek.y <- NULL
  }

  base <- base %>%
    mutate(
      geocode = normalize_geocode(geocode),
      year = as.integer(lubridate::year(date)),
      mes = lubridate::month(date)
    ) %>%
    arrange(geocode, date)

  summary_vars <- c("casos", "indexP", "precip_tot", "rel_humid_med", "temp_max", "temp_med", "temp_min")
  descriptive_before <- summarize_variables(base, summary_vars, "before_population_offset")

  pop_std <- standardize_population(pop_raw, target_uf = "PE")
  pop <- pop_std$population %>% mutate(geocode = normalize_geocode(geocode))

  n_before <- nrow(base)
  dup_before <- sum(duplicated(base[, c("date", "geocode")]))

  show_progress("Left join com populacao por year+geocode.")
  base <- base %>%
    left_join(pop, by = c("year" = "ano", "geocode" = "geocode"))

  n_after <- nrow(base)
  dup_after <- sum(duplicated(base[, c("date", "geocode")]))

  base <- base %>%
    mutate(
      Pop_i = as.numeric(Pop_i),
      # Offset populacional aplicado aos modelos binomial negativa
      # em escala por 100 mil habitantes.
      offset = ifelse(is.na(Pop_i) | Pop_i <= 0, NA_real_, log(Pop_i / 100000)),
      time = as.numeric(difftime(date, min(date, na.rm = TRUE), units = "weeks"))
    ) %>%
    arrange(geocode, date)

  descriptive_after <- summarize_variables(
    base,
    c(summary_vars, "Pop_i", "offset"),
    "after_population_offset"
  )

  merge_integrity <- data.frame(
    metric = c(
      "n_before_population_join",
      "n_after_population_join",
      "row_count_changed_after_join",
      "duplicated_date_geocode_before_join",
      "duplicated_date_geocode_after_join",
      "missing_population_after_join",
      "missing_offset_after_join"
    ),
    value = c(
      n_before,
      n_after,
      n_after - n_before,
      dup_before,
      dup_after,
      sum(is.na(base$Pop_i)),
      sum(is.na(base$offset))
    ),
    stringsAsFactors = FALSE
  )

  safe_dir(summaries_dir)
  write.csv(pop_std$validation, file.path(summaries_dir, "population_validation_offset.csv"), row.names = FALSE)
  write.csv(merge_integrity, file.path(summaries_dir, "population_merge_integrity_offset.csv"), row.names = FALSE)
  write.csv(
    bind_rows(descriptive_before, descriptive_after),
    file.path(summaries_dir, "descriptive_before_after_offset.csv"),
    row.names = FALSE
  )

  list(
    data = base,
    merge_integrity = merge_integrity,
    population_validation = pop_std$validation
  )
}

select_model_data <- function(base_data, exposure_vars) {
  cols <- unique(c(
    "date", "geocode", "year", "mes", "time", "casos", "Pop_i", "offset",
    exposure_vars
  ))

  dados <- base_data[, cols, drop = FALSE] %>%
    mutate(geocode = normalize_geocode(geocode)) %>%
    arrange(geocode, date)

  model_required <- c("casos", "offset", exposure_vars)
  dados <- dados[complete.cases(dados[, model_required, drop = FALSE]), , drop = FALSE]
  dados <- dados %>% arrange(geocode, date)

  dados
}

deduplicate_exposure_individual <- function(dados, exposure_var) {
  # Deduplicacao apenas para grid de predicao e figuras.
  # Nao remove linhas do painel de municipios.
  x <- as.numeric(dados[[exposure_var]])
  sort(unique(x[is.finite(x)]))
}

deduplicate_exposure_combined <- function(dados, exposure_vars) {
  # Deduplicacao apenas para grid de predicao e figuras.
  # Nao remove linhas do painel de municipios.
  out <- lapply(exposure_vars, function(v) {
    x <- as.numeric(dados[[v]])
    sort(unique(x[is.finite(x)]))
  })
  names(out) <- exposure_vars
  out
}

build_crossbasis_panel <- function(exposure, geocode, lag_max = 12, var_df = 3, lag_df = 3) {
  # Solucao adotada para painel: `group = geocode`.
  # Isso bloqueia memoria de lag entre municipios diferentes.
  dlnm::crossbasis(
    exposure,
    lag = lag_max,
    argvar = list(fun = "ns", df = var_df),
    arglag = list(fun = "ns", df = lag_df),
    group = geocode
  )
}

test_lag_crossing_risk <- function(dados, exposure_var, lag_max = 12) {
  dados <- dados %>% arrange(geocode, date)
  geocode <- as.character(dados$geocode)
  x <- as.numeric(dados[[exposure_var]])

  crossing_by_lag <- lapply(seq_len(lag_max), function(lg) {
    lag_geo <- dplyr::lag(geocode, lg)
    idx <- which(!is.na(lag_geo) & geocode != lag_geo)
    data.frame(lag = lg, crossing_rows = length(idx))
  }) %>% bind_rows()

  crossing_rows <- unique(unlist(lapply(seq_len(lag_max), function(lg) {
    lag_geo <- dplyr::lag(geocode, lg)
    which(!is.na(lag_geo) & geocode != lag_geo)
  })))

  cb_no_group <- dlnm::crossbasis(
    x,
    lag = lag_max,
    argvar = list(fun = "ns", df = 3),
    arglag = list(fun = "ns", df = 3)
  )

  cb_group <- build_crossbasis_panel(
    exposure = x,
    geocode = geocode,
    lag_max = lag_max,
    var_df = 3,
    lag_df = 3
  )

  crossing_rows <- crossing_rows[!is.na(x[crossing_rows])]

  no_group_complete <- if (length(crossing_rows) == 0) {
    0L
  } else {
    sum(rowSums(is.na(cb_no_group[crossing_rows, , drop = FALSE])) == 0)
  }

  group_complete <- if (length(crossing_rows) == 0) {
    0L
  } else {
    sum(rowSums(is.na(cb_group[crossing_rows, , drop = FALSE])) == 0)
  }

  summary_df <- data.frame(
    exposure = exposure_var,
    n_crossing_rows_detected = length(crossing_rows),
    n_rows_fully_defined_without_group = no_group_complete,
    n_rows_fully_defined_with_group = group_complete,
    lag_crossing_blocked_by_group = as.integer(group_complete < no_group_complete),
    stringsAsFactors = FALSE
  )

  list(crossing_by_lag = crossing_by_lag, summary = summary_df)
}

save_model_diagnostic_plot <- function(modelo, output_file) {
  svg(output_file, width = 10, height = 8)
  par(mfrow = c(2, 2))
  plot(modelo)
  par(mfrow = c(1, 1))
  dev.off()
}

create_prediction_plots <- function(pred, var_label, var_name, figure_dir, suffix = "_offset") {
  safe_dir(figure_dir)

  overall_file <- file.path(figure_dir, paste0(var_name, "_overall", suffix, ".svg"))
  contour_file <- file.path(figure_dir, paste0(var_name, "_contour", suffix, ".svg"))
  p3d_file <- file.path(figure_dir, paste0(var_name, "_3d", suffix, ".svg"))
  slices_file <- file.path(figure_dir, paste0(var_name, "_slices", suffix, ".svg"))

  svg(overall_file, width = 6, height = 6)
  plot(
    pred, "overall",
    xlab = var_label, ylab = "Relative Risk",
    main = paste("Cumulative effect -", var_name, "(offset)"),
    ylim = c(0.5, 2.5),
    ci.arg = list(density = 15, col = gray(0.5))
  )
  dev.off()

  svg(contour_file, width = 6.5, height = 6)
  plot(
    pred, "contour",
    xlab = var_label, ylab = "Lag (weeks)",
    key.title = title("RR"),
    main = paste("Effect by lag -", var_name, "(offset)")
  )
  dev.off()

  svg(p3d_file, width = 7, height = 6)
  plot(
    pred, "3d",
    xlab = var_label, ylab = "Lag (weeks)", zlab = "RR",
    main = paste("Effect by lag (3D) -", var_name, "(offset)")
  )
  dev.off()

  svg(slices_file, width = 6, height = 6)
  raw_sel <- quantile(pred$predvar, probs = c(0.1, 0.5, 0.9), na.rm = TRUE)
  sel <- sapply(raw_sel, function(v) pred$predvar[which.min(abs(pred$predvar - v))])
  plot(
    pred, "slices",
    var = sel,
    lag = c(0, 4, 8),
    col = c("blue", "green", "red"),
    xlab = "Lag (weeks)", ylab = "Relative Risk",
    main = paste("Slices -", var_name, "(offset)")
  )
  legend(
    "topright",
    legend = paste(var_name, "=", round(sel, 2)),
    col = c("blue", "green", "red"),
    lty = 1,
    cex = 0.8
  )
  dev.off()
}

run_individual_model <- function(
  base_data,
  exposure_var,
  exposure_label,
  model_id,
  figures_root,
  summaries_dir,
  lag_max = 12,
  by_step = 0.1
) {
  show_progress(sprintf("Modelo individual: %s", model_id))

  dados <- select_model_data(base_data, exposure_var)
  if (nrow(dados) < 100) {
    stop(sprintf("Dados insuficientes para %s apos filtros.", model_id))
  }

  # Deduplicacao so para metadados de predicao.
  exposure_grid <- deduplicate_exposure_individual(dados, exposure_var)

  cb <- build_crossbasis_panel(dados[[exposure_var]], dados$geocode, lag_max = lag_max)
  df_time <- 7 * length(unique(dados$year))

  formula_model <- as.formula(
    "casos ~ cb + ns(time, df = df_time) + factor(mes) + factor(geocode) + offset(offset)"
  )

  # Offset populacional no modelo binomial negativa.
  modelo <- MASS::glm.nb(
    formula_model,
    data = dados,
    control = glm.control(maxit = 50)
  )

  pred <- dlnm::crosspred(
    cb,
    modelo,
    cen = median(dados[[exposure_var]], na.rm = TRUE),
    by = by_step
  )

  figure_dir <- file.path(figures_root, "individuais", model_id)
  safe_dir(figure_dir)
  create_prediction_plots(pred, exposure_label, exposure_var, figure_dir, suffix = "_offset")

  save_model_diagnostic_plot(
    modelo,
    file.path(figure_dir, paste0("diagnostico_modelo_", model_id, "_offset.svg"))
  )

  summary_file <- file.path(summaries_dir, paste0("summary_", model_id, "_offset.txt"))
  summary_lines <- c(
    sprintf("Model ID: %s", model_id),
    sprintf("Rows used (n_final): %d", nrow(dados)),
    sprintf("Unique geocodes: %d", dplyr::n_distinct(dados$geocode)),
    sprintf("Exposure grid unique values: %d", length(exposure_grid)),
    "Model formula (includes population offset):",
    paste(deparse(formula(modelo)), collapse = ""),
    "",
    capture.output(summary(modelo))
  )
  writeLines(summary_lines, con = summary_file)

  lag_test <- test_lag_crossing_risk(dados, exposure_var = exposure_var, lag_max = lag_max)
  write.csv(
    lag_test$crossing_by_lag,
    file.path(summaries_dir, paste0("lag_crossing_by_lag_", model_id, "_offset.csv")),
    row.names = FALSE
  )
  write.csv(
    lag_test$summary,
    file.path(summaries_dir, paste0("lag_crossing_summary_", model_id, "_offset.csv")),
    row.names = FALSE
  )

  save(
    modelo,
    pred,
    dados,
    file = file.path(summaries_dir, paste0("resultados_", model_id, "_offset.RData"))
  )

  data.frame(
    model_id = model_id,
    model_type = "individual",
    exposure_main = exposure_var,
    n_final = nrow(dados),
    geocodes = dplyr::n_distinct(dados$geocode),
    aic = AIC(modelo),
    bic = BIC(modelo),
    stringsAsFactors = FALSE
  )
}

run_combined_model <- function(
  base_data,
  temp_var,
  temp_label,
  model_id,
  figures_root,
  summaries_dir,
  lag_max = 12
) {
  show_progress(sprintf("Modelo combinado: %s", model_id))

  exposure_vars <- c(temp_var, "precip_tot", "rel_humid_med")
  dados <- select_model_data(base_data, exposure_vars)

  if (nrow(dados) < 100) {
    stop(sprintf("Dados insuficientes para %s apos filtros.", model_id))
  }

  # Deduplicacao so para metadados de predicao.
  exposure_grids <- deduplicate_exposure_combined(dados, exposure_vars)

  cb_temp <- build_crossbasis_panel(dados[[temp_var]], dados$geocode, lag_max = lag_max)
  cb_precip <- build_crossbasis_panel(dados$precip_tot, dados$geocode, lag_max = lag_max)
  cb_humid <- build_crossbasis_panel(dados$rel_humid_med, dados$geocode, lag_max = lag_max)

  df_time <- 7 * length(unique(dados$year))
  formula_model <- as.formula(
    "casos ~ cb_temp + cb_precip + cb_humid + ns(time, df = df_time) + factor(mes) + factor(geocode) + offset(offset)"
  )

  # Offset populacional no modelo binomial negativa.
  modelo <- MASS::glm.nb(
    formula_model,
    data = dados,
    control = glm.control(maxit = 50)
  )

  pred_temp <- dlnm::crosspred(cb_temp, modelo, cen = median(dados[[temp_var]], na.rm = TRUE), by = 0.1)
  pred_precip <- dlnm::crosspred(cb_precip, modelo, cen = median(dados$precip_tot, na.rm = TRUE), by = 1)
  pred_humid <- dlnm::crosspred(cb_humid, modelo, cen = median(dados$rel_humid_med, na.rm = TRUE), by = 1)

  figure_dir <- file.path(figures_root, "combinados", model_id)
  safe_dir(figure_dir)

  create_prediction_plots(pred_temp, temp_label, temp_var, figure_dir, suffix = "_offset")
  create_prediction_plots(pred_precip, "Precipitacao total (mm)", "precip_tot", figure_dir, suffix = "_offset")
  create_prediction_plots(pred_humid, "Umidade relativa media (%)", "rel_humid_med", figure_dir, suffix = "_offset")

  save_model_diagnostic_plot(
    modelo,
    file.path(figure_dir, paste0("diagnostico_", model_id, "_offset.svg"))
  )

  summary_file <- file.path(summaries_dir, paste0("summary_", model_id, "_offset.txt"))
  summary_lines <- c(
    sprintf("Model ID: %s", model_id),
    sprintf("Rows used (n_final): %d", nrow(dados)),
    sprintf("Unique geocodes: %d", dplyr::n_distinct(dados$geocode)),
    sprintf("Unique grid (%s): %d", temp_var, length(exposure_grids[[temp_var]])),
    sprintf("Unique grid (precip_tot): %d", length(exposure_grids[["precip_tot"]])),
    sprintf("Unique grid (rel_humid_med): %d", length(exposure_grids[["rel_humid_med"]])),
    "Model formula (includes population offset):",
    paste(deparse(formula(modelo)), collapse = ""),
    "",
    capture.output(summary(modelo))
  )
  writeLines(summary_lines, con = summary_file)

  lag_temp <- test_lag_crossing_risk(dados, exposure_var = temp_var, lag_max = lag_max)
  lag_precip <- test_lag_crossing_risk(dados, exposure_var = "precip_tot", lag_max = lag_max)
  lag_humid <- test_lag_crossing_risk(dados, exposure_var = "rel_humid_med", lag_max = lag_max)

  lag_crossing_detail <- bind_rows(
    mutate(lag_temp$crossing_by_lag, exposure = temp_var),
    mutate(lag_precip$crossing_by_lag, exposure = "precip_tot"),
    mutate(lag_humid$crossing_by_lag, exposure = "rel_humid_med")
  )

  write.csv(
    lag_crossing_detail,
    file.path(summaries_dir, paste0("lag_crossing_by_lag_", model_id, "_offset.csv")),
    row.names = FALSE
  )

  write.csv(
    bind_rows(lag_temp$summary, lag_precip$summary, lag_humid$summary),
    file.path(summaries_dir, paste0("lag_crossing_summary_", model_id, "_offset.csv")),
    row.names = FALSE
  )

  save(
    modelo,
    pred_temp,
    pred_precip,
    pred_humid,
    dados,
    file = file.path(summaries_dir, paste0("resultados_", model_id, "_offset.RData"))
  )

  data.frame(
    model_id = model_id,
    model_type = "combined",
    exposure_main = temp_var,
    n_final = nrow(dados),
    geocodes = dplyr::n_distinct(dados$geocode),
    aic = AIC(modelo),
    bic = BIC(modelo),
    stringsAsFactors = FALSE
  )
}

compute_vif_table <- function(df) {
  out <- lapply(names(df), function(v) {
    others <- setdiff(names(df), v)
    fit <- lm(reformulate(others, response = v), data = df)
    r2 <- summary(fit)$r.squared
    data.frame(variable = v, r2 = r2, vif = 1 / (1 - r2))
  })
  bind_rows(out)
}

run_multicollinearity_diagnostics <- function(base_data, summaries_dir) {
  show_progress("Diagnostico de multicolinearidade para Pernambuco.")

  vars_all <- c("temp_max", "temp_med", "temp_min", "precip_tot", "rel_humid_med")
  d_all <- base_data[, vars_all, drop = FALSE]
  d_all <- d_all[complete.cases(d_all), , drop = FALSE]

  cor_pearson <- cor(d_all, method = "pearson")
  cor_spearman <- cor(d_all, method = "spearman")
  vif_all <- compute_vif_table(d_all)

  write.csv(cor_pearson, file.path(summaries_dir, "multicolinearidade_cor_pearson_pe_offset.csv"))
  write.csv(cor_spearman, file.path(summaries_dir, "multicolinearidade_cor_spearman_pe_offset.csv"))
  write.csv(vif_all, file.path(summaries_dir, "multicolinearidade_vif_pe_offset.csv"), row.names = FALSE)

  comb_specs <- model_specs_combined()
  vif_combined <- lapply(names(comb_specs), function(mn) {
    temp_var <- comb_specs[[mn]]$temp_var
    vars <- c(temp_var, "precip_tot", "rel_humid_med")
    d <- base_data[, vars, drop = FALSE]
    d <- d[complete.cases(d), , drop = FALSE]
    out <- compute_vif_table(d)
    out$model_id <- mn
    out
  }) %>% bind_rows() %>% dplyr::select(model_id, variable, r2, vif)

  write.csv(
    vif_combined,
    file.path(summaries_dir, "multicolinearidade_vif_modelos_combinados_pe_offset.csv"),
    row.names = FALSE
  )

  list(cor_pearson = cor_pearson, cor_spearman = cor_spearman, vif_all = vif_all, vif_combined = vif_combined)
}

build_qc_report <- function(summaries_dir, model_results, merge_integrity, lag_summary_all, multicolin) {
  report_file <- file.path(summaries_dir, "RELATORIO_QC_OFFSET_PERNAMBUCO.md")

  lag_blocked <- sum(lag_summary_all$lag_crossing_blocked_by_group, na.rm = TRUE)
  lag_total <- nrow(lag_summary_all)

  lines <- c(
    "# Relatorio QC - PE DLNM MASS + OFFSET",
    "",
    "## Solucao adotada para painel e lag",
    "- Solucao implementada: `crossbasis(..., group = geocode)` em todos os modelos (individuais e combinados).",
    "- Justificativa metodologica: no `dlnm`, `group` define series independentes no painel e evita uso de observacoes de outro municipio na memoria de lag.",
    "- Teste explicito executado: comparacao de `crossbasis` com e sem `group` nas linhas de fronteira entre municipios.",
    sprintf("- Evidencia agregada: %d de %d verificacoes marcaram bloqueio de lag crossing (`lag_crossing_blocked_by_group = 1`).", lag_blocked, lag_total),
    "",
    "## Integridade do merge com populacao",
    paste0(
      "- n antes/depois do left join: ",
      merge_integrity$value[merge_integrity$metric == "n_before_population_join"],
      " / ",
      merge_integrity$value[merge_integrity$metric == "n_after_population_join"]
    ),
    paste0(
      "- Linhas duplicadas (date+geocode) antes/depois: ",
      merge_integrity$value[merge_integrity$metric == "duplicated_date_geocode_before_join"],
      " / ",
      merge_integrity$value[merge_integrity$metric == "duplicated_date_geocode_after_join"]
    ),
    paste0(
      "- Linhas com Pop_i ausente apos join: ",
      merge_integrity$value[merge_integrity$metric == "missing_population_after_join"]
    ),
    paste0(
      "- Linhas com offset ausente apos join: ",
      merge_integrity$value[merge_integrity$metric == "missing_offset_after_join"]
    ),
    "",
    "## Offset populacional",
    "- Aplicado apenas em modelos binomial negativa (`MASS::glm.nb`).",
    "- Formula dos modelos inclui `offset(offset)` onde `offset = log(Pop_i/100000)`.",
    "- Conferir `summary_*_offset.txt` para evidencia em cada modelo.",
    "",
    "## Sumarios descritivos",
    "- Arquivo `descriptive_before_after_offset.csv` contem n, media e desvio-padrao antes/depois da inclusao do offset.",
    "",
    "## Evidencias de lag crossing",
    "- Arquivos `lag_crossing_by_lag_*_offset.csv` mostram o numero de linhas em fronteira por lag.",
    "- Arquivos `lag_crossing_summary_*_offset.csv` mostram comparacao com e sem `group` e indicador de bloqueio.",
    "",
    "## Comparabilidade e ranking",
    "- `n_final_comparison_offset.csv`: n final, AIC e BIC por modelo.",
    "- `ranking_modelos_offset.csv` e `ranking_modelos_por_BIC_offset.csv`: ordenacao final."
  )

  writeLines(lines, report_file)
}

run_individual_by_name <- function(model_name, data_dir = NULL, results_dir = NULL) {
  paths <- default_paths()
  if (!is.null(data_dir)) paths$data_dir <- data_dir
  if (!is.null(results_dir)) {
    paths$results_dir <- results_dir
    paths$figures_root <- file.path(results_dir, "figuras")
    paths$summaries_dir <- file.path(results_dir, "summaries")
  }

  safe_dir(paths$figures_root)
  safe_dir(paths$summaries_dir)

  specs <- model_specs_individual()
  if (!model_name %in% names(specs)) {
    stop(sprintf("Modelo individual invalido: %s", model_name))
  }

  prepared <- prepare_base_with_population(paths$data_dir, paths$summaries_dir)
  sp <- specs[[model_name]]

  run_individual_model(
    base_data = prepared$data,
    exposure_var = sp$var,
    exposure_label = sp$label,
    model_id = model_name,
    figures_root = paths$figures_root,
    summaries_dir = paths$summaries_dir,
    lag_max = 12,
    by_step = sp$by
  )
}

run_combined_by_name <- function(model_name, data_dir = NULL, results_dir = NULL) {
  paths <- default_paths()
  if (!is.null(data_dir)) paths$data_dir <- data_dir
  if (!is.null(results_dir)) {
    paths$results_dir <- results_dir
    paths$figures_root <- file.path(results_dir, "figuras")
    paths$summaries_dir <- file.path(results_dir, "summaries")
  }

  safe_dir(paths$figures_root)
  safe_dir(paths$summaries_dir)

  specs <- model_specs_combined()
  if (!model_name %in% names(specs)) {
    stop(sprintf("Modelo combinado invalido: %s", model_name))
  }

  prepared <- prepare_base_with_population(paths$data_dir, paths$summaries_dir)
  sp <- specs[[model_name]]

  run_combined_model(
    base_data = prepared$data,
    temp_var = sp$temp_var,
    temp_label = sp$temp_label,
    model_id = model_name,
    figures_root = paths$figures_root,
    summaries_dir = paths$summaries_dir,
    lag_max = 12
  )
}

run_all_models <- function(data_dir = NULL, results_dir = NULL) {
  paths <- default_paths()
  if (!is.null(data_dir)) paths$data_dir <- data_dir
  if (!is.null(results_dir)) {
    paths$results_dir <- results_dir
    paths$figures_root <- file.path(results_dir, "figuras")
    paths$summaries_dir <- file.path(results_dir, "summaries")
  }

  safe_dir(paths$figures_root)
  safe_dir(paths$summaries_dir)

  prepared <- prepare_base_with_population(paths$data_dir, paths$summaries_dir)
  base_data <- prepared$data

  ind_specs <- model_specs_individual()
  comb_specs <- model_specs_combined()

  show_progress("Executando modelos individuais (binomial negativa com offset).")
  ind_results <- lapply(names(ind_specs), function(mn) {
    sp <- ind_specs[[mn]]
    run_individual_model(
      base_data = base_data,
      exposure_var = sp$var,
      exposure_label = sp$label,
      model_id = mn,
      figures_root = paths$figures_root,
      summaries_dir = paths$summaries_dir,
      lag_max = 12,
      by_step = sp$by
    )
  }) %>% bind_rows()

  show_progress("Executando modelos combinados (binomial negativa com offset).")
  comb_results <- lapply(names(comb_specs), function(mn) {
    sp <- comb_specs[[mn]]
    run_combined_model(
      base_data = base_data,
      temp_var = sp$temp_var,
      temp_label = sp$temp_label,
      model_id = mn,
      figures_root = paths$figures_root,
      summaries_dir = paths$summaries_dir,
      lag_max = 12
    )
  }) %>% bind_rows()

  all_results <- bind_rows(ind_results, comb_results)
  write.csv(all_results, file.path(paths$summaries_dir, "n_final_comparison_offset.csv"), row.names = FALSE)

  lag_files <- list.files(
    paths$summaries_dir,
    pattern = "^lag_crossing_summary_.*_offset\\.csv$",
    full.names = TRUE
  )
  lag_summary_all <- bind_rows(lapply(lag_files, read.csv, stringsAsFactors = FALSE))
  write.csv(
    lag_summary_all,
    file.path(paths$summaries_dir, "lag_crossing_summary_all_models_offset.csv"),
    row.names = FALSE
  )

  multicolin <- run_multicollinearity_diagnostics(base_data, paths$summaries_dir)

  build_qc_report(
    summaries_dir = paths$summaries_dir,
    model_results = all_results,
    merge_integrity = prepared$merge_integrity,
    lag_summary_all = lag_summary_all,
    multicolin = multicolin
  )

  show_progress("Pipeline completo: modelos, figuras, sumarios e relatorios com offset.")
  invisible(all_results)
}

