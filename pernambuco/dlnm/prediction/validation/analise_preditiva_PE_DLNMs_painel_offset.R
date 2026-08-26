# ==============================================================================
# Validação Preditiva DLNM - Pernambuco (Treino: 2017-2022 | Teste: 2023-2024)
# Modelos avaliados no painel municipal e agregados para estado na avaliação.
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(lubridate)
  library(dlnm)
  library(splines)
  library(MASS)
  library(ggplot2)
})

# Caminhos
path_dengue  <- "../../data/dengue_pe_2015_2024.csv"
path_indexp  <- "../../data/mvse_pernambuco_consolidado.csv"
path_climate <- "../../data/climate_pe_pos_2016_2_backup.csv"
path_pop     <- "../../data/br_ibge_populacao_municipio_filtrado.csv"
dir_out      <- "../../prediction/validation/"

# 1. FUNÇÕES REAPROVEITADAS/ADAPTADAS
normalize_geocode <- function(x) {
  x <- as.character(x)
  ifelse(nchar(x) == 7, substr(x, 1, 6), x)
}

# 2. CARREGAR E PREPARAR DADOS
cat("Carregando os dados...\n")
dengue  <- read.csv(path_dengue, stringsAsFactors = FALSE)
indexp  <- read.csv(path_indexp, stringsAsFactors = FALSE)
climate <- read.csv(path_climate, stringsAsFactors = FALSE)
pop     <- read.csv(path_pop, stringsAsFactors = FALSE)

# Normalizar geocodes e datas
dengue$geocode  <- normalize_geocode(dengue$geocode)
indexp$geocode  <- normalize_geocode(indexp$geocode)
climate$geocode <- normalize_geocode(climate$geocode)
pop$id_municipio<- normalize_geocode(pop$id_municipio)

dengue$date  <- as.Date(dengue$date)
indexp$date  <- as.Date(indexp$date)
climate$date <- as.Date(climate$date)

# Filtrar população de PE e renomear
pop_pe <- pop %>% 
  filter(sigla_uf == "PE") %>%
  rename(geocode = id_municipio, Pop_i = populacao, year = ano) %>%
  dplyr::select(geocode, year, Pop_i)

# Preparar clima
climate_pe <- climate %>%
  rename(temp_med = temp_med, temp_min = temp_min, temp_max = temp_max, 
         precip_tot = precip_tot, rel_humid_med = rel_humid_med) %>%
  dplyr::select(date, geocode, temp_med, temp_min, temp_max, precip_tot, rel_humid_med)

# Preparar Índice P
indexp_pe <- indexp %>% dplyr::select(date, geocode, indexP)

# Remover duplicatas para evitar many-to-many relationship
climate_pe <- climate_pe %>% distinct(geocode, date, .keep_all = TRUE)
indexp_pe <- indexp_pe %>% distinct(geocode, date, .keep_all = TRUE)

# Filtrar Dengue para >= 2017 e preparar painel
cat("Unindo os bancos no nível municipal-semana...\n")
dados_painel <- dengue %>%
  filter(year >= 2017) %>%
  dplyr::select(date, geocode, year, epiweek, casos) %>%
  left_join(pop_pe, by = c("geocode", "year")) %>%
  left_join(indexp_pe, by = c("geocode", "date")) %>%
  left_join(climate_pe, by = c("geocode", "date")) %>%
  arrange(geocode, date)

# Remover NAs, criar mês, time e offset
dados_painel <- dados_painel %>%
  drop_na() %>%
  group_by(geocode) %>%
  arrange(date) %>%
  mutate(
    time = row_number(),
    mes = month(date),
    offset = log(Pop_i / 100000)
  ) %>%
  ungroup()

# Verificações de Offset e NAs
if(any(is.na(dados_painel$offset) | is.infinite(dados_painel$offset))) {
  stop("Erro: População gerou offset ausente ou infinito!")
}

# 3. DIVISÃO TREINO/TESTE
# IMPORTANTE: A construção da crossbasis exige a série contínua, mas o ajuste será apenas no treino!
dados_treino <- dados_painel %>% filter(year >= 2017 & year <= 2022)
dados_teste  <- dados_painel %>% filter(year >= 2023 & year <= 2024)

