#!/usr/bin/env bash
#SBATCH --job-name=Barrnap_16S
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=7-00:00:00
#SBATCH --output=logs/Barrnap_16S-%j.out
#SBATCH --error=logs/Barrnap_16S-%j.err

################################################################################
# ARMonaut - Barrnap 16S Annotation HPC Wrapper
# Author: Federica Piergiacomo
################################################################################
module load nextflow/23.10.1-gcc-12.1.0
module load singularity/3.11.4 2>/dev/null || echo "[WARN] Singularity module not found, assuming it is in PATH."

mkdir -p logs

nextflow run . \
  -profile slurm \
  --input data \
  --outdir results \
  --enable_rgi false \
  --enable_bacmet false \
  --enable_plasmid false \
  --enable_prokka false \
  --threads 4

echo "[✅ DONE] Barrnap 16S completed at $(date)"

