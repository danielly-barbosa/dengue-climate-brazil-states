# PE DLNM MASS + OFFSET

Nova versao dos codigos de Pernambuco com:
- modelos apenas binomial negativa (`MASS::glm.nb`);
- offset populacional `offset = log(Pop_i / 100000)`;
- crossbasis em painel por municipio com `group = geocode`;
- validacao explicita de risco de lag atravessar municipios.

## Estrutura
- `dados/`: bases usadas (dengue, clima, indexP, populacao).
- `scripts/`: funcoes e scripts de execucao por modelo.
- `resultados/figuras/`: figuras DLNM com sufixo `_offset`.
- `resultados/summaries/`: sumarios de modelo, QC, n_final, lag crossing, multicolinearidade e ranking.

## Dependencias R
- `dlnm`
- `splines`
- `ggplot2`
- `dplyr`
- `lubridate`
- `MASS`

## Scripts principais
- `scripts/functions_dlnm_offset_pernambuco.R` (funcoes obrigatorias e pipeline)
- `scripts/run_all_models_offset.R` (executa todos os modelos)
- `scripts/finalize_reports_offset.R` (consolida relatorios finais)
- `scripts/avaliar_modelos_AIC_QAIC_pe_offset.R` (gera ranking por AIC/BIC)

## Scripts por modelo
- Individuais:
  - `run_individual_indexP_offset.R`
  - `run_individual_precip_tot_offset.R`
  - `run_individual_rel_humid_med_offset.R`
  - `run_individual_temp_max_offset.R`
  - `run_individual_temp_med_offset.R`
  - `run_individual_temp_min_offset.R`
- Combinados:
  - `run_combined_temp_max_precip_humid_offset.R`
  - `run_combined_temp_med_precip_humid_offset.R`
  - `run_combined_temp_min_precip_humid_offset.R`

## Comando principal
Executar em `PE DLNM MASS + OFFSET/scripts`:

```bash
Rscript run_all_models_offset.R
```

Opcional, para consolidar relatorios e ranking:

```bash
Rscript finalize_reports_offset.R
Rscript avaliar_modelos_AIC_QAIC_pe_offset.R
```
