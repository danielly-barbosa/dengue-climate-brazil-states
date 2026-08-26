# ==============================================================================
# Análise Preditiva - Etapa 1: Pernambuco + Índice P
# Objetivo: Avaliar se o Índice P melhora a capacidade preditiva de casos de dengue
# fora da amostra (treino: 2017-2022, teste: 2023-2024).
# ==============================================================================

# Carregar pacotes necessários
suppressPackageStartupMessages({
  library(dplyr)
  library(lubridate)
  library(MASS)
  library(ggplot2)
  library(tidyr)
})

# Caminhos dos arquivos
path_dengue <- "DLNM MASS + OFFSET/PE DLNM MASS + OFFSET/dados/dengue_pe_2015_2024.csv"
path_indexp <- "DLNM MASS + OFFSET/PE DLNM MASS + OFFSET/dados/mvse_pernambuco_consolidado.csv"

# 1. Carregar bancos de dados
cat("Carregando bancos de dados...\n")
dengue_df <- read.csv(path_dengue)
indexp_df <- read.csv(path_indexp)

# Garantir que as datas estejam no formato Date
dengue_df$date <- as.Date(dengue_df$date)
indexp_df$date <- as.Date(indexp_df$date)

# 2. Agregar dados para o nível estadual (Pernambuco)
cat("Agregando dados para o nível estadual...\n")

# Agregar casos de dengue (somar casos de todos os municípios de PE)
dengue_agg <- dengue_df %>%
  filter(year >= 2017) %>% # Índice P começa em 2017
  group_by(date) %>%
  summarise(
    casos_dengue = sum(casos, na.rm = TRUE),
    ano = first(year),
    semana_epidemiologica = as.numeric(substr(as.character(first(epiweek)), 5, 6)),
    .groups = "drop"
  )

# Agregar Índice P (média simples dos municípios de PE)
indexp_agg <- indexp_df %>%
  group_by(date) %>%
  summarise(
    indiceP = mean(indexP, na.rm = TRUE),
    .groups = "drop"
  )

# Unir os bancos
df_pe <- inner_join(dengue_agg, indexp_agg, by = "date") %>%
  mutate(estado = "PE") %>%
  dplyr::select(estado, ano, semana_epidemiologica, casos_dengue, indiceP, date) %>%
  arrange(date)

# Verificar valores ausentes
if (any(is.na(df_pe))) {
  warning("Existem valores ausentes na base agregada. Tratando NAs...")
  df_pe <- drop_na(df_pe)
}

# 3. Preparação da Base (Tempo sequencial e Sazonalidade)
cat("Criando variáveis de tempo e sazonalidade...\n")
df_pe <- df_pe %>%
  mutate(
    tempo = row_number(),
    # Nota sobre semana 53: a divisão por 52 permite que o ciclo feche, 
    # a semana 53 terá um valor levemente deslocado mas funcional para a função trigonométrica
    sin_ano = sin(2 * pi * semana_epidemiologica / 52),
    cos_ano = cos(2 * pi * semana_epidemiologica / 52)
  )

# 4. Separar em treino (2017-2022) e teste (2023-2024)
df_treino <- df_pe %>% filter(ano >= 2017 & ano <= 2022)
df_teste  <- df_pe %>% filter(ano >= 2023 & ano <= 2024)

# 5. Funções de modelagem e avaliação
calcular_mae <- function(observado, predito) {
  mean(abs(observado - predito), na.rm = TRUE)
}

calcular_rmse <- function(observado, predito) {
  sqrt(mean((observado - predito)^2, na.rm = TRUE))
}

ajustar_modelo_contagem <- function(formula, data) {
  # Tenta primeiro a binomial negativa (MASS::glm.nb)
  modelo <- tryCatch({
    mod <- MASS::glm.nb(formula, data = data)
    list(modelo = mod, familia_usada = "binomial_negativa")
  }, error = function(e) {
    warning("glm.nb falhou ou não convergiu. Usando Poisson como fallback.")
    mod <- glm(formula, family = poisson, data = data)
    list(modelo = mod, familia_usada = "poisson_fallback")
  })
  return(modelo)
}

avaliar_modelo <- function(nome_modelo, formula, dados_treino, dados_teste) {
  # Ajustar o modelo apenas no treino
  ajuste <- ajustar_modelo_contagem(formula, dados_treino)
  mod <- ajuste$modelo
  familia <- ajuste$familia_usada
  
  # Prever no teste
  predito <- predict(mod, newdata = dados_teste, type = "response")
  
  # Calcular métricas no teste
  observado <- dados_teste$casos_dengue
  mae <- calcular_mae(observado, predito)
  rmse <- calcular_rmse(observado, predito)
  
  # Retornar resultados
  resultados <- data.frame(
    estado = "PE",
    modelo = nome_modelo,
    variaveis = deparse(formula),
    familia_usada = familia,
    MAE = mae,
    RMSE = rmse,
    stringsAsFactors = FALSE
  )
  
  list(resultados = resultados, predito = predito, modelo = mod)
}

