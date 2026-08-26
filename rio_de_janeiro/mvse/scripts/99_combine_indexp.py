import os
import pandas as pd

# Directory containing the CSV files
dir_path = r"denovo/rio de janeiro/climate.csv/indexP_tempMed_humMed"

# List to store all dataframes
dfs = []

# Iterate through all files in the directory
for root, dirs, files in os.walk(dir_path):
    for file in files:
        if file.endswith('.estimated_indexP.csv'):
            # Read the CSV file
            file_path = os.path.join(root, file)
            df = pd.read_csv(file_path)
            
            # Extract geocode from filename (part before first dot)
            geocode = file.split('.')[0]
            
            # Add geocode column
            df['geocode'] = geocode
            
            # Keep only geocode, date, indexP columns
            df = df[['geocode', 'date', 'indexP']]
            
            # Append to list of dataframes
            dfs.append(df)

# Combine all dataframes
combined_df = pd.concat(dfs, ignore_index=True)

# Sort by geocode then date
combined_df = combined_df.sort_values(['geocode', 'date'])

# Count unique geocodes
unique_geocodes = combined_df['geocode'].nunique()

# Save the combined dataframe
output_path = r"denovo/rio de janeiro/climate.csv/rio de janeiro_indexP_combined.csv"
combined_df.to_csv(output_path, index=False)

print(f"Combined CSV file saved to: {output_path}")
print(f"Number of unique geocodes: {unique_geocodes}")