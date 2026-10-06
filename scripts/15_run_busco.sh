#!/usr/bin/env bash
#SBATCH --job-name=run_busco_Altai05
#SBATCH --output=/data/users/sbertschinger/genome_assembly_annotation/logs/15_run_busco/busco_output_%j.out
#SBATCH --error=/data/users/sbertschinger/genome_assembly_annotation/logs/15_run_busco/busco_error_%j.err
#SBATCH --cpus-per-task=8
#SBATCH --mail-user=simon.bertschinger@students.unibe.ch
#SBATCH --mail-type=fail,end
#SBATCH --mem=32G
#SBATCH --time=04:00:00
#SBATCH --partition=pibu_el8

# PATHS
INPUT_FLYE_ASSEMBLY=/data/users/sbertschinger/genome_assembly_annotation/outputs/06_flye_assembly/assembly.fasta
INPUT_LJA_ASSEMBLY=/data/users/sbertschinger/genome_assembly_annotation/outputs/08_lja_assembly/assembly.fasta
INPUT_HIFIASM_ASSEMBLY=/data/users/sbertschinger/genome_assembly_annotation/outputs/10_hifiasm_conversion/Altai05.bp.p_ctg.fa
INPUT_TRINITY_ASSEMBLY=/data/users/sbertschinger/genome_assembly_annotation/outputs/09_trinity_rna_assembly/09_trinity_rna_assembly.Trinity.fasta
OUTPUT_DIR=/data/users/sbertschinger/genome_assembly_annotation/outputs/15_run_busco/

echo "=== Starting BUSCO for Altai-05 at $(date) ==="
# Changing to the output directory BEFORE running BUSCO since it generates temporary files and logs in the current working directory. 
cd "$OUTPUT_DIR" || exit 1

# Busco helper function to run BUSCO on a given input file with specified name and mode
run_busco () {
    local INPUT=$1
    local NAME=$2
    local MODE=$3

    apptainer exec --bind /data /containers/apptainer/busco_5.7.1.sif busco \
        --in "$INPUT" \
        --out "$NAME" \
        --out_path "$OUTPUT_DIR" \
        --mode "$MODE" \
        --auto-lineage \
        --cpu "$SLURM_CPUS_PER_TASK"

    if [ $? -ne 0 ]; then
        echo "=== ERROR: BUSCO failed for $NAME ($INPUT) at $(date) ==="
        return 1
    fi
    echo "=== BUSCO finished successfully for $NAME at $(date) ==="
}

# Whole genome assemblies (mode: genome)
run_busco "$INPUT_FLYE_ASSEMBLY"   "busco_flye"   genome || exit 1
run_busco "$INPUT_HIFIASM_ASSEMBLY" "busco_hifiasm" genome || exit 1
run_busco "$INPUT_LJA_ASSEMBLY"   "busco_lja"    genome || exit 1

# Transcriptome assembly (mode: transcriptome)
run_busco "$INPUT_TRINITY_ASSEMBLY" "busco_trinity" transcriptome || exit 1

# Final check: report chosen lineage and completeness
echo ""
echo "=== BUSCO summary overviews ==="
for summary in "$OUTPUT_DIR"/busco_*/short_summary*.txt; do
    echo "--- $summary ---"
    grep -E "Lineage dataset|program version|Complete percentage|one-to-one|multi-copy|fragmented|missing" "$summary" || true
done

echo "=== All BUSCO runs finished at $(date) ==="