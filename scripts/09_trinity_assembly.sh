#!/usr/bin/env bash
#SBATCH --job-name=run_trinity_rna_Altai05
#SBATCH --output=/data/users/sbertschinger/genome_assembly_annotation/logs/09_trinity_assembly/trinity_rna_output_%j.out
#SBATCH --error=/data/users/sbertschinger/genome_assembly_annotation/logs/09_trinity_assembly/trinity_rna_error_%j.err
#SBATCH --cpus-per-task=16
#SBATCH --mail-user=simon.bertschinger@students.unibe.ch
#SBATCH --mail-type=fail,end
#SBATCH --mem=64G
#SBATCH --time=1-00:00:00
#SBATCH --partition=pibu_el8

# PATHS
# RNA Data Path (Different from Genome Data)
INPUT_DIR=/data/users/sbertschinger/genome_assembly_annotation/rna_data/RNAseq_Sha/
OUTPUT_DIR=/data/users/sbertschinger/genome_assembly_annotation/outputs/09_trinity_rna_assembly/

echo "=== Starting Trinity RNA-Seq assembly at $(date) ==="
echo "Input Directory: $INPUT_DIR"
echo "Output Directory: $OUTPUT_DIR"
echo "Allocated Memory: 64G"
echo "Allocated CPUs: $SLURM_CPUS_PER_TASK"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Define specific file names to avoid wildcard ambiguity
LEFT_FILE="$INPUT_DIR/ERR754081_1.fastq.gz"
RIGHT_FILE="$INPUT_DIR/ERR754081_2.fastq.gz"

# Validate that both paired files exist
if [ ! -f "$LEFT_FILE" ]; then
    echo "ERROR: Left read file not found: $LEFT_FILE"
    exit 1
fi

if [ ! -f "$RIGHT_FILE" ]; then
    echo "ERROR: Right read file not found: $RIGHT_FILE"
    exit 1
fi

echo "Found Left Reads: $LEFT_FILE"
echo "Found Right Reads: $RIGHT_FILE"

# Run Trinity
apptainer exec --bind /data /containers/apptainer/trinity_2.15.2.sif Trinity \
    --seqType fq \
    --max_memory 64G \
    --CPU "$SLURM_CPUS_PER_TASK" \
    --left "$LEFT_FILE" \
    --right "$RIGHT_FILE" \
    --output "$OUTPUT_DIR"

# Check exit status
if [ $? -eq 0 ]; then
    echo "=== Trinity RNA-Seq assembly completed successfully at $(date) ==="
    # Trinity creates a subdirectory 'trinity_out_dir' inside the output folder
    ASSEMBLY_FILE="$OUTPUT_DIR/trinity_out_dir/Trinity.fasta"
    if [ -f "$ASSEMBLY_FILE" ]; then
        echo "Assembly found at: $ASSEMBLY_FILE"
        echo "Transcript count: $(grep -c "^>" $ASSEMBLY_FILE)"
    else
        echo "WARNING: Expected assembly file ($ASSEMBLY_FILE) not found, check logs."
    fi
else
    echo "=== ERROR: Trinity assembly failed at $(date) ==="
    exit 1
fi