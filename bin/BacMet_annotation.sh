#!/usr/bin/env bash
(set -Eeuo pipefail) 2>/dev/null || set -Eeuo


# ==========================
# DEFAULT PARAMETERS
# ==========================
INPUT_DIR=""
OUTPUT_DIR=""
THREADS=8
TEST_MODE="${TEST_MODE:-false}"

# Database paths
BACMET_DIR="${BACMET_DIR:-$(pwd)/bacmet2}"
BACMET_FASTA="$BACMET_DIR/BacMet2_PROTEIN.fasta"
BACMET_DB="$BACMET_DIR/bacmet_db.dmnd"
BACMET_FASTA_URL="https://zenodo.org/records/7577664/files/BacMet2_PROTEIN.fasta.gz"

log(){ echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

# ==========================
# ARGUMENT PARSING
# ==========================
while [[ $# -gt 0 ]]; do
  case "$1" in
    --input)   INPUT_DIR="$2"; shift 2 ;;
    --outdir)  OUTPUT_DIR="$2"; shift 2 ;;
    --dbdir)
      BACMET_DIR="$2"
      BACMET_FASTA="$BACMET_DIR/BacMet2_PROTEIN.fasta"
      BACMET_DB="$BACMET_DIR/bacmet_db.dmnd"
      shift 2 ;;
    --threads) THREADS="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: BacMet_annotation.sh --input DIR --outdir DIR --dbdir DIR [--threads N]"
      exit 0 ;;
    *) echo "[ERROR] Unknown option: $1"; exit 1 ;;
  esac
done

[[ -z "$INPUT_DIR"  ]] && { echo "[ERROR] --input required"; exit 1; }
[[ -z "$OUTPUT_DIR" ]] && { echo "[ERROR] --outdir required"; exit 1; }

mkdir -p "$OUTPUT_DIR" "$BACMET_DIR"

log "[INFO] Input dir:  $INPUT_DIR"
log "[INFO] Output dir: $OUTPUT_DIR"
log "[INFO] DB dir:     $BACMET_DIR"
log "[INFO] Threads:    $THREADS"

# ==========================
# DOWNLOAD DATABASE IF NEEDED
# ==========================
if [[ "${TEST_MODE:-false}" != "true" ]] && [[ ! -f "$BACMET_DB" ]]; then
  log "[INFO] BacMet2 database not found – downloading..."

  wget -q "$BACMET_FASTA_URL" -O "${BACMET_FASTA}.gz"
  gunzip -f "${BACMET_FASTA}.gz"

  log "[INFO] Building DIAMOND database..."
  diamond makedb \
    --in "$BACMET_FASTA" \
    --db "$BACMET_DIR/bacmet_db"

  log "[DONE] Database ready: $BACMET_DB"
else
  log "[INFO] TEST_MODE active or DB already exists – skipping download."
fi


# ==========================
# RUN DIAMOND BLASTX
# ==========================
FASTAS=( "$INPUT_DIR"/*.fa "$INPUT_DIR"/*.fasta "$INPUT_DIR"/*.fna )

if [[ ${#FASTAS[@]} -eq 0 ]]; then
  log "[ERROR] No FASTA files found in $INPUT_DIR"
  exit 1
fi

log "[INFO] Starting BacMet2 annotation on ${#FASTAS[@]} file(s)..."

for fa in "${FASTAS[@]}"; do
  sample=$(basename "$fa")
  sample="${sample%.*}"

  out="$OUTPUT_DIR/${sample}_bacmet.tsv"

  log "[RUN] ${sample}"
 if [[ "${TEST_MODE:-false}" == "true" ]]; then
    log "[INFO] TEST_MODE active – creating dummy BacMet2 output"
    echo -e "qseqid\tsseqid\tpident\tlength\tmismatch\tgapopen\tqstart\tqend\tsstart\tsend\tevalue\tbitscore" > "$out"
    echo -e "${sample}\tTESTSEQ\t100\t10\t0\t0\t1\t10\t1\t10\t1e-5\t100" >> "$out"
 else
  diamond blastx \
    --db "$BACMET_DB" \
    --query "$fa" \
    --out "$out" \
    --outfmt 6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore \
    --threads "$THREADS" \
    --max-target-seqs 1 \
    --evalue 1e-5
 fi
done

log "[✅ COMPLETED] BacMet2 annotation finished successfully."
