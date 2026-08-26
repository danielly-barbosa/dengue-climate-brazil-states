# RIO GRANDE DO SUL DLNM MASS + OFFSET

Nova versao dos codigos do Rio Grande do Sul com:
- modelos apenas binomial negativa (`MASS::glm.nb`);
- offset populacional `offset = log(Pop_i / 100000)`;
- validacao da base populacional (`ano`, `id_municipio/geocode`, `Pop_i/populacao`) sem duplicatas de chave;
- merge por `year + geocode` sem remocao de duplicacoes preexistentes;
- crossbasis em painel por municipio;
- teste explicito de risco de lag atravessar fronteiras de municipio;
- logica da **versao A** dos originais do RS:
  - remove geocodes com menos de 10 casos totais por modelo;
  - combinados com DLNM na temperatura principal e ajuste por `ns(rel_humid_med, df=3)` e `ns(precip_tot, df=3)`.

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
- `scripts/functions_dlnm_offset_rio_grande_do_sul.R`
- `scripts/run_all_models_offset.R`
- `scripts/finalize_reports_offset.R`
- `scripts/avaliar_modelos_AIC_QAIC_rs_offset.R`
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
Executar em `RIO GRANDE DO SUL DLNM MASS + OFFSET/scripts`:

```bash
Rscript run_all_models_offset.R
```

Opcional para consolidacao e ranking:

```bash
Rscript finalize_reports_offset.R
Rscript avaliar_modelos_AIC_QAIC_base_PE_copiado.R
```
