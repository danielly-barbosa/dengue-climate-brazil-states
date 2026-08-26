import csv
import os
from datetime import datetime


pasta_saida = "..\\cidades_pernambuco_individuais"
os.makedirs(pasta_saida, exist_ok=True)


cidades_dados = {}


print("Lendo arquivo climate.csv...")
with open('..\\ZENODO\\infodengue_sprint_24-25\\climate.csv\\climate.csv', 'r', encoding='utf-8') as arquivo:
    leitor = csv.reader(arquivo)


    cabeçalho = next(leitor)
    print(f"Colunas disponíveis: {cabeçalho}")


    linhas_processadas = 0
    for linha in leitor:
        if len(linha) > 2:
            geocode = linha[2]


            if geocode.startswith('26'):

                data = linha[0]
                temp_med = linha[4]
                precip_tot = linha[9]
                rel_humid_med = linha[13]


                if geocode not in cidades_dados:
                    cidades_dados[geocode] = []


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


print("\nCriando arquivos CSV individuais...")
for geocode, dados in cidades_dados.items():

    dados_ordenados = sorted(dados, key=lambda x: x['data'])


    nome_arquivo = f"clima_{geocode}.csv"
    caminho_arquivo = os.path.join(pasta_saida, nome_arquivo)


    with open(caminho_arquivo, 'w', newline='', encoding='utf-8') as arquivo_saida:
        escritor = csv.writer(arquivo_saida)


        escritor.writerow(['data', 'cidade', 'umidade', 'temperatura', 'precipitacao'])


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


print(f"\nEstatísticas:")
for geocode in sorted(list(cidades_dados.keys()))[:5]:
    print(f"- Cidade {geocode}: {len(cidades_dados[geocode])} registros")

print(f"\nExemplo de estrutura dos arquivos:")
if cidades_dados:
    geocode_exemplo = list(cidades_dados.keys())[0]
    print(f"Arquivo: clima_{geocode_exemplo}.csv")
    print("Colunas: data, cidade, umidade, temperatura, precipitacao")
    print(f"Primeira linha de dados: {cidades_dados[geocode_exemplo][0]}")