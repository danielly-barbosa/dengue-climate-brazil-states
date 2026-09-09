# Pipeline MVSE / IndexP

Scripts e dados organizados por estado para cálculo do **indexP** (Mosquito-borne Viral Suitability Estimator) com pacote MVSE 1.0.1.

## Estrutura geral

```
mvse/
├── README.md                           # Este arquivo
├── inputs_climate_zenodo_todos_os_estados.csv  # CSV unificado nacional (524 MB)
│
├── pernambuco/                  # 185 municípios (IBGE 26xxxxxx)
├── rio_grande_do_sul/           # 497 municípios (IBGE 43xxxxxx)
├── rio_de_janeiro/              #  92 municípios (IBGE 33xxxxxx)
├── goias/                       # 246 municípios (IBGE 52xxxxxx)
│
├── tempMin_humMed/              # Pernambuco com temp_min (185 outputs)
├── tempMed_humMed/              # Pernambuco com temp_med (relatórios)
│
└── legacy/                      # Scripts antigos (09-17/10/2025)
```

## Estrutura de cada estado

Tudo é **cópia real** (sem symlinks/junctions).

```
<estado>/
├── inputs/
│   ├── <estado>_climate.csv         # CSV único do estado
│   ├── geocodes_*.csv               # Lista de municípios (quando aplicável)
│   └── geocodes/                    # CSVs por município (entrada MVSE)
├── outputs/
│   ├── <estado>_indexP_combined.csv # CSV consolidado final
│   └── indexP_tempMed_humMed/       # CSVs estimados por município
└── scripts/
    ├── 00a_filter_climate.py        # Filtra estado do CSV nacional
    ├── 00b_split_geocodes.py        # Quebra em CSVs por município
    ├── 01_executar_mvse.R           # RODA MVSE (calcula indexP)
    └── 99_combine_indexp.py         # Consolida resultados
```

## Versão do MVSE usada

**MVSE 1.0.1** — Lourenco & Obolski (Univ. Oxford), 2021
- Localização: `d:\CÓDIGOS\CÓDIGOS\ANTIGO\MVSE_1.0.1\MVSE\`
- Pacote carregado via `require('MVSE')` (deve estar instalado na lib R)

## Configuração MVSE padrão

| Parâmetro | Valor |
|---|---|
| Temperatura | temp_med |
| Umidade | rel_humid_med |
| Precipitação | precip_tot |
| MCMC (`nMCMC`) | 25.000 |
| nSample (simulações) | 120 |
| Smoothing (dias) | 7, 15, 30, 60 |
| GPU | RTX 2060 SUPER |
| Threads CPU | 28 |

## Estados cobertos

| Estado | Municípios | CSV único | CSV indexP | Período |
|---|---|---|---|---|
| Pernambuco | 185 | 17,65 MB | 5,01 MB | pós-2016 |
| Rio Grande do Sul | 497 | 47,23 MB | 13,71 MB | pós-2016 |
| Rio de Janeiro | 92 | 8,79 MB | 2,52 MB | pós-2016 |
| Goiás | 246 | 23,06 MB | 6,70 MB | pós-2016 |

## Como executar para um estado (exemplo Pernambuco)

```powershell
cd pernambuco
python mvse/scripts/00a_filter_climate.py
python mvse/scripts/00b_split_geocodes.py
Rscript mvse/scripts/01_executar_mvse.R
python mvse/scripts/99_combine_indexp.py
```

## Origem dos dados

- **CSV unificado nacional**: `cross_state/data/inputs_climate_zenodo_todos_os_estados.csv`
- **Filtragem por estado**: scripts `00a_filter_climate.py` em `<state>/mvse/scripts/`
- **Geocodes**: `pernambuco/mvse/inputs/geocodes_pernambuco.csv` (PE) + pastas `geocodes/` por estado

## Pastas Pernambuco (ciclos paralelos)

- `tempMin_humMed/`: ciclo com **temperatura mínima** (185 outputs já calculados)
- `tempMed_humMed/`: ciclo com **temperatura média** (relatórios gerados)

## Última atualização

2026-08-14 — organização por estado (paralelo ao `cross_state/data/inputs_climate_zenodo_todos_os_estados.csv`).