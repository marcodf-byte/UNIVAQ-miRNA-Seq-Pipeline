#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

input_fastq_dir="$PROJECT_ROOT/data/alignments/unaligned"
output_sam_dir="$PROJECT_ROOT/data/alignments/hg38/sam"
index_dir="$PROJECT_ROOT/reference/hg38/GRCh38_noalt_as"
output_bam_dir="$PROJECT_ROOT/data/alignments/hg38/bam"

# Process the alignment to reference genome
n=1 
for d in "$input_fastq_dir"/*; do
	if [ -d "$d" ]; then
		dirname="run$n"
		mkdir -p "$output_sam_dir/$dirname"
		n=$((n+1)) 
		for file in "$d"/*.fastq; do
			filename=$(basename "$file")
			echo "$filename alignment started"
			bowtie2 --very-sensitive -N 1 -p 8 -x $index_dir -U $file -S $output_sam_dir/$dirname/$filename.sam
			echo "$filename alignment completed"
		done
	fi
done

echo "Alignment completed"

# Process SAM files for further analysis 
mkdir -p "$output_bam_dir"
n=1
for d in "$output_sam_dir"/*; do
	if [ -d "$d" ]; then
		dirname="run$n"
		mkdir -p "$output_bam_dir/$dirname"
		n=$((n+1))
		for file in "$d"/*.fastq.sam; do
			# Removing .fastq from the filename
			renamed_file="${file/.fastq.sam/.sam}"
			mv "$file" "$renamed_file"
			filename=$(basename "$renamed_file" .sam)
			
			# Converting SAM to BAM
			samtools view -S -b "$renamed_file" > "$output_bam_dir/$dirname/$filename.bam"
			echo "Conversion completed for $filename"
			
			# Sorting BAM files
			samtools sort "$output_bam_dir/$dirname/$filename.bam" -o "$output_bam_dir/$dirname/${filename}_sorted.bam"
			mv "$output_bam_dir/$dirname/${filename}_sorted.bam" "$output_bam_dir/$dirname/$filename.bam"
			echo "Sorting completed for $filename"
			
			# Index the sorted BAM file
			samtools index "$output_bam_dir/$dirname/$filename.bam"
			echo "Index generated for $filename"
			
			# UMI deduplication
			mkdir -p "$output_bam_dir/$dirname/UMI_log"
			mkdir -p "$output_bam_dir/$dirname/nondedup"
umi_tools dedup --method=unique --stdin="$output_bam_dir/$dirname/$filename.bam" --log="$output_bam_dir/$dirname/UMI_log/$filename.log" > "$output_bam_dir/$dirname/${filename}_dedup.bam"
			mv "$output_bam_dir/$dirname/$filename.bam" "$output_bam_dir/$dirname/nondedup/$filename.bam"
			echo "Deduplication completed for $filename"
			
			# Index the deduplicated BAM file
			samtools index "$output_bam_dir/$dirname/${filename}_dedup.bam"
			echo "Index generated for ${filename}_dedup"
						
		done
	fi
done

echo "Processing completed"





