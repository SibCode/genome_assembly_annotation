#!/usr/bin/env bash
#SBATCH --job-name=run_fastp
#SBATCH --output=/data/users/sbertschinger/genome_assembly_annotation/logs/03_run_fastp/fastp_output_%j.out
#SBATCH --error=/data/users/sbertschinger/genome_assembly_annotation/logs/03_run_fastp/fastp_error_%j.err
#SBATCH --cpus-per-task=6
#SBATCH --mail-user=simon.bertschinger@students.unibe.ch
#SBATCH --mail-type=fail,end
#SBATCH --mem=16G
#SBATCH --time=02:00:00
#SBATCH --partition=pibu_el8

# INPUT PATHS
PATH_TO_RNA_FASTQ_FILES=/data/users/sbertschinger/genome_assembly_annotation/rna_data/RNAseq_Sha/
PATH_TO_HIFI_FASTQ_FILES=/data/users/sbertschinger/genome_assembly_annotation/raw_data/Altai-5/

# OUTPUT PATHS
RNA_OUT_DIR=/data/users/sbertschinger/genome_assembly_annotation/outputs/03_run_fastp/rna/
HIFI_OUT_DIR=/data/users/sbertschinger/genome_assembly_annotation/outputs/03_run_fastp/hifi/
LOG_DIR=/data/users/sbertschinger/genome_assembly_annotation/logs/03_run_fastp/

mkdir -p "$RNA_OUT_DIR" "$HIFI_OUT_DIR" "$LOG_DIR"

echo "=== Starting fastp QC at $(date) ==="
echo "Illumina RNA-seq dir: $PATH_TO_RNA_FASTQ_FILES"
echo "PacBio HiFi dir: $PATH_TO_HIFI_FASTQ_FILES"

###############################################################################
# PART 1: Illumina RNA-seq - Filter and Trim Paired-End Reads
###############################################################################
echo ""
echo "=== Processing Illumina RNA-seq (paired-end) ==="

for SAMPLE in "$PATH_TO_RNA_FASTQ_FILES"/*_1.fastq.gz; do
    if [[ ! -f "$SAMPLE" ]]; then
        echo "No RNA-seq files found in $PATH_TO_RNA_FASTQ_FILES"
        break
    fi
    
    BASENAME=$(basename "$SAMPLE" _1.fastq.gz)
    R2_INPUT="$PATH_TO_RNA_FASTQ_FILES/${BASENAME}_2.fastq.gz"
    
    echo "--- Processing sample: $BASENAME ---"
    
    if [[ ! -f "$R2_INPUT" ]]; then
        echo "WARNING: Missing R2 file for $BASENAME ($R2_INPUT)"
        continue
    fi
    
    apptainer exec --bind /data /containers/apptainer/fastp_0.23.2--h5f740d0_3.sif fastp \
        -i "$SAMPLE" \
        -I "$R2_INPUT" \
        -o "$RNA_OUT_DIR/${BASENAME}_1_trimmed.fastq.gz" \
        -O "$RNA_OUT_DIR/${BASENAME}_2_trimmed.fastq.gz" \
        -j "$LOG_DIR/${BASENAME}_fastp.json" \
        -h "$LOG_DIR/${BASENAME}_fastp.html" \
        -w 6 \
        --qualified_quality_phred 20 \
        --unqualified_percent_limit 40 \
        --n_base_limit 5 \
        --length_required 30 \
        --cut_mean_quality 20 \
        --cut_window_size 4 \
        -p \
        --detect_adapter_for_pe \
        --report_title "${BASENAME}_RNAseq_QC" || {
        echo "ERROR: fastp failed for $BASENAME"
        exit 1
    }
    
    echo "Completed: $BASENAME"
done

###############################################################################
# PART 2: PacBio HiFi - Count Total Bases Without Filtering
###############################################################################
echo ""
echo "=== Processing PacBio HiFi (base count only, no filtering) ==="

TOTAL_BASES=0

for SAMPLE in "$PATH_TO_HIFI_FASTQ_FILES"/*.fastq.gz; do
    if [[ ! -f "$SAMPLE" ]]; then
        echo "No PacBio files found in $PATH_TO_HIFI_FASTQ_FILES"
        break
    fi
    
    BASENAME=$(basename "$SAMPLE" .fastq.gz)
    echo "--- Counting bases: $BASENAME ---"
    
    # fastp with minimal settings: just count stats, no trimming/filtering
    apptainer exec --bind /data /containers/apptainer/fastp_0.23.2--h5f740d0_3.sif fastp \
        -i "$SAMPLE" \
        -o "$HIFI_OUT_DIR/${BASENAME}_stats.fastq.gz" \
        -j "$LOG_DIR/${BASENAME}_hifi_stats.json" \
        -h "$LOG_DIR/${BASENAME}_hifi_stats.html" \
        -w 6 \
        --disable_quality_filtering \
        --disable_length_filtering \
        --disable_trim_poly_g \
        --disable_adapter_trimming \
        --report_title "${BASENAME}_HiFi_BaseCount" || {
        echo "ERROR: fastp failed for $BASENAME"
        exit 1
    }
    
    # Extract total bases from JSON report
    if command -v jq &> /dev/null; then
        SAMPLE_BASES=$(jq '.summary.before_filtering.total_bases' "$LOG_DIR/${BASENAME}_hifi_stats.json")
        TOTAL_BASES=$((TOTAL_BASES + SAMPLE_BASES))
        echo "  ${BASENAME}: $SAMPLE_BASES bases"
    else
        SAMPLE_BPS=$(grep -o '"total_bases": [0-9]*' "$LOG_DIR/${BASENAME}_hifi_stats.json" | head -1 | grep -o '[0-9]*')
        if [[ -n "$SAMPLE_BPS" ]]; then
            TOTAL_BASES=$((TOTAL_BASES + SAMPLE_BPS))
            echo "  ${BASENAME}: $SAMPLE_BPS bases"
        fi
    fi
done

echo ""
echo "=== Total HiFi bases counted: $TOTAL_BASES ==="

###############################################################################
# Summary
###############################################################################
echo ""
echo "=== Fastp Complete at $(date) ==="
echo "RNA-seq trimmed files: $RNA_OUT_DIR/"
echo "HiFi stats JSONs: $LOG_DIR/*hifi_stats.json"
echo "Logs and reports: $LOG_DIR/"