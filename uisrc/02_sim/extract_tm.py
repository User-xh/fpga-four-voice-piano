import json
def sample(path, step_ns, end_ns):
    cur=2048; t=0; out=[]; next_t=0
    with open(path,"r",errors="ignore") as f:
        for line in f:
            line=line.strip()
            if line.startswith("#"):
                t=int(line[1:])
                while next_t<=t and next_t<=end_ns:
                    out.append(cur); next_t+=step_ns
            elif line.startswith("b") and line.endswith("!"):
                cur=int(line[1:].split()[0],2)
    return out

c4=sample(r"D:\FPGA-2\my_projects\my_dds\uisrc\02_sim\dds_sin.vcd", 20000, 2_000_000)
a4=sample(r"D:\FPGA-2\my_projects\my_dds\uisrc\02_sim\dds_a4.vcd", 20000, 2_000_000)
json.dump({"c4":c4,"a4":a4}, open(r"D:\FPGA-2\my_projects\my_dds\uisrc\02_sim\tm.json","w"))
print("c4 n=",len(c4),"a4 n=",len(a4))
# 数峰(接近4095)个数
def peaks(v):
    return sum(1 for i in range(1,len(v)-1) if v[i]>=4090 and v[i]>=v[i-1] and v[i]>=v[i+1])
print("C4 峰数≈",peaks(c4)," A4 峰数≈",peaks(a4))
