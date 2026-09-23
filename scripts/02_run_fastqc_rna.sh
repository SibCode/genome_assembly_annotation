#!/usr/bin/env bash
#SBATCH --job-name=run_fastqc_rna
#SBATCH --output=/data/users/sbertschinger/genome_assembly_annotation/logs/02_run_fastqc_rna/fastqc_output_%j.out
#SBATCH --error=/data/users/sbertschinger/genome_assembly_annotation/logs/02_run_fastqc_rna/run_fastqc_error_%j.err
#SBATCH --cpus-per-task=6
#SBATCH --mail-user=simon.bertschinger@students.unibe.ch
#SBATCH --mail-type=fail,end
#SBATCH --mem=16G
#SBATCH --time=01:00:00
#SBATCH --partition=pibu_el8

PATH_TO_OUTPUT=/data/users/sbertschinger/genome_assembly_annotation/outputs/02_run_fastqc_rna/
PATH_TO_FASTQ_FILES=/data/users/sbertschinger/genome_assembly_annotation/rna_data/RNAseq_Sha/

apptainer exec --bind /data /containers/apptainer/fastqc-0.12.1.sif fastqc -o $PATH_TO_OUTPUT -t 6 ${PATH_TO_FASTQ_FILES}*.fastq.gz