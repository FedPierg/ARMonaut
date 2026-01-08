#!/usr/bin/env bash
#SBATCH --job-name=ARG_annotation
#SBATCH --cpus-per-task=16
#SBATCH --mem=128G
#SBATCH --time=14-00:00:00
#SBATCH --output=logs/ARG_annotation-%j.out
#SBATCH --error=logs/ARG_annotation-%j.err

################################################################################
# ARMonaut - RGI Annotation (SLURM wrapper)
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
  --enable_bacmet false \
  --enable_barrnap false \
  --enable_plasmid false \
  --enable_prokka false \
  --threads 16
echo "[✅ DONE] BacMet annotation completed at $(date)"
