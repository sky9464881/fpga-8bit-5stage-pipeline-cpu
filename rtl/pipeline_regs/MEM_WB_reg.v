`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// MEM_WB_reg.v
// MEM 단계 결과를 WB 단계로 전달하는 파이프라인 레지스터
////////////////////////////////////////////////////////////////////////////////
module MEM_WB_reg(
    input  wire        clk,
    input  wire        rst,
    input  wire        in_reg_write,  // MEM_stage에서 나온 레지스터 쓰기 제어
    input  wire        in_mem_write,  // MEM_stage에서 나온 메모리 쓰기 제어
    input  wire [4:0]  in_dest,       // 목적 레지스터
    input  wire [7:0]  in_imm,        // 메모리 주소 (필요시)
    input  wire [7:0]  in_acc_data, // WB 단계로 전달할 값 (레지스터/ACC 업데이트용)
    input  wire [7:0]  in_mem_data,   // WB 단계에서 메모리에 쓸 데이터
	 input  wire [2:0]  in_wb_opcode,
	 input  wire [7:0]  in_reg_data,
    output reg         out_reg_write,
    output reg         out_mem_write,
    output reg  [4:0]  out_dest,
    output reg  [7:0]  out_imm,
    output reg  [7:0]  out_acc_data,
    output reg  [7:0]  out_mem_data,
	 output reg  [7:0]  out_reg_data,
	 output reg [2:0] out_opcode
);
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            // 리셋 시 모든 신호 초기화
            out_reg_write  <= 1'b0;
            out_mem_write  <= 1'b0;
            out_dest       <= 5'd0;
            out_imm        <= 8'd0;
            out_acc_data <= 8'd0;
            out_mem_data   <= 8'd0;
				out_reg_data  <= 8'd0;
				out_opcode <= 3'b000;
	
				
        end 
		  else if (in_wb_opcode== 3'b001) begin
				out_reg_data <= in_reg_data;
				out_reg_write  <= in_reg_write;
				out_mem_write  <= in_mem_write;
				out_dest       <= in_dest;
				out_opcode  <= in_wb_opcode;
				out_imm        <= in_imm;
				 end
		  else if (in_wb_opcode== 3'b010) begin
				out_reg_data <= in_reg_data;
				out_reg_write  <= in_reg_write;
				out_mem_write  <= in_mem_write;
				out_dest       <= in_dest;
				out_imm        <= in_imm;
				out_opcode  <= in_wb_opcode;
				 end
			else if (in_wb_opcode== 3'b110) begin
				out_reg_data <= in_reg_data;
				out_reg_write  <= in_reg_write;
				out_mem_write  <= in_mem_write;
				out_dest       <= in_dest;
				out_imm        <= in_imm;
				out_opcode  <= in_wb_opcode;
				 end
			else if (in_wb_opcode== 3'b011) begin
				out_mem_data   <= in_mem_data;
				out_reg_write  <= in_reg_write;
				out_mem_write  <= in_mem_write;
				out_dest       <= in_dest;
				out_imm        <= in_imm;
				out_opcode  <= in_wb_opcode;
				 end
		  else begin
            // 입력 값을 그대로 래치하여 WB 단계로 전달
            out_reg_write  <= in_reg_write;
            out_mem_write  <= in_mem_write;
            out_dest       <= in_dest;
            out_imm        <= in_imm;
				out_mem_data   <= in_mem_data;
				out_acc_data <= in_acc_data;
				out_opcode  <= in_wb_opcode;
			
   
				
           
        end
    end
endmodule
