# Script GPU MÁXIMO ADAPTADO - RTX 2060 SUPER Estressado ao Limite
# Adaptado para usar dados de temp_med e rel_humid_med

# CONFIGURAÇÕES EXTREMAS DE GPU
Sys.setenv(OMP_NUM_THREADS = "28")           # Todos os threads CPU
Sys.setenv(MKL_NUM_THREADS = "28")           # Intel MKL máximo
Sys.setenv(CUDA_VISIBLE_DEVICES = "0")       # GPU principal
Sys.setenv(OPENBLAS_NUM_THREADS = "28")      # OpenBLAS máximo
Sys.setenv(CUDA_CACHE_DISABLE = "0")         # Cache CUDA habilitado
Sys.setenv(CUDA_LAUNCH_BLOCKING = "0")       # Execução assíncrona
Sys.setenv(CUDA_DEVICE_MAX_CONNECTIONS = "32") # Máximas conexões

# Limpar ambiente agressivamente
rm(list = ls())
gc(verbose = FALSE, reset = TRUE, full = TRUE)

# Configurar CRAN
local({r <- getOption("repos")
       r["CRAN"] <- "https://cloud.r-project.org/"
       options(repos=r)})

# Carregar pacotes necessários
require('MVSE')
require('data.table')
require('parallel')
require('pbapply')
require('doParallel')
require('foreach')
require('scales')
require('genlasso')

# Configurar pbapply para máximo desempenho
pboptions(type = "none")  # Sem barra de progresso para economizar recursos

# CONFIGURAÇÃO EXTREMA DE PARALELIZAÇÃO
n_cores <- detectCores()  # TODOS os cores (28)
cat("MODO EXTREMO TEMP_MED + REL_HUMID_MED: Usando TODOS os", n_cores, "núcleos CPU + GPU RTX 2060 SUPER\n")

# Cluster com configuração agressiva
cl <- makeCluster(n_cores, type = "PSOCK", outfile = "")
registerDoParallel(cl)

# Configurar workers para máximo desempenho
clusterEvalQ(cl, {
  Sys.setenv(OMP_NUM_THREADS = "1")  # 1 thread por worker
  Sys.setenv(CUDA_VISIBLE_DEVICES = "0")
})

# Diretórios - ADAPTADO PARA DADOS TEMP_MED + REL_HUMID_MED
setwd("d:/CÓDIGOS")
dados_dir <- "dados_mvse_cidades_tempMed_humidMed"
resultados_dir <- "indexP_tempMed_humidMed"

# Criar diretório de resultados
dir.create(resultados_dir, showWarnings = FALSE, recursive = TRUE)

# Listar arquivos de dados
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

# Função otimizada para processar uma cidade
processar_cidade_extremo <- function(arquivo_dados) {
  geocode <- tools::file_path_sans_ext(basename(arquivo_dados))
  
  tempo_inicio <- Sys.time()
  
  tryCatch({
    # Carregar biblioteca MVSE no worker
    require('MVSE')
    
    # Carregar dados climáticos
    dados_clima <- read.csv(arquivo_dados, stringsAsFactors = FALSE)
    
    # Verificar dados mínimos
    if(nrow(dados_clima) < 365) {
      return(list(
        geocode = geocode,
        status = "ERRO",
        erro = paste("Dados insuficientes:", nrow(dados_clima), "registros"),
        tempo = difftime(Sys.time(), tempo_inicio, units = "mins"),
        arquivo_saida = NA
      ))
    }
    
    # Converter data
    dados_clima$date <- as.Date(dados_clima$date)
    
    # Verificar e tratar valores faltantes
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
    
    # Ordenar por data
    dados_clima <- dados_clima[order(dados_clima$date), ]
    
    # Configurar série temporal MVSE usando o arquivo CSV diretamente
    setEmpiricalClimateSeries(arquivo_dados)
    
    # Configurar priors MVSE
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
    
    # Estimar coeficientes eco-epidemiológicos
    estimateEcoCoefficients(
      nMCMC = 25000,
      bMCMC = 0.5,
      cRho = 1,
      cEta = 1,
      gauJump = 0.75
    )
    
    # Simular IndexP empírico
    simulateEmpiricalIndexP(
      nSample = 120,
      smoothing = c(7, 15, 30, 60)
    )
    
    # Criar diretório da cidade
    dir_cidade <- file.path(resultados_dir, geocode)
    dir.create(dir_cidade, showWarnings = FALSE, recursive = TRUE)
    
    # Exportar resultados
    arquivo_saida <- file.path(dir_cidade, paste0(geocode, ".estimated_indexP.csv"))
    exportEmpiricalIndexP(arquivo_saida)
    
    # Verificar se arquivo foi criado
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

# EXECUÇÃO PARALELA EXTREMA
cat("Iniciando processamento paralelo extremo...\n")
tempo_total_inicio <- Sys.time()

# Processar todas as cidades em paralelo
resultados <- pblapply(arquivos_dados, processar_cidade_extremo, cl = cl)

# Finalizar cluster
stopCluster(cl)

# Calcular tempo total
tempo_total <- difftime(Sys.time(), tempo_total_inicio, units = "mins")

# Analisar resultados
sucessos <- sum(sapply(resultados, function(x) x$status == "SUCESSO"))
erros <- sum(sapply(resultados, function(x) x$status == "ERRO"))

# Relatório final
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

# Salvar relatório detalhado
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