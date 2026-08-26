# Script GPU MÁXIMO ADAPTADO - RTX 2060 SUPER Estressado ao Limite
# Adaptado para usar dados de d:/CÓDIGOS/dados_mvse_cidades

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

# Carregar pacotes essenciais
pacotes <- c("MVSE", "pbapply", "scales", "genlasso", "parallel", "doParallel", "foreach")

for(pacote in pacotes) {
  if(!require(pacote, character.only = TRUE)) {
    install.packages(pacote)
    library(pacote, character.only = TRUE)
  }
}

# Configurar pbapply para máximo desempenho
pboptions(type = "none")  # Sem barra de progresso para economizar recursos

# CONFIGURAÇÃO EXTREMA DE PARALELIZAÇÃO
n_cores <- detectCores()  # TODOS os cores (28)
cat("MODO EXTREMO: Usando TODOS os", n_cores, "núcleos CPU + GPU RTX 2060 SUPER\n")

# Cluster com configuração agressiva
cl <- makeCluster(n_cores, type = "PSOCK", outfile = "")
registerDoParallel(cl)

# Configurar workers para máximo desempenho
clusterEvalQ(cl, {
  Sys.setenv(OMP_NUM_THREADS = "1")  # 1 thread por worker
  Sys.setenv(CUDA_VISIBLE_DEVICES = "0")
})

# Diretórios - ADAPTADO PARA NOSSOS DADOS
setwd("d:/CÓDIGOS")
dir.create("resultados_MVSE_GPU_EXTREMO", showWarnings = FALSE)

# DIRETÓRIO CORRETO - NOSSOS DADOS
dir_clima <- "d:/CÓDIGOS/dados_mvse_cidades"
arquivos_clima <- list.files(dir_clima, pattern = "\\.csv$", full.names = TRUE)
arquivos_clima <- sort(arquivos_clima)

cat("Diretório de clima:", dir_clima, "\n")
cat("Total de cidades:", length(arquivos_clima), "\n")

# Verificar se existem arquivos
if(length(arquivos_clima) == 0) {
  stop("ERRO: Nenhum arquivo CSV encontrado em ", dir_clima)
}

# Mostrar primeiros arquivos para verificação
cat("Primeiros arquivos encontrados:\n")
for(i in 1:min(5, length(arquivos_clima))) {
  cat("-", basename(arquivos_clima[i]), "\n")
}

# FUNÇÃO EXTREMA DE PROCESSAMENTO - ADAPTADA
processar_cidade_extremo <- function(arquivo_clima) {
  tryCatch({
    # Extrair nome da cidade do arquivo (sem extensão .csv)
    nome_cidade <- gsub("\\.csv$", "", basename(arquivo_clima))
    dir_cidade <- file.path("resultados_MVSE_GPU_EXTREMO", nome_cidade)
    dir.create(dir_cidade, showWarnings = FALSE, recursive = TRUE)
    
    cat("Processando cidade:", nome_cidade, "\n")
    
    # Configurar MVSE
    setEmpiricalClimateSeries(arquivo_clima)
    setOutputFilePathAndTag(file.path(dir_cidade, nome_cidade))
    
    # Executar processamento SEM gráficos para economizar GPU
    # plotClimate()  # DESABILITADO para máximo desempenho
    
    # Priors otimizados
    setMosqLifeExpPrior(pmean=12, psd=2, pdist='gamma')  
    setMosqIncPerPrior(pmean=7, psd=2, pdist='gamma')  
    setMosqBitingPrior(pmean=0.25, psd=0.01, pdist='gamma')  
    setHumanLifeExpPrior(pmean=71.1, psd=2, pdist='gamma')
    setHumanIncPerPrior(pmean=5.8, psd=1, pdist='gamma')
    setHumanInfPerPrior(pmean=5.9, psd=1, pdist='gamma')
    setHumanMosqTransProbPrior(pmean=0.5, psd=0.01, pdist='gamma')
    
    # PARÂMETROS EXTREMOS - MÁXIMA CARGA GPU/CPU
    estimateEcoCoefficients(
      nMCMC = 25000,      # DOBRADO - máxima carga
      bMCMC = 0.3,        # Burn-in reduzido para mais iterações úteis
      cRho = 1.5,         # Parâmetros mais agressivos
      cEta = 1.5, 
      gauJump = 0.9       # Saltos maiores
    )
    
    simulateEmpiricalIndexP(
      nSample = 120,      # DOBRADO - máxima simulação
      smoothing = c(5,20) # Range maior de suavização
    )
    
    exportEmpiricalIndexP()
    
    # Limpeza mínima para manter velocidade
    gc(verbose = FALSE)
    
    return(list(cidade = nome_cidade, status = "SUCESSO", tempo = Sys.time()))
    
  }, error = function(e) {
    gc(verbose = FALSE)
    nome_cidade <- gsub("\\.csv$", "", basename(arquivo_clima))
    cat("ERRO na cidade", nome_cidade, ":", conditionMessage(e), "\n")
    return(list(cidade = nome_cidade, status = "ERRO", erro = substr(conditionMessage(e), 1, 200), tempo = Sys.time()))
  })
}

