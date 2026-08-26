# Teste MVSE para uma única cidade - TEMP_MIN
# Script para identificar problemas no processamento

# Limpar ambiente
rm(list = ls())
gc()

# Carregar biblioteca
library(MVSE)

# Configurar diretórios
setwd("d:/CÓDIGOS")
dir.create("teste_mvse_tempMin", showWarnings = FALSE)

# Arquivo de teste
arquivo_teste <- "d:/CÓDIGOS/dados_mvse_cidades_tempMin_corrigido/recife.csv"
dir_saida <- "teste_mvse_tempMin/recife"
dir.create(dir_saida, showWarnings = FALSE, recursive = TRUE)

cat(paste0(rep("=", 80), collapse=""), "\n")
cat("TESTE MVSE - UMA CIDADE (TEMP_MIN)\n")
cat(paste0(rep("=", 80), collapse=""), "\n")
cat("Arquivo:", arquivo_teste, "\n")
cat("Diretório saída:", dir_saida, "\n")

# Verificar se arquivo existe
if(!file.exists(arquivo_teste)) {
  stop("ERRO: Arquivo não encontrado: ", arquivo_teste)
}

# Ler e verificar dados
dados <- read.csv(arquivo_teste)
cat("Dados carregados:\n")
cat("- Linhas:", nrow(dados), "\n")
cat("- Colunas:", ncol(dados), "\n")
cat("- Nomes das colunas:", paste(names(dados), collapse=", "), "\n")
cat("- Primeiras 3 linhas:\n")
print(head(dados, 3))

cat("\nIniciando processamento MVSE...\n")

tryCatch({
  # Passo 1: Configurar série temporal
  cat("1. Configurando série temporal...\n")
  setEmpiricalClimateSeries(arquivo_teste)
  cat("   ✓ Série temporal configurada\n")
  
  # Passo 2: Configurar saída
  cat("2. Configurando arquivo de saída...\n")
  setOutputFilePathAndTag(file.path(dir_saida, "recife"))
  cat("   ✓ Arquivo de saída configurado\n")
  
  # Passo 3: Configurar priors
  cat("3. Configurando priors...\n")
  setMosqLifeExpPrior(pmean=12, psd=2, pdist='gamma')
  setMosqIncPerPrior(pmean=7, psd=2, pdist='gamma')
  setMosqBitingPrior(pmean=0.25, psd=0.01, pdist='gamma')
  setHumanLifeExpPrior(pmean=71.1, psd=2, pdist='gamma')
  setHumanIncPerPrior(pmean=5.8, psd=1, pdist='gamma')
  setHumanInfPerPrior(pmean=5.9, psd=1, pdist='gamma')
  setHumanMosqTransProbPrior(pmean=0.5, psd=0.01, pdist='gamma')
  cat("   ✓ Priors configurados\n")
  
  # Passo 4: Estimar coeficientes (parâmetros corretos)
  cat("4. Estimando coeficientes ecológicos...\n")
  estimateEcoCoefficients(
    nMCMC = 1000,      # Reduzido para teste
    bMCMC = 0.5,       # Parâmetro correto
    cRho = 1,          # Parâmetro correto
    cEta = 1,          # Parâmetro correto
    gauJump = 0.75     # Parâmetro correto
  )
  cat("   ✓ Coeficientes estimados\n")
  
  # Passo 5: Calcular indexP
  cat("5. Calculando indexP...\n")
  simulateEmpiricalIndexP(
    nSample = 10,      # Reduzido para teste
    smoothing = c(7, 15)  # Suavização padrão
  )
  cat("   ✓ IndexP calculado\n")
  
  # Passo 6: Exportar resultados
  cat("6. Exportando resultados...\n")
  exportEmpiricalIndexP()
  cat("   ✓ Resultados exportados\n")
  
  # Verificar se arquivo foi criado
  arquivo_resultado <- file.path(dir_saida, "estimated_indexP.csv")
  if(file.exists(arquivo_resultado)) {
    cat("\n✓ SUCESSO! Arquivo criado:", arquivo_resultado, "\n")
    
    # Ler e mostrar resultado
    resultado <- read.csv(arquivo_resultado)
    cat("Resultado:\n")
    cat("- Linhas:", nrow(resultado), "\n")
    cat("- Colunas:", paste(names(resultado), collapse=", "), "\n")
    cat("- Primeiras 5 linhas:\n")
    print(head(resultado, 5))
    
  } else {
    cat("\n✗ ERRO: Arquivo de resultado não foi criado\n")
  }
  
}, error = function(e) {
  cat("\n✗ ERRO durante processamento:\n")
  cat("Mensagem:", e$message, "\n")
  cat("Detalhes:", toString(e), "\n")
})

cat("\n", paste0(rep("=", 80), collapse=""), "\n")
cat("TESTE CONCLUÍDO\n")
cat(paste0(rep("=", 80), collapse=""), "\n")