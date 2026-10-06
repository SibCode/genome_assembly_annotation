#!/usr/bin/env bash
#SBATCH --job-name=run_mummer_plot_Altai05
#SBATCH --output=/data/users/sbertschinger/genome_assembly_annotation/logs/23_mummer_analysis/mummer_plot_%j.out
#SBATCH --error=/data/users/sbertschinger/genome_assembly_annotation/logs/23_mummer_analysis/mummer_plot_%j.err
#SBATCH --cpus-per-task=4
#SBATCH --mail-user=simon.bertschinger@students.unibe.ch
#SBATCH --mail-type=fail,end
#SBATCH --mem=16G
#SBATCH --time=01:00:00
#SBATCH --partition=pibu_el8

# --- PATHS ---
REF_GENOME="/data/courses/assembly-annotation-course/references/Arabidopsis_thaliana.TAIR10.dna.toplevel.fa"
ASSEMBLY_DIR=/data/users/sbertschinger/genome_assembly_annotation/outputs/
BASE_OUTPUT=/data/users/sbertschinger/genome_assembly_annotation/outputs/23_mummer_analysis
LOG_DIR=/data/users/sbertschinger/genome_assembly_annotation/logs/23_mummer_analysis/
INPUT_DIR=/data/users/sbertschinger/genome_assembly_annotation/outputs/22_nucmer_analysis/

CONTAINER=/containers/apptainer/mummer4_gnuplot.sif

# Define assemblies
declare -A ASSEMBLIES
ASSEMBLIES["flye"]="$ASSEMBLY_DIR/06_flye_assembly/assembly.fasta"
ASSEMBLIES["hifiasm"]="$ASSEMBLY_DIR/10_hifiasm_conversion/Altai05.bp.p_ctg.fa"
ASSEMBLIES["lja"]="$ASSEMBLY_DIR/08_lja_assembly/assembly.fasta"

# Output folders
PLOT_REF_DIR="$BASE_OUTPUT/reference_vs_assemblies"
INPUT_REF_DIR="$INPUT_DIR/reference_vs_assemblies"
PLOT_PAIR_DIR="$BASE_OUTPUT/pairwise_comparisons"
INPUT_PAIR_DIR="$INPUT_DIR/pairwise_comparisons"

mkdir -p "$PLOT_REF_DIR"
mkdir -p "$PLOT_PAIR_DIR"

echo "=== Starting MUMMER Plot Generation at $(date) ==="

# ---------------------------------------------------------
# PHASE 1: Plot Assembly vs Reference (using existing .delta files)
# ---------------------------------------------------------
echo "--- Phase 1: Generating plots for Assembly vs Reference ---"

for NAME in "${!ASSEMBLIES[@]}"; do
    DELTA_FILE="$INPUT_REF_DIR/${NAME}_vs_REF.delta"
    PREFIX="$PLOT_REF_DIR/${NAME}_vs_REF"
    
    if [ ! -f "$DELTA_FILE" ]; then
        echo "WARNING: Delta file not found for $NAME ($DELTA_FILE). Skipping plot."
        continue
    fi

    echo "Generating plot for $NAME vs Reference..."
    
    # mummerplot syntax: mummerplot [options] <delta_file>
    # We use --prefix to name the output files
    #apptainer exec --bind /data "$CONTAINER" mummerplot \
    #    "$DELTA_FILE" \
    #    --prefix "$PREFIX" \
    #    -R "$REF_GENOME" \
    #    -Q "${ASSEMBLIES[$NAME]}" \
    #    --filter \
    #    --layout \
    #    --fat \
    #    -t png

    apptainer exec --bind /data ${CONTAINER} \
            mummerplot -R "${REF_GENOME}" -Q "${ASSEMBLIES[$NAME]}" \
            --filter -t png --large --layout --fat \
            -p "${PREFIX}" "$DELTA_FILE"

    
    # Check if plot generation succeeded (mummerplot creates .plot file)
    if [ -f "${PREFIX}.plot" ]; then
        echo "Running gnuplot to render PNG for $NAME..."
        # Explicitly call gnuplot to ensure the PNG is created
        apptainer exec --bind /data "$CONTAINER" gnuplot "${PREFIX}.plot"
        
        if [ -f "${PREFIX}.png" ]; then
            echo "SUCCESS: Created ${PREFIX}.png"
        else
            echo "ERROR: gnuplot failed to create PNG for $NAME"
        fi
    else
        echo "ERROR: mummerplot failed to create .plot file for $NAME"
    fi
    echo "---"
done

# ---------------------------------------------------------
# PHASE 2: Plot Pairwise Comparisons (using existing .delta files)
# ---------------------------------------------------------
echo ""
echo "--- Phase 2: Generating plots for Pairwise Comparisons ---"

NAMES=("${!ASSEMBLIES[@]}")

for (( i=0; i<${#NAMES[@]}; i++ )); do
    for (( j=i+1; j<${#NAMES[@]}; j++ )); do
        NAME_A="${NAMES[$i]}"
        NAME_B="${NAMES[$j]}"
        
        DELTA_FILE="$INPUT_PAIR_DIR/${NAME_A}_vs_${NAME_B}.delta"
        PREFIX="$PLOT_PAIR_DIR/${NAME_A}_vs_${NAME_B}"
        
        if [ ! -f "$DELTA_FILE" ]; then
            echo "WARNING: Delta file not found for $NAME_A vs $NAME_B ($DELTA_FILE). Skipping plot."
            continue
        fi

        echo "Generating plot for $NAME_A vs $NAME_B..."
        
        #apptainer exec --bind /data "$CONTAINER" mummerplot \
        #    --prefix "$PREFIX" \
        #    -R "${ASSEMBLIES[$NAME_A]}" \
        #    -Q "${ASSEMBLIES[$NAME_B]}" \
        #    --filter \
        #    --layout \
        #    --fat \
        #    "$DELTA_FILE"

        apptainer exec --bind /data ${CONTAINER} \
            mummerplot -R "${ASSEMBLIES[$NAME_A]}" -Q "${ASSEMBLIES[$NAME_B]}" \
            --filter -t png --large --layout --fat \
            -p "${PREFIX}" "$DELTA_FILE"
            
        if [ -f "${PREFIX}.plot" ]; then
            echo "Running gnuplot to render PNG for $NAME_A vs $NAME_B..."
            apptainer exec --bind /data "$CONTAINER" gnuplot "${PREFIX}.plot"
            
            if [ -f "${PREFIX}.png" ]; then
                echo "SUCCESS: Created ${PREFIX}.png"
            else
                echo "ERROR: gnuplot failed to create PNG for $NAME_A vs $NAME_B"
            fi
        else
            echo "ERROR: mummerplot failed to create .plot file for $NAME_A vs $NAME_B"
        fi
        echo "---"
    done
done

echo "=== All MUMMER plotting finished at $(date) ==="
echo "Check $BASE_OUTPUT for .png files."