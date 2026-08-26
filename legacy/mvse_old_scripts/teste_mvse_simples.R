
library(MVSE)


arquivo_teste <- 'dados_mvse_cidades_tempMin_humMed/2600054.csv'
nome_cidade <- '2600054'
dir_cidade <- file.path('teste_mvse_tempMin_humMed', nome_cidade)
dir.create(dir_cidade, showWarnings = FALSE, recursive = TRUE)

cat('Iniciando teste MVSE...\n')


if(!file.exists(arquivo_teste)) {
  stop("Arquivo não encontrado: ", arquivo_teste)
}


dados <- read.csv(arquivo_teste)
cat('Dados carregados:', nrow(dados), 'registros\n')
cat('Colunas:', paste(names(dados), collapse=', '), '\n')


cat('Configurando MVSE...\n')
setEmpiricalClimateSeries(arquivo_teste)
setOutputFilePathAndTag(file.path(dir_cidade, nome_cidade))


cat('Configurando priors...\n')
setMosqLifeExpPrior(pmean=12, psd=2, pdist='gamma')
setMosqIncPerPrior(pmean=7, psd=2, pdist='gamma')
setMosqBitingPrior(pmean=0.25, psd=0.01, pdist='gamma')
setHumanLifeExpPrior(pmean=71.1, psd=2, pdist='gamma')
setHumanIncPerPrior(pmean=5.8, psd=1, pdist='gamma')
setHumanInfPerPrior(pmean=5.9, psd=1, pdist='gamma')
setHumanMosqTransProbPrior(pmean=0.5, psd=0.01, pdist='gamma')


cat('Executando estimateEcoCoefficients...\n')
estimateEcoCoefficients(nMCMC=500, bMCMC=0.5, cRho=1, cEta=1, gauJump=0.75)


cat('Executando simulateEmpiricalIndexP...\n')
simulateEmpiricalIndexP(nSample=50, smoothing=c(7,15,30,60))


cat('Exportando resultados...\n')
exportEmpiricalIndexP()


arquivo_saida <- file.path(dir_cidade, paste0(nome_cidade, ".estimated_indexP.csv"))
if(file.exists(arquivo_saida)) {
  cat('SUCESSO: Arquivo criado em', arquivo_saida, '\n')
} else {
  cat('ERRO: Arquivo não foi criado\n')
}

cat('Teste concluído.\n')