#!/bin/bash

# A script that edits mature.fa converting U to T and extracting only human miRNAs

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT/reference"

sed '/^[^>]/s/U/T/g mature.fa > mature_converted.fa

grep "Homo sapiens" mature.fa -A 1 | grep -v "\--" > human_mature_converted.fa