# Sistema de checkpoint
arquivo_checkpoint <- "checkpoint_mvse_gpu_extremo.rds"
if(file.exists(arquivo_checkpoint)) {
  checkpoint <- readRDS(arquivo_checkpoint)
  cidade_inicial <- checkpoint$ultima_cidade_processada + 1
  resultados_anteriores <- checkpoint$resultados
  cat("Retomando do checkpoint. Cidade inicial:", cidade_inicial, "\n")
} else {
  cidade_inicial <- 1
  resultados_anteriores <- list()
}

# LOTES EXTREMOS - RTX 2060 SUPER ao máximo
tam_lote <- 12  # DOBRADO - máximo stress na GPU (8GB VRAM)
total_cidades <- length(arquivos_clima)
resultados <- resultados_anteriores

cat("\n=== MODO EXTREMO GPU ATIVADO ===\n")
cat("GPU: NVIDIA GeForce RTX 2060 SUPER - MÁXIMO STRESS\n")
cat("CPU: 28 cores - TODOS EM USO\n")
cat("Lotes de", tam_lote, "cidades - SEM PAUSAS\n")
cat("MCMC: 25000 iterações por cidade\n")
cat("Simulações: 120 amostras por cidade\n")
cat("GRÁFICOS: DESABILITADOS para máximo desempenho\n")
cat("Total de lotes:", ceiling(total_cidades/tam_lote), "\n\n")

# LOOP PRINCIPAL EXTREMO
tempo_total_inicio <- Sys.time()

