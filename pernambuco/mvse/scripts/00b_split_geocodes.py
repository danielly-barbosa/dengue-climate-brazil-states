import csv
import os
from collections import defaultdict

input_file = r'denovo/pernambuco/climate.csv/pernambuco_climate.csv'
subfolder = r'denovo/pernambuco/climate.csv/geocodes'

os.makedirs(subfolder, exist_ok=True)

data = defaultdict(list)

with open(input_file, 'r', newline='', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        geocode = row['geocode']
        data[geocode].append({
            'date': row['date'],
            'T': row['temp_med'],
            'H': row['rel_humid_med'],
            'R': row['precip_tot']
        })

for geocode, rows in data.items():
    rows.sort(key=lambda x: x['date'])
    output_file = os.path.join(subfolder, f"{geocode}.csv")
    with open(output_file, 'w', newline='', encoding='utf-8') as outf:
        fieldnames = ['date', 'T', 'H', 'R']
        writer = csv.DictWriter(outf, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

print(f'Created {len(data)} CSV files in {subfolder}')