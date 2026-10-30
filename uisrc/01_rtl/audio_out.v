//============================================================
// 音频输出打包：混音12位 -> 16位有符号PCM，48k采样锁存送I2S
// mixed 为12位无符号(中点2048)，先去直流再左移4位放大成16位有符号。
// 采样率：25MHz / SAMPLE_DIV，默认520 ≈ 48.08kHz。
// 单声道：左右声道送同一个样本。
//============================================================
module audio_out #(
    parameter SAMPLE_DIV = 520
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [11:0] mixed,
    output reg  [15:0] l_data,
    output reg  [15:0] r_data,
    output wire        samp_tick      // 48k采样节拍(供可视化取样本)
);
    reg [9:0] div;
    wire tick = (div == SAMPLE_DIV-1);
    assign samp_tick = tick;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) div <= 10'd0;
        else       div <= div + 1'b1;
    end

    // 去直流：mixed-2048(13位有符号)，再<<4成16位有符号
    wire signed [12:0] ac = $signed({1'b0, mixed}) - 13'sd2048;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            l_data <= 16'sd0;
            r_data <= 16'sd0;
        end else if(tick) begin
            l_data <= ac << 4;
            r_data <= ac << 4;
        end
    end

endmodule
