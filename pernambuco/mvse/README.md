# MVSE — Pernambuco (PE)

**Municípios**: 185 | **Códigos IBGE**: 26xxxxxx | **Período**: pós-2016

## Estrutura

```
pernambuco/
├── inputs/
│   ├── pernambuco_climate.csv    # CSV único do estado (17,65 MB)
│   ├── geocodes_pernambuco.csv   # Lista dos 185 municípios
│   └── geocodes/                 # 185 CSVs por município (cópia real)
├── outputs/
│   ├── pernambuco_indexP_combined.csv   # CSV único consolidado (5,01 MB)
│   └── indexP_tempMed_humMed/    # 185 CSVs estimados por município (cópia real)
└── scripts/
    ├── 00a_filter_climate.py    # Filtra pernambuco do CSV nacional
    ├── 00b_split_geocodes.py    # Quebra em CSVs por município
    ├── 01_executar_mvse.R       # Roda MVSE (25.000 MCMC, 120 amostras)
    └── 99_combine_indexp.py     # Consolida em 1 CSV
```

## Como executar (do zero)

```powershell
cd d:\CÓDIGOS\mvse\pernambuco
python scripts\00a_filter_climate.py    # gera pernambuco_climate.csv
python scripts\00b_split_geocodes.py    # gera geocodes/*.csv
Rscript scripts\01_executar_mvse.R      # roda MVSE (calcula indexP)
python scripts\99_combine_indexp.py     # gera pernambuco_indexP_combined.csv
```

## Configuração MVSE (01_executar_mvse.R)

- Temperatura: **temp_med**
- Umidade: **rel_humid_med**
- Precipitação: **precip_tot**
- MCMC: 25.000 amostras
- nSample: 120 simulações
- Smoothing: 7, 15, 30, 60 dias
- GPU: RTX 2060 SUPER + 28 threads CPU

## Origem dos dados

- **CSV único**: `cross_state/data/inputs_climate_zenodo_todos_os_estados.csv` (524 MB)
- **CSV filtrado PE**: `pernambuco/mvse/outputs/pernambuco_climate.csv`
- **Geocodes**: `pernambuco/mvse/inputs/geocodes_pernambuco.csv`

## Pacote MVSE

Versão 1.0.1 — `d:\CÓDIGOS\CÓDIGOS\ANTIGO\MVSE_1.0.1\MVSE\`