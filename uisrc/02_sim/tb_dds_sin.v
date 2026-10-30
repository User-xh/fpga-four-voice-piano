`timescale 1ns / 1ps
//============================================================
// dds_sin 的仿真 testbench（配合 Icarus/ModelSim 均可）
// 生成25MHz时钟(周期40ns)，复位后观察 sin_out，导出VCD波形
//============================================================
module tb_dds_sin;

    localparam PHASE_W = 32;
    localparam DATA_W  = 12;

    reg               clk;
    reg               rst_n;
    wire [DATA_W-1:0] sin_out;

    // 例化被测模块（中央C FCW=44947）
    dds_sin #(
        .FCW(32'd44947)
    ) u_dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .sin_out (sin_out)
    );

    // 25MHz 时钟，周期40ns
    initial clk = 1'b0;
    always #20 clk = ~clk;

    // 复位序列 + 运行时长
    initial begin
        rst_n = 1'b0;
        #200;
        rst_n = 1'b1;
        // 跑足够时间观察若干个正弦周期
        #20000000;   // 20ms
        $finish;
    end

    // 导出VCD波形（GTKWave可打开）
    initial begin
        $dumpfile("dds_sin.vcd");
        $dumpvars(0, tb_dds_sin);
    end

endmodule
