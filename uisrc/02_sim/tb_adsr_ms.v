`timescale 1ns / 1ps
//============================================================
// ADSR 真实毫秒验证：用520分频产生48k samp_tick，测量
// 起音到255≈10ms、保持160、松手到0≈200ms(斜率取整允许±30%)。
//============================================================
module tb_adsr_ms;
    reg clk=0, rst_n=0, gate=0;
    wire [7:0] gain;
    always #20 clk=~clk;

    // 48k tick：25MHz/520
    reg [9:0] div;
    reg samp_tick;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin div<=0; samp_tick<=0; end
        else if(div==519) begin div<=0; samp_tick<=1; end
        else begin div<=div+1'b1; samp_tick<=0; end
    end

    adsr_env u(.clk(clk),.rst_n(rst_n),.samp_tick(samp_tick),.gate(gate),.gain(gain));

    integer t0,t1,t2,t3;
    integer err=0;
    real attack_ms, rel_ms;
    initial begin
        rst_n=0; #200; rst_n=1; repeat(20) @(posedge clk);
        // 按下
        gate=1; t0=$time;
        wait(gain==8'd255); @(posedge clk); t1=$time;
        attack_ms=(t1-t0)/1_000_000.0;
        $display("起音到255 = %.2f ms (目标10ms)",attack_ms);
        if(attack_ms<7 || attack_ms>14) begin err=err+1; $display("起音时长超差"); end
        // 等进入保持160
        wait(gain==8'd160); repeat(10) @(posedge clk);
        $display("保持段 gain=%0d (应160)",gain);
        if(gain!==8'd160) begin err=err+1; $display("保持电平错"); end
        // 松手
        gate=0; t2=$time;
        wait(gain==8'd0); @(posedge clk); t3=$time;
        rel_ms=(t3-t2)/1_000_000.0;
        $display("释音到0 = %.2f ms (目标200ms)",rel_ms);
        if(rel_ms<150 || rel_ms>280) begin err=err+1; $display("释音时长超差"); end

        if(err==0) $display("=== ADSR MS PASS (真实毫秒包络) ===");
        else $display("=== ADSR MS FAIL err=%0d ===",err);
        $finish;
    end
    initial #600000000 $finish;  // 600ms兜底
endmodule
