#!/usr/bin/env bash
#SBATCH --job-name=run_clean_hifi
#SBATCH --output=/data/users/sbertschinger/genome_assembly_annotation/logs/05_clean_hifi/clean_hifi_output_%j.out
#SBATCH --error=/data/users/sbertschinger/genome_assembly_annotation/logs/05_clean_hifi/clean_hifi_error_%j.err
#SBATCH --cpus-per-task=6
#SBATCH --mail-user=simon.bertschinger@students.unibe.ch
#SBATCH --mail-type=fail,end
#SBATCH --mem=16G
#SBATCH --time=02:00:00
#SBATCH --partition=pibu_el8

PATH_TO_FASTQ_FILES=/data/users/sbertschinger/genome_assembly_annotation/raw_data/Altai-5/
PATH_TO_OUTPUT=/data/users/sbertschinger/genome_assembly_annotation/outputs/05_run_clean_hifi/
LOG_DIR=/data/users/sbertschinger/genome_assembly_annotation/logs/05_clean_hifi/

mkdir -p "$PATH_TO_OUTPUT" "$LOG_DIR"

echo "=== Starting HiFi cleaning at $(date) ==="

# Process each HiFi FASTQ file
for SAMPLE in "$PATH_TO_FASTQ_FILES"/*.fastq.gz; do
    if [[ ! -f "$SAMPLE" ]]; then
        echo "No HiFi files found in $PATH_TO_FASTQ_FILES"
        break
    fi
    
    BASENAME=$(basename "$SAMPLE" .fastq.gz)
    echo "--- Processing: $BASENAME ---"
    
    apptainer exec --bind /data /containers/apptainer/fastp_0.23.2--h5f740d0_3.sif fastp \
        -i "$SAMPLE" \
        -o "${PATH_TO_OUTPUT}/${BASENAME}_cleaned.fastq.gz" \
        -j "${LOG_DIR}/${BASENAME}_fastp.json" \
        -h "${LOG_DIR}/${BASENAME}_fastp.html" \
        -w 6 \
        --qualified_quality_phred 20 \
        --unqualified_percent_limit 40 \
        --n_base_limit 5 \
        --length_required 30 \
        --cut_mean_quality 20 \
        --cut_window_size 4 \
        -3 \
        --trim_poly_x \
        --poly_x_min_len 25 \
        -A \
        --report_title "${BASENAME}_cleaned_QC" || {
        echo "ERROR: fastp failed for $BASENAME"
        exit 1
    }
    
    echo "Completed: $BASENAME"
done

echo "=== Fastp HiFi cleaning complete at $(date) ==="
echo "Output files: $PATH_TO_OUTPUT/"
echo "JSON/HTML reports: $LOG_DIR/"