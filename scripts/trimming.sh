#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Paths to your data
input_dir="$PROJECT_ROOT/data/raw"
output_dir="$PROJECT_ROOT/data/trimmedbis"

# Create the output subdirectories scheme and execute trimming for each fastq.gz file in input
for d in "$input_dir"/*; do
    if [ -d "$d" ]; then
        dirname="trim$(basename "$d")"
        for file in "$d"/*.fastq.gz; do
            mkdir -p "$output_dir/$dirname/uncut"
            mkdir -p "$output_dir/$dirname/umi_log"
            filename=$(basename "$file")
            basename="${filename%.fastq.gz}"
            #extraction of the UMI tag sequence and deletion of the adapters
            umi_tools extract --stdin="$file" --log="$output_dir/$dirname/umi_log/${basename}_umiextraction.log" --stdout="$output_dir/$dirname/uncut/${basename}.fastq.gz" --extract-method=regex --bc-pattern='.+(?P<discard_1>AACTGTAGGCACCATCAAT){s<=2}(?P<umi_1>.{12})(?P<discard_2>.+)'
            #removing sequences shorter than 15 nucleotides or longer than 30 nucleotides 
            cutadapt --cores=8 -m 15 -M 30 -o "$output_dir/$dirname/${basename}_m15M30.fastq.gz" "$output_dir/$dirname/uncut/${basename}.fastq.gz"
        done
    fi
done

echo "UMI extraction and trimming completed"

