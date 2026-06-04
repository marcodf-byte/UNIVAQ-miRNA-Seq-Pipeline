#!/bin/bash

# A script that generates fastqc and multiqc reports of fastq.gz files

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Fastq.gz input directory
fastq_input_dir="$PROJECT_ROOT/data/raw"
# Fastqc reports output directory
fastqc_output_dir="$PROJECT_ROOT/results/fastqc_reports"
# Multiqc reports output directory
multiqc_output_dir="$PROJECT_ROOT/results/multiqc_reports"

for d in "$fastq_input_dir"/*; do
	if [ -d "$d" ]; then
		dirname=$(basename "$d")
		for file in "$d"/*.fastq.gz; do
			mkdir -p "$fastqc_output_dir/$dirname"
			fastqc -t 4 -o "$fastqc_output_dir/$dirname" "$file"
		done
	fi
done

for d in "$fastqc_output_dir"/*; do
	if [ -d "$d" ]; then
		dirname=$(basename "$d")
		multiqc -o "$multiqc_output_dir/$dirname" "$d"
	fi
done

echo "quality check completed"

