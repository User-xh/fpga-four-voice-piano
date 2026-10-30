//============================================================
// 单音 DDS 模块（教学版）
// 功能：按给定频率字 FCW，输出一路正弦采样点
// 结构：相位累加器 -> 取高位 -> 查正弦ROM -> 输出幅度
// 采样时钟 Fs = 25MHz，相位累加器 32 位，正弦表 256 点
// 频率字公式：FCW = f * 2^32 / Fs
//============================================================
module dds_sin #(
    parameter PHASE_W = 32,                 // 相位累加器位宽
    parameter TABLE_BITS = 8,               // 表地址位宽 -> 256 点
    parameter DATA_W = 12,                  // 输出数据位宽
    parameter FCW = 32'd44947              // 频率字，默认中央C(261.63Hz) @25MHz
)(
    input  wire               clk,           // 采样时钟(25MHz)
    input  wire               rst_n,         // 复位，低有效
    output reg  [DATA_W-1:0] sin_out        // 当前正弦采样点(12位,中点2048)
);

    //---------- 1. 相位累加器：每个时钟加上 FCW ----------
    reg [PHASE_W-1:0] phase_acc;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            phase_acc <= {PHASE_W{1'b0}};
        else
            phase_acc <= phase_acc + FCW;
    end

    //---------- 2. 正弦ROM：256点，12位 ----------
    reg [DATA_W-1:0] rom [0:(1<<TABLE_BITS)-1];
    initial begin
        $readmemb("./sin256.txt", rom);
    end

    //---------- 3. 取累加器最高8位当表地址 ----------
    wire [TABLE_BITS-1:0] addr;
    assign addr = phase_acc[PHASE_W-1 : PHASE_W-TABLE_BITS];

    //---------- 4. 查表输出 ----------
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            sin_out <= 2048;
        else
            sin_out <= rom[addr];
    end

endmodule
