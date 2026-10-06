#!/usr/bin/env bash
#SBATCH --job-name=run_clean_flye_assembly
#SBATCH --output=/data/users/sbertschinger/genome_assembly_annotation/logs/11_clean_flye_assembly/clean_flye_assembly_output_%j.out
#SBATCH --error=/data/users/sbertschinger/genome_assembly_annotation/logs/11_clean_flye_assembly/clean_flye_assembly_error_%j.err
#SBATCH --cpus-per-task=16
#SBATCH --mail-user=simon.bertschinger@students.unibe.ch
#SBATCH --mail-type=fail,end
#SBATCH --mem=64G
#SBATCH --time=1-00:00:00
#SBATCH --partition=pibu_el8


# PATHS
INPUT_DIR=/data/users/sbertschinger/genome_assembly_annotation/outputs/05_run_clean_hifi/
OUTPUT_DIR=/data/users/sbertschinger/genome_assembly_annotation/outputs/11_clean_flye_assembly/

# GENOME SIZE ADJUSTMENT
# Based on GenomeScope 2.0: Haploid Length ~153.5 Mb (153,528,153 bp)
GENOME_SIZE="153.5m" 

echo "=== Starting Clean Flye assembly at $(date) ==="

apptainer exec --bind /data /containers/apptainer/flye_2.9.5.sif flye \
    --pacbio-hifi "$INPUT_DIR"/*.fastq.gz \
    --out-dir "$OUTPUT_DIR" \
    --threads "$SLURM_CPUS_PER_TASK" \
    --genome-size "$GENOME_SIZE"

# Check exit status
if [ $? -eq 0 ]; then
    echo "=== Clean Flye assembly completed successfully at $(date) ==="
else
    echo "=== ERROR: Clean Flye assembly failed at $(date) ==="
    exit 1
fi
