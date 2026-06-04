#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

input_dir="$PROJECT_ROOT/data/alignments/hg38/bam"
output_dir="$PROJECT_ROOT/results/counts/hg38/featurecounts"
annotation_file="$PROJECT_ROOT/annotation_files/hsa.gff3"
output_file="$output_dir/combined_featurecounts.tsv"

# Create the output directory if it does not exist
mkdir -p "$output_dir"

# Initialize the header and sample file array
header="GeneID"
sample_files=()

# Collect BAM files and sample names
for d in "$input_dir"/*; do
    if [ -d "$d" ]; then
        for file in "$d"/*.bam; do
            if [ -f "$file" ]; then
                sample_name=$(basename "$file" .bam)
                sample_files+=("$file")
                header="$header\t$sample_name"
            fi
        done
    fi
done

# Run featureCounts on all collected BAM files
featureCounts -T 8 -a "$annotation_file" -o "$output_dir/featurecounts.tsv" -g Name -t miRNA "${sample_files[@]}"
echo "featureCounts completed"

# Initialize the combined output file with the header
echo -e "$header" > "$output_file"

# Extract relevant columns and format the output
awk 'NR>2 {print $1}' "$output_dir/featurecounts.tsv" > "$output_dir/temp_GeneID.txt"
cut -f 1,7- "$output_dir/featurecounts.tsv" | tail -n +3 > "$output_dir/temp_counts.tsv"
paste "$output_dir/temp_GeneID.txt" "$output_dir/temp_counts.tsv" | cut -f 1,3- | sort -k1,1 > "$output_dir/sorted_counts.tsv"

# Add the final header to the merged file
echo -e "$header" > "$output_file"
# Append sorted counts to the final output file
cat "$output_dir/sorted_counts.tsv" >> "$output_file"

# Clean up temporary files
rm "$output_dir/temp_GeneID.txt" "$output_dir/temp_counts.tsv" "$output_dir/sorted_counts.tsv"

echo "Processing and merging completed"