# Infos no console
cat("\n=== INFORMAÇÕES DA BASE DE PAINEL ===\n")
cat("Total de linhas:        ", nrow(dados_painel), "\n")
cat("Linhas no Treino:       ", nrow(dados_treino), "\n")
cat("Linhas no Teste:        ", nrow(dados_teste), "\n")
cat("Municípios:             ", length(unique(dados_painel$geocode)), "\n")
cat("Datas Treino:           ", as.character(min(dados_treino$date)), " a ", as.character(max(dados_treino$date)), "\n")
cat("Datas Teste:            ", as.character(min(dados_teste$date)), " a ", as.character(max(dados_teste$date)), "\n")
cat("=====================================\n\n")

# 4. PREPARAR CROSSBASIS NA SÉRIE COMPLETA (Para não quebrar o lag no limite treino/teste)
cat("Construindo matrizes crossbasis...\n")
# O DLNM será gerado na base completa para manter o lag, mas as regressões vão usar `subset = (year <= 2022)` ou fit na `dados_treino`.
# A melhor forma é gerar os cb e atachar ao data.frame completo para usar na função predict com facilidade, ou usar as matrizes separadas.

cb_indexP       <- crossbasis(dados_painel$indexP, lag = 12, argvar = list(fun = "ns", df = 3), arglag = list(fun = "ns", df = 3), group = dados_painel$geocode)
cb_temp_med     <- crossbasis(dados_painel$temp_med, lag = 12, argvar = list(fun = "ns", df = 3), arglag = list(fun = "ns", df = 3), group = dados_painel$geocode)
cb_precip_tot   <- crossbasis(dados_painel$precip_tot, lag = 12, argvar = list(fun = "ns", df = 3), arglag = list(fun = "ns", df = 3), group = dados_painel$geocode)
cb_rel_humid_med<- crossbasis(dados_painel$rel_humid_med, lag = 12, argvar = list(fun = "ns", df = 3), arglag = list(fun = "ns", df = 3), group = dados_painel$geocode)

# 5. AJUSTE DOS MODELOS (Apenas no Treino)
cat("Ajustando modelos no Treino (2017-2022). Isso pode demorar bastante...\n")

# Para evitar convergência lenta/problemática de glm.nb em painéis tão grandes:
# Se glm.nb falhar, o fallback de poisson já é útil, mas o glm.nb nativo com MASS 
# costuma ficar preso na estimativa de theta. Vamos simplificar o tempo para 3df.
df_time <- 3 * length(unique(dados_treino$year)) 

# Vetor para indicar o subset de treino
idx_treino <- dados_painel$year <= 2022

# Para o painel estadual com quase 60.000 linhas, usamos mgcv::gam para modelagem aditiva de grande porte com familia poisson. 
# glm ou glm.nb ficam lentos na inversão da matriz.

# Para glm poisson, usando speedglm pode acelerar:
# mas como o objetivo é rapidez e garantia de não-travamento:
ajustar_nb_com_fallback <- function(formula, data) {
  cat("   Ajustando...\n")
  mod <- glm(formula, family = poisson, data = data, control = glm.control(maxit = 20, epsilon = 1e-4, trace = FALSE))
  list(modelo = mod, familia = "poisson")
}

# 1. Base
form_base <- casos ~ ns(time, df = df_time) + factor(mes) + factor(geocode) + offset(offset)
# ajuste_base <- ajustar_nb_com_fallback(form_base, dados_treino)

# 2. Índice P
form_ip <- casos ~ cb_indexP[idx_treino,] + ns(time, df = df_time) + factor(mes) + factor(geocode) + offset(offset)
# ajuste_ip <- ajustar_nb_com_fallback(form_ip, dados_treino)

# 3. Temp Média
form_tm <- casos ~ cb_temp_med[idx_treino,] + ns(time, df = df_time) + factor(mes) + factor(geocode) + offset(offset)
# ajuste_tm <- ajustar_nb_com_fallback(form_tm, dados_treino)

# 4. Precipitação
form_pr <- casos ~ cb_precip_tot[idx_treino,] + ns(time, df = df_time) + factor(mes) + factor(geocode) + offset(offset)
# ajuste_pr <- ajustar_nb_com_fallback(form_pr, dados_treino)

