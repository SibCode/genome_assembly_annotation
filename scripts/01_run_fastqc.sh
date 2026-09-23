#!/usr/bin/env bash
#SBATCH --job-name=run_fastqc_Altai-5
#SBATCH --output=/data/users/sbertschinger/genome_assembly_annotation/logs/01_run_fastqc/fastqc_output_%j.out
#SBATCH --error=/data/users/sbertschinger/genome_assembly_annotation/logs/01_run_fastqc/run_fastqc_error_%j.err
#SBATCH --cpus-per-task=6
#SBATCH --mail-user=simon.bertschinger@students.unibe.ch
#SBATCH --mail-type=fail,end
#SBATCH --mem=16G
#SBATCH --time=01:00:00
#SBATCH --partition=pibu_el8

PATH_TO_OUTPUT=/data/users/sbertschinger/genome_assembly_annotation/outputs/01_run_fastqc/
PATH_TO_FASTQ_FILES=/data/users/sbertschinger/genome_assembly_annotation/raw_data/Altai-5/

apptainer exec --bind /data /containers/apptainer/fastqc-0.12.1.sif fastqc -o $PATH_TO_OUTPUT -t 6 ${PATH_TO_FASTQ_FILES}*.fastq.gz