#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

directories_hg38=("$PROJECT_ROOT/data/alignments/hg38/bam/run1" "$PROJECT_ROOT/data/alignments/hg38/bam/run2" "$PROJECT_ROOT/data/alignments/hg38/bam/run3")
directories_miRBase=("$PROJECT_ROOT/data/alignments/miRBase/bam/run1" "$PROJECT_ROOT/data/alignments/miRBase/bam/run2" "$PROJECT_ROOT/data/alignments/miRBase/bam/run3")

n=1
for directory in "${directories_hg38[@]}"; do
  cd "$directory"
  
  for file in *.bam; do
    base_name=$(basename "$file")
    # Extracting the sample name using cut and adding a prefix to keep trace of the run
    sample_name=$n"-"$(echo "$base_name" | cut -d'_' -f4 | cut -d'-' -f2)
    new_name="${sample_name}.bam"
    echo "$new_name"
    mv "$file" "$new_name"
  done
  
  n=$((n+1))
done

n=1
for directory in "${directories_hg38[@]}"; do
  cd "$directory"
  
  for file in *.bam.bai; do
    base_name=$(basename "$file")
    # Extracting the sample name using cut and adding a prefix to keep trace of the run
    sample_name=$n"-"$(echo "$base_name" | cut -d'_' -f4 | cut -d'-' -f2)
    new_name="${sample_name}.bam.bai"
    echo "$new_name"
    mv "$file" "$new_name"
  done
  
  n=$((n+1))
done

n=1
for directory in "${directories_miRBase[@]}"; do
  cd "$directory"
  
  for file in *.bam; do
    base_name=$(basename "$file")
    # Extracting the sample name using cut and adding a prefix to keep trace of the run
    sample_name=$n"-"$(echo "$base_name" | cut -d'_' -f3 | cut -d'-' -f2)
    new_name="${sample_name}.bam"
    echo "$new_name"
    mv "$file" "$new_name"
  done
  
  n=$((n+1))
done

n=1
for directory in "${directories_miRBase[@]}"; do
  cd "$directory"
  
  for file in *.bam.bai; do
    base_name=$(basename "$file")
    # Extracting the sample name using cut and adding a prefix to keep trace of the run
    sample_name=$n"-"$(echo "$base_name" | cut -d'_' -f3 | cut -d'-' -f2)
    new_name="${sample_name}.bam.bai"
    echo "$new_name"
    mv "$file" "$new_name"
  done
  
  n=$((n+1))
done


