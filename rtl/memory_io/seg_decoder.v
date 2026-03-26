module seg_decoder (
    input wire [3:0] digit,
    output reg [6:0] seg
);

    always @(*) begin
        case (digit)
            4'd0: seg = 7'b1000000;//b0111111 / b1000000
            4'd1: seg = 7'b1111001;//b0000110 / b1111001
            4'd2: seg = 7'b0100100;//b1011011 / b0100100
            4'd3: seg = 7'b0110000;//b1001111 / b0110000
            4'd4: seg = 7'b0011001;//b1100110 / b0011001
            4'd5: seg = 7'b0010010;//b1101101 / b0010010
            4'd6: seg = 7'b0000010;//b1111101 / b0000010
            4'd7: seg = 7'b1111000;//b0000111 / b1111000
            4'd8: seg = 7'b0000000;//b1111111 / b0000000
            4'd9: seg = 7'b0010000;//b1101111 / b0010000
            default: seg = 7'b1111111;
        endcase
    end
endmodule