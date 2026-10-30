`timescale 1ns / 1ps
//============================================================
// top_organ 串联仿真：扫描 -> 查表 -> DDS
// 验证按不同键时，内部 FCW 正确切换到对应频率字
//============================================================
module tb_top;
    reg clk=1'b0;
    reg rst_n;
    wire [3:0] col_in;
    wire [3:0] row_out;
    wire [11:0] sin_out;

    top_organ #(.SCAN_US(1)) u_dut (
        .clk(clk), .rst_n(rst_n),
        .col_in(col_in), .row_out(row_out),
        .sin_out(sin_out)
    );

    always #20 clk = ~clk;   // 25MHz

    //---------- 键盘行为模型 ----------
    reg [4:0] target;
    reg  [3:0] col_drv;
    assign col_in = col_drv;
    always @(*) begin
        col_drv = 4'b1111;
        if(target < 16 && row_out[target[3:2]] == 1'b0)
            col_drv[target[1:0]] = 1'b0;
    end

    integer errors=0;
    task press_check(input [3:0] k, input [31:0] expect_fcw);
        reg [31:0] got;
        begin
            target = k;
            wait(u_dut.u_scan.key_on && u_dut.u_scan.key_code==k);
            repeat(5) @(posedge clk);
            got = u_dut.u_lut.fcw;
            if(got!==expect_fcw) begin
                errors=errors+1;
                $display("FAIL 键%0d 期望FCW=%0d 实得=%0d", k, expect_fcw, got);
            end else
                $display("OK 键%0d -> FCW=%0d", k, got);
            target = 5'd16;
            wait(!u_dut.u_scan.key_on);
            repeat(10) @(posedge clk);
        end
    endtask

    initial begin
        rst_n=1'b0; target=5'd16;
        #200; rst_n=1'b1;
        repeat(20) @(posedge clk);

        press_check(4'd0,  32'd44947);    // C4
        press_check(4'd9,  32'd75591);    // A4
        press_check(4'd15, 32'd106902);    // D#5

        if(errors==0) $display("=== LUT LINK ALL PASS ===");
        else          $display("=== FAIL count=%0d ===", errors);
        $finish;
    end

    initial begin
        $dumpfile("top.vcd");
        $dumpvars(0, tb_top);
    end
endmodule
