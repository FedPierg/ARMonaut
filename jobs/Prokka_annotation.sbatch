#!/usr/bin/env bash
#SBATCH --job-name=Prokka
#SBATCH --cpus-per-task=16
#SBATCH --mem=200G
#SBATCH --time=6-00:00:00
#SBATCH --output=logs/Prokka-%j.out
#SBATCH --error=logs/Prokka-%j.err

################################################################################
# ARMonaut - Prokka Annotation (SLURM wrapper)
# Author: Federica Piergiacomo
################################################################################
module load nextflow/23.10.1-gcc-12.1.0
module load singularity/3.11.4 2>/dev/null || \
  echo "[WARN] Singularity module not found, assuming it is in PATH."

mkdir -p logs

nextflow run . \
  -profile slurm \
  --input data \
  --outdir results \
  --enable_rgi false \
  --enable_bacmet false \
  --enable_barrnap false \
  --enable_plasmid false \
  --threads 16