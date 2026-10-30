# 基于 FPGA 的四复音电子琴 —— 竞赛代码包说明

## 一、作品概况
- 作品名称：基于 FPGA 的四复音电子琴
- FPGA 器件：安路 PH1A180SFG676（Family=PH1，Speed=-2），承载板为米联客 MLK-H10（含 DDR3 核心板）
- 顶层模块：top_system（音频链 top_audio + 预留可视化 top_viz）
- 开发工具：唐 IDE（TangDynasty Release_2026.1_SP3）；仿真工具 Icarus Verilog v14（-g2012）
- 主时钟：板载 Y23，25 MHz，LVCMOS33
- 功能：4×4 矩阵键盘输入，最多 4 路复音并行合成；每路 DDS 正弦 + ADSR 包络；按发声路数动态归一化混音；48.08 kHz 采样、16 bit 有符号、I2S 时序输出至 PCM5102A DAC 接耳机/音箱。

## 二、目录结构
```
四复音电子琴_FPGA代码包/
├─ my_dds.al                         唐 IDE 工程文件（双击/在 IDE 中打开此文件）
├─ uisrc/
│  ├─ 01_rtl/                        RTL 设计源码（含音频链与预留可视化模块）
│  ├─ 02_sim/                        各模块测试台 tb_*.v、辅助脚本与仿真结果文本
│  ├─ 03_rom/                        正弦查找表数据 sin256.txt
│  └─ 04_pin/fpga_pin.adc            板级引脚约束
├─ my_dds_Runs/
│  ├─ syn_1/                         综合结果（时序、面积、日志文本）
│  ├─ phy_1/                         布局布线结果（时序报告、QoR、日志文本）
│  └─ best_result/my_dds.bit         最终下载比特流（约 9.0 MB）
├─ docs/                             接线说明与音频链技术文档
├─ 板级综合对照.md
└─ README_代码包说明.md              本文件
```

### 音频链源码模块对应关系（01_rtl）
| 模块 | 作用 |
|---|---|
| keyscan_multi.v | 4×4 矩阵扫描，每行 1 ms，低有效，支持多键同时按下 |
| voice_assign.v | 16 位图分配至多 4 个音槽，低键优先，输出门控与频率字 |
| voice_chan.v | 单声道封装：dds_nco + adsr_env，包络调制后限幅输出 |
| dds_nco.v | 32 位相位累加器，高 8 位索引 256 点 12 bit 正弦表 |
| adsr_env.v | 48 kHz 节拍驱动的起音/衰减/保持/释音包络（10/80/200 ms，保持 160） |
| mixer.v | 四路去直流后按实际有效路数归一化相加，限幅 0~4095 |
| audio_out.v | 25 MHz/520 ≈ 48.08 kHz 采样节拍，去直流并放大为 16 bit 有符号左右声道 |
| i2s_tx.v | BCK=3.125 MHz，32 槽/声道，MSB 先出，输出 bck/lrck/din |
| top_audio.v | 音频链顶层互连；top_system.v 总顶层 |

## 三、主要对外引脚（详见 uisrc/04_pin/fpga_pin.adc）
- 键盘列输入 col_in：AC4、AC3、V2、V1（内部上拉，低有效）
- 键盘行输出 row_out：Y6、Y5、AF5、AF4
- 音频：bck=AF3，lrck=AF2，din=AE3（均属 BANK33，LVCMOS18）
- 预留可视化：oled_scl=AE2，oled_sda=AD1

## 四、复现步骤
1. 打开唐 IDE，通过“打开工程”载入本目录的 `my_dds.al`；确认 01_rtl、02_sim 引用路径完整。
2. 依次执行综合（Synthesis）→ 布局布线（Place & Route / P&R）→ 比特流生成（Bitstream Generate）；产物位于 `my_dds_Runs/best_result/my_dds.bit`。
3. 仿真（可选）：在 `uisrc/02_sim` 下用 Icarus v14 对对应 `tb_*.v` 与 01_rtl 源文件联合 `iverilog -g2012` 编译后 `vvp` 运行；各 `*.out` 为对应测试台的已通过结果文本。
4. 板级下载：唐 IDE 编程器连接开发板（PROGRAM_SRAM 易失，断电后需重新下载）。

## 五、关键量化参数
- 音域：16 键，261.63 Hz（C4）~ 622.25 Hz（D#5），一个八度加大二度全半音
- 采样率 25 MHz / 520 ≈ 48.08 kHz；BCK 25 MHz / 8 = 3.125 MHz；LRCK ≈ 48.83 kHz
- 单路：12 bit 样本（中点 2048）；混音后 16 bit 有符号输出
- 综合收敛：建立时间裕量约 +7186 ps，保持时间裕量约 +127 ps，布线错误 FEPS = 0

## 六、本压缩包刻意排除的文件（可在本地由流程重新生成，无评审价值且体积巨大）
- `*.vcd` 波形文件（合计约 1.9 GB，仿真观测用）
- `*.vvp` 仿真可执行文件、`*.db` 布线中间库、`*.dmp` 崩溃转储、`.f` 临时占位文件
- 重复生成的非最终 bit 与 IDE 顶层控制台日志
- 官方示例工程与参考资料目录（不属于本作品代码）

## 七、当前完成状态说明
- 音频合成链：全部子模块与完整链回归仿真通过（PASS），综合、布局布线与比特流生成成功并下载到板。
- 可视化（OLED）：驱动与显存刷新逻辑、波形与频谱柱渲染已完成仿真并纳入顶层预留接口，硬件点亮联调仍在进行；本包保留其源码以便复现，不作为已完成硬件功能。
- 外置 DAC（PCM5102A）出声联调、整机实物照片为后续补充项。
