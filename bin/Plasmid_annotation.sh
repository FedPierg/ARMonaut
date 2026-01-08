#!/usr/bin/env bash
set -euo pipefail

# ==========================
# DEFAULT PARAMETERS
# ==========================
INPUT_DIR=""
OUTPUT_DIR=""
DB_DIR="${DB_DIR:-$(pwd)/plasmidfinder_db}"
IDENTITY=0.95
COVERAGE=0.60
THREADS=4

log(){ echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

# ==========================
# ARGUMENT PARSING
# ==========================
while [[ $# -gt 0 ]]; do
  case "$1" in
    --input)    INPUT_DIR="$2"; shift 2 ;;
    --outdir)   OUTPUT_DIR="$2"; shift 2 ;;
    --db)       DB_DIR="$2"; shift 2 ;;
    --identity) IDENTITY="$2"; shift 2 ;;
    --coverage) COVERAGE="$2"; shift 2 ;;
    --threads)  THREADS="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: PlasmidFinder_annotation.sh --input DIR --outdir DIR --db DIR"
      exit 0 ;;
    *) echo "[ERROR] Unknown option: $1"; exit 1 ;;
  esac
done

[[ -z "$INPUT_DIR"  ]] && { echo "[ERROR] --input required"; exit 1; }
[[ -z "$OUTPUT_DIR" ]] && { echo "[ERROR] --outdir required"; exit 1; }


mkdir -p "$OUTPUT_DIR" "$DB_DIR"

log "[INFO] Input dir:  $INPUT_DIR"
log "[INFO] Output dir: $OUTPUT_DIR"
log "[INFO] DB dir:     $DB_DIR"

# ==========================
# DOWNLOAD DATABASE IF NEEDED
# ==========================
if [[ ! -f "$DB_DIR/plasmidfinder_db.fsa" ]]; then
  log "[INFO] Downloading PlasmidFinder database..."
  git clone https://bitbucket.org/genomicepidemiology/plasmidfinder_db.git "$DB_DIR/tmp"
  mv "$DB_DIR/tmp"/* "$DB_DIR"
  rm -rf "$DB_DIR/tmp"
fi

# ==========================
# RUN PLASMIDFINDER
# ==========================
FASTAS=( "$INPUT_DIR"/*.fa "$INPUT_DIR"/*.fasta "$INPUT_DIR"/*.fna )

if [[ ${#FASTAS[@]} -eq 0 ]]; then
  log "[WARN] No FASTA files found"
  exit 0
fi

for fa in "${FASTAS[@]}"; do
  sample=$(basename "$fa")
  sample="${sample%.*}"
  outdir="$OUTPUT_DIR/$sample"

  log "[RUN] PlasmidFinder on $sample"

  plasmidfinder.py \
    -i "$fa" \
    -o "$outdir" \
    -p "$DB_DIR" \
    -t "$IDENTITY" \
    -l "$COVERAGE"

done

log "[✅ COMPLETED] PlasmidFinder annotation finished."

