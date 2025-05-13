import time, threading, pathlib, json

CPU_STAT   = pathlib.Path("/sys/fs/cgroup/cpu.stat")
MEM_STAT   = pathlib.Path("/sys/fs/cgroup/memory.current")

INTERVAL_MS = 1.0 

latest_sample = {}
LOG_PATH = "/var/log/metrics.log" # persistent log file

def _read_counters():
    with CPU_STAT.open() as f:
        cpu = {k: int(v) for k, v in
                (line.split() for line in f if line.strip())}

    memory_bytes = int(MEM_STAT.read_text())
    return cpu["usage_usec"], memory_bytes      # cumulative us & bytes

def _sampler():
    prev_cpu, _ = _read_counters()
    prev_t      = time.time_ns()

    while True:
        time.sleep(INTERVAL_MS / 1000)          # sleep one quantum
        cpu, mem     = _read_counters()
        now          = time.time_ns()

        # dCPU/dtime gives utilisation across all cores
        cpu_delta_ns = (cpu - prev_cpu) * 1_000        # us → ns
        wall_delta   = now - prev_t
        cpu_pct      = cpu_delta_ns / wall_delta * 100

        sample = {
            "timestamp_ms": int(now / 1e6),
            "cpu_percent": round(cpu_pct, 2),
            "mem_bytes": mem
        }

        latest_sample.update(sample)

        # Persist sample to log file
        try:
            with open(LOG_PATH, 'a') as lf:
                lf.write(json.dumps(sample) + "\n")
        except Exception:
            # Prevent logging failures from stopping the sampler
            pass

        prev_cpu, prev_t = cpu, now

# start background sampler once when module is imported
threading.Thread(target=_sampler, daemon=True).start()
