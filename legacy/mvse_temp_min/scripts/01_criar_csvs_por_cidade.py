#!/usr/bin/env python3
"""
Script para criar CSVs por cidade com temp_min e rel_humid_med
Baseado no arquivo climate_pe_pos_2016_2.csv para processamento MVSE
"""

import pandas as pd
import os
from pathlib import Path

def criar_csvs_por_cidade():
    """Cria arquivos CSV individuais por cidade com temp_min, rel_humid_med e precip_tot"""


    arquivo_clima = r"..\ZENODO\infodengue_sprint_24-25\climate_pe_pos_2016_2.csv"


    dir_saida = r"..\dados_mvse_cidades_tempMin_humidMed"


    arquivo_geocodes = r"..\geocodes_pernambuco.csv"

    print("=" * 80)
    print("CRIAÇÃO DE CSVs POR CIDADE - TEMP_MIN + UMIDADE MÉDIA + PRECIPITAÇÃO TOTAL")
    print("=" * 80)
    print(f"Arquivo clima: {arquivo_clima}")
    print(f"Diretório saída: {dir_saida}")
    print()


    if not Path(arquivo_clima).exists():
        print(f"✗ ERRO: Arquivo de clima não encontrado: {arquivo_clima}")
        return False

    if not Path(arquivo_geocodes).exists():
        print(f"✗ ERRO: Arquivo de geocodes não encontrado: {arquivo_geocodes}")
        return False


    print("Carregando dados de clima...")
    df_clima = pd.read_csv(arquivo_clima)
    print(f"✓ Dados de clima carregados: {len(df_clima):,} registros")

    print("Carregando geocodes das cidades...")
    df_geocodes = pd.read_csv(arquivo_geocodes)
    print(f"✓ Geocodes carregados: {len(df_geocodes)} cidades")
    print()


    colunas_necessarias = ['date', 'geocode', 'temp_min', 'rel_humid_med', 'precip_tot']
    colunas_faltando = [col for col in colunas_necessarias if col not in df_clima.columns]

    if colunas_faltando:
        print(f"✗ ERRO: Colunas faltando no arquivo de clima: {colunas_faltando}")
        print(f"Colunas disponíveis: {list(df_clima.columns)}")
        return False


    df_clima = df_clima[colunas_necessarias].copy()


    df_clima['date'] = pd.to_datetime(df_clima['date'])


    print("Estatísticas dos dados:")
    print(f"- Período: {df_clima['date'].min().strftime('%Y-%m-%d')} a {df_clima['date'].max().strftime('%Y-%m-%d')}")
    print(f"- Geocodes únicos: {df_clima['geocode'].nunique()}")
    print(f"- Temp_min: {df_clima['temp_min'].min():.2f}°C a {df_clima['temp_min'].max():.2f}°C")
    print(f"- Rel_humid_med: {df_clima['rel_humid_med'].min():.2f}% a {df_clima['rel_humid_med'].max():.2f}%")
    print(f"- Precip_tot: {df_clima['precip_tot'].min():.2f}mm a {df_clima['precip_tot'].max():.2f}mm")
    print()


    contador = 0
    erros = 0

    for _, row in df_geocodes.iterrows():
        geocode = row['geocode']

        try:

            df_cidade = df_clima[df_clima['geocode'] == geocode].copy()

            if len(df_cidade) == 0:
                print(f"⚠ Aviso: Nenhum dado encontrado para geocode {geocode}")
                continue


            df_cidade = df_cidade.sort_values('date')


            df_cidade = df_cidade.drop('geocode', axis=1)


            df_cidade = df_cidade.rename(columns={
                'temp_min': 'T',
                'rel_humid_med': 'H',
                'precip_tot': 'R'
            })


            arquivo_saida = Path(dir_saida) / f"{geocode}.csv"
            df_cidade.to_csv(arquivo_saida, index=False)

            contador += 1

            if contador % 20 == 0:
                print(f"Processadas: {contador} cidades...")

        except Exception as e:
            print(f"✗ ERRO ao processar geocode {geocode}: {e}")
            erros += 1

    print(f"\n✓ PROCESSAMENTO CONCLUÍDO!")
    print(f"Cidades processadas: {contador}")
    print(f"Erros: {erros}")
    print(f"Arquivos salvos em: {dir_saida}")


    arquivos_criados = list(Path(dir_saida).glob("*.csv"))
    print(f"Total de arquivos criados: {len(arquivos_criados)}")

    if arquivos_criados:
        print(f"\nExemplo de arquivo criado:")
        arquivo_exemplo = arquivos_criados[0]
        df_exemplo = pd.read_csv(arquivo_exemplo)
        print(f"- Arquivo: {arquivo_exemplo.name}")
        print(f"- Registros: {len(df_exemplo)}")
        print(f"- Colunas: {', '.join(df_exemplo.columns)}")
        print(f"- Período: {df_exemplo['date'].min()} a {df_exemplo['date'].max()}")
        print(f"- Primeiras linhas:")
        print(df_exemplo.head(3).to_string(index=False))

    return contador > 0

if __name__ == "__main__":
    sucesso = criar_csvs_por_cidade()
    if sucesso:
        print("\n🎉 CRIAÇÃO DE CSVs CONCLUÍDA COM SUCESSO!")
    else:
        print("\n❌ FALHA NA CRIAÇÃO DOS CSVs!")