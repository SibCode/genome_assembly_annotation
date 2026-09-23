#!/usr/bin/env bash
#SBATCH --job-name=run_jellyfish
#SBATCH --output=/data/users/sbertschinger/genome_assembly_annotation/logs/04_run_jellyfish/jellyfish_output_%j.out
#SBATCH --error=/data/users/sbertschinger/genome_assembly_annotation/logs/04_run_jellyfish/jellyfish_error_%j.err
#SBATCH --cpus-per-task=6
#SBATCH --mail-user=simon.bertschinger@students.unibe.ch
#SBATCH --mail-type=fail,end
#SBATCH --mem=40G
#SBATCH --time=01:00:00
#SBATCH --partition=pibu_el8

PATH_TO_OUTPUT=/data/users/sbertschinger/genome_assembly_annotation/outputs/04_run_jellyfish/
PATH_TO_FASTQ_FILES=/data/users/sbertschinger/genome_assembly_annotation/raw_data/Altai-5/
JELLYFISH_CONTAINER=/containers/apptainer/jellyfish-2.2.6--0.sif
DECOMPRESSED_DIR=/data/users/sbertschinger/genome_assembly_annotation/raw_data/decompressed/

echo "=== Starting Jellyfish k-mer counting at $(date) ==="

# Step 1: Decompress .fastq.gz files (keep originals with -k)
echo "Decompressing FASTQ files..."
for GZ_FILE in "$PATH_TO_FASTQ_FILES"/*.fastq.gz; do
    if [[ ! -f "$GZ_FILE" ]]; then
        echo "ERROR: No .fastq.gz files found in $PATH_TO_FASTQ_FILES"
        exit 1
    fi
    
    BASENAME=$(basename "$GZ_FILE" .fastq.gz)
    gunzip -k -c "$GZ_FILE" > "$DECOMPRESSED_DIR/${BASENAME}.fastq"
    echo "  Decompressed: $BASENAME"
done

# Step 2: Find decompressed files
FASTQ_FILES=$(find "$DECOMPRESSED_DIR" -name "*.fastq" -type f | tr '\n' ' ')

if [ -z "$FASTQ_FILES" ]; then
    echo "ERROR: No decompressed .fastq files found in $DECOMPRESSED_DIR"
    exit 1
fi

echo ""
echo "Found FASTQ files:"
echo "$FASTQ_FILES"
echo ""

# Step 3: Count k-mers using jellyfish
echo "Starting k-mer counting..."
apptainer exec --bind /data "$JELLYFISH_CONTAINER" jellyfish count -C -m 31 -s 1000000000 -t 6 $FASTQ_FILES -o "$PATH_TO_OUTPUT/reads.jf"

if [ $? -ne 0 ]; then
    echo "ERROR: Jellyfish count failed"
    exit 1
fi

echo "Generating histogram..."
apptainer exec --bind /data "$JELLYFISH_CONTAINER" jellyfish histo -t 10 "$PATH_TO_OUTPUT/reads.jf" > "$PATH_TO_OUTPUT/reads.histo"

if [ $? -ne 0 ]; then
    echo "ERROR: Jellyfish histo failed"
    exit 1
fi

echo ""
echo "=== Jellyfish pipeline completed successfully at $(date) ==="
echo "Output files: $PATH_TO_OUTPUT/"