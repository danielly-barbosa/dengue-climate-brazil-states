import csv
import os
from datetime import datetime


pasta_saida = "..\\dados_mvse_cidades_tempMin"
os.makedirs(pasta_saida, exist_ok=True)


cidades_dados = {}


print("Lendo arquivo climate_pe_pos_2016_2.csv...")
with open('..\\ZENODO\\infodengue_sprint_24-25\\climate_pe_pos_2016_2.csv', 'r', encoding='utf-8') as arquivo:
    leitor = csv.reader(arquivo)


    cabeçalho = next(leitor)
    print(f"Colunas disponíveis: {cabeçalho}")


    linhas_processadas = 0
    for linha in leitor:
        if len(linha) > 2:
            geocode = linha[2]


            data = linha[0]
            temp_min = linha[3]
            precip_tot = linha[9]
            rel_humid_med = linha[14]


            if geocode not in cidades_dados:
                cidades_dados[geocode] = []


            cidades_dados[geocode].append({
                'data': data,
                'cidade': geocode,
                'umidade': rel_humid_med,
                'temperatura': temp_min,
                'precipitacao': precip_tot
            })

        linhas_processadas += 1
        if linhas_processadas % 10000 == 0:
            print(f"Processadas {linhas_processadas} linhas...")

print(f"Processamento concluído! Total de linhas processadas: {linhas_processadas}")
print(f"Total de cidades de Pernambuco encontradas: {len(cidades_dados)}")


print("\nLendo arquivo de mapeamento cidade-geocode...")
mapeamento_cidades = {}
with open('..\\ZENODO\\pernambuco\\pernambuco\\indexP\\tratamento\\cidade_Mesorregiao_atualizado.csv', 'r', encoding='utf-8') as arquivo_map:
    leitor_map = csv.DictReader(arquivo_map)
    for linha in leitor_map:
        geocode = linha['geocode']
        nome_cidade = linha['cidade'].lower().replace(' ', '_').replace('-', '_')
        mapeamento_cidades[geocode] = nome_cidade

print("\nCriando arquivos CSV individuais com temp_min...")
for geocode, dados in cidades_dados.items():

    dados_ordenados = sorted(dados, key=lambda x: x['data'])


    nome_cidade = mapeamento_cidades.get(geocode, f"cidade_{geocode}")
    nome_arquivo = f"{nome_cidade}.csv"
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
print("✓ USANDO TEMPERATURA MÍNIMA (temp_min) ao invés de temperatura média")


print(f"\nEstatísticas:")
for geocode in sorted(list(cidades_dados.keys()))[:5]:
    nome_cidade = mapeamento_cidades.get(geocode, f"cidade_{geocode}")
    print(f"- {nome_cidade} ({geocode}): {len(cidades_dados[geocode])} registros")

print(f"\nExemplo de estrutura dos arquivos:")
if cidades_dados:
    geocode_exemplo = list(cidades_dados.keys())[0]
    nome_cidade_exemplo = mapeamento_cidades.get(geocode_exemplo, f"cidade_{geocode_exemplo}")
    print(f"Arquivo: {nome_cidade_exemplo}.csv")
    print("Colunas: data, cidade, umidade, temperatura (temp_min), precipitacao")
    print(f"Primeira linha de dados: {cidades_dados[geocode_exemplo][0]}")