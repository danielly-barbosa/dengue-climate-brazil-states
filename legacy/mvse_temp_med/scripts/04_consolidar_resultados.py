import pandas as pd
import os
import json
from pathlib import Path

def main():

    diretorio_indexP = r"..\indexP_tempMed_humMed"


    arquivo_saida = r"..\indexP_tempMed_humMed_consolidado.csv"


    arquivo_geojson = r"..\PERNAMBUCO\geojs-26-mun.json"

    if not os.path.exists(arquivo_geojson):
        print(f"❌ Arquivo de mapeamento não encontrado: {arquivo_geojson}")
        return


    print("Carregando mapeamento de geocodes do GeoJSON...")
    with open(arquivo_geojson, 'r', encoding='utf-8') as f:
        geojson_data = json.load(f)


    mapeamento = {}
    for feature in geojson_data['features']:
        geocode = feature['properties']['id']
        cidade = feature['properties']['cidade']
        mapeamento[geocode] = cidade

    print(f"Mapeamento carregado: {len(mapeamento)} cidades")


    dados_consolidados = []


    print("Processando arquivos indexP...")

    geocodes_processados = []
    for item in os.listdir(diretorio_indexP):
        caminho_item = os.path.join(diretorio_indexP, item)

        if os.path.isdir(caminho_item):
            geocode = item
            arquivo_csv = os.path.join(caminho_item, f"{geocode}.estimated_indexP.csv")

            if os.path.exists(arquivo_csv):
                try:

                    df = pd.read_csv(arquivo_csv)


                    df['geocode'] = geocode
                    df['cidade'] = mapeamento.get(geocode, f"cidade_{geocode}")


                    colunas = ['geocode', 'cidade'] + [col for col in df.columns if col not in ['geocode', 'cidade']]
                    df = df[colunas]


                    dados_consolidados.append(df)
                    geocodes_processados.append(geocode)

                    if len(geocodes_processados) % 20 == 0:
                        print(f"  Processados: {len(geocodes_processados)} arquivos")

                except Exception as e:
                    print(f"❌ Erro ao processar {arquivo_csv}: {e}")

    if not dados_consolidados:
        print("❌ Nenhum arquivo foi processado!")
        return


    print("Consolidando dados...")
    df_final = pd.concat(dados_consolidados, ignore_index=True)


    print(f"Salvando arquivo consolidado: {arquivo_saida}")
    df_final.to_csv(arquivo_saida, index=False)


    print(f"\n✓ Consolidação concluída!")
    print(f"  - Total de arquivos processados: {len(geocodes_processados)}")
    print(f"  - Total de registros: {len(df_final):,}")
    print(f"  - Período: {df_final['date'].min()} a {df_final['date'].max()}")
    print(f"  - Arquivo salvo: {arquivo_saida}")

    print(f"\nGeocodes processados:")
    for i, geocode in enumerate(sorted(geocodes_processados)):
        if i % 10 == 0:
            print()
        print(f"  - {geocode}")

    print(f"\nPrimeiras 5 linhas do arquivo consolidado:")
    print(df_final.head().to_string(index=False))

if __name__ == "__main__":
    main()