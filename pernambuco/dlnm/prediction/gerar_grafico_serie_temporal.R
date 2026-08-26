# ==============================================================================
# Gráfico Final - Série Temporal Completa (Treino + Teste) para Pernambuco
# Modelos: Base, Índice P, Temp. Média, Temp. Mínima, Temp. Máxima, Precipitação e Umidade
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(lubridate)
  library(MASS)
  library(ggplot2)
  library(tidyr)
  library(RColorBrewer)
})

cat("1. Carregando e processando os dados...\n")

# Caminhos dos arquivos
path_dengue  <- "DLNM MASS + OFFSET/PE DLNM MASS + OFFSET/dados/dengue_pe_2015_2024.csv"
path_indexp  <- "DLNM MASS + OFFSET/PE DLNM MASS + OFFSET/dados/mvse_pernambuco_consolidado.csv"
path_climate <- "DLNM MASS + OFFSET/PE DLNM MASS + OFFSET/dados/climate_pe_pos_2016_2_backup.csv"
path_pop     <- "DLNM MASS + OFFSET/PE DLNM MASS + OFFSET/dados/br_ibge_populacao_municipio_filtrado.csv"

# Carregar dados
dengue_df  <- read.csv(path_dengue)
indexp_df  <- read.csv(path_indexp)
climate_df <- read.csv(path_climate)
pop_df     <- read.csv(path_pop)

# Formatar datas
dengue_df$date  <- as.Date(dengue_df$date)
indexp_df$date  <- as.Date(indexp_df$date)
climate_df$date <- as.Date(climate_df$date)

# Prepara População
pop_pe <- pop_df %>% filter(sigla_uf == "PE") %>% rename(geocode = id_municipio)
pop_agg <- pop_pe %>% group_by(ano) %>% summarise(populacao = sum(populacao, na.rm = TRUE), .groups = "drop")

# Prepara Clima
climate_pe <- climate_df %>%
  rename(temp_media = temp_med, temp_minima = temp_min, temp_maxima = temp_max, precipitacao = precip_tot, umidade = rel_humid_med) %>%
  dplyr::select(date, geocode, temp_media, temp_minima, temp_maxima, precipitacao, umidade)
climate_agg <- climate_pe %>% 
  group_by(date) %>% 
  summarise(
    temp_media = mean(temp_media, na.rm = TRUE),
    temp_minima = mean(temp_minima, na.rm = TRUE),
    temp_maxima = mean(temp_maxima, na.rm = TRUE),
    precipitacao = mean(precipitacao, na.rm = TRUE),
    umidade = mean(umidade, na.rm = TRUE),
    .groups = "drop"
  )

# Prepara Índice P
indexp_agg <- indexp_df %>% group_by(date) %>% summarise(indiceP = mean(indexP, na.rm = TRUE), .groups = "drop")

# Prepara Dengue
dengue_agg <- dengue_df %>%
  filter(year >= 2017) %>%
  group_by(date) %>%
  summarise(
    casos_dengue = sum(casos, na.rm = TRUE),
    ano = first(year),
    semana_epidemiologica = as.numeric(substr(as.character(first(epiweek)), 5, 6)),
    .groups = "drop"
  )

# Unir tudo
df_pe <- dengue_agg %>%
  left_join(pop_agg, by = "ano") %>%
  left_join(indexp_agg, by = "date") %>%
  left_join(climate_agg, by = "date") %>%
  arrange(date) %>%
  drop_na() %>%
  mutate(
    tempo = row_number(),
    sin_ano = sin(2 * pi * semana_epidemiologica / 52),
    cos_ano = cos(2 * pi * semana_epidemiologica / 52)
  )

# Divisão
df_treino <- df_pe %>% filter(ano >= 2017 & ano <= 2022)
df_teste  <- df_pe %>% filter(ano >= 2023 & ano <= 2024)

cat("2. Ajustando todos os modelos (isso pode levar alguns segundos)...\n")

# Fórmulas
form_base     <- casos_dengue ~ tempo + sin_ano + cos_ano + offset(log(populacao))
form_indiceP  <- casos_dengue ~ indiceP + tempo + sin_ano + cos_ano + offset(log(populacao))
form_tmed     <- casos_dengue ~ temp_media + tempo + sin_ano + cos_ano + offset(log(populacao))
form_tmin     <- casos_dengue ~ temp_minima + tempo + sin_ano + cos_ano + offset(log(populacao))
form_tmax     <- casos_dengue ~ temp_maxima + tempo + sin_ano + cos_ano + offset(log(populacao))
form_prec     <- casos_dengue ~ precipitacao + tempo + sin_ano + cos_ano + offset(log(populacao))
form_umid     <- casos_dengue ~ umidade + tempo + sin_ano + cos_ano + offset(log(populacao))

# Modelos
mod_base     <- MASS::glm.nb(form_base, data = df_treino)
mod_indiceP  <- MASS::glm.nb(form_indiceP, data = df_treino)
mod_tmed     <- MASS::glm.nb(form_tmed, data = df_treino)
mod_tmin     <- MASS::glm.nb(form_tmin, data = df_treino)
mod_tmax     <- MASS::glm.nb(form_tmax, data = df_treino)
mod_prec     <- MASS::glm.nb(form_prec, data = df_treino)
mod_umid     <- MASS::glm.nb(form_umid, data = df_treino)

