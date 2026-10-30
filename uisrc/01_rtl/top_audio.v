//============================================================
// 完整音频链顶层（教学版，先纯仿真）
// keyscan_multi -> voice_assign -> 4路dds_nco -> mixer
//   -> audio_out(48k采样/16位PCM) -> i2s_tx(BCK/LRCK/DIN)
//============================================================
module top_audio #(
    parameter CLK_FREQ = 25_000_000,
    parameter SCAN_US  = 1000
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [3:0] col_in,
    output wire [3:0] row_out,
    output wire        bck,
    output wire        lrck,
    output wire        din,
    // 引出给可视化
    output wire [15:0] key_state_o,
    output wire [11:0] mix_sample,
    output wire        samp_vld,
    output wire [127:0] key_gain_o   // 16键各8位音量(ADSR gain)
);

    wire [15:0] key_state;
    wire [3:0]  v_gate;
    wire [127:0] v_fcw;
    wire [15:0] v_keynum;
    wire [7:0]  g0,g1,g2,g3;
    wire [31:0] v_gain = {g3,g2,g1,g0};
    wire [11:0] s0, s1, s2, s3;
    wire [11:0] mixed;
    wire [15:0] l_data, r_data;
    wire        samp_tick;

    assign key_state_o = key_state;
    assign mix_sample  = mixed;
    assign samp_vld    = samp_tick;

    // 把4路gain按占用键号摊到16键音量数组
    reg [127:0] key_gain;
    integer k;
    always @(*) begin
        key_gain = 128'd0;
        for(k=0;k<4;k=k+1)
            if(v_gate[k])
                key_gain[v_keynum[k*4 +: 4]*8 +: 8] = v_gain[k*8 +: 8];
    end
    assign key_gain_o = key_gain;

    keyscan_multi #(.CLK_FREQ(CLK_FREQ), .SCAN_US(SCAN_US)) u_scan (
        .clk(clk), .rst_n(rst_n), .col_in(col_in),
        .row_out(row_out), .key_state(key_state)
    );

    voice_assign u_assign (.key_state(key_state), .v_gate(v_gate),
                           .v_fcw(v_fcw), .v_keynum(v_keynum));

    voice_chan c0 (.clk(clk), .rst_n(rst_n), .samp_tick(samp_tick), .gate(v_gate[0]),
                    .fcw(v_gate[0] ? v_fcw[0*32 +:32] : 32'd0),
                    .sin_out(s0), .gain_out(g0));
    voice_chan c1 (.clk(clk), .rst_n(rst_n), .samp_tick(samp_tick), .gate(v_gate[1]),
                    .fcw(v_gate[1] ? v_fcw[1*32 +:32] : 32'd0),
                    .sin_out(s1), .gain_out(g1));
    voice_chan c2 (.clk(clk), .rst_n(rst_n), .samp_tick(samp_tick), .gate(v_gate[2]),
                    .fcw(v_gate[2] ? v_fcw[2*32 +:32] : 32'd0),
                    .sin_out(s2), .gain_out(g2));
    voice_chan c3 (.clk(clk), .rst_n(rst_n), .samp_tick(samp_tick), .gate(v_gate[3]),
                    .fcw(v_gate[3] ? v_fcw[3*32 +:32] : 32'd0),
                    .sin_out(s3), .gain_out(g3));

    mixer u_mix (.s0(s0), .s1(s1), .s2(s2), .s3(s3),
                 .gate(v_gate), .mixed(mixed));

    audio_out u_ao (.clk(clk), .rst_n(rst_n), .mixed(mixed),
                    .l_data(l_data), .r_data(r_data), .samp_tick(samp_tick));

    i2s_tx u_i2s (.clk(clk), .rst_n(rst_n),
                  .l_data(l_data), .r_data(r_data),
                  .bck(bck), .lrck(lrck), .din(din));

endmodule
