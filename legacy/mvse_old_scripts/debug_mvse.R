# Script de debug para identificar o problema no MVSE
library(MVSE)

# Testar com uma cidade específica
geocode_teste <- "2600054"
arquivo_entrada <- file.path("d:/CÓDIGOS/dados_mvse_cidades_tempMin_humidMed", paste0(geocode_teste, ".csv"))

cat("Testando arquivo:", arquivo_entrada, "\n")
cat("Arquivo existe:", file.exists(arquivo_entrada), "\n")

# Carregar dados
dados <- read.csv(arquivo_entrada, stringsAsFactors = FALSE)
cat("Dimensões dos dados:", dim(dados), "\n")
cat("Nomes das colunas:", names(dados), "\n")
cat("Primeiras linhas:\n")
print(head(dados))

# Verificar estrutura
cat("\nVerificando estrutura...\n")
colunas_necessarias <- c("date", "T", "H", "R")
for (col in colunas_necessarias) {
  cat("Coluna", col, "existe:", col %in% names(dados), "\n")
}

# Verificar NAs
cat("\nVerificando NAs...\n")
cat("NAs em T:", sum(is.na(dados$T)), "\n")
cat("NAs em H:", sum(is.na(dados$H)), "\n")
cat("NAs em R:", sum(is.na(dados$R)), "\n")

# Tentar filtrar dados
cat("\nTentando filtrar dados...\n")
tryCatch({
  dados_limpos <- dados[!is.na(dados$T) & !is.na(dados$H) & !is.na(dados$R), ]
  cat("Dados limpos - dimensões:", dim(dados_limpos), "\n")
}, error = function(e) {
  cat("ERRO ao filtrar dados:", e$message, "\n")
})

# Verificar tipos de dados
cat("\nTipos de dados:\n")
cat("T:", class(dados$T), "\n")
cat("H:", class(dados$H), "\n")
cat("R:", class(dados$R), "\n")