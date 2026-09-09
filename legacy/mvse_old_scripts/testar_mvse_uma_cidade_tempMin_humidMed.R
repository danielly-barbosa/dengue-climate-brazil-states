



suppressMessages({
  library(MVSE)
})


cidade_teste <- "recife"
geocode_teste <- "2611606"
dir_dados <- "../dados_mvse_cidades_tempMin_humidMed"
dir_teste <- "../teste_mvse_tempMin_humidMed"

cat("================================================================================\n")
cat("TESTE MVSE - TEMP_MIN + UMIDADE MÉDIA + PRECIPITAÇÃO TOTAL\n")
cat("================================================================================\n")
cat("Cidade teste:", cidade_teste, "\n")
cat("Geocode teste:", geocode_teste, "\n")
cat("Diretório dados:", dir_dados, "\n")
cat("Diretório teste:", dir_teste, "\n")
cat("\n")


if (!dir.exists(dir_teste)) {
  dir.create(dir_teste, recursive = TRUE)
  cat("✓ Diretório de teste criado\n")
}


arquivo_entrada <- file.path(dir_dados, paste0(geocode_teste, ".csv"))

cat("Arquivo de entrada:", arquivo_entrada, "\n")


if (!file.exists(arquivo_entrada)) {
  cat("✗ ERRO: Arquivo não encontrado:", arquivo_entrada, "\n")
  cat("Arquivos disponíveis no diretório:\n")
  arquivos <- list.files(dir_dados, pattern = "\\.csv$")
  cat(paste(head(arquivos, 10), collapse = "\n"), "\n")
  stop("Arquivo de entrada não encontrado")
}


cat("\nCarregando dados...\n")
dados <- read.csv(arquivo_entrada)

cat("✓ Dados carregados\n")
cat("Dimensões:", nrow(dados), "linhas x", ncol(dados), "colunas\n")
cat("Colunas:", paste(names(dados), collapse = ", "), "\n")
cat("Período:", min(dados$date), "a", max(dados$date), "\n")


colunas_esperadas <- c("date", "T", "H", "R")
colunas_faltando <- setdiff(colunas_esperadas, names(dados))

if (length(colunas_faltando) > 0) {
  cat("✗ ERRO: Colunas faltando:", paste(colunas_faltando, collapse = ", "), "\n")
  stop("Estrutura de dados incorreta")
}


cat("\nEstatísticas dos dados:\n")
cat("- T (temp_min):", round(min(dados$T, na.rm = TRUE), 2), "a", round(max(dados$T, na.rm = TRUE), 2), "°C\n")
cat("- H (umidade_med):", round(min(dados$H, na.rm = TRUE), 2), "a", round(max(dados$H, na.rm = TRUE), 2), "%\n")
cat("- R (precip_tot):", round(min(dados$R, na.rm = TRUE), 2), "a", round(max(dados$R, na.rm = TRUE), 2), "mm\n")


dados_originais <- nrow(dados)
dados <- dados[!is.na(dados$T) & !is.na(dados$H) & !is.na(dados$R), ]
dados_limpos <- nrow(dados)

cat("- Registros originais:", dados_originais, "\n")
cat("- Registros após limpeza:", dados_limpos, "\n")
cat("- Registros removidos:", dados_originais - dados_limpos, "\n")

if (dados_limpos < 100) {
  cat("✗ ERRO: Dados insuficientes após limpeza:", dados_limpos, "registros\n")
  stop("Dados insuficientes para MVSE")
}


cat("\nDefinindo parâmetros MVSE...\n")
nMCMC <- 1000
bMCMC <- 0.5
cRho <- 0.5
cEta <- 2.0
gauJump <- 0.05
nSim <- 100
smoothing <- c(7, 15)

cat("Parâmetros definidos:\n")
cat("- nMCMC:", nMCMC, "\n")
cat("- bMCMC:", bMCMC, "\n")
cat("- cRho:", cRho, "\n")
cat("- cEta:", cEta, "\n")
cat("- gauJump:", gauJump, "\n")
cat("- nSim:", nSim, "\n")
cat("- smoothing:", paste(smoothing, collapse = ", "), "\n")


setwd(dir_teste)


setOutputFilePathAndTag(paste0("teste_", geocode_teste))


cat("\nDefinindo série climática...\n")
setEmpiricalClimateSeries(arquivo_entrada)
cat("✓ Série climática definida\n")


cat("Plotando clima...\n")
tryCatch({
  plotClimate()
  cat("✓ Gráfico de clima criado\n")
}, error = function(e) {
  cat("⚠ Aviso: Erro ao plotar clima:", e$message, "\n")
})


cat("\nDefinindo priors...\n")
setMosqLifeExpPrior(pmean=12, psd=2, pdist='gamma')
setMosqIncPerPrior(pmean=7, psd=2, pdist='gamma')
setMosqBitingPrior(pmean=0.25, psd=0.01, pdist='gamma')
setHumanLifeExpPrior(pmean=71.1, psd=2, pdist='gamma')
setHumanIncPerPrior(pmean=5.8, psd=1, pdist='gamma')
setHumanInfPerPrior(pmean=5.9, psd=1, pdist='gamma')
setHumanMosqTransProbPrior(pmean=0.5, psd=0.01, pdist='gamma')
cat("✓ Priors definidos\n")


cat("\n", rep("=", 60), "\n")
cat("PASSO 1: Estimando coeficientes ecológicos...\n")
cat(rep("=", 60), "\n")

tryCatch({
  estimateEcoCoefficients(
    nMCMC = nMCMC,
    bMCMC = bMCMC,
    cRho = cRho,
    cEta = cEta,
    gauJump = gauJump
  )
  cat("✓ Coeficientes estimados com sucesso\n")
}, error = function(e) {
  cat("✗ ERRO na estimação de coeficientes:", e$message, "\n")
  quit(status = 1)
})


cat("\n", rep("=", 60), "\n")
cat("PASSO 2: Simulando indexP empírico...\n")
cat(rep("=", 60), "\n")

tryCatch({
  simulateEmpiricalIndexP(
    nSample = nSim,
    smoothing = smoothing
  )
  cat("✓ IndexP simulado com sucesso\n")
}, error = function(e) {
  cat("✗ ERRO na simulação do indexP:", e$message, "\n")
  quit(status = 1)
})


cat("\n", rep("=", 60), "\n")
cat("PASSO 3: Exportando resultados...\n")
cat(rep("=", 60), "\n")

tryCatch({
  exportEmpiricalIndexP()
  cat("✓ IndexP exportado com sucesso\n")

  plotEmpiricalIndexP(outfilename='teste_indexP')
  cat("✓ Gráfico do indexP criado\n")
}, error = function(e) {
  cat("✗ ERRO na exportação:", e$message, "\n")
  quit(status = 1)
})


cat("\nVerificando arquivos criados...\n")
arquivos_criados <- list.files(dir_teste, pattern = paste0("teste_", geocode_teste))
if (length(arquivos_criados) > 0) {
  cat("✓ Arquivos criados:\n")
  for (arquivo in arquivos_criados) {
    cat("  -", arquivo, "\n")
  }
} else {
  cat("⚠ Nenhum arquivo encontrado com o padrão esperado\n")
}

cat("\n", rep("=", 80), "\n")
cat("🎉 TESTE MVSE CONCLUÍDO COM SUCESSO!\n")
cat(rep("=", 80), "\n")
cat("Cidade:", cidade_teste, "\n")
cat("Geocode:", geocode_teste, "\n")
cat("Variáveis: temp_min (T) + rel_humid_med (H) + precip_tot (R)\n")
cat("Diretório de saída:", dir_teste, "\n")
cat(rep("=", 80), "\n")