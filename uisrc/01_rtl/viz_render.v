//============================================================
// 音乐可视化渲染：上半屏(页0~3, y0~31)居中对称波形，下半屏16根8列频谱柱
// 本模块只负责把画面点写到 fb 的像素接口；显存 mem 由外部 oled_fb 持有。
// 一帧流程：清屏 -> 遍历128列画波形 -> 遍历16键(8列x16行)画柱 -> frame_done。
//============================================================
module viz_render(
    input  wire        clk,
    input  wire        rst_n,
    // 音频样本(12位,中点2048)与新样本节拍
    input  wire [11:0] sample,
    input  wire        sample_vld,
    // 16键位图（保留兼容）与16键音量(每键8位ADSR gain)
    input  wire [15:0] key_state,
    input  wire [127:0] key_gain,
    // 帧触发
    input  wire        frame_req,
    output reg         frame_done,
    // 写像素到 fb
    output reg         pix_wr,
    output reg  [6:0]  pix_x,
    output reg  [5:0]  pix_y,
    output reg         pix_on,
    // 清屏握手
    output reg         fb_clear_req,
    input  wire        fb_clear_done
);
    // ---- 波形环形缓冲：128列，存样本[11:7]压缩到0~31，16为居中 ----
    reg [4:0] wbuf [0:127];
    reg [6:0] widx;
    integer wi;
    initial for(wi=0;wi<128;wi=wi+1) wbuf[wi]=5'd16; // 初始居中

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) widx<=0;
        else if(sample_vld) begin
            wbuf[widx] <= sample[11:7];   // 12位压到5位(0~31)
            widx <= widx+1'b1;
        end
    end

    // ---- 帧绘制状态机 ----
    localparam F_IDLE=0, F_CLR=1, F_WAVE=2, F_BAR=3, F_DONE=4;
    reg [2:0]  fst;
    reg [6:0]  cx;      // 波形列
    reg [3:0]  bidx;    // 柱索引0~15
    reg [4:0]  row;     // 柱内行0~23(从底向上)
    reg [2:0]  col;     // 柱内列0~7

    // 波形点 y：以16为中线上下对称，上半区0~30
    wire [4:0]  wa = wbuf[cx];
    wire [5:0]  wave_y = (wa>=5'd16) ? (6'd15-(wa-5'd16)) : (6'd15+(5'd15-wa));

    // 柱高：gain(0~255)>>3 -> 0~31，限幅24行(下半区留底边距)
    wire [7:0]  gh    = key_gain[bidx*8 +: 8];
    wire [4:0]  bar_h = (gh[7:3] > 5'd24) ? 5'd24 : gh[7:3];

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            fst<=F_IDLE; pix_wr<=0; fb_clear_req<=0; frame_done<=0;
            cx<=0; bidx<=0; row<=0; col<=0; pix_on<=1;
        end else case(fst)
        F_IDLE: begin
            frame_done<=0; pix_wr<=0;
            if(frame_req) begin fb_clear_req<=1; fst<=F_CLR; end
        end
        F_CLR: begin
            fb_clear_req<=0;
            if(fb_clear_done) begin cx<=0; bidx<=0; row<=0; col<=0; fst<=F_WAVE; end
        end
        F_WAVE: begin
            pix_x<=cx; pix_y<=wave_y; pix_on<=1; pix_wr<=1;
            if(cx==7'd127) begin cx<=0; bidx<=0; row<=0; col<=0; fst<=F_BAR; end
            else cx<=cx+1'b1;
        end
        F_BAR: begin
            if(bar_h==5'd0) begin
                // 该键音量为0：跳过
                row<=0; col<=0;
                if(bidx==4'd15) fst<=F_DONE;
                else bidx<=bidx+1'b1;
            end else begin
                // 柱宽8列 x={bidx,col}，从底y=63向上bar_h行
                pix_x <= {bidx,col};
                pix_y <= 6'd63 - row;
                pix_on<=1; pix_wr<=1;
                if(col==3'd7) begin
                    col<=0;
                    if(row==bar_h-1'b1) begin
                        row<=0;
                        if(bidx==4'd15) fst<=F_DONE;
                        else bidx<=bidx+1'b1;
                    end else row<=row+1'b1;
                end else col<=col+1'b1;
            end
        end
        F_DONE: begin
            pix_wr<=0; frame_done<=1; fst<=F_IDLE;
        end
        default: fst<=F_IDLE;
        endcase
    end
endmodule
