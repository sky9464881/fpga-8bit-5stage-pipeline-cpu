// IF_ID_reg.v
// IF 단계의 출력(명령어 정보)을 ID 단계로 전달하는 파이프라인 레지스터 모듈
`timescale 1ns / 1ps
module IF_ID_reg(
    input  wire clk,
    input  wire rst,
    input  wire stall,       // IF 단계 스톨 시 동작
    input  wire in_valid,    // IF 단계에서 유효한 명령어 신호
    input  wire [2:0] in_opcode,
    input  wire [4:0] in_ad1,
    input  wire [7:0] in_imm,
    output reg  [2:0] out_opcode,
    output reg  [4:0] out_ad1,
    output reg  [7:0] out_imm,
    output reg  out_valid
);
	

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            out_opcode <= 3'd0;
            out_ad1    <= 5'd0;
            out_imm    <= 8'd0;
            out_valid  <= 1'b0;
        end else if (stall) begin
            // 스톨 시 출력 유지 또는 NOP(0)로 처리하여 버블 생성
            out_opcode <= out_opcode;
            out_ad1    <= out_ad1;
            out_imm    <= out_imm;
            out_valid  <= 1'b0;
        end else begin
            out_opcode <= in_opcode;
            out_ad1    <= in_ad1;
            out_imm    <= in_imm;
            out_valid  <= in_valid;
        end
    end
endmodule
