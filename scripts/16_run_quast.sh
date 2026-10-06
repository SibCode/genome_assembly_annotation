#!/usr/bin/env bash
#SBATCH --job-name=run_quast_combined_Altai05
#SBATCH --output=/data/users/sbertschinger/genome_assembly_annotation/logs/16_run_quast/quast_combined_output_%j.out
#SBATCH --error=/data/users/sbertschinger/genome_assembly_annotation/logs/16_run_quast/quast_combined_error_%j.err
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

# Reference Data (Arabidopsis thaliana TAIR10)
REF_GENOME=/data/courses/assembly-annotation-course/references/Arabidopsis_thaliana.TAIR10.dna.toplevel.fa
REF_GFF=/data/courses/assembly-annotation-course/references/Arabidopsis_thaliana.TAIR10.57.gff3

# Output Directory
OUTPUT_BASE=/data/users/sbertschinger/genome_assembly_annotation/outputs/16_run_quast/

# Container
CONTAINER=/containers/apptainer/quast_5.2.0.sif

# --- CONFIGURATION ---
THREADS="$SLURM_CPUS_PER_TASK"
OUT_DIR="$OUTPUT_BASE/comparison_all"

echo "=== Starting Combined QUAST for Altai-05 at $(date) ==="

# Create output directory
mkdir -p "$OUT_DIR"

# Change to output directory to keep temp files organized
cd "$OUT_DIR" || exit 1

# Check if reference exists
if [ ! -f "$REF_GENOME" ]; then
    echo "ERROR: Reference genome not found at $REF_GENOME"
    exit 1
fi

# --- RUN SINGLE COMPARISON JOB ---
# We pass all assemblies at once. 
# --labels must correspond to the order of assemblies provided.
# -R adds the reference for alignment-based metrics (NGA50, misassemblies).
# -g adds gene-level statistics.
# --eukaryote optimizes for eukaryotic genomes.

apptainer exec --bind /data "$CONTAINER" quast.py \
    --eukaryote \
    --threads "$THREADS" \
    --labels "Flye,Hifiasm,LJA" \
    -R "$REF_GENOME" \
    -g "$REF_GFF" \
    -o "$OUT_DIR" \
    "$INPUT_FLYE" \
    "$INPUT_HIFIASM" \
    "$INPUT_LJA"

echo "=== QUAST completed successfully at $(date) ==="
