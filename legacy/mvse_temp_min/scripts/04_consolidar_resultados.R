
library(data.table)


dir_resultados <- "indexP_tempMin_humMed"


arquivos <- list.files(dir_resultados,
                      pattern = "*.estimated_indexP.csv",
                      recursive = TRUE,
                      full.names = TRUE)

cat("Encontrados", length(arquivos), "arquivos de resultados\n")


ler_arquivo <- function(arquivo) {

  codigo_cidade <- basename(dirname(arquivo))


  dados <- fread(arquivo)
  dados[, cidade := codigo_cidade]

  return(dados)
}


cat("Consolidando resultados...\n")
resultados_consolidados <- rbindlist(lapply(arquivos, ler_arquivo))


arquivo_saida <- "resultados_mvse_tempMin_humMed_consolidado.csv"
fwrite(resultados_consolidados, arquivo_saida)

cat("Resultados consolidados salvos em:", arquivo_saida, "\n")
cat("Total de registros:", nrow(resultados_consolidados), "\n")
cat("Cidades processadas:", length(unique(resultados_consolidados$cidade)), "\n")


cat("\nEstatísticas do IndexP:\n")
print(summary(resultados_consolidados$indexP))

cat("\nPrimeiras linhas do resultado:\n")
print(head(resultados_consolidados))
