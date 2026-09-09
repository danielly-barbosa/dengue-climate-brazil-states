#!/usr/bin/env python3
"""
Script para processar dados climáticos de Pernambuco para MVSE
Adaptado para usar temp_med (temperatura média) ao invés de temp_min
Arquivo fonte: climate_pe_pos_2016_2.csv
"""

import pandas as pd
import numpy as np
import os
from pathlib import Path
import sys
from datetime import datetime

def processar_dados_mvse_tempMed():
    """
    Processa dados climáticos para MVSE usando temp_med
    """
    print("=== PROCESSAMENTO DADOS MVSE - TEMP_MED + REL_HUMID_MED ===")
    print(f"Início: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")


    arquivo_entrada = "../ZENODO/infodengue_sprint_24-25/climate_pe_pos_2016_2.csv"


    if not os.path.exists(arquivo_entrada):
        print(f"ERRO: Arquivo não encontrado: {arquivo_entrada}")
        return False

    print(f"Carregando dados de: {arquivo_entrada}")

    try:

        df = pd.read_csv(arquivo_entrada)
        print(f"Dados carregados: {len(df)} registros, {len(df.columns)} colunas")


        colunas_necessarias = ['date', 'geocode', 'temp_med', 'rel_humid_med', 'precip_tot']
        colunas_faltantes = [col for col in colunas_necessarias if col not in df.columns]

        if colunas_faltantes:
            print(f"ERRO: Colunas faltantes: {colunas_faltantes}")
            print(f"Colunas disponíveis: {list(df.columns)}")
            return False

        print("✓ Todas as colunas necessárias encontradas")


        mapeamento = {
            'temp_med': 'T',
            'rel_humid_med': 'H',
            'precip_tot': 'R'
        }


        df_mvse = df[['date', 'geocode'] + list(mapeamento.keys())].copy()
        df_mvse = df_mvse.rename(columns=mapeamento)


        dados_na = df_mvse.isnull().sum()
        if dados_na.sum() > 0:
            print("Dados faltantes por coluna:")
            for col, count in dados_na.items():
                if count > 0:
                    print(f"  {col}: {count} valores NA")


        df_limpo = df_mvse.dropna()
        registros_removidos = len(df_mvse) - len(df_limpo)
        if registros_removidos > 0:
            print(f"Removidos {registros_removidos} registros com dados faltantes")


        print("\nEstatísticas dos dados processados:")
        print(f"  Período: {df_limpo['date'].min()} a {df_limpo['date'].max()}")
        print(f"  Cidades únicas: {df_limpo['geocode'].nunique()}")
        print(f"  Registros totais: {len(df_limpo)}")

        print("\nEstatísticas das variáveis:")
        for var in ['T', 'H', 'R']:
            stats = df_limpo[var].describe()
            print(f"  {var}: min={stats['min']:.2f}, max={stats['max']:.2f}, média={stats['mean']:.2f}")


        dir_saida = "../dados_mvse_cidades_tempMed_humMed"
        Path(dir_saida).mkdir(parents=True, exist_ok=True)
        print(f"\nDiretório de saída: {dir_saida}")


        cidades = sorted(df_limpo['geocode'].unique())
        print(f"Processando {len(cidades)} cidades...")

        cidades_processadas = 0
        cidades_com_erro = 0

        for geocode in cidades:
            try:

                dados_cidade = df_limpo[df_limpo['geocode'] == geocode].copy()


                dados_cidade = dados_cidade.sort_values('date')


                if len(dados_cidade) < 50:
                    print(f"  Cidade {geocode}: poucos dados ({len(dados_cidade)} registros) - pulando")
                    continue


                dados_mvse = dados_cidade[['date', 'T', 'H', 'R']].copy()


                if dados_mvse.isnull().any().any():
                    print(f"  Cidade {geocode}: dados faltantes - pulando")
                    continue


                if (dados_mvse['T'] <= 0).any() or (dados_mvse['H'] <= 0).any() or (dados_mvse['R'] < 0).any():
                    print(f"  Cidade {geocode}: valores inválidos - pulando")
                    continue


                arquivo_cidade = os.path.join(dir_saida, f"{geocode}.csv")
                dados_mvse.to_csv(arquivo_cidade, index=False)

                cidades_processadas += 1

                if cidades_processadas % 50 == 0:
                    print(f"  Processadas {cidades_processadas} cidades...")

            except Exception as e:
                print(f"  ERRO na cidade {geocode}: {str(e)}")
                cidades_com_erro += 1
                continue


        print(f"\n=== RELATÓRIO FINAL ===")
        print(f"Cidades processadas com sucesso: {cidades_processadas}")
        print(f"Cidades com erro: {cidades_com_erro}")
        print(f"Taxa de sucesso: {100 * cidades_processadas / len(cidades):.1f}%")
        print(f"Arquivos gerados em: {dir_saida}")


        arquivos_gerados = list(Path(dir_saida).glob("*.csv"))
        print(f"Total de arquivos CSV gerados: {len(arquivos_gerados)}")

        if len(arquivos_gerados) > 0:

            arquivo_exemplo = arquivos_gerados[0]
            print(f"\nExemplo de arquivo gerado ({arquivo_exemplo.name}):")
            df_exemplo = pd.read_csv(arquivo_exemplo)
            print(f"  Registros: {len(df_exemplo)}")
            print(f"  Colunas: {list(df_exemplo.columns)}")
            print(f"  Primeiras linhas:")
            print(df_exemplo.head(3).to_string(index=False))

        print(f"\nFim: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        return True

    except Exception as e:
        print(f"ERRO no processamento: {str(e)}")
        return False

if __name__ == "__main__":
    sucesso = processar_dados_mvse_tempMed()
    if sucesso:
        print("\n✓ Processamento concluído com sucesso!")
        sys.exit(0)
    else:
        print("\n✗ Processamento falhou!")
        sys.exit(1)