//============================================================
// SSD1306 128x64 页式显存 framebuffer
// 8页(page0~7) x 128列，每页1字节=8个垂直像素(bit0=顶行)。
// 像素坐标 x:0~127, y:0~63；page=y[5:3], 列=x, 页内bit=y[2:0]。
//============================================================
module oled_fb(
    input  wire        clk,
    input  wire        rst_n,
    // 写像素
    input  wire        pix_wr,
    input  wire [6:0] pix_x,
    input  wire [5:0] pix_y,
    input  wire        pix_on,     // 1=点亮该像素 0=擦除
    // 清屏
    input  wire        clear_req,
    output reg         clear_done,
    // 供刷屏读出
    input  wire [9:0]  rd_addr,
    output wire [7:0]  rd_data
);
    reg [7:0] mem [0:1023];
    integer k;
    initial for(k=0;k<1024;k=k+1) mem[k]=8'h00;
    assign rd_data = mem[rd_addr];

    wire [2:0] page = pix_y[5:3];
    wire [6:0] col  = pix_x;
    wire [9:0]  paddr = {page, col};
    wire [2:0]  pbit  = pix_y[2:0];

    // 清屏计数器
    reg [9:0] clr_cnt;
    reg       clr_busy;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            clr_busy<=0; clr_cnt<=0; clear_done<=0;
        end else if(clear_req && !clr_busy) begin
            clr_busy<=1; clr_cnt<=0; clear_done<=0;
        end else if(clr_busy) begin
            mem[clr_cnt]<=8'h00;
            if(clr_cnt==10'd1023) begin
                clr_busy<=0; clear_done<=1;
            end else clr_cnt<=clr_cnt+1'b1;
        end else begin
            clear_done<=0;
            // 写像素（清屏期间不接受写）
            if(pix_wr && !clr_busy) begin
                if(pix_on) mem[paddr] <= mem[paddr] | (8'b1<<pbit);
                else       mem[paddr] <= mem[paddr] & ~(8'b1<<pbit);
            end
        end
    end
endmodule
