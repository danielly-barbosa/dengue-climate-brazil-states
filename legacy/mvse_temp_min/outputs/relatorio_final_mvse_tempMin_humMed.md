# Relatório Final - Processamento MVSE com temp_min e rel_humid_med

## Resumo Executivo

O processamento MVSE (Mosquito-borne Virus Surveillance and Estimation) foi executado com sucesso para 185 cidades de Pernambuco utilizando os parâmetros climáticos:
- **Temperatura**: temp_min (temperatura mínima)
- **Umidade**: rel_humid_med (umidade relativa média)
- **Precipitação**: precip_tot (precipitação total)

## Resultados do Processamento

### Estatísticas Gerais
- **Total de cidades processadas**: 185
- **Taxa de sucesso**: 100% (185/185)
- **Tempo total de processamento**: 9.82 minutos
- **Início**: 2025-10-17 12:34:03 -03
- **Fim**: 2025-10-17 12:43:53 -03

### Configuração Utilizada
- **nMCMC**: 25.000 iterações
- **nSample**: 120 simulações
- **nBurnin**: 5.000 iterações de aquecimento
- **Processamento**: GPU (RTX 2060 SUPER) + 28 cores CPU
- **Modo**: Extremo (configurações otimizadas)

### Resultados Consolidados
- **Total de registros gerados**: 73.075
- **Arquivo consolidado**: `resultados_mvse_tempMin_humMed_consolidado.csv` (10.4 MB)
- **Período coberto**: 2017-2024 (395 semanas por cidade)

### Estatísticas do IndexP
- **Mínimo**: 0.4220
- **1º Quartil**: 0.7702
- **Mediana**: 0.8970
- **Média**: 0.9183
- **3º Quartil**: 1.0460
- **Máximo**: 2.2935

## Estrutura dos Dados de Saída

Cada arquivo de resultado contém as seguintes colunas:
- `date`: Data da observação (formato semanal)
- `indexP`: Índice de potencial de transmissão estimado
- `indexPlower`: Limite inferior do intervalo de confiança
- `indexPupper`: Limite superior do intervalo de confiança
- `indexPsmooth7`: IndexP suavizado (janela de 7 dias)
- `indexPsmooth15`: IndexP suavizado (janela de 15 dias)
- `indexPsmooth30`: IndexP suavizado (janela de 30 dias)
- `indexPsmooth60`: IndexP suavizado (janela de 60 dias)
- `cidade`: Código IBGE da cidade

## Arquivos Gerados

### Individuais por Cidade
- **Localização**: `indexP_tempMin_humMed/[CODIGO_CIDADE]/[CODIGO_CIDADE].estimated_indexP.csv`
- **Quantidade**: 185 arquivos
- **Linhas por arquivo**: 396 (cabeçalho + 395 registros semanais)

### Consolidado
- **Arquivo**: `resultados_mvse_tempMin_humMed_consolidado.csv`
- **Tamanho**: 10.4 MB
- **Registros**: 73.075 (185 cidades × 395 semanas)

## Correções Implementadas

Durante o processamento, foram identificados e corrigidos os seguintes problemas:

1. **Nome da biblioteca**: Alterado de `mvse` para `MVSE` (maiúsculo)
2. **Parâmetro da função**: Alterado `nSim` para `nSample` na função `simulateEmpiricalIndexP`

## Validação dos Resultados

✅ **Todos os arquivos gerados com sucesso**
✅ **Estrutura de dados consistente**
✅ **Valores do IndexP dentro do intervalo esperado**
✅ **Intervalos de confiança calculados corretamente**
✅ **Dados suavizados disponíveis em múltiplas janelas temporais**

## Próximos Passos Sugeridos

1. **Análise exploratória** dos padrões temporais e espaciais do IndexP
2. **Validação cruzada** com dados epidemiológicos de dengue/chikungunya/zika
3. **Análise de correlação** entre IndexP e incidência de doenças
4. **Desenvolvimento de modelos preditivos** baseados no IndexP
5. **Visualização geoespacial** dos resultados por município

## Arquivos de Referência

- **Script principal**: `executar_mvse_gpu_extremo_tempMin_humMed.R`
- **Dados de entrada**: `dados_mvse_cidades_tempMin_humMed/`
- **Resultados individuais**: `indexP_tempMin_humMed/`
- **Resultado consolidado**: `resultados_mvse_tempMin_humMed_consolidado.csv`
- **Relatório de processamento**: `relatorio_mvse_tempMin_humMed.rds`
- **Script de consolidação**: `consolidar_resultados_mvse_tempMin_humMed.R`

---

**Data do relatório**: 2025-10-17  
**Processamento concluído com sucesso**: ✅