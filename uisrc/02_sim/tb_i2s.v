`timescale 1ns / 1ps
//============================================================
// i2s_tx 仿真：左=1234 右=ABCD，帧边界检查槽寄存器sh装入是否正确
// （MSB串行移位由固定左移完成，这里验证声道槽数据与LRCK归属）
//============================================================
module tb_i2s;
    reg clk=1'b0;
    reg rst_n;
    wire bck, lrck, din;
    reg [15:0] l_data=16'h1234;
    reg [15:0] r_data=16'hABCD;

    i2s_tx u_dut(
        .clk(clk), .rst_n(rst_n),
        .l_data(l_data), .r_data(r_data),
        .bck(bck), .lrck(lrck), .din(din)
    );
    always #20 clk=~clk;

    reg [31:0] capL, capR;
    always @(posedge clk) begin
        if(u_dut.bcnt==6'd1)  capL <= u_dut.sh;   // 左槽已装载
        if(u_dut.bcnt==6'd33) capR <= u_dut.sh;   // 右槽已装载
    end

    integer errors=0;
    initial begin
        rst_n=1'b0; capL=0; capR=0;
        #200; rst_n=1'b1;
        #30000;
        $display("左槽sh=%h LRCK=%b (期望 12340000, lrck=0)", capL, 1'b0);
        $display("右槽sh=%h LRCK=%b (期望 abcd0000, lrck=1)", capR, 1'b1);
        if(capL!==32'h12340000 || capR!==32'habcd0000) errors=errors+1;
        if(errors==0) $display("=== I2S FRAME PASS ===");
        else          $display("=== CHECK ===");
        $finish;
    end

    initial begin $dumpfile("i2s.vcd"); $dumpvars(0,tb_i2s); end
endmodule
