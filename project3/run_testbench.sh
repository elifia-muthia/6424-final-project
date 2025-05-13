#!/usr/bin/env bash
set -euo pipefail

# 1. Set args

# Default values
URL=""
DURATION=120        
TOTAL_RPS=50  
CONC=1 # concurrent live connections
PREFILL_USERS=1000
NAME="fithealth_srv"
TIMESTAMP=$(date +'%Y-%m-%d_%H:%M:%S')
OUTDIR="results/${TIMESTAMP}"

# Example:
#   ./run_bench.sh \
#       --url https://127.0.0.1:443 \
#       --duration 120 \
#       --rps 1000 \
#       --concurrency 256 \
#       --container fithealth_srv \
#       --outdir results/tdx_run1
#
while [[ $# -gt 0 ]]; do
  case $1 in
    --url)         URL="$2"; shift 2 ;;
    --duration)    DURATION="$2"; shift 2 ;;
    --rps)         TOTAL_RPS="$2"; shift 2 ;;
    --concurrency) CONC="$2"; shift 2 ;;
    --container)   NAME="$2"; shift 2 ;;
    --outdir)      OUTDIR="$2"; shift 2 ;;
    *) echo "Unknown flag $1"; exit 1 ;;
  esac
done
mkdir -p "$OUTDIR"

log(){ printf "%s  %s\n" "$(date '+%H:%M:%S')" "$*"; }

# 2. Test if we can connect
log "-> Curling root endpoint to verify server is up …"
/usr/bin/curl -sk --max-time 5 "$URL/" || {
  log "Server unreachable. Aborting."; exit 8; }

# 3. Create dummy JSON data to prefill
log "-> Generating $PREFILL_USERS JSON bodies"
BODY_DIR="$OUTDIR/bodies"
mkdir -p "$BODY_DIR"
for i in $(seq 1 $PREFILL_USERS); do
  cat >"$BODY_DIR/user_${i}.json"<<EOF
{"user_id":"$i",
"timestamp":$(date +%s),
"heart_rate":$((60+RANDOM%40)),
"blood_pressure":"$((110+RANDOM%20))/$((70+RANDOM%10))",
"notes":"prefill"
}
EOF
done

# vegeta target files
PREFILL_TGT="$OUTDIR/prefill.targets"
STEADY_POST_TGT="$OUTDIR/post.targets"
STEADY_GET_TGT="$OUTDIR/get.targets"

# Prefill: one POST per user
for i in $(seq 1 $PREFILL_USERS); do
  echo "POST $URL/insert"                              >>"$PREFILL_TGT"
  echo "Content-Type: application/json"                >>"$PREFILL_TGT"
  echo "@$BODY_DIR/user_${i}.json"                     >>"$PREFILL_TGT"
  echo                                                >>"$PREFILL_TGT"
done

# POST: vegeta will select randomly
find "$BODY_DIR" -maxdepth 1 -name '*.json' | while read f; do
  echo "POST $URL/insert"               >>"$STEADY_POST_TGT"
  echo "Content-Type: application/json" >>"$STEADY_POST_TGT"
  echo "@$f"                            >>"$STEADY_POST_TGT"
  echo                                   >>"$STEADY_POST_TGT"
done

# GET
for i in $(seq 1 $PREFILL_USERS); do
  echo "GET $URL/fetch/$i" >>"$STEADY_GET_TGT"
done

# Set mixed workload (90% GET / 10% POST)
GET_RPS=$(awk "BEGIN{printf \"%.0f\",$TOTAL_RPS*0.9}")
POST_RPS=$(awk "BEGIN{printf \"%.0f\",$TOTAL_RPS*0.1}")

# 4. Prefill data
log "-> Prefilling …"
vegeta attack -insecure -keepalive -targets="$PREFILL_TGT" \
       -rate="$POST_RPS" -duration=10s -connections "$CONC" | vegeta report

# 5. Steady phase
log "-> Steady phase $DURATION s  ($GET_RPS GET/s | $POST_RPS POST/s)"

vegeta attack -insecure -keepalive -lazy -targets="$STEADY_GET_TGT" \
       -rate="$TOTAL_RPS" -duration="${DURATION}s" -connections "$CONC" \
       | tee "$OUTDIR/get.bin"  >/dev/null & GPID=$!

vegeta attack -insecure -keepalive -lazy -targets="$STEADY_POST_TGT" \
       -rate="$POST_RPS" -duration="${DURATION}s" -connections "$CONC" \
       | tee "$OUTDIR/post.bin" >/dev/null & POST_PID=$!

wait $GPID $POST_PID
log "-> Load finished"

# 6. Summary Report
report() {
  vegeta report -type=json "$1" |
  jq --arg ep "$2" \
     '{endpoint: $ep,
       throughput: .throughput,
       p50: .latencies["50th"],
       p95: .latencies["95th"],
       p99: .latencies["99th"]}'
}

log "-> Generating combined report + metrics JSON…"

# Gather Vegeta reports
reports_json=$(jq -s '.' \
  <( report "$OUTDIR/get.bin"  "GET" ) \
  <( report "$OUTDIR/post.bin" "POST" )
)

# Fetch /metrics endpoint
metrics_json=$(curl -sk "$URL/metrics")

# Extract and compute attestation latency
START_MS=$(jq -r '.start_time'        <<<"$metrics_json")
KEY_MS=$(jq -r '.key_retrieved_ms'   <<<"$metrics_json")
ATT_LAT=$(( KEY_MS - START_MS ))

# Build final JSON
jq -n \
  --argjson reports "$reports_json" \
  --argjson metrics "$metrics_json" \
  --argjson attestation_latency_ms "$ATT_LAT" \
  '{
    reports: $reports,
    start_key_elapsed_ms: $attestation_latency_ms
  }' > "$OUTDIR/stats.json"

log "-> Wrote $OUTDIR/stats.json"

# DONE
log "Done. Results in $OUTDIR"