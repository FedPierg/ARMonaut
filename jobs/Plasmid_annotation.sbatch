#!/usr/bin/env bash
#SBATCH --job-name=PlasmidFinder
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=7-00:00:00
#SBATCH --output=logs/PlasmidFinder-%j.out
#SBATCH --error=logs/PlasmidFinder-%j.err

################################################################################
# ARMonaut - PlasmidFinder Annotation (SLURM wrapper)
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
  --enable_prokka false \
  --threads 8
echo "[✅ DONE] PlasmidFinder completed at $(date)"