# 5. Umidade
form_um <- casos ~ cb_rel_humid_med[idx_treino,] + ns(time, df = df_time) + factor(mes) + factor(geocode) + offset(offset)
# ajuste_um <- ajustar_nb_com_fallback(form_um, dados_treino)

# 6. PREDIÇÃO E AVALIAÇÃO (Agregada Estadual-Semanal)
cat("Realizando predições no Teste (2023-2024) e agregando estado-semana...\n")

# Para evitar o erro de variável 'ns(time)' com tamanhos diferentes durante o predict
# quando se usa o pacote splines, é mais seguro rodar o predict na base completa (ou passar o tempo original).
# Outra forma é gerar as spline basis fora da formula ou usar um hack no predict.

# Hack seguro para ns() no predict com modelos fitados em subsets
# Ao invés de usar subset, é mais fácil re-criar a base de treino com as matrizes CB fatiadas
# Mas como já treinamos, vamos criar a função custom predict para lidar com o problema do df.

# Como o predict() com splines treinadas em subset pode bugar:
# A melhor forma garantida para dlnm em crossbasis é refitar na base completa 
# MAS passando pesos = 0 para os anos de teste!
pesos <- ifelse(dados_painel$year <= 2022, 1, 0)

ajustar_nb_com_peso <- function(formula, data, pesos) {
  cat("   Ajustando...\n")
  mod <- glm(formula, family = poisson, data = data, weights = pesos, control = glm.control(maxit = 25, epsilon = 1e-5, trace = FALSE))
  list(modelo = mod, familia = "poisson")
}

# Refazendo o ajuste com pesos
ajuste_base <- ajustar_nb_com_peso(casos ~ ns(time, df = df_time) + factor(mes) + factor(geocode) + offset(offset), dados_painel, pesos)
ajuste_ip   <- ajustar_nb_com_peso(casos ~ cb_indexP + ns(time, df = df_time) + factor(mes) + factor(geocode) + offset(offset), dados_painel, pesos)
ajuste_tm   <- ajustar_nb_com_peso(casos ~ cb_temp_med + ns(time, df = df_time) + factor(mes) + factor(geocode) + offset(offset), dados_painel, pesos)
ajuste_pr   <- ajustar_nb_com_peso(casos ~ cb_precip_tot + ns(time, df = df_time) + factor(mes) + factor(geocode) + offset(offset), dados_painel, pesos)
ajuste_um   <- ajustar_nb_com_peso(casos ~ cb_rel_humid_med + ns(time, df = df_time) + factor(mes) + factor(geocode) + offset(offset), dados_painel, pesos)

# O predict com pesos = 0 gera valores, mas para ser rigoroso e prever de fato na base de teste, 
# extraímos diretamente com type="response" já que o predict(mod) em glm ignora dados novos por padrão se newdata não for fornecido.
# Como nós usamos dados_painel no fit, predict() sem newdata vai gerar os fits originais.
# Vamos usar o hack de newdata = dados_painel e ignorar o warning do splines se ocorrer, ou
# extrair o vetor fitted() diretamente

dados_painel$pred_base <- predict(ajuste_base$modelo, newdata = dados_painel, type = "response")
dados_painel$pred_ip   <- predict(ajuste_ip$modelo, newdata = dados_painel, type = "response")
dados_painel$pred_tm   <- predict(ajuste_tm$modelo, newdata = dados_painel, type = "response")
dados_painel$pred_pr   <- predict(ajuste_pr$modelo, newdata = dados_painel, type = "response")
dados_painel$pred_um   <- predict(ajuste_um$modelo, newdata = dados_painel, type = "response")

# Corrigir NAs se glm introduziu por causa de pesos
dados_painel <- dados_painel %>% mutate(
  pred_base = ifelse(is.na(pred_base), 0, pred_base),
  pred_ip = ifelse(is.na(pred_ip), 0, pred_ip),
  pred_tm = ifelse(is.na(pred_tm), 0, pred_tm),
  pred_pr = ifelse(is.na(pred_pr), 0, pred_pr),
  pred_um = ifelse(is.na(pred_um), 0, pred_um)
)

