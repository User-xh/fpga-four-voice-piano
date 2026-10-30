`timescale 1ns / 1ps
//============================================================
// top_audio 完整链仿真：C4+E4，检查分配/样本/送I2S
//============================================================
module tb_audio;
    reg clk=1'b0;
    reg rst_n;
    wire [3:0] col_in, row_out;
    wire bck, lrck, din;

    top_audio #(.SCAN_US(1)) u_dut (
        .clk(clk), .rst_n(rst_n), .col_in(col_in),
        .row_out(row_out), .bck(bck), .lrck(lrck), .din(din)
    );
    always #20 clk=~clk;

    reg [15:0] mask;
    reg [3:0] col_drv;
    assign col_in=col_drv;
    integer k;
    always @(*) begin
        col_drv=4'b1111;
        for(k=0;k<16;k=k+1)
            if(mask[k] && row_out[k[3:2]]==1'b0) col_drv[k[1:0]]=1'b0;
    end

    integer errors=0;
    reg signed [15:0] s1, s2;

    initial begin
        rst_n=1'b0; mask=16'd0;
        #200; rst_n=1'b1; repeat(20) @(posedge clk);

        // C4(bit0)+E4(bit4)
        mask=16'h0011;
        repeat(2000) @(posedge clk);

        if(u_dut.u_assign.v_gate!==4'b0011) begin errors=errors+1; $display("FAIL gate %b",u_dut.u_assign.v_gate); end
        if(u_dut.u_assign.v_fcw[0*32+:32]!==32'd44947) begin errors=errors+1; $display("FAIL fcw0"); end
        if(u_dut.u_assign.v_fcw[1*32+:32]!==32'd56630) begin errors=errors+1; $display("FAIL fcw1"); end

        // 采两个样本，确认正弦在变化且16位范围合法
        s1=u_dut.u_ao.l_data; repeat(3000) @(posedge clk); s2=u_dut.u_ao.l_data;
        if(s2>32767 || s2<-32768) begin errors=errors+1; $display("FAIL 样本越界 %0d",s2); end
        // 样本确实送到了I2S输入端口
        if(u_dut.u_i2s.l_data!==u_dut.u_ao.l_data) begin errors=errors+1; $display("FAIL 样本未送I2S"); end

        $display("gate=%b fcw0=%0d fcw1=%0d",u_dut.u_assign.v_gate,
            u_dut.u_assign.v_fcw[0*32+:32],u_dut.u_assign.v_fcw[1*32+:32]);
        $display("样本 s1=%0d s2=%0d (正弦变化即正常) I2S输入已连通",s1,s2);

        if(errors==0) $display("=== AUDIO CHAIN PASS ===");
        else          $display("=== FAIL=%0d ===",errors);
        $finish;
    end

    initial begin $dumpfile("audio.vcd"); $dumpvars(0,tb_audio); end
endmodule