cat("3. Extraindo predições (Fitted no treino, Predicted no teste)...\n")

# Juntar treino e teste
df_pe$Pred_Base     <- c(fitted(mod_base), predict(mod_base, newdata = df_teste, type = "response"))
df_pe$Pred_IndiceP  <- c(fitted(mod_indiceP), predict(mod_indiceP, newdata = df_teste, type = "response"))
df_pe$Pred_TempMed  <- c(fitted(mod_tmed), predict(mod_tmed, newdata = df_teste, type = "response"))
df_pe$Pred_TempMin  <- c(fitted(mod_tmin), predict(mod_tmin, newdata = df_teste, type = "response"))
df_pe$Pred_TempMax  <- c(fitted(mod_tmax), predict(mod_tmax, newdata = df_teste, type = "response"))
df_pe$Pred_Precip   <- c(fitted(mod_prec), predict(mod_prec, newdata = df_teste, type = "response"))
df_pe$Pred_Umidade  <- c(fitted(mod_umid), predict(mod_umid, newdata = df_teste, type = "response"))

cat("4. Gerando o gráfico com todos os modelos...\n")

# Pivotar para formato longo
df_long <- df_pe %>%
  dplyr::select(date, casos_dengue, Pred_Base, Pred_IndiceP, Pred_TempMed, Pred_TempMin, Pred_TempMax, Pred_Precip, Pred_Umidade) %>%
  pivot_longer(
    cols = starts_with("Pred_"),
    names_to = "Modelo",
    values_to = "Predito"
  )

# Ajustar nomes para legenda
df_long$Modelo <- recode(df_long$Modelo,
                         "Pred_Base" = "Modelo Base",
                         "Pred_IndiceP" = "Índice P",
                         "Pred_TempMed" = "Temp. Média",
                         "Pred_TempMin" = "Temp. Mínima",
                         "Pred_TempMax" = "Temp. Máxima",
                         "Pred_Precip" = "Precipitação",
                         "Pred_Umidade" = "Umidade")

# Reordenar níveis da legenda (Destacando Base e Índice P)
niveis_modelos <- c("Modelo Base", "Índice P", "Temp. Média", "Temp. Mínima", "Temp. Máxima", "Precipitação", "Umidade")
df_long$Modelo <- factor(df_long$Modelo, levels = niveis_modelos)

# Definir data de corte
data_corte <- as.Date("2023-01-01")

# Definir paleta de cores (Base = Preto, Índice P = Vermelho, Clima = Tons diversos)
cores_modelos <- c("Modelo Base" = "black", 
                   "Índice P" = "#e31a1c", 
                   "Temp. Média" = "#1f78b4", 
                   "Temp. Mínima" = "#a6cee3", 
                   "Temp. Máxima" = "#33a02c", 
                   "Precipitação" = "#ff7f00", 
                   "Umidade" = "#6a3d9a")

# Tipos de linha (destacar Índice P como linha sólida, os demais tracejados/pontilhados para diferenciar)
linhas_modelos <- c("Modelo Base" = "dotted", 
                    "Índice P" = "solid", 
                    "Temp. Média" = "dashed", 
                    "Temp. Mínima" = "twodash", 
                    "Temp. Máxima" = "longdash", 
                    "Precipitação" = "dotdash", 
                    "Umidade" = "dashed")

p_final <- ggplot(df_long, aes(x = date)) +
  # Observado (Fundo espesso cinza claro)
  geom_line(aes(y = casos_dengue), color = "gray75", linewidth = 1.5, alpha = 0.8) +
  
  # Predições
  geom_line(aes(y = Predito, color = Modelo, linetype = Modelo), linewidth = 0.8, alpha = 0.85) +
  
  # Linha vertical separando Treino/Teste
  geom_vline(xintercept = as.numeric(data_corte), linetype = "dashed", color = "black", linewidth = 1) +
  
  # Anotações
  annotate("text", x = as.Date("2020-01-01"), y = max(df_pe$casos_dengue)*0.95, label = "TREINAMENTO (2017-2022)", size = 5, fontface = "bold", color = "black") +
  annotate("text", x = as.Date("2023-09-01"), y = max(df_pe$casos_dengue)*0.95, label = "TESTE (2023-2024)", size = 5, fontface = "bold", color = "black") +
  
  # Escalas
  scale_color_manual(values = cores_modelos) +
  scale_linetype_manual(values = linhas_modelos) +
  
  # Títulos
  labs(
    title = "Série Temporal de Dengue em Pernambuco: Todos os Modelos Isolados",
    subtitle = "Comparação dos valores ajustados (Treinamento) e previsões (Teste) para todas as variáveis",
    x = "Ano",
    y = "Número de Casos",
    color = "Modelos Ajustados/Previstos",
    linetype = "Modelos Ajustados/Previstos"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold"),
    panel.grid.minor = element_blank()
  ) +
  guides(color = guide_legend(nrow = 2, byrow = TRUE))

dir_out <- "DLNM MASS + OFFSET/PE DLNM MASS + OFFSET/PREDIÇÃO/"
arquivo_grafico <- paste0(dir_out, "serie_temporal_todas_variaveis_PE_offset.png")

ggsave(arquivo_grafico, plot = p_final, width = 16, height = 8, bg = "white", dpi = 300)

cat(sprintf("Gráfico salvo com sucesso em: %s\n", arquivo_grafico))