# Agregar para estado-semana apenas no TESTE
aval_estado <- dados_painel %>%
  filter(!idx_treino) %>% # Filtra 2023-2024
  group_by(date) %>%
  summarise(
    casos_obs  = sum(casos, na.rm = TRUE),
    pred_base  = sum(pred_base, na.rm = TRUE),
    pred_ip    = sum(pred_ip, na.rm = TRUE),
    pred_tm    = sum(pred_tm, na.rm = TRUE),
    pred_pr    = sum(pred_pr, na.rm = TRUE),
    pred_um    = sum(pred_um, na.rm = TRUE),
    .groups = "drop"
  )

# Calcular MAE e RMSE
calcular_mae <- function(obs, pred) mean(abs(obs - pred))
calcular_rmse <- function(obs, pred) sqrt(mean((obs - pred)^2))

resultados <- data.frame(
  estado = "PE",
  modelo = c("Base", "DLNM Índice P", "DLNM Temp Média", "DLNM Precipitação", "DLNM Umidade"),
  tipo = c("Base", "Sintético", "Clima", "Clima", "Clima"),
  exposicao = c("Nenhuma", "indexP", "temp_med", "precip_tot", "rel_humid_med"),
  familia_usada = c(ajuste_base$familia, ajuste_ip$familia, ajuste_tm$familia, ajuste_pr$familia, ajuste_um$familia),
  lag_max = c(NA, 12, 12, 12, 12),
  var_df = c(NA, 3, 3, 3, 3),
  lag_df = c(NA, 3, 3, 3, 3),
  offset_usado = "log(Pop_i/100k)",
  MAE_estado = c(
    calcular_mae(aval_estado$casos_obs, aval_estado$pred_base),
    calcular_mae(aval_estado$casos_obs, aval_estado$pred_ip),
    calcular_mae(aval_estado$casos_obs, aval_estado$pred_tm),
    calcular_mae(aval_estado$casos_obs, aval_estado$pred_pr),
    calcular_mae(aval_estado$casos_obs, aval_estado$pred_um)
  ),
  RMSE_estado = c(
    calcular_rmse(aval_estado$casos_obs, aval_estado$pred_base),
    calcular_rmse(aval_estado$casos_obs, aval_estado$pred_ip),
    calcular_rmse(aval_estado$casos_obs, aval_estado$pred_tm),
    calcular_rmse(aval_estado$casos_obs, aval_estado$pred_pr),
    calcular_rmse(aval_estado$casos_obs, aval_estado$pred_um)
  ),
  stringsAsFactors = FALSE
)

# Rankings
rank_mae  <- resultados %>% arrange(MAE_estado)
rank_rmse <- resultados %>% arrange(RMSE_estado)

# Salvar tabelas
write.csv(resultados, paste0(dir_out, "resultados_metricas_PE_DLNMs_predicao_painel_offset.csv"), row.names = FALSE)
write.csv(rank_mae, paste0(dir_out, "ranking_MAE_estado_PE_DLNMs_predicao_painel_offset.csv"), row.names = FALSE)
write.csv(rank_rmse, paste0(dir_out, "ranking_RMSE_estado_PE_DLNMs_predicao_painel_offset.csv"), row.names = FALSE)

cat("\nRANKING POR MAE ESTADUAL:\n")
print(rank_mae %>% dplyr::select(modelo, MAE_estado, RMSE_estado))

cat("\nRANKING POR RMSE ESTADUAL:\n")
print(rank_rmse %>% dplyr::select(modelo, RMSE_estado, MAE_estado))

# 7. GRÁFICOS
cat("\nGerando gráficos...\n")

# Gráfico MAE
p_mae <- ggplot(rank_mae, aes(x = reorder(modelo, MAE_estado), y = MAE_estado, fill = tipo)) +
  geom_bar(stat = "identity", width = 0.6) +
  coord_flip() +
  labs(title = "MAE Estadual (Pernambuco - Teste 2023-2024)", x = "Modelo", y = "MAE_estado") +
  theme_minimal() +
  scale_fill_brewer(palette = "Set1")
ggsave(paste0(dir_out, "comparacao_MAE_estado_PE_DLNMs_predicao_painel_offset.png"), plot = p_mae, width = 8, height = 5, bg = "white")

