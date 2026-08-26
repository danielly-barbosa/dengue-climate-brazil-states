# Script para extrair a defasagem (lag) média e de pico para o Index P
# Metodologia: DLNM MASS + OFFSET (Metodologia original e final)

suppressPackageStartupMessages({
  library(dplyr)
  library(dlnm)
})

# Definir diretórios
base_dir <- "c:/Users/DaniLinda/Desktop/Doutorado PE/analises_individuais/DLNM MASS + OFFSET"
input_dir <- file.path(base_dir, "Tabela Rdata")
output_dir <- file.path(base_dir, "Defasagens")

# Criar pasta de saída se não existir
if(!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
  cat("Diretório criado:", output_dir, "\n")
}

estados <- c("PE", "GO", "RJ", "RS")
resultados <- data.frame()

for(uf in estados) {
  arquivo <- file.path(input_dir, paste0("indexP_", uf, "_offset.RData"))
  
  if(file.exists(arquivo)) {
    # Cria um ambiente limpo para não sobrescrever variáveis
    env <- new.env()
    load(arquivo, envir = env)
    
    # Identificar o objeto crosspred (geralmente chamado 'pred')
    if("pred" %in% ls(env)) {
      pred_obj <- env$pred
    } else {
      # Tenta achar qualquer objeto da classe crosspred
      objs <- ls(env)
      pred_name <- objs[sapply(objs, function(x) inherits(env[[x]], "crosspred"))][1]
      if(is.na(pred_name)) stop(paste("Objeto crosspred não encontrado em", arquivo))
      pred_obj <- env[[pred_name]]
    }
    
    # Encontrar o valor de IndexP que causou o MAIOR Risco Relativo acumulado (overall)
    idx_max <- which.max(pred_obj$allRRfit)
    valor_pico <- as.character(pred_obj$predvar[idx_max])
    rr_max_overall <- pred_obj$allRRfit[idx_max]
    
    # Extrair a curva de risco ao longo dos lags para ESSE valor de IndexP
    rr_por_lag <- pred_obj$matRRfit[valor_pico, ]
    lags_char <- colnames(pred_obj$matRRfit)
    lags <- as.numeric(gsub("lag", "", lags_char))
    
    # 1. Defasagem de pico (semana em que o RR é mais alto)
    lag_pico <- lags[which.max(rr_por_lag)]
    
    # 2. Defasagem média ponderada (Centro de massa do efeito)
    # Ponderamos apenas onde o RR > 1 (log(RR) > 0), ou seja, onde há aumento de risco
    efeitos_log <- log(rr_por_lag)
    pesos <- ifelse(efeitos_log > 0, efeitos_log, 0)
    
    if(sum(pesos) > 0) {
      defasagem_media <- sum(lags * pesos) / sum(pesos)
    } else {
      defasagem_media <- NA
    }
    
    # Adicionar ao dataframe de resultados
    resultados <- rbind(resultados, data.frame(
      Estado = uf,
      Variavel = "Index P",
      Valor_IndexP_Maior_RR = as.numeric(valor_pico),
      RR_Geral_Acumulado = round(rr_max_overall, 3),
      Lag_de_Pico_Semanas = lag_pico,
      Lag_Medio_Ponderado_Semanas = round(defasagem_media, 2)
    ))
    
    cat(sprintf("Estado %s processado com sucesso.\n", uf))
  } else {
    cat(sprintf("AVISO: Arquivo não encontrado para %s: %s\n", uf, arquivo))
  }
}

# Salvar resultados
output_file <- file.path(output_dir, "tabela_defasagens_indexP_offset.csv")
write.csv(resultados, output_file, row.names = FALSE)

cat("\n=== RESULTADOS FINAIS ===\n")
print(resultados)
cat("\nResultados salvos com sucesso em:", output_file, "\n")