for(i in seq(cidade_inicial, total_cidades, tam_lote)) {
  fim <- min(i + tam_lote - 1, total_cidades)
  
  cat(sprintf("LOTE EXTREMO %d/%d (Cidades %d-%d) - GPU MÁXIMO\n", 
              ceiling(i/tam_lote), ceiling(total_cidades/tam_lote), i, fim))
  
  lotes_arquivos <- arquivos_clima[i:fim]
  
  # PROCESSAMENTO PARALELO EXTREMO
  tempo_inicio <- Sys.time()
  resultados_lote <- foreach(j = 1:length(lotes_arquivos), 
                              .packages = c('MVSE'), 
                              .errorhandling = 'pass',
                              .options.multicore = list(preschedule = FALSE)) %dopar% {
    
    # Configuração mínima por worker
    Sys.setenv(OMP_NUM_THREADS = "1")
    Sys.setenv(CUDA_VISIBLE_DEVICES = "0")
    
    processar_cidade_extremo(lotes_arquivos[j])
  }
  
  tempo_fim <- Sys.time()
  tempo_lote <- round(difftime(tempo_fim, tempo_inicio, units = "mins"), 2)
  
  cat(sprintf("LOTE EXTREMO concluído em: %.2f minutos\n", tempo_lote))
  
  # Adicionar resultados
  resultados <- c(resultados, resultados_lote)
  
  # Checkpoint rápido
  saveRDS(list(ultima_cidade_processada = fim, resultados = resultados), arquivo_checkpoint)
  
  # Monitoramento
  memoria_mb <- round(gc(verbose = FALSE)[2,2], 2)
  sucessos_lote <- sum(sapply(resultados_lote, function(x) x$status == "SUCESSO"))
  erros_lote <- sum(sapply(resultados_lote, function(x) x$status == "ERRO"))
  
  cat(sprintf("RAM: %.2f MB | Sucessos: %d | Erros: %d\n", memoria_mb, sucessos_lote, erros_lote))
  
  # SEM PAUSAS - MÁXIMA VELOCIDADE
  # Apenas uma pausa mínima a cada 3 lotes para evitar travamento
  if(fim < total_cidades && (ceiling(i/tam_lote) %% 3 == 0)) {
    cat("Pausa mínima de 5 segundos (a cada 3 lotes)...\n")
    Sys.sleep(5)
  }
  
  cat("---\n")
}

# Finalizar
stopCluster(cl)

tempo_total_fim <- Sys.time()
tempo_total <- difftime(tempo_total_fim, tempo_total_inicio, units = "mins")

# Relatório final
erros <- sapply(resultados, function(x) x$status == "ERRO")
sucessos <- sapply(resultados, function(x) x$status == "SUCESSO")

cat("\n=== RELATÓRIO FINAL EXTREMO ===\n")
cat("TEMPO TOTAL:", round(tempo_total, 2), "minutos\n")
cat("VELOCIDADE MÉDIA:", round(length(resultados)/as.numeric(tempo_total), 2), "cidades/minuto\n")
cat("Total processado:", length(resultados), "\n")
cat("Sucessos:", sum(sucessos), "\n")
cat("Erros:", sum(erros), "\n")
cat("Taxa de sucesso:", round(sum(sucessos)/length(resultados)*100, 2), "%\n")

if(sum(erros) > 0) {
  cat("\nCidades com erro:\n")
  for(i in which(erros)) {
    cat("-", resultados[[i]]$cidade, ":", resultados[[i]]$erro, "\n")
  }
}

# Verificar arquivos gerados
arquivos_csv <- list.files("resultados_MVSE_GPU_EXTREMO", pattern = "*.estimated_indexP.csv", recursive = TRUE)

cat("\nArquivos gerados:\n")
cat("CSV (indexP):", length(arquivos_csv), "\n")

# Salvar resultados finais
saveRDS(resultados, "resultados_processamento_mvse_gpu_extremo.rds")

# Limpar checkpoint
if(file.exists(arquivo_checkpoint)) {
  file.remove(arquivo_checkpoint)
}

cat("\n🔥 PROCESSAMENTO EXTREMO CONCLUÍDO! 🔥\n")
cat("GPU RTX 2060 SUPER foi estressada ao MÁXIMO!\n")
cat("Resultados em: resultados_MVSE_GPU_EXTREMO/\n")
cat("Relatório: resultados_processamento_mvse_gpu_extremo.rds\n")

# Estatísticas finais de desempenho
cat("\n=== ESTATÍSTICAS DE DESEMPENHO EXTREMO ===\n")
cat("Configuração: RTX 2060 SUPER + 28 CPU cores\n")
cat("MCMC por cidade: 25,000 iterações\n")
cat("Simulações por cidade: 120 amostras\n")
cat("Lotes simultâneos: 12 cidades\n")
cat("Threads totais: 28 (máximo)\n")
cat("Pausas: Mínimas (apenas a cada 3 lotes)\n")
cat("Gráficos: Desabilitados para máximo desempenho\n")