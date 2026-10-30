//============================================================
// OLED 刷屏器（I2C 版）：一帧画完后
//   事务1(命令块,控制0x00)：列/页地址6条命令连发 -> STOP
//   事务2(数据块,控制0x40)：fb 的1024字节连续发出 -> STOP
// 水平寻址模式下地址自动递增。不自带 i2c_master，由顶层例化并握手。
//============================================================
module oled_flush(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,        // frame_done 触发
    input  wire        init_done,    // 初始化完成才允许刷屏
    input  wire [7:0]  fb_rd_data,
    output reg  [9:0]  fb_rd_addr,
    output reg         tx_req,
    output reg         tx_new_txn,
    output reg  [7:0]  tx_ctrl,
    output reg  [7:0]  tx_data,
    output reg         tx_stop,
    input  wire        tx_busy,
    output reg         done
);
    localparam P_IDLE=0, P_CMD=1, P_WAITC=2, P_CSTOP=3,
               P_DATA=4, P_WAITD=5, P_DSTOP=6, P_DONE=7;
    reg [2:0] st;
    reg [2:0] cidx;
    reg [9:0] daddr;
    reg [1:0] sc;

    function [7:0] cmd; input [2:0] i;
        case(i)
         0: cmd=8'h21; // 列地址设置
         1: cmd=8'h00; // 列起0
         2: cmd=8'h7F; // 列止127
         3: cmd=8'h22; // 页地址设置
         4: cmd=8'h00; // 页起0
         5: cmd=8'h07; // 页止7
         default: cmd=8'h00;
        endcase
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            st<=P_IDLE; tx_req<=1'b0; tx_new_txn<=1'b0; tx_ctrl<=8'h00;
            tx_data<=8'd0; tx_stop<=1'b0; done<=1'b0;
            cidx<=3'd0; daddr<=10'd0; fb_rd_addr<=10'd0; sc<=2'd0;
        end else case(st)
        P_IDLE: begin
            done<=1'b0; tx_req<=1'b0; tx_stop<=1'b0; tx_new_txn<=1'b0;
            if(start && init_done) begin
                cidx<=3'd0; tx_ctrl<=8'h00; tx_new_txn<=1'b1;
                tx_req<=1'b1; tx_data<=cmd(0); st<=P_CMD;
            end
        end
        P_CMD: begin
            tx_req<=1'b0; tx_new_txn<=1'b0; st<=P_WAITC;
        end
        P_WAITC: begin
            if(!tx_busy) begin
                if(cidx==3'd5) begin
                    tx_req<=1'b0; st<=P_CSTOP; sc<=2'd0;
                end else begin
                    cidx<=cidx+1'b1; tx_new_txn<=1'b0; tx_ctrl<=8'h00;
                    tx_req<=1'b1; tx_data<=cmd(cidx+1'b1); st<=P_CMD;
                end
            end
        end
        P_CSTOP: begin
            if(sc==2'd0) begin tx_stop<=1'b1; sc<=2'd1; end
            else if(sc==2'd1) begin tx_stop<=1'b0; sc<=2'd2; end
            else if(!tx_busy) begin
                tx_stop<=1'b0;
                daddr<=10'd0; fb_rd_addr<=10'd0;
                tx_ctrl<=8'h40; tx_new_txn<=1'b1;
                tx_req<=1'b1; tx_data<=fb_rd_data; st<=P_DATA;
            end
        end
        P_DATA: begin
            tx_req<=1'b0; tx_new_txn<=1'b0; st<=P_WAITD;
        end
        P_WAITD: begin
            if(!tx_busy) begin
                if(daddr==10'd1023) begin
                    tx_req<=1'b0; st<=P_DSTOP; sc<=2'd0;
                end else begin
                    daddr<=daddr+1'b1; fb_rd_addr<=daddr+1'b1;
                    tx_new_txn<=1'b0; tx_ctrl<=8'h40;
                    tx_req<=1'b1; tx_data<=fb_rd_data; st<=P_DATA;
                end
            end
        end
        P_DSTOP: begin
            if(sc==2'd0) begin tx_stop<=1'b1; sc<=2'd1; end
            else if(sc==2'd1) begin tx_stop<=1'b0; sc<=2'd2; end
            else if(!tx_busy) begin tx_stop<=1'b0; done<=1'b1; st<=P_DONE; end
        end
        P_DONE: begin done<=1'b1; st<=P_IDLE; end
        default: st<=P_IDLE;
        endcase
    end
endmodule
