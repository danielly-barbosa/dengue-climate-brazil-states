import csv
import os

input_file = r'infodengue_sprint_24-25/climate.csv/climate.csv'
output_file = r'goias/mvse/outputs/goias_climate.csv'

os.makedirs(os.path.dirname(output_file), exist_ok=True)

with open(input_file, 'r', newline='', encoding='utf-8') as infile, \
     open(output_file, 'w', newline='', encoding='utf-8') as outfile:
    reader = csv.DictReader(infile)
    fieldnames = reader.fieldnames
    writer = csv.DictWriter(outfile, fieldnames=fieldnames)
    writer.writeheader()
    count = 0
    for row in reader:
        geocode = row.get('geocode', '')
        if str(geocode).startswith('52'):
            writer.writerow(row)
            count += 1
print(f'Filtered {count} rows for Goiás (52) to {output_file}')