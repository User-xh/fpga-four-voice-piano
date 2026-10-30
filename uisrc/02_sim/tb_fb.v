`timescale 1ns / 1ps
//============================================================
// oled_fb 仿真：写/擦单个像素、清屏，读回核对位
//============================================================
module tb_fb;
    reg clk=0, rst_n=0, pix_wr=0, pix_on=0, clear_req=0;
    reg [6:0] pix_x=0; reg [5:0] pix_y=0;
    wire clear_done;
    reg [9:0] rd_addr=0; wire [7:0] rd_data;
    oled_fb u(.clk(clk),.rst_n(rst_n),.pix_wr(pix_wr),.pix_x(pix_x),
        .pix_y(pix_y),.pix_on(pix_on),.clear_req(clear_req),
        .clear_done(clear_done),.rd_addr(rd_addr),.rd_data(rd_data));
    always #20 clk=~clk;

    integer err=0,i;
    task wrpix(input [6:0] x, input [5:0] y, input on);
        begin pix_x=x; pix_y=y; pix_on=on; pix_wr=1; #40; pix_wr=0; #40; end
    endtask

    initial begin
        rst_n=0; #100; rst_n=1; #50;
        // 点亮 (10,3): page0, col10, bit3 -> 0x08
        wrpix(7'd10,6'd3,1'b1);
        rd_addr={3'd0,7'd10}; #40;
        $display("点亮后字节=%h (期望08)",rd_data);
        if(rd_data!==8'h08) err=err+1;
        // 同列另一像素 (10,5) bit5 -> 应=0x08|0x20=0x28
        wrpix(7'd10,6'd5,1'b1);
        rd_addr={3'd0,7'd10}; #40;
        $display("再加bit5后=%h (期望28)",rd_data);
        if(rd_data!==8'h28) err=err+1;
        // 擦除(10,3) bit3 -> 剩0x20
        wrpix(7'd10,6'd3,1'b0);
        rd_addr={3'd0,7'd10}; #40;
        $display("擦除bit3后=%h (期望20)",rd_data);
        if(rd_data!==8'h20) err=err+1;
        // 清屏
        clear_req=1; #40; clear_req=0;
        wait(clear_done==1); #40;
        for(i=0;i<1024;i=i+1) begin rd_addr=i; #20; if(rd_data!==8'h00) err=err+1; end
        $display("清屏完成, 抽查错误数=%0d",err);
        if(err==0) $display("=== FRAMEBUFFER PASS ===");
        else $display("=== FB FAIL err=%0d ===",err);
        $finish;
    end
    initial #2000000 $finish;
endmodule
