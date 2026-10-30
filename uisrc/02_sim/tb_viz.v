`timescale 1ns / 1ps
//============================================================
// viz_render + oled_fb 仿真：验证波形居中对称 + 柱宽8列
//============================================================
module tb_viz;
    reg clk=0, rst_n=0;
    reg [11:0] sample=0; reg sample_vld=0;
    reg [15:0] key_state=0;
    reg [127:0] key_gain=0;
    reg frame_req=0; wire frame_done;
    wire pix_wr, pix_on; wire [6:0] pix_x; wire [5:0] pix_y;
    wire fb_clear_req, fb_clear_done;
    reg [9:0] rd_addr=0; wire [7:0] rd_data;

    oled_fb fb(.clk(clk),.rst_n(rst_n),.pix_wr(pix_wr),.pix_x(pix_x),
        .pix_y(pix_y),.pix_on(pix_on),.clear_req(fb_clear_req),
        .clear_done(fb_clear_done),.rd_addr(rd_addr),.rd_data(rd_data));
    viz_render r(.clk(clk),.rst_n(rst_n),.sample(sample),.sample_vld(sample_vld),
        .key_state(key_state),.key_gain(key_gain),.frame_req(frame_req),.frame_done(frame_done),
        .pix_wr(pix_wr),.pix_x(pix_x),.pix_y(pix_y),.pix_on(pix_on),
        .fb_clear_req(fb_clear_req),.fb_clear_done(fb_clear_done));
    always #20 clk=~clk;

    integer err=0;
    task feed(input [11:0] s);
        begin sample=s; sample_vld=1; #40; sample_vld=0; #40; end
    endtask

    initial begin
        rst_n=0; #100; rst_n=1; #50;
        feed(12'd2048);   // buf0 中点 -> y=15
        feed(12'd4095);  // buf1 满幅 -> y=0
        key_gain={120'd0,8'd255};  // 键0满音量 -> 柱满高
        frame_req=1;
        begin: W
            integer t;
            for(t=0;t<2000000;t=t+1) begin
                #20; if(frame_done==1) disable W;
            end
            $display("TIMEOUT fst=%0d bidx=%0d row=%0d col=%0d",r.fst,r.bidx,r.row,r.col);
        end
        frame_req=0; #60;

        // 波形列0中点 y15 -> page1 bit7
        rd_addr={3'd1,7'd0}; #20;
        $display("中点波形 page1/col0=%b (bit7应=1)",rd_data);
        if(rd_data[7]!==1'b1) err=err+1;
        // 波形列1满幅 y0 -> page0 bit0
        rd_addr={3'd0,7'd1}; #20;
        $display("满幅波形 page0/col1=%b (bit0应=1)",rd_data);
        if(rd_data[0]!==1'b1) err=err+1;
        // 柱宽8列：键0 page7 的 col0 和 col7 都应亮(bit7)
        rd_addr={3'd7,7'd0}; #20;
        if(rd_data[7]!==1'b1) begin err=err+1; $display("柱col0未亮"); end
        rd_addr={3'd7,7'd7}; #20;
        $display("柱宽 page7/col7=%b (bit7应=1)",rd_data);
        if(rd_data[7]!==1'b1) err=err+1;

        if(err==0) $display("=== VIZ RENDER PASS (居中+8列) ===");
        else $display("=== VIZ FAIL err=%0d ===",err);
        $finish;
    end
    initial #400000000 $finish;
endmodule
