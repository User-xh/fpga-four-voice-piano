//============================================================
// SPI 主机发送（教学版，CPOL=0 / CPHA=0，MSB先出，只发不收）
// 用于驱动 SSD1306 OLED。req 为一拍脉冲触发发送1字节；
// busy=1 表示正在发送，期间不要发新请求。
// 每个 bit：bit 起始即把 mosi 置为当前 MSB，sclk 中段拉高(上升沿被采样)，
// 半周期后拉低并推进到下一位。
//============================================================
module spi_master #(
    parameter DIV = 10        // 半个sclk周期的系统时钟数(仿真可改小)
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        req,
    input  wire [7:0]  data,
    output reg         busy,
    output reg         sclk,
    output reg         mosi
);
    reg [7:0] sr;
    reg [3:0] bitcnt;
    reg [9:0] cnt;
    localparam HALF = DIV - 1;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            busy  <= 1'b0;
            sclk  <= 1'b0;
            mosi  <= 1'b0;
            sr    <= 8'd0;
            bitcnt<= 4'd0;
            cnt   <= 10'd0;
        end else if(!busy) begin
            sclk <= 1'b0;
            cnt  <= 10'd0;
            if(req) begin
                sr    <= data;
                bitcnt<= 4'd0;
                busy  <= 1'b1;
                mosi  <= data[7];   // 第一位MSB先就绪
            end
        end else begin
            // 每个bit占 2*DIV 个系统时钟：HALF拍拉高sclk(上升沿采样)，终点拍拉低并推进
            if(cnt == HALF)
                sclk <= 1'b1;
            else
                sclk <= 1'b0;

            if(cnt == {1'b0, HALF} + DIV) begin
                sclk <= 1'b0;
                if(bitcnt == 4'd7) begin
                    busy  <= 1'b0;  // 8位发完
                    bitcnt<= 4'd0;
                end else begin
                    bitcnt <= bitcnt + 1'b1;
                    sr     <= {sr[6:0], 1'b0};
                    mosi   <= sr[6];// 下一位MSB
                end
                cnt <= 10'd0;
            end else begin
                cnt <= cnt + 1'b1;
            end
        end
    end
endmodule
