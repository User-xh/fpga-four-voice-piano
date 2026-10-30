//============================================================
// 4x4 矩阵扫描（多键版）：输出16位按下位图 key_state[15:0]
// 与单键版区别：不只报一个键，而是记录当前所有按下的键，
// 每一位 = 一个键，1=按下，供多声部(复音)分配给各路DDS。
// 位编号 bit = 行号*4 + 列号（与note_lut键号一致）：
//   R1: bit0~3(S1~S4)  R2: bit4~7(S5~S8)
//   R3: bit8~11(S9~S12) R4: bit12~15(S13~S16)
// 低有效：行当前扫描=0其余=1；列按下=0空闲=1(内部上拉)。
//============================================================
module keyscan_multi #(
    parameter CLK_FREQ = 25_000_000,
    parameter SCAN_US  = 1000
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [3:0] col_in,
    output reg  [3:0] row_out,
    output reg  [15:0] key_state      // 1=按下，可同时多个为1
);

    localparam SCAN_MAX = CLK_FREQ / 1_000_000 * SCAN_US;

    reg [17:0] div;
    reg  [1:0] row_idx;
    wire tick = (div == SCAN_MAX - 1);

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            div     <= 18'd0;
            row_idx <= 2'd0;
        end else if(tick) begin
            div     <= 18'd0;
            row_idx <= row_idx + 1'b1;
        end else
            div <= div + 1'b1;
    end

    always @(*) begin
        row_out = 4'b1111;
        row_out[row_idx] = 1'b0;
    end

    // 每拍只刷新"当前扫描行"的4位，其余行保持 -> 支持多键
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            key_state <= 16'd0;
        else if(tick) begin
            case(row_idx)
            2'd0: begin
                key_state[0]  <= ~col_in[0];
                key_state[1]  <= ~col_in[1];
                key_state[2]  <= ~col_in[2];
                key_state[3]  <= ~col_in[3];
            end
            2'd1: begin
                key_state[4]  <= ~col_in[0];
                key_state[5]  <= ~col_in[1];
                key_state[6]  <= ~col_in[2];
                key_state[7]  <= ~col_in[3];
            end
            2'd2: begin
                key_state[8]  <= ~col_in[0];
                key_state[9]  <= ~col_in[1];
                key_state[10] <= ~col_in[2];
                key_state[11] <= ~col_in[3];
            end
            2'd3: begin
                key_state[12] <= ~col_in[0];
                key_state[13] <= ~col_in[1];
                key_state[14] <= ~col_in[2];
                key_state[15] <= ~col_in[3];
            end
            endcase
        end
    end

endmodule