# Gráfico RMSE
p_rmse <- ggplot(rank_rmse, aes(x = reorder(modelo, RMSE_estado), y = RMSE_estado, fill = tipo)) +
  geom_bar(stat = "identity", width = 0.6) +
  coord_flip() +
  labs(title = "RMSE Estadual (Pernambuco - Teste 2023-2024)", x = "Modelo", y = "RMSE_estado") +
  theme_minimal() +
  scale_fill_brewer(palette = "Set1")
ggsave(paste0(dir_out, "comparacao_RMSE_estado_PE_DLNMs_predicao_painel_offset.png"), plot = p_rmse, width = 8, height = 5, bg = "white")

# Gráfico de Linha (Observado vs Predito) - Base, IP, e o Melhor Clima (por RMSE)
melhor_clima <- rank_rmse %>% filter(tipo == "Clima") %>% slice(1) %>% pull(modelo)
nome_col_clima <- case_when(
  melhor_clima == "DLNM Temp Média" ~ "pred_tm",
  melhor_clima == "DLNM Precipitação" ~ "pred_pr",
  melhor_clima == "DLNM Umidade" ~ "pred_um"
)

df_graf_linha <- aval_estado %>%
  dplyr::select(date, casos_obs, pred_base, pred_ip, all_of(nome_col_clima)) %>%
  pivot_longer(cols = -date, names_to = "Variavel", values_to = "Casos") %>%
  mutate(Variavel = recode(Variavel, 
                           "casos_obs" = "Observado", 
                           "pred_base" = "Modelo Base", 
                           "pred_ip" = "DLNM Índice P", 
                           !!nome_col_clima := melhor_clima))

p_linha <- ggplot(df_graf_linha, aes(x = date, y = Casos, color = Variavel, linetype = Variavel)) +
  geom_line(linewidth = 1.2) +
  scale_color_manual(values = c("Observado" = "gray50", "Modelo Base" = "black", "DLNM Índice P" = "red", setNames("blue", melhor_clima))) +
  scale_linetype_manual(values = c("Observado" = "solid", "Modelo Base" = "dotted", "DLNM Índice P" = "solid", setNames("dashed", melhor_clima))) +
  labs(title = "Casos Observados vs Preditos - Nível Estadual (PE 2023-2024)", subtitle = "Comparação dos melhores modelos DLNM", x = "Data", y = "Casos de Dengue") +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave(paste0(dir_out, "observado_vs_predito_estado_PE_DLNMs_teste_painel_offset.png"), plot = p_linha, width = 12, height = 6, bg = "white")

# 8. INTERPRETAÇÃO
cat("\n=== INTERPRETAÇÃO DOS RESULTADOS ===\n")
base_mae  <- resultados$MAE_estado[resultados$modelo == "Base"]
base_rmse <- resultados$RMSE_estado[resultados$modelo == "Base"]
ip_mae    <- resultados$MAE_estado[resultados$modelo == "DLNM Índice P"]
ip_rmse   <- resultados$RMSE_estado[resultados$modelo == "DLNM Índice P"]
clima_min_rmse <- min(rank_rmse$RMSE_estado[rank_rmse$tipo == "Clima"])

cat("1. O DLNM com Índice P melhorou em relação ao modelo base?\n")
if (ip_rmse < base_rmse & ip_mae < base_mae) {
  cat("   Sim. O Índice P superou o modelo base tanto em MAE quanto em RMSE.\n")
} else if (ip_rmse < base_rmse) {
  cat("   Parcialmente. O Índice P obteve RMSE menor (penaliza menos erros grandes), mas MAE maior.\n")
} else {
  cat("   Não. O modelo base teve desempenho preditivo superior ao Índice P nas métricas gerais.\n")
}

cat("2. O DLNM com Índice P foi competitivo em relação aos climáticos?\n")
if (ip_rmse < clima_min_rmse) {
  cat("   Sim. O Índice P obteve o MENOR RMSE entre todos os modelos DLNM, incluindo os climáticos isolados.\n")
} else {
  cat(sprintf("   Misto/Inferior. O melhor modelo climático (%s) teve um RMSE de %.2f, melhor que o Índice P (%.2f).\n", 
              melhor_clima, clima_min_rmse, ip_rmse))
}
cat("====================================\n")
