import pandas as pd
import os

# Path to the directory containing subdirectories
path = 'santa_catarina/mvse/outputs/indexP_tempMed_humMed/'

# List of subdirectories (geocodes)
subdirs = [d for d in os.listdir(path) if os.path.isdir(os.path.join(path, d))]

# List to hold dataframes
dfs = []

for subdir in subdirs:
    file_path = os.path.join(path, subdir, f"{subdir}.estimated_indexP.csv")
    if os.path.exists(file_path):
        df = pd.read_csv(file_path)
        df['geocode'] = subdir
        dfs.append(df)
    else:
        print(f"File not found: {file_path}")

# Concatenate all dataframes
combined_df = pd.concat(dfs, ignore_index=True)

# Select only the required columns
combined_df = combined_df[['geocode', 'date', 'indexP']]

# Sort by geocode then date
combined_df = combined_df.sort_values(by=['geocode', 'date'])

# Save to the output file
output_path = 'santa_catarina/mvse/outputs/santa_catarina_indexP_combined.csv'
combined_df.to_csv(output_path, index=False)

# Get number of unique geocodes
unique_geocodes = combined_df['geocode'].nunique()
print(f"Number of unique geocodes combined: {unique_geocodes}")