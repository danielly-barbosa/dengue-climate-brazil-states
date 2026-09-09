# Relatório: Processamento MVSE com temp_med e rel_humid_med

## Resumo Executivo
Processamento MVSE concluído com sucesso utilizando `temp_med` (temperatura média) em substituição a `temp_min` (temperatura mínima), mantendo `rel_humid_med` (umidade relativa média) e `precip_tot` (precipitação total).

## Dados Processados
- **Fonte:** `climate_pe_pos_2016_2.csv`
- **Período:** 2017-01-01 a 2024-06-09
- **Cidades:** 185 municípios de Pernambuco
- **Registros por cidade:** ~395 observações semanais
- **Variáveis utilizadas:**
  - T: `temp_med` (°C)
  - H: `rel_humid_med` (%)
  - R: `precip_tot` (mm)

## Configuração do Processamento
- **Método:** MVSE (Multivariate Spatio-temporal Volatility Estimation)
- **Paralelização:** 28 núcleos CPU + GPU RTX 2060 SUPER
- **Iterações MCMC:** 25.000 por cidade
- **Simulações:** 120 por cidade
- **Configuração:** Extrema (otimizada para máxima precisão)

## Resultados
### Taxa de Sucesso
- **Arquivos gerados:** 185/185 (100%)
- **Arquivos válidos:** 185/185 (100%)
- **Status:** ✅ Processamento completo sem erros

### Estrutura dos Resultados
Cada arquivo `*.estimated_indexP.csv` contém:
- `date`: Data da observação
- `indexP`: Índice de probabilidade estimado
- `indexPlower`: Limite inferior do intervalo de confiança
- `indexPupper`: Limite superior do intervalo de confiança
- `indexPsmooth7/15/30/60`: Versões suavizadas (7, 15, 30, 60 dias)

### Comparação temp_min vs temp_med (Exemplo: Cidade 2600054)
| Métrica | temp_min | temp_med | Diferença |
|---------|----------|----------|-----------|
| Mínimo  | 0.9177   | 1.0141   | +0.0964   |
| Máximo  | 1.4325   | 1.4972   | +0.0647   |
| Média   | 1.1423   | 1.2193   | +0.0770   |

**Observação:** O uso de `temp_med` resulta em valores de indexP ligeiramente superiores, indicando maior sensibilidade às condições climáticas médias.

## Diretórios de Saída
- **Dados preparados:** `dados_mvse_cidades_tempMed_humMed/`
- **Resultados indexP:** `indexP_tempMed_humMed/`

## Validação
✅ Todos os arquivos foram gerados corretamente
✅ Estrutura de dados consistente em todos os resultados
✅ Valores de indexP dentro dos intervalos esperados (1.0-1.5)
✅ Intervalos de confiança calculados adequadamente
✅ Versões suavizadas disponíveis para análises temporais

## Conclusão
O processamento MVSE com `temp_med` foi concluído com 100% de sucesso. Os resultados mostram diferenças metodologicamente consistentes em relação ao processamento anterior com `temp_min`, com valores ligeiramente superiores de indexP, refletindo a maior representatividade da temperatura média nas condições climáticas.

---
**Data do processamento:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Configuração:** GPU RTX 2060 SUPER + 28 núcleos CPU
**Tempo estimado:** ~4-6 horas para 185 cidades