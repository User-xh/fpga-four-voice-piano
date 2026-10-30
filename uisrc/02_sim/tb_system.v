`timescale 1ns / 1ps
//============================================================
// top_system 串联仿真(I2C)：音频链+可视化编译连通，OLED完成至少一次刷屏
// 无键(col_in全1)，重点验证顶层可链接、init后flush正常出帧。
//============================================================
module tb_system;
    reg clk=0, rst_n=0;
    reg [3:0] col_in=4'b1111;
    wire [3:0] row_out;
    wire bck,lrck,din,oscl,osda;
    top_system #(.CLK_FREQ(25_000_000)) dut(
        .clk(clk),.rst_n(rst_n),.col_in(col_in),.row_out(row_out),
        .bck(bck),.lrck(lrck),.din(din),
        .oled_scl(oscl),.oled_sda(osda));
    always #20 clk=~clk;

    integer err=0;
    integer bck_edges=0;
    reg last_bck;
    always @(posedge clk) begin
        if(last_bck!==bck) bck_edges=bck_edges+1;
        last_bck<=bck;
    end

    initial begin
        rst_n=0; #100; rst_n=1;
        // 等OLED初始化完成
        wait(dut.vz.init_done==1); #50;
        $display("OLED init_done=1");
        // 等至少一次刷屏完成
        wait(dut.vz.flush_done==1); #50;
        $display("OLED flush_done=1 (至少一帧)");
        #200;
        if(bck_edges<10) begin err=err+1; $display("I2S BCK无活动 edges=%0d",bck_edges); end
        else $display("I2S BCK活动 edges=%0d",bck_edges);
        if(err==0) $display("=== TOP SYSTEM LINK PASS (I2C) ===");
        else $display("=== TOP SYSTEM FAIL err=%0d ===",err);
        $finish;
    end
    initial #60000000 $finish;
endmodule
