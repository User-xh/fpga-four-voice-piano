`timescale 1ns / 1ps
//============================================================
// 柱高随gain起伏：直接给viz_render喂key_gain，验证柱行数=gain>>3(限24)
//============================================================
module tb_render_gain;
    reg clk=0, rst_n=0;
    reg [11:0] sample=12'd2048; reg sample_vld=0;
    reg [15:0] key_state=0;
    reg [127:0] key_gain=0;
    reg frame_req=0; wire frame_done;
    wire pix_wr,pix_on; wire [6:0] pix_x; wire [5:0] pix_y;
    wire fb_clear_req,fb_clear_done;
    reg [9:0] rd_addr=0; wire [7:0] rd_data;

    oled_fb fb(.clk(clk),.rst_n(rst_n),.pix_wr(pix_wr),.pix_x(pix_x),
        .pix_y(pix_y),.pix_on(pix_on),.clear_req(fb_clear_req),
        .clear_done(fb_clear_done),.rd_addr(rd_addr),.rd_data(rd_data));
    viz_render r(.clk(clk),.rst_n(rst_n),.sample(sample),.sample_vld(sample_vld),
        .key_state(key_state),.key_gain(key_gain),.frame_req(frame_req),
        .frame_done(frame_done),.pix_wr(pix_wr),.pix_x(pix_x),.pix_y(pix_y),
        .pix_on(pix_on),.fb_clear_req(fb_clear_req),.fb_clear_done(fb_clear_done));
    always #20 clk=~clk;

    integer err=0;
    // 读键0柱区：page7(y56~63)=低位行，page6(y48~55)=更高行
    task chk(input [9:0] pa, input [7:0] exp, input [63:0] msg);
        begin rd_addr=pa; #20;
            $display("%s page=%0d data=%b",msg,pa[9:7],rd_data);
            if(rd_data!==exp) begin err=err+1; $display("  期望%b",exp); end
        end
    endtask

    task run_frame;
        integer to;
        begin
            frame_req=1; to=0;
            while(frame_done==0 && to<2000000) begin #20; to=to+1; end
            if(frame_done==0) $display("TIMEOUT fst=%0d bidx=%0d row=%0d col=%0d bar_h=%0d",
                r.fst,r.bidx,r.row,r.col,r.bar_h);
            frame_req=0; #60;
        end
    endtask

    initial begin
        rst_n=0; #100; rst_n=1; #50;

        // 场景1: gain=0 -> 无柱
        key_gain=0; run_frame;
        chk({3'd7,7'd0},8'b0,"gain=0 page7");

        // 场景2: gain=8 (h=1) -> 仅page7最低行(bit7)
        key_gain={120'd0,8'd8}; run_frame;
        chk({3'd7,7'd0},8'b10000000,"gain=8 page7");
        chk({3'd6,7'd0},8'b0,"gain=8 page6(应空)");

        // 场景3: gain=255 (h=24) -> page6也有柱
        key_gain={120'd0,8'd255}; run_frame;
        chk({3'd7,7'd0},8'b11111111,"gain=255 page7");
        chk({3'd6,7'd0},8'b11111111,"gain=255 page6");

        if(err==0) $display("=== GAIN BAR HEIGHT PASS ===");
        else $display("=== GAIN BAR FAIL err=%0d ===",err);
        $finish;
    end
    initial #400000000 $finish;
endmodule
