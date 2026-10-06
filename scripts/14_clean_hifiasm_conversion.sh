#!/usr/bin/env bash
#SBATCH --job-name=run_clean_hifiasm_conversion_Altai05_fixed
#SBATCH --output=/data/users/sbertschinger/genome_assembly_annotation/logs/14_hifiasm_conversion/clean_hifiasm_conversion_output_%j.out
#SBATCH --error=/data/users/sbertschinger/genome_assembly_annotation/logs/14_hifiasm_conversion/clean_hifiasm_conversion_error_%j.err
#SBATCH --cpus-per-task=1
#SBATCH --mail-user=simon.bertschinger@students.unibe.ch
#SBATCH --mail-type=fail,end
#SBATCH --mem=4G
#SBATCH --time=01:00:00
#SBATCH --partition=pibu_el8

# PATHS
INPUT_DIR=/data/users/sbertschinger/genome_assembly_annotation/outputs/12_clean_hifiasm_assembly/
OUTPUT_DIR=/data/users/sbertschinger/genome_assembly_annotation/outputs/14_hifiasm_conversion/

# Define the prefix
PREFIX="Altai05"

PRIMARY_GFA="${INPUT_DIR}/${PREFIX}.bp.p_ctg.gfa"
ALT_GFA="${INPUT_DIR}/${PREFIX}.bp.a_ctg.gfa"

PRIMARY_FA="${OUTPUT_DIR}/${PREFIX}.bp.p_ctg.fa"
ALT_FA="${OUTPUT_DIR}/${PREFIX}.bp.a_ctg.fa"

echo "=== Starting Clean Hifiasm GFA to FASTA conversion at $(date) ==="
echo "Input Directory: $INPUT_DIR"
echo "Output Directory: $OUTPUT_DIR"
echo "Target Primary GFA: $PRIMARY_GFA"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Debug: List available .gfa files
echo "--- Checking for GFA files in $INPUT_DIR ---"
ls -lh "${INPUT_DIR}"/*.gfa 2>/dev/null || echo "No .gfa files found!"

# Convert Primary Contigs
if [ -f "$PRIMARY_GFA" ]; then
    echo "Converting Primary Contigs: $PRIMARY_GFA -> $PRIMARY_FA"
    awk '/^S/{print ">"$2;print $3}' "$PRIMARY_GFA" > "$PRIMARY_FA"
    
    if [ -s "$PRIMARY_FA" ]; then
        COUNT=$(grep -c "^>" "$PRIMARY_FA")
        echo "SUCCESS: Converted $COUNT sequences to $PRIMARY_FA"
        echo "File size: $(du -h $PRIMARY_FA | cut -f1)"
    else
        echo "ERROR: Output file is empty."
        exit 1
    fi
else
    echo "ERROR: Primary contig GFA file not found: $PRIMARY_GFA"
    echo "Available files:"
    ls -1 "${INPUT_DIR}"/*.gfa
    exit 1
fi

# Convert Alternate Haplotigs if they exist
if [ -f "$ALT_GFA" ]; then
    echo "Converting Alternate Haplotigs: $ALT_GFA -> $ALT_FA"
    awk '/^S/{print ">"$2;print $3}' "$ALT_GFA" > "$ALT_FA"
    
    if [ -s "$ALT_FA" ]; then
        COUNT=$(grep -c "^>" "$ALT_FA")
        echo "SUCCESS: Converted $COUNT alternate sequences to $ALT_FA"
    else
        echo "WARNING: Alternate output file is empty."
    fi
else
    echo "INFO: No alternate haplotigs found ($ALT_GFA). Skipping."
fi

echo "=== Conversion completed successfully at $(date) ==="
echo "Final Assembly located at: $PRIMARY_FA"