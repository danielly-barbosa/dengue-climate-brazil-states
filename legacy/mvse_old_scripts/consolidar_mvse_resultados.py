#!/usr/bin/env python3

"""
Script para consolidar todos os arquivos estimated_indexP.csv em um único arquivo
Autor: Assistente IA
Data: 2024
"""

import pandas as pd
import os
from pathlib import Path
import glob

def carregar_mapeamento_geocodes():
    """Carrega o mapeamento cidade -> geocode"""
    print("Carregando mapeamento cidade-geocode...")


    arquivo_mapeamento = r"..\ZENODO\pernambuco\pernambuco\indexP\tratamento\cidade_Mesorregiao_atualizado.csv"


    df_mapeamento = pd.read_csv(arquivo_mapeamento)


    mapeamento = {}
    for _, row in df_mapeamento.iterrows():
        cidade_normalizada = row['cidade'].lower().replace(' ', '_').replace('-', '_')
        mapeamento[cidade_normalizada] = row['geocode']

    print(f"Carregado mapeamento para {len(mapeamento)} cidades")
    return mapeamento

def consolidar_arquivos_mvse():
    """Consolida todos os arquivos estimated_indexP.csv em um único arquivo"""


    diretorio_resultados = r"..\resultados_MVSE_GPU_EXTREMO"


    mapeamento_geocodes = carregar_mapeamento_geocodes()


    lista_dfs = []


    arquivos_processados = 0
    cidades_sem_geocode = []

    print("Iniciando consolidação dos arquivos MVSE...")


    for pasta_cidade in os.listdir(diretorio_resultados):
        caminho_pasta = os.path.join(diretorio_resultados, pasta_cidade)


        if not os.path.isdir(caminho_pasta):
            continue


        arquivo_csv = os.path.join(caminho_pasta, f"{pasta_cidade}.estimated_indexP.csv")

        if os.path.exists(arquivo_csv):
            try:

                df = pd.read_csv(arquivo_csv)


                colunas_para_remover = ['indexPsmooth5', 'indexPsmooth20']
                for coluna in colunas_para_remover:
                    if coluna in df.columns:
                        df = df.drop(columns=[coluna])


                df['cidade'] = pasta_cidade


                if pasta_cidade in mapeamento_geocodes:
                    df['geocode'] = mapeamento_geocodes[pasta_cidade]
                else:
                    df['geocode'] = None
                    cidades_sem_geocode.append(pasta_cidade)


                colunas_ordenadas = ['geocode', 'cidade', 'date', 'indexP', 'indexPlower', 'indexPupper']
                df = df[colunas_ordenadas]


                lista_dfs.append(df)
                arquivos_processados += 1

                if arquivos_processados % 20 == 0:
                    print(f"Processados {arquivos_processados} arquivos...")

            except Exception as e:
                print(f"Erro ao processar {arquivo_csv}: {e}")
        else:
            print(f"Arquivo não encontrado: {arquivo_csv}")


    if lista_dfs:
        print("Consolidando todos os dados...")
        df_consolidado = pd.concat(lista_dfs, ignore_index=True)


        df_consolidado = df_consolidado.sort_values(['geocode', 'date']).reset_index(drop=True)


        arquivo_saida = r"..\mvse_pernambuco_consolidado.csv"
        df_consolidado.to_csv(arquivo_saida, index=False)


        print("\n" + "="*60)
        print("CONSOLIDAÇÃO CONCLUÍDA COM SUCESSO!")
        print("="*60)
        print(f"Arquivos processados: {arquivos_processados}")
        print(f"Total de registros: {len(df_consolidado):,}")
        print(f"Cidades únicas: {df_consolidado['cidade'].nunique()}")
        print(f"Período: {df_consolidado['date'].min()} a {df_consolidado['date'].max()}")
        print(f"Arquivo salvo em: {arquivo_saida}")


        print(f"\nColunas no arquivo final:")
        for i, coluna in enumerate(df_consolidado.columns, 1):
            print(f"  {i}. {coluna}")


        if cidades_sem_geocode:
            print(f"\nCidades sem geocode encontrado ({len(cidades_sem_geocode)}):")
            for cidade in sorted(cidades_sem_geocode):
                print(f"  - {cidade}")


        print(f"\nRegistros por cidade:")
        registros_por_cidade = df_consolidado.groupby('cidade').size()
        print(f"  Mínimo: {registros_por_cidade.min()} registros")
        print(f"  Máximo: {registros_por_cidade.max()} registros")
        print(f"  Média: {registros_por_cidade.mean():.1f} registros")


        arquivo_relatorio = r"..\relatorio_consolidacao_mvse.csv"
        relatorio_detalhado = df_consolidado.groupby(['geocode', 'cidade']).agg({
            'date': ['min', 'max', 'count'],
            'indexP': ['mean', 'min', 'max', 'std']
        }).round(4)

        relatorio_detalhado.columns = ['data_inicio', 'data_fim', 'num_registros',
                                     'indexP_media', 'indexP_min', 'indexP_max', 'indexP_desvio']
        relatorio_detalhado.to_csv(arquivo_relatorio)
        print(f"Relatório detalhado salvo em: {arquivo_relatorio}")

    else:
        print("Nenhum arquivo foi processado!")

if __name__ == "__main__":
    consolidar_arquivos_mvse()