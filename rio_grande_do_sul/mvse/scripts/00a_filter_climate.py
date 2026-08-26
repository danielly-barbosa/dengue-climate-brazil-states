import pandas as pd
import os

# Create the target directory if it doesn't exist
os.makedirs('denovo/rio grande do sul/climate.csv', exist_ok=True)

# Read the source CSV
df = pd.read_csv('infodengue_sprint_24-25/climate.csv/climate.csv')

# Filter rows where geocode starts with '43'
filtered_df = df[df['geocode'].astype(str).str.startswith('43')]

# Write the filtered data to the target CSV
filtered_df.to_csv('denovo/rio grande do sul/climate.csv/rs_climate.csv', index=False)

# Report the number of rows filtered
print(f"Number of rows filtered: {len(filtered_df)}")