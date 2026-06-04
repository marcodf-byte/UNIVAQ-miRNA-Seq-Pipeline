#!/bin/bash

# Define the directory containing the scripts
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="$PROJECT_ROOT/scripts"

# Run the scripts in the specified order
bash "$SCRIPT_DIR/quality_before_trimming.sh"
bash "$SCRIPT_DIR/trimming.sh"
bash "$SCRIPT_DIR/quality_after_trimming.sh"
bash "$SCRIPT_DIR/convert.sh"
bash "$SCRIPT_DIR/align_to_miRBase.sh"
bash "$SCRIPT_DIR/align_to_hg38.sh"
bash "$SCRIPT_DIR/qualimap.sh"
bash "$SCRIPT_DIR/rename.sh"
bash "$SCRIPT_DIR/miRBase_counts.sh"
bash "$SCRIPT_DIR/hg38_featurecounts.sh"
python3 "$SCRIPT_DIR/mergeCounts.py"
Rscript "$SCRIPT_DIR/dea.R"

echo "All scripts executed successfully."
