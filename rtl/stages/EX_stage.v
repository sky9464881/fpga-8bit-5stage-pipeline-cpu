`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// EX_stage.v (수정됨)
// 5단계 파이프라인 구조에서 EX 단계: ALU 연산만 수행 (레지스터/RAM 접근 제거)
//////////////////////////////////////////////////////////////////////////////////
module EX_stage(
    input  wire clk,
    input  wire rst,

    // ID_EX 레지스터로부터 입력
    input  wire [2:0] in_opcode,     // 명령어 opcode
    input  wire [4:0] in_dest,       // 목적 레지스터 주소
    input  wire [7:0] in_imm,        // 즉치값 (RAM/ROM 주소 등)
    input  wire [7:0] in_reg_val,    // 범용 레지스터 값
    input  wire [7:0] in_acc_val,    // 누산기 현재 값
    input  wire       in_reg_write,  // 레지스터 쓰기 여부
    input  wire       in_mem_write,  // 메모리 쓰기 여부
	 input  wire [7:0] in_forwarding,

    // 출력: 다음 파이프라인 단계로 전달
    output reg  [7:0] alu_result,    // 연산 결과 (다음 누산기 값)
    output reg        out_reg_write, // 레지스터 쓰기 제어 (그대로 전달)
    output reg        out_mem_write, // 메모리 쓰기 제어 (그대로 전달)
    output reg  [4:0] out_dest,      // 목적지 레지스터 주소
    output reg  [7:0] out_mem_data,  // 메모리에 저장할 데이터 (STO일 경우)
    output reg        halt,           // HLT 명령 시 1
	 output reg  [7:0] out_forwarding,
	 output reg  [2:0] out_opcode
	 
	 );

    // ALU 연산 결과 계산 (조합 논리)
    always @(*) begin
        case (in_opcode)
            3'b000: alu_result = in_acc_val;                  // NOP
            3'b001: alu_result = in_imm;                    // LDO
            3'b010: alu_result = in_imm;                    // LDA: MEM_stage에서 처리 → dummy 값
            3'b011: alu_result = in_reg_val;                  // STO: 누산기 변화 없음
            3'b100: begin
							alu_result = in_reg_val;
							out_forwarding = in_reg_val;
							end                							 // PRE: 레지스터 값 → 누산기
            3'b101: begin
							alu_result = in_forwarding + in_reg_val;
							out_forwarding = in_forwarding + in_reg_val;
							end// ADD
            3'b110: alu_result = in_forwarding; //in_acc_val;                  // LDM: 누산기 값을 그대로 레지스터로 저장
            3'b111: alu_result = in_acc_val;                  // HLT
            default: alu_result = alu_result;
        endcase
    end

    // 동기 처리: 파이프라인 다음 단계로 전달
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            out_dest       <= 5'd0;
            out_reg_write  <= 1'b0;
            out_mem_write  <= 1'b0;
            out_mem_data   <= 8'd0;
				out_opcode		<= 3'd0;
            halt           <= 1'b0;
        end 
		  else if (in_opcode == 3'b100||in_opcode == 3'b101) begin
				//out_forwarding <= in_reg_val;
				out_dest       <= in_dest;
            out_reg_write  <= in_reg_write;
            out_mem_write  <= in_mem_write;
				out_opcode		<= in_opcode;
			end
			
			else if (in_opcode == 3'b011) begin
				//out_forwarding <= in_forwarding + in_reg_val;
				out_dest       <= in_dest;
            out_reg_write  <= in_reg_write;
            out_mem_write  <= in_mem_write;
				out_opcode		<= in_opcode;
			end
		  else begin
            out_dest       <= in_dest;
            out_reg_write  <= in_reg_write;
            out_mem_write  <= in_mem_write;
				out_opcode		<= in_opcode;
            // HLT 제어 신호
            if (in_opcode == 3'b111)
                halt <= 1'b1;
            else
                halt <= 1'b0;
        end
    end

endmodule
