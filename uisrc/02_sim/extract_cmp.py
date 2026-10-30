import json
def extract(path, sym='!'):
    cur=None; vals=[]
    with open(path,"r",errors="ignore") as f:
        for line in f:
            line=line.strip()
            if line.startswith("b") and line.endswith(sym):
                v=int(line[1:].split()[0],2)
                if cur is None or v!=cur:
                    cur=v; vals.append(v)
    return vals

c4=extract(r"D:\FPGA-2\my_projects\my_dds\uisrc\02_sim\dds_sin.vcd")
a4=extract(r"D:\FPGA-2\my_projects\my_dds\uisrc\02_sim\dds_a4.vcd")
N=400
c4=c4[:N]; a4=a4[:N]
# A4上移2500避免与C4重叠
a4_up=[v+2500 for v in a4]
json.dump({"c4":c4,"a4_up":a4_up}, open(r"D:\FPGA-2\my_projects\my_dds\uisrc\02_sim\cmp.json","w"))
def periods(v):
    mid=2048; c=0; prev=v[0]
    for x in v[1:]:
        if (prev-mid)*(x-mid)<0: c+=1
        prev=x
    return c//2
print("C4前400点周期数≈",periods(c4)," A4前400点周期数≈",periods(a4))
