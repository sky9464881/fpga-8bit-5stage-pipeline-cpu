`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// MEM_stage.v
// 메모리 접근 단계: 데이터 메모리에서 값 읽기 (쓰기 동작은 하지 않음)
////////////////////////////////////////////////////////////////////////////////
module MEM_stage(
    input  wire        clk,
    input  wire        rst,
    input  wire [2:0]  in_opcode,     // EX_MEM_reg에서 전달된 opcode
    input  wire        in_reg_write,  // EX 단계에서 넘어온 레지스터 쓰기 제어
    input  wire        in_mem_write,  // EX 단계에서 넘어온 메모리 쓰기 제어
    input  wire [4:0]  in_dest,       // 목적 레지스터 번호
    input  wire [7:0]  in_imm,        // 메모리 주소 또는 즉치값
    input  wire [7:0]  in_alu_result, // EX 단계 ALU 결과
    input  wire [7:0]  in_mem_data,   // 메모리로 쓸 데이터(STO 명령의 경우)
    input  wire [7:0]  mem_read_data, // 데이터 메모리로부터 읽은 값 (주소 in_imm의 내용)
    output reg         out_reg_write, // WB 단계로 전달할 레지스터 쓰기 제어
    output reg         out_mem_write, // WB 단계로 전달할 메모리 쓰기 제어
    output reg  [4:0]  out_dest,      // WB 단계로 전달할 목적 레지스터
    output reg  [7:0]  out_imm,       // WB 단계로 전달할 메모리 주소 (STO의 경우)
    output reg  [7:0]  out_acc_data,// WB 단계로 전달할 값 (레지스터 쓰기나 ACC 업데이트용)
    output reg  [7:0]  out_mem_data,   // WB 단계로 전달할 메모리 쓰기 데이터 (STO의 경우)
	 output reg [7:0] out_reg_data,
	 output reg [2:0]  out_wb_opcode
);

    // ROM 접근 (LDO 명령에 필요)
    wire [7:0] rom_data;
    rom rom_inst (
        .data(rom_data),
        .addr(in_alu_result),
        .read(1'b1),
        .ena(1'b1)
    );
	 
  
 
    // MEM 단계에서는 LDA 명령일 때 메모리에서 값을 읽어 ALU 결과를 대체하고,
    // 그 외에는 EX_stage에서 전달된 ALU 결과를 그대로 사용합니다.
    always @* begin
        // 기본적으로는 입력을 그대로 전달
        out_reg_write  = in_reg_write;
        out_mem_write  = in_mem_write;
        out_dest       = in_dest;
        out_imm        = in_imm;
		  out_wb_opcode = in_opcode;
        
        // ALU 결과는 기본적으로 EX의 결과를 사용
       
        // LDA 명령(Opcode 010)인 경우: 데이터 메모리에서 읽은 값을 사용
        if (in_opcode == 3'b001) begin
            // 메모리에서 읽은 데이터를 레지스터에 쓸 값으로 설정
            out_reg_data = rom_data;
				end
			else if (in_opcode == 3'b010) begin
				out_reg_data = in_mem_data;
        end
		  else if (in_opcode == 3'b110) begin
				out_reg_data = in_alu_result;
        end
		  else if (in_opcode == 3'b011) begin
				out_mem_data = in_alu_result;
        end
			else if (in_opcode == 3'b100 || in_opcode == 3'b101  ) begin
            out_acc_data = in_alu_result;
				end
				
        // STO 명령의 경우(out_mem_write=1) 이 단계에서는 실제 메모리 쓰기를 하지 않음.
        // 주소(out_imm)와 쓰기 데이터(out_mem_data)는 다음 WB 단계로 전달되어 처리됨.
        // (별도 동작 필요 없음; 기본값으로 전달됨)
    end
endmodule
