# Script para preparar dados MVSE com temp_min e rel_humid_med
# Baseado no arquivo climate_pe_pos_2016_2.csv

# Limpar ambiente
rm(list = ls())
gc()

# Configurar CRAN
local({r <- getOption("repos")
       r["CRAN"] <- "https://cloud.r-project.org/"
       options(repos=r)})

# Carregar pacotes necessários
pacotes <- c("dplyr", "readr", "lubridate")

for(pacote in pacotes) {
  if(!require(pacote, character.only = TRUE)) {
    install.packages(pacote)
    library(pacote, character.only = TRUE)
  }
}

# Configurar diretórios
setwd("d:/CÓDIGOS")
arquivo_clima <- "d:/CÓDIGOS/ZENODO/infodengue_sprint_24-25/climate_pe_pos_2016_2.csv"
dir_saida <- "d:/CÓDIGOS/dados_mvse_cidades_tempMin_humMed"

# Criar diretório de saída
dir.create(dir_saida, showWarnings = FALSE, recursive = TRUE)

cat("Preparando dados MVSE com temp_min e rel_humid_med\n")
cat("Arquivo de entrada:", arquivo_clima, "\n")
cat("Diretório de saída:", dir_saida, "\n\n")

# Verificar se arquivo existe
if(!file.exists(arquivo_clima)) {
  stop("ERRO: Arquivo não encontrado: ", arquivo_clima)
}

# Ler dados climáticos
cat("Lendo dados climáticos...\n")
dados_clima <- read_csv(arquivo_clima, show_col_types = FALSE)

cat("Dimensões dos dados:", nrow(dados_clima), "linhas x", ncol(dados_clima), "colunas\n")
cat("Período:", min(dados_clima$date), "a", max(dados_clima$date), "\n")
cat("Cidades únicas:", length(unique(dados_clima$geocode)), "\n\n")

# Verificar colunas necessárias
colunas_necessarias <- c("date", "geocode", "temp_min", "rel_humid_med", "precip_tot")
colunas_faltantes <- setdiff(colunas_necessarias, names(dados_clima))

if(length(colunas_faltantes) > 0) {
  stop("ERRO: Colunas faltantes: ", paste(colunas_faltantes, collapse = ", "))
}

cat("Colunas verificadas: ✓\n")
cat("- temp_min: Temperatura mínima\n")
cat("- rel_humid_med: Umidade relativa média\n") 
cat("- precip_tot: Precipitação total\n\n")

# Processar dados por cidade
cidades <- unique(dados_clima$geocode)
cat("Processando", length(cidades), "cidades...\n\n")

sucessos <- 0
erros <- 0

