import pandas as pd
import os
from datetime import datetime
import numpy as np

def processar_dados_para_mvse():
    """
    Processa os dados climáticos de Pernambuco para análise MVSE:
    1. Padroniza colunas para formato: geocode,year,month,day,date,T,H,R
    2. Substitui geocodes por nomes das cidades
    3. Cria CSVs individuais para cada cidade
    """
    
    # Caminhos dos arquivos
    arquivo_clima = r"d:\CÓDIGOS\ZENODO\infodengue_sprint_24-25\climate_pe_pos_2016.csv"
    arquivo_mapeamento = r"D:\CÓDIGOS\ZENODO\pernambuco\pernambuco\indexP\tratamento\cidade_Mesorregiao_atualizado.csv"
    pasta_saida = r"d:\CÓDIGOS\dados_mvse_cidades"
    
    print("=== PROCESSAMENTO DE DADOS PARA MVSE ===\n")
    
    # 1. Carregar dados climáticos
    print("1. Carregando dados climáticos...")
    df_clima = pd.read_csv(arquivo_clima)
    print(f"   - Registros carregados: {len(df_clima)}")
    print(f"   - Colunas atuais: {list(df_clima.columns)}")
    
    # 2. Carregar mapeamento geocode -> cidade
    print("\n2. Carregando mapeamento geocode -> cidade...")
    df_mapeamento = pd.read_csv(arquivo_mapeamento)
    print(f"   - Cidades mapeadas: {len(df_mapeamento)}")
    
    # Criar dicionário de mapeamento geocode -> cidade
    mapeamento_geocode = dict(zip(df_mapeamento['geocode'], df_mapeamento['cidade']))
    print(f"   - Exemplo de mapeamento: {list(mapeamento_geocode.items())[:3]}")
    
    # 3. Padronizar formato das colunas
    print("\n3. Padronizando formato das colunas...")
    
    # Converter coluna date para datetime
    df_clima['date'] = pd.to_datetime(df_clima['date'])
    
    # Criar colunas year, month, day
    df_clima['year'] = df_clima['date'].dt.year
    df_clima['month'] = df_clima['date'].dt.month
    df_clima['day'] = df_clima['date'].dt.day
    
    # Renomear colunas para o padrão MVSE
    df_padronizado = df_clima.rename(columns={
        'temp_med': 'T',
        'rel_humid_med': 'H', 
        'precip_tot': 'R'
    })
    
    # Selecionar e reordenar colunas no formato desejado
    colunas_finais = ['geocode', 'year', 'month', 'day', 'date', 'T', 'H', 'R']
    df_padronizado = df_padronizado[colunas_finais]
    
    print(f"   - Formato padronizado: {list(df_padronizado.columns)}")
    print(f"   - Exemplo de dados:")
    print(df_padronizado.head(3))
    
    # 4. Substituir geocodes por nomes das cidades
    print("\n4. Substituindo geocodes por nomes das cidades...")
    
    # Mapear geocodes para cidades
    df_padronizado['cidade'] = df_padronizado['geocode'].map(mapeamento_geocode)
    
    # Verificar se há geocodes não mapeados
    geocodes_nao_mapeados = df_padronizado[df_padronizado['cidade'].isna()]['geocode'].unique()
    if len(geocodes_nao_mapeados) > 0:
        print(f"   - ATENÇÃO: {len(geocodes_nao_mapeados)} geocodes não foram mapeados:")
        print(f"     {geocodes_nao_mapeados[:10]}...")  # Mostrar apenas os primeiros 10
    
    # Remover registros sem mapeamento
    df_final = df_padronizado.dropna(subset=['cidade']).copy()
    print(f"   - Registros após mapeamento: {len(df_final)}")
    
    # Substituir coluna geocode pela cidade
    df_final = df_final.drop('geocode', axis=1)
    df_final = df_final[['cidade', 'year', 'month', 'day', 'date', 'T', 'H', 'R']]
    
    # 5. Criar pasta de saída
    print(f"\n5. Criando pasta de saída: {pasta_saida}")
    os.makedirs(pasta_saida, exist_ok=True)
    
    # 6. Criar CSVs individuais para cada cidade
    print("\n6. Criando CSVs individuais para cada cidade...")
    
    cidades_unicas = df_final['cidade'].unique()
    print(f"   - Total de cidades: {len(cidades_unicas)}")
    
    cidades_processadas = []
    
    for i, cidade in enumerate(cidades_unicas, 1):
        # Filtrar dados da cidade
        dados_cidade = df_final[df_final['cidade'] == cidade].copy()
        
        # Remover coluna cidade do CSV final (não é necessária no arquivo individual)
        dados_cidade_final = dados_cidade.drop('cidade', axis=1)
        
        # Reordenar para o formato final: year,month,day,date,T,H,R
        dados_cidade_final = dados_cidade_final[['year', 'month', 'day', 'date', 'T', 'H', 'R']]
        
        # Nome do arquivo (limpar caracteres especiais)
        nome_arquivo = cidade.replace(' ', '_').replace('/', '_').replace('\\', '_')
        nome_arquivo = nome_arquivo.replace('ã', 'a').replace('ç', 'c').replace('é', 'e')
        nome_arquivo = nome_arquivo.replace('í', 'i').replace('ó', 'o').replace('ú', 'u')
        nome_arquivo = nome_arquivo.replace('â', 'a').replace('ê', 'e').replace('ô', 'o')
        nome_arquivo = nome_arquivo.replace('à', 'a').replace('õ', 'o')
        
        caminho_arquivo = os.path.join(pasta_saida, f"{nome_arquivo}.csv")
        
        # Salvar CSV
        dados_cidade_final.to_csv(caminho_arquivo, index=False)
        
        cidades_processadas.append({
            'cidade': cidade,
            'arquivo': f"{nome_arquivo}.csv",
            'registros': len(dados_cidade_final),
            'periodo': f"{dados_cidade_final['date'].min().strftime('%Y-%m-%d')} a {dados_cidade_final['date'].max().strftime('%Y-%m-%d')}"
        })
        
        if i % 20 == 0:  # Mostrar progresso a cada 20 cidades
            print(f"   - Processadas {i}/{len(cidades_unicas)} cidades...")
    
    print(f"\n✅ PROCESSAMENTO CONCLUÍDO!")
    print(f"   - Total de cidades processadas: {len(cidades_processadas)}")
    print(f"   - Pasta de saída: {pasta_saida}")
    print(f"   - Formato final dos CSVs: year,month,day,date,T,H,R")
    
    # Salvar relatório de processamento
    df_relatorio = pd.DataFrame(cidades_processadas)
    caminho_relatorio = os.path.join(pasta_saida, "relatorio_processamento.csv")
    df_relatorio.to_csv(caminho_relatorio, index=False)
    print(f"   - Relatório salvo em: {caminho_relatorio}")
    
    # Mostrar algumas estatísticas
    print(f"\n📊 ESTATÍSTICAS:")
    print(f"   - Registros por cidade (média): {df_relatorio['registros'].mean():.0f}")
    print(f"   - Registros por cidade (min): {df_relatorio['registros'].min()}")
    print(f"   - Registros por cidade (max): {df_relatorio['registros'].max()}")
    
    print(f"\n📋 PRIMEIRAS 10 CIDADES PROCESSADAS:")
    for i, cidade_info in enumerate(cidades_processadas[:10]):
        print(f"   {i+1:2d}. {cidade_info['cidade']:25} -> {cidade_info['arquivo']:30} ({cidade_info['registros']:4d} registros)")
    
    return pasta_saida, cidades_processadas

if __name__ == "__main__":
    pasta_saida, cidades_processadas = processar_dados_para_mvse()