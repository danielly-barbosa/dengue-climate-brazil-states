# Ranking de Modelos RIO GRANDE DO SUL DLNM MASS + OFFSET
Gerado em: 2026-03-13 12:34:59.934877

## Melhor Modelo Geral (AIC) - OFFSET
Tipo: individual_offset
Modelo: indexP
Distribuicao: Negative Binomial(0.3632)
AIC: 55919.109
BIC: 57950.167
QAIC: NA
nobs: 59100 | k: 226 | theta: 0.3632

## Top 10 por AIC - OFFSET
| # | Tipo | Modelo | Distribuicao | AIC | BIC | QAIC | nobs | k | theta |
|---:|:-----|:------|:------------|----:|----:|-----:|-----:|--:|------:|
| 1 | individual_offset | indexP | Negative Binomial(0.3632) | 55919.109 | 57950.167 | NA | 59100 | 226 | 0.3632 |
| 2 | individual_offset | precip_tot | Negative Binomial(0.3475) | 56186.532 | 58217.591 | NA | 59100 | 226 | 0.3475 |
| 3 | individual_offset | temp_max | Negative Binomial(0.3443) | 56235.692 | 58266.751 | NA | 59100 | 226 | 0.3443 |
| 4 | combinado_offset | temp_max_precip_humid | Negative Binomial(0.3448) | 56241.772 | 58326.753 | NA | 59100 | 232 | 0.3448 |
| 5 | individual_offset | temp_med | Negative Binomial(0.3435) | 56268.347 | 58299.406 | NA | 59100 | 226 | 0.3435 |
| 6 | individual_offset | rel_humid_med | Negative Binomial(0.3445) | 56272.516 | 58303.575 | NA | 59100 | 226 | 0.3445 |
| 7 | combinado_offset | temp_med_precip_humid | Negative Binomial(0.3439) | 56275.35 | 58360.33 | NA | 59100 | 232 | 0.3439 |
| 8 | individual_offset | temp_min | Negative Binomial(0.3431) | 56279.517 | 58310.576 | NA | 59100 | 226 | 0.3431 |
| 9 | combinado_offset | temp_min_precip_humid | Negative Binomial(0.3434) | 56288.5 | 58373.48 | NA | 59100 | 232 | 0.3434 |

## Melhor por BIC - OFFSET
Tipo: individual_offset
Modelo: indexP
Distribuicao: Negative Binomial(0.3632)
BIC: 57950.167
nobs: 59100 | k: 226 | theta: 0.3632

## Top 10 por BIC - OFFSET
| # | Tipo | Modelo | Distribuicao | BIC | nobs | k | theta |
|---:|:-----|:------|:------------|----:|-----:|--:|------:|
| 1 | individual_offset | indexP | Negative Binomial(0.3632) | 57950.167 | 59100 | 226 | 0.3632 |
| 2 | individual_offset | precip_tot | Negative Binomial(0.3475) | 58217.591 | 59100 | 226 | 0.3475 |
| 3 | individual_offset | temp_max | Negative Binomial(0.3443) | 58266.751 | 59100 | 226 | 0.3443 |
| 4 | individual_offset | temp_med | Negative Binomial(0.3435) | 58299.406 | 59100 | 226 | 0.3435 |
| 5 | individual_offset | rel_humid_med | Negative Binomial(0.3445) | 58303.575 | 59100 | 226 | 0.3445 |
| 6 | individual_offset | temp_min | Negative Binomial(0.3431) | 58310.576 | 59100 | 226 | 0.3431 |
| 7 | combinado_offset | temp_max_precip_humid | Negative Binomial(0.3448) | 58326.753 | 59100 | 232 | 0.3448 |
| 8 | combinado_offset | temp_med_precip_humid | Negative Binomial(0.3439) | 58360.33 | 59100 | 232 | 0.3439 |
| 9 | combinado_offset | temp_min_precip_humid | Negative Binomial(0.3434) | 58373.48 | 59100 | 232 | 0.3434 |

## Observacoes
- Este ranking considera explicitamente apenas modelos com sufixo _offset.
- QAIC e reportado apenas quando houver familia quasi.
- Para binomial negativa, comparar preferencialmente por AIC/BIC.
