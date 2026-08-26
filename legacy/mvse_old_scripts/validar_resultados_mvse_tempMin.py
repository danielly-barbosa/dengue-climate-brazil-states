#!/usr/bin/env python3
"""
Script para validar e analisar resultados MVSE temp_min consolidados
Gera relatório detalhado da qualidade e características dos dados
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path
import warnings
warnings.filterwarnings('ignore')

def validar_resultados_mvse():
    """Valida e analisa os resultados consolidados do MVSE"""


    arquivo_consolidado = r"..\resultados_MVSE_tempMin_consolidado.csv"

    print("=" * 80)
    print("VALIDAÇÃO RESULTADOS MVSE - TEMPERATURA MÍNIMA")
    print("=" * 80)
    print(f"Arquivo: {arquivo_consolidado}")
    print()


    if not Path(arquivo_consolidado).exists():
        print("✗ ERRO: Arquivo consolidado não encontrado!")
        return False


    print("Carregando dados...")
    df = pd.read_csv(arquivo_consolidado)
    df['date'] = pd.to_datetime(df['date'])

    print(f"✓ Dados carregados: {len(df):,} registros")
    print()


    print("1. VALIDAÇÕES BÁSICAS")
    print("-" * 40)


    print(f"Dimensões: {df.shape[0]:,} linhas × {df.shape[1]} colunas")
    print(f"Cidades: {df['cidade'].nunique()}")
    print(f"Período: {df['date'].min().strftime('%Y-%m-%d')} a {df['date'].max().strftime('%Y-%m-%d')}")
    print(f"Colunas: {', '.join(df.columns)}")
    print()


    print("Valores ausentes por coluna:")
    for col in df.columns:
        missing = df[col].isna().sum()
        pct = (missing / len(df)) * 100
        print(f"  {col}: {missing:,} ({pct:.2f}%)")
    print()


    print("2. VALIDAÇÕES ESPECÍFICAS")
    print("-" * 40)


    indexP_stats = df['indexP'].describe()
    print("Estatísticas IndexP:")
    for stat, value in indexP_stats.items():
        print(f"  {stat}: {value:.4f}")
    print()


    q01 = df['indexP'].quantile(0.01)
    q99 = df['indexP'].quantile(0.99)
    extremos = ((df['indexP'] < q01) | (df['indexP'] > q99)).sum()
    print(f"Valores extremos IndexP (< P1 ou > P99): {extremos:,} ({extremos/len(df)*100:.2f}%)")
    print(f"  P1 = {q01:.4f}, P99 = {q99:.4f}")
    print()


    ic_inconsistente = (df['indexPlower'] > df['indexP']).sum() + (df['indexP'] > df['indexPupper']).sum()
    print(f"Intervalos de confiança inconsistentes: {ic_inconsistente:,}")
    print()


    print("3. ANÁLISE POR CIDADE")
    print("-" * 40)


    cidade_stats = df.groupby('cidade').agg({
        'indexP': ['count', 'mean', 'std', 'min', 'max'],
        'date': ['min', 'max']
    }).round(4)


    contagem_por_cidade = df['cidade'].value_counts()
    print(f"Cidade com mais dados: {contagem_por_cidade.index[0]} ({contagem_por_cidade.iloc[0]:,} registros)")
    print(f"Cidade com menos dados: {contagem_por_cidade.index[-1]} ({contagem_por_cidade.iloc[-1]:,} registros)")
    print(f"Média de registros por cidade: {contagem_por_cidade.mean():.0f}")
    print()


    indexP_medio_cidade = df.groupby('cidade')['indexP'].mean().sort_values()
    print(f"Cidade com menor IndexP médio: {indexP_medio_cidade.index[0]} ({indexP_medio_cidade.iloc[0]:.4f})")
    print(f"Cidade com maior IndexP médio: {indexP_medio_cidade.index[-1]} ({indexP_medio_cidade.iloc[-1]:.4f})")
    print()


    print("4. ANÁLISE TEMPORAL")
    print("-" * 40)


    df_temporal = df.groupby('date')['indexP'].agg(['mean', 'std', 'count']).reset_index()


    df['mes'] = df['date'].dt.month
    sazonalidade = df.groupby('mes')['indexP'].mean()
    mes_max = sazonalidade.idxmax()
    mes_min = sazonalidade.idxmin()

    meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
             'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez']

    print(f"Mês com maior IndexP médio: {meses[mes_max-1]} ({sazonalidade[mes_max]:.4f})")
    print(f"Mês com menor IndexP médio: {meses[mes_min-1]} ({sazonalidade[mes_min]:.4f})")
    print(f"Amplitude sazonal: {sazonalidade.max() - sazonalidade.min():.4f}")
    print()


    print("5. QUALIDADE DOS DADOS")
    print("-" * 40)


    duplicatas = df.duplicated(['cidade', 'date']).sum()
    print(f"Registros duplicados (cidade + data): {duplicatas:,}")


    cidades_com_gaps = 0
    for cidade in df['cidade'].unique()[:10]:
        df_cidade = df[df['cidade'] == cidade].sort_values('date')
        if len(df_cidade) > 1:
            gaps = (df_cidade['date'].diff() > pd.Timedelta(days=2)).sum()
            if gaps > 0:
                cidades_com_gaps += 1

    print(f"Cidades com gaps temporais (amostra de 10): {cidades_com_gaps}")
    print()


    print("6. RESUMO DA VALIDAÇÃO")
    print("-" * 40)


    score_qualidade = 100


    pct_missing = df['indexP'].isna().mean() * 100
    score_qualidade -= pct_missing * 2


    if ic_inconsistente > 0:
        score_qualidade -= 10


    if duplicatas > 0:
        score_qualidade -= 5

    score_qualidade = max(0, score_qualidade)

    print(f"Score de Qualidade: {score_qualidade:.1f}/100")

    if score_qualidade >= 90:
        status = "✓ EXCELENTE"
        cor = "🟢"
    elif score_qualidade >= 75:
        status = "✓ BOM"
        cor = "🟡"
    elif score_qualidade >= 60:
        status = "⚠ REGULAR"
        cor = "🟠"
    else:
        status = "✗ RUIM"
        cor = "🔴"

    print(f"Status da Validação: {cor} {status}")
    print()


    relatorio_arquivo = r"..\relatorio_validacao_MVSE_tempMin.txt"

    with open(relatorio_arquivo, 'w', encoding='utf-8') as f:
        f.write("RELATÓRIO DE VALIDAÇÃO - MVSE TEMPERATURA MÍNIMA\n")
        f.write("=" * 60 + "\n\n")
        f.write(f"Data da validação: {pd.Timestamp.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"Arquivo analisado: {arquivo_consolidado}\n\n")
        f.write(f"RESUMO EXECUTIVO:\n")
        f.write(f"- Total de registros: {len(df):,}\n")
        f.write(f"- Cidades processadas: {df['cidade'].nunique()}\n")
        f.write(f"- Período: {df['date'].min().strftime('%Y-%m-%d')} a {df['date'].max().strftime('%Y-%m-%d')}\n")
        f.write(f"- IndexP médio: {df['indexP'].mean():.4f}\n")
        f.write(f"- Score de qualidade: {score_qualidade:.1f}/100\n")
        f.write(f"- Status: {status}\n")

    print(f"✓ Relatório salvo em: {relatorio_arquivo}")

    return score_qualidade >= 75

if __name__ == "__main__":
    sucesso = validar_resultados_mvse()
    if sucesso:
        print("\n🎉 VALIDAÇÃO APROVADA!")
    else:
        print("\n⚠ VALIDAÇÃO COM RESSALVAS!")