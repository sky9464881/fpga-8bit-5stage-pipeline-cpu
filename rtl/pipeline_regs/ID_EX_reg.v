// ID_EX_reg.v
// ID 단계의 해독 결과와 피연산자 값을 EX 단계로 전달하는 파이프라인 레지스터 모듈
`timescale 1ns / 1ps
module ID_EX_reg(
    input  wire clk,
    input  wire rst,
    input  wire [2:0] in_opcode,
    input  wire [4:0] in_dest,
    input  wire [7:0] in_imm,
    input  wire [7:0] in_reg_val,
    input  wire [7:0] in_acc_val,
    input  wire       in_reg_write,
    input  wire       in_mem_write,
    output reg  [2:0] out_opcode,
    output reg  [4:0] out_dest,
    output reg  [7:0] out_imm,
    output reg  [7:0] out_reg_val,
    output reg  [7:0] out_acc_val,
    output reg        out_reg_write,
    output reg        out_mem_write
);
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            out_opcode    <= 3'd0;
            out_dest      <= 5'd0;
            out_imm       <= 8'd0;
            out_reg_val   <= 8'd0;
            out_acc_val   <= 8'd0;
            out_reg_write <= 1'b0;
            out_mem_write <= 1'b0;
        end else begin
            out_opcode    <= in_opcode;
            out_dest      <= in_dest;
            out_imm       <= in_imm;
            out_reg_val   <= in_reg_val;
            out_acc_val   <= in_acc_val;
            out_reg_write <= in_reg_write;
            out_mem_write <= in_mem_write;
        end
    end
endmodule
