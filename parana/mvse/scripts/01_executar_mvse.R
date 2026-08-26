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
# setwd("d:/CÓDIGOS")
dir.create("parana/mvse/outputs/indexP_tempMed_humMed", showWarnings = FALSE)

# DIRETÓRIO CORRETO - NOSSOS DADOS COM TEMP_MED + REL_HUMID_MED
dir_clima <- "parana/mvse/outputs/geocodes"
arquivos_clima <- list.files(dir_clima, pattern = "\\.csv$", full.names = TRUE)
arquivos_clima <- sort(arquivos_clima)

cat("Diretório de clima (TEMP_MED + REL_HUMID_MED):", dir_clima, "\n")
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

# FUNÇÃO EXTREMA DE PROCESSAMENTO - ADAPTADA PARA TEMP_MED + REL_HUMID_MED
processar_cidade_extremo <- function(arquivo_clima) {
  tryCatch({
    # Extrair nome da cidade do arquivo (sem extensão .csv)
    nome_cidade <- gsub("\\.csv$", "", basename(arquivo_clima))
    dir_cidade <- file.path("parana/mvse/outputs/indexP_tempMed_humMed", nome_cidade)
    dir.create(dir_cidade, showWarnings = FALSE, recursive = TRUE)

    cat("Processando cidade (TEMP_MED + REL_HUMID_MED):", nome_cidade, "\n")

    # Verificar estrutura dos dados antes do processamento
    dados_teste <- read.csv(arquivo_clima)
    cat("  Estrutura T-H-R verificada:", ncol(dados_teste), "colunas,", nrow(dados_teste), "registros\n")

    # Verificar colunas necessárias
    if(!all(c("date", "T", "H", "R") %in% names(dados_teste))) {
      stop("Estrutura T-H-R inválida no arquivo ", arquivo_clima)
    }

    # Verificar integridade dos dados
    if(any(is.na(dados_teste$T)) || any(is.na(dados_teste$H)) || any(is.na(dados_teste$R))) {
      stop("Valores NA encontrados nos dados T-H-R")
    }

    # Configurar MVSE
    setEmpiricalClimateSeries(arquivo_clima)
    setOutputFilePathAndTag(file.path(dir_cidade, nome_cidade))

    # Executar processamento SEM gráficos para economizar GPU
    # plotClimate()  # DESABILITADO para máximo desempenho

    # Priors otimizados para temp_med e rel_humid_med
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
      bMCMC = 0.5,
      cRho = 1,
      cEta = 1,
      gauJump = 0.75
    )

    # Simular indexP empírico com máxima precisão
    simulateEmpiricalIndexP(
      nSample = 120,         # TRIPLICADO - stress test
      smoothing = c(7, 15, 30, 60)
    )

    # Exportar resultados
    exportEmpiricalIndexP()

    # Verificar se arquivo foi criado (o MVSE salva com o nome da cidade)
    arquivo_saida <- file.path(dir_cidade, paste0(nome_cidade, ".estimated_indexP.csv"))

    # Verificar se arquivo foi criado
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

# INÍCIO DO PROCESSAMENTO EXTREMO COM TEMP_MED + REL_HUMID_MED
cat("\n", paste0(rep("=", 80), collapse=""), "\n")
cat("INICIANDO PROCESSAMENTO EXTREMO MVSE - TEMP_MED + REL_HUMID_MED\n")
cat("GPU: RTX 2060 SUPER | CPU: 28 threads | Dados: T=temp_med, H=rel_humid_med, R=precip_tot\n")
cat("Cidades: ", length(arquivos_clima), " | MCMC: 25,000 | Simulações: 120\n")
cat(paste0(rep("=", 80), collapse=""), "\n\n")

# Salvar configuração inicial
config_inicial <- list(
  timestamp = Sys.time(),
  total_cidades = length(arquivos_clima),
  diretorio_dados = dir_clima,
  diretorio_resultados = "parana/mvse/outputs/indexP_tempMed_humMed",
  parametros = list(
    nMCMC = 25000,
    nSample = 120,
    nBurnin = 5000,
    temperatura = "temp_med",
    umidade = "rel_humid_med",
    precipitacao = "precip_tot"
  )
)

# Executar processamento paralelo EXTREMO
inicio_processamento <- Sys.time()

# Usar foreach para processamento paralelo extremo
resultados <- foreach(
  arquivo = arquivos_clima,
  .combine = c,
  .packages = c("MVSE"),
  .export = c("processar_cidade_extremo"),
  .errorhandling = "pass"
) %dopar% {
  processar_cidade_extremo(arquivo)
}

# Finalizar processamento
fim_processamento <- Sys.time()
tempo_total <- difftime(fim_processamento, inicio_processamento, units = "mins")

# Parar cluster
stopCluster(cl)

# RELATÓRIO FINAL
cat("\n", paste0(rep("=", 80), collapse=""), "\n")
cat("PROCESSAMENTO EXTREMO MVSE CONCLUÍDO - TEMP_MED + REL_HUMID_MED\n")
cat(paste0(rep("=", 80), collapse=""), "\n")

sucessos <- sum(resultados == TRUE, na.rm = TRUE)
erros <- length(resultados) - sucessos

cat("Total de cidades processadas:", length(arquivos_clima), "\n")
cat("Sucessos:", sucessos, "\n")
cat("Erros:", erros, "\n")
cat("Taxa de sucesso:", round(sucessos/length(arquivos_clima)*100, 1), "%\n")
cat("Tempo total:", round(tempo_total, 2), "minutos\n")
cat("Tempo médio por cidade:", round(tempo_total/length(arquivos_clima), 2), "minutos\n")

# Verificar arquivos de saída
arquivos_saida <- list.files("parana/mvse/outputs/indexP_tempMed_humMed", pattern = "\\.estimated_indexP\\.csv$", recursive = TRUE)
cat("Arquivos de resultado encontrados:", length(arquivos_saida), "\n")

if(length(arquivos_saida) > 0) {
  cat("Primeiros resultados:\n")
  for(i in 1:min(5, length(arquivos_saida))) {
    cat("-", arquivos_saida[i], "\n")
  }
}

# Salvar relatório final
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

saveRDS(relatorio_final, "relatorio_mvse_parana.rds")

cat("\nRelatório salvo em: relatorio_mvse_parana.rds\n")
cat("Resultados salvos em: parana/mvse/outputs/indexP_tempMed_humMed/\n")
cat("\nProcessamento MVSE com TEMP_MED + REL_HUMID_MED finalizado!\n")
cat(paste0(rep("=", 80), collapse=""), "\n")