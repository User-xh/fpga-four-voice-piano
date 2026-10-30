import json
vcd = r"D:\FPGA-2\my_projects\my_dds\uisrc\02_sim\dds_sin.vcd"
cur = None
vals = []
with open(vcd, "r", errors="ignore") as f:
    for line in f:
        line = line.strip()
        if line.startswith("b") and line.endswith("!"):
            bits = line[1:].split()[0]
            v = int(bits, 2)
            if cur is None or v != cur:
                cur = v
                vals.append(v)
# 降采样到约300点，便于绘图
step = max(1, len(vals)//300)
ds = vals[::step]
out = r"D:\FPGA-2\my_projects\my_dds\uisrc\02_sim\sin_series.json"
json.dump(ds, open(out,"w"))
print("total", len(vals), "downsampled", len(ds), "min", min(vals), "max", max(vals))
