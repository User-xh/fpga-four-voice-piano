`timescale 1ns / 1ps
//============================================================
// keyscan_multi 测试：同时按下多个键，检查16位位图
//============================================================
module tb_multi;
    reg clk=1'b0;
    reg rst_n;
    wire [3:0] col_in;
    wire [3:0] row_out;
    wire [15:0] key_state;

    keyscan_multi #(.SCAN_US(1)) u_dut (
        .clk(clk), .rst_n(rst_n),
        .col_in(col_in), .row_out(row_out), .key_state(key_state)
    );

    always #20 clk = ~clk;

    //---------- 多键行为模型：mask里所有键同时按下 ----------
    reg [15:0] mask;
    reg  [3:0] col_drv;
    reg [15:0] expect_val;
    reg [8*16-1:0] test_name;
    assign col_in = col_drv;
    integer k;
    always @(*) begin
        col_drv = 4'b1111;
        for(k=0;k<16;k=k+1) begin
            if(mask[k] && row_out[k[3:2]] == 1'b0)
                col_drv[k[1:0]] = 1'b0;
        end
    end

    integer errors=0;
    task do_check;
        begin
            repeat(300) @(posedge clk);
            if(key_state!==expect_val) begin
                errors=errors+1;
                $display("FAIL %0s 期望=%b 实得=%b", test_name, expect_val, key_state);
            end else
                $display("OK %0s -> %b", test_name, key_state);
            mask=16'd0;
            repeat(150) @(posedge clk);
        end
    endtask

    initial begin
        rst_n=1'b0; mask=16'd0;
        #200; rst_n=1'b1;
        repeat(20) @(posedge clk);

        // 跨两行：键0(R1) + 键9(R3)
        mask=16'h0201; expect_val=16'h0201; test_name="k0+k9"; do_check;
        // 同行两键：键0+键1(都在R1)
        mask=16'h0003; expect_val=16'h0003; test_name="k0+k1"; do_check;
        // 键5(R2)+键15(R4)
        mask=16'h8020; expect_val=16'h8020; test_name="k5+k15"; do_check;
        // 三键：键0、键5、键15
        mask=16'h8021; expect_val=16'h8021; test_name="k0+k5+k15"; do_check;

        if(errors==0) $display("=== MULTI-KEY ALL PASS ===");
        else          $display("=== FAIL count=%0d ===", errors);
        $finish;
    end

    initial begin
        $dumpfile("multi.vcd");
        $dumpvars(0, tb_multi);
    end
endmodule
