//============================================================
// 单声通道 = DDS + ADSR包络增益缩放
// 去直流样本 × gain/256，再加回直流并钳位到12位，供mixer去直流相加。
// ADSR由48k samp_tick驱动(真实毫秒)。
//============================================================
module voice_chan #(
    parameter ATTACK_MS  = 10,
    parameter DECAY_MS   = 80,
    parameter RELEASE_MS = 200,
    parameter SUSTAIN    = 8'd160
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        samp_tick,
    input  wire        gate,
    input  wire [31:0] fcw,
    output wire [11:0] sin_out,
    output wire [7:0]  gain_out
);
    wire [11:0] sin_raw;
    wire [7:0]  gain;

    dds_nco u_nco (.clk(clk), .rst_n(rst_n), .fcw(fcw), .sin_out(sin_raw));
    adsr_env #(.ATTACK_MS(ATTACK_MS),.DECAY_MS(DECAY_MS),
               .RELEASE_MS(RELEASE_MS),.SUSTAIN(SUSTAIN))
             u_env (.clk(clk), .rst_n(rst_n), .samp_tick(samp_tick),
                    .gate(gate), .gain(gain));
    assign gain_out = gain;

    // 去直流 -> 乘增益/256 -> 加回直流 -> 钳位
    wire signed [12:0] ac = $signed({1'b0, sin_raw}) - 13'sd2048;
    wire signed [21:0]  p  = ac * $signed({1'b0, gain});
    wire signed [12:0]  sc = (p >>> 8) + 13'sd2048;

    assign sin_out = (sc < 0)        ? 12'd0  :
                     (sc > 4095)     ? 12'd4095 : sc[11:0];

endmodule
