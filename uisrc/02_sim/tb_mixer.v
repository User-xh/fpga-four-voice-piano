`timescale 1ns / 1ps
//============================================================
// mixer 按路数归一化：n=1不被压成1/4，n=4不削波，n=0回到中点
//============================================================
module tb_mixer;
    reg [11:0] s0=0,s1=0,s2=0,s3=0;
    reg [3:0] gate=0;
    wire [11:0] mixed;
    mixer m(.s0(s0),.s1(s1),.s2(s2),.s3(s3),.gate(gate),.mixed(mixed));

    integer err=0;
    task chk(input [11:0] exp, input [63:0] msg);
        begin #1;
            $display("%s mixed=%0d (期望%0d)",msg,mixed,exp);
            if(mixed!==exp) begin err=err+1; $display("  FAIL"); end
        end
    endtask

    initial begin
        // n=0 -> 中点2048
        gate=0; s0=0; #1; chk(12'd2048,"n=0");
        // n=1 单路满幅 -> 不再除4，mixed≈4095
        gate=4'b0001; s0=12'd4095; #1; chk(12'd4095,"n=1满幅");
        // n=1 单路零点 -> 2048
        s0=12'd2048; #1; chk(12'd2048,"n=1零点");
        // n=4 四路同向满幅 -> /4后仍≈4095不削波
        gate=4'b1111; s0=12'd4095;s1=12'd4095;s2=12'd4095;s3=12'd4095; #1;
        $display("n=4满幅 mixed=%0d (应4095不削波)",mixed);
        if(mixed!==12'd4095) begin err=err+1; $display("n=4归一化错"); end

        if(err==0) $display("=== MIXER NORMALIZE PASS ===");
        else $display("=== MIXER FAIL err=%0d ===",err);
        $finish;
    end
endmodule
