//============================================================
// 4路混音器：去直流 -> 只加gate有效路 -> 按实际路数n归一化 -> 加回中点
// n=1: /1  n=2: /2  n=3: 近似/3(×85/256)  n=4: /4，防止单键音量偏小、多键削波。
//============================================================
module mixer (
    input  wire [11:0] s0, s1, s2, s3,
    input  wire [3:0]  gate,
    output reg  [11:0] mixed
);
    // 去直流：扩展到14位有符号后减中点2048 -> -2047~+2047
    wire signed [13:0] a0 = $signed({2'b00, s0}) - 14'sd2048;
    wire signed [13:0] a1 = $signed({2'b00, s1}) - 14'sd2048;
    wire signed [13:0] a2 = $signed({2'b00, s2}) - 14'sd2048;
    wire signed [13:0] a3 = $signed({2'b00, s3}) - 14'sd2048;

    // 实际发声路数 0~4
    wire [2:0] n = gate[0] + gate[1] + gate[2] + gate[3];

    reg signed [13:0] sum, norm, centered;
    always @(*) begin
        sum = 14'sd0;
        if(gate[0]) sum = sum + a0;
        if(gate[1]) sum = sum + a1;
        if(gate[2]) sum = sum + a2;
        if(gate[3]) sum = sum + a3;

        case(n)
            3'd0: norm = 14'sd0;
            3'd1: norm = sum;                  // /1
            3'd2: norm = sum >>> 1;           // /2
            3'd3: norm = (sum * 8'sd85) >>> 8; // 近似/3 (85/256≈0.332)
            default: norm = sum >>> 2;         // /4
        endcase

        centered = 14'sd2048 + norm;
        mixed = (centered < 0)    ? 12'd0  :
                (centered > 4095) ? 12'd4095 : centered[11:0];
    end
endmodule
