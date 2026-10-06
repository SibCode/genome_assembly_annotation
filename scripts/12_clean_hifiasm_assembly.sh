#!/usr/bin/env bash
#SBATCH --job-name=run_clean_hifiasm_assembly_Altai05
#SBATCH --output=/data/users/sbertschinger/genome_assembly_annotation/logs/12_clean_hifiasm_assembly/clean_hifiasm_assembly_output_%j.out
#SBATCH --error=/data/users/sbertschinger/genome_assembly_annotation/logs/12_clean_hifiasm_assembly/clean_hifiasm_assembly_error_%j.err
#SBATCH --cpus-per-task=16
#SBATCH --mail-user=simon.bertschinger@students.unibe.ch
#SBATCH --mail-type=fail,end
#SBATCH --mem=64G
#SBATCH --time=1-00:00:00
#SBATCH --partition=pibu_el8

# PATHS
INPUT_DIR=/data/users/sbertschinger/genome_assembly_annotation/outputs/05_run_clean_hifi/
OUTPUT_DIR=/data/users/sbertschinger/genome_assembly_annotation/outputs/12_clean_hifiasm_assembly/

# GENOME SIZE
# Based on GenomeScope 2.0: ~153.5 Mb
GENOME_SIZE="153.5m" 

# Define the output prefix since hifiasm needs a prefix, not just a dir
OUT_PREFIX="$OUTPUT_DIR/Altai05"

echo "=== Starting Clean Hifiasm assembly for Altai-05 at $(date) ==="

# Run Hifiasm
# Hifiasm auto-detects HiFi reads. 
# -t: Threads
# -o: Output prefix (file name without extension)
# -l: Log level (optional, default is usually fine)
echo "Running clean hifiasm..."
apptainer exec --bind /data /containers/apptainer/hifiasm_0.25.0.sif hifiasm \
    -t "$SLURM_CPUS_PER_TASK" \
    -o "$OUT_PREFIX" \
    "$INPUT_DIR"/*.fastq.gz

# Check if hifiasm succeeded
if [ $? -ne 0 ]; then
    echo "=== ERROR: Clean Hifiasm assembly failed at $(date) ==="
    exit 1
fi

echo "=== Clean Hifiasm pipeline completed successfully at $(date) ==="
echo "Primary Assembly located at: $PRIMARY_FA"
