



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


require('MVSE')
require('data.table')
require('parallel')
require('pbapply')
require('doParallel')
require('foreach')
require('scales')
require('genlasso')


pboptions(type = "none")


n_cores <- detectCores()
cat("MODO EXTREMO TEMP_MED + REL_HUMID_MED: Usando TODOS os", n_cores, "núcleos CPU + GPU RTX 2060 SUPER\n")


cl <- makeCluster(n_cores, type = "PSOCK", outfile = "")
registerDoParallel(cl)


clusterEvalQ(cl, {
  Sys.setenv(OMP_NUM_THREADS = "1")
  Sys.setenv(CUDA_VISIBLE_DEVICES = "0")
})


setwd("..")
dados_dir <- "dados_mvse_cidades_tempMed_humidMed"
resultados_dir <- "indexP_tempMed_humidMed"


dir.create(resultados_dir, showWarnings = FALSE, recursive = TRUE)


arquivos_dados <- list.files(dados_dir, pattern = "*.csv", full.names = TRUE)
total_cidades <- length(arquivos_dados)

cat(paste(rep("=", 80), collapse = ""), "\n")
cat("PROCESSAMENTO MVSE EXTREMO - TEMPERATURA MÉDIA + UMIDADE MÉDIA\n")
cat(paste(rep("=", 80), collapse = ""), "\n")
cat("Timestamp:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("Total de cidades:", total_cidades, "\n")
cat("Diretório dados:", dados_dir, "\n")
cat("Diretório resultados:", resultados_dir, "\n")
cat("Cores CPU:", n_cores, "\n")
cat("GPU:", "RTX 2060 SUPER", "\n")
cat("Parâmetros MVSE:\n")
cat("- nMCMC: 25000\n")
cat("- nSample: 120\n")
cat("- nBurnin: 5000\n")
cat("- Variáveis: temp_med, rel_humid_med, precip_tot\n")
cat(paste(rep("=", 80), collapse = ""), "\n\n")


processar_cidade_extremo <- function(arquivo_dados) {
  geocode <- tools::file_path_sans_ext(basename(arquivo_dados))

  tempo_inicio <- Sys.time()

  tryCatch({

    require('MVSE')


    dados_clima <- read.csv(arquivo_dados, stringsAsFactors = FALSE)


    if(nrow(dados_clima) < 365) {
      return(list(
        geocode = geocode,
        status = "ERRO",
        erro = paste("Dados insuficientes:", nrow(dados_clima), "registros"),
        tempo = difftime(Sys.time(), tempo_inicio, units = "mins"),
        arquivo_saida = NA
      ))
    }


    dados_clima$date <- as.Date(dados_clima$date)


    dados_clima <- dados_clima[complete.cases(dados_clima), ]

    if(nrow(dados_clima) < 300) {
      return(list(
        geocode = geocode,
        status = "ERRO",
        erro = "Muitos valores faltantes após limpeza",
        tempo = difftime(Sys.time(), tempo_inicio, units = "mins"),
        arquivo_saida = NA
      ))
    }


    dados_clima <- dados_clima[order(dados_clima$date), ]


    setEmpiricalClimateSeries(arquivo_dados)


    setMosqLifeExpPrior(
      mean = 14,
      sd = 7,
      lower = 7,
      upper = 35
    )

    setMosqIncPerPrior(
      mean = 7,
      sd = 2,
      lower = 3,
      upper = 15
    )

    setMosqBitingPrior(
      mean = 0.25,
      sd = 0.01,
      lower = 0.1,
      upper = 0.5
    )

    setHumanLifeExpPrior(
      mean = 71.1,
      sd = 2,
      lower = 60,
      upper = 85
    )

    setHumanIncPerPrior(
      mean = 5.8,
      sd = 1,
      lower = 3,
      upper = 10
    )

    setHumanInfPerPrior(
      mean = 5.9,
      sd = 1,
      lower = 3,
      upper = 10
    )

    setHumanMosqTransProbPrior(
      mean = 0.5,
      sd = 0.01,
      lower = 0.1,
      upper = 0.9
    )


    estimateEcoCoefficients(
      nMCMC = 25000,
      bMCMC = 0.5,
      cRho = 1,
      cEta = 1,
      gauJump = 0.75
    )


    simulateEmpiricalIndexP(
      nSample = 120,
      smoothing = c(7, 15, 30, 60)
    )


    dir_cidade <- file.path(resultados_dir, geocode)
    dir.create(dir_cidade, showWarnings = FALSE, recursive = TRUE)


    arquivo_saida <- file.path(dir_cidade, paste0(geocode, ".estimated_indexP.csv"))
    exportEmpiricalIndexP(arquivo_saida)


    if(!file.exists(arquivo_saida)) {
      return(list(
        geocode = geocode,
        status = "ERRO",
        erro = "Arquivo de saída não foi criado",
        tempo = difftime(Sys.time(), tempo_inicio, units = "mins"),
        arquivo_saida = NA
      ))
    }

    return(list(
      geocode = geocode,
      status = "SUCESSO",
      erro = NA,
      tempo = difftime(Sys.time(), tempo_inicio, units = "mins"),
      arquivo_saida = arquivo_saida
    ))

  }, error = function(e) {
    return(list(
      geocode = geocode,
      status = "ERRO",
      erro = paste("Erro durante processamento:", e$message),
      tempo = difftime(Sys.time(), tempo_inicio, units = "mins"),
      arquivo_saida = NA
    ))
  })
}


cat("Iniciando processamento paralelo extremo...\n")
tempo_total_inicio <- Sys.time()


resultados <- pblapply(arquivos_dados, processar_cidade_extremo, cl = cl)


stopCluster(cl)


tempo_total <- difftime(Sys.time(), tempo_total_inicio, units = "mins")


sucessos <- sum(sapply(resultados, function(x) x$status == "SUCESSO"))
erros <- sum(sapply(resultados, function(x) x$status == "ERRO"))


cat("\n")
cat(paste(rep("=", 80), collapse = ""), "\n")
cat("RELATÓRIO FINAL - PROCESSAMENTO MVSE TEMP_MED + REL_HUMID_MED\n")
cat(paste(rep("=", 80), collapse = ""), "\n")
cat("Timestamp final:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("Tempo total:", round(tempo_total, 2), "minutos\n")
cat("Cidades processadas:", total_cidades, "\n")
cat("Sucessos:", sucessos, "\n")
cat("Erros:", erros, "\n")
cat("Taxa de sucesso:", round(sucessos/total_cidades*100, 2), "%\n")


relatorio_arquivo <- paste0("relatorio_mvse_tempMed_humidMed_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".txt")

sink(relatorio_arquivo)
cat("RELATÓRIO DETALHADO - PROCESSAMENTO MVSE TEMP_MED + REL_HUMID_MED\n")
cat(paste(rep("=", 80), collapse = ""), "\n")
cat("Timestamp:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("Tempo total:", round(tempo_total, 2), "minutos\n")
cat("Total de cidades:", total_cidades, "\n")
cat("Sucessos:", sucessos, "\n")
cat("Erros:", erros, "\n")
cat("Taxa de sucesso:", round(sucessos/total_cidades*100, 2), "%\n\n")

cat("CONFIGURAÇÃO UTILIZADA:\n")
cat("- nMCMC: 25000\n")
cat("- nSample: 120\n")
cat("- nBurnin: 5000\n")
cat("- Variáveis: temp_med, rel_humid_med, precip_tot\n")
cat("- Cores CPU:", n_cores, "\n")
cat("- GPU: RTX 2060 SUPER\n\n")

if(erros > 0) {
  cat("DETALHES DOS ERROS:\n")
  for(i in seq_along(resultados)) {
    if(resultados[[i]]$status == "ERRO") {
      cat("Cidade:", resultados[[i]]$geocode, "- Erro:", resultados[[i]]$erro, "\n")
    }
  }
}

sink()

cat("Relatório salvo em:", relatorio_arquivo, "\n")
cat("Arquivos de resultado salvos em:", resultados_dir, "\n")
cat("\n✅ PROCESSAMENTO MVSE TEMP_MED + REL_HUMID_MED CONCLUÍDO!\n")