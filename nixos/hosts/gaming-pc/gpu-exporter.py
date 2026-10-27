"""Prometheus exporter for the 5070 Ti, read through NVML on port 9835.

nvidia-smi segfaults on this driver build and NVML does not, so this replaces both the
old nvidia_gpu_exporter (same nvidia_smi_* names, so the dashboards and power rules
keep working) and usage/scripts/gpu_procs.py from the Proxmox days:
  nvidia_smi_*         the card: temperature, power, load, VRAM, fan, clocks
  gpu_process_*        GPU use per process, with the pod or service it belongs to
  session_process_*    CPU and memory per command in SSH sessions, which cAdvisor sees
                       as one cgroup
Runs as root on the host so it can read every process's cgroup and environment.
"""
import http.server
import os
import re
import threading
import time

import pynvml as nv

PORT = 9835
INTERVAL = 10

TICK = os.sysconf("SC_CLK_TCK")
SESSION = re.compile(r"^/user\.slice/user-\d+\.slice/session-\d+\.scope$")
POD_SUFFIX = re.compile(r"(-[0-9a-f]{8,10})?(-\d{8,})?-[a-z0-9]{5}$")
STARTED = time.time()
BOOT = float(next(l.split()[1] for l in open("/proc/stat") if l.startswith("btime")))
seen = {}         # pid -> (starttime, cpu ticks) at the last pass
session_cpu = {}  # comm -> CPU seconds, a counter that only grows

lock = threading.Lock()
body = b""


def read(path):
    try:
        with open(path, "rb") as f:
            return f.read().decode(errors="replace")
    except OSError:
        return ""


def esc(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')


def cgroup(pid):
    return read(f"/proc/{pid}/cgroup").strip().partition("::")[2]


def owner(pid):
    """k8s/<namespace>, svc/<systemd unit>, ssh, or the command name. Pods use the
    namespace like the cAdvisor panels, pod names change on every run."""
    path = cgroup(pid)
    if "/kubepods" in path:
        env = dict(kv.split("=", 1) for kv in read(f"/proc/{pid}/environ").split("\0") if "=" in kv)
        ns = env.get("POD_NAMESPACE") or env.get("KUBERNETES_NAMESPACE")
        return "k8s/" + (ns or POD_SUFFIX.sub("", env.get("HOSTNAME", "unknown")))
    units = re.findall(r"/([^/]+)\.service", path)
    if units and not units[-1].startswith("user@"):
        return "svc/" + units[-1]
    if SESSION.match(path):
        return "ssh"
    return read(f"/proc/{pid}/comm").strip() or "unknown"


def card(h, labels):
    """One gauge per reading. Readings this card doesn't support are left out."""
    out = []

    def put(name, fn, scale=1.0):
        try:
            out.append(f"nvidia_smi_{name}{{{labels}}} {fn() * scale}")
        except nv.NVMLError:
            pass

    put("temperature_gpu", lambda: nv.nvmlDeviceGetTemperature(h, nv.NVML_TEMPERATURE_GPU))
    put("power_draw_watts", lambda: nv.nvmlDeviceGetPowerUsage(h), 1e-3)
    put("enforced_power_limit_watts", lambda: nv.nvmlDeviceGetEnforcedPowerLimit(h), 1e-3)
    put("utilization_gpu_ratio", lambda: nv.nvmlDeviceGetUtilizationRates(h).gpu, 0.01)
    put("utilization_memory_ratio", lambda: nv.nvmlDeviceGetUtilizationRates(h).memory, 0.01)
    put("utilization_encoder_ratio", lambda: nv.nvmlDeviceGetEncoderUtilization(h)[0], 0.01)
    put("utilization_decoder_ratio", lambda: nv.nvmlDeviceGetDecoderUtilization(h)[0], 0.01)
    put("memory_used_bytes", lambda: nv.nvmlDeviceGetMemoryInfo(h).used)
    put("memory_total_bytes", lambda: nv.nvmlDeviceGetMemoryInfo(h).total)
    put("fan_speed_ratio", lambda: nv.nvmlDeviceGetFanSpeed(h), 0.01)
    put("clocks_current_graphics_clock_hz", lambda: nv.nvmlDeviceGetClockInfo(h, nv.NVML_CLOCK_GRAPHICS), 1e6)
    put("clocks_current_memory_clock_hz", lambda: nv.nvmlDeviceGetClockInfo(h, nv.NVML_CLOCK_MEM), 1e6)
    put("performance_state", lambda: nv.nvmlDeviceGetPerformanceState(h))
    return out


def processes(h):
    """(owner, comm) -> [sm%, mem bandwidth%, enc%, dec%, VRAM bytes, count]"""
    rows, vram = {}, {}
    for getter in (nv.nvmlDeviceGetComputeRunningProcesses, nv.nvmlDeviceGetGraphicsRunningProcesses):
        try:
            for p in getter(h):
                vram[p.pid] = max(vram.get(p.pid, 0), p.usedGpuMemory or 0)
        except nv.NVMLError:
            pass
    util = {}
    try:
        for s in nv.nvmlDeviceGetProcessUtilization(h, int((time.time() - 2 * INTERVAL) * 1e6)):
            util.setdefault(s.pid, []).append((s.smUtil, s.memUtil, s.encUtil, s.decUtil))
    except nv.NVMLError:  # NotFound when nothing ran in the window
        pass
    for pid in set(vram) | set(util):
        if not os.path.exists(f"/proc/{pid}"):
            continue
        key = (owner(pid), read(f"/proc/{pid}/comm").strip() or "unknown")
        agg = rows.setdefault(key, [0.0, 0.0, 0.0, 0.0, 0.0, 0])
        samples = util.get(pid, [])
        for i in range(4):
            agg[i] += sum(s[i] for s in samples) / len(samples) if samples else 0.0
        agg[4] += vram.get(pid, 0)
        agg[5] += 1
    return rows


def sessions():
    """CPU seconds and resident memory per command name for processes in SSH sessions.

    CPU is accumulated from per-process deltas, so it keeps counting after a process
    exits. Processes that live less than one interval are missed.
    """
    mem, alive = {}, {}
    for pid in filter(str.isdigit, os.listdir("/proc")):
        if not SESSION.match(cgroup(pid)):
            continue
        stat = read(f"/proc/{pid}/stat")
        comm = stat[stat.find("(") + 1:stat.rfind(")")]
        f = stat[stat.rfind(")") + 2:].split()
        if len(f) < 22:
            continue
        start, ticks = int(f[19]), int(f[11]) + int(f[12])
        prev = seen.get(pid)
        if prev and prev[0] == start:
            delta = ticks - prev[1]
        elif BOOT + start / TICK >= STARTED:
            delta = ticks  # started since the exporter did, count all of it
        else:
            delta = 0  # was already running at exporter start, count from now on
        session_cpu[comm] = session_cpu.get(comm, 0.0) + delta / TICK
        alive[pid] = (start, ticks)
        mem[comm] = mem.get(comm, 0) + int(f[21]) * 4096
    seen.clear()
    seen.update(alive)
    lines = ["# TYPE session_process_cpu_seconds_total counter"]
    lines += [f'session_process_cpu_seconds_total{{comm="{esc(c)}"}} {v}'
              for c, v in sorted(session_cpu.items())]
    lines.append("# TYPE session_process_memory_bytes gauge")
    lines += [f'session_process_memory_bytes{{comm="{esc(c)}"}} {v}' for c, v in sorted(mem.items())]
    return lines


def collect():
    lines, rows = [], {}
    driver = nv.nvmlSystemGetDriverVersion()
    for i in range(nv.nvmlDeviceGetCount()):
        h = nv.nvmlDeviceGetHandleByIndex(i)
        uuid = nv.nvmlDeviceGetUUID(h)
        labels = f'gpu="{i}",uuid="{uuid}"'
        lines.append(f'nvidia_smi_gpu_info{{{labels},name="{esc(nv.nvmlDeviceGetName(h))}",'
                     f'driver_version="{driver}"}} 1')
        lines += card(h, labels)
        for key, v in processes(h).items():
            agg = rows.setdefault(key, [0.0, 0.0, 0.0, 0.0, 0.0, 0])
            for j in range(6):
                agg[j] += v[j]
    names = ["sm_percent", "mem_bandwidth_percent", "encoder_percent", "decoder_percent",
             "memory_bytes", "count"]
    for j, name in enumerate(names):
        lines.append(f"# TYPE gpu_process_{name} gauge")
        for (own, comm), v in sorted(rows.items()):
            lines.append(f'gpu_process_{name}{{owner="{esc(own)}",comm="{esc(comm)}"}} {v[j]}')
    lines += sessions()
    lines.append(f"gpu_exporter_last_success_seconds {time.time()}")
    return ("\n".join(lines) + "\n").encode()


def loop():
    global body
    while True:
        try:
            new = collect()
            with lock:
                body = new
        except Exception as e:  # keep serving the last good sample
            print("collect failed:", e, flush=True)
        time.sleep(INTERVAL)


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        with lock:
            data = body
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; version=0.0.4")
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    nv.nvmlInit()
    threading.Thread(target=loop, daemon=True).start()
    http.server.ThreadingHTTPServer(("", PORT), Handler).serve_forever()
