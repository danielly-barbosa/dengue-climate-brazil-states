# Ranking de Modelos RIO DE JANEIRO DLNM MASS + OFFSET
Gerado em: 2026-03-12 17:29:47.669077

## Melhor Modelo Geral (AIC) - OFFSET
Tipo: individual_offset
Modelo: indexP
Distribuicao: Negative Binomial(0.5247)
AIC: 109777.893
BIC: 111205.58
QAIC: NA
nobs: 36248 | k: 168 | theta: 0.5247

## Top 10 por AIC - OFFSET
| # | Tipo | Modelo | Distribuicao | AIC | BIC | QAIC | nobs | k | theta |
|---:|:-----|:------|:------------|----:|----:|-----:|-----:|--:|------:|
| 1 | individual_offset | indexP | Negative Binomial(0.5247) | 109777.893 | 111205.58 | NA | 36248 | 168 | 0.5247 |
| 2 | combinado_offset | temp_med_precip_humid | Negative Binomial(0.5224) | 109838.367 | 111419.021 | NA | 36248 | 186 | 0.5224 |
| 3 | combinado_offset | temp_min_precip_humid | Negative Binomial(0.5213) | 109884.803 | 111465.457 | NA | 36248 | 186 | 0.5213 |
| 4 | individual_offset | temp_min | Negative Binomial(0.5173) | 109963.986 | 111391.673 | NA | 36248 | 168 | 0.5173 |
| 5 | individual_offset | temp_med | Negative Binomial(0.5169) | 109964.457 | 111392.144 | NA | 36248 | 168 | 0.5169 |
| 6 | combinado_offset | temp_max_precip_humid | Negative Binomial(0.5188) | 109964.852 | 111545.506 | NA | 36248 | 186 | 0.5188 |
| 7 | individual_offset | precip_tot | Negative Binomial(0.5163) | 110015.575 | 111443.263 | NA | 36248 | 168 | 0.5163 |
| 8 | individual_offset | temp_max | Negative Binomial(0.5095) | 110215.037 | 111642.725 | NA | 36248 | 168 | 0.5095 |
| 9 | individual_offset | rel_humid_med | Negative Binomial(0.5087) | 110246.107 | 111673.795 | NA | 36248 | 168 | 0.5087 |

## Melhor por BIC - OFFSET
Tipo: individual_offset
Modelo: indexP
Distribuicao: Negative Binomial(0.5247)
BIC: 111205.58
nobs: 36248 | k: 168 | theta: 0.5247

## Top 10 por BIC - OFFSET
| # | Tipo | Modelo | Distribuicao | BIC | nobs | k | theta |
|---:|:-----|:------|:------------|----:|-----:|--:|------:|
| 1 | individual_offset | indexP | Negative Binomial(0.5247) | 111205.58 | 36248 | 168 | 0.5247 |
| 2 | individual_offset | temp_min | Negative Binomial(0.5173) | 111391.673 | 36248 | 168 | 0.5173 |
| 3 | individual_offset | temp_med | Negative Binomial(0.5169) | 111392.144 | 36248 | 168 | 0.5169 |
| 4 | combinado_offset | temp_med_precip_humid | Negative Binomial(0.5224) | 111419.021 | 36248 | 186 | 0.5224 |
| 5 | individual_offset | precip_tot | Negative Binomial(0.5163) | 111443.263 | 36248 | 168 | 0.5163 |
| 6 | combinado_offset | temp_min_precip_humid | Negative Binomial(0.5213) | 111465.457 | 36248 | 186 | 0.5213 |
| 7 | combinado_offset | temp_max_precip_humid | Negative Binomial(0.5188) | 111545.506 | 36248 | 186 | 0.5188 |
| 8 | individual_offset | temp_max | Negative Binomial(0.5095) | 111642.725 | 36248 | 168 | 0.5095 |
| 9 | individual_offset | rel_humid_med | Negative Binomial(0.5087) | 111673.795 | 36248 | 168 | 0.5087 |

## Observacoes
- Este ranking considera explicitamente apenas modelos com sufixo _offset.
- QAIC e reportado apenas quando houver familia quasi.
- Para binomial negativa, comparar preferencialmente por AIC/BIC.
