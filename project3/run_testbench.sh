#!/usr/bin/env bash
set -euo pipefail

# 1. Parse CLI Arguments
# Example:
#   ./run_bench.sh \
#       --url https://127.0.0.1:443 \
#       --duration 120 \
#       --rps 1000 \
#       --concurrency 256 \
#       --container fithealth_srv \
#       --outdir results/tdx_run1
#
URL="https://127.0.0.1:443"
DURATION=120           # seconds
TOTAL_RPS=1000
CONC=256
NAME="fithealth_srv"
OUTDIR="results/$(date +%s)"
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

# 2. Enable docker-stats
STATS_FILE="$OUTDIR/stats.csv"
echo "timestamp,cpu_perc,mem_used" >"$STATS_FILE"
docker stats "$NAME" --format '{{.CPUPerc}},{{.MemUsage}}' \
        --no-stream=false --interval 1s |
while read -r line; do
  printf '%s,%s\n' "$(date +%s)" "$line"
done >>"$STATS_FILE" &
STATS_PID=$!

# Attestation start time
START_TS_MS=$(($(date +%s%N)/1000000))

# 4. Build vegeta target files (90% GET, 10% POST)
GET_RPS=$(awk "BEGIN{printf \"%.0f\",$TOTAL_RPS*0.9}")
POST_RPS=$(awk "BEGIN{printf \"%.0f\",$TOTAL_RPS*0.1}")

echo "GET  $URL/fetch/123"                >  "$OUTDIR/get.targets"
echo "POST $URL/insert"                    >  "$OUTDIR/post.targets"

# 5. Run workloads
echo "Running workload ($DURATION s)..."

vegeta attack -lazy -targets="$OUTDIR/get.targets" \
       -rate="$GET_RPS" -duration="${DURATION}s" -connections "$CONC" \
       | tee "$OUTDIR/read.bin"  >/dev/null & READ_PID=$!

vegeta attack -lazy -targets="$OUTDIR/post.targets" \
       -rate="$POST_RPS" -duration="${DURATION}s" -connections "$CONC" \
       | tee "$OUTDIR/write.bin" >/dev/null & WRITE_PID=$!

wait $READ_PID $WRITE_PID

# 6. Stop stats collection
kill $STATS_PID 2>/dev/null || true

# 7. Build reports
function vrep () {
    local BIN=$1 PREF=$2
    vegeta report -type=json "$BIN" \
      | jq --arg p "$PREF" '
        {throughput: .throughput, p50: .latencies.mean, p95: .latencies["95th"], p99: .latencies["99th"]}
        | {endpoint: $p} + .
      '
}
jq -s 'add' \
  <(vrep "$OUTDIR/read.bin"  "GET") \
  <(vrep "$OUTDIR/write.bin" "POST") \
  | tee "$OUTDIR/latency_throughput.json"

# 8. Calculate attestation latency
KEY_LINE=$(docker logs "$NAME" --timestamps 2>&1 | grep -m1 'KEY_RETRIEVED')
if [[ -n $KEY_LINE ]]; then
  KEY_TS_MS=$(date --date="$(cut -d' ' -f1 <<<"$KEY_LINE")" +%s%3N)
  ATTEST_MS=$(( KEY_TS_MS - START_TS_MS ))
  echo "{\"attestation_ms\": $ATTEST_MS}" | tee "$OUTDIR/attestation.json"
else
  echo '{"attestation_ms": null}' | tee "$OUTDIR/attestation.json"
fi

# DONE
echo "Done!"
echo "Results saved under $OUTDIR"