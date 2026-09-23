#!/usr/bin/env bash
#SBATCH --job-name=run_lja_assembly_Altai05
#SBATCH --output=/data/users/sbertschinger/genome_assembly_annotation/logs/08_lja_assembly/lja_assembly_output_%j.out
#SBATCH --error=/data/users/sbertschinger/genome_assembly_annotation/logs/08_lja_assembly/lja_assembly_error_%j.err
#SBATCH --cpus-per-task=16
#SBATCH --mail-user=simon.bertschinger@students.unibe.ch
#SBATCH --mail-type=fail,end
#SBATCH --mem=64G
#SBATCH --time=1-00:00:00
#SBATCH --partition=pibu_el8

# PATHS
INPUT_DIR=/data/users/sbertschinger/genome_assembly_annotation/raw_data/Altai-5/
OUTPUT_DIR=/data/users/sbertschinger/genome_assembly_annotation/outputs/08_lja_assembly/

# GENOME SIZE
# Based on GenomeScope 2.0: ~153.5 Mb
GENOME_SIZE="153.5m" 

echo "=== Starting LJA assembly for Altai-05 at $(date) ==="

apptainer exec --bind /data /containers/apptainer/lja-0.2.sif lja \
    --threads "$SLURM_CPUS_PER_TASK" \
    --output-dir "$OUTPUT_DIR" \
    --reads "$INPUT_DIR"/*.fastq.gz

# Check if LJA succeeded
if [ $? -ne 0 ]; then
    echo "=== ERROR: LJA assembly failed at $(date) ==="
    exit 1
fi

echo "=== LJA assembly finished. ==="