# 6. Ajustar modelos e avaliar
cat("Ajustando modelos e fazendo previsões...\n")

# Modelo Base
form_base <- casos_dengue ~ tempo + sin_ano + cos_ano
aval_base <- avaliar_modelo("Base", form_base, df_treino, df_teste)

# Modelo com Índice P
form_indiceP <- casos_dengue ~ indiceP + tempo + sin_ano + cos_ano
aval_indiceP <- avaliar_modelo("Índice P", form_indiceP, df_treino, df_teste)

# 7. Salvar resultados em CSV
cat("Gerando saídas (Tabela e Gráficos)...\n")

resultados_finais <- bind_rows(aval_base$resultados, aval_indiceP$resultados)
write.csv(resultados_finais, "resultados_metricas_PE_indiceP.csv", row.names = FALSE)

# 8. Gráficos

# Adicionar predições ao df_teste para os gráficos
df_teste$pred_base <- aval_base$predito
df_teste$pred_indiceP <- aval_indiceP$predito

# Gráfico 1: Observado vs Predito para o modelo com Índice P
p1 <- ggplot(df_teste, aes(x = date)) +
  geom_line(aes(y = casos_dengue, color = "Observado"), linewidth = 1) +
  geom_line(aes(y = pred_indiceP, color = "Predito (Índice P)"), linewidth = 1, linetype = "dashed") +
  scale_color_manual(values = c("Observado" = "black", "Predito (Índice P)" = "red")) +
  labs(title = "Casos Observados vs Preditos - Pernambuco (Teste 2023-2024)",
       subtitle = "Modelo com Índice P",
       x = "Data",
       y = "Casos de Dengue",
       color = "Legenda") +
  theme_minimal()

ggsave("observado_vs_predito_PE_indiceP.png", plot = p1, width = 10, height = 6, bg = "white")

# Gráfico 2: Comparação Base vs Índice P
p2 <- ggplot(df_teste, aes(x = date)) +
  geom_line(aes(y = casos_dengue, color = "Observado"), linewidth = 1) +
  geom_line(aes(y = pred_base, color = "Predito (Base)"), linewidth = 1, linetype = "dotted") +
  geom_line(aes(y = pred_indiceP, color = "Predito (Índice P)"), linewidth = 1, linetype = "dashed") +
  scale_color_manual(values = c("Observado" = "black", 
                                "Predito (Base)" = "blue", 
                                "Predito (Índice P)" = "red")) +
  labs(title = "Comparação de Previsões - Pernambuco (Teste 2023-2024)",
       subtitle = "Modelo Base vs Modelo com Índice P",
       x = "Data",
       y = "Casos de Dengue",
       color = "Legenda") +
  theme_minimal()

ggsave("comparacao_modelo_base_vs_indiceP_PE.png", plot = p2, width = 10, height = 6, bg = "white")

# 9. Imprimir no console
cat("\n=======================================================\n")
cat("RESULTADOS DAS MÉTRICAS DE PREVISÃO (TESTE 2023-2024)\n")
cat("=======================================================\n")
cat(sprintf("MAE do modelo base:         %.2f\n", aval_base$resultados$MAE))
cat(sprintf("RMSE do modelo base:        %.2f\n", aval_base$resultados$RMSE))
cat(sprintf("MAE do modelo com Índice P: %.2f\n", aval_indiceP$resultados$MAE))
cat(sprintf("RMSE do modelo com Índice P:%.2f\n", aval_indiceP$resultados$RMSE))

# Determinar melhores modelos
melhor_mae <- if (aval_base$resultados$MAE < aval_indiceP$resultados$MAE) "Base" else "Índice P"
melhor_rmse <- if (aval_base$resultados$RMSE < aval_indiceP$resultados$RMSE) "Base" else "Índice P"

cat("\n=======================================================\n")
cat(sprintf("O modelo que teve menor MAE foi:  %s\n", melhor_mae))
cat(sprintf("O modelo que teve menor RMSE foi: %s\n", melhor_rmse))
cat("=======================================================\n\n")

# Interpretação
interpretacao <- sprintf("Na validação temporal fora da amostra, o modelo com Índice P apresentou MAE %s e RMSE %s do que o modelo base no período de teste 2023–2024. Isso sugere que a inclusão do Índice P %s a capacidade preditiva dos casos de dengue em Pernambuco em comparação ao modelo contendo apenas tendência e sazonalidade.",
                         ifelse(aval_indiceP$resultados$MAE < aval_base$resultados$MAE, "menor", "maior"),
                         ifelse(aval_indiceP$resultados$RMSE < aval_base$resultados$RMSE, "menor", "maior"),
                         ifelse(aval_indiceP$resultados$MAE < aval_base$resultados$MAE & aval_indiceP$resultados$RMSE < aval_base$resultados$RMSE, "melhora", "não melhora/tem impacto misto sobre"))

cat("INTERPRETAÇÃO:\n")
cat(interpretacao, "\n")
