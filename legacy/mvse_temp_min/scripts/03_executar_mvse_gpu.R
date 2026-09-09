



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
cat("MODO EXTREMO TEMP_MIN + REL_HUMID_MED: Usando TODOS os", n_cores, "núcleos CPU + GPU RTX 2060 SUPER\n")


cl <- makeCluster(n_cores, type = "PSOCK", outfile = "")
registerDoParallel(cl)


clusterEvalQ(cl, {
  Sys.setenv(OMP_NUM_THREADS = "1")
  Sys.setenv(CUDA_VISIBLE_DEVICES = "0")
})


setwd("..")
dir.create("indexP_tempMin_humMed", showWarnings = FALSE)


dir_clima <- "../dados_mvse_cidades_tempMin_humMed"
arquivos_clima <- list.files(dir_clima, pattern = "\\.csv$", full.names = TRUE)
arquivos_clima <- sort(arquivos_clima)

cat("Diretório de clima (TEMP_MIN + REL_HUMID_MED):", dir_clima, "\n")
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
    dir_cidade <- file.path("indexP_tempMin_humMed", nome_cidade)
    dir.create(dir_cidade, showWarnings = FALSE, recursive = TRUE)

    cat("Processando cidade (TEMP_MIN + REL_HUMID_MED):", nome_cidade, "\n")


    dados_teste <- read.csv(arquivo_clima)
    cat("  Estrutura T-H-R verificada:", ncol(dados_teste), "colunas,", nrow(dados_teste), "registros\n")


    if(!all(c("date", "T", "H", "R") %in% names(dados_teste))) {
      stop("Estrutura T-H-R inválida no arquivo ", arquivo_clima)
    }


    if(any(is.na(dados_teste$T)) || any(is.na(dados_teste$H)) || any(is.na(dados_teste$R))) {
      stop("Valores NA encontrados nos dados T-H-R")
    }


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
      nSample = 120,
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
cat("INICIANDO PROCESSAMENTO EXTREMO MVSE - TEMP_MIN + REL_HUMID_MED\n")
cat("GPU: RTX 2060 SUPER | CPU: 28 threads | Dados: T=temp_min, H=rel_humid_med, R=precip_tot\n")
cat("Cidades: ", length(arquivos_clima), " | MCMC: 25,000 | Simulações: 120\n")
cat(paste0(rep("=", 80), collapse=""), "\n\n")


config_inicial <- list(
  timestamp = Sys.time(),
  total_cidades = length(arquivos_clima),
  diretorio_dados = dir_clima,
  diretorio_resultados = "indexP_tempMin_humMed",
  parametros = list(
    nMCMC = 25000,
    nSim = 120,
    nBurnin = 5000,
    temperatura = "temp_min",
    umidade = "rel_humid_med",
    precipitacao = "precip_tot"
  )
)


inicio_processamento <- Sys.time()


resultados <- foreach(
  arquivo = arquivos_clima,
  .combine = c,
  .packages = c("MVSE"),
  .export = c("processar_cidade_extremo"),
  .errorhandling = "pass"
) %dopar% {
  processar_cidade_extremo(arquivo)
}


fim_processamento <- Sys.time()
tempo_total <- difftime(fim_processamento, inicio_processamento, units = "mins")


stopCluster(cl)


cat("\n", paste0(rep("=", 80), collapse=""), "\n")
cat("PROCESSAMENTO EXTREMO MVSE CONCLUÍDO - TEMP_MIN + REL_HUMID_MED\n")
cat(paste0(rep("=", 80), collapse=""), "\n")

sucessos <- sum(resultados == TRUE, na.rm = TRUE)
erros <- length(resultados) - sucessos

cat("Total de cidades processadas:", length(arquivos_clima), "\n")
cat("Sucessos:", sucessos, "\n")
cat("Erros:", erros, "\n")
cat("Taxa de sucesso:", round(sucessos/length(arquivos_clima)*100, 1), "%\n")
cat("Tempo total:", round(tempo_total, 2), "minutos\n")
cat("Tempo médio por cidade:", round(tempo_total/length(arquivos_clima), 2), "minutos\n")


arquivos_saida <- list.files("indexP_tempMin_humMed", pattern = "\\.estimated_indexP\\.csv$", recursive = TRUE)
cat("Arquivos de resultado encontrados:", length(arquivos_saida), "\n")

if(length(arquivos_saida) > 0) {
  cat("Primeiros resultados:\n")
  for(i in 1:min(5, length(arquivos_saida))) {
    cat("-", arquivos_saida[i], "\n")
  }
}


relatorio_final <- list(
  config_inicial = config_inicial,
  resultados = list(
    inicio = inicio_processamento,
    fim = fim_processamento,
    tempo_total_min = as.numeric(tempo_total),
    total_cidades = length(arquivos_clima),
    sucessos = sucessos,
    erros = erros,
    taxa_sucesso = sucessos/length(arquivos_clima)*100,
    arquivos_resultado = length(arquivos_saida)
  )
)

saveRDS(relatorio_final, "relatorio_mvse_tempMin_humMed.rds")

cat("\nRelatório salvo em: relatorio_mvse_tempMin_humMed.rds\n")
cat("Resultados salvos em: indexP_tempMin_humMed/\n")
cat("\nProcessamento MVSE com TEMP_MIN + REL_HUMID_MED finalizado!\n")
cat(paste0(rep("=", 80), collapse=""), "\n")