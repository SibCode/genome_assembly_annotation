# genome_assembly_annotation
De Novo Genome Assembly Course Bioinformatics Master University of Bern

Folder structure is as follows:

- scripts (contains all scripts)
  - 01_aaa.sh
  - 02_bbb.sh
  - ... etc. (for each step)
- logs (contains all SLURM error and output logs)
  - 01_aaa_xxx
  - 02_bbb_xxx
  - ... etc. (for each script)
- outputs (contains all output files of scripts)
  - 01_aaa
  - 02_bbb
  - ... etc. (for each script that has outputs)
- metadata (contains all metadata used by / for scripts)
- raw_data (contains raw data provided for assembly)
- rna_data (contains rna data provided)
- assemblies (contains the assembled genome/genomes)

Due to data amount outputs, logs, raw_data and assemblies folder is .gitignored.

Scripts were run in order unless specified.