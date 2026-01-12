#!/usr/bin/env bash
#SBATCH --job-name=Prokka
#SBATCH --cpus-per-task=16
#SBATCH --mem=200G
#SBATCH --time=6-00:00:00
#SBATCH --output=logs/Prokka-%j.out
#SBATCH --error=logs/Prokka-%j.err

################################################################################
# ARMonaut - Prokka Annotation HPC Wrapper
# Author: Federica Piergiacomo
################################################################################

module load singularity/3.11.4 2>/dev/null || \
  echo "[WARN] Singularity module not found, assuming it is in PATH."

mkdir -p logs

bash bin/Prokka_annotation.sh \
  --input data \
  --outdir results/prokka \
  --threads 16

echo "[✅ DONE] Prokka annotation completed at $(date)"
