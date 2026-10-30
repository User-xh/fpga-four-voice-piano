`timescale 1ns / 1ps
//============================================================
// top_viz 整合仿真(I2C)：init -> 喂样本/按键 -> 一帧 -> flush 完成
// 统计上层发出的命令字节(init25 + 地址6=31)与数据字节(1024)
//============================================================
module tb_top_viz;
    reg clk=0, rst_n=0;
    reg [11:0] sample=0; reg sample_vld=0;
    reg [15:0] key_state=0; reg [127:0] key_gain=0; reg frame_in=0;
    wire scl,sda,init_done,frame_done,flush_done;
    top_viz #(.DIV(2)) dut(.clk(clk),.rst_n(rst_n),.sample(sample),
        .sample_vld(sample_vld),.key_state(key_state),.key_gain(key_gain),.frame_in(frame_in),
        .oled_scl(scl),.oled_sda(sda),
        .init_done(init_done),.frame_done(frame_done),.flush_done(flush_done));
    always #20 clk=~clk;

    integer cmd_cnt=0, data_cnt=0;
    always @(posedge clk) if(dut.i2c_req) begin
        if(dut.i2c_ctrl==8'h40) data_cnt=data_cnt+1; else cmd_cnt=cmd_cnt+1;
    end

    integer err=0;
    initial begin
        rst_n=0; #100; rst_n=1;
        // 1) 等初始化完成
        wait(init_done==1); #50;
        $display("init_done=1");
        // 2) 喂样本与按键
        sample=12'd3000; sample_vld=1; #40; sample_vld=0; #40;
        key_gain={120'd0,8'd255};
        // 3) 触发一帧
        frame_in=1; wait(frame_done==1); frame_in=0; #20;
        $display("frame_done=1, 等待flush...");
        wait(flush_done==1); #20;
        $display("flush_done=1");
        if(init_done!==1'b1) err=err+1;
        $display("命令字节=%0d(期望31) 数据字节=%0d(期望1024)",cmd_cnt,data_cnt);
        if(cmd_cnt!==31) err=err+1;
        if(data_cnt!==1024) err=err+1;
        if(err==0) $display("=== TOP VIZ INTEGRATION PASS (I2C) ===");
        else $display("=== TOP VIZ FAIL err=%0d ===",err);
        $finish;
    end
    initial #60000000 $finish;
endmodule
