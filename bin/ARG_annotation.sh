#!/usr/bin/env bash
(set -Eeuo pipefail) 2>/dev/null || set -Eeuo
shopt -s nullglob

# ==========================
# DEFAULT PARAMETERS
# ==========================
INPUT_DIR=""
OUTPUT_DIR=""
CARD_DIR=""
THREADS=8
TEST_MODE="${TEST_MODE:-false}"
# ==========================
# PARSE ARGUMENTS
# ==========================
while [[ $# -gt 0 ]]; do
  case "$1" in
    --input)   INPUT_DIR="$2"; shift 2 ;;
    --outdir)  OUTPUT_DIR="$2"; shift 2 ;;
    --card)    CARD_DIR="$2"; shift 2 ;;
    --threads) THREADS="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: ARG_annotation.sh --input DIR --outdir DIR --card DIR [--threads N]"
      exit 0 ;;
    *) echo "[ERROR] Unknown option: $1"; exit 1 ;;
  esac
done

[[ -z "$INPUT_DIR"  ]] && { echo "[ERROR] --input required"; exit 1; }
[[ -z "$OUTPUT_DIR" ]] && { echo "[ERROR] --outdir required"; exit 1; }
[[ -z "$CARD_DIR"   ]] && { echo "[ERROR] --card required"; exit 1; }

mkdir -p "$OUTPUT_DIR"

# ==========================
# LOG FUNCTION
# ==========================
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

log "[INFO] RGI version: $(rgi --version 2>/dev/null || echo 'NOT FOUND')"
log "[INFO] Threads: ${THREADS}"
log "[INFO] Input dir: ${INPUT_DIR}"
log "[INFO] Output dir: ${OUTPUT_DIR}"
log "[INFO] CARD dir: ${CARD_DIR}"
log "[INFO] Test mode: ${TEST_MODE}"

# ==========================
# DOWNLOAD CARD DATABASE (only if not test)
# ==========================
if [[ "$TEST_MODE" != true ]]; then
  if [[ ! -f "${CARD_DIR}/card.json" ]]; then
    log "[INFO] Downloading CARD database..."
    mkdir -p "$CARD_DIR"
    wget -q https://card.mcmaster.ca/latest/data -O "${CARD_DIR}/card_data.tar.gz"
    tar -xzf "${CARD_DIR}/card_data.tar.gz" -C "$CARD_DIR"
    CARD_JSON=$(find "$CARD_DIR" -name card.json | head -n1)
    [[ -z "$CARD_JSON" ]] && { echo "[ERROR] card.json not found"; exit 1; }
    mv "$CARD_JSON" "${CARD_DIR}/card.json"
    rm -f "${CARD_DIR}/card_data.tar.gz"
  fi
else
  log "[INFO] Test mode: skipping CARD download."
  mkdir -p "$CARD_DIR"
  echo "{}" > "${CARD_DIR}/card.json"  # dummy file per test
fi

# ==========================
# RUN RGI
# ==========================
FASTAS=( "${INPUT_DIR}"/*.fa "${INPUT_DIR}"/*.fasta "${INPUT_DIR}"/*.fna )

if [[ ${#FASTAS[@]} -eq 0 ]]; then
  log "[ERROR] No FASTA files found in ${INPUT_DIR}"
  exit 1
fi

log "[INFO] Starting RGI on ${#FASTAS[@]} file(s)..."

for fasta in "${FASTAS[@]}"; do
  base=$(basename "$fasta")
  prefix="${base%.*}"

   if [[ "$TEST_MODE" = true ]]; then
    log "[TEST] Skipping actual RGI run for $base"
    touch "${OUTPUT_DIR}/${prefix}_rgi.json"  # dummy output
  else
    rgi main \
      --input_sequence "$fasta" \
      --output_file "${OUTPUT_DIR}/${prefix}_rgi" \
      --card_json "${CARD_DIR}/card.json" \
      --local \
      --num_threads "${THREADS}"
  fi
done

log "[✅ COMPLETED] RGI annotation finished successfully."
