#!/usr/bin/env bash
(set -Eeuo pipefail) 2>/dev/null || set -Eeuo

shopt -s failglob 2>/dev/null || true

# ==========================
# DEFAULT PARAMETERS
# ==========================
INPUT_DIR=""
OUTPUT_DIR="results/barrnap"
KINGDOM="bac"
THREADS=2
ONLY16S=false
BACKEND="singularity"    # singularity|docker|host
IMG_BARRNAP="docker://chrishah/barrnap:0.9"

log(){ echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
usage(){ grep '^#' "$0" | sed 's/^# //'; exit 0; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --input) INPUT_DIR="$2"; shift 2 ;;
    --outdir) OUTPUT_DIR="$2"; shift 2 ;;
    --kingdom) KINGDOM="$2"; shift 2 ;;
    --threads) THREADS="$2"; shift 2 ;;
    --only-16S) ONLY16S=true; shift ;;
    --singularity) BACKEND="singularity"; shift ;;
    --docker) BACKEND="docker"; shift ;;
    --host) BACKEND="host"; shift ;;
    -h|--help) usage ;;
    *) echo "[ERROR] Unknown arg: $1"; usage ;;
  esac
done

[[ -z "$INPUT_DIR" ]] && { echo "[ERROR] --input required"; exit 1; }
mkdir -p "$OUTPUT_DIR"

run_barrnap(){
  barrnap "$@"
}

log "[INFO] Scanning: ${INPUT_DIR}/*.fa|*.fasta|*.fna (KINGDOM=${KINGDOM}, THREADS=${THREADS})"
shopt -s nullglob
any=false
for fa in "$INPUT_DIR"/*.fa "$INPUT_DIR"/*.fasta "$INPUT_DIR"/*.fna; do
  [[ -e "$fa" ]] || continue
  any=true
  sample=$(basename "$fa"); sample="${sample%.*}"
  outfile="${OUTPUT_DIR}/${sample}_rRNA.gff"

  log "[RUN] Barrnap on ${sample}"
  run_barrnap --kingdom "$KINGDOM" --threads "$THREADS" "/in/$(basename "$fa")" > "/out/${sample}_rRNA.gff"

  if $ONLY16S; then
    # Estrae solo features 16S in un file separato
    awk '$0 ~ /16S/ || $1 ~ /^#/' "$outfile" > "${OUTPUT_DIR}/${sample}_16S.gff"
    log "[POST] Wrote ${sample}_16S.gff"
  fi

  log "[DONE] ${sample} → ${outfile}"
done
$any || { echo "[WARN] No FASTA files found in ${INPUT_DIR}"; exit 0; }

log "[✅ COMPLETED] Barrnap scan finished."

