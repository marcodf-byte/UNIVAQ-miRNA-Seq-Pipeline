#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

input_dir="$PROJECT_ROOT/data/alignments/miRBase/bam"
output_dir="$PROJECT_ROOT/results/counts/miRBase"
output_file="$output_dir/combined_counts.tsv"

# Create the output directory if it does not exist
mkdir -p "$output_dir"

# Initialize the header and sample file array
header="GeneID"
temp_files=()

# Collect BAM files and sample names
for d in "$input_dir"/*; do
    if [ -d "$d" ]; then
        for file in "$d"/*.bam; do
            if [ -f "$file" ]; then
                sample_name=$(basename "$file" .bam)
                temp_file="$output_dir/${sample_name}_counts.tsv"
                temp_files+=("$temp_file")
                header="$header\t$sample_name"
                
                # Run samtools idxstats, remove the line with *, and format output
                samtools idxstats "$file" | grep -v -P '^\*\t' | cut -f 1,3 - | sort -k1,1 > "$temp_file"
                echo "Counting completed for $sample_name"
            fi
        done
    fi
done

# Initialize the combined output file with the header
echo -e "$header" > "$output_file"

# Extract and merge counts
# Create a list of unique GeneIDs from all temporary files
cat "${temp_files[@]}" | cut -f 1 | sort | uniq > "$output_dir/all_geneids.txt"

# Initialize the combined counts file with the GeneIDs
cp "$output_dir/all_geneids.txt" "$output_dir/combined_counts_temp.tsv"

# Add each sample's counts to the combined file
for temp_file in "${temp_files[@]}"; do
    sample_name=$(basename "$temp_file" _counts.tsv)
    join -a1 -a2 -e 0 -o auto -t $'\t' "$output_dir/combined_counts_temp.tsv" "$temp_file" > "$output_dir/combined_counts_temp2.tsv"
    mv "$output_dir/combined_counts_temp2.tsv" "$output_dir/combined_counts_temp.tsv"
done

# Sort the final output by GeneID and add the header
sort -k1,1 "$output_dir/combined_counts_temp.tsv" >> "$output_file"

# Clean up temporary files
rm "${temp_files[@]}" "$output_dir/all_geneids.txt" "$output_dir/combined_counts_temp.tsv"

echo "Processing and merging completed"



