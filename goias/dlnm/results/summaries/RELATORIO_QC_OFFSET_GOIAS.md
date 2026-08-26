# Relatorio QC - GO DLNM MASS + OFFSET

## Solucao para painel e lags
- Solucao adotada: `crossbasis(..., group = geocode)` em todos os modelos.
- Motivo: no dlnm 2.4.10, `group` define series independentes, evitando que o historico de um municipio alimente o lag de outro.
- Evidencia objetiva: os testes de fronteira de lag compararam `crossbasis` com e sem `group` e mostram bloqueio do cruzamento em fronteiras.
- Resultado agregado: 15 de 15 verificacoes indicaram bloqueio de lag crossing com `group`.

## Integridade do merge com populacao
- n antes/depois do left join: 99064 / 99064
- Linhas com Pop_i ausente apos join: 0
- Linhas com offset ausente apos join: 0

## Comparabilidade n_final
- Tabela completa em `n_final_comparison_offset.csv`.

## Multicolinearidade
- Correlacoes (Pearson/Spearman): arquivos `multicolinearidade_cor_*_goias_offset.csv`.
- VIF global e por modelo combinado: arquivos `multicolinearidade_vif*_offset.csv`.
- Interpretacao: correlacoes altas entre variaveis termicas podem reduzir ganho informativo marginal e afetar AIC dos combinados.

## Offset populacional
- Aplicado apenas em modelos binomial negativa (`MASS::glm.nb`) por `offset(log(Pop_i/100000))`.
- Sumarios dos modelos salvos em `summary_*_offset.txt` com formula contendo `offset(offset)`.
