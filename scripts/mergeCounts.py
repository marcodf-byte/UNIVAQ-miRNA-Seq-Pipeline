import os
import pandas as pd

# Get the project root directory
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(script_dir)

# Load .tsv files
hg38_path = os.path.join(project_root, 'results', 'counts', 'hg38', 'combined_featurecounts.tsv')
miRBase_path = os.path.join(project_root, 'results', 'counts', 'miRBase', 'combined_counts.tsv')
hg38 = pd.read_csv(hg38_path, sep='\t')
miRBase = pd.read_csv(miRBase_path, sep='\t')

# Set 'mirnaID' as index for both tables
hg38.set_index('GeneID', inplace=True)
miRBase.set_index('GeneID', inplace=True)

# Sum the two tables and keep the values from miRBase where summation is not possible
summed_df = hg38.add(miRBase, fill_value=0).combine_first(miRBase)

# Convert the values to integers
summed_df = summed_df.astype(int)

# Reset the index
summed_df.reset_index(inplace=True)

# Save the result in a new .tsv file
output_path = os.path.join(project_root, 'results', 'counts', 'summed_results.tsv')
summed_df.to_csv(output_path, sep='\t', index=False)