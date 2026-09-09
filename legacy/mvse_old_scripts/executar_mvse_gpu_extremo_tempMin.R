



Sys.setenv(OMP_NUM_THREADS = "28")
Sys.setenv(MKL_NUM_THREADS = "28")
Sys.setenv(CUDA_VISIBLE_DEVICES = "0")
Sys.setenv(OPENBLAS_NUM_THREADS = "28")
Sys.setenv(CUDA_CACHE_DISABLE = "0")
Sys.setenv(CUDA_LAUNCH_BLOCKING = "0")
Sys.setenv(CUDA_DEVICE_MAX_CONNECTIONS = "32")


rm(list = ls())
gc(verbose = FALSE, reset = TRUE, full = TRUE)


local({r <- getOption("repos")
       r["CRAN"] <- "https://cloud.r-project.org/"
       options(repos=r)})


pacotes <- c("MVSE", "pbapply", "scales", "genlasso", "parallel", "doParallel", "foreach")

for(pacote in pacotes) {
  if(!require(pacote, character.only = TRUE)) {
    install.packages(pacote)
    library(pacote, character.only = TRUE)
  }
}


pboptions(type = "none")


n_cores <- detectCores()
cat("MODO EXTREMO TEMP_MIN: Usando TODOS os", n_cores, "núcleos CPU + GPU RTX 2060 SUPER\n")


cl <- makeCluster(n_cores, type = "PSOCK", outfile = "")
registerDoParallel(cl)


clusterEvalQ(cl, {
  Sys.setenv(OMP_NUM_THREADS = "1")
  Sys.setenv(CUDA_VISIBLE_DEVICES = "0")
})


setwd("..")
dir.create("resultados_MVSE_GPU_EXTREMO_tempMin", showWarnings = FALSE)


dir_clima <- "../dados_mvse_cidades_tempMin_corrigido"
arquivos_clima <- list.files(dir_clima, pattern = "\\.csv$", full.names = TRUE)
arquivos_clima <- sort(arquivos_clima)

cat("Diretório de clima (TEMP_MIN):", dir_clima, "\n")
cat("Total de cidades:", length(arquivos_clima), "\n")


if(length(arquivos_clima) == 0) {
  stop("ERRO: Nenhum arquivo CSV encontrado em ", dir_clima)
}


cat("Primeiros arquivos encontrados:\n")
for(i in 1:min(5, length(arquivos_clima))) {
  cat("-", basename(arquivos_clima[i]), "\n")
}


processar_cidade_extremo <- function(arquivo_clima) {
  tryCatch({

    nome_cidade <- gsub("\\.csv$", "", basename(arquivo_clima))
    dir_cidade <- file.path("resultados_MVSE_GPU_EXTREMO_tempMin", nome_cidade)
    dir.create(dir_cidade, showWarnings = FALSE, recursive = TRUE)

    cat("Processando cidade (TEMP_MIN):", nome_cidade, "\n")


    setEmpiricalClimateSeries(arquivo_clima)
    setOutputFilePathAndTag(file.path(dir_cidade, nome_cidade))





    setMosqLifeExpPrior(pmean=12, psd=2, pdist='gamma')
    setMosqIncPerPrior(pmean=7, psd=2, pdist='gamma')
    setMosqBitingPrior(pmean=0.25, psd=0.01, pdist='gamma')
    setHumanLifeExpPrior(pmean=71.1, psd=2, pdist='gamma')
    setHumanIncPerPrior(pmean=5.8, psd=1, pdist='gamma')
    setHumanInfPerPrior(pmean=5.9, psd=1, pdist='gamma')
    setHumanMosqTransProbPrior(pmean=0.5, psd=0.01, pdist='gamma')


    estimateEcoCoefficients(
      nMCMC = 25000,
      bMCMC = 0.5,
      cRho = 1,
      cEta = 1,
      gauJump = 0.75
    )


    simulateEmpiricalIndexP(
      nSim = 120,
      smoothing = c(7, 15, 30, 60)
    )


    exportEmpiricalIndexP()


    arquivo_saida <- file.path(dir_cidade, paste0(nome_cidade, ".estimated_indexP.csv"))


    if(file.exists(arquivo_saida)) {
      cat("✓ Concluído:", nome_cidade, "- Arquivo salvo\n")
      return(TRUE)
    } else {
      cat("✗ ERRO:", nome_cidade, "- Arquivo não encontrado\n")
      return(FALSE)
    }

  }, error = function(e) {
    cat("✗ ERRO em", nome_cidade, ":", e$message, "\n")
    return(FALSE)
  })
}


cat("\n", paste0(rep("=", 80), collapse=""), "\n")
cat("INICIANDO PROCESSAMENTO EXTREMO MVSE - TEMPERATURA MÍNIMA\n")
cat("GPU: RTX 2060 SUPER | CPU: 28 threads | Dados: TEMP_MIN\n")
cat("Cidades: ", length(arquivos_clima), " | MCMC: 25,000 | Simulações: 120\n")
cat(paste0(rep("=", 80), collapse=""), "\n\n")


config_inicial <- list(
  timestamp = Sys.time(),
  total_cidades = length(arquivos_clima),
  diretorio_dados = dir_clima,
  diretorio_resultados = "resultados_MVSE_GPU_EXTREMO_tempMin",
  parametros = list(
    nMCMC = 25000,
    nSim = 120,
    nBurnin = 5000,
    nThin = 10
  ),
  sistema = list(
    cores_cpu = n_cores,
    gpu = "RTX 2060 SUPER",
    temperatura_usada = "temp_min"
  )
)

saveRDS(config_inicial, "config_processamento_mvse_gpu_extremo_tempMin.rds")


inicio_total <- Sys.time()
cidades_processadas <- 0
cidades_sucesso <- 0
cidades_erro <- 0


tamanho_lote <- 12
total_lotes <- ceiling(length(arquivos_clima) / tamanho_lote)

for(lote in 1:total_lotes) {
  inicio_lote <- (lote - 1) * tamanho_lote + 1
  fim_lote <- min(lote * tamanho_lote, length(arquivos_clima))
  arquivos_lote <- arquivos_clima[inicio_lote:fim_lote]

  cat("LOTE", lote, "de", total_lotes, "- Processando cidades", inicio_lote, "a", fim_lote, "\n")


  inicio_lote_tempo <- Sys.time()

  resultados_lote <- foreach(arquivo = arquivos_lote,
                            .packages = c("MVSE"),
                            .combine = c,
                            .errorhandling = "pass") %dopar% {
    processar_cidade_extremo(arquivo)
  }

  fim_lote_tempo <- Sys.time()
  tempo_lote <- as.numeric(difftime(fim_lote_tempo, inicio_lote_tempo, units = "mins"))


  sucessos_lote <- sum(resultados_lote == TRUE, na.rm = TRUE)
  erros_lote <- length(resultados_lote) - sucessos_lote

  cidades_processadas <- cidades_processadas + length(arquivos_lote)
  cidades_sucesso <- cidades_sucesso + sucessos_lote
  cidades_erro <- cidades_erro + erros_lote


  cat("Lote", lote, "concluído em", round(tempo_lote, 2), "minutos\n")
  cat("Sucessos:", sucessos_lote, "| Erros:", erros_lote, "\n")
  cat("Progresso total:", cidades_processadas, "/", length(arquivos_clima),
      "(", round(100 * cidades_processadas / length(arquivos_clima), 1), "%)\n\n")


  gc(verbose = FALSE, reset = TRUE, full = TRUE)


  checkpoint <- list(
    lote_atual = lote,
    cidades_processadas = cidades_processadas,
    cidades_sucesso = cidades_sucesso,
    cidades_erro = cidades_erro,
    tempo_decorrido = as.numeric(difftime(Sys.time(), inicio_total, units = "mins"))
  )
  saveRDS(checkpoint, "checkpoint_mvse_gpu_extremo_tempMin.rds")
}


fim_total <- Sys.time()
tempo_total <- as.numeric(difftime(fim_total, inicio_total, units = "mins"))


stopCluster(cl)


cat("\n", paste0(rep("=", 80), collapse=""), "\n")
cat("PROCESSAMENTO EXTREMO CONCLUÍDO - TEMPERATURA MÍNIMA\n")
cat(paste0(rep("=", 80), collapse=""), "\n")
cat("Tempo total:", round(tempo_total, 2), "minutos (", round(tempo_total/60, 2), "horas)\n")
cat("Cidades processadas:", cidades_processadas, "/", length(arquivos_clima), "\n")
cat("Sucessos:", cidades_sucesso, "(", round(100 * cidades_sucesso / length(arquivos_clima), 1), "%)\n")
cat("Erros:", cidades_erro, "(", round(100 * cidades_erro / length(arquivos_clima), 1), "%)\n")
cat("Velocidade média:", round(cidades_processadas / tempo_total, 2), "cidades/minuto\n")
cat("Resultados salvos em: resultados_MVSE_GPU_EXTREMO_tempMin/\n")
cat(paste0(rep("=", 80), collapse=""), "\n")


relatorio_final <- list(
  timestamp_inicio = inicio_total,
  timestamp_fim = fim_total,
  tempo_total_minutos = tempo_total,
  total_cidades = length(arquivos_clima),
  cidades_processadas = cidades_processadas,
  cidades_sucesso = cidades_sucesso,
  cidades_erro = cidades_erro,
  taxa_sucesso = cidades_sucesso / length(arquivos_clima),
  velocidade_cidades_por_minuto = cidades_processadas / tempo_total,
  diretorio_resultados = "resultados_MVSE_GPU_EXTREMO_tempMin",
  temperatura_usada = "temp_min",
  parametros_mvse = config_inicial$parametros,
  sistema = config_inicial$sistema
)

saveRDS(relatorio_final, "relatorio_final_mvse_gpu_extremo_tempMin.rds")

cat("Relatório salvo em: relatorio_final_mvse_gpu_extremo_tempMin.rds\n")
cat("MISSÃO CONCLUÍDA COM SUCESSO! 🚀\n")