`timescale 1ns / 1ps
// A4(440Hz) FCW=75591 @25MHz，用于对比中央C
module tb_dds_a4;
    localparam DATA_W = 12;
    reg clk=1'b0;
    reg rst_n;
    wire [DATA_W-1:0] sin_out;

    dds_sin #(.FCW(32'd75591)) u_dut (
        .clk(clk), .rst_n(rst_n), .sin_out(sin_out)
    );

    always #20 clk = ~clk;   // 25MHz

    initial begin
        rst_n=1'b0; #200; rst_n=1'b1;
        #20000000;
        $finish;
    end

    initial begin
        $dumpfile("dds_a4.vcd");
        $dumpvars(0, tb_dds_a4);
    end
endmodule
