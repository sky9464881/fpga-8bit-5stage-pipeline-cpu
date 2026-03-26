`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module ram(

input wire clk,
input wire rst,
input ex_out_mem_write,
input ena,
input [7:0] ex_imm,
input [7:0] ex_out_mem_data,
input [7:0] ex_write_address,
output [7:0] data_mem,
input wire sw8_write_en,
input wire [7:0] sw8_addr,
input wire [7:0] sw8_data
);

  
reg [7:0] memory[255:0];


// note: Decimal number in the bracket
 integer k;
	always @(posedge clk or negedge rst) begin
   	
	 if (!rst) begin
    for (k = 0; k < 256; k = k + 1)
        memory[k] <= 8'd0;
		end else if (sw8_write_en) begin
			 memory[sw8_addr] <= sw8_data;
		end else if (ex_out_mem_write) begin
			 memory[ex_write_address] <= ex_out_mem_data;
		end
end

assign  data_mem = memory[ex_imm];

endmodule