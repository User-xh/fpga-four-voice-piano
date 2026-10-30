//============================================================
// 可视化顶层：SSD1306初始化 + 显存 + 波形/柱渲染 + 刷屏，共享一个 i2c_master
// I2C 物理脚：SCL / SDA（4脚屏，无 DC / CS）。
// 本层不接音频；sample/key_state/frame_in 由上层(音频链或tb)提供。
//============================================================
module top_viz #(parameter DIV=2)(
    input  wire        clk,
    input  wire        rst_n,
    // 输入(来自音频链/tb)
    input  wire [11:0] sample,
    input  wire        sample_vld,
    input  wire [15:0] key_state,
    input  wire [127:0] key_gain,
    input  wire        frame_in,
    // I2C 物理脚(板级约束)
    output wire        oled_scl,
    output wire        oled_sda,
    // 状态
    output wire        init_done,
    output wire        frame_done,
    output wire        flush_done
);
    // ---- 共享 I2C ----
    wire        i2c_busy;
    wire        init_req, flush_req;
    wire        init_new, flush_new;
    wire [7:0]  init_ctrl, flush_ctrl;
    wire [7:0]  init_data, flush_data;
    wire        init_stop, flush_stop;
    wire        use_init = !init_done;
    wire        i2c_req    = use_init ? init_req  : flush_req;
    wire        i2c_new    = use_init ? init_new  : flush_new;
    wire [7:0]  i2c_ctrl   = use_init ? init_ctrl : flush_ctrl;
    wire [7:0]  i2c_data   = use_init ? init_data : flush_data;
    wire        i2c_stop   = use_init ? init_stop : flush_stop;

    i2c_master #(.DIV(DIV)) i2c(
        .clk(clk),.rst_n(rst_n),
        .tx_req(i2c_req),.new_txn(i2c_new),
        .tx_ctrl(i2c_ctrl),.tx_data(i2c_data),.stop_req(i2c_stop),
        .busy(i2c_busy),.scl(oled_scl),.sda(oled_sda));

    ssd1306_init ini(.clk(clk),.rst_n(rst_n),.init_done(init_done),
        .m_req(init_req),.m_new_txn(init_new),.m_ctrl(init_ctrl),
        .m_data(init_data),.m_stop(init_stop),.m_busy(i2c_busy));

    // ---- 显存 ----
    wire        pix_wr, pix_on;
    wire [6:0]  pix_x; wire [5:0] pix_y;
    wire        fb_clear_req, fb_clear_done;
    wire [9:0]  fb_rd_addr; wire [7:0] fb_rd_data;
    oled_fb fb(.clk(clk),.rst_n(rst_n),.pix_wr(pix_wr),.pix_x(pix_x),
        .pix_y(pix_y),.pix_on(pix_on),.clear_req(fb_clear_req),
        .clear_done(fb_clear_done),.rd_addr(fb_rd_addr),.rd_data(fb_rd_data));

    // ---- 渲染 ----
    viz_render ren(.clk(clk),.rst_n(rst_n),.sample(sample),.sample_vld(sample_vld),
        .key_state(key_state),.key_gain(key_gain),.frame_req(frame_in),.frame_done(frame_done),
        .pix_wr(pix_wr),.pix_x(pix_x),.pix_y(pix_y),.pix_on(pix_on),
        .fb_clear_req(fb_clear_req),.fb_clear_done(fb_clear_done));

    // ---- 刷屏：一帧画完即发 ----
    oled_flush fl(.clk(clk),.rst_n(rst_n),.start(frame_done),.init_done(init_done),
        .fb_rd_data(fb_rd_data),.fb_rd_addr(fb_rd_addr),
        .tx_req(flush_req),.tx_new_txn(flush_new),.tx_ctrl(flush_ctrl),
        .tx_data(flush_data),.tx_stop(flush_stop),.tx_busy(i2c_busy),
        .done(flush_done));
endmodule
