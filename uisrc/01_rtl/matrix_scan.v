//============================================================
// 4x4 矩阵键盘扫描模块（教学版，先纯仿真）
// 硬件：无源开关矩阵，4行(R1~R4) + 4列(C1~C4)，无板载上拉，
//       列线在 FPGA 内部弱上拉为高，按键按下把对应列拉到 0。
// 原理：逐行拉低 -> 读哪一列为0 -> 行号*4 + 列号 = 键号(0~15)
// 键号约定：
//   R1行 S1 S2 S3 S4 -> 键0  键1  键2  键3
//   R2行 S5 S6 S7 S8 -> 键4  键5  键6  键7
//   R3行 S9 S10 S11 S12 -> 键8 键9  键10 键11
//   R4行 S13 S14 S15 S16 -> 键12 键13 键14 键15
// 低有效：行输出被扫描行为0、其余为1；列输入按下为0、空闲为1。
// 说明：本版"读到有效键即输出"，松手保持 DEB_N 拍再清，先保证
//       行列定位正确；机械按键的严格消抖后续可在此基础上加轮次滤波。
//============================================================
module matrix_scan #(
    parameter CLK_FREQ = 25_000_000,  // 系统时钟 25MHz
    parameter SCAN_US  = 1000,        // 每行停留时间(us)，默认1ms
    parameter DEB_N     = 8            // 松手保持拍数(防抖)
)(
    input  wire        clk,            // 系统时钟
    input  wire        rst_n,          // 复位，低有效
    input  wire [3:0] col_in,         // 4列输入，低有效(内部上拉)
    output reg  [3:0] row_out,        // 4行输出，低有效，当前行=0其余=1
    output reg  [3:0] key_code,       // 当前稳定按下的键号 0~15
    output reg        key_on,         // 当前有键按下
    output reg        key_pulse       // 新键按下的单脉冲(一拍)
);

    localparam SCAN_MAX = CLK_FREQ / 1_000_000 * SCAN_US;  // 每行计数值

    //---------- 1. 扫描节拍分频：每 SCAN_US 推进一行 ----------
    reg [17:0] div;
    reg  [1:0] row_idx;              // 当前扫描行 0~3
    wire tick = (div == SCAN_MAX - 1);

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            div     <= 18'd0;
            row_idx <= 2'd0;
        end else if(tick) begin
            div     <= 18'd0;
            row_idx <= row_idx + 1'b1;     // 0->1->2->3->0 循环
        end else begin
            div <= div + 1'b1;
        end
    end

    // 当前行拉低，其余行拉高（低有效）
    always @(*) begin
        row_out = 4'b1111;
        row_out[row_idx] = 1'b0;
    end

    //---------- 2. 列号识别：哪一列为0就是哪一列 ----------
    function [1:0] col_decode(input [3:0] c);
        if(!c[0])      col_decode = 2'd0;
        else if(!c[1]) col_decode = 2'd1;
        else if(!c[2]) col_decode = 2'd2;
        else           col_decode = 2'd3;   // !c[3]
    endfunction

    wire       raw_on   = (col_in != 4'b1111);            // 有列被拉低=有键按下
    wire [3:0] raw_code = {row_idx, col_decode(col_in)}; // 行号*4 + 列号

    //---------- 3. 识别 + 松手保持 ----------
    reg [3:0] hold;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            key_code  <= 4'd0;
            key_on    <= 1'b0;
            key_pulse <= 1'b0;
            hold      <= 4'd0;
        end else if(tick) begin
            key_pulse <= 1'b0;                 // 默认每拍清掉脉冲
            if(raw_on) begin
                if((raw_code != key_code) || (!key_on))
                    key_pulse <= 1'b1;         // 新键按下给单脉冲
                key_code <= raw_code;
                key_on   <= 1'b1;
                hold     <= DEB_N;             // 刷新保持计数
            end else begin
                if(hold > 4'd0)
                    hold <= hold - 1'b1;       // 松手保持几拍再清，防抖
                else
                    key_on <= 1'b0;
            end
        end
    end

endmodule
