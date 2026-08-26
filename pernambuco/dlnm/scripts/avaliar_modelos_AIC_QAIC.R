# Adaptado de: DLNM MASS/PE DLNM MASS/relatorios/avaliar_modelos_AIC_QAIC.R
# Escopo explicito: modelos DLNM com OFFSET populacional (_offset)

base_dir <- ".."
input_dir <- file.path(base_dir, "results", "summaries")
out_dir <- file.path(base_dir, "results", "summaries")

files <- list.files(
  input_dir,
  pattern = "^resultados_.*_offset\\.RData$",
  recursive = TRUE,
  full.names = TRUE
)

cat("Arquivos OFFSET encontrados:", length(files), "\n")

res <- list()
for (f in files) {
  cat("Processando OFFSET:", f, "\n")
  e <- new.env()
  load(f, envir = e)
  objs <- ls(e)

  modname <- NA_character_
  for (n in objs) {
    o <- get(n, envir = e)
    cls <- class(o)
    if (inherits(o, "glm") || inherits(o, "negbin") || (is.character(cls) && any(grepl("glm|negbin|negative", cls)))) {
      modname <- n
      break
    }
  }

  if (is.na(modname)) {
    cat("Nenhum objeto de modelo encontrado em:", f, "\n")
    next
  }

  m <- get(modname, envir = e)
  modelo_file <- sub("^resultados_(.*)_offset\\.RData$", "\\1", basename(f))
  tipo <- if (grepl("_precip_humid$", modelo_file)) "combinado" else "individual"

  dist <- tryCatch({
    if (!is.null(m$family$family)) {
      m$family$family
    } else if (inherits(m, "negbin")) {
      "Negative Binomial"
    } else {
      NA_character_
    }
  }, error = function(x) NA_character_)

  aic <- suppressWarnings(tryCatch(AIC(m), error = function(x) NA_real_))
  bic <- suppressWarnings(tryCatch(BIC(m), error = function(x) NA_real_))
  qaic <- NA_real_
  if (!is.null(m$family) && grepl("quasi", m$family$family)) {
    if (requireNamespace("MuMIn", quietly = TRUE)) {
      qaic <- suppressWarnings(tryCatch(MuMIn::QAIC(m), error = function(x) NA_real_))
    }
  }

  n <- suppressWarnings(tryCatch(nobs(m), error = function(x) NA_integer_))
  k <- suppressWarnings(tryCatch(length(stats::coef(m)), error = function(x) NA_integer_))
  theta <- if (!is.null(m$theta)) m$theta else NA_real_
  ll <- suppressWarnings(tryCatch(as.numeric(stats::logLik(m)), error = function(x) NA_real_))

  res[[length(res) + 1]] <- data.frame(
    tipo = tipo,
    modelo = modelo_file,
    distribuicao = dist,
    AIC = aic,
    BIC = bic,
    QAIC = qaic,
    nobs = n,
    k = k,
    theta = theta,
    logLik = ll,
    arquivo = f,
    stringsAsFactors = FALSE
  )
}

if (length(res) == 0) {
  cat("Nenhum modelo OFFSET encontrado. Verifique os arquivos .RData.\n")
  quit(save = "no", status = 1)
}

df <- do.call(rbind, res)
df_ord <- df[order(df$AIC, df$QAIC, df$nobs, na.last = TRUE), ]
df_bic <- df[order(df$BIC, df$nobs, na.last = TRUE), ]

if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)
write.csv(df_ord, file.path(out_dir, "ranking_modelos_offset.csv"), row.names = FALSE)
write.csv(df_bic, file.path(out_dir, "ranking_modelos_por_BIC_offset.csv"), row.names = FALSE)

top <- head(df_ord, 10)
top_bic <- head(df_bic, 10)
best <- df_ord[1, ]
best_bic <- df_bic[1, ]

md <- c(
  "# Ranking de Modelos PE DLNM MASS + OFFSET",
  paste0("Gerado em: ", as.character(Sys.time())),
  "",
  "## Melhor Modelo Geral (AIC) - OFFSET",
  paste0("Tipo: ", best$tipo),
  paste0("Modelo: ", best$modelo),
  paste0("Distribuicao: ", best$distribuicao),
  paste0("AIC: ", round(best$AIC, 3)),
  paste0("BIC: ", round(best$BIC, 3)),
  paste0("QAIC: ", ifelse(is.na(best$QAIC), "NA", round(best$QAIC, 3))),
  paste0("nobs: ", best$nobs, " | k: ", best$k, " | theta: ", ifelse(is.na(best$theta), "NA", round(best$theta, 4))),
  "",
  "## Top 10 por AIC (OFFSET)",
  "| # | Tipo | Modelo | Distribuicao | AIC | BIC | QAIC | nobs | k | theta |",
  "|---:|:-----|:------|:------------|----:|----:|-----:|-----:|--:|------:|"
)

for (i in seq_len(nrow(top))) {
  md <- c(
    md,
    paste0(
      "| ", i, " | ", top$tipo[i], " | ", top$modelo[i], " | ", top$distribuicao[i],
      " | ", round(top$AIC[i], 3), " | ", round(top$BIC[i], 3), " | ",
      ifelse(is.na(top$QAIC[i]), "NA", round(top$QAIC[i], 3)), " | ",
      top$nobs[i], " | ", top$k[i], " | ",
      ifelse(is.na(top$theta[i]), "NA", round(top$theta[i], 4)), " |"
    )
  )
}

md <- c(
  md,
  "",
  "## Melhor por BIC - OFFSET",
  paste0("Tipo: ", best_bic$tipo),
  paste0("Modelo: ", best_bic$modelo),
  paste0("Distribuicao: ", best_bic$distribuicao),
  paste0("BIC: ", round(best_bic$BIC, 3)),
  paste0("nobs: ", best_bic$nobs, " | k: ", best_bic$k, " | theta: ", ifelse(is.na(best_bic$theta), "NA", round(best_bic$theta, 4))),
  "",
  "## Top 10 por BIC (OFFSET)",
  "| # | Tipo | Modelo | Distribuicao | BIC | nobs | k | theta |",
  "|---:|:-----|:------|:------------|----:|-----:|--:|------:|"
)

for (i in seq_len(nrow(top_bic))) {
  md <- c(
    md,
    paste0(
      "| ", i, " | ", top_bic$tipo[i], " | ", top_bic$modelo[i], " | ", top_bic$distribuicao[i],
      " | ", round(top_bic$BIC[i], 3), " | ", top_bic$nobs[i], " | ", top_bic$k[i], " | ",
      ifelse(is.na(top_bic$theta[i]), "NA", round(top_bic$theta[i], 4)), " |"
    )
  )
}

md <- c(
  md,
  "",
  "## Observacoes",
  "- Este ranking considera explicitamente apenas modelos com sufixo _offset.",
  "- QAIC e reportado somente para modelos quasi.",
  "- Para binomial negativa, usar AIC/BIC para comparacao."
)

writeLines(md, file.path(out_dir, "RELATORIO_RANKING_MODELOS_OFFSET.md"))

cat("Ranking AIC OFFSET gerado em:", file.path(out_dir, "ranking_modelos_offset.csv"), "\n")
cat("Ranking BIC OFFSET gerado em:", file.path(out_dir, "ranking_modelos_por_BIC_offset.csv"), "\n")
cat("Relatorio OFFSET gerado em:", file.path(out_dir, "RELATORIO_RANKING_MODELOS_OFFSET.md"), "\n")
