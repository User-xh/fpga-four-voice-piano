//============================================================
// I2C 主机发送（教学版，推挽输出，不读取从机ACK）
// 适配 4 脚 SSD1306（GND/VCC/SCL/SDA，写地址 0x78）。
// 事务模型：
//   new_txn=1 首字节：START -> 0x78(地址) -> 控制字节(0x00命令/0x40数据) -> 数据字节
//   new_txn=0 连续字节：事务内只追加发送数据字节，不重复起始/地址
//   stop_req：发 STOP 条件结束当前事务
// tx_req 为一拍脉冲；busy=1 期间不要再发新请求。
// SCL 由本模块产生；SDA 本模块单向驱动（屏为输入，ACK 位释放为高）。
//============================================================
module i2c_master #(
    parameter DIV    = 10,       // 每个SCL电平的系统时钟拍数(仿真传小值提速)
    parameter ADDR_W = 8'h7A     // SSD1306 写地址(SA0=1=0x3D)；若不亮可改回 8'h78(0x3C)
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tx_req,
    input  wire       new_txn,
    input  wire [7:0] tx_ctrl,  // 事务首块控制字节：0x00=命令块 0x40=数据块
    input  wire [7:0] tx_data,
    input  wire       stop_req,
    output reg        busy,
    output reg        scl,
    output reg        sda
);
    localparam S_IDLE=0, S_START=1, S_TX=2, S_STOP=3;
    localparam K_ADDR=0, K_CTRL=1, K_DATA=2;

    reg [2:0] st;
    reg [1:0] kind;
    reg [7:0] cur;
    reg [3:0] bitn;      // 0..7数据位，8=ACK位
    reg       low;       // 当前处于SCL低电平段
    reg [9:0] cnt;
    localparam HALF = DIV - 1;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            busy<=1'b0; scl<=1'b1; sda<=1'b1;
            st<=S_IDLE; kind<=K_DATA; cur<=8'd0;
            bitn<=4'd0; low<=1'b0; cnt<=10'd0;
        end else case(st)
        S_IDLE: begin
            busy<=1'b0; scl<=1'b1; sda<=1'b1; cnt<=10'd0; bitn<=4'd0; low<=1'b0;
            if(stop_req) begin
                busy<=1'b1; st<=S_STOP; cnt<=10'd0;
            end else if(tx_req) begin
                busy<=1'b1;
                if(new_txn) begin
                    cur<=ADDR_W; kind<=K_ADDR; bitn<=4'd0; st<=S_START; cnt<=10'd0;
                end else begin
                    cur<=tx_data; kind<=K_DATA; bitn<=4'd0; low<=1'b0; st<=S_TX; cnt<=10'd0;
                end
            end
        end
        S_START: begin
            // SCL保持高，SDA由高拉低建立起始条件
            scl<=1'b1; sda<=1'b0; cnt<=cnt+1'b1;
            if(cnt==10'd3) begin cnt<=10'd0; bitn<=4'd0; low<=1'b0; st<=S_TX; end
        end
        S_TX: begin
            if(!low) begin
                // ---- SCL 低电平段：布置 SDA ----
                scl<=1'b0;
                sda <= (bitn==4'd8) ? 1'b1 : cur[7];   // ACK位释放为高
                if(cnt==HALF) begin cnt<=10'd0; low<=1'b1; end
                else cnt<=cnt+1'b1;
            end else begin
                // ---- SCL 高电平段：数据稳定被从机采样 ----
                scl<=1'b1;
                if(cnt==HALF) begin
                    cnt<=10'd0; low<=1'b0;
                    if(bitn==4'd8) begin
                        // 一个字节(含ACK位)发完，按kind决定下一步
                        case(kind)
                        K_ADDR: begin cur<=tx_ctrl; kind<=K_CTRL; bitn<=4'd0; end
                        K_CTRL: begin cur<=tx_data; kind<=K_DATA; bitn<=4'd0; end
                        default: begin bitn<=4'd0; st<=S_IDLE; busy<=1'b0; end
                        endcase
                    end else begin
                        cur<={cur[6:0],1'b0}; bitn<=bitn+1'b1;
                    end
                end else cnt<=cnt+1'b1;
            end
        end
        S_STOP: begin
            // SCL保持高，SDA先低后高建立停止条件
            scl<=1'b1; sda<=(cnt==10'd0)?1'b0:1'b1;
            cnt<=cnt+1'b1;
            if(cnt==10'd4) begin cnt<=10'd0; st<=S_IDLE; busy<=1'b0; end
        end
        default: st<=S_IDLE;
        endcase
    end
endmodule