for(i in seq_along(cidades)) {
  cidade_codigo <- cidades[i]
  
  tryCatch({
    # Filtrar dados da cidade
    dados_cidade <- dados_clima %>%
      filter(geocode == cidade_codigo) %>%
      select(date, temp_min, rel_humid_med, precip_tot) %>%
      arrange(date)
    
    # Verificar se há dados suficientes
    if(nrow(dados_cidade) < 365) {
      cat("⚠ Cidade", cidade_codigo, "- Poucos dados:", nrow(dados_cidade), "registros\n")
    }
    
    # Verificar valores faltantes
    valores_faltantes <- sum(is.na(dados_cidade))
    if(valores_faltantes > 0) {
      cat("⚠ Cidade", cidade_codigo, "- Valores faltantes:", valores_faltantes, "\n")
      # Remover linhas com valores faltantes
      dados_cidade <- dados_cidade %>% filter(complete.cases(.))
    }
    
    # Preparar dados no formato MVSE (T, H, R)
    dados_mvse <- dados_cidade %>%
      mutate(
        T = temp_min,           # Temperatura mínima
        H = rel_humid_med,      # Umidade relativa média  
        R = precip_tot          # Precipitação total
      ) %>%
      select(date, T, H, R)
    
    # Verificar integridade dos dados
    if(any(is.na(dados_mvse$T)) || any(is.na(dados_mvse$H)) || any(is.na(dados_mvse$R))) {
      stop("Valores NA encontrados após processamento")
    }
    
    # Verificar valores válidos
    if(any(dados_mvse$T < -50 | dados_mvse$T > 60)) {
      cat("⚠ Cidade", cidade_codigo, "- Temperaturas extremas detectadas\n")
    }
    
    if(any(dados_mvse$H < 0 | dados_mvse$H > 100)) {
      cat("⚠ Cidade", cidade_codigo, "- Umidade fora do intervalo 0-100%\n")
    }
    
    if(any(dados_mvse$R < 0)) {
      cat("⚠ Cidade", cidade_codigo, "- Precipitação negativa detectada\n")
    }
    
    # Salvar arquivo da cidade
    arquivo_saida <- file.path(dir_saida, paste0(cidade_codigo, ".csv"))
    write_csv(dados_mvse, arquivo_saida)
    
    sucessos <- sucessos + 1
    
    if(i %% 20 == 0 || i == length(cidades)) {
      cat("Progresso:", i, "/", length(cidades), "cidades processadas\n")
    }
    
  }, error = function(e) {
    cat("✗ ERRO na cidade", cidade_codigo, ":", e$message, "\n")
    erros <- erros + 1
  })
}

# Resumo final
cat("\n", paste0(rep("=", 60), collapse=""), "\n")
cat("PREPARAÇÃO DE DADOS CONCLUÍDA\n")
cat("Sucessos:", sucessos, "cidades\n")
cat("Erros:", erros, "cidades\n")
cat("Diretório de saída:", dir_saida, "\n")
cat("Estrutura dos dados: T (temp_min), H (rel_humid_med), R (precip_tot)\n")
cat(paste0(rep("=", 60), collapse=""), "\n")

# Verificar alguns arquivos criados
arquivos_criados <- list.files(dir_saida, pattern = "\\.csv$")
cat("Arquivos criados:", length(arquivos_criados), "\n")

if(length(arquivos_criados) > 0) {
  cat("Primeiros arquivos:\n")
  for(i in 1:min(5, length(arquivos_criados))) {
    cat("-", arquivos_criados[i], "\n")
  }
  
  # Verificar estrutura de um arquivo exemplo
  arquivo_exemplo <- file.path(dir_saida, arquivos_criados[1])
  dados_exemplo <- read_csv(arquivo_exemplo, show_col_types = FALSE)
  
  cat("\nEstrutura do arquivo exemplo (", arquivos_criados[1], "):\n")
  cat("Colunas:", paste(names(dados_exemplo), collapse = ", "), "\n")
  cat("Registros:", nrow(dados_exemplo), "\n")
  cat("Período:", min(dados_exemplo$date), "a", max(dados_exemplo$date), "\n")
  
  # Estatísticas básicas
  cat("\nEstatísticas básicas:\n")
  cat("T (temp_min): min =", round(min(dados_exemplo$T, na.rm=TRUE), 2), 
      ", max =", round(max(dados_exemplo$T, na.rm=TRUE), 2),
      ", média =", round(mean(dados_exemplo$T, na.rm=TRUE), 2), "\n")
  cat("H (rel_humid_med): min =", round(min(dados_exemplo$H, na.rm=TRUE), 2), 
      ", max =", round(max(dados_exemplo$H, na.rm=TRUE), 2),
      ", média =", round(mean(dados_exemplo$H, na.rm=TRUE), 2), "\n")
  cat("R (precip_tot): min =", round(min(dados_exemplo$R, na.rm=TRUE), 2), 
      ", max =", round(max(dados_exemplo$R, na.rm=TRUE), 2),
      ", média =", round(mean(dados_exemplo$R, na.rm=TRUE), 2), "\n")
}

cat("\nDados prontos para processamento MVSE!\n")