`timescale 1ns / 1ps
//============================================================
// ssd1306_init 仿真：采集初始化发出的命令字节，与标准序列比对
//============================================================
module tb_ssd_init;
    reg clk=0, rst_n=0;
    wire init_done, mosi, sclk, dc, cs_n, m_busy, m_req;
    wire [7:0] m_data;
    ssd1306_init u(.clk(clk),.rst_n(rst_n),.init_done(init_done),
        .m_req(m_req),.m_data(m_data),.m_busy(m_busy),
        .mosi(mosi),.sclk(sclk),.dc(dc),.cs_n(cs_n));
    always #20 clk=~clk;

    reg [7:0] q [0:31];
    integer qi=0;
    always @(posedge clk) if(m_req) begin q[qi]=m_data; qi=qi+1; end

    // 标准初始化序列(25字节)
    reg [7:0] exp [0:24];
    integer i, err;
    initial begin
        exp[ 0]=8'hAE; exp[ 1]=8'hD5; exp[ 2]=8'h80; exp[ 3]=8'hA8; exp[ 4]=8'h3F;
        exp[ 5]=8'hD3; exp[ 6]=8'h00; exp[ 7]=8'h40; exp[ 8]=8'h8D; exp[ 9]=8'h14;
        exp[10]=8'h20; exp[11]=8'h00; exp[12]=8'hA1; exp[13]=8'hC8; exp[14]=8'hDA;
        exp[15]=8'h12; exp[16]=8'h81; exp[17]=8'h7F; exp[18]=8'hD9; exp[19]=8'hF1;
        exp[20]=8'hDB; exp[21]=8'h40; exp[22]=8'hA4; exp[23]=8'hA6; exp[24]=8'hAF;
        rst_n=0; #100; rst_n=1;
        wait(init_done==1); #100;
        err=0;
        if(qi!==25) begin $display("字节数=%0d 期望25",qi); err=err+1; end
        for(i=0;i<25;i=i+1)
            if(q[i]!==exp[i]) begin $display("位置%0d: 发%h 期望%h",i,q[i],exp[i]); err=err+1; end
        if(dc!==0) begin $display("命令阶段DC应为0"); err=err+1; end
        if(err==0) $display("=== SSD1306 INIT SEQ PASS (25 bytes, DC=0) ===");
        else $display("=== INIT FAIL err=%0d ===",err);
        $finish;
    end
    initial #500000 $finish;
endmodule
