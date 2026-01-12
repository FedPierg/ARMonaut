#!/usr/bin/env bash
#SBATCH --job-name=BacMet_annotation
#SBATCH --cpus-per-task=16
#SBATCH --mem=128G
#SBATCH --time=14-00:00:00
#SBATCH --output=logs/BacMet_annotation-%j.out
#SBATCH --error=logs/BacMet_annotation-%j.err

################################################################################
# ARMonaut - BacMet Annotation HPC Wrapper
# Author: Federica Piergiacomo
################################################################################

module load singularity/3.11.4 2>/dev/null || \
  echo "[WARN] Singularity module not found, assuming it is in PATH."

mkdir -p logs

bash bin/BacMet_annotation.sh \
  --input data \
  --outdir results/bacmet \
  --threads 16

echo "[✅ DONE] BacMet annotation completed at $(date)"

