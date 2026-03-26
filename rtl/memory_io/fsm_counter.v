module fsm_counter (
    input wire clk,
    input wire button,
    output reg [3:0] digit  // 범위: 1~3
);

    reg prev_button = 0;

    always @(posedge clk) begin
        prev_button <= button;

        if (button && !prev_button) begin  // rising edge
            if (digit == 4'd3)
                digit <= 4'd1;
            else
                digit <= digit + 1;
        end
    end

    // 초기값
    initial digit = 4'd1;
endmodule