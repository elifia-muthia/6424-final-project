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
PREFILL_USERS=10000

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

# 3. Create dummy JSON to insert
BODY_DIR="$OUTDIR/bodies"
mkdir -p "$BODY_DIR"
for i in $(seq 1 $PREFILL_USERS); do
  cat >"$BODY_DIR/user_${i}.json"<<EOF
{ "user_id":"$i",
  "timestamp":$(date +%s),
  "heart_rate":$((60+RANDOM%40)),
  "blood_pressure":"$((110+RANDOM%20))/$((70+RANDOM%10))",
  "notes":"prefill"
}
EOF
done

# 4. Prepare
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

# Steady-state POST (reuse bodies; vegeta will pick randomly)
find "$BODY_DIR" -maxdepth 1 -name '*.json' | while read f; do
  echo "POST $URL/insert"               >>"$STEADY_POST_TGT"
  echo "Content-Type: application/json" >>"$STEADY_POST_TGT"
  echo "@$f"                            >>"$STEADY_POST_TGT"
  echo                                   >>"$STEADY_POST_TGT"
done

# Steady-state GETs
for i in $(seq 1 $PREFILL_USERS); do
  echo "GET  $URL/fetch/$i" >>"$STEADY_GET_TGT"
done

# 5. Set Attestation start time
START_TS_MS=$(($(date +%s%N)/1000000))

# 6. Prefill data
echo "Prefilling $PREFILL_USERS users …"
vegeta attack -targets="$PREFILL_TGT" \
       -rate=5000 -duration=0 -connections "$CONC" | vegeta report

### 7. Mixed workload (90% GET, 10% POST)
GET_RPS=$(awk "BEGIN{printf \"%.0f\",$TOTAL_RPS*0.9}")
POST_RPS=$(awk "BEGIN{printf \"%.0f\",$TOTAL_RPS*0.1}")

echo "Steady workload $DURATION s ( ${GET_RPS} GET/s | ${POST_RPS} POST/s )"

vegeta attack -lazy -targets="$STEADY_GET_TGT" \
       -rate="$GET_RPS" -duration="${DURATION}s" -connections "$CONC" \
       | tee "$OUTDIR/get.bin"  >/dev/null & GET_PID=$!

vegeta attack -lazy -targets="$STEADY_POST_TGT" \
       -rate="$POST_RPS" -duration="${DURATION}s" -connections "$CONC" \
       | tee "$OUTDIR/post.bin" >/dev/null & POST_PID=$!

wait $GET_PID $POST_PID

# 8. Stop stats collection
kill $STATS_PID 2>/dev/null || true

# 9. Build reports
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

# 10. Calculate attestation latency
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