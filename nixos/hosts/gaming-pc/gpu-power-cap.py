# Caps the 5070 Ti while the case runs hot (CPU at 90 C, hard reset on 27 Oct 2026).
# 250 W is the lowest limit the card takes, the clock cap brings full load to about 200 W.
# Undo by stopping gpu-power-cap and rebooting, or drop it once the BIOS fan curve is set.
import pynvml as nvml

POWER_LIMIT_MW = 250_000
MAX_CLOCK_MHZ = 2400


def main():
    nvml.nvmlInit()
    gpu = nvml.nvmlDeviceGetHandleByIndex(0)
    nvml.nvmlDeviceSetPowerManagementLimit(gpu, POWER_LIMIT_MW)
    nvml.nvmlDeviceSetGpuLockedClocks(gpu, 0, MAX_CLOCK_MHZ)
    limit = nvml.nvmlDeviceGetPowerManagementLimit(gpu) / 1000
    print(f"power limit {limit:.0f} W, graphics clock at most {MAX_CLOCK_MHZ} MHz")


main()
