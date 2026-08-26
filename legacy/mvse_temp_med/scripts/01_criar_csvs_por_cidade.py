#!/usr/bin/env python3
"""
Script para criar CSVs por cidade com temp_med e humid_med
Baseado no arquivo climate_pe_pos_2016_2.csv para processamento MVSE
"""

import pandas as pd
import os
from pathlib import Path

def criar_csvs_por_cidade():
    """Cria arquivos CSV individuais por cidade com temp_med, humid_med e precip_tot"""


    arquivo_clima = r"..\ZENODO\infodengue_sprint_24-25\climate_pe_pos_2016_2.csv"


    dir_saida = r"..\dados_mvse_cidades_tempMed_humidMed"


    arquivo_geocodes = r"..\geocodes_pernambuco.csv"

    print("=" * 80)
    print("CRIAÇÃO DE CSVs POR CIDADE - TEMP_MED + UMIDADE MÉDIA + PRECIPITAÇÃO TOTAL")
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


    colunas_necessarias = ['date', 'geocode', 'temp_med', 'rel_humid_med', 'precip_tot']
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
    print(f"- Temp_med: {df_clima['temp_med'].min():.2f}°C a {df_clima['temp_med'].max():.2f}°C")
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


            df_mvse = pd.DataFrame({
                'date': df_cidade['date'].dt.strftime('%Y-%m-%d'),
                'T': df_cidade['temp_med'],
                'H': df_cidade['rel_humid_med'],
                'R': df_cidade['precip_tot']
            })


            df_mvse = df_mvse.dropna()

            if len(df_mvse) < 365:
                print(f"⚠ Aviso: Cidade {geocode} tem apenas {len(df_mvse)} registros válidos")


            arquivo_saida = os.path.join(dir_saida, f"{geocode}.csv")
            df_mvse.to_csv(arquivo_saida, index=False)

            contador += 1
            if contador % 20 == 0:
                print(f"✓ Processadas {contador} cidades...")

        except Exception as e:
            print(f"✗ Erro ao processar cidade {geocode}: {str(e)}")
            erros += 1

    print()
    print("=" * 80)
    print("RESUMO DO PROCESSAMENTO")
    print("=" * 80)
    print(f"✓ Cidades processadas com sucesso: {contador}")
    print(f"✗ Erros encontrados: {erros}")
    print(f"📁 Arquivos salvos em: {dir_saida}")
    print()


    arquivos_criados = list(Path(dir_saida).glob("*.csv"))
    print(f"Total de arquivos CSV criados: {len(arquivos_criados)}")

    if arquivos_criados:
        print("\nExemplo de arquivo criado:")
        arquivo_exemplo = arquivos_criados[0]
        df_exemplo = pd.read_csv(arquivo_exemplo)
        print(f"Arquivo: {arquivo_exemplo.name}")
        print(f"Registros: {len(df_exemplo)}")
        print("Primeiras 3 linhas:")
        print(df_exemplo.head(3).to_string(index=False))
        print()
        print("Estatísticas do exemplo:")
        print(f"- Temperatura média: {df_exemplo['T'].min():.2f}°C a {df_exemplo['T'].max():.2f}°C")
        print(f"- Umidade média: {df_exemplo['H'].min():.2f}% a {df_exemplo['H'].max():.2f}%")
        print(f"- Precipitação: {df_exemplo['R'].min():.2f}mm a {df_exemplo['R'].max():.2f}mm")

    return contador > 0

if __name__ == "__main__":
    sucesso = criar_csvs_por_cidade()
    if sucesso:
        print("✅ Script executado com sucesso!")
    else:
        print("❌ Script falhou!")