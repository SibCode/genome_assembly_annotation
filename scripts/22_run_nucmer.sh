#!/usr/bin/env bash
#SBATCH --job-name=run_nucmer_Altai05
#SBATCH --output=/data/users/sbertschinger/genome_assembly_annotation/logs/22_nucmer_analysis/nucmer_output_%j.out
#SBATCH --error=/data/users/sbertschinger/genome_assembly_annotation/logs/22_nucmer_analysis/nucmer_error_%j.err
#SBATCH --cpus-per-task=8
#SBATCH --mail-user=simon.bertschinger@students.unibe.ch
#SBATCH --mail-type=fail,end
#SBATCH --mem=32G
#SBATCH --time=02:00:00
#SBATCH --partition=pshort_el8

# PATHS
REF_GENOME="/data/courses/assembly-annotation-course/references/Arabidopsis_thaliana.TAIR10.dna.toplevel.fa"
ASSEMBLY_DIR=/data/users/sbertschinger/genome_assembly_annotation/outputs/
OUTPUT_DIR=/data/users/sbertschinger/genome_assembly_annotation/outputs/22_nucmer_analysis/
LOG_DIR=/data/users/sbertschinger/genome_assembly_annotation/logs/22_nucmer_analysis/

# CONTAINER
CONTAINER=/containers/apptainer/mummer4_gnuplot.sif

# Define the assemblies to compare
declare -A ASSEMBLIES
ASSEMBLIES["flye"]="$ASSEMBLY_DIR/06_flye_assembly/assembly.fasta"
ASSEMBLIES["hifiasm"]="$ASSEMBLY_DIR/10_hifiasm_conversion/Altai05.bp.p_ctg.fa"
ASSEMBLIES["lja"]="$ASSEMBLY_DIR/08_lja_assembly/assembly.fasta" # Adjust LJA output name if different

# Create output directories
mkdir -p "$OUTPUT_DIR/reference_vs_assemblies"
mkdir -p "$OUTPUT_DIR/pairwise_comparisons"

echo "=== Starting MUMMER4 Analysis at $(date) ==="
echo "Reference: $REF_GENOME"
echo "Output Dir: $OUTPUT_DIR"
echo "Threads: $SLURM_CPUS_PER_TASK"

# Check if reference exists
if [ ! -f "$REF_GENOME" ]; then
    echo "ERROR: Reference genome not found at $REF_GENOME"
    exit 1
fi

# ---------------------------------------------------------
# PHASE 1: Compare each Assembly vs Reference
# ---------------------------------------------------------
echo ""
echo "=== Phase 1: Assembly vs Reference ==="

for NAME in "${!ASSEMBLIES[@]}"; do
    ASSEM_FILE="${ASSEMBLIES[$NAME]}"
    
    if [ ! -f "$ASSEM_FILE" ]; then
        echo "WARNING: Assembly file for $NAME not found: $ASSEM_FILE. Skipping."
        continue
    fi

    PREFIX="$OUTPUT_DIR/reference_vs_assemblies/${NAME}_vs_REF"
    
    echo "Running NUCMER: $NAME vs Reference..."
    
    # NUCMER Options:
    # --prefix: Output prefix
    # --breaklen 1000: Break alignments longer than 1kb (good for large repeats)
    # --mincluster 1000: Minimum cluster size for alignment
    apptainer exec --bind /data "$CONTAINER" nucmer \
        --prefix "$PREFIX" \
        --breaklen 1000 \
        --mincluster 1000 \
        -t "$SLURM_CPUS_PER_TASK" \
        "$REF_GENOME" \
        "$ASSEM_FILE"

    if [ $? -ne 0 ]; then
        echo "ERROR: NUCMER failed for $NAME"
        exit 1
    fi

        
    echo "Completed: $NAME vs Reference"
    echo "---"
done

# ---------------------------------------------------------
# PHASE 2: Pairwise Comparisons (Flye vs Hifiasm, Flye vs LJA, Hifiasm vs LJA)
# ---------------------------------------------------------
echo ""
echo "=== Phase 2: Pairwise Assembly Comparisons ==="

# Get list of assembly names
NAMES=("${!ASSEMBLIES[@]}")

for (( i=0; i<${#NAMES[@]}; i++ )); do
    for (( j=i+1; j<${#NAMES[@]}; j++ )); do
        NAME_A="${NAMES[$i]}"
        NAME_B="${NAMES[$j]}"
        
        FILE_A="${ASSEMBLIES[$NAME_A]}"
        FILE_B="${ASSEMBLIES[$NAME_B]}"
        
        if [ ! -f "$FILE_A" ] || [ ! -f "$FILE_B" ]; then
            echo "Skipping pair $NAME_A vs $NAME_B (file missing)"
            continue
        fi

        PREFIX="$OUTPUT_DIR/pairwise_comparisons/${NAME_A}_vs_${NAME_B}"
        
        echo "Running NUCMER: $NAME_A vs $NAME_B..."
        
        apptainer exec --bind /data "$CONTAINER" nucmer \
            --prefix "$PREFIX" \
            --breaklen 1000 \
            --mincluster 1000 \
            -t "$SLURM_CPUS_PER_TASK" \
            "$FILE_A" \
            "$FILE_B"
            
        if [ $? -ne 0 ]; then
            echo "ERROR: NUCMER failed for $NAME_A vs $NAME_B"
            continue
        fi

        echo "Completed: $NAME_A vs $NAME_B"
        echo "---"
    done
done

echo "=== All NUCMER analyses finished at $(date) ==="
echo "Results located in: $OUTPUT_DIR"
echo "Delta files are ready for viewing."
