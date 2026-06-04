#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Directories for hg38 alignments
input_hg38="$PROJECT_ROOT/data/alignments/hg38/bam"
output_hg38="$PROJECT_ROOT/results/alignment_reports/hg38"
# Directories for miRBase alignments
input_miRBase="$PROJECT_ROOT/data/alignments/miRBase/bam"
output_miRBase="$PROJECT_ROOT/results/alignment_reports/miRBase"

# Processing hg38 alignments
for d in "$input_hg38"/*; do
    if [ -d "$d" ]; then
        dirname=$(basename "$d")
        mkdir -p "$output_hg38/$dirname"
        for f in "$d"/*; do
            if [ "$(basename "$f")" == "nondedup" ]; then
                for file in "$f"/*.bam; do
                    if [ -f "$file" ]; then
                        qualimap bamqc -bam "$file" -outdir "$output_hg38/$dirname/$(basename "${file%.*}")" -outformat HTML -nt 8
                    fi
                done
            fi
        done
    fi
done

#Processing miRBase aligments
for d in "$input_miRBase"/*; do
    if [ -d "$d" ]; then
        dirname=$(basename "$d")
        mkdir -p "$output_miRBase/$dirname"
        for f in "$d"/*; do
            if [ "$(basename "$f")" == "nondedup" ]; then
                for file in "$f"/*.bam; do
                    if [ -f "$file" ]; then
                        qualimap bamqc -bam "$file" -outdir "$output_miRBase/$dirname/$(basename "${file%.*}")" -outformat HTML -nt 8
                    fi
                done
            fi
        done
    fi
done

echo "Qualimap analysis completed"

