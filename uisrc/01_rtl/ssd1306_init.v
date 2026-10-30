//============================================================
// SSD1306 上电初始化命令通道（I2C：写地址0x78 + 控制字节0x00 + 命令块连发 + STOP）
// 25条初始化命令在同一个命令事务内连续发出，发完 STOP 并拉高 init_done。
// 命令序列已对照 SSD1306 标准初始化核验。
//============================================================
module ssd1306_init(
    input  wire       clk,
    input  wire       rst_n,
    output reg        init_done,
    // 接到顶层共享的 i2c_master
    output reg        m_req,
    output reg        m_new_txn,
    output reg [7:0]  m_ctrl,
    output reg [7:0]  m_data,
    output reg        m_stop,
    input  wire       m_busy
);
    reg [5:0] idx;
    reg [2:0] st;
    reg [1:0] sc;
    localparam S_IDLE=0, S_LOAD=1, S_WAIT=2, S_STOP=3, S_DONE=4;

    // 命令全表（25字节）；I2C命令块首控制字节恒为 0x00
    function [7:0] ncmd; input [5:0] i;
        begin
            case(i)
             0: ncmd=8'hAE;
             1: ncmd=8'hD5;  2: ncmd=8'h80;
             3: ncmd=8'hA8;  4: ncmd=8'h3F;
             5: ncmd=8'hD3;  6: ncmd=8'h00;
             7: ncmd=8'h40;
             8: ncmd=8'h8D;  9: ncmd=8'h14;
            10: ncmd=8'h20; 11: ncmd=8'h00;
            12: ncmd=8'hA1;
            13: ncmd=8'hC8;
            14: ncmd=8'hDA; 15: ncmd=8'h12;
            16: ncmd=8'h81; 17: ncmd=8'h7F;
            18: ncmd=8'hD9; 19: ncmd=8'hF1;
            20: ncmd=8'hDB; 21: ncmd=8'h40;
            22: ncmd=8'hA4;
            23: ncmd=8'hA6;
            24: ncmd=8'hAF;
            default: ncmd=8'h00;
            endcase
        end
    endfunction
    localparam TOTAL = 25;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            st<=S_IDLE; idx<=6'd0; sc<=2'd0;
            m_req<=1'b0; m_new_txn<=1'b0; m_ctrl<=8'h00;
            m_data<=8'd0; m_stop<=1'b0; init_done<=1'b0;
        end else case(st)
        S_IDLE: begin
            idx<=6'd0; sc<=2'd0; m_ctrl<=8'h00;
            m_new_txn<=1'b1; m_req<=1'b1; m_data<=ncmd(0); st<=S_LOAD;
        end
        S_LOAD: begin
            m_req<=1'b0; m_new_txn<=1'b0; m_stop<=1'b0; st<=S_WAIT;
        end
        S_WAIT: begin
            if(!m_busy) begin
                if(idx==TOTAL-1) begin
                    m_req<=1'b0; st<=S_STOP; sc<=2'd0;
                end else begin
                    idx<=idx+1'b1; m_new_txn<=1'b0; m_ctrl<=8'h00;
                    m_req<=1'b1; m_data<=ncmd(idx+1'b1); st<=S_LOAD;
                end
            end
        end
        S_STOP: begin
            if(sc==2'd0) begin m_stop<=1'b1; sc<=2'd1; end
            else if(sc==2'd1) begin m_stop<=1'b0; sc<=2'd2; end
            else if(!m_busy) begin m_stop<=1'b0; init_done<=1'b1; st<=S_DONE; end
        end
        S_DONE: init_done<=1'b1;
        default: st<=S_IDLE;
        endcase
    end
endmodule
