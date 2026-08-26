# RIO DE JANEIRO DLNM MASS + OFFSET

Nova versao dos codigos de Rio de Janeiro com:
- modelos apenas binomial negativa (`MASS::glm.nb`);
- offset populacional `offset = log(Pop_i / 100000)`;
- validacao da base populacional (`ano`, `id_municipio/geocode`, `Pop_i/populacao`) sem duplicatas de chave;
- merge por `year + geocode` sem remocao de duplicacoes preexistentes;
- `crossbasis` em painel por municipio;
- teste explicito de risco de lag atravessar fronteiras de municipio.

## Estrutura
- `dados/`: bases de dengue, clima, indexP e populacao.
- `scripts/`: funcoes e scripts de execucao por modelo.
- `resultados/figuras/`: figuras DLNM com sufixo `_offset`.
- `resultados/summaries/`: sumarios de modelo, QC, ranking, diagnosticos de lag e merge.

## Dependencias R
- `dlnm`
- `splines`
- `ggplot2`
- `dplyr`
- `lubridate`
- `MASS`

## Arquivos principais modificados
- `scripts/functions_dlnm_offset_rio_de_janeiro.R`
- `scripts/run_all_models_offset.R`
- `scripts/finalize_reports_offset.R`
- `scripts/avaliar_modelos_AIC_QAIC_rj_offset.R`
- `scripts/avaliar_modelos_AIC_QAIC_base_PE_copiado.R` (copia adaptada do PE para uso explicito com OFFSET)

## Scripts por modelo
- Individuais:
  - `scripts/run_individual_indexP_offset.R`
  - `scripts/run_individual_precip_tot_offset.R`
  - `scripts/run_individual_rel_humid_med_offset.R`
  - `scripts/run_individual_temp_max_offset.R`
  - `scripts/run_individual_temp_med_offset.R`
  - `scripts/run_individual_temp_min_offset.R`
- Combinados:
  - `scripts/run_combined_temp_max_precip_humid_offset.R`
  - `scripts/run_combined_temp_med_precip_humid_offset.R`
  - `scripts/run_combined_temp_min_precip_humid_offset.R`

## Comando principal
Executar em `RIO DE JANEIRO DLNM MASS + OFFSET/scripts`:

```bash
Rscript run_all_models_offset.R
```

Opcional para consolidacao:

```bash
Rscript finalize_reports_offset.R
Rscript avaliar_modelos_AIC_QAIC_rj_offset.R
```

## Evidencias esperadas apos executar
- `resultados/summaries/population_validation_offset.csv`
- `resultados/summaries/population_merge_integrity_offset.csv`
- `resultados/summaries/descriptive_before_after_offset.csv`
- `resultados/summaries/lag_crossing_summary_all_models_offset.csv`
- `resultados/summaries/RELATORIO_QC_OFFSET_RIO_DE_JANEIRO.md`
