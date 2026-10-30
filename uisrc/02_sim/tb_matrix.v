`timescale 1ns / 1ps
//============================================================
// matrix_scan 测试平台：用行为模型模拟4x4矩阵键盘
// 给定目标键号，在该行被拉低扫描时把对应列拉到0
// 依次按下 S1(键0)、S6(键5)、S16(键15)，检查识别是否正确
//============================================================
module tb_matrix;
    reg clk=1'b0;
    reg rst_n;
    wire [3:0] col_in;
    wire [3:0] row_out;
    wire [3:0] key_code;
    wire       key_on;
    wire       key_pulse;

    // 仿真里把扫描节拍压到极快，便于观察
    matrix_scan #(.SCAN_US(1), .DEB_N(2)) u_dut (
        .clk(clk), .rst_n(rst_n),
        .col_in(col_in),
        .row_out(row_out),
        .key_code(key_code), .key_on(key_on), .key_pulse(key_pulse)
    );

    always #20 clk = ~clk;   // 25MHz

    //---------- 键盘行为模型 ----------
    reg [4:0] target;         // 0~15=按下该键，16=无键
    reg  [3:0] col_drv;
    assign col_in = col_drv;

    always @(*) begin
        col_drv = 4'b1111;
        if(target < 16) begin
            // 该行正被扫描(row_out该位=0)时，把目标列拉低
            if(row_out[target[3:2]] == 1'b0)
                col_drv[target[1:0]] = 1'b0;
        end
    end

    integer errors=0;
    integer k;
    task press_check(input [3:0] k, input [8*8-1:0] name);
        begin
            target = k;
            wait(key_on && key_code == k);
            if(key_code!==k || !key_on) begin
                errors=errors+1;
                $display("FAIL 期望键%0d 实得%0d", k, key_code);
            end else
                $display("OK 按下 %s = 键%0d, key_on=%b pulse=%b", name, key_code, key_on, key_pulse);
            target = 5'd16;          // 松手
            wait(!key_on);
            repeat(10) @(posedge clk);
        end
    endtask

    initial begin
        rst_n=1'b0; target=5'd16;
        #200; rst_n=1'b1;
        repeat(20) @(posedge clk);

        // 逐个测 S1~S16（键0~15）
        for(k=0;k<16;k=k+1) begin
            press_check(k, "key");
        end

        if(errors==0) $display("=== ALL 16 KEYS PASS ===");
        else          $display("=== FAIL count=%0d ===", errors);
        $finish;
    end

    initial begin
        $dumpfile("matrix.vcd");
        $dumpvars(0, tb_matrix);
    end
endmodule
