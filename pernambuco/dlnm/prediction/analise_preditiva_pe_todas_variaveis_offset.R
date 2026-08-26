# ==============================================================================
# Análise Preditiva - Etapa 2: Pernambuco + Offset Populacional
# Comparando o Índice P com variáveis climáticas isoladas na previsão fora
# da amostra (treino: 2017-2022, teste: 2023-2024), usando binomial negativa.
# ==============================================================================

# 1. Carregar pacotes necessários
suppressPackageStartupMessages({
  library(dplyr)
  library(lubridate)
  library(MASS)
  library(ggplot2)
  library(tidyr)
})

# Caminhos dos arquivos (assumindo wd como a raiz do projeto)
path_dengue  <- "DLNM MASS + OFFSET/PE DLNM MASS + OFFSET/dados/dengue_pe_2015_2024.csv"
path_indexp  <- "DLNM MASS + OFFSET/PE DLNM MASS + OFFSET/dados/mvse_pernambuco_consolidado.csv"
path_climate <- "DLNM MASS + OFFSET/PE DLNM MASS + OFFSET/dados/climate_pe_pos_2016_2_backup.csv"
path_pop     <- "DLNM MASS + OFFSET/PE DLNM MASS + OFFSET/dados/br_ibge_populacao_municipio_filtrado.csv"

cat("1. Carregando bancos de dados...\n")
dengue_df  <- read.csv(path_dengue)
indexp_df  <- read.csv(path_indexp)
climate_df <- read.csv(path_climate)
pop_df     <- read.csv(path_pop)

# Garantir datas
dengue_df$date  <- as.Date(dengue_df$date)
indexp_df$date  <- as.Date(indexp_df$date)
climate_df$date <- as.Date(climate_df$date)

# Filtrar e padronizar nomes
# População
pop_pe <- pop_df %>%
  filter(sigla_uf == "PE") %>%
  rename(geocode = id_municipio)

# Clima (padronizar nomes)
climate_pe <- climate_df %>%
  rename(
    temp_media   = temp_med,
    temp_minima  = temp_min,
    temp_maxima  = temp_max,
    precipitacao = precip_tot,
    umidade      = rel_humid_med
  ) %>%
  dplyr::select(date, geocode, temp_media, temp_minima, temp_maxima, precipitacao, umidade)

cat("2. Agregando dados para o nível estadual...\n")

# Dengue: Somar casos por semana
dengue_agg <- dengue_df %>%
  filter(year >= 2017) %>%
  group_by(date) %>%
  summarise(
    casos_dengue = sum(casos, na.rm = TRUE),
    ano = first(year),
    semana_epidemiologica = as.numeric(substr(as.character(first(epiweek)), 5, 6)),
    .groups = "drop"
  )

# População: Somar população por ano
pop_agg <- pop_pe %>%
  group_by(ano) %>%
  summarise(
    populacao = sum(populacao, na.rm = TRUE),
    .groups = "drop"
  )

# Índice P: Média por semana
indexp_agg <- indexp_df %>%
  group_by(date) %>%
  summarise(
    indiceP = mean(indexP, na.rm = TRUE),
    .groups = "drop"
  )

# Clima: Média por semana
climate_agg <- climate_pe %>%
  group_by(date) %>%
  summarise(
    temp_media   = mean(temp_media, na.rm = TRUE),
    temp_minima  = mean(temp_minima, na.rm = TRUE),
    temp_maxima  = mean(temp_maxima, na.rm = TRUE),
    precipitacao = mean(precipitacao, na.rm = TRUE),
    umidade      = mean(umidade, na.rm = TRUE),
    .groups = "drop"
  )

cat("3. Unindo os bancos de dados...\n")
df_pe <- dengue_agg %>%
  left_join(pop_agg, by = "ano") %>%
  left_join(indexp_agg, by = "date") %>%
  left_join(climate_agg, by = "date") %>%
  mutate(estado = "PE") %>%
  arrange(date) %>%
  drop_na() # Remover NAs gerados pelas junções de períodos que não cruzam

# Verificar se população tem valor nulo/negativo
if (any(df_pe$populacao <= 0)) {
  stop("Existem valores nulos ou negativos na população!")
}

cat("4. Criando variáveis de tempo e sazonalidade...\n")
df_pe <- df_pe %>%
  mutate(
    tempo = row_number(),
    # Divisão por 52 garante o ciclo completo anual; se tiver 53 semanas, ficará levemente > 1 mas ciclando corretamente.
    sin_ano = sin(2 * pi * semana_epidemiologica / 52),
    cos_ano = cos(2 * pi * semana_epidemiologica / 52)
  )

# Dividir dados
df_treino <- df_pe %>% filter(ano >= 2017 & ano <= 2022)
df_teste  <- df_pe %>% filter(ano >= 2023 & ano <= 2024)

cat(sprintf("   - Linhas na base final: %d\n", nrow(df_pe)))
cat(sprintf("   - Intervalo de datas: %s a %s\n", min(df_pe$date), max(df_pe$date)))
cat(sprintf("   - Semanas no treino: %d\n", nrow(df_treino)))
cat(sprintf("   - Semanas no teste: %d\n", nrow(df_teste)))

# Imprimir população estadual por ano
cat("\nPopulação Estadual de Pernambuco por Ano:\n")
print(pop_agg %>% filter(ano >= 2017 & ano <= 2024))

# 5. Funções Auxiliares
calcular_mae <- function(observado, predito) {
  mean(abs(observado - predito), na.rm = TRUE)
}

calcular_rmse <- function(observado, predito) {
  sqrt(mean((observado - predito)^2, na.rm = TRUE))
}

