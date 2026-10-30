`timescale 1ns / 1ps
//============================================================
// ADSR gain动态链路：按下起音升到255、保持SUSTAIN=160、松手回0
// 复现top_audio的 key_gain 组合，证明柱高输入随包络动态变化。
//============================================================
module tb_adsr_gain_link;
    reg clk=0, rst_n=0;
    reg [15:0] key_state=0;
    always #20 clk=~clk;

    wire [3:0] v_gate; wire [127:0] v_fcw; wire [15:0] v_keynum;
    voice_assign u_assign(.key_state(key_state),.v_gate(v_gate),
                          .v_fcw(v_fcw),.v_keynum(v_keynum));
    wire [7:0] g0,g1,g2,g3;
    wire [11:0] s0,s1,s2,s3;
    voice_chan c0(.clk(clk),.rst_n(rst_n),.samp_tick(1'b1),.gate(v_gate[0]),
        .fcw(v_gate[0]?v_fcw[0*32+:32]:32'd0),.sin_out(s0),.gain_out(g0));
    voice_chan c1(.clk(clk),.rst_n(rst_n),.samp_tick(1'b1),.gate(v_gate[1]),
        .fcw(v_gate[1]?v_fcw[1*32+:32]:32'd0),.sin_out(s1),.gain_out(g1));
    voice_chan c2(.clk(clk),.rst_n(rst_n),.samp_tick(1'b1),.gate(v_gate[2]),
        .fcw(v_gate[2]?v_fcw[2*32+:32]:32'd0),.sin_out(s2),.gain_out(g2));
    voice_chan c3(.clk(clk),.rst_n(rst_n),.samp_tick(1'b1),.gate(v_gate[3]),
        .fcw(v_gate[3]?v_fcw[3*32+:32]:32'd0),.sin_out(s3),.gain_out(g3));

    wire [31:0] v_gain={g3,g2,g1,g0};
    reg [127:0] key_gain; integer k;
    always @(*) begin
        key_gain=0;
        for(k=0;k<4;k=k+1)
            if(v_gate[k]) key_gain[v_keynum[k*4+:4]*8+:8]=v_gain[k*8+:8];
    end

    integer err=0;
    initial begin
        rst_n=0; #100; rst_n=1; #50;
        // 按下键0，等到起音峰值255
        key_state=16'h0001;
        wait(g0==8'd255); #20;
        $display("起音峰值 gain=%0d (应255)",g0);
        if(g0!==8'd255) begin err=err+1; $display("峰值错"); end
        // 等到进入保持SUSTAIN=160并稳定
        wait(g0==8'd160); repeat(50) #20;
        $display("保持阶段 gain=%0d (应160)",g0);
        if(g0!==8'd160) begin err=err+1; $display("保持电平错"); end
        // 松手，等到归零
        key_state=16'h0000;
        wait(g0==8'd0); repeat(10) #20;
        $display("松手后 gain=%0d (应0)",g0);
        if(g0!==8'd0) begin err=err+1; $display("未归零"); end
        if(key_gain[7:0]!==8'd0) begin err=err+1; $display("松手柱位未清零"); end

        if(err==0) $display("=== ADSR GAIN LINK PASS (起音255/保持160/松手0) ===");
        else $display("=== ADSR GAIN FAIL err=%0d ===",err);
        $finish;
    end
    initial #20000000 $finish;
endmodule
