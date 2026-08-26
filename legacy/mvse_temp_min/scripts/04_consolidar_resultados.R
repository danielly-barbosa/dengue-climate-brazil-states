# Script para consolidar resultados MVSE temp_min e rel_humid_med
library(data.table)

# Diretório com os resultados
dir_resultados <- "indexP_tempMin_humMed"

# Listar todos os arquivos .estimated_indexP.csv
arquivos <- list.files(dir_resultados, 
                      pattern = "*.estimated_indexP.csv", 
                      recursive = TRUE, 
                      full.names = TRUE)

cat("Encontrados", length(arquivos), "arquivos de resultados\n")

# Função para ler e adicionar código da cidade
ler_arquivo <- function(arquivo) {
  # Extrair código da cidade do caminho
  codigo_cidade <- basename(dirname(arquivo))
  
  # Ler dados
  dados <- fread(arquivo)
  dados[, cidade := codigo_cidade]
  
  return(dados)
}

# Consolidar todos os arquivos
cat("Consolidando resultados...\n")
resultados_consolidados <- rbindlist(lapply(arquivos, ler_arquivo))

# Salvar resultado consolidado
arquivo_saida <- "resultados_mvse_tempMin_humMed_consolidado.csv"
fwrite(resultados_consolidados, arquivo_saida)

cat("Resultados consolidados salvos em:", arquivo_saida, "\n")
cat("Total de registros:", nrow(resultados_consolidados), "\n")
cat("Cidades processadas:", length(unique(resultados_consolidados$cidade)), "\n")

# Estatísticas básicas
cat("\nEstatísticas do IndexP:\n")
print(summary(resultados_consolidados$indexP))

cat("\nPrimeiras linhas do resultado:\n")
print(head(resultados_consolidados))
