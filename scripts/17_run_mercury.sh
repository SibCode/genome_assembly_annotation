#!/usr/bin/env bash
#SBATCH --job-name=run_merqury_Altai05_fixed
#SBATCH --output=/data/users/sbertschinger/genome_assembly_annotation/logs/17_run_merqury/merqury_output_%j.out
#SBATCH --error=/data/users/sbertschinger/genome_assembly_annotation/logs/17_run_merqury/merqury_error_%j.out
#SBATCH --cpus-per-task=16
#SBATCH --mail-user=simon.bertschinger@students.unibe.ch
#SBATCH --mail-type=fail,end
#SBATCH --mem=128G
#SBATCH --time=02:00:00
#SBATCH --partition=pshort_el8

# --- PATHS ---
# Input Assemblies
INPUT_FLYE=/data/users/sbertschinger/genome_assembly_annotation/outputs/06_flye_assembly/assembly.fasta
INPUT_HIFIASM=/data/users/sbertschinger/genome_assembly_annotation/outputs/10_hifiasm_conversion/Altai05.bp.p_ctg.fa
INPUT_LJA=/data/users/sbertschinger/genome_assembly_annotation/outputs/08_lja_assembly/assembly.fasta

# Raw Reads (Ensure this is the decompressed FASTA, not .gz)
READS_PATH="/data/users/sbertschinger/genome_assembly_annotation/raw_data/decompressed/ERR11437324.fastq"

# Output Directory
OUTPUT_BASE=/data/users/sbertschinger/genome_assembly_annotation/outputs/17_run_merqury/

# Container
CONTAINER=/containers/apptainer/merqury_1.3.sif

# Parameters
K=31
DB_NAME="altai_k${K}"
DB_DIR="$OUTPUT_BASE/meryl_db"

echo "=== Starting Merqury for Altai-05 at $(date) ==="
echo "Using K-mer size: $K"

# --- STEP 1: Build Meryl Database (If not exists) ---
if [ ! -d "$DB_DIR" ]; then
    echo "--- Step 1: Building Meryl database from reads ---"
    mkdir -p "$OUTPUT_BASE"
    cd "$OUTPUT_BASE" || exit 1
    
    if ! ls $READS_PATH 1> /dev/null 2>&1; then
        echo "ERROR: No reads found at $READS_PATH"
        exit 1
    fi

    apptainer exec --bind /data "$CONTAINER" meryl count k=$K threads=$SLURM_CPUS_PER_TASK \
        output "$DB_DIR" $READS_PATH
    
    if [ $? -ne 0 ]; then
        echo "=== ERROR: Meryl database creation failed ==="
        exit 1
    fi
    echo "--- Meryl database created ---"
else
    echo "--- Meryl database already exists, skipping step 1 ---"
fi

# --- STEP 2: Run Merqury Evaluation ---
run_merqury_eval() {
    local ASSEMBLY=$1
    local NAME=$2
    local OUT_DIR="$OUTPUT_BASE/$NAME"
    
    # Create output directory
    mkdir -p "$OUT_DIR"
    
    # CRITICAL FIX: Change to the output directory and create 'logs' subdir
    # This prevents the "logs//..." path error
    cd "$OUT_DIR" || exit 1
    mkdir -p logs
    
    echo "--- Running Merqury for $NAME in $OUT_DIR ---"
    
    # Run merqury.sh
    # Arguments: <meryl_db> <assembly> <output_prefix>
    # We run it from inside OUT_DIR so relative paths work
    # Export MERQURY path to ensure the script can find its dependencies
    export MERQURY="/usr/local/share/merqury"
    apptainer exec --bind /data "$CONTAINER" merqury.sh \
        "$DB_DIR" \
        "$ASSEMBLY" \
        "${NAME}_merqury"
        
    local EXIT_CODE=$?
    
    if [ $EXIT_CODE -ne 0 ]; then
        echo "=== ERROR: Merqury failed for $NAME (Exit Code: $EXIT_CODE) ==="
        return 1
    fi
    
    echo "--- Finished Merqury for $NAME ---"
    
    # Return to base for next iteration
    cd "$OUTPUT_BASE" || exit 1
}

# Run for all three assemblies
run_merqury_eval "$INPUT_FLYE" "flye" || exit 1
run_merqury_eval "$INPUT_HIFIASM" "hifiasm" || exit 1
run_merqury_eval "$INPUT_LJA" "lja" || exit 1

# --- STEP 3: Summary Extraction ---
echo ""
echo "=== Extracting Key Metrics ==="
for dir in "$OUTPUT_BASE"/flye* "$OUTPUT_BASE"/hifiasm* "$OUTPUT_BASE"/lja*; do
    if [ -d "$dir" ]; then
        QV_FILE="$dir/${dir##*/}_merqury.qv.txt"
        if [ -f "$QV_FILE" ]; then
            echo "--- ${dir##*/} ---"
            cat "$QV_FILE"
            echo ""
        else
            echo "WARNING: QV file not found for ${dir##*/}"
        fi
    fi
done

echo "=== All Merqury jobs completed at $(date) ==="
echo "Results are in: $OUTPUT_BASE"
echo "Check .qv.txt for Quality Value and .spectra-cn.ps for plots."