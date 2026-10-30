`timescale 1ns / 1ps
//============================================================
// adsr_env 快速电平验证：samp_tick恒1(每clk一拍)，只验 0->255->160->0
// 真实毫秒时长由 tb_adsr_ms.v 验证。
//============================================================
module tb_adsr;
    reg clk=1'b0; reg rst_n; reg gate;
    wire [7:0] gain;
    integer maxg=0;
    always #20 clk=~clk;

    adsr_env #(.SUSTAIN(8'd160))
             u(.clk(clk),.rst_n(rst_n),.samp_tick(1'b1),.gate(gate),.gain(gain));

    initial begin
        rst_n=0; gate=0; #200; rst_n=1;
        repeat(50) @(posedge clk);
        // 按下：起音到255
        gate=1;
        wait(gain==8'd255); maxg=255; repeat(5) @(posedge clk);
        // 等进入保持160
        wait(gain==8'd160); repeat(5) @(posedge clk);
        // 松手：应释放到0
        gate=0;
        wait(gain==8'd0); repeat(5) @(posedge clk);
        $display("峰值max=%0d 保持段hold=%0d 松手后gain=%0d",maxg,160,gain);
        if(maxg==255 && gain==0) $display("=== ADSR PASS ===");
        else $display("=== CHECK ADSR ===");
        $finish;
    end
    initial #2000000 $finish;
    initial begin $dumpfile("adsr.vcd"); $dumpvars(0,tb_adsr); end
endmodule
