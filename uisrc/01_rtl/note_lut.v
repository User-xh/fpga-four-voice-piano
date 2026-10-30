//============================================================
// 音符查表模块：键号 key_code(0~15) -> 频率字 FCW(32位)
// 采样时钟 Fs=25MHz，相位32位，FCW = f * 2^32 / Fs
// 全半音 C4 ~ D#5（含黑键），共16个音
// 新键按下(key_pulse)时更新FCW，松手保持上一个音(简易延音)
//============================================================
module note_lut (
    input  wire        clk,
    input  wire        rst_n,
    input  wire       key_pulse,      // 新键按下单脉冲
    input  wire [3:0] key_code,      // 键号 0~15
    output reg  [31:0] fcw            // 输出频率字
);

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            fcw <= 32'd44947;          // 默认中央C
        else if(key_pulse) begin
            case(key_code)
                4'd0:  fcw <= 32'd44947;    // C4  261.63Hz
                4'd1:  fcw <= 32'd47620;    // C#4 277.18Hz
                4'd2:  fcw <= 32'd50451;    // D4  293.66Hz
                4'd3:  fcw <= 32'd53451;    // D#4 311.13Hz
                4'd4:  fcw <= 32'd56630;    // E4  329.63Hz
                4'd5:  fcw <= 32'd59997;    // F4  349.23Hz
                4'd6:  fcw <= 32'd63565;    // F#4 369.99Hz
                4'd7:  fcw <= 32'd67344;    // G4  392.00Hz
                4'd8:  fcw <= 32'd71349;    // G#4 415.30Hz
                4'd9:  fcw <= 32'd75591;    // A4  440.00Hz
                4'd10: fcw <= 32'd80086;    // A#4 466.16Hz
                4'd11: fcw <= 32'd84849;    // B4  493.88Hz
                4'd12: fcw <= 32'd89894;    // C5  523.25Hz
                4'd13: fcw <= 32'd95239;    // C#5 554.37Hz
                4'd14: fcw <= 32'd100902;   // D5  587.33Hz
                4'd15: fcw <= 32'd106902;   // D#5 622.25Hz
                default: fcw <= 32'd44947;
            endcase
        end
        // 松手不刷新，fcw保持(延音)
    end

endmodule
