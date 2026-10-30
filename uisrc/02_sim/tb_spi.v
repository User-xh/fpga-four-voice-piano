`timescale 1ns / 1ps
//============================================================
// spi_master 仿真：发 0xA5(10100101)，sclk上升沿采样mosi核对位序
//============================================================
module tb_spi;
    reg clk=0, rst_n=0, req=0;
    reg [7:0] data;
    wire busy, sclk, mosi;
    spi_master #(.DIV(2)) u(.clk(clk),.rst_n(rst_n),.req(req),.data(data),
                            .busy(busy),.sclk(sclk),.mosi(mosi));
    always #20 clk=~clk;

    reg [7:0] cap;
    integer n=0;
    always @(posedge sclk) begin
        cap <= {cap[6:0], mosi};
        n <= n+1;
        $display("bit#%0d mosi=%b", n, mosi);
    end

    integer errors=0;
    initial begin
        rst_n=0; #100; rst_n=1; #50;
        data=8'hA5; req=1; #40; req=0;
        wait(n>=8); #60;
        $display("收到字节=%h (期望 a5), n=%0d", cap, n);
        if(cap!==8'hA5) errors=errors+1;
        if(errors==0) $display("=== SPI BYTE PASS ===");
        else $display("=== SPI FAIL ===");
        $finish;
    end
    initial #300000 $finish;   // 兜底超时，防止挂死
endmodule
