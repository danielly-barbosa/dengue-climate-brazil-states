




suppressMessages({
  library(MVSE)
  library(dplyr)
  library(parallel)
})


filter <- stats::filter


dir_dados <- "../dados_mvse_cidades_tempMin_humidMed"
dir_resultados <- "../resultados_MVSE_tempMin_humidMed"

cat("================================================================================\n")
cat("PROCESSAMENTO MVSE COMPLETO - TEMP_MIN + UMIDADE MÉDIA + PRECIPITAÇÃO TOTAL\n")
cat("================================================================================\n")
cat("Diretório dados:", dir_dados, "\n")
cat("Diretório resultados:", dir_resultados, "\n")
cat("\n")


if (!dir.exists(dir_resultados)) {
  dir.create(dir_resultados, recursive = TRUE)
  cat("✓ Diretório de resultados criado\n")
}


arquivos_cidades <- list.files(dir_dados, pattern = "\\.csv$", full.names = FALSE)
geocodes <- gsub("\\.csv$", "", arquivos_cidades)

cat("✓ Encontradas", length(geocodes), "cidades para processar\n")
cat("Primeiras 10 cidades:", paste(head(geocodes, 10), collapse = ", "), "\n")
cat("\n")


nMCMC <- 10000
bMCMC <- 5000
cRho <- 0.5
cEta <- 0.5
gauJump <- 0.1
nSim <- 1000
smoothing <- c(5, 20)

cat("Parâmetros MVSE:\n")
cat("- nMCMC:", nMCMC, "\n")
cat("- bMCMC:", bMCMC, "\n")
cat("- cRho:", cRho, "\n")
cat("- cEta:", cEta, "\n")
cat("- gauJump:", gauJump, "\n")
cat("- nSim:", nSim, "\n")
cat("- smoothing:", paste(smoothing, collapse = ", "), "\n")
cat("\n")


processar_cidade <- function(geocode, idx, total) {

  cat(sprintf("[%d/%d] Processando %s...\n", idx, total, geocode))


  arquivo_entrada <- file.path(dir_dados, paste0(geocode, ".csv"))


  dir_cidade <- file.path(dir_resultados, geocode)

  if (!dir.exists(dir_cidade)) {
    dir.create(dir_cidade, recursive = TRUE)
  }


  arquivo_resultado <- file.path(dir_cidade, paste0(geocode, ".estimated_indexP.csv"))


  if (file.exists(arquivo_resultado)) {
    cat(sprintf("  ✓ %s já processado, pulando...\n", geocode))
    return(TRUE)
  }

  tryCatch({

    dados <- read.csv(arquivo_entrada, stringsAsFactors = FALSE)


    if (!all(c("date", "T", "H", "R") %in% names(dados))) {
      cat(sprintf("  ✗ %s: Colunas necessárias não encontradas\n", geocode))
      return(FALSE)
    }


    dados <- dados[!is.na(dados$T) & !is.na(dados$H) & !is.na(dados$R), ]

    if (nrow(dados) < 100) {
      cat(sprintf("  ✗ %s: Dados insuficientes (%d registros)\n", geocode, nrow(dados)))
      return(FALSE)
    }


    dados$date <- as.Date(dados$date)


    arquivo_temp <- file.path(tempdir(), paste0(geocode, "_temp.csv"))
    write.csv(dados[, c("date", "T", "H", "R")], arquivo_temp, row.names = FALSE)


    setEmpiricalClimateSeries(filepath = arquivo_temp)
    setOutputFilePathAndTag(geocode)


    setMosqLifeExpPrior(pmean=12, psd=2, pdist='gamma')
    setMosqIncPerPrior(pmean=7, psd=2, pdist='gamma')
    setMosqBitingPrior(pmean=0.25, psd=0.01, pdist='gamma')
    setHumanLifeExpPrior(pmean=71.1, psd=2, pdist='gamma')
    setHumanIncPerPrior(pmean=5.8, psd=1, pdist='gamma')
    setHumanInfPerPrior(pmean=5.9, psd=1, pdist='gamma')
    setHumanMosqTransProbPrior(pmean=0.5, psd=0.01, pdist='gamma')


    coef_result <- estimateEcoCoefficients(
      nMCMC = nMCMC,
      bMCMC = bMCMC,
      cRho = cRho,
      cEta = cEta,
      gauJump = gauJump
    )


    indexP_result <- simulateEmpiricalIndexP(
      nSample = nSim,
      smoothing = smoothing
    )


    old_wd <- getwd()
    setwd(dir_cidade)

    exportEmpiricalIndexP()

    setwd(old_wd)


    if (file.exists(arquivo_resultado)) {
      cat(sprintf("  ✓ %s processado com sucesso\n", geocode))
      return(TRUE)
    } else {
      cat(sprintf("  ✗ %s: Arquivo de resultado não foi criado\n", geocode))
      return(FALSE)
    }

  }, error = function(e) {
    cat(sprintf("  ✗ %s: ERRO - %s\n", geocode, e$message))
    return(FALSE)
  })
}


cat("Iniciando processamento das cidades...\n")
cat(rep("=", 80), "\n")

sucessos <- 0
falhas <- 0
inicio <- Sys.time()

for (i in seq_along(geocodes)) {
  geocode <- geocodes[i]


  progresso <- round((i / length(geocodes)) * 100, 1)
  cat(sprintf("\nProgresso: %.1f%% (%d/%d)\n", progresso, i, length(geocodes)))

  resultado <- processar_cidade(geocode, i, length(geocodes))

  if (resultado) {
    sucessos <- sucessos + 1
  } else {
    falhas <- falhas + 1
  }


  if (i %% 10 == 0) {
    tempo_decorrido <- as.numeric(difftime(Sys.time(), inicio, units = "mins"))
    tempo_estimado <- (tempo_decorrido / i) * length(geocodes)
    tempo_restante <- tempo_estimado - tempo_decorrido

    cat(sprintf("\nEstatísticas parciais:\n"))
    cat(sprintf("- Sucessos: %d\n", sucessos))
    cat(sprintf("- Falhas: %d\n", falhas))
    cat(sprintf("- Tempo decorrido: %.1f min\n", tempo_decorrido))
    cat(sprintf("- Tempo estimado restante: %.1f min\n", tempo_restante))
    cat(rep("-", 50), "\n")
  }
}


fim <- Sys.time()
tempo_total <- as.numeric(difftime(fim, inicio, units = "mins"))

cat("\n", rep("=", 80), "\n")
cat("RELATÓRIO FINAL DO PROCESSAMENTO\n")
cat(rep("=", 80), "\n")
cat("Cidades processadas:", length(geocodes), "\n")
cat("Sucessos:", sucessos, "\n")
cat("Falhas:", falhas, "\n")
cat("Taxa de sucesso:", round((sucessos / length(geocodes)) * 100, 1), "%\n")
cat("Tempo total:", round(tempo_total, 1), "minutos\n")
cat("Tempo médio por cidade:", round(tempo_total / length(geocodes), 2), "minutos\n")


arquivos_resultado <- list.files(dir_resultados, pattern = "estimated_indexP.csv", recursive = TRUE)
cat("Arquivos de resultado criados:", length(arquivos_resultado), "\n")

if (sucessos > 0) {
  cat("\n✓ PROCESSAMENTO CONCLUÍDO COM SUCESSO!\n")
  cat("Resultados salvos em:", dir_resultados, "\n")
} else {
  cat("\n✗ PROCESSAMENTO FALHOU!\n")
  cat("Nenhuma cidade foi processada com sucesso.\n")
}

cat(rep("=", 80), "\n")