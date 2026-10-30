//============================================================
// I2S 发送模块（教学版，先纯仿真，待接 PCM5102A）
// 三信号：BCK位时钟 / LRCK(WS)声道 / DIN串行数据
// 帧格式：32位/声道槽，16位有效数据放在槽的高16位，低16位补0，MSB先出
//         LRCK=0 左声道，LRCK=1 右声道
// 时钟：25MHz 分频，BCK=25M/8=3.125MHz，LRCK=BCK/64≈48.8kHz(接近48k)
// 全部动作对齐 BCK 下降沿；帧起始沿直接送出该槽MSB，避免错位一拍。
//============================================================
module i2s_tx (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] l_data,
    input  wire [15:0] r_data,
    output wire        bck,
    output reg         lrck,
    output reg         din
);

    //---------- 1. BCK 分频：25MHz / 8，下降沿在 cnt==4 ----------
    reg [2:0] cnt;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) cnt <= 3'd0;
        else       cnt <= cnt + 1'b1;
    end
    assign bck = cnt[2];
    wire neg = (cnt == 3'd4);

    //---------- 2. 位计数器 0~63：0~31左，32~63右 ----------
    reg [5:0] bcnt;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)          bcnt <= 6'd0;
        else if(neg)       bcnt <= bcnt + 1'b1;
    end
    always @(*) lrck = bcnt[5];

    //---------- 3. 移位：起始沿装槽并直接给MSB，其余沿左移 ----------
    reg [31:0] sh;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            sh  <= 32'd0;
            din <= 1'b0;
        end else if(neg) begin
            if(bcnt == 6'd0) begin
                sh  <= {l_data, 16'h0000};
                din <= l_data[15];
            end else if(bcnt == 6'd32) begin
                sh  <= {r_data, 16'h0000};
                din <= r_data[15];
            end else begin
                sh  <= {sh[30:0], 1'b0};
                din <= sh[30];
            end
        end
    end

endmodule
