# Relatorio QC - PE DLNM MASS + OFFSET

## Solucao adotada para painel e lag
- Solucao implementada: `crossbasis(..., group = geocode)` em todos os modelos (individuais e combinados).
- Justificativa metodologica: no `dlnm`, `group` define series independentes no painel e evita uso de observacoes de outro municipio na memoria de lag.
- Teste explicito executado: comparacao de `crossbasis` com e sem `group` nas linhas de fronteira entre municipios.
- Evidencia agregada: 15 de 15 verificacoes marcaram bloqueio de lag crossing (`lag_crossing_blocked_by_group = 1`).

## Integridade do merge com populacao
- n antes/depois do left join: 74692 / 74692
- Linhas duplicadas (date+geocode) antes/depois: 3300 / 3300
- Linhas com Pop_i ausente apos join: 0
- Linhas com offset ausente apos join: 0

## Offset populacional
- Aplicado apenas em modelos binomial negativa (`MASS::glm.nb`).
- Formula dos modelos inclui `offset(offset)` onde `offset = log(Pop_i/100000)`.
- Conferir `summary_*_offset.txt` para evidencia em cada modelo.

## Sumarios descritivos
- Arquivo `descriptive_before_after_offset.csv` contem n, media e desvio-padrao antes/depois da inclusao do offset.

## Evidencias de lag crossing
- Arquivos `lag_crossing_by_lag_*_offset.csv` mostram o numero de linhas em fronteira por lag.
- Arquivos `lag_crossing_summary_*_offset.csv` mostram comparacao com e sem `group` e indicador de bloqueio.

## Comparabilidade e ranking
- `n_final_comparison_offset.csv`: n final, AIC e BIC por modelo.
- `ranking_modelos_offset.csv` e `ranking_modelos_por_BIC_offset.csv`: ordenacao final.
