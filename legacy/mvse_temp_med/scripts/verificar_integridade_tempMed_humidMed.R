# Script para verificar integridade dos dados T-H-R médios
# Temperatura média, umidade relativa média e precipitação total

library(data.table)
library(dplyr)

cat(paste(rep("=", 80), collapse = ""), "\n")
cat("VERIFICAÇÃO DE INTEGRIDADE - DADOS T-H-R MÉDIOS\n")
cat(paste(rep("=", 80), collapse = ""), "\n\n")

# Diretório dos dados
dir_dados <- "d:/CÓDIGOS/dados_mvse_cidades_tempMed_humidMed"

# Listar arquivos CSV
arquivos_csv <- list.files(dir_dados, pattern = "*.csv", full.names = TRUE)
cat("Total de arquivos encontrados:", length(arquivos_csv), "\n\n")

# Inicializar contadores
cidades_ok <- 0
cidades_problemas <- 0
problemas_detalhados <- list()

# Verificar cada arquivo
for(i in seq_along(arquivos_csv)) {
  arquivo <- arquivos_csv[i]
  geocode <- tools::file_path_sans_ext(basename(arquivo))
  
  tryCatch({
    # Carregar dados
    dados <- read.csv(arquivo, stringsAsFactors = FALSE)
    
    # Verificações básicas
    problemas <- c()
    
    # 1. Verificar colunas obrigatórias
    colunas_esperadas <- c("date", "T", "H", "R")
    colunas_faltantes <- setdiff(colunas_esperadas, names(dados))
    if(length(colunas_faltantes) > 0) {
      problemas <- c(problemas, paste("Colunas faltantes:", paste(colunas_faltantes, collapse = ", ")))
    }
    
    # 2. Verificar número de registros
    if(nrow(dados) < 365) {
      problemas <- c(problemas, paste("Poucos registros:", nrow(dados), "< 365"))
    }
    
    # 3. Verificar valores faltantes
    valores_na <- sum(is.na(dados))
    if(valores_na > 0) {
      problemas <- c(problemas, paste("Valores NA:", valores_na))
    }
    
    # 4. Verificar formato de data
    dados$date <- as.Date(dados$date)
    datas_invalidas <- sum(is.na(dados$date))
    if(datas_invalidas > 0) {
      problemas <- c(problemas, paste("Datas inválidas:", datas_invalidas))
    }
    
    # 5. Verificar ranges de valores
    if(any(dados$T < -10 | dados$T > 50, na.rm = TRUE)) {
      problemas <- c(problemas, "Temperatura fora do range (-10°C a 50°C)")
    }
    
    if(any(dados$H < 0 | dados$H > 100, na.rm = TRUE)) {
      problemas <- c(problemas, "Umidade fora do range (0% a 100%)")
    }
    
    if(any(dados$R < 0, na.rm = TRUE)) {
      problemas <- c(problemas, "Precipitação negativa")
    }
    
    # 6. Verificar continuidade temporal
    if(nrow(dados) > 1) {
      datas_ordenadas <- sort(dados$date)
      gaps <- diff(datas_ordenadas)
      gaps_grandes <- sum(gaps > 14)  # Gaps maiores que 2 semanas
      if(gaps_grandes > 0) {
        problemas <- c(problemas, paste("Gaps temporais grandes:", gaps_grandes))
      }
    }
    
    # Resultado da verificação
    if(length(problemas) == 0) {
      cidades_ok <- cidades_ok + 1
      if(i %% 50 == 0) {
        cat("✓ Verificadas", i, "cidades...\n")
      }
    } else {
      cidades_problemas <- cidades_problemas + 1
      problemas_detalhados[[geocode]] <- problemas
      cat("⚠ Cidade", geocode, "- Problemas:", length(problemas), "\n")
    }
    
  }, error = function(e) {
    cidades_problemas <- cidades_problemas + 1
    problemas_detalhados[[geocode]] <- paste("Erro ao ler arquivo:", e$message)
    cat("✗ Erro na cidade", geocode, ":", e$message, "\n")
  })
}

cat("\n")
cat(paste(rep("=", 80), collapse = ""), "\n")
cat("RESUMO DA VERIFICAÇÃO DE INTEGRIDADE\n")
cat(paste(rep("=", 80), collapse = ""), "\n")
cat("✓ Cidades sem problemas:", cidades_ok, "\n")
cat("⚠ Cidades com problemas:", cidades_problemas, "\n")
cat("📊 Taxa de sucesso:", round(cidades_ok / length(arquivos_csv) * 100, 2), "%\n\n")

# Mostrar detalhes dos problemas
if(cidades_problemas > 0) {
  cat("DETALHES DOS PROBLEMAS:\n")
  cat(paste(rep("-", 40), collapse = ""), "\n")
  
  for(cidade in names(problemas_detalhados)) {
    cat("Cidade", cidade, ":\n")
    for(problema in problemas_detalhados[[cidade]]) {
      cat("  -", problema, "\n")
    }
    cat("\n")
  }
}

# Estatísticas gerais dos dados válidos
cat("ESTATÍSTICAS GERAIS DOS DADOS VÁLIDOS:\n")
cat(paste(rep("-", 40), collapse = ""), "\n")

# Carregar uma amostra de arquivos para estatísticas
amostra_arquivos <- sample(arquivos_csv, min(10, length(arquivos_csv)))
dados_amostra <- data.frame()

for(arquivo in amostra_arquivos) {
  tryCatch({
    dados_temp <- read.csv(arquivo, stringsAsFactors = FALSE)
    dados_temp$geocode <- tools::file_path_sans_ext(basename(arquivo))
    dados_amostra <- rbind(dados_amostra, dados_temp)
  }, error = function(e) {
    # Ignorar erros na amostra
  })
}

if(nrow(dados_amostra) > 0) {
  cat("Amostra de", length(amostra_arquivos), "cidades:\n")
  cat("- Registros totais:", nrow(dados_amostra), "\n")
  cat("- Temperatura média:", round(mean(dados_amostra$T, na.rm = TRUE), 2), "°C\n")
  cat("- Umidade média:", round(mean(dados_amostra$H, na.rm = TRUE), 2), "%\n")
  cat("- Precipitação média:", round(mean(dados_amostra$R, na.rm = TRUE), 2), "mm\n")
  cat("- Período:", min(as.Date(dados_amostra$date)), "a", max(as.Date(dados_amostra$date)), "\n")
}

cat("\n✅ Verificação de integridade concluída!\n")