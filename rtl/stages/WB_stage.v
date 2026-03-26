`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// WB_stage.v
// Write-Back 단계: 레지스터 파일과 메모리 갱신을 위한 제어 신호 생성
////////////////////////////////////////////////////////////////////////////////
module WB_stage(
    input  wire        clk,
    input  wire        rst,
    input  wire        in_reg_write,   // MEM_WB_reg에서 전달된 레지스터 쓰기 제어
    input  wire        in_mem_write,   // MEM_WB_reg에서 전달된 메모리 쓰기 제어
    input  wire [4:0]  in_dest,        // 쓰기 대상 레지스터 번호
    input  wire [7:0]  in_imm,         // 메모리 쓰기 대상 주소 (STO 명령용)
    input  wire [7:0]  in_acc_data,  // 최종 연산 결과 값 (레지스터/ACC 업데이트)
    input  wire [7:0]  in_mem_data,    // 메모리에 저장할 데이터 (STO 명령용)
	 input wire [2:0] in_opcode,
	 input wire [7:0] in_reg_data,
    output wire        reg_write_enable, // 상위 모듈의 레지스터 파일 쓰기 활성화
    output wire [4:0]  reg_write_addr,   // 상위 모듈에 전달할 레지스터 쓰기 주소
    output wire [7:0]  reg_write_data,   // 상위 모듈에 전달할 레지스터 쓰기 데이터
    output wire        mem_write_enable, // 상위 모듈의 데이터 메모리 쓰기 활성화
    output wire [7:0]  mem_write_addr,   // 상위 모듈에 전달할 메모리 쓰기 주소
    output wire [7:0]  mem_write_data,   // 상위 모듈에 전달할 메모리 쓰기 데이터
    output wire [7:0]  accum_value       // 갱신될 누산기(accumulator) 값
);



	
	
	 
    // 레지스터 파일 쓰기 제어 출력
    assign reg_write_enable = in_reg_write;
    assign reg_write_addr   = in_dest;
    assign reg_write_data   = in_reg_data;
    // 메모리 쓰기 제어 출력
    assign mem_write_enable = in_mem_write;
    assign mem_write_addr   = in_imm;
    assign mem_write_data   = in_mem_data;
    // 누산기(accum) 새 값 출력 (ALU 결과를 그대로 사용)
    assign accum_value      = in_acc_data;
	 
endmodule