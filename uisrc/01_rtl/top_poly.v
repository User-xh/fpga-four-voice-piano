//============================================================
// 复音电子琴顶层（教学版，先纯仿真）
// keyscan_multi(多键位图) -> voice_assign(分4槽/给FCW)
//   -> 4路并行 dds_nco -> mixer(去直流相加/4加回中点)
//============================================================
module top_poly #(
    parameter CLK_FREQ = 25_000_000,
    parameter SCAN_US  = 1000
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [3:0] col_in,
    output wire [3:0] row_out,
    output wire [11:0] mixed
);

    wire [15:0] key_state;
    wire [3:0]  v_gate;
    wire [127:0] v_fcw;
    wire [11:0] s0, s1, s2, s3;

    keyscan_multi #(.CLK_FREQ(CLK_FREQ), .SCAN_US(SCAN_US)) u_scan (
        .clk(clk), .rst_n(rst_n), .col_in(col_in),
        .row_out(row_out), .key_state(key_state)
    );

    voice_assign u_assign (
        .key_state(key_state), .v_gate(v_gate), .v_fcw(v_fcw)
    );

    dds_nco d0 (.clk(clk), .rst_n(rst_n),
                .fcw(v_gate[0] ? v_fcw[0*32 +:32] : 32'd0), .sin_out(s0));
    dds_nco d1 (.clk(clk), .rst_n(rst_n),
                .fcw(v_gate[1] ? v_fcw[1*32 +:32] : 32'd0), .sin_out(s1));
    dds_nco d2 (.clk(clk), .rst_n(rst_n),
                .fcw(v_gate[2] ? v_fcw[2*32 +:32] : 32'd0), .sin_out(s2));
    dds_nco d3 (.clk(clk), .rst_n(rst_n),
                .fcw(v_gate[3] ? v_fcw[3*32 +:32] : 32'd0), .sin_out(s3));

    mixer u_mix (
        .s0(s0), .s1(s1), .s2(s2), .s3(s3),
        .gate(v_gate), .mixed(mixed)
    );

endmodule
