#!/usr/bin/env python3
"""
Script para consolidar resultados MVSE temp_min
Combina todos os arquivos .estimated_indexP.csv em um único arquivo final
"""

import pandas as pd
import os
from pathlib import Path
import glob

def consolidar_resultados_mvse():
    """Consolida todos os resultados MVSE em um único arquivo"""
    
    # Diretório com os resultados
    dir_resultados = r"d:\CÓDIGOS\resultados_MVSE_GPU_EXTREMO"
    
    # Arquivo de saída
    arquivo_saida = r"d:\CÓDIGOS\resultados_MVSE_tempMin_consolidado.csv"
    
    print("=" * 80)
    print("CONSOLIDAÇÃO RESULTADOS MVSE - TEMPERATURA MÍNIMA")
    print("=" * 80)
    print(f"Diretório origem: {dir_resultados}")
    print(f"Arquivo saída: {arquivo_saida}")
    print()
    
    # Lista para armazenar todos os DataFrames
    todos_resultados = []
    
    # Contador de arquivos processados
    contador = 0
    erros = 0
    
    # Percorrer todos os diretórios de cidades
    for cidade_dir in Path(dir_resultados).iterdir():
        if cidade_dir.is_dir() and cidade_dir.name != "relatorio_processamento":
            nome_cidade = cidade_dir.name
            
            # Procurar arquivo .estimated_indexP.csv
            arquivo_csv = cidade_dir / f"{nome_cidade}.estimated_indexP.csv"
            
            if arquivo_csv.exists():
                try:
                    # Ler o arquivo CSV
                    df = pd.read_csv(arquivo_csv)
                    
                    # Adicionar coluna com nome da cidade
                    df['cidade'] = nome_cidade
                    
                    # Reorganizar colunas (cidade primeiro)
                    colunas = ['cidade'] + [col for col in df.columns if col != 'cidade']
                    df = df[colunas]
                    
                    todos_resultados.append(df)
                    contador += 1
                    
                    if contador % 20 == 0:
                        print(f"Processados: {contador} arquivos...")
                        
                except Exception as e:
                    print(f"✗ ERRO ao processar {nome_cidade}: {e}")
                    erros += 1
            else:
                print(f"✗ Arquivo não encontrado: {arquivo_csv}")
                erros += 1
    
    print(f"\nArquivos processados: {contador}")
    print(f"Erros encontrados: {erros}")
    
    if todos_resultados:
        # Combinar todos os DataFrames
        print("\nCombinando resultados...")
        df_final = pd.concat(todos_resultados, ignore_index=True)
        
        # Ordenar por cidade e data
        df_final = df_final.sort_values(['cidade', 'date'])
        
        # Salvar arquivo consolidado
        print(f"Salvando arquivo consolidado...")
        df_final.to_csv(arquivo_saida, index=False)
        
        print(f"\n✓ CONSOLIDAÇÃO CONCLUÍDA!")
        print(f"Arquivo final: {arquivo_saida}")
        print(f"Total de registros: {len(df_final):,}")
        print(f"Cidades processadas: {df_final['cidade'].nunique()}")
        print(f"Colunas: {', '.join(df_final.columns)}")
        
        # Mostrar estatísticas básicas
        print(f"\nEstatísticas básicas:")
        print(f"- Período: {df_final['date'].min()} a {df_final['date'].max()}")
        print(f"- IndexP médio: {df_final['indexP'].mean():.4f}")
        print(f"- IndexP válidos: {df_final['indexP'].notna().sum():,} ({df_final['indexP'].notna().mean()*100:.1f}%)")
        
        return True
    else:
        print("✗ ERRO: Nenhum resultado encontrado!")
        return False

if __name__ == "__main__":
    sucesso = consolidar_resultados_mvse()
    if sucesso:
        print("\n🎉 MISSÃO CONCLUÍDA COM SUCESSO!")
    else:
        print("\n❌ FALHA NA CONSOLIDAÇÃO!")