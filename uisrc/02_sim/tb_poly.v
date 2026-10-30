`timescale 1ns / 1ps
//============================================================
// top_poly 复音仿真：多键分配 + 4路DDS + 混音不溢出
//============================================================
module tb_poly;
    reg clk=1'b0;
    reg rst_n;
    wire [3:0] col_in;
    wire [3:0] row_out;
    wire [11:0] mixed;

    top_poly #(.SCAN_US(1)) u_dut (
        .clk(clk), .rst_n(rst_n),
        .col_in(col_in), .row_out(row_out), .mixed(mixed)
    );
    always #20 clk = ~clk;

    reg [15:0] mask;
    reg [3:0] col_drv;
    assign col_in = col_drv;
    integer k;
    always @(*) begin
        col_drv = 4'b1111;
        for(k=0;k<16;k=k+1)
            if(mask[k] && row_out[k[3:2]]==1'b0) col_drv[k[1:0]]=1'b0;
    end

    integer errors=0;
    task settle; begin repeat(400) @(posedge clk); end endtask

    task check_gate_fcw(input [3:0] eg, input [31:0] f0, f1, f2, f3);
        begin
            settle;
            if(u_dut.u_assign.v_gate!==eg) begin
                errors=errors+1;
                $display("FAIL gate 期望%b 实得%b",eg,u_dut.u_assign.v_gate);
            end
            if(u_dut.u_assign.v_fcw[0*32+:32]!==f0) begin errors=errors+1; $display("FAIL fcw0"); end
            if(u_dut.u_assign.v_fcw[1*32+:32]!==f1) begin errors=errors+1; $display("FAIL fcw1"); end
            if(u_dut.u_assign.v_fcw[2*32+:32]!==f2) begin errors=errors+1; $display("FAIL fcw2"); end
            if(u_dut.u_assign.v_fcw[3*32+:32]!==f3) begin errors=errors+1; $display("FAIL fcw3"); end
            if(mixed>4095 || mixed<0) begin errors=errors+1; $display("FAIL 混音溢出 mixed=%0d",mixed); end
            $display("gate=%b fcw0=%0d fcw1=%0d mixed=%0d",
                u_dut.u_assign.v_gate,
                u_dut.u_assign.v_fcw[0*32+:32],
                u_dut.u_assign.v_fcw[1*32+:32], mixed);
            mask=16'd0; repeat(200) @(posedge clk);
        end
    endtask

    initial begin
        rst_n=1'b0; mask=16'd0;
        #200; rst_n=1'b1; repeat(20) @(posedge clk);

        // 单键 C4(bit0)
        mask=16'h0001; check_gate_fcw(4'b0001, 32'd44947,32'd0,32'd0,32'd0);
        // 双键 C4(bit0)+E4(bit4) 大三度
        mask=16'h0011; check_gate_fcw(4'b0011, 32'd44947,32'd56630,32'd0,32'd0);
        // 四键 C4(bit0)/E4(bit4)/A4(bit9)/C5(bit12)
        mask=16'h1211; check_gate_fcw(4'b1111, 32'd44947,32'd56630,32'd75591,32'd89894);

        if(errors==0) $display("=== POLY ALL PASS ===");
        else          $display("=== FAIL count=%0d ===",errors);
        $finish;
    end

    initial begin $dumpfile("poly.vcd"); $dumpvars(0,tb_poly); end
endmodule
