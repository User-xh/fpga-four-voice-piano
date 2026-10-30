//============================================================
// 复音分配器：把16位按下位图分配给最多4个voice槽
// 优先级：低位键(bit0)先占voice0，依次填满voice1~3，超出忽略。
// 输出：v_gate[3:0] 该路是否发声；v_fcw[127:0] 每路32位频率字
//       v_fcw[0*32+:32]=voice0, [1*32+:32]=voice1 ...
//============================================================
module voice_assign (
    input  wire [15:0] key_state,
    output reg  [3:0]  v_gate,
    output reg  [127:0] v_fcw,
    output reg  [15:0] v_keynum   // 每voice占用的键号[k*4+:4]，0~15
);

    // 键号 -> FCW（与 note_lut 相同的16个音）
    function [31:0] fcw_of(input [3:0] b);
        begin
            case(b)
                4'd0:  fcw_of = 32'd44947;
                4'd1:  fcw_of = 32'd47620;
                4'd2:  fcw_of = 32'd50451;
                4'd3:  fcw_of = 32'd53451;
                4'd4:  fcw_of = 32'd56630;
                4'd5:  fcw_of = 32'd59997;
                4'd6:  fcw_of = 32'd63565;
                4'd7:  fcw_of = 32'd67344;
                4'd8:  fcw_of = 32'd71349;
                4'd9:  fcw_of = 32'd75591;
                4'd10: fcw_of = 32'd80086;
                4'd11: fcw_of = 32'd84849;
                4'd12: fcw_of = 32'd89894;
                4'd13: fcw_of = 32'd95239;
                4'd14: fcw_of = 32'd100902;
                4'd15: fcw_of = 32'd106902;
                default: fcw_of = 32'd44947;
            endcase
        end
    endfunction

    integer v, b;
    always @(*) begin
        v_gate = 4'b0000;
        v_fcw  = 128'd0;
        v_keynum = 16'd0;
        v = 0;
        for(b=0; b<16; b=b+1) begin
            if(key_state[b] && v<4) begin
                v_gate[v] = 1'b1;
                v_fcw[v*32 +: 32] = fcw_of(b[3:0]);
                v_keynum[v*4 +: 4] = b[3:0];
                v = v + 1;
            end
        end
    end

endmodule
