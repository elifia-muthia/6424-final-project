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
URL="https://34.162.223.243:443"
DURATION=120        
TOTAL_RPS=100  
CONC=64 # concurrent live connections
PREFILL_USERS=1000
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

# 2. To measure FitHealth container's CPU % usage and Memory utilization per 1 HZ
STATS_FILE="$OUTDIR/stats.csv"
echo "timestamp,cpu%,mem_used" >"$STATS_FILE"
docker run --rm --network=host -v /var/run/docker.sock:/var/run/docker.sock:ro \
  bash:5 bash -c "
    while true; do
      docker stats --no-stream --format '{{.CPUPerc}},{{.MemUsage}}' $NAME |
      awk -v ts=\$(date +%s) -F',' '{gsub(/%/,\"\",\$1); gsub(/ .*/,\"\",\$2);print ts\",\" \$1\",\" \$2}'
      sleep 1
    done" >>"$STATS_FILE" &
STATS_PID=$!
trap 'kill $STATS_PID 2>/dev/null || true' EXIT

# 3. Create dummy JSON to insert
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

# 4. Prepare requests to send
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
  echo "GET  $URL/fetch/$i" >>"$STEADY_GET_TGT"
done

# 5. Set Attestation start time
START_TS_MS=$(($(date +%s%N)/1000000))

# 6. Prefill data
echo "Prefilling $PREFILL_USERS users …"
vegeta attack -keepalive -targets="$PREFILL_TGT" \
       -rate=200 -duration=5s -connections "$CONC" | vegeta report

### 7. Mixed workload (90% GET, 10% POST)
GET_RPS=$(awk "BEGIN{printf \"%.0f\",$TOTAL_RPS*0.9}")
POST_RPS=$(awk "BEGIN{printf \"%.0f\",$TOTAL_RPS*0.1}")
echo "Steady $DURATION s  (${GET_RPS} GET/s | ${POST_RPS} POST/s)"

START_TS_MS=$(($(date +%s%N)/1000000))   # for attestation latency

vegeta attack -keepalive -lazy -targets="$GET_TGT" \
       -rate="$GET_RPS"  -duration="${DURATION}s" -connections "$CONC" \
       | tee "$OUTDIR/get.bin"  >/dev/null & GPID=$!

vegeta attack -keepalive -lazy -targets="$POST_TGT" \
       -rate="$POST_RPS" -duration="${DURATION}s" -connections "$CONC" \
       | tee "$OUTDIR/post.bin" >/dev/null & PPID=$!

wait $GPID $PPID

# 8. Latency / Throughput Reports
summary () {
  vegeta report -type=json "$1" |
  jq --arg ep "$2" '{endpoint:$ep,throughput:.throughput,
        p50:.latencies["50th"],p95:.latencies["95th"],p99:.latencies["99th"]}'
}
jq -s 'add' \
  <(summary "$OUTDIR/get.bin"  "GET") \
  <(summary "$OUTDIR/post.bin" "POST") \
  | tee "$OUTDIR/latency_throughput.json"

# 9. Calculate attestation latency
KEY_LINE=$(docker logs "$NAME" --timestamps 2>&1 | grep -m1 'KEY_RETRIEVED' || true)
if [[ -n $KEY_LINE ]]; then
  KEY_TS_MS=$(date --date="$(cut -d' ' -f1 <<<"$KEY_LINE")" +%s%3N)
  echo "{\"attestation_ms\":$((KEY_TS_MS-START_TS_MS))}" | tee "$OUTDIR/attestation.json"
else
  echo '{"attestation_ms":null}' | tee "$OUTDIR/attestation.json"
fi

# DONE
echo "Done!"
echo "Results saved under $OUTDIR"