`timescale 1ns / 1ps
//============================================================
// i2c_master 时序仿真：
// 事务1(命令块): START 0x78 0x00 0xAE；连续字节 0xD5(无重复起始)；STOP
// 在SCL上升沿按MSB先采集每个8位字节，核对顺序与数值。
//============================================================
module tb_i2c;
    reg clk=0, rst_n=0;
    reg tx_req=0, new_txn=0, stop_req=0;
    reg [7:0] tx_ctrl=0, tx_data=0;
    wire busy, scl, sda;
    i2c_master #(.DIV(2)) u(.clk(clk),.rst_n(rst_n),
        .tx_req(tx_req),.new_txn(new_txn),.tx_ctrl(tx_ctrl),.tx_data(tx_data),
        .stop_req(stop_req),.busy(busy),.scl(scl),.sda(sda));
    always #20 clk=~clk;

    // ---- 从机侧采样模型 ----
    reg started=0;
    reg [7:0] cap=8'd0; reg [3:0] nb=4'd0;
    reg [7:0] bytes [0:7]; integer bi=0;
    always @(*) if(scl==1'b1 && sda==1'b0) started=1;  // START: SCL高时SDA被拉低
    always @(posedge scl) begin
        if(started) begin
            if(nb<4'd8) begin cap<={cap[6:0],sda}; nb<=nb+1'b1; end
            else begin bytes[bi]=cap; bi=bi+1; nb<=4'd0; end  // 跳过ACK位
        end
    end

    integer err=0;
    initial begin
        rst_n=0; #100; rst_n=1; #50;
        // 事务1首字节：命令块
        new_txn=1; tx_ctrl=8'h00; tx_data=8'hAE; tx_req=1; #40; tx_req=0;
        wait(!busy); #20;
        // 事务内连续命令字节
        new_txn=0; tx_data=8'hD5; tx_req=1; #40; tx_req=0;
        wait(!busy); #20;
        // STOP
        stop_req=1; #40; stop_req=0; wait(!busy); #100;

        $display("采集字节数=%0d",bi);
        $display("b0=%h(期望78) b1=%h(期望00) b2=%h(期望AE) b3=%h(期望D5)",
                 bytes[0],bytes[1],bytes[2],bytes[3]);
        if(bi!==4) err=err+1;
        if(bytes[0]!==8'h78) err=err+1;
        if(bytes[1]!==8'h00) err=err+1;
        if(bytes[2]!==8'hAE) err=err+1;
        if(bytes[3]!==8'hD5) err=err+1;
        if(err==0) $display("=== I2C MASTER SEQ PASS (78 00 AE D5) ===");
        else $display("=== I2C FAIL err=%0d ===",err);
        $finish;
    end
    initial #2000000 $finish;
endmodule
