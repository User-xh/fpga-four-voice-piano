//============================================================
// 电子琴顶层（教学版，先纯仿真）
// 串联：4x4矩阵扫描 -> 音符查表(键号->FCW) -> 动态DDS出正弦
// 对外：clk/rst_n/col_in/row_out(键盘) + sin_out(待送DAC)
//============================================================
module top_organ #(
    parameter CLK_FREQ = 25_000_000,
    parameter SCAN_US  = 1000
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [3:0] col_in,
    output wire [3:0] row_out,
    output wire [11:0] sin_out
);

    // 内部连线
    wire [3:0] key_code;
    wire       key_on;
    wire       key_pulse;
    wire [31:0] fcw;

    // 1. 矩阵扫描
    matrix_scan #(.CLK_FREQ(CLK_FREQ), .SCAN_US(SCAN_US)) u_scan (
        .clk(clk), .rst_n(rst_n),
        .col_in(col_in), .row_out(row_out),
        .key_code(key_code), .key_on(key_on), .key_pulse(key_pulse)
    );

    // 2. 键号 -> 频率字
    note_lut u_lut (
        .clk(clk), .rst_n(rst_n),
        .key_pulse(key_pulse), .key_code(key_code),
        .fcw(fcw)
    );

    // 3. 动态DDS出正弦
    dds_nco u_dds (
        .clk(clk), .rst_n(rst_n),
        .fcw(fcw), .sin_out(sin_out)
    );

endmodule
