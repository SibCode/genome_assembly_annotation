#!/usr/bin/env bash
#SBATCH --job-name=run_quast_combined_Altai05
#SBATCH --output=/data/users/sbertschinger/genome_assembly_annotation/logs/24_run_quast_without_ref/quast_combined_output_%j.out
#SBATCH --error=/data/users/sbertschinger/genome_assembly_annotation/logs/24_run_quast_without_ref/quast_combined_error_%j.err
#SBATCH --cpus-per-task=16
#SBATCH --mail-user=simon.bertschinger@students.unibe.ch
#SBATCH --mail-type=fail,end
#SBATCH --mem=64G
#SBATCH --time=02:00:00
#SBATCH --partition=pshort_el8

# --- PATHS ---
# Input Assemblies
INPUT_FLYE=/data/users/sbertschinger/genome_assembly_annotation/outputs/06_flye_assembly/assembly.fasta
INPUT_LJA=/data/users/sbertschinger/genome_assembly_annotation/outputs/08_lja_assembly/assembly.fasta
INPUT_HIFIASM=/data/users/sbertschinger/genome_assembly_annotation/outputs/10_hifiasm_conversion/Altai05.bp.p_ctg.fa

# Output Directory
OUTPUT_BASE=/data/users/sbertschinger/genome_assembly_annotation/outputs/24_run_quast_without_ref/

# Container
CONTAINER=/containers/apptainer/quast_5.2.0.sif

# --- CONFIGURATION ---
THREADS="$SLURM_CPUS_PER_TASK"
OUT_DIR="$OUTPUT_BASE/comparison_all"

echo "=== Starting Combined QUAST without reference for Altai-05 at $(date) ==="

# Create output directory
mkdir -p "$OUT_DIR"

# Change to output directory to keep temp files organized
cd "$OUT_DIR" || exit 1

apptainer exec --bind /data "$CONTAINER" quast.py \
    --eukaryote \
    --threads "$THREADS" \
    --labels "Flye,Hifiasm,LJA" \
    -o "$OUT_DIR" \
    "$INPUT_FLYE" \
    "$INPUT_HIFIASM" \
    "$INPUT_LJA"

echo "=== QUAST completed successfully at $(date) ==="
