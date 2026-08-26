# Ranking de Modelos PE DLNM MASS + OFFSET
Gerado em: 2026-03-12 16:26:04.452344

## Melhor Modelo Geral (AIC) - OFFSET
Tipo: individual
Modelo: indexP
Distribuicao: Negative Binomial(0.3822)
AIC: 163147.931
BIC: 165527.063
QAIC: NA
nobs: 72102 | k: 259 | theta: 0.3822

## Top 10 por AIC (OFFSET)
| # | Tipo | Modelo | Distribuicao | AIC | BIC | QAIC | nobs | k | theta |
|---:|:-----|:------|:------------|----:|----:|-----:|-----:|--:|------:|
| 1 | individual | indexP | Negative Binomial(0.3822) | 163147.931 | 165527.063 | NA | 72102 | 259 | 0.3822 |
| 2 | combinado | temp_med_precip_humid | Negative Binomial(0.3844) | 164210.964 | 166766.096 | NA | 72484 | 278 | 0.3844 |
| 3 | combinado | temp_min_precip_humid | Negative Binomial(0.3839) | 164231.697 | 166786.828 | NA | 72484 | 278 | 0.3839 |
| 4 | combinado | temp_max_precip_humid | Negative Binomial(0.3802) | 164453.315 | 167008.446 | NA | 72484 | 278 | 0.3802 |
| 5 | individual | precip_tot | Negative Binomial(0.3715) | 164864.713 | 167254.405 | NA | 72484 | 260 | 0.3715 |
| 6 | individual | temp_min | Negative Binomial(0.3701) | 164878.591 | 167268.282 | NA | 72484 | 260 | 0.3701 |
| 7 | individual | rel_humid_med | Negative Binomial(0.3705) | 164883.503 | 167273.194 | NA | 72484 | 260 | 0.3705 |
| 8 | individual | temp_med | Negative Binomial(0.3687) | 164931.631 | 167321.323 | NA | 72484 | 260 | 0.3687 |
| 9 | individual | temp_max | Negative Binomial(0.3676) | 164988.882 | 167378.574 | NA | 72484 | 260 | 0.3676 |

## Melhor por BIC - OFFSET
Tipo: individual
Modelo: indexP
Distribuicao: Negative Binomial(0.3822)
BIC: 165527.063
nobs: 72102 | k: 259 | theta: 0.3822

## Top 10 por BIC (OFFSET)
| # | Tipo | Modelo | Distribuicao | BIC | nobs | k | theta |
|---:|:-----|:------|:------------|----:|-----:|--:|------:|
| 1 | individual | indexP | Negative Binomial(0.3822) | 165527.063 | 72102 | 259 | 0.3822 |
| 2 | combinado | temp_med_precip_humid | Negative Binomial(0.3844) | 166766.096 | 72484 | 278 | 0.3844 |
| 3 | combinado | temp_min_precip_humid | Negative Binomial(0.3839) | 166786.828 | 72484 | 278 | 0.3839 |
| 4 | combinado | temp_max_precip_humid | Negative Binomial(0.3802) | 167008.446 | 72484 | 278 | 0.3802 |
| 5 | individual | precip_tot | Negative Binomial(0.3715) | 167254.405 | 72484 | 260 | 0.3715 |
| 6 | individual | temp_min | Negative Binomial(0.3701) | 167268.282 | 72484 | 260 | 0.3701 |
| 7 | individual | rel_humid_med | Negative Binomial(0.3705) | 167273.194 | 72484 | 260 | 0.3705 |
| 8 | individual | temp_med | Negative Binomial(0.3687) | 167321.323 | 72484 | 260 | 0.3687 |
| 9 | individual | temp_max | Negative Binomial(0.3676) | 167378.574 | 72484 | 260 | 0.3676 |

## Observacoes
- Este ranking considera explicitamente apenas modelos com sufixo _offset.
- QAIC e reportado somente para modelos quasi.
- Para binomial negativa, usar AIC/BIC para comparacao.
