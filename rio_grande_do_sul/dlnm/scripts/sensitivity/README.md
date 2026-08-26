## Sensibilidade do Filtro de Geocodes - RS + OFFSET

Esta pasta isola a analise de sensibilidade pedida pelo revisor no mesmo pipeline do `RS + OFFSET`.

Arquivos copiados do pipeline base:

- `functions_dlnm_offset_rio_grande_do_sul.R`
- `run_all_models_offset.R`

Objetivo:

- manter o pipeline principal intacto;
- comparar `com filtro (<10 casos removidos)` vs `sem filtro`;
- mudar apenas o limiar de exclusao dos geocodes.

Como rodar:

```r
Rscript "run_all_models_offset.R"
```

Comportamento padrao:

- reutiliza os resultados filtrados ja existentes do pipeline principal;
- reroda apenas a versao sem filtro em `resultados/sensibilidade_geocodes_mesmo_pipeline/unfiltered_same_pipeline`.

Opcao adicional:

- definir `RERUN_FILTERED_SENSITIVITY=true` para rerodar tambem a versao filtrada dentro desta pasta de sensibilidade.