ajustar_modelo_contagem <- function(formula, data) {
  modelo <- tryCatch({
    mod <- MASS::glm.nb(formula, data = data)
    list(modelo = mod, familia_usada = "binomial_negativa")
  }, error = function(e) {
    warning(paste("glm.nb falhou para a formula:", deparse(formula), "- Usando Poisson como fallback."))
    mod <- glm(formula, family = poisson, data = data)
    list(modelo = mod, familia_usada = "poisson_fallback")
  })
  return(modelo)
}

avaliar_modelo <- function(nome_modelo, formula, dados_treino, dados_teste) {
  ajuste <- ajustar_modelo_contagem(formula, dados_treino)
  
  # Prevendo no teste. type="response" já considera o offset da população 
  # para retornar a contagem esperada (número de casos previstos).
  predito <- predict(ajuste$modelo, newdata = dados_teste, type = "response")
  observado <- dados_teste$casos_dengue
  
  mae <- calcular_mae(observado, predito)
  rmse <- calcular_rmse(observado, predito)
  
  resultados <- data.frame(
    estado = "PE",
    modelo = nome_modelo,
    variaveis = deparse(formula),
    familia_usada = ajuste$familia_usada,
    offset_usado = "sim_populacao",
    MAE = mae,
    RMSE = rmse,
    stringsAsFactors = FALSE
  )
  
  return(resultados)
}

cat("\n5. Ajustando modelos e calculando previsões (isso pode levar alguns segundos)...\n")

# Definir as fórmulas
formulas <- list(
  "Base" = casos_dengue ~ tempo + sin_ano + cos_ano + offset(log(populacao)),
  "Índice P" = casos_dengue ~ indiceP + tempo + sin_ano + cos_ano + offset(log(populacao)),
  "Temperatura Média" = casos_dengue ~ temp_media + tempo + sin_ano + cos_ano + offset(log(populacao)),
  "Temperatura Mínima" = casos_dengue ~ temp_minima + tempo + sin_ano + cos_ano + offset(log(populacao)),
  "Temperatura Máxima" = casos_dengue ~ temp_maxima + tempo + sin_ano + cos_ano + offset(log(populacao)),
  "Precipitação" = casos_dengue ~ precipitacao + tempo + sin_ano + cos_ano + offset(log(populacao)),
  "Umidade" = casos_dengue ~ umidade + tempo + sin_ano + cos_ano + offset(log(populacao))
)

# Rodar todos os modelos
lista_resultados <- lapply(names(formulas), function(nome) {
  avaliar_modelo(nome, formulas[[nome]], df_treino, df_teste)
})

# Juntar resultados em um data.frame
resultados_finais <- bind_rows(lista_resultados)

# Ordenar por MAE e RMSE
resultados_mae <- resultados_finais %>% arrange(MAE)
resultados_rmse <- resultados_finais %>% arrange(RMSE)

cat("\n6. Salvando tabelas de resultados...\n")
dir_out <- "DLNM MASS + OFFSET/PE DLNM MASS + OFFSET/PREDIÇÃO/"

write.csv(resultados_finais, paste0(dir_out, "resultados_metricas_PE_todas_variaveis_offset.csv"), row.names = FALSE)
write.csv(resultados_mae, paste0(dir_out, "resultados_metricas_PE_ordenado_MAE_offset.csv"), row.names = FALSE)
write.csv(resultados_rmse, paste0(dir_out, "resultados_metricas_PE_ordenado_RMSE_offset.csv"), row.names = FALSE)

cat("\nRANKING POR MAE:\n")
print(resultados_mae %>% dplyr::select(modelo, MAE, RMSE))

cat("\nRANKING POR RMSE:\n")
print(resultados_rmse %>% dplyr::select(modelo, RMSE, MAE))

cat("\n7. Gerando gráficos de comparação...\n")

# Gráfico de MAE
p_mae <- ggplot(resultados_mae, aes(x = reorder(modelo, MAE), y = MAE)) +
  geom_segment(aes(x = reorder(modelo, MAE), xend = reorder(modelo, MAE), y = 0, yend = MAE), color = "gray50") +
  geom_point(color = "blue", size = 4) +
  coord_flip() +
  labs(title = "Comparação de MAE por Modelo - Pernambuco (Teste 2023-2024)",
       subtitle = "Modelos ajustados com Binomial Negativa e offset populacional",
       x = "Modelo", y = "MAE (Menor é Melhor)") +
  theme_minimal()

ggsave(paste0(dir_out, "comparacao_MAE_modelos_PE_offset.png"), plot = p_mae, width = 8, height = 5, bg = "white")

# Gráfico de RMSE
p_rmse <- ggplot(resultados_rmse, aes(x = reorder(modelo, RMSE), y = RMSE)) +
  geom_segment(aes(x = reorder(modelo, RMSE), xend = reorder(modelo, RMSE), y = 0, yend = RMSE), color = "gray50") +
  geom_point(color = "red", size = 4) +
  coord_flip() +
  labs(title = "Comparação de RMSE por Modelo - Pernambuco (Teste 2023-2024)",
       subtitle = "Modelos ajustados com Binomial Negativa e offset populacional",
       x = "Modelo", y = "RMSE (Menor é Melhor)") +
  theme_minimal()

ggsave(paste0(dir_out, "comparacao_RMSE_modelos_PE_offset.png"), plot = p_rmse, width = 8, height = 5, bg = "white")

cat("\nAnálise concluída com sucesso! Resultados salvos na pasta PREDIÇÃO.\n")
