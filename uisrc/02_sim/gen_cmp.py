import json, math
tab=[2048+2047*math.sin(2*math.pi*i/256) for i in range(256)]
def dds(FCW, steps):
    ph=0; out=[]
    for _ in range(steps):
        ph=(ph+FCW)&0xFFFFFFFF
        out.append(round(tab[ph>>24]))
    return out
N=120000
c4=dds(44947,N); a4=dds(75591,N)
# 降采样到300点
step=N//300
c4=c4[::step]; a4=a4[::step]
a4_up=[v+2500 for v in a4]
json.dump({"c4":c4,"a4_up":a4_up}, open(r"D:\FPGA-2\my_projects\my_dds\uisrc\02_sim\freq.json","w"))
def peaks(v):
    return sum(1 for i in range(1,len(v)-1) if v[i]>=4090 and v[i]>=v[i-1] and v[i]>=v[i+1])
print("C4峰数≈",peaks(c4)," A4峰数≈",peaks(a4)," 点长",len(c4))
