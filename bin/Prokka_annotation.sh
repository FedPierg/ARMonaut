#!/usr/bin/env bash
set -euo pipefail

# ==========================
# DEFAULT PARAMETERS
# ==========================
INPUT_DIR=""
OUTPUT_DIR=""
THREADS=4
KINGDOM="Bacteria"

log(){ echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

# ==========================
# ARGUMENT PARSING
# ==========================
while [[ $# -gt 0 ]]; do
  case "$1" in
    --input)   INPUT_DIR="$2"; shift 2 ;;
    --outdir)  OUTPUT_DIR="$2"; shift 2 ;;
    --threads) THREADS="$2"; shift 2 ;;
    --kingdom) KINGDOM="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: Prokka_annotation.sh --input DIR --outdir DIR [--threads N]"
      exit 0 ;;
    *) echo "[ERROR] Unknown option: $1"; exit 1 ;;
  esac
done

[[ -z "$INPUT_DIR"  ]] && { echo "[ERROR] --input required"; exit 1; }
[[ -z "$OUTPUT_DIR" ]] && { echo "[ERROR] --outdir required"; exit 1; }

mkdir -p "$OUTPUT_DIR"

log "[INFO] Input dir:  $INPUT_DIR"
log "[INFO] Output dir: $OUTPUT_DIR"

# ==========================
# RUN PROKKA
# ==========================
FASTAS=( "$INPUT_DIR"/*.fa "$INPUT_DIR"/*.fasta "$INPUT_DIR"/*.fna )

if [[ ${#FASTAS[@]} -eq 0 ]]; then
  log "[WARN] No FASTA files found"
  exit 0
fi

for fa in "${FASTAS[@]}"; do
  sample=$(basename "$fa")
  sample="${sample%.*}"

  log "[RUN] Prokka on $sample"

  prokka \
    --outdir "$OUTPUT_DIR/$sample" \
    --prefix "$sample" \
    --kingdom "$KINGDOM" \
    --cpus "$THREADS" \
    "$fa"
done

# ==========================
# BUILD COMBINED FAA FOR KAAS
# ==========================
log "[POST] Building combined FAA for KAAS"

mkdir -p "$OUTPUT_DIR/combined_faa"
OUTFAA="$OUTPUT_DIR/combined_faa/all_proteins.faa"

> "$OUTFAA"

for faa in "$OUTPUT_DIR"/*/*.faa; do
  sample=$(basename "$(dirname "$faa")")
  awk -v s="$sample" '{if(/^>/) print ">"s"_"substr($0,2); else print}' "$faa" >> "$OUTFAA"
done

gzip -f "$OUTFAA"

log "[✅ COMPLETED] Prokka annotation + KAAS file ready"
log "[INFO] File: $OUTFAA.gz"

