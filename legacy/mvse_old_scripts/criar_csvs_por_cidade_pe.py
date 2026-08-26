import csv
import os
from datetime import datetime

# Criar pasta para armazenar os CSVs das cidades
pasta_saida = "d:\\CÓDIGOS\\cidades_pernambuco_individuais"
os.makedirs(pasta_saida, exist_ok=True)

# Dicionário para armazenar dados por cidade
cidades_dados = {}

# Ler o arquivo climate.csv e filtrar por Pernambuco
print("Lendo arquivo climate.csv...")
with open('d:\\CÓDIGOS\\ZENODO\\infodengue_sprint_24-25\\climate.csv\\climate.csv', 'r', encoding='utf-8') as arquivo:
    leitor = csv.reader(arquivo)
    
    # Ler cabeçalho
    cabeçalho = next(leitor)
    print(f"Colunas disponíveis: {cabeçalho}")
    
    # Processar cada linha
    linhas_processadas = 0
    for linha in leitor:
        if len(linha) > 2:  # Verificar se há geocode na linha
            geocode = linha[2]  # Terceira coluna é o geocode
            
            # Verificar se é de Pernambuco (começa com 26)
            if geocode.startswith('26'):
                # Extrair dados relevantes
                data = linha[0]  # data
                temp_med = linha[4]  # temp_med (temperatura média)
                precip_tot = linha[9]  # precip_tot (precipitação total)
                rel_humid_med = linha[13]  # rel_humid_med (umidade relativa média)
                
                # Se a cidade ainda não está no dicionário, adicionar
                if geocode not in cidades_dados:
                    cidades_dados[geocode] = []
                
                # Adicionar dados à cidade
                cidades_dados[geocode].append({
                    'data': data,
                    'cidade': geocode,
                    'umidade': rel_humid_med,
                    'temperatura': temp_med,
                    'precipitacao': precip_tot
                })
        
        linhas_processadas += 1
        if linhas_processadas % 100000 == 0:
            print(f"Processadas {linhas_processadas} linhas...")

print(f"Processamento concluído! Total de linhas processadas: {linhas_processadas}")
print(f"Total de cidades de Pernambuco encontradas: {len(cidades_dados)}")

# Criar CSV individual para cada cidade
print("\nCriando arquivos CSV individuais...")
for geocode, dados in cidades_dados.items():
    # Ordenar por data
    dados_ordenados = sorted(dados, key=lambda x: x['data'])
    
    # Nome do arquivo
    nome_arquivo = f"clima_{geocode}.csv"
    caminho_arquivo = os.path.join(pasta_saida, nome_arquivo)
    
    # Escrever CSV
    with open(caminho_arquivo, 'w', newline='', encoding='utf-8') as arquivo_saida:
        escritor = csv.writer(arquivo_saida)
        
        # Escrever cabeçalho
        escritor.writerow(['data', 'cidade', 'umidade', 'temperatura', 'precipitacao'])
        
        # Escrever dados
        for dado in dados_ordenados:
            escritor.writerow([
                dado['data'],
                dado['cidade'],
                dado['umidade'],
                dado['temperatura'],
                dado['precipitacao']
            ])
    
    print(f"Criado: {nome_arquivo} com {len(dados)} registros")

print(f"\n✓ Todos os arquivos foram criados na pasta: {pasta_saida}")
print(f"✓ Total de cidades processadas: {len(cidades_dados)}")

# Mostrar estatísticas
print(f"\nEstatísticas:")
for geocode in sorted(list(cidades_dados.keys()))[:5]:
    print(f"- Cidade {geocode}: {len(cidades_dados[geocode])} registros")

print(f"\nExemplo de estrutura dos arquivos:")
if cidades_dados:
    geocode_exemplo = list(cidades_dados.keys())[0]
    print(f"Arquivo: clima_{geocode_exemplo}.csv")
    print("Colunas: data, cidade, umidade, temperatura, precipitacao")
    print(f"Primeira linha de dados: {cidades_dados[geocode_exemplo][0]}")