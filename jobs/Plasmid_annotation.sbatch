#!/usr/bin/env bash
#SBATCH --job-name=PlasmidFinder
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=7-00:00:00
#SBATCH --output=logs/PlasmidFinder-%j.out
#SBATCH --error=logs/PlasmidFinder-%j.err

################################################################################
# ARMonaut - PlasmidFinder Annotation HPC Wrapper
# Author: Federica Piergiacomo
################################################################################

module load singularity/3.11.4 2>/dev/null || \
  echo "[WARN] Singularity module not found, assuming it is in PATH."

mkdir -p logs

bash bin/Plasmid_annotation.sh \
  --input data \
  --outdir results/plasmidfinder \
  --threads 8

echo "[✅ DONE] PlasmidFinder completed at $(date)"


