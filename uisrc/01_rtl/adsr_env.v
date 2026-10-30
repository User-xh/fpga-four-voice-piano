//============================================================
// ADSR 包络发生器（per voice，48k采样节拍驱动，真实毫秒）
// 状态：IDLE -> ATTACK(0升到255) -> DECAY(降到SUSTAIN)
//       -> SUSTAIN(按住保持) -> [松手]RELEASE(降到0) -> IDLE
// 输出 gain[7:0] 0~255，作为该路DDS样本的线性增益。
//
// 节拍：只在 samp_tick(48k) 有效时推进一步，包络时长=真实毫秒。
// 实现：16位斜率累加器 acc，gain=acc[15:8]（高8位），每拍加/减一个
//       定点斜率，避免除法。斜率取整使实际时长与目标略有偏差(略长)。
//============================================================
module adsr_env #(
    parameter FS         = 48000,   // 采样率Hz
    parameter ATTACK_MS  = 10,      // 起音 ms
    parameter DECAY_MS   = 80,      // 衰减 ms
    parameter RELEASE_MS = 200,     // 释音 ms
    parameter SUSTAIN    = 8'd160   // 保持电平(0~255)
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       samp_tick,   // 48k采样节拍，1拍推进一步
    input  wire       gate,        // 1=该键按下
    output reg [7:0]  gain
);
    // 各阶段拍数与定点斜率(Q8：满幅255<<8=65280)
    localparam NA = ATTACK_MS  * FS / 1000;
    localparam ND = DECAY_MS   * FS / 1000;
    localparam NR = RELEASE_MS * FS / 1000;
    localparam SLOPE_A = (256*256) / NA;
    localparam SLOPE_D = ((256-SUSTAIN)*256) / ND;
    localparam SLOPE_R = (SUSTAIN*256) / NR;
    localparam PK = 16'd65280;            // 255<<8
    localparam SUS_ACC = SUSTAIN*256;

    localparam IDLE=3'd0, ATT=3'd1, DEC=3'd2, SUS=3'd3, REL=3'd4;
    reg [2:0] st;
    reg [15:0] acc;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            st   <= IDLE;
            acc  <= 16'd0;
            gain <= 8'd0;
        end else if(samp_tick) begin
            case(st)
            IDLE: begin
                acc  <= 16'd0;
                gain <= 8'd0;
                if(gate) st <= ATT;
            end
            ATT: begin
                if(!gate) st <= REL;
                else if(acc + SLOPE_A >= PK) begin
                    acc  <= PK;
                    gain <= 8'd255;
                    st   <= DEC;
                end else begin
                    acc  <= acc + SLOPE_A;
                    gain <= acc[15:8];
                end
            end
            DEC: begin
                if(!gate) st <= REL;
                else if(acc - SLOPE_D <= SUS_ACC) begin
                    acc  <= SUS_ACC;
                    gain <= SUSTAIN;
                    st   <= SUS;
                end else begin
                    acc  <= acc - SLOPE_D;
                    gain <= acc[15:8];
                end
            end
            SUS: begin
                acc  <= SUS_ACC;
                gain <= SUSTAIN;
                if(!gate) st <= REL;
            end
            REL: begin
                if(acc <= SLOPE_R) begin
                    acc  <= 16'd0;
                    gain <= 8'd0;
                    st   <= IDLE;
                end else begin
                    acc  <= acc - SLOPE_R;
                    gain <= acc[15:8];
                end
            end
            default: st <= IDLE;
            endcase
        end
    end

endmodule
