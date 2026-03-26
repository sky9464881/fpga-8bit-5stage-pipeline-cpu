`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// EX_MEM_reg.v
// EX 단계 결과를 MEM 단계로 전달하는 파이프라인 레지스터
////////////////////////////////////////////////////////////////////////////////
module EX_MEM_reg(
    input  wire        clk,
    input  wire        rst,
    input  wire [2:0]  in_opcode,     // EX 단계 opcode (제어를 위해 전달)
    input  wire        in_reg_write,  // EX 단계에서 유효한 레지스터 쓰기 신호
    input  wire        in_mem_write,  // EX 단계에서 유효한 메모리 쓰기 신호
    input  wire [4:0]  in_dest,       // 목적 레지스터 주소
    input  wire [7:0]  in_imm,        // 즉치값 (메모리 주소 등으로 사용)
    input  wire [7:0]  in_alu_result, // ALU 연산 결과 값
    input  wire [7:0]  in_mem_data,   // 메모리 쓰기용 데이터 (STO인 경우)
    output reg  [2:0]  out_opcode,
    output reg         out_reg_write,
    output reg         out_mem_write,
    output reg  [4:0]  out_dest,
    output reg  [7:0]  out_imm,
    output reg  [7:0]  out_alu_result,
    output reg  [7:0]  out_mem_data
);
    // 매 사이클 클럭 상승 모서리에서 입력 값을 래치하여 출력으로 보냄
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            // 리셋 시 모든 출력 초기화
            out_opcode     <= 3'd0;
            out_reg_write  <= 1'b0;
            out_mem_write  <= 1'b0;
            out_dest       <= 5'd0;
            out_imm        <= 8'd0;
            out_alu_result <= 8'd0;
            out_mem_data   <= 8'd0;
        end else begin
            // 정상 동작: 입력 값을 그대로 다음 단계로 전달
            out_opcode     <= in_opcode;
            out_reg_write  <= in_reg_write;
            out_mem_write  <= in_mem_write;
            out_dest       <= in_dest;
            out_imm        <= in_imm;
            out_alu_result <= in_alu_result;
            out_mem_data   <= in_mem_data;
        end
    end
endmodule
