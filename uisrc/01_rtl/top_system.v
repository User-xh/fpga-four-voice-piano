//============================================================
// 系统总顶层：音频链(top_audio) + 音乐可视化(top_viz)
// 按键 -> 复音DDS/ADSR/混音 -> I2S(PCM5102A)
//                 \-> mixed样本 + key_state -> OLED波形/柱(I2C)
// 板级物理脚：键盘col/row、I2S(bck/lrck/din)、OLED(scl/sda)
//============================================================
module top_system #(
    parameter CLK_FREQ = 25_000_000
)(
    input  wire        clk,
    input  wire        rst_n,
    // 4x4矩阵键盘
    input  wire [3:0]  col_in,
    output wire [3:0]  row_out,
    // I2S -> PCM5102A
    output wire        bck,
    output wire        lrck,
    output wire        din,
    // I2C -> SSD1306 OLED(4脚)
    output wire        oled_scl,
    output wire        oled_sda
);
    // ---- 音频链引出 ----
    wire [15:0] ks;
    wire [11:0] mix;
    wire        vld;
    wire [127:0] kg;

    top_audio #(.CLK_FREQ(CLK_FREQ)) au (
        .clk(clk), .rst_n(rst_n),
        .col_in(col_in), .row_out(row_out),
        .bck(bck), .lrck(lrck), .din(din),
        .key_state_o(ks), .mix_sample(mix), .samp_vld(vld),
        .key_gain_o(kg)
    );

    // ---- 20ms 帧节拍(500000 cycles @25MHz) ----
    localparam FRAME_CNT = 500_000;
    reg [18:0] fcnt;
    reg frame_tick;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin fcnt<=0; frame_tick<=0; end
        else if(fcnt>=FRAME_CNT-1) begin fcnt<=0; frame_tick<=1; end
        else begin fcnt<=fcnt+1'b1; frame_tick<=0; end
    end

    // ---- 可视化 ----
    // DIV=31: SCL周期约4*31拍@25MHz≈200kHz，适配SSD1306 I2C上限400kHz以内
    top_viz #(.DIV(31)) vz (
        .clk(clk), .rst_n(rst_n),
        .sample(mix), .sample_vld(vld),
        .key_state(ks), .key_gain(kg), .frame_in(frame_tick),
        .oled_scl(oled_scl), .oled_sda(oled_sda),
        .init_done(), .frame_done(), .flush_done()
    );
endmodule
